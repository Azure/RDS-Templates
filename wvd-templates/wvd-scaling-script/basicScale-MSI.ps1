<#
Copyright 2019 Microsoft
Version 2.0 March 2019
.SYNOPSIS
This is a sample script for automatically scaling Tenant Environment WVD Host Servers in Micrsoft Azure
.Description
This script will start/stop Tenant WVD host VMs based on the number of user sessions and peak/off-peak time period specified in the configuration file.
During the peak hours, the script will start necessary session hosts in the Hostpool to meet the demands of users.
During the off-peak hours, the script will shut down session hosts and only keep the minimum number of session hosts.
This script depends on two powershell modules: Azure RM and WVD Module to get modules execute following commands.
Use "-AllowClobber" parameter if you have more than one version of PS modules installed.
PS C:\>Install-Module AzureRM  -AllowClobber
PS C:\>Install-Module Microsoft.RDInfra.RDPowershell  -AllowClobber

#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#Function for convert from UTC to Local time
function ConvertUTCtoLocal {
    param(
        $timeDifferenceInHours
    )

    $UniversalTime = (Get-Date).ToUniversalTime()
    $TimeDifferenceMinutes = 0 
    if ($TimeDifferenceInHours -match ":") {
        $TimeDifferenceHours = $TimeDifferenceInHours.Split(":")[0]
        $TimeDifferenceMinutes = $TimeDifferenceInHours.Split(":")[1]
    }
    else {
        $TimeDifferenceHours = $TimeDifferenceInHours
    }
    #Azure is using UTC time, justify it to the local time
    $ConvertedTime = $UniversalTime.AddHours($TimeDifferenceHours).AddMinutes($TimeDifferenceMinutes)
    Return $ConvertedTime
}


<#
.SYNOPSIS
Function for writing the log
#>
function Write-Log {
    param(
        [int]$level
        , [string]$Message
        , [ValidateSet("Info", "Warning", "Error")] [string]$severity = 'Info'
        , [string]$logname = $WVDTenantlog
        , [string]$color = "white"
    )
    $time = ConvertUTCtoLocal -timeDifferenceInHours $TimeDifference
    Add-Content $logname -Value ("{0} - [{1}] {2}" -f $time, $severity, $Message)
    if ($interactive) {
        switch ($severity) {
            'Error' { $color = 'Red' }
            'Warning' { $color = 'Yellow' }
        }
        if ($level -le $VerboseLogging) {
            if ($color -match "Red|Yellow") {
                Write-Output ("{0} - [{1}] {2}" -f $time, $severity, $Message) -ForegroundColor $color -BackgroundColor Black
                if ($severity -eq 'Error') {

                    throw $Message
                }
            }
            else {
                Write-Output ("{0} - [{1}] {2}" -f $time, $severity, $Message) -ForegroundColor $color
            }
        }
    }
    else {
        switch ($severity) {
            'Info' { Write-Verbose -Message $Message }
            'Warning' { Write-Warning -Message $Message }
            'Error' {
                throw $Message
            }
        }
    }
}

<#
.SYNOPSIS
Function for writing the usage log
#>
function Write-UsageLog {
    param(
        [string]$hostpoolName,
        [int]$corecount,
        [int]$vmcount,
        [bool]$depthBool = $True,
        [string]$logfilename = $WVDTenantUsagelog
    )
    $time = ConvertUTCtoLocal -timeDifferenceInHours $TimeDifference 
    if ($depthBool) {
        Add-Content $logfilename -Value ("{0}, {1}, {2}" -f $time, $hostpoolName, $vmcount)
    }

    else {

        Add-Content $logfilename -Value ("{0}, {1}, {2}, {3}" -f $time, $hostpoolName, $corecount, $vmcount)
    }
}
<#
.SYNOPSIS
Function for creating variable from JSON
#>
function SetScriptVariable ($Name, $Value) {
    Invoke-Expression ("`$Script:" + $Name + " = `"" + $Value + "`"")
}

$CurrentPath = Split-Path $script:MyInvocation.MyCommand.Path

#Json path
$JsonPath = "$CurrentPath\Config-MSI.Json"

#Log path
$WVDTenantlog = "$CurrentPath\WVDTenantScale.log"

#usage log path
$WVDTenantUsagelog = "$CurrentPath\WVDTenantUsage.log"

###### Verify Json file ######
if (Test-Path $JsonPath) {
    Write-Verbose "Found $JsonPath"
    Write-Verbose "Validating file..."
    try {
        $Variable = Get-Content $JsonPath | Out-String | ConvertFrom-Json
    }
    catch {
        #$Validate = $false
        Write-Error "$JsonPath is invalid. Check Json syntax - Unable to proceed"
        Write-Log 3 "$JsonPath is invalid. Check Json syntax - Unable to proceed" "Error"
        exit 1
    }
}
else {
    #$Validate = $false
    Write-Error "Missing $JsonPath - Unable to proceed"
    Write-Log 3 "Missing $JsonPath - Unable to proceed" "Error"
    exit 1
}
##### Load Json Configuration values as variables #########
Write-Verbose "Loading values from Config.Json"
$Variable = Get-Content $JsonPath | Out-String | ConvertFrom-Json
$Variable.WVDScale.Azure | ForEach-Object { $_.Variable } | Where-Object { $_.Name -ne $null } | ForEach-Object { SetScriptVariable -Name $_.Name -Value $_.Value }
$Variable.WVDScale.WVDScaleSettings | ForEach-Object { $_.Variable } | Where-Object { $_.Name -ne $null } | ForEach-Object { SetScriptVariable -Name $_.Name -Value $_.Value }
$Variable.WVDScale.Deployment | ForEach-Object { $_.Variable } | Where-Object { $_.Name -ne $null } | ForEach-Object { SetScriptVariable -Name $_.Name -Value $_.Value }
##### Construct Begin time and End time for the Peak period from utc to local time #####
$TimeDifference = [string]$TimeDifferenceInHours
$CurrentDateTime = ConvertUTCtoLocal -timeDifferenceInHours $TimeDifference

# Checking if the WVD Modules are existed
$WVDModules = Get-InstalledModule -Name "Microsoft.RDInfra.RDPowershell" -ErrorAction SilentlyContinue
if (!$WVDModules) {
    Write-Log 1 "WVD Modules doesn't exist. Ensure WVD Modules are installed if not execute this command 'Install-Module Microsoft.RDInfra.RDPowershell  -AllowClobber' "
    exit
}

Import-Module "Microsoft.RDInfra.RDPowershell"
$isServicePrincipalBool = ($isServicePrincipal -eq "True")

# MSI based authentication
#    - In order to rely on this, please add the MSI accounts as VM contributors at resource group level
Add-AzureRmAccount -Identity


#select the current Azure Subscription specified in the config
Select-AzureRmSubscription -SubscriptionId $currentAzureSubscriptionId

#Authenticating to WVD

# Building credentials from KeyVault
$WVDServicePrincipalPwd = (Get-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $KeyVaultSecretName).SecretValue
$WVDCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList($Username, $WVDServicePrincipalPwd)

if (!$isServicePrincipalBool) {
    # if standard account is provided login in WVD with that account 
    try {
        $authentication = Add-RdsAccount -DeploymentUrl $RDBroker -Credential $WVDCreds

    }
    catch {
        Write-Log 1 "Failed to authenticate with WVD Tenant with standard account: $($_.exception.message)" "Error"
        exit 1

    }
    $obj = $authentication | Out-String
    Write-Log 3 "Authenticating as standard account for WVD. Result: `n$obj" "Info"
}
else {
    # if service principal account is provided login in WVD with that account 
    try {
        $authentication = Add-RdsAccount -DeploymentUrl $RDBroker -TenantId $AADTenantId -Credential $wvdCreds -ServicePrincipal

    }
    catch {
        Write-Log 1 "Failed to authenticate with WVD Tenant with the service principal: $($_.exception.message)" "Error"
        exit 1
    }
    $obj = $authentication | Out-String
    Write-Log 3 "Authenticating as service principal account for WVD. Result: `n$obj" "Info"
}

#Set context to the appropriate tenant group
$currentTenantGroupName = (Get-RdsContext).TenantGroupName
if ( $tenantGroupName -ne $currentTenantGroupName ) {
    Write-Log 1 "Running switching to the $tenantGroupName context" "Info"
    Set-RdsContext -TenantGroupName $tenantGroupName
}      

#Splitting session load balancing peak hours
$BeginPeakHour = $sessionLoadBalancingPeakHours.Split("-")[0]
$EndPeakHour = $sessionLoadBalancingPeakHours.Split("-")[1]


$PeakBeginDateTime = [datetime]::Parse($CurrentDateTime.ToShortDateString() + ' ' + $BeginPeakHour)

$PeakEndDateTime = [datetime]::Parse($CurrentDateTime.ToShortDateString() + ' ' + $EndPeakHour)

#Getting Hostpool information
$hostpoolInfo = Get-RdsHostPool -TenantName $tenantName -Name $hostPoolName
if ($hostpoolInfo -eq $null) {
    Write-Log 1 "Hostpoolname '$hostpoolname' does not exist in the tenant of '$tenantname'. Ensure that you have entered the correct values." "Info"
    exit
}	
        
#Compare session loadbalancing peak hours and setting up appropriate load balacing type based on PeakLoadBalancingType
if ($CurrentDateTime -ge $PeakBeginDateTime -and $CurrentDateTime -le $PeakEndDateTime) {

    if ($hostpoolInfo.LoadBalancerType -ne $PeakLoadBalancingType) {
        Write-Log 3 "Changing Hostpool Load Balance Type:$PeakLoadBalancingType Current Date Time is: $CurrentDateTime" "Info"

        if ($PeakLoadBalancingType -eq "DepthFirst") {                
            Set-RdsHostPool -TenantName $tenantName -Name $hostPoolName -DepthFirstLoadBalancer -MaxSessionLimit $hostpoolInfo.MaxSessionLimit
        }
        else {
            Set-RdsHostPool -TenantName $tenantName -Name $hostPoolName -BreadthFirstLoadBalancer -MaxSessionLimit $hostpoolInfo.MaxSessionLimit
        }
        Write-Log 3 "Hostpool Load balancer Type in Session Load Balancing Peak Hours is '$PeakLoadBalancingType Load Balancing'"
    }
}
     
Write-Log 3 "Starting WVD Tenant Hosts Scale Optimization: Current Date Time is: $CurrentDateTime" "Info"

$BeginPeakDateTime = [datetime]::Parse($CurrentDateTime.ToShortDateString() + ' ' + $BeginPeakTime)

$EndPeakDateTime = [datetime]::Parse($CurrentDateTime.ToShortDateString() + ' ' + $EndPeakTime)

$hostpoolInfo = Get-RdsHostPool -TenantName $tenantName -Name $hostPoolName
if ($hostpoolInfo.LoadBalancerType -eq "DepthFirst") {
    Write-Log 1 "$hostPoolName hostpool loadbalancer type is $($hostpoolInfo.LoadBalancerType)" "Info"
    
    #Gathering hostpool maximum session and calculating Scalefactor for each host.										  
    $hostpoolMaxSessionLimit = $hostpoolinfo.MaxSessionLimit
    $ScaleFactorEachHost = $hostpoolMaxSessionLimit * 0.80
    $SessionhostLimit = [math]::floor($ScaleFactorEachHost)
    
    Write-Log 1 "Hostpool Maximum Session Limit: $($hostpoolMaxSessionLimit)"

    if ($CurrentDateTime -ge $BeginPeakDateTime -and $CurrentDateTime -le $EndPeakDateTime) {
        Write-output "It is in peak hours now"
        Write-Log 1 "It is in peak hours now" "Info"
        Write-Log 1 "Peak hours: starting session hosts as needed based on current workloads." "Info"
   
        #Get the session hosts in the hostpool
   
        $getHosts = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostpoolname | Sort-Object Sessions -Descending | Sort-Object Status
        if ($getHosts -eq $null) {
            Write-Log 1 "Hosts are does not exist in the Hostpool of '$hostpoolname'. Ensure that hostpool have hosts or not?." "Info"
            exit
        }
        # Check dynamically created offpeakusage-minimumnoofRDSh text file and then remove in peak hours.
        if (Test-Path -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt) {
            remove-Item -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt
        }
    
        #check the number of running session hosts
        $numberOfRunningHost = 0
        foreach ($sessionHost in $getHosts) {
            Write-Log 1 "Checking session host:$($sessionHost.SessionHostName | Out-String)  of sessions:$($sessionHost.Sessions) and status:$($sessionHost.Status)" "Info"
            $sessionCapacityofhost = $sessionhost.Sessions
            if ($SessionhostLimit -lt $sessionCapacityofhost -or $sessionHost.Status -eq "Available") {
                $numberOfRunningHost = $numberOfRunningHost + 1
            }
        }
        Write-Log 1 "Current number of running hosts: $numberOfRunningHost" "Info"
        if ($numberOfRunningHost -lt $MinimumNumberOfRDSH) {
            Write-Log 1 "Current number of running session hosts is less than minimum requirements, start session host ..." "Info"

            foreach ($sessionhost in $getHosts) {
                if ($numberOfRunningHost -lt $MinimumNumberOfRDSH) {
                    $hostofsessions = $sessionHost.Sessions
                    if ($hostpoolMaxSessionLimit -ne $hostofsessions) {
                        #Check the session host status and if the session host is healthy before starting the host
                        if ($sessionhost.Status -eq "NoHeartbeat" -and $sessionhost.UpdateState -eq "Succeeded") {
                            $sessionhostname = $sessionhost.sessionhostname | out-string
                                $VMName = $sessionhostname.Split(".")[0]
                                $VmInfo = Get-AzureRmVM | Where-Object { $_.Name -eq $VMName }
                                #Check the Session host is in maintenance
                                if($VmInfo.Tags.Keys -contains  $maintenanceTagName){
                                Write-Log 1 "Session Host is in Maintenance: $sessionhostname"
                                Continue
                                }

                            #check if the session host is allowing new connections
                            $checkAllowNewSession = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostpoolname -Name $sessionhost.sessionhostname
                            if (!($checkAllowNewSession.AllowNewSession)) {
                                Set-RdsSessionHost -TenantName $tenantname -HostPoolName $hostpoolname -Name $sessionhost.sessionhostname -AllowNewSession $true
                            }
                            
                            #start the azureRM VM
                            try {
                                Write-Log 1 "Starting Azure VM: $VMName and waiting for it to complete ..." "Info"
                                Start-AzureRmVM -Name $VMName -ResourceGroupName $VmInfo.ResourceGroupName
                            }
                            catch {
                                Write-Log 1 "Failed to start Azure VM: $($VMName) with error: $($_.exception.message)" "Info"
                                exit
                            }
                            #wait for the sessionhost is available
                            $IsHostAvailable = $false
                            while (!$IsHostAvailable) {

                                $hoststatus = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostpoolname -Name $sessionhost.sessionhostname

                                if ($hoststatus.Status -eq "Available") {
                                    $IsHostAvailable = $true

                                }
                            }
                        }
                    }
                    $numberOfRunningHost = $numberOfRunningHost + 1
                }

            }
        }

        else {
            $getHosts = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostpoolname | Sort-Object "Sessions" -Descending | Sort-Object Status
            foreach ($sessionhost in $getHosts) {
                if ($sessionHost.Sessions -ne $hostpoolMaxSessionLimit) {
                    if ($sessionHost.Sessions -ge $SessionhostLimit) {
                        foreach ($sHost in $getHosts) {
                            if ($sHost.Status -eq "Available" -and $sHost.Sessions -eq 0) { break }
                            #Check the session host status and if the session host is healthy before starting the host
                            if ($sHost.Status -eq "NoHeartbeat" -and $sHost.UpdateState -eq "Succeeded") {
                                Write-Log 1 "Existing Sessionhost Sessions value reached near by hostpool maximumsession limit need to start the session host" "Info"
                                $sessionhostname = $sHost.sessionhostname | out-string
                                $VMName = $sessionHostname.Split(".")[0]
                                #Check the Session host is in maintenance
                                $VmInfo = Get-AzureRmVM | Where-Object { $_.Name -eq $VMName }
                                if($VmInfo.Tags.Keys -contains $maintenanceTagName){
                                Write-Log 1 "Session Host is in Maintenance: $sessionhostname"
                                Continue
                                }
                                
                                #Check if the session host is allowing new connections
                                $checkAllowNewSession = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostpoolname -Name $sHost.sessionhostname
                                if (!($checkAllowNewSession.AllowNewSession)) {
                                    Set-RdsSessionHost -TenantName $tenantname -HostPoolName $hostpoolname -Name $sHost.sessionhostname -AllowNewSession $true
                                }
                                
                                #start the azureRM VM
                                try {
                                    Write-Log 1 "Starting Azure VM: $VMName and waiting for it to complete ..." "Info"
                                    Start-AzureRmVM -Name $VMName -ResourceGroupName $VMInfo.ResourceGroupName
                                }
                                catch {
                                    Write-Log 1 "Failed to start Azure VM: $($VMName) with error: $($_.exception.message)" "Info"
                                    exit
                                }
                                #wait for the sessionhost is available
                                $IsHostAvailable = $false
                                while (!$IsHostAvailable) {

                                    $hoststatus = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostpoolname -Name $sHost.sessionhostname

                                    if ($hoststatus.Status -eq "Available") {
                                        $IsHostAvailable = $true
                                    }
                                }
                                $numberOfRunningHost = $numberOfRunningHost + 1
                                break
                            
                        }
                    }
                
                }
                }
            }
        }

        Write-Log 1 "HostpoolName:$hostpoolname, NumberofRunnighosts:$numberOfRunningHost" "Info"
        $depthBool = $true
        Write-UsageLog -hostpoolName $hostPoolName -vmcount $numberOfRunningHost -depthBool $depthBool
    }
    else {
        Write-Log 1 "It is Off-peak hours" "Info"
        Write-Output "It is Off-peak hours"
        Write-Log 1 "It is off-peak hours. Starting to scale down RD session hosts..." "Info"
        Write-Log 1 ("Processing hostPool {0}" -f $hostPoolName) "Info"
        ### Getting Sessionhosts of Hostpool
        $getHosts = Get-RdsSessionHost -TenantName $tenantName -HostPoolName $hostPoolName | Sort-Object Sessions
        if ($getHosts -eq $null) {
            Write-Log 1 "Hosts are does not exist in the Hostpool of '$hostpoolname'. Ensure that hostpool have hosts or not?." "Info"
            exit
        }
	
        #check the number of running session hosts
        $numberOfRunningHost = 0
        foreach ($sessionHost in $getHosts) {
            if ($sessionHost.Status -eq "Available") {
                $numberOfRunningHost = $numberOfRunningHost + 1
            }
        }
        #Defined minimum no of rdsh value from JSON file
        [int]$definedMinimumnumberofrdsh = $MinimumNumberOfRDSH

        #Check and Collecting dynamically stored MinimumNoOfRDSH Value																 
        if (Test-Path -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt) {
            [int]$MinimumNumberOfRDSH = Get-Content $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt
        }
    
      
        if ($numberOfRunningHost -gt $MinimumNumberOfRDSH) {
            foreach ($sessionHost in $getHosts.sessionhostname) {
                if ($numberOfRunningHost -gt $MinimumNumberOfRDSH) {

                    $sessionHostinfo = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostpoolname -Name $sessionHost
                    if ($sessionHostinfo.Status -eq "Available") {

                        #ensure the running Azure VM is set as drain mode
                        try {
                            Set-RdsSessionHost -TenantName $tenantName -HostPoolName $hostPoolName -Name $sessionHost -AllowNewSession $false -ErrorAction SilentlyContinue
                        }
                        catch {
                            Write-Log 1 "Unable to set it to allow connections on session host: $($sessionHost.SessionHost) with error: $($_.exception.message)" "Info"
                            exit
                        }
                        #notify user to log off session
                        #Get the user sessions in the hostPool
                        try {
                            $hostPoolUserSessions = Get-RdsUserSession -TenantName $tenantName -HostPoolName $hostPoolName
                        }
                        catch {
                            Write-ouput "Failed to retrieve user sessions in hostPool: $($hostPoolName) with error: $($_.exception.message)"
                            exit
                        }
                        $hostUserSessionCount = ($hostPoolUserSessions | Where-Object -FilterScript { $_.sessionhostname -eq $sessionHost }).Count
                        Write-Log 1 "Counting the current sessions on the host $sessionhost...:$hostUserSessionCount" "Info"

                        $existingSession = 0
                        foreach ($session in $hostPoolUserSessions) {
                            if ($session.sessionhostname -eq $sessionHost) {
                                if ($LimitSecondsToForceLogOffUser -ne 0) {
                                    #send notification
                                    try {
                                        Send-RdsUserSessionMessage -TenantName $tenantName -HostPoolName $hostPoolName -SessionHostName $session.sessionhostname -SessionId $session.sessionid -MessageTitle $LogOffMessageTitle -MessageBody "$($LogOffMessageBody) You will logged off in $($LimitSecondsToForceLogOffUser) seconds." -NoUserPrompt

                                    }
                                    catch {
                                        Write-Log 1 "Failed to send message to user with error: $($_.exception.message)" "Info"
                                        exit
                                    }
                                }

                                $existingSession = $existingSession + 1
                            }
                        }
                        #wait for n seconds to log off user
                        Start-Sleep -Seconds $LimitSecondsToForceLogOffUser
                        if ($LimitSecondsToForceLogOffUser -ne 0) {
                            #force users to log off
                            Write-Log 1 "Force users to log off..." "Info"
                            try {
                                $hostPoolUserSessions = Get-RdsUserSession -TenantName $tenantName -HostPoolName $hostPoolName

                            }
                            catch {
                                Write-Log 1 "Failed to retrieve list of user sessions in hostPool: $($hostPoolName) with error: $($_.exception.message)" "Info"
                                exit
                            }
                            foreach ($session in $hostPoolUserSessions) {
                                if ($session.sessionhostname -eq $sessionHost) {
                                    #log off user
                                    try {

                                        Invoke-RdsUserSessionLogoff -TenantName $tenantName -HostPoolName $hostPoolName -SessionHostName $session.sessionhostname -SessionId $session.sessionid -NoUserPrompt
                                        $existingSession = $existingSession - 1
                                    }
                                    catch {
                                        Write-ouput "Failed to log off user with error: $($_.exception.message)"
                                        exit
                                    }
                                }
                            }
                        }


                        $VMName = $sessionHost.Split(".")[0]
                          #Check the Session host is in maintenance
                                $VmInfo = Get-AzureRmVM | Where-Object { $_.Name -eq $VMName }
                                if($VmInfo.Tags.Keys -contains $maintenanceTagName){
                                Write-Log 1 "Session Host is in Maintenance: $($sessionHost | out-string)"
                                $numberOfRunningHost = $numberOfRunningHost - 1
                                Continue
                                }

                        #check the session count before shutting down the VM
                        if ($existingSession -eq 0) {
                            #shutdown the Azure VM
                            try {
                                Write-Log 1 "Stopping Azure VM: $VMName and waiting for it to complete ..." "Info"
                                Stop-AzureRmVM -Name $VMName -ResourceGroupName $VmInfo.ResourceGroupName -Force
                            }
                            catch {
                                Write-Log 1 "Failed to stop Azure VM: $VMName with error: $_.exception.message" "Info"
                                exit
                            }
                        }

                        #Check if the session host server is healthy before enable allowing new connections
                        if ($sessionHostinfo.UpdateState -eq "Succeeded") {
                            #Ensure the Azure VMs that are off have the AllowNewSession mode set to True
                            try {
                                Set-RdsSessionHost -TenantName $tenantName -HostPoolName $hostPoolName -Name $sessionHost -AllowNewSession $true -ErrorAction SilentlyContinue
                            }
                            catch {
                                Write-Log 1 "Unable to set it to allow connections on session host: $($sessionHost.SessionHost) with error: $($_.exception.message)" "Error"
                                exit 1
                            }
                        }

                        #Decrement the number of running session host
                        $numberOfRunningHost = $numberOfRunningHost - 1
                    }
                }
            }
        }

        #Check whether minimumNoofRDSH Value stored dynamically
        if (Test-Path -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt) {
            [int]$MinimumNumberOfRDSH = Get-Content $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt
            $noConnectionsofhost = 0
            if ($numberOfRunningHost -le $MinimumNumberOfRDSH) {
                foreach ($sHost in $getHosts) {
                    if ($sHost.Status -eq "Available" -and $sHost.Sessions -eq 0) { 
                        $noConnectionsofhost = $noConnectionsofhost + 1 
                 
                    }
                }
                if ($noconnectionsofhost -gt $definedMinimumnumberofrdsh) {
                    [int]$MinimumNumberOfRDSH = [int]$MinimumNumberOfRDSH - $noconnectionsofhost
                    Clear-Content -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt
                    Set-Content -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt $MinimumNumberOfRDSH
                }
            }
        }


        $HostpoolMaxSessionLimit = $hostpoolInfo.MaxSessionLimit
        $HostpoolSessionCount = (Get-RdsUserSession -TenantName $tenantName -HostPoolName $hostPoolName).count
        if ($HostpoolSessionCount -eq 0) {
            Write-Log 1 "HostpoolName:$hostpoolname, NumberofRunnighosts:$numberOfRunningHost" "Info"
            #write to the usage log					   
            $depthBool = $true
            Write-UsageLog -hostpoolName $hostPoolName -vmcount $numberOfRunningHost -depthBool $depthBool
            Write-Log 3 "End WVD Tenant Scale Optimization." "Info"
            break
        }
        else {
            #Calculate the how many sessions will allow in minimum number of RDSH VMs in off peak hours and calculate TotalAllowSessions Scale Factor																						   
            $totalAllowSessionsinOffPeak = [int]$MinimumNumberOfRDSH * $HostpoolMaxSessionLimit
            $SessionsScaleFactor = $totalAllowSessionsinOffPeak * 0.90
            $ScaleFactor = [math]::Floor($SessionsScaleFactor)										  
     

            if ($HostpoolSessionCount -ge $ScaleFactor) {
    
                foreach ($sessionHost in $getHosts) {
                    if ($sessionHost.Sessions -ge $SessionhostLimit) {
      
                        $getHosts = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostpoolname | Sort-Object Sessions | Sort-Object Status
                        foreach ($sessionhost in $getHosts) {
                            if ($sessionHost.Status -eq "Available" -and $sessionHost.Sessions -eq 0) 
                            { break }
                            #Check the session host status and if the session host is healthy before starting the host
                            if ($sessionHost.Status -eq "NoHeartbeat" -and $sessionhost.UpdateState -eq "Succeeded") {
                                Write-Log 1 "Existing Sessionhost Sessions value reached near by hostpool maximumsession limit need to start the session host" "Info"
                                $sessionhostname = $sessionHost.sessionhostname | Out-String
                                
                                $VMName = $sessionHostname.Split(".")[0]
                                $VmInfo = Get-AzureRmVM | Where-Object { $_.Name -eq $VMName }
                                #Check the Session host is in maintenance
                                if($VmInfo.Tags.Keys -eq $maintenanceTagName){
                                Write-Log 1 "Session Host is in Maintenance: $sessionhostname"
                                Continue
                                }
                                
                                #check if the session host is allowing new connections
                                $checkAllowNewSession = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostpoolname -Name $sessionHost.sessionhostname
                                if (!($checkAllowNewSession.AllowNewSession)) {
                                    Set-RdsSessionHost -TenantName $tenantname -HostPoolName $hostpoolname -Name $sessionHost.sessionhostname -AllowNewSession $true
                                }
                               

                                #start the azureRM VM
                                try {
									Write-Log 1 "Starting Azure VM: $VMName and waiting for it to complete ..." "Info"
                                    Start-AzureRmVM -Name $VMName -ResourceGroupName $VmInfo.ResourceGroupName
                                }
                                catch {
                                    Write-Log 1 "Failed to start Azure VM: $($VMName) with error: $($_.exception.message)" "Info"
                                    exit
                                }
                                #wait for the sessionhost is available
                                $IsHostAvailable = $false
                                while (!$IsHostAvailable) {

                                    $hoststatus = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostpoolname -Name $sessionHost.sessionhostname

                                    if ($hoststatus.Status -eq "Available") {
                                        $IsHostAvailable = $true
                                    }
                                }
                                $numberOfRunningHost = $numberOfRunningHost + 1
                                [int]$MinimumNumberOfRDSH = $MinimumNumberOfRDSH + 1
                                if (!(Test-Path -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt)) {
                                    New-Item -ItemType File -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt
                                    Add-Content $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt $MinimumNumberOfRDSH
                                }
                                else {
                                    Clear-Content -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt
                                    Set-Content -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt $MinimumNumberOfRDSH
                                }
                                break
                            }
                        }
                    }
                }
            }
        }


        Write-Log 1 "HostpoolName:$hostpoolname, NumberofRunnighosts:$numberOfRunningHost" "Info"
        $depthBool = $true
        Write-UsageLog -hostpoolName $hostPoolName -vmcount $numberOfRunningHost -depthBool $depthBool
    }
    Write-Log 3 "End WVD Tenant Scale Optimization." "Info"
  
}
else {
    Write-Log 3 "$hostPoolName hostpool loadbalancer type is $($hostpoolInfo.LoadBalancerType)" "Info"
    #check if it is during the peak or off-peak time
    if ($CurrentDateTime -ge $BeginPeakDateTime -and $CurrentDateTime -le $EndPeakDateTime) {
        Write-Output "It is in peak hours now"
        Write-log 1 "It is in peak hours now" "Info"
        Write-Log 3 "Peak hours: starting session hosts as needed based on current workloads." "Info"
        #Get the Session Hosts in the hostPool		
        $RDSessionHost = Get-RdsSessionHost -TenantName $tenantName -HostPoolName $hostPoolName -ErrorAction SilentlyContinue | Sort-Object SessionHostName
        if ($RDSessionHost -eq $null) {
            Write-Log 1 "Hosts are does not exist in the Hostpool of '$hostpoolname'. Ensure that hostpool have hosts or not?." "Info"
            exit
        }

        #Get the User Sessions in the hostPool
        try {
            $hostPoolUserSessions = Get-RdsUserSession -TenantName $tenantName -HostPoolName $hostPoolName
        }
        catch {
            Write-Log 1 "Failed to retrieve user sessions in hostPool:$($hostPoolName) with error: $($_.exception.message)" "Error"
            exit 1
        }
	
        #Check and Remove the MinimumnoofRDSH value dynamically stored file												   
        if (Test-Path -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt) {
            remove-Item -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt
        }

        #check the number of running session hosts
        $numberOfRunningHost = 0

        #total of running cores
        $totalRunningCores = 0

        #total capacity of sessions of running VMs
        $AvailableSessionCapacity = 0

        foreach ($sessionHost in $RDSessionHost) {
            Write-Log 1 "Checking session host:$($sessionHost.SessionHostName | Out-String)  of sessions:$($sessionHost.Sessions) and status:$($sessionHost.Status)" "Info"
            $hostName = $sessionHost.SessionHostName | Out-String
            $VMName = $hostName.Split(".")[0]
            $VmInfo = Get-AzureRmVM | Where-Object { $_.Name -eq $VMName }
             #Check the Session host is in maintenance
             if($VmInfo.Tags.Keys -contains $maintenanceTagName){
             Write-Log 1 "Session Host is in Maintenance: $hostName"
             Continue
             }
            $roleInstance = Get-AzureRmVM -Status | Where-Object { $_.Name.Contains($VMName) }
            if ($hostName.ToLower().Contains($roleInstance.Name.ToLower())) {
                #check if the azure vm is running       
                if ($roleInstance.PowerState -eq "VM running") {
                    $numberOfRunningHost = $numberOfRunningHost + 1
                    #Calculate available capacity of sessions						
                    $roleSize = Get-AzureRmVMSize -Location $roleInstance.Location | Where-Object { $_.Name -eq $roleInstance.HardwareProfile.VmSize }
                    $AvailableSessionCapacity = $AvailableSessionCapacity + $roleSize.NumberOfCores * $SessionThresholdPerCPU
                    $totalRunningCores = $totalRunningCores + $roleSize.NumberOfCores
                }
            }
        }
        Write-Log 1 "Current number of running hosts:$numberOfRunningHost" "Info"
        if ($numberOfRunningHost -lt $MinimumNumberOfRDSH) {
            Write-Log 1 "Current number of running session hosts is less than minimum requirements, start session host ..." "Info"
            #start VM to meet the minimum requirement            
            foreach ($sessionHost in $RDSessionHost.sessionhostname) {
                #check whether the number of running VMs meets the minimum or not
                if ($numberOfRunningHost -lt $MinimumNumberOfRDSH) {
                    $VMName = $sessionHost.Split(".")[0]
                     $VmInfo = Get-AzureRmVM | Where-Object { $_.Name -eq $VMName }
                    #Check the Session host is in maintenance
                    if($VmInfo.Tags.Keys -contains $maintenanceTagName){
                        Write-Log 1 "Session Host is in Maintenance: $($sessionhost | out-string )"
                        Continue
                        }
                    
                    $roleInstance = Get-AzureRmVM -Status | Where-Object { $_.Name.Contains($VMName) }
                    if ($sessionHost.ToLower().Contains($roleInstance.Name.ToLower())) {
                        
                        #Check if the Azure VM is running and if the session host is healthy
                        $getShsinfo = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostPoolName -Name $sessionHost
                        if ($roleInstance.PowerState -ne "VM running" -and $getShsinfo.UpdateState -eq "Succeeded") {
                            #check if the session host is allowing new connections
                            if ($getShsinfo.AllowNewSession -eq $false) {
                                Set-RdsSessionHost -TenantName $tenantName -HostPoolName $hostPoolName -Name $sessionHost -AllowNewSession $true
                            }
                            #start the azure VM
                            try {
								Write-Log 1 "Starting Azure VM: $($roleInstance.Name) and waiting for it to complete ..." "Info"
                                Start-AzureRmVM -Name $roleInstance.Name -Id $roleInstance.Id -ErrorAction SilentlyContinue
                            }
                            catch {
                                Write-Log 1 "Failed to start Azure VM: $($roleInstance.Name) with error: $($_.exception.message)" "Error"
                                exit 1
                            }
                            #wait for the VM to start
                            $IsVMStarted = $false
                            while (!$IsVMStarted) {

                                $vm = Get-AzureRmVM -Status | Where-Object { $_.Name -eq $roleInstance.Name }

                                if ($vm.PowerState -eq "VM running" -and $vm.ProvisioningState -eq "Succeeded") {
                                    $IsVMStarted = $true
                                    Set-RdsSessionHost -TenantName $tenantName -HostPoolName $hostPoolName -Name $sessionHost -AllowNewSession $true
                                }
                            }
                            # Calculate available capacity of sessions
                            $vm = Get-AzureRmVM -Status | Where-Object { $_.Name -eq $roleInstance.Name }
                            $roleSize = Get-AzureRmVMSize -Location $roleInstance.Location | Where-Object { $_.Name -eq $roleInstance.HardwareProfile.VmSize }
                            $AvailableSessionCapacity = $AvailableSessionCapacity + $roleSize.NumberOfCores * $SessionThresholdPerCPU
                            $numberOfRunningHost = $numberOfRunningHost + 1
                            $totalRunningCores = $totalRunningCores + $roleSize.NumberOfCores
                            if ($numberOfRunningHost -ge $MinimumNumberOfRDSH) {
                                break;
                            }
                        }
                    }
                }
            }
        }
        else {
            #check if the available capacity meets the number of sessions or not
            Write-Log 1 "Current total number of user sessions: $(($hostPoolUserSessions).Count)" "Info"
            Write-Log 1 "Current available session capacity is: $AvailableSessionCapacity" "Info"
            if ($hostPoolUserSessions.Count -ge $AvailableSessionCapacity) {
                Write-Log 1 "Current available session capacity is less than demanded user sessions, starting session host" "Info"
                #running out of capacity, we need to start more VMs if there are any 
                foreach ($sessionHost in $RDSessionHost.sessionhostname) {
                    if ($hostPoolUserSessions.Count -ge $AvailableSessionCapacity) {
                        $VMName = $sessionHost.Split(".")[0]
                          $VmInfo = Get-AzureRmVM | Where-Object { $_.Name -eq $VMName }
                            #Check the Session host is in maintenance
                            if($VmInfo.Tags.Keys -contains $maintenanceTagName){
                                 Write-Log 1 "Session Host is in Maintenance: $($sessionhost | out-string)"
                                 Continue
                                }

                        $roleInstance = Get-AzureRmVM -Status | Where-Object { $_.Name.Contains($VMName) }

                        if ($sessionHost.ToLower().Contains($roleInstance.Name.ToLower())) {
                            #Check if the Azure VM is running and if the session host is healthy
                            $getShsinfo = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostPoolName -Name $sessionHost
                            if ($roleInstance.PowerState -ne "VM running" -and $getShsinfo.UpdateState -eq "Succeeded") {
                                #check if the session host is allowing new connections
                                if ($getShsinfo.AllowNewSession -eq $false) {
                                    Set-RdsSessionHost -TenantName $tenantName -HostPoolName $hostPoolName -Name $sessionHost -AllowNewSession $true
                                }
                                #start the Azure VM
                                try {
									Write-Log 1 "Starting Azure VM: $($roleInstance.Name) and waiting for it to complete ..." "Info"
                                    Start-AzureRmVM -Name $roleInstance.Name -Id $roleInstance.Id -ErrorAction SilentlyContinue

                                }
                                catch {
                                    Write-Log 1 "Failed to start Azure VM: $($roleInstance.Name) with error: $($_.exception.message)" "Error"
                                    exit 1
                                }
                                #wait for the VM to start
                                $IsVMStarted = $false
                                while (!$IsVMStarted) {
                                    $vm = Get-AzureRmVM -Status | Where-Object { $_.Name -eq $roleInstance.Name }

                                    if ($vm.PowerState -eq "VM running" -and $vm.ProvisioningState -eq "Succeeded") {
                                        $IsVMStarted = $true
                                        Write-Log 1 "Azure VM has been started: $($roleInstance.Name) ..." "Info"
                                    }
                                    else {
                                        Write-Log 3 "Waiting for Azure VM to start $($roleInstance.Name) ..." "Info"
                                    }
                                }
                                # Calculate available capacity of sessions
                                $vm = Get-AzureRmVM -Status | Where-Object { $_.Name -eq $roleInstance.Name }
                                $roleSize = Get-AzureRmVMSize -Location $roleInstance.Location | Where-Object { $_.Name -eq $roleInstance.HardwareProfile.VmSize }
                                $AvailableSessionCapacity = $AvailableSessionCapacity + $roleSize.NumberOfCores * $SessionThresholdPerCPU
                                $numberOfRunningHost = $numberOfRunningHost + 1
                                $totalRunningCores = $totalRunningCores + $roleSize.NumberOfCores
                                Write-Log 1 "new available session capacity is: $AvailableSessionCapacity" "Info"
                                if ($AvailableSessionCapacity -gt $hostPoolUserSessions.Count) {
                                    break
                                }
                            }
                            #Break # break out of the inner foreach loop once a match is found and checked
                        }
                    }
                }
            }
        }
        Write-Log 1 "HostpoolName:$hostpoolName, TotalRunningCores:$totalRunningCores NumberOfRunningHost:$numberOfRunningHost" "Info"
        #write to the usage log
        $depthBool = $false
        Write-UsageLog $hostPoolName $totalRunningCores $numberOfRunningHost $depthBool
    }
    #} 
    else {
        Write-Log 1 "It is Off-peak hours" "Info"
        Write-Output "It is Off-peak hours"
        Write-Log 3 "It is off-peak hours. Starting to scale down RD session hosts..." "Info"
        Write-Output ("Processing hostPool {0}" -f $hostPoolName)
        Write-Log 3 "Processing hostPool $($hostPoolName)"
        #Get the Session Hosts in the hostPool
        $RDSessionHost = Get-RdsSessionHost -TenantName $tenantName -HostPoolName $hostPoolName
  
        if ($RDSessionHost -eq $null) {
            Write-Log 1 "Hosts are does not exist in the Hostpool of '$hostpoolname'. Ensure that hostpool have hosts or not?." "Info"
            exit
        }
    
        #check the number of running session hosts
        $numberOfRunningHost = 0

        #Total number of running cores
        $totalRunningCores = 0
    
        foreach ($sessionHost in $RDSessionHost.sessionhostname) {

            $VMName = $sessionHost.Split(".")[0]
            $roleInstance = Get-AzureRmVM -Status | Where-Object { $_.Name.Contains($VMName) }

            if ($sessionHost.ToLower().Contains($roleInstance.Name.ToLower())) {
                #check if the Azure VM is running or not

                if ($roleInstance.PowerState -eq "VM running") {
                    $numberOfRunningHost = $numberOfRunningHost + 1

                    # Calculate available capacity of sessions  
                    $roleSize = Get-AzureRmVMSize -Location $roleInstance.Location | Where-Object { $_.Name -eq $roleInstance.HardwareProfile.VmSize }

                    $totalRunningCores = $totalRunningCores + $roleSize.NumberOfCores
                }
            }
        }
        #Defined minimum no of rdsh value from JSON file
        [int]$definedMinimumnumberofrdsh = $MinimumNumberOfRDSH
    
        #Check and Collecting dynamically stored MinimumNoOfRDSH Value																 
        if (Test-Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt) {
            [int]$MinimumNumberOfRDSH = Get-Content $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt
        }

        if ($numberOfRunningHost -gt $MinimumNumberOfRDSH) {
            #shutdown VM to meet the minimum requirement

            foreach ($sessionHost in $RDSessionHost.sessionhostname) {
                if ($numberOfRunningHost -gt $MinimumNumberOfRDSH) {

                    $VMName = $sessionHost.Split(".")[0]
                    $roleInstance = Get-AzureRmVM -Status | Where-Object { $_.Name.Contains($VMName) }

                    if ($sessionHost.ToLower().Contains($roleInstance.Name.ToLower())) {
                        #check if the Azure VM is running or not

                        if ($roleInstance.PowerState -eq "VM running") {
                            #check the role isntance status is ReadyRole or not, before setting the session host
                            $isInstanceReady = $false
                            $numOfRetries = 0

                            while (!$isInstanceReady -and $numOfRetries -le 3) {
                                $numOfRetries = $numOfRetries + 1
                                $instance = Get-AzureRmVM -Status | Where-Object { $_.Name -eq $roleInstance.Name }
                                if ($instance.ProvisioningState -eq "Succeeded" -and $instance -ne $null) {
                                    $isInstanceReady = $true
                                }

                            }
                            if ($isInstanceReady) {
                                #ensure the running Azure VM is set as drain mode
                                try {
                                    Set-RdsSessionHost -TenantName $tenantName -HostPoolName $hostPoolName -Name $sessionHost -AllowNewSession $false -ErrorAction SilentlyContinue
                                }
                                catch {
                                    Write-Log 1 "Unable to set it to allow connections on session host: $($sessionHost.SessionHost) with error: $($_.exception.message)" "Error"
                                    exit 1
                                }
                                #notify user to log off session
                                #Get the user sessions in the hostPool
                                try {
                                    $hostPoolUserSessions = Get-RdsUserSession -TenantName $tenantName -HostPoolName $hostPoolName
                                }
                                catch {
                                    Write-Log 1 "Failed to retrieve user sessions in hostPool: $($hostPoolName) with error: $($_.exception.message)" "Error"
                                    exit 1
                                }

                                $hostUserSessionCount = ($hostPoolUserSessions | Where-Object -FilterScript { $_.sessionhostname -eq $sessionHost }).Count
                                Write-Log 1 "Counting the current sessions on the host $sessionhost...:$hostUserSessionCount" "Info"
                                #Write-Log 1 "Counting the current sessions on the host..." "Info"
                                $existingSession = 0

                                foreach ($session in $hostPoolUserSessions) {

                                    if ($session.sessionhostname -eq $sessionHost) {

                                        if ($LimitSecondsToForceLogOffUser -ne 0) {
                                            #send notification
                                            try {

                                                Send-RdsUserSessionMessage -TenantName $tenantName -HostPoolName $hostPoolName -SessionHostName $sessionHost -SessionId $session.sessionid -MessageTitle $LogOffMessageTitle -MessageBody "$($LogOffMessageBody) You will logged off in $($LimitSecondsToForceLogOffUser) seconds." -NoUserPrompt
                                            }
                                            catch {

                                                Write-Log 1 "Failed to send message to user with error: $($_.exception.message)" "Error"
                                                exit 1

                                            }
                                        }

                                        $existingSession = $existingSession + 1
                                    }
                                }
                                #wait for n seconds to log off user
                                Start-Sleep -Seconds $LimitSecondsToForceLogOffUser

                                if ($LimitSecondsToForceLogOffUser -ne 0) {
                                    #force users to log off
                                    Write-Log 1 "Force users to log off..." "Info"
                                    try {
                                        $hostPoolUserSessions = Get-RdsUserSession -TenantName $tenantName -HostPoolName $hostPoolName
                                    }
                                    catch {
                                        Write-Log 1 "Failed to retrieve list of user sessions in hostPool: $($hostPoolName) with error: $($_.exception.message)" "Error"
                                        exit 1
                                    }
                                    foreach ($session in $hostPoolUserSessions) {
                                        if ($session.sessionhostname -eq $sessionHost) {
                                            #log off user
                                            try {

                                                Invoke-RdsUserSessionLogoff -TenantName $tenantName -HostPoolName $hostPoolName -SessionHostName $session.sessionhostname -SessionId $session.sessionid -NoUserPrompt

                                                $existingSession = $existingSession - 1
                                            }
                                            catch {
                                                Write-Log 1 "Failed to log off user with error: $($_.exception.message)" "Error"
                                                exit 1
                                            }
                                        }
                                    }
                                }
                                
                              
                                #check the session count before shutting down the VM
                                if ($existingSession -eq 0) {

                                    #Check the Session host is in maintenance
                                    $VmInfo = Get-AzureRmVM | Where-Object { $_.Name -eq $VMName }
                                    if($VmInfo.Tags.Keys -contains $maintenanceTagName){
                                    Write-Log 1 "Session Host is in Maintenance: $($sessionHost | out-string)"
                                    $numberOfRunningHost = $numberOfRunningHost - 1
                                    Continue
                                    }
                                
                                    #shutdown the Azure VM
                                    try {
                                        Write-Log 1 "Stopping Azure VM: $($roleInstance.Name) and waiting for it to complete ..." "Info"
                                        Stop-AzureRmVM -Name $roleInstance.Name -Id $roleInstance.Id -Force -ErrorAction SilentlyContinue

                                    }
                                    catch {
                                        Write-Log 1 "Failed to stop Azure VM: $($roleInstance.Name) with error: $($_.exception.message)" "Error"
                                        exit 1
                                    }
                                    #wait for the VM to stop
                                    $IsVMStopped = $false
                                    while (!$IsVMStopped) {

                                        $vm = Get-AzureRmVM -Status | Where-Object { $_.Name -eq $roleInstance.Name }

                                        if ($vm.PowerState -eq "VM deallocated") {
                                            $IsVMStopped = $true
                                            Write-Log 1 "Azure VM has been stopped: $($roleInstance.Name) ..." "Info"
                                        }
                                        else {
                                            Write-Log 3 "Waiting for Azure VM to stop $($roleInstance.Name) ..." "Info"
                                        }
                                    }
                                    $getShsinfo = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostPoolName -Name $sessionHost
                                    if ($getShsinfo.UpdateState -eq "Succeeded") {
                                        # Ensure the Azure VMs that are off have Allow new connections mode set to True
                                        try {
                                            Set-RdsSessionHost -TenantName $tenantName -HostPoolName $hostPoolName -Name $sessionHost -AllowNewSession $true -ErrorAction SilentlyContinue
                                        }
                                        catch {
                                            Write-Log 1 "Unable to set it to allow connections on session host: $($sessionHost | Out-String) with error: $($_.exception.message)" "Error"
                                            exit 1
                                        }
                                    }
                                    $vm = Get-AzureRmVM -Status | Where-Object { $_.Name -eq $roleInstance.Name }
                                    $roleSize = Get-AzureRmVMSize -Location $roleInstance.Location | Where-Object { $_.Name -eq $roleInstance.HardwareProfile.VmSize }
                                    #decrement number of running session host
                                    $numberOfRunningHost = $numberOfRunningHost - 1
                                    $totalRunningCores = $totalRunningCores - $roleSize.NumberOfCores
                                }
                            }
                        }
                    }
                }
            }

        }        

        #Check whether minimumNoofRDSH Value stored dynamically and calculate minimumNoOfRDSh value
        if (Test-Path -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt) {
            [int]$MinimumNumberOfRDSH = Get-Content $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt
            $noConnectionsofhost = 0
            if ($numberOfRunningHost -le $MinimumNumberOfRDSH) {
                $MinimumNumberOfRDSH = $numberOfRunningHost
                $RDSessionHost = Get-RdsSessionHost -TenantName $tenantName -HostPoolName $hostPoolName | Sort-Object sessions | Sort-Object status
                foreach ($sHost in $RDSessionHost) {
                    if ($sHost.Status -eq "Available" -and $sHost.Sessions -eq 0) { 
                        $noConnectionsofhost = $noConnectionsofhost + 1 
                 
                    }
                }
                if ($noconnectionsofhost -gt $definedMinimumnumberofrdsh) {
                    [int]$MinimumNumberOfRDSH = [int]$MinimumNumberOfRDSH - $noConnectionsofhost
                    Clear-Content -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt
                    Set-Content -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt $MinimumNumberOfRDSH
                }
            }
        }
        #Calculate the how many sessions will allow in minimum number of RDSH VMs in off peak hours
        $HostpoolMaxSessionLimit = $hostpoolInfo.MaxSessionLimit
        $HostpoolSessionCount = (Get-RdsUserSession -TenantName $tenantName -HostPoolName $hostPoolName).count
        if ($HostpoolSessionCount -eq 0) {
            Write-Log 1 "HostpoolName:$hostpoolName, TotalRunningCores:$totalRunningCores NumberOfRunningHost:$numberOfRunningHost" "Info"
            #write to the usage log
            $depthBool = $false
            Write-UsageLog $hostPoolName $totalRunningCores $numberOfRunningHost $depthBool
            Write-Log 3 "End WVD Tenant Scale Optimization." "Info"
            break
        }
        else {
            #Calculate the how many sessions will allow in minimum number of RDSH VMs in off peak hours and calculate TotalAllowSessions Scale Factor
            $totalAllowSessionsinOffPeak = [int]$MinimumNumberOfRDSH * $HostpoolMaxSessionLimit
            $SessionsScaleFactor = $totalAllowSessionsinOffPeak * 0.90
            $ScaleFactor = [math]::Floor($SessionsScaleFactor)
     		
            if ($HostpoolSessionCount -ge $ScaleFactor) {
   
                #check if the available capacity meets the number of sessions or not
                Write-Log 1 "Current total number of user sessions: $HostpoolSessionCount" "Info"
                Write-Log 1 "Current available session capacity is less than demanded user sessions, starting session host" "Info"
                #running out of capacity, we need to start more VMs if there are any 
                foreach ($sessionHost in $RDSessionHost) {
                    $hostname = $sessionHost.SessionHostname | out-string
                    $VMName = $hostname.Split(".")[0]
                    
                    $VmInfo = Get-AzureRmVM | Where-Object { $_.Name -eq $VMName }
                    #Check the Session host is in maintenance
                    if($VmInfo.Tags.Keys -contains $maintenanceTagName){
                        Write-Log 1 "Session Host is in Maintenance: $hostname"
                        Continue
                        }
                    $roleInstance = Get-AzureRmVM -Status | Where-Object { $_.Name.Contains($VMName) }

                    if ($sessionHost.Status -eq "Available" -and $sessionHost.Sessions -eq 0) 
                    { break }
                    if ($hostname.ToLower().Contains($roleInstance.Name.ToLower())) {
                        #Check if the Azure VM is running and if the session host is healthy
                        $getShsinfo = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostPoolName -Name $sessionHost.SessionHostname
                        if ($roleInstance.PowerState -ne "VM running" -and $getShsinfo.UpdateState -eq "Succeeded") {
                            if ($getShsinfo.AllowNewSession -eq $false) {
                                Set-RdsSessionHost -TenantName $tenantName -HostPoolName $hostPoolName -Name $sessionHost.SessionHostname -AllowNewSession $true
                            }
                            #start the Azure VM
                            try {
								Write-Log 1 "Starting Azure VM: $($roleInstance.Name) and waiting for it to complete ..." "Info"
                                Start-AzureRmVM -Name $roleInstance.Name -Id $roleInstance.Id -ErrorAction SilentlyContinue
                            }
                            catch {
                                Write-Log 1 "Failed to start Azure VM: $($roleInstance.Name) with error: $($_.exception.message)" "Error"
                                exit 1
                            }
                            #wait for the VM to start
                            $IsVMStarted = $false
                            while (!$IsVMStarted) {
                                $vm = Get-AzureRmVM -Status | Where-Object { $_.Name -eq $roleInstance.Name }

                                if ($vm.PowerState -eq "VM running" -and $vm.ProvisioningState -eq "Succeeded") {
                                    $IsVMStarted = $true
                                    Write-Log 1 "Azure VM has been started: $($roleInstance.Name) ..." "Info"
                                }
                                else {
                                    Write-Log 3 "Waiting for Azure VM to start $($roleInstance.Name) ..." "Info"
                                }
                            }
                            # we need to calculate available capacity of sessions
                            $vm = Get-AzureRmVM -Status | Where-Object { $_.Name -eq $roleInstance.Name }
                            $roleSize = Get-AzureRmVMSize -Location $roleInstance.Location | Where-Object { $_.Name -eq $roleInstance.HardwareProfile.VmSize }
                            $AvailableSessionCapacity = $TotalAllowSessions + $hostpoolInfo.MaxSessionLimit
                            $numberOfRunningHost = $numberOfRunningHost + 1
                            $totalRunningCores = $totalRunningCores + $roleSize.NumberOfCores
                            Write-Log 1 "new available session capacity is: $AvailableSessionCapacity" "Info"

                            [int]$MinimumNumberOfRDSH = [int]$MinimumNumberOfRDSH + 1
                            if (!(Test-Path -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt)) {
                                New-Item -ItemType File -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt
                                Add-Content $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt $MinimumNumberOfRDSH
                            }
                            else {
                                Clear-Content -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt
                                Set-Content $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt $MinimumNumberOfRDSH
                            }
                            break
                        }
                        #Break # break out of the inner foreach loop once a match is found and checked
                    }
                }
            }

        }
      
        Write-Log 1 "HostpoolName:$hostpoolName, TotalRunningCores:$totalRunningCores NumberOfRunningHost:$numberOfRunningHost" "Info"
        #write to the usage log
        $depthBool = $false
        Write-UsageLog -hostpoolName $hostPoolName -corecount $totalRunningCores -vmcount $numberOfRunningHost -depthBool $depthBool
    } #Scale hostPool
    Write-Log 3 "End WVD Tenant Scale Optimization." "Info"
}
