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

#Function for convert current time from UTC to Local time
function ConvertUTCtoLocal {
    param(
        $TimeDifferenceInHours
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
Function to write logs of the scale script execution process.
#>
function Write-Log {
    param([string]$Message
        , [ValidateSet("Info", "Warning", "Error")] [string]$Severity = 'Info'
        , [string]$Logname = $WVDTenantlog
        , [string]$Color = "White"
    )
    $Time = ConvertUTCtoLocal -timeDifferenceInHours $TimeDifference
    Add-Content $Logname -Value ("{0} - [{1}] {2}" -f $Time, $Severity, $Message)
}

<#
.SYNOPSIS
Function to write logs on the usage of UserSessions & SessionHosts running at a particular time.
#>
function Write-UsageLog {
    param(
        [string]$HostpoolName,
        [int]$VMCount,
        [string]$LogFileName = $WVDTenantUsagelog
    )
    $Time = ConvertUTCtoLocal -TimeDifferenceInHours $TimeDifference 
    Add-Content $LogFileName -Value ("{0}, {1}, {2}" -f $Time, $HostpoolName, $VMCount)
}

<#
.SYNOPSIS
Function for creating a variable from JSON configurations
#>
function SetScriptVariable ($Name, $Value) {
    Invoke-Expression ("`$Script:" + $Name + " = `"" + $Value + "`"")
}

# Function to calculate scaleFactor for hostpool based on running hosts.
function Calculate-ScaleFactorForHostpool {
    param (
        $AllSessionHosts, 
        [int]$MaxSessionLimit,
        [double]$scaleFactor
    )
    $NumberOfRunningHost = ($AllSessionHosts | Where-Object { $_.Status -eq 'Available' }).count
    $UserSessionsLimit = [math]::Floor(($MaxSessionLimit * $NumberOfRunningHost) * $scaleFactor)
    Return $UserSessionsLimit
}

# Function to start VM 
function StartVM {
    param (
        $AllSessionHosts, 
        $MaintenanceTagName
    )
    try {
        [bool]$isSuccess = $false
        # loop through stopped session hosts to start vm and exit.
        foreach ($SessionHost in $AllSessionHosts | Where-Object { $_.Status -eq 'NoHeartBeat' } ) {
            
            # Checking the state whether is healthy or not before starting the VM.
            if ($SessionHost.UpdateState -eq "Succeeded") {
                $VMName = $SessionHost.SessionHostName.Split(".")[0]
                $VmInfo = Get-AzureRmVM | Where-Object { $_.Name -eq $VMName }
                
                # Checking whether session host is in maintenance or not to ignore the VMs in maintenance
                if ($VmInfo.Tags.Keys -contains $MaintenanceTagName) {
                    Write-Log "Session host '$VMName' is in MAINTENANCE phase, so this session host will be skipped."
                    Continue
                }

                # Check if the session host is allowing new connections 
                if (!($SessionHost.AllowNewSession)) {
                    Set-RdsSessionHost -TenantName $SessionHost.TenantName -HostPoolName $SessionHost.HostpoolName -Name $SessionHost.SessionHostName -AllowNewSession $true
                }

                # Start the VM
                try {
                    Write-Log "Starting Azure VM: $VMName and waiting for it to complete ..." "Info"
                    Start-AzureRmVM -Name $VMName -ResourceGroupName $VmInfo.ResourceGroupName
                }
                catch {
                    Write-Log "Failed to start Azure VM: $($VMName) with error: $($_.exception.message)" "Info"
                    exit
                }
                # Wait for the sessionhost is available
                $IsHostAvailable = $false
                while (!$IsHostAvailable) {
                    Write-Log "VM is starting... Waiting for it to complete..." "Info"
                    $SessionHostStatus = Get-RdsSessionHost -TenantName $SessionHost.TenantName -HostPoolName $SessionHost.HostpoolName -Name $SessionHost.SessionHostName
                    if ($SessionHostStatus.Status -eq "Available") {
                        $IsHostAvailable = $true
                        $isSuccess = $true
                        Write-Log "VM is Available" "Info"
                        break
                    }
                }
                [int]$MinimumNumberOfRDSH = [int]$MinimumNumberOfRDSH + 1

                # Adding the current running hosts count to text file to utilize in off peak hours logic
                if (!(Test-Path -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt)) {
                    New-Item -ItemType File -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt
                    Add-Content $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt $MinimumNumberOfRDSH
                }
                else {
                    Clear-Content -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt
                    Set-Content -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt $MinimumNumberOfRDSH
                }
                if ($IsHostAvailable) {
                    break
                }
            }
        }
    }
    catch {
        Write-Error "Error occurred when turning on VM : $($_.exception.message)"
        Write-Log "Error occurred when turning on VM : $($_.exception.message)" "Error"
        exit 1
    }
    Return $isSuccess
}

# Function to send alert messages to user sessions & turn off SessionHost during off-peak hours
function Send-UserSessionMessage-StopVM {
    param (
        $AllSessionHosts
    )
    try {
        [bool]$VMStoppedStatus = $false
        foreach ($SessionHost in $AllSessionHosts | Where-Object { $_.Status -eq 'Available' } ) {
            if ($NumberOfRunningHost -gt $minimumNumberOfRDSH) {
                # Setting session host to drain mode for blocking any new user connections before stopping.
                try {
                    Set-RdsSessionHost -TenantName $SessionHost.TenantName -HostPoolName $SessionHost.HostpoolName -Name $SessionHost.SessionHostName -AllowNewSession $false -ErrorAction SilentlyContinue
                }
                catch {
                    Write-Log "Unable to set session host : '$($SessionHost.SessionHostName)' to drain mode. Error occurred : '$($_.exception.message)'" "Info"
                    exit
                }
                $ExistingUserSessions = Get-RdsUserSession -TenantName $SessionHost.TenantName -HostPoolName $SessionHost.HostpoolName
                Write-Log "Currently there are : $($ExistingUserSessions.count) user sessions in '$($SessionHost.SessionHostName.split(".")[0])' session host" "Info"
                
                # Notify users to log off user session
                if ($ExistingUserSessions.count -gt 0) {
                    foreach ($userSession in $ExistingUserSessions) {
                        if ($LimitSecondsToForceLogOffUser -ne 0) {
                            # Send notification message to user session
                            try {
                                Send-RdsUserSessionMessage -TenantName $SessionHost.TenantName -HostPoolName $SessionHost.HostpoolName -SessionHostName $SessionHost.SessionHostName -SessionId $userSession.sessionid -MessageTitle $LogOffMessageTitle -MessageBody "$($LogOffMessageBody) You will logged off in $($LimitSecondsToForceLogOffUser) seconds." -NoUserPrompt
                            }
                            catch {
                                Write-Log "Failed to send alert message to user '$($userSession.UserPrincipalName)'. \n Error occurred: $($_.exception.message)" "Info"
                                exit
                            }
                        }
                    }
                }

                # Wait for specified number of seconds to log off user
                Start-Sleep -Seconds $LimitSecondsToForceLogOffUser
                $ExistingUserSessions = Get-RdsUserSession -TenantName $TenantName -HostPoolName $HostpoolName
                if ($ExistingUserSessions.count -gt 0) {
                    foreach ($userSession in $ExistingUserSessions) {
                        Invoke-RdsUserSessionLogoff -TenantName $TenantName -HostPoolName $HostpoolName -SessionHostName $userSession.SessionHostName -SessionId $userSession.sessionid -NoUserPrompt
                    }
                }
            
                $VMName = $SessionHost.SessionHostName.Split(".")[0]
                # Check the Session host is in maintenance
                $VmInfo = Get-AzureRmVM | Where-Object { $_.Name -eq $VMName }
                if ($VmInfo.Tags.Keys -contains $MaintenanceTagName) {
                    Write-Log "Session Host is in MAINTENANCE : $VMName"
                    $NumberOfRunningHost = $NumberOfRunningHost - 1
                    Continue
                }
                  
                # Shutdown the Azure VM
                try {
                    Write-Log "Stopping Azure VM: $VMName and waiting for it to complete ..." "Info"
                    Stop-AzureRmVM -Name $VMName -ResourceGroupName $VmInfo.ResourceGroupName -Force
                    $VMStoppedStatus = $true
                }
                catch {
                    Write-Log "Failed to stop Azure VM: $VMName with error: $($_.exception.message)" "Error"
                    exit
                }
            
                # Make the allow new sessions to true Ensure Azure VMs that are stopped have the allowing new connections state True
                try {
                    Set-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -Name $($SessionHost.SessionHostName) -AllowNewSession $true -ErrorAction SilentlyContinue
                    $NumberOfRunningHost = $NumberOfRunningHost - 1
                }
                catch {
                    Write-Log "Unable to set it to allow connections on session host: $($SessionHost.SessionHostName) with error: $($_.exception.message)" "Error"
                    exit 1
                }
            }
        }
    }
    catch {
        Write-Log "Error occurred while sending  message to user session error: $($_.exception.message)" "Error"
        exit 1
    }
    Return $VMStoppedStatus
}

function Get-AvailableSessionsCapacity {
    param (
        $AllSessionHosts
    )
    try {
        $AvailableSessionCapacity = 0;
        foreach ($SessionHost in $AllSessionHosts | Where-Object { $_.Status -eq 'Available' }) {
            Write-Log "Checking session host : '$($SessionHost.SessionHostName)' has $($SessionHost.Sessions) user sessions" "Info"
            $VMName = $SessionHost.SessionHostName.Split(".")[0]
            $VmInfo = Get-AzureRmVM | Where-Object { $_.Name -eq $VMName }
            
            # Check the Session host is in maintenance
            if ($VmInfo.Tags.Keys -contains $MaintenanceTagName) {
                Write-Log "Session Host is in Maintenance: $($SessionHost.SessionHostName)"
                Continue
            }
            $RoleInstance = Get-AzureRmVM -Status | Where-Object { $_.Name.Contains($VMName) }
            if ($SessionHost.SessionHostName.ToLower().Contains($RoleInstance.Name.ToLower())) {
                # Check if the azure vm is running
                if ($RoleInstance.PowerState -eq "VM running") {
                    [int]$NumberOfRunningHost = [int]$NumberOfRunningHost + 1
                    # Calculate available capacity of sessions based on number of cores & sessionThresholdPerCPU
                    $RoleSize = Get-AzureRmVMSize -Location $RoleInstance.Location | Where-Object { $_.Name -eq $RoleInstance.HardwareProfile.VmSize }
                    $AvailableSessionCapacity = $AvailableSessionCapacity + $RoleSize.NumberOfCores * $SessionThresholdPerCPU
                }
            }
        }
    }
    catch {
        Write-Log "Unable to set it to allow connections on session host: $($SessionHost.SessionHostName) with error: $($_.exception.message)" "Error"
        exit
    }
    Return $AvailableSessionCapacity
}

function Execute-DepthFirstPeakHoursLogic {
    param (
        $AllSessionHosts
    )
    # For depthFirst hostpool the scale factor to turn on one more session host is if user sessions >= 80%.
    $ScaleFactor = 0.8

    # Function to calculate existing user session limit for a hostpool based on running hosts & MaxSessionLimit
    $UserSessionsLimitInPeakHours = Calculate-ScaleFactorForHostpool -AllSessionHosts $AllSessionHosts -MaxSessionLimit $HostpoolInfo.MaxSessionLimit -scaleFactor $ScaleFactor
    Write-Log "Available userSession limit : $UserSessionsLimitInPeakHours"

    # Check the number of running session hosts
    $NumberOfRunningHost = ($AllSessionHosts | Where-Object { $_.Status -eq 'Available' }).count
    Write-Log "Current number of running hosts: $NumberOfRunningHost" "Info"

    if ($NumberOfRunningHost -lt $MinimumNumberOfRDSH) {
        Write-Log "Current number of running session hosts is less than minimum requirements, start session host ..." "Info"
        # Function to start VM. 
        $isSuccess = StartVM -AllSessionHosts $AllSessionHosts -MaintenanceTagName $MaintenanceTagName
        if ($isSuccess) {
            $NumberOfRunningHost = $NumberOfRunningHost + 1
        }
    }

    else {
        $NoOfSessionsConnected = (Get-RdsUserSession -TenantName $TenantName -HostPoolName $HostpoolName).count
        if ($NoOfSessionsConnected -ge $UserSessionsLimitInPeakHours) {
            # Function to start VM if more than 80% user sessions are connected. 
            $isSuccess = StartVM -AllSessionHosts $AllSessionHosts -MaintenanceTagName $MaintenanceTagName
            if ($isSuccess) {
                $NumberOfRunningHost = $NumberOfRunningHost + 1
            }
        }
    }
}

function Execute-DepthFirstOffPeakHoursLogic {
    param (
        $AllSessionHosts
    )
    # Check the number of running session hosts
    $NumberOfRunningHost = ($AllSessionHosts | Where-Object { $_.Status -eq 'Available' }).count
    # Defined minimum no of rdsh value from JSON file
    [int]$DefinedMinimumNumberOfRDSH = $MinimumNumberOfRDSH 

    # Collecting the current off-peak hours MinimumNoOfRDSH value from text file which is generated based on off-peak hours usage.
    if (Test-Path -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt) {
        [int]$MinimumNumberOfRDSH = Get-Content $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt
    }

    if ($NumberOfRunningHost -gt $MinimumNumberOfRDSH) {
        $VMStoppedStatus = Send-UserSessionMessage-StopVM -AllSessionHosts $AllSessionHosts
        if ($VMStoppedStatus) {
            $NumberOfRunningHost = $NumberOfRunningHost - 1
        }
    }
    # Check whether minimumNoofRDSH Value stored dynamically
    if (Test-Path -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt) {
        [int]$MinimumNumberOfRDSH = Get-Content $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt
        $NoConnectionsofhost = 0
        if ($NumberOfRunningHost -le $MinimumNumberOfRDSH) {
            $NoConnectionsofhost = ($AllSessionHosts | Where-Object { $_.Status -eq 'Available' }).count 
            if ($NoConnectionsofhost -gt $DefinedMinimumNumberOfRDSH) {
                [int]$MinimumNumberOfRDSH = [int]$MinimumNumberOfRDSH - $NoConnectionsofhost
                Clear-Content -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt
                Set-Content -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt $MinimumNumberOfRDSH
            }
        }
    }
    $HostpoolSessionCount = (Get-RdsUserSession -TenantName $TenantName -HostPoolName $HostpoolName).count
    if ($HostpoolSessionCount -eq 0) {
        Write-Log "HostpoolName:$HostpoolName, NumberofRunnighosts:$NumberOfRunningHost" "Info"
        #write to the usage log					   
        Write-UsageLog -HostpoolName $HostpoolName -VMCount $NumberOfRunningHost
        Write-Log "End WVD Tenant Scale Optimization." "Info"
        break
    }
    else {
        # Scale factor to check no. of user sessions limit during off-peak hours to turn on another Session Host pro-actively
        $ScaleFactor = 0.9
        # Function to calculate scaleFactor for a hostpool based on running hosts & MaxSessionLimit
        $UserSessionsLimitInOffPeakHours = Calculate-ScaleFactorForHostpool -AllSessionHosts $AllSessionHosts -MaxSessionLimit $HostpoolInfo.MaxSessionLimit -scaleFactor $ScaleFactor
        if ($HostpoolSessionCount -ge $UserSessionsLimitInOffPeakHours) {
            # Function to start VM if more than 90% sessions are connected. 
            $isSuccess = StartVM -AllSessionHosts $AllSessionHosts -MaintenanceTagName $MaintenanceTagName
            if ($isSuccess) {
                $NumberOfRunningHost = $NumberOfRunningHost + 1
            }
        }
        Write-Log "HostpoolName:$HostpoolName, NumberofRunnighosts:$NumberOfRunningHost" "Info"
        Write-UsageLog -HostPoolName $HostpoolName -VMCount $NumberOfRunningHost
    }
    
}

function Execute-BreadthFirstPeakHoursLogic {
    param (
        $AllSessionHosts
    )
    # Get the Session Hosts in the hostPool		
    if ($AllSessionHosts -eq $null) {
        Write-Log "Sessionhosts does not exist in the Hostpool of '$HostpoolName'. Ensure that hostpool have hosts or not?." "Info"
        exit
    }
    # Check and Remove the MinimumnoofRDSH value dynamically stored file												   
    if (Test-Path -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt) {
        Remove-Item -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt
    }
    # Check the number of running session hosts
    $NumberOfRunningHost = ($AllSessionHosts | Where-Object { $_.Status -eq 'Available' }).count
    # Function to get TotalCapacity of user sessions available for all running hosts
    $AvailableSessionCapacity = Get-AvailableSessionsCapacity -AllSessionHosts $AllSessionHosts
    
    Write-Log "Current number of running hosts:$NumberOfRunningHost" "Info"
    if ($NumberOfRunningHost -lt $MinimumNumberOfRDSH) {
        Write-Log "Current number of running session hosts is less than minimum requirements, start session host ..." "Info"

        $isSuccess = StartVM -AllSessionHosts $AllSessionHosts -MaintenanceTagName $MaintenanceTagName
        if ($isSuccess) {
            $NumberOfRunningHost = $NumberOfRunningHost + 1
            $AllSessionHosts = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -ErrorAction SilentlyContinue | Sort-Object SessionHostName
        }
    }
    else {
        #check if the available capacity meets the number of sessions or not
        Write-Log "Current available session capacity is: $AvailableSessionCapacity" "Info"

        try {
            $HostPoolUserSessions = Get-RdsUserSession -TenantName $TenantName -HostPoolName $HostpoolName
        }
        catch {
            Write-Log "Failed to retrieve user sessions in hostPool:$($HostpoolName) with error: $($_.exception.message)" "Error"
            exit 1
        }
        Write-Log "Current total number of user sessions: $($HostPoolUserSessions.Count)" "Info"

        if ($HostPoolUserSessions.Count -ge $AvailableSessionCapacity) {
            Write-Log "The current user sessions are more then the specified user sessions capacity. So new session host is getting started." "Info"
            $isSuccess = StartVM -AllSessionHosts $AllSessionHosts -MaintenanceTagName $MaintenanceTagName
            if ($isSuccess) {
                $AllSessionHosts = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -ErrorAction SilentlyContinue | Sort-Object SessionHostName
                $AvailableSessionCapacity = Get-AvailableSessionsCapacity -AllSessionHosts $AllSessionHosts
            }
            else {
                exit
            }
        }
    }
}

function Execute-BreadthFirstOffPeakHoursLogic {
    param (
        $AllSessionHosts
    )
    
    # Check the number of running session hosts
    $NumberOfRunningHost = ($AllSessionHosts | Where-Object { $_.Status -eq 'Available' }).count

    # Total number of running cores
    $TotalRunningCores = 0
    
    # Defined minimum no of rdsh value from JSON file
    [int]$DefinedMinimumNumberOfRDSH = $MinimumNumberOfRDSH
    
    # Check and Collecting dynamically stored MinimumNoOfRDSH Value																 
    if (Test-Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt) {
        [int]$MinimumNumberOfRDSH = Get-Content $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt
    }

    if ($NumberOfRunningHost -gt $MinimumNumberOfRDSH) {

        # Shutdown VM to meet the minimum requirement
        $VMStoppedStatus = Send-UserSessionMessage-StopVM -AllSessionHosts $AllSessionHosts
        if ($VMStoppedStatus) {
            $NumberOfRunningHost = $NumberOfRunningHost - 1
        }
        else {
            exit
        }
            
        $SessionHostInfo = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -Name $SessionHost
        if ($SessionHostInfo.UpdateState -eq "Succeeded") {
            # Ensure the Azure VMs that are off have Allow new connections mode set to True
            try {
                Set-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -Name $SessionHost -AllowNewSession $true -ErrorAction SilentlyContinue
            }
            catch {
                Write-Log "Unable to set it to allow connections on session host: $($SessionHost | Out-String) with error: $($_.exception.message)" "Error"
                exit 1
            }
        }
        $RoleSize = Get-AzureRmVMSize -Location $RoleInstance.Location | Where-Object { $_.Name -eq $RoleInstance.HardwareProfile.VmSize }
        $NumberOfRunningHost = $NumberOfRunningHost - 1
    }

    # Check whether minimumNoOfRDSH Value stored dynamically
    if (Test-Path -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt) {
        [int]$MinimumNumberOfRDSH = Get-Content $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt
        $NoConnectionsofhost = 0
        if ($NumberOfRunningHost -le $MinimumNumberOfRDSH) {
            $MinimumNumberOfRDSH = $NumberOfRunningHost
            $NoConnectionsofhost = ($AllSessionHosts | Where-Object { $_.Status -eq 'Available' }).count 
            if ($NoConnectionsofhost -gt $DefinedMinimumNumberOfRDSH) {
                [int]$MinimumNumberOfRDSH = [int]$MinimumNumberOfRDSH - $NoConnectionsofhost
                Clear-Content -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt
                Set-Content -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt $MinimumNumberOfRDSH
            }
        }
    }
    $HostpoolSessionCount = (Get-RdsUserSession -TenantName $TenantName -HostPoolName $HostpoolName).count
    if ($HostpoolSessionCount -eq 0) {
        Write-Log "HostpoolName:$HostpoolName, NumberOfRunningHost:$NumberOfRunningHost" "Info"
        # Write to the usage log
        Write-UsageLog -HostpoolName $HostpoolName -VMCount $NumberOfRunningHost
        Write-Log "End WVD Tenant Scale Optimization." "Info"
        break
    }
    else {

        # Scale factor to check no. of user sessions limit during off-peak hours to turn on another Session Host pro-actively
        $ScaleFactor = 0.9

        # Function to calculate scaleFactor for a hostpool based on running hosts & MaxSessionLimit
        $UserSessionsLimitInOffPeakHours = Calculate-ScaleFactorForHostpool -AllSessionHosts $AllSessionHosts -MaxSessionLimit $HostpoolInfo.MaxSessionLimit -scaleFactor $ScaleFactor
        if ($HostpoolSessionCount -ge $UserSessionsLimitInOffPeakHours) {

            # Function to start VM if more than 90% sessions are connected. 
            $isSuccess = StartVM -AllSessionHosts $AllSessionHosts -MaintenanceTagName $MaintenanceTagName
            if ($isSuccess) {
                $NumberOfRunningHost = $NumberOfRunningHost + 1
                
                # Calculate available capacity of sessions
                $RoleSize = Get-AzureRmVMSize -Location $RoleInstance.Location | Where-Object { $_.Name -eq $RoleInstance.HardwareProfile.VmSize }
                $AvailableSessionCapacity = $TotalAllowSessions + $HostpoolInfo.MaxSessionLimit
                $TotalRunningCores = $TotalRunningCores + $RoleSize.NumberOfCores
                Write-Log "New available session capacity is: $AvailableSessionCapacity" "Info"

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
        }
    }
}

$CurrentPath = Split-Path $script:MyInvocation.MyCommand.Path

#Json path
$JsonPath = "$CurrentPath\Config-MSI.Json"

#Log path
$WVDTenantlog = "$CurrentPath\WVDTenantScale.log"

#usage log path
$WVDTenantUsagelog = "$CurrentPath\WVDTenantUsage.log"

Write-Log "------------------Started Executing the scale script at : $(Get-Date) ------------------" "Info"
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
        Write-Log "$JsonPath is invalid. Check Json syntax - Unable to proceed" "Error"
        exit 1
    }
}
else {
    #$Validate = $false
    Write-Error "Missing $JsonPath - Unable to proceed"
    Write-Log "Missing $JsonPath - Unable to proceed" "Error"
    exit 1
}
##### Load Json Configuration values as variables #########
Write-Verbose "Loading values from Config.Json"
$Variable.WVDScale.Azure | ForEach-Object { $_.Variable } | Where-Object { $_.Name -ne $null } | ForEach-Object { SetScriptVariable -Name $_.Name -Value $_.Value }
$Variable.WVDScale.WVDScaleSettings | ForEach-Object { $_.Variable } | Where-Object { $_.Name -ne $null } | ForEach-Object { SetScriptVariable -Name $_.Name -Value $_.Value }
$Variable.WVDScale.Deployment | ForEach-Object { $_.Variable } | Where-Object { $_.Name -ne $null } | ForEach-Object { SetScriptVariable -Name $_.Name -Value $_.Value }

##### Get current time  #####
$CurrentDateTime = ConvertUTCtoLocal -TimeDifferenceInHours $TimeDifferenceInHours

# Checking if the WVD Modules are existed
$WVDModules = Get-InstalledModule -Name "Microsoft.RDInfra.RDPowershell" -ErrorAction SilentlyContinue
if (!$WVDModules) {
    Write-Log "WVD Modules doesn't exist. Ensure WVD Modules are installed if not execute this command 'Install-Module Microsoft.RDInfra.RDPowershell  -AllowClobber' "
    exit
}

Import-Module "Microsoft.RDInfra.RDPowershell"
$IsServicePrincipalBool = ($IsServicePrincipal -eq "True")

# MSI based authentication
#    - In order to rely on this, please add the MSI accounts as VM contributors at subscription level
Add-AzureRmAccount -Identity

# Select the current Azure Subscription specified in the config
Select-AzureRmSubscription -SubscriptionId $CurrentAzureSubscriptionId

# Authenticating to WVD
# Building credentials from KeyVault
$WVDServicePrincipalPwd = (Get-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $KeyVaultSecretName).SecretValue
$WVDCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList($Username, $WVDServicePrincipalPwd)

if (!$IsServicePrincipalBool) {
    # If standard account is provided login in WVD with that account 
    try {
        $Authentication = Add-RdsAccount -DeploymentUrl $RDBroker -Credential $WVDCreds
    }
    catch {
        Write-Log "Failed to authenticate with WVD Tenant with standard account: $($_.exception.message)" "Error"
        exit 1

    }
    $Obj = $Authentication | Out-String
    Write-Log "Authenticating as standard account for WVD. Result: `n$Obj" "Info"
}
else {
    # If service principal account is provided login in WVD with that account 
    try {
        $Authentication = Add-RdsAccount -DeploymentUrl $RDBroker -TenantId $AADTenantId -Credential $WVDCreds -ServicePrincipal
    }
    catch {
        Write-Log "Failed to authenticate with WVD Tenant with the service principal: $($_.exception.message)" "Error"
        exit 1
    }
    $Obj = $Authentication | Out-String
    Write-Log "Authenticating as service principal account for WVD. Result: `n$Obj" "Info"
}

# Set context to the appropriate tenant group
$CurrentTenantGroupName = (Get-RdsContext).TenantGroupName
if ( $TenantGroupName -ne $CurrentTenantGroupName ) {
    Write-Log "Running switching to the $TenantGroupName context" "Info"
    Set-RdsContext -TenantGroupName $TenantGroupName
}      

# Adding PeakHours Begin & End Time for today.
$BeginPeakDateTime = Get-Date $BeginPeakTime
$EndPeakDateTime = Get-Date $EndPeakTime

# Checking given host pool name exists in Tenant
$HostpoolInfo = Get-RdsHostPool -TenantName $TenantName -Name $HostpoolName
if ($HostpoolInfo -eq $null) {
    Write-Log "Hostpoolname '$HostpoolName' does not exist in the tenant of '$TenantName'. Ensure that you have entered the correct values." "Info"
    exit
}	
        
# Checking whether current time is in peak hours or not and updating LoadBalancerType accordingly based on the PeakLoadBalancingType mentioned in configurations.
if ($CurrentDateTime -ge $BeginPeakDateTime -and $CurrentDateTime -le $EndPeakDateTime) {
    Write-Log "Script execution is in PeakHours, current time is : $CurrentDateTime and loadBalancerType should be : '$PeakLoadBalancingType'"
    if ($HostpoolInfo.LoadBalancerType -eq 'BreadthFirst' -and $PeakLoadBalancingType -eq 'DepthFirst') {
        Write-Log "Modifying hostpool LoadBalanceType to : '$PeakLoadBalancingType'" "Info"
        $HostpoolInfo = Set-RdsHostPool -TenantName $TenantName -Name $HostpoolName -DepthFirstLoadBalancer -MaxSessionLimit $HostpoolInfo.MaxSessionLimit
    }
    else {
        $HostpoolInfo = Set-RdsHostPool -TenantName $TenantName -Name $HostpoolName -BreadthFirstLoadBalancer
    }
    Write-Log "Hostpool LoadBalancerType is changed to '$($HostpoolInfo.LoadBalancerType)' during Peak Hours."
}
elseif ($HostpoolInfo.LoadBalancerType -eq 'BreadthFirst' -and $PeakLoadBalancingType -eq 'DepthFirst') {
    Write-Log "Script execution is in Off-Peak Hours, current time is : $CurrentDateTime and loadBalancerType should not be : $PeakLoadBalancingType"
    $HostpoolInfo = Set-RdsHostPool -TenantName $TenantName -Name $HostpoolName -DepthFirstLoadBalancer -MaxSessionLimit $HostpoolInfo.MaxSessionLimit
}
else {
    $HostpoolInfo = Set-RdsHostPool -TenantName $TenantName -Name $HostpoolName -BreadthFirstLoadBalancer
}
Write-Log "Hostpool LoadBalancerType in Off-Peak hours is : '$($HostpoolInfo.LoadBalancerType)' Load Balancing"

Write-Log "--------Starting WVD Tenant Hosts Scale Optimization: Current Date Time is: $CurrentDateTime --------" "Info"
Write-Log ("Processing hostPool {0}" -f $HostpoolName) "Info"
if ($HostpoolInfo.LoadBalancerType -eq "DepthFirst") {
    Write-Log "$HostpoolName hostpool loadbalancer type is $($HostpoolInfo.LoadBalancerType)" "Info"
    $AllSessionHosts = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -ErrorAction SilentlyContinue | Sort-Object SessionHostName

    # Checking the current time to see whether it is in Peak hours/ Off-Peak hours
    # Depth First : Peak hours logic
    if ($CurrentDateTime -ge $BeginPeakDateTime -and $CurrentDateTime -le $EndPeakDateTime) {
        Write-Log "It is in DepthFirst peak hours now" "Info"
        # Check dynamically created OffPeakUsage-MinimumNoOfRDSH text file while turning on VMs during Off-Peak hours based on increase in user sessions 
        # Remove it in peak hours.
        if (Test-Path -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt) {
            Remove-Item -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt
        }

        # Get all session hosts in the hostpool
        if ($AllSessionHosts -eq $null) {
            Write-Log "Session hosts does not exist in this Hostpool of '$HostpoolName'. Ensure that hostpool have hosts or not?." "Info"
            exit
        }

        # Function call to execute DepthFirst peak hours logic
        Execute-DepthFirstPeakHoursLogic -AllSessionHosts $AllSessionHosts
        Write-Log "HostpoolName:$HostpoolName, NumberofRunnighosts:$NumberOfRunningHost" "Info"
        Write-UsageLog -HostPoolName $HostpoolName -VMCount $NumberOfRunningHost
        Write-Log "End of WVD Tenant Scale Optimization during DepthFirst peak hours." "Info"
    }

    # Depth First : Off-Peak hours logic
    else {
        Write-Log "It is Off-peak hours" "Info"
        Write-Log "It is off-peak hours. Starting to scale down RD session hosts..." "Info"
        # Get all session hosts in the host pool
        if ($AllSessionHosts -eq $null) {
            Write-Log "Sessionhosts does not exist in the Hostpool of '$HostpoolName'. Ensure that hostpool have hosts or not?." "Info"
            exit
        }
        # Function call to execute DepthFirst Off-Peak hours logic
        Execute-DepthFirstOffPeakHoursLogic -AllSessionHosts $AllSessionHosts
        Write-Log "End of WVD Tenant Scale Optimization during DepthFirst Off-Peak hours." "Info"
    }
}
else {
    # Given hostpool is BreadthFirst LoadBalancerType
    Write-Log "$HostpoolName hostpool loadbalancer type is '$($HostpoolInfo.LoadBalancerType)'" "Info"
    
    # Get the Session Hosts in the hostPool
    $AllSessionHosts = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -ErrorAction SilentlyContinue | Sort-Object SessionHostName

    # Checking the current time to see whether it is in Peak hours/ Off-Peak hours
    if ($CurrentDateTime -ge $BeginPeakDateTime -and $CurrentDateTime -le $EndPeakDateTime) {
        Write-Log "It is in peak hours now" "Info"
        # Function call to execute BreadthFirst Peak hours logic
        Execute-BreadthFirstPeakHoursLogic -AllSessionHosts $AllSessionHosts
        Write-Log "HostpoolName : '$HostpoolName' and currently running hosts : '$NumberOfRunningHost'" "Info"
        # Write to the usage log
        Write-UsageLog -HostpoolName $HostpoolName -VMCount $NumberOfRunningHost
        Write-Log "End of WVD Tenant Scale Optimization during BreadthFirst peak hours." "Info"
    }
    else {
        Write-Log "It is Off-peak hours" "Info"
        Write-Log "It is off-peak hours. Starting to scale down RD session hosts..." "Info"
        Write-Log "Processing hostPool $($HostpoolName)"
        # Check the sessionhosts are exist in the hostpool
        if ($AllSessionHosts -eq $null) {
            Write-Log "Sessionhosts does not exist in the Hostpool of '$HostpoolName'. Ensure that hostpool have hosts or not?." "Info"
            exit
        }

        # Function call to execute BreadthFirst Off-Peak hours logic
        Execute-BreadthFirstOffPeakHoursLogic -AllSessionHosts $AllSessionHosts
        Write-Log "HostpoolName:$HostpoolName, TotalRunningCores:$TotalRunningCores NumberOfRunningHost:$NumberOfRunningHost" "Info"
        # Write to the usage log
        Write-UsageLog -HostpoolName $HostpoolName -VMCount $NumberOfRunningHost
        Write-Log "End of WVD Tenant Scale Optimization during BreadthFirst Off-Peak hours." "Info"
    }
}
Write-Log "------------------END of Executing the scale script at $(Get-Date) ------------------" "Info"