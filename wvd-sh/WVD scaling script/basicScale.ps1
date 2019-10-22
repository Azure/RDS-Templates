<#
Copyright 2019 Microsoft
Version 2.0 March 2019
.SYNOPSIS
This is a sample script for automatically scaling Tenant Environment WVD Host Servers in Microsoft Azure
.Description
This script will start/stop Tenant WVD host VMs based on the number of user sessions and peak/off-peak time period specified in the configuration file.
During the peak hours, the script will start necessary session hosts in the Hostpool to meet the demands of users.
During the off-peak hours, the script will shut down session hosts and only keep the minimum number of session hosts.
This script depends on two PowerShell modules: Azure RM and Windows Virtual Desktop modules. To install Azure RM module and WVD Module execute the following commands. Use "-AllowClobber" parameter if you have more than one version of PowerShell modules installed.
PS C:\>Install-Module AzureRM  -AllowClobber
PS C:\>Install-Module Microsoft.RDInfra.RDPowershell  -AllowClobber
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#Function for convert from UTC to Local time
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
  return $ConvertedTime
}


<#
.SYNOPSIS
Function for writing the log
#>
function Write-Log {
  param(
    [int]$Level
    ,[string]$Message
    ,[ValidateSet("Info","Warning","Error")] [string]$Severity = 'Info'
    ,[string]$Logname = $WVDTenantlog
    ,[string]$Color = "White"
  )
  $Time = ConvertUTCtoLocal -TimeDifferenceInHours $TimeDifference
  Add-Content $Logname -Value ("{0} - [{1}] {2}" -f $Time,$Severity,$Message)
  if ($interactive) {
    switch ($Severity) {
      'Error' { $Color = 'Red' }
      'Warning' { $Color = 'Yellow' }
    }
    if ($Level -le $VerboseLogging) {
      if ($Color -match "Red|Yellow") {
        Write-Output ("{0} - [{1}] {2}" -f $Time,$Severity,$Message) -ForegroundColor $Color -BackgroundColor Black
        if ($Severity -eq 'Error') {

          throw $Message
        }
      }
      else {
        Write-Output ("{0} - [{1}] {2}" -f $Time,$Severity,$Message) -ForegroundColor $Color
      }
    }
  }
  else {
    switch ($Severity) {
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
    [string]$HostpoolName,
    [int]$Corecount,
    [int]$VMCount,
    [bool]$DepthBool = $True,
    [string]$LogFileName = $WVDTenantUsagelog
  )
  $Time = ConvertUTCtoLocal -TimeDifferenceInHours $TimeDifference
  if ($DepthBool) {
    Add-Content $LogFileName -Value ("{0}, {1}, {2}" -f $Time,$HostpoolName,$VMCount)
  }



  else {

    Add-Content $LogFileName -Value ("{0}, {1}, {2}, {3}" -f $Time,$HostpoolName,$Corecount,$VMCount)
  }
}
<#
.SYNOPSIS
Function for creating a variable from JSON
#>
function SetScriptVariable ($Name,$Value) {
  Invoke-Expression ("`$Script:" + $Name + " = `"" + $Value + "`"")
}

$CurrentPath = Split-Path $script:MyInvocation.MyCommand.Path

##### Json path #####
$JsonPath = "$CurrentPath\Config.Json"

##### Log path #####
$WVDTenantlog = "$CurrentPath\WVDTenantScale.log"

##### Usage log path #####
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
$Variable.WVDScale.Azure | ForEach-Object { $_.Variable } | Where-Object { $_.Name -ne $null } | ForEach-Object { Set-ScriptVariable -Name $_.Name -Value $_.Value }
$Variable.WVDScale.WVDScaleSettings | ForEach-Object { $_.Variable } | Where-Object { $_.Name -ne $null } | ForEach-Object { Set-ScriptVariable -Name $_.Name -Value $_.Value }
$Variable.WVDScale.Deployment | ForEach-Object { $_.Variable } | Where-Object { $_.Name -ne $null } | ForEach-Object { Set-ScriptVariable -Name $_.Name -Value $_.Value }
##### Construct Begin time and End time for the Peak period from utc to local time #####
$TimeDifference = [string]$TimeDifferenceInHours
$CurrentDateTime = ConvertUTCtoLocal -TimeDifferenceInHours $TimeDifference

##### Load functions/module #####
. $CurrentPath\Functions-PSStoredCredentials.ps1
# Checking if the WVD Modules are existed
$WVDModules = Get-InstalledModule -Name "Microsoft.RDInfra.RDPowershell" -ErrorAction SilentlyContinue
if (!$WVDModules) {
  Write-Log 1 "WVD Modules doesn't exist. Ensure WVD Modules are installed if not execute this command 'Install-Module Microsoft.RDInfra.RDPowershell  -AllowClobber'"
  exit
}
Import-Module "Microsoft.RDInfra.RDPowershell"
##### Login with delegated access in WVD tenant #####
$Credential = Get-StoredCredential -UserName $Username

$isWVDServicePrincipal = ($isWVDServicePrincipal -eq "True")
##### Check if service principal or user account is being used for WVD #####
if (!$isWVDServicePrincipal) {
  ##### If standard account is provided login in WVD with that account #####
  try {
    $Authentication = Add-RdsAccount -DeploymentUrl $RDBroker -Credential $Credential
  }
  catch {
    Write-Log 1 "Failed to authenticate with WVD Tenant with a standard account: $($_.exception.message)" "Error"
    exit 1
  }
  $Obj = $Authentication | Out-String
  Write-Log 3 "Authenticating as standard account for WVD. Result: `n$obj" "Info"
}
else {
  ##### When service principal account is provided login in WVD with that account #####

  try {
    $authentication = Add-RdsAccount -DeploymentUrl $RDBroker -TenantId $AADTenantId -Credential $Credential -ServicePrincipal
  }
  catch {
    Write-Log 1 "Failed to authenticate with WVD Tenant with the service principal: $($_.exception.message)" "Error"
    exit 1
  }
  $Obj = $Authentication | Out-String
  Write-Log 3 "Authenticating as service principal account for WVD. Result: `n$obj" "Info"
}

##### Authenticating to Azure #####
$AppCreds = Get-StoredCredential -UserName $AADApplicationId
try {
  $Authentication = Add-AzureRmAccount -SubscriptionId $currentAzureSubscriptionId -Credential $AppCreds
}
catch {
  Write-Log 1 "Failed to authenticate with Azure with a standard account: $($_.exception.message)" "Error"
  exit 1
}

##### Set context to the appropriate tenant group #####
#Set context to the appropriate tenant group
$CurrentTenantGroupName = (Get-RdsContext).TenantGroupName
if ($TenantGroupName -ne $CurrentTenantGroupName) {
  Write-Log 1 "Running switching to the $TenantGroupName context" "Info"
  Set-RdsContext -TenantGroupName $TenantGroupName
}


##### select the current Azure subscription specified in the config #####
Select-AzureRmSubscription -SubscriptionId $CurrentAzureSubscriptionId

# Converting Datetime format
$BeginPeakDateTime = [datetime]::Parse($CurrentDateTime.ToShortDateString() + ' ' + $BeginPeakTime)
$EndPeakDateTime = [datetime]::Parse($CurrentDateTime.ToShortDateString() + ' ' + $EndPeakTime)

#Checking given host pool name exists in Tenant
$HostpoolInfo = Get-RdsHostPool -TenantName $TenantName -Name $HostpoolName
if ($HostpoolInfo -eq $null) {
    Write-Log 1 "Hostpoolname '$HostpoolName' does not exist in the tenant of '$TenantName'. Ensure that you have entered the correct values." "Info"
    exit
}	
        
#Compare beginpeaktime and endpeaktime hours and setting up appropriate load balacing type based on PeakLoadBalancingType
if ($CurrentDateTime -ge $BeginPeakDateTime -and $CurrentDateTime -le $EndPeakDateTime) {

    if ($HostpoolInfo.LoadBalancerType -ne $PeakLoadBalancingType) {
        Write-Log 3 "Changing Hostpool Load Balance Type:$PeakLoadBalancingType Current Date Time is: $CurrentDateTime" "Info"

        if ($PeakLoadBalancingType -eq "DepthFirst") {                
            Set-RdsHostPool -TenantName $TenantName -Name $HostpoolName -DepthFirstLoadBalancer -MaxSessionLimit $HostpoolInfo.MaxSessionLimit
        }
        else {
            Set-RdsHostPool -TenantName $TenantName -Name $HostpoolName -BreadthFirstLoadBalancer -MaxSessionLimit $HostpoolInfo.MaxSessionLimit
        }
        Write-Log 3 "Hostpool Load balancer Type in Session Load Balancing Peak Hours is '$PeakLoadBalancingType Load Balancing'"
    }
}
else{
    if ($HostpoolInfo.LoadBalancerType -eq $PeakLoadBalancingType) {
        Write-Log 3 "Changing Hostpool Load Balance Type in off peak hours. Current Date Time is: $CurrentDateTime" "Info"
        
        if ($hostpoolinfo.LoadBalancerType -ne "DepthFirst") {                
            $LoadBalanceType = Set-RdsHostPool -TenantName $TenantName -Name $HostpoolName -DepthFirstLoadBalancer -MaxSessionLimit $HostpoolInfo.MaxSessionLimit

         }else{
            $LoadBalanceType = Set-RdsHostPool -TenantName $TenantName -Name $HostpoolName -BreadthFirstLoadBalancer -MaxSessionLimit $HostpoolInfo.MaxSessionLimit
        }
        $LoadBalancerType = $LoadBalanceType.LoadBalancerType
        Write-Log 3 "Hostpool Load balancer Type in off Peak Hours is '$LoadBalancerType Load Balancing'"
    }
  }
     


Write-Log 3 "Starting WVD Tenant Hosts Scale Optimization: Current Date Time is: $CurrentDateTime" "Info"

#Check the after changing hostpool loadbalancer type
$HostpoolInfo = Get-RdsHostPool -TenantName $tenantName -Name $hostPoolName
if ($HostpoolInfo.LoadBalancerType -eq "DepthFirst") {

  Write-Log 1 "$HostpoolName hostpool loadbalancer type is $($HostpoolInfo.LoadBalancerType)" "Info"

  #Gathering hostpool maximum session and calculating Scalefactor for each host.										  
  $HostpoolMaxSessionLimit = $HostpoolInfo.MaxSessionLimit
  $ScaleFactorEachHost = $HostpoolMaxSessionLimit * 0.80
  $SessionhostLimit = [math]::Floor($ScaleFactorEachHost)

  Write-Log 1 "Hostpool Maximum Session Limit: $($HostpoolMaxSessionLimit)"


  if ($CurrentDateTime -ge $BeginPeakDateTime -and $CurrentDateTime -le $EndPeakDateTime) {
    Write-Log 1 "It is in peak hours now" "Info"
    Write-Log 1 "Peak hours: starting session hosts as needed based on current workloads." "Info"

    # Get all session hosts in the host pool
    $AllSessionHosts = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName | Sort-Object Sessions -Descending | Sort-Object Status
    if ($AllSessionHosts -eq $null) {
      Write-Log 1 "Session hosts does not exist in the Hostpool of '$HostpoolName'. Ensure that hostpool have hosts or not?." "Info"
      exit
    }
    # Check dynamically created offpeakusage-minimumnoofRDSh text file and will remove in peak hours.
    if (Test-Path -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt) {
      Remove-Item -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt
    }

    # Check the number of running session hosts
    $NumberOfRunningHost = 0
    foreach ($SessionHost in $AllSessionHosts) {

      Write-Log 1 "Checking session host:$($SessionHost.SessionHostName | Out-String)  of sessions:$($SessionHost.Sessions) and status:$($SessionHost.Status)" "Info"
      $SessionCapacityofSessionHost = $SessionHost.Sessions

      if ($SessionHostLimit -lt $SessionCapacityofSessionHost -or $SessionHost.Status -eq "Available") {
        $NumberOfRunningHost = $NumberOfRunningHost + 1

      }
    }
    Write-Log 1 "Current number of running hosts: $NumberOfRunningHost" "Info"
    if ($NumberOfRunningHost -lt $MinimumNumberOfRDSH) {
      Write-Log 1 "Current number of running session hosts is less than minimum requirements, start session host ..." "Info"

      foreach ($SessionHost in $AllSessionHosts) {

        if ($NumberOfRunningHost -lt $MinimumNumberOfRDSH) {
          $SessionHostSessions = $SessionHost.Sessions
          if ($HostpoolMaxSessionLimit -ne $SessionHostSessions) {
            # Check the session host status and if the session host is healthy before starting the host
            if ($SessionHost.Status -eq "NoHeartbeat" -and $SessionHost.UpdateState -eq "Succeeded") {
              $SessionHostName = $SessionHost.SessionHostName | Out-String
              $VMName = $SessionHostName.Split(".")[0]
              $VmInfo = Get-AzureRmVM | Where-Object { $_.Name -eq $VMName }
              # Check the Session host is in maintenance
              if ($VmInfo.Tags.Keys -contains $MaintenanceTagName) {
                Write-Log 1 "Session host is in Maintenance: $SessionHostName, so this session host is skipped"
                continue
              }

              # Check if the session host is allowing new connections
              $StateOftheSessionHost = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -Name $SessionHost.SessionHostName
              if (!($StateOftheSessionHost.AllowNewSession)) {
                Set-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -Name $SessionHost.SessionHostName -AllowNewSession $true
              }

              # Start the azureRM VM
              try {
                Write-Log 1 "Starting Azure VM: $VMName and waiting for it to complete ..." "Info"
                Start-AzureRmVM -Name $VMName -ResourceGroupName $VmInfo.ResourceGroupName

              }
              catch {
                Write-Log 1 "Failed to start Azure VM: $($VMName) with error: $($_.exception.message)" "Info"
                exit
              }
              # Wait for the sessionhost is available
              $IsHostAvailable = $false
              while (!$IsHostAvailable) {

                $SessionHostStatus = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -Name $SessionHost.SessionHostName

                if ($SessionHostStatus.Status -eq "Available") {
                  $IsHostAvailable = $true

                }
              }
            }
          }
          $NumberOfRunningHost = $NumberOfRunningHost + 1
        }

      }
    }

    else {
      $AllSessionHosts = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName | Sort-Object "Sessions" -Descending | Sort-Object Status
      foreach ($SessionHost in $AllSessionHosts) {
        if ($SessionHost.Sessions -ne $HostpoolMaxSessionLimit) {
          if ($SessionHost.Sessions -ge $SessionHostLimit) {
            foreach ($SessionHost in $AllSessionHosts) {
              #Check the session host status and sessions before starting the one more session host
              if ($SessionHost.Status -eq "Available" -and $SessionHost.Sessions -eq 0)
              {
                break
              }
              # Check the session host status and if the session host is healthy before starting the host
              if ($SessionHost.Status -eq "NoHeartbeat" -and $SessionHost.UpdateState -eq "Succeeded") {
                Write-Log 1 "Existing Sessionhost Sessions value reached near by hostpool maximumsession limit need to start the session host" "Info"
                $SessionHostName = $SessionHost.SessionHostName | Out-String
                $VMName = $SessionHostName.Split(".")[0]
                # Check the session host is in maintenance
                $VmInfo = Get-AzureRmVM | Where-Object { $_.Name -eq $VMName }
                if ($VmInfo.Tags.Keys -contains $MaintenanceTagName) {
                  Write-Log 1 "Session Host is in Maintenance: $SessionHostName"
                  continue
                }

                # Check if the session host is allowing new connections
                $StateOftheSessionHost = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -Name $SessionHost.SessionHostName
                if (!($StateOftheSessionHost.AllowNewSession)) {
                  Set-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -Name $SessionHost.SessionHostName -AllowNewSession $true
                }


                # Start the azureRM VM
                try {
                  Write-Log 1 "Starting Azure VM: $VMName and waiting for it to complete ..." "Info"
                  Start-AzureRmVM -Name $VMName -ResourceGroupName $VMInfo.ResourceGroupName
                }
                catch {
                  Write-Log 1 "Failed to start Azure VM: $($VMName) with error: $($_.exception.message)" "Info"
                  exit
                }
                # Wait for the sessionhost is available
                $IsHostAvailable = $false
                while (!$IsHostAvailable) {

                  $SessionHostStatus = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -Name $SessionHost.SessionHostName

                  if ($SessionHostStatus.Status -eq "Available") {
                    $IsHostAvailable = $true
                  }
                }
                $NumberOfRunningHost = $NumberOfRunningHost + 1
                break

              }
            }

          }
        }
      }
    }

    Write-Log 1 "HostpoolName:$HostpoolName, NumberofRunnighosts:$NumberOfRunningHost" "Info"
    $DepthBool = $true
    Write-UsageLog -HostPoolName $HostpoolName -VMCount $NumberOfRunningHost -DepthBool $DepthBool
  }
  else {
    Write-Log 1 "It is Off-peak hours" "Info"
    Write-Log 1 "It is off-peak hours. Starting to scale down RD session hosts..." "Info"
    Write-Log 1 ("Processing hostPool {0}" -f $HostpoolName) "Info"
    # Get all session hosts in the host pool

    $AllSessionHosts = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName | Sort-Object Sessions
    if ($AllSessionHosts -eq $null) {
      Write-Log 1 "Sessionhosts does not exist in the Hostpool of '$HostpoolName'. Ensure that hostpool have hosts or not?." "Info"
      exit
    }

    # Check the number of running session hosts
    $NumberOfRunningHost = 0
    foreach ($SessionHost in $AllSessionHosts) {
      if ($SessionHost.Status -eq "Available") {
        $NumberOfRunningHost = $NumberOfRunningHost + 1
      }
    }
    # Defined minimum no of rdsh value from JSON file
    [int]$DefinedMinimumNumberOfRDSH = $MinimumNumberOfRDSH

    # Check and Collecting dynamically stored MinimumNoOfRDSH Value																 
    if (Test-Path -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt) {
      [int]$MinimumNumberOfRDSH = Get-Content $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt
    }


    if ($NumberOfRunningHost -gt $MinimumNumberOfRDSH) {
      foreach ($SessionHost in $AllSessionHosts.SessionHostName) {
        if ($NumberOfRunningHost -gt $MinimumNumberOfRDSH) {

          $SessionHostInfo = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -Name $SessionHost
          if ($SessionHostInfo.Status -eq "Available") {

            # Ensure the running Azure VM is set as drain mode
            try {
              Set-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -Name $SessionHost -AllowNewSession $false -ErrorAction SilentlyContinue
            }
            catch {
              Write-Log 1 "Unable to set it to allow connections on session host: $($SessionHost.SessionHost) with error: $($_.exception.message)" "Info"
              exit
            }
            # Notify user to log off session
            # Get the user sessions in the hostPool
            try {
              $HostPoolUserSessions = Get-RdsUserSession -TenantName $TenantName -HostPoolName $HostpoolName
            }
            catch {
              Write-ouput "Failed to retrieve user sessions in hostPool: $($HostpoolName) with error: $($_.exception.message)"
              exit
            }
            $HostUserSessionCount = ($HostPoolUserSessions | Where-Object -FilterScript { $_.SessionHostName -eq $SessionHost }).Count
            Write-Log 1 "Counting the current sessions on the host $SessionHost...:$HostUserSessionCount" "Info"

            $ExistingSession = 0
            foreach ($Session in $HostPoolUserSessions) {
              if ($Session.SessionHostName -eq $SessionHost) {
                if ($LimitSecondsToForceLogOffUser -ne 0) {
                  # Send notification to user
                  try {
                    Send-RdsUserSessionMessage -TenantName $TenantName -HostPoolName $HostpoolName -SessionHostName $session.SessionHostName -SessionId $session.sessionid -MessageTitle $LogOffMessageTitle -MessageBody "$($LogOffMessageBody) You will logged off in $($LimitSecondsToForceLogOffUser) seconds." -NoUserPrompt

                  }
                  catch {
                    Write-Log 1 "Failed to send message to user with error: $($_.exception.message)" "Info"
                    exit
                  }
                }

                $ExistingSession = $ExistingSession + 1
              }
            }
            #wait for n seconds to log off user
            Start-Sleep -Seconds $LimitSecondsToForceLogOffUser
            if ($LimitSecondsToForceLogOffUser -ne 0) {
              #force users to log off
              Write-Log 1 "Force users to log off..." "Info"
              try {
                $HostPoolUserSessions = Get-RdsUserSession -TenantName $TenantName -HostPoolName $HostpoolName

              }
              catch {
                Write-Log 1 "Failed to retrieve list of user sessions in hostPool: $($HostpoolName) with error: $($_.exception.message)" "Info"
                exit
              }
              foreach ($Session in $HostPoolUserSessions) {
                if ($Session.SessionHostName -eq $SessionHost) {
                  #log off user
                  try {

                    Invoke-RdsUserSessionLogoff -TenantName $TenantName -HostPoolName $HostpoolName -SessionHostName $Session.SessionHostName -SessionId $Session.sessionid -NoUserPrompt
                    $ExistingSession = $ExistingSession - 1

                  }
                  catch {
                    Write-ouput "Failed to log off user with error: $($_.exception.message)"
                    exit
                  }
                }
              }
            }


            $VMName = $SessionHost.Split(".")[0]
            # Check the Session host is in maintenance
            $VmInfo = Get-AzureRmVM | Where-Object { $_.Name -eq $VMName }
            if ($VmInfo.Tags.Keys -contains $MaintenanceTagName) {
              Write-Log 1 "Session Host is in Maintenance: $($SessionHost | Out-String)"
              $NumberOfRunningHost = $NumberOfRunningHost - 1
              continue
            }

            # Check the session count before shutting down the VM
            if ($ExistingSession -eq 0) {
              # Shutdown the Azure VM
              try {
                Write-Log 1 "Stopping Azure VM: $VMName and waiting for it to complete ..." "Info"

                Stop-AzureRmVM -Name $VMName -ResourceGroupName $VmInfo.ResourceGroupName -Force
              }
              catch {
                Write-Log 1 "Failed to stop Azure VM: $VMName with error: $_.exception.message" "Info"
                exit
              }
            }

            # Check if the session host server is healthy before enable allowing new connections
            if ($SessionHostInfo.UpdateState -eq "Succeeded") {
              # Ensure Azure VMs that are stopped have the allowing new connections state True
              try {
                Set-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -Name $SessionHost -AllowNewSession $true -ErrorAction SilentlyContinue
              }
              catch {
                Write-Log 1 "Unable to set it to allow connections on session host: $($SessionHost.SessionHost) with error: $($_.exception.message)" "Error"
                exit 1
              }
            }





            # Decrement the number of running session host
            $NumberOfRunningHost = $NumberOfRunningHost - 1
          }
        }
      }
    }

    # Check whether minimumNoofRDSH Value stored dynamically
    if (Test-Path -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt) {
      [int]$MinimumNumberOfRDSH = Get-Content $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt
      $NoConnectionsofhost = 0
      if ($NumberOfRunningHost -le $MinimumNumberOfRDSH) {
        foreach ($SessionHost in $AllSessionHosts) {
          if ($SessionHost.Status -eq "Available" -and $SessionHost.Sessions -eq 0) {
            $NoConnectionsofhost = $NoConnectionsofhost + 1

          }
        }
        if ($NoConnectionsofhost -gt $DefinedMinimumNumberOfRDSH) {
          [int]$MinimumNumberOfRDSH = [int]$MinimumNumberOfRDSH - $NoConnectionsofhost
          Clear-Content -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt
          Set-Content -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt $MinimumNumberOfRDSH
        }
      }
    }


    $HostpoolMaxSessionLimit = $HostpoolInfo.MaxSessionLimit
    $HostpoolSessionCount = (Get-RdsUserSession -TenantName $TenantName -HostPoolName $HostpoolName).Count
    if ($HostpoolSessionCount -eq 0) {
      Write-Log 1 "HostpoolName:$HostpoolName, NumberofRunnighosts:$NumberOfRunningHost" "Info"
      #write to the usage log					   
      $DepthBool = $true
      Write-UsageLog -HostPoolName $HostpoolName -VMCount $NumberOfRunningHost -DepthBool $DepthBool
      Write-Log 3 "End WVD Tenant Scale Optimization." "Info"
      break
    }
    else {
      # Calculate the how many sessions will allow in minimum number of RDSH VMs in off peak hours and calculate TotalAllowSessions Scale Factor
      $TotalAllowSessionsInOffPeak = [int]$MinimumNumberOfRDSH * $HostpoolMaxSessionLimit
      $SessionsScaleFactor = $TotalAllowSessionsInOffPeak * 0.90
      $ScaleFactor = [math]::Floor($SessionsScaleFactor)


      if ($HostpoolSessionCount -ge $ScaleFactor) {

        foreach ($SessionHost in $AllSessionHosts) {
          if ($SessionHost.Sessions -ge $SessionHostLimit) {

            $AllSessionHosts = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName | Sort-Object Sessions | Sort-Object Status
            foreach ($SessionHost in $AllSessionHosts) {

              if ($SessionHost.Status -eq "Available" -and $SessionHost.Sessions -eq 0)
              { break }
              # Check the session host status and if the session host is healthy before starting the host
              if ($SessionHost.Status -eq "NoHeartbeat" -and $SessionHost.UpdateState -eq "Succeeded") {
                Write-Log 1 "Existing Sessionhost Sessions value reached near by hostpool maximumsession limit need to start the session host" "Info"
                $SessionHostName = $SessionHost.SessionHostName | Out-String

                $VMName = $SessionHostName.Split(".")[0]
                $VmInfo = Get-AzureRmVM | Where-Object { $_.Name -eq $VMName }
                # Check the Session host is in maintenance
                if ($VmInfo.Tags.Keys -contains $MaintenanceTagName) {
                  Write-Log 1 "Session Host is in Maintenance: $SessionHostName"
                  continue
                }

                # Check if the session host is allowing new connections
                $StateOftheSessionHost = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -Name $SessionHost.SessionHostName
                if (!($StateOftheSessionHost.AllowNewSession)) {
                  Set-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -Name $SessionHost.SessionHostName -AllowNewSession $true
                }


                # Start the azureRM VM
                try {
                  Write-Log 1 "Starting Azure VM: $VMName and waiting for it to complete ..." "Info"
                  Start-AzureRmVM -Name $VMName -ResourceGroupName $VmInfo.ResourceGroupName
                }
                catch {
                  Write-Log 1 "Failed to start Azure VM: $($VMName) with error: $($_.exception.message)" "Info"
                  exit
                }
                # Wait for the sessionhost is available
                $IsHostAvailable = $false
                while (!$IsHostAvailable) {

                  $SessionHostStatus = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -Name $SessionHost.SessionHostName

                  if ($SessionHostStatus.Status -eq "Available") {
                    $IsHostAvailable = $true
                  }
                }
                $NumberOfRunningHost = $NumberOfRunningHost + 1
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

    Write-Log 1 "HostpoolName:$HostpoolName, NumberofRunnighosts:$NumberOfRunningHost" "Info"
    $DepthBool = $true
    Write-UsageLog -HostPoolName $HostpoolName -VMCount $NumberOfRunningHost -DepthBool $DepthBool
  }
  Write-Log 3 "End WVD Tenant Scale Optimization." "Info"

}
else {
  Write-Log 3 "$HostpoolName hostpool loadbalancer type is $($HostpoolInfo.LoadBalancerType)" "Info"
  # check if it is during the peak or off-peak time
  if ($CurrentDateTime -ge $BeginPeakDateTime -and $CurrentDateTime -le $EndPeakDateTime) {
    Write-Log 1 "It is in peak hours now" "Info"
    Write-Log 3 "Peak hours: starting session hosts as needed based on current workloads." "Info"
    # Get the Session Hosts in the hostPool		
    $AllSessionHosts = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -ErrorAction SilentlyContinue | Sort-Object SessionHostName
    if ($AllSessionHosts -eq $null) {
      Write-Log 1 "Sessionhosts does not exist in the Hostpool of '$HostpoolName'. Ensure that hostpool have hosts or not?." "Info"
      exit
    }

    # Get the User Sessions in the hostPool
    try {
      $HostPoolUserSessions = Get-RdsUserSession -TenantName $TenantName -HostPoolName $HostpoolName
    }
    catch {
      Write-Log 1 "Failed to retrieve user sessions in hostPool:$($HostpoolName) with error: $($_.exception.message)" "Error"
      exit 1
    }

    # Check and Remove the MinimumnoofRDSH value dynamically stored file												   
    if (Test-Path -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt) {
      Remove-Item -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt
    }

    # Check the number of running session hosts
    $NumberOfRunningHost = 0

    # Total of running cores
    $TotalRunningCores = 0

    # Total capacity of sessions of running VMs
    $AvailableSessionCapacity = 0

    foreach ($SessionHost in $AllSessionHosts) {
      Write-Log 1 "Checking session host:$($SessionHost.SessionHostName | Out-String)  of sessions:$($SessionHost.Sessions) and status:$($SessionHost.Status)" "Info"
      $SessionHostName = $SessionHost.SessionHostName | Out-String
      $VMName = $SessionHostName.Split(".")[0]
      $VmInfo = Get-AzureRmVM | Where-Object { $_.Name -eq $VMName }
      # Check the Session host is in maintenance
      if ($VmInfo.Tags.Keys -contains $MaintenanceTagName) {
        Write-Log 1 "Session Host is in Maintenance: $SessionHostName"
        continue
      }
      $RoleInstance = Get-AzureRmVM -Status | Where-Object { $_.Name.Contains($VMName) }
      if ($SessionHostName.ToLower().Contains($RoleInstance.Name.ToLower())) {
        # Check if the azure vm is running       
        if ($RoleInstance.PowerState -eq "VM running") {
          $NumberOfRunningHost = $NumberOfRunningHost + 1
          # Calculate available capacity of sessions						
          $RoleSize = Get-AzureRmVMSize -Location $RoleInstance.Location | Where-Object { $_.Name -eq $RoleInstance.HardwareProfile.VmSize }
          $AvailableSessionCapacity = $AvailableSessionCapacity + $RoleSize.NumberOfCores * $SessionThresholdPerCPU
          $TotalRunningCores = $TotalRunningCores + $RoleSize.NumberOfCores
        }

      }

    }
    Write-Log 1 "Current number of running hosts:$NumberOfRunningHost" "Info"

    if ($NumberOfRunningHost -lt $MinimumNumberOfRDSH) {

      Write-Log 1 "Current number of running session hosts is less than minimum requirements, start session host ..." "Info"

      # Start VM to meet the minimum requirement            
      foreach ($SessionHost in $AllSessionHosts.SessionHostName) {

        # Check whether the number of running VMs meets the minimum or not
        if ($NumberOfRunningHost -lt $MinimumNumberOfRDSH) {

          $VMName = $SessionHost.Split(".")[0]
          $VmInfo = Get-AzureRmVM | Where-Object { $_.Name -eq $VMName }
          # Check the Session host is in maintenance
          if ($VmInfo.Tags.Keys -contains $MaintenanceTagName) {
            Write-Log 1 "Session Host is in Maintenance: $($SessionHost | Out-String )"
            continue
          }

          $RoleInstance = Get-AzureRmVM -Status | Where-Object { $_.Name.Contains($VMName) }

          if ($SessionHost.ToLower().Contains($RoleInstance.Name.ToLower())) {

            # Check if the Azure VM is running and if the session host is healthy
            $SessionHostInfo = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -Name $SessionHost
            if ($RoleInstance.PowerState -ne "VM running" -and $SessionHostInfo.UpdateState -eq "Succeeded") {
              # Check if the session host is allowing new connections
              if ($SessionHostInfo.AllowNewSession -eq $false) {
                Set-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -Name $SessionHost -AllowNewSession $true

              }
              # Start the AzureRM VM
              try {
                Write-Log 1 "Starting Azure VM: $($RoleInstance.Name) and waiting for it to complete ..." "Info"
                Start-AzureRmVM -Name $RoleInstance.Name -Id $RoleInstance.Id -ErrorAction SilentlyContinue
              }
              catch {
                Write-Log 1 "Failed to start Azure VM: $($RoleInstance.Name) with error: $($_.exception.message)" "Error"
                exit 1
              }
              # Wait for the VM to start
              $IsVMStarted = $false
              while (!$IsVMStarted) {

                $VMState = Get-AzureRmVM -Status | Where-Object { $_.Name -eq $RoleInstance.Name }

                if ($VMState.PowerState -eq "VM running" -and $VMState.ProvisioningState -eq "Succeeded") {
                  $IsVMStarted = $true
                  Set-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -Name $SessionHost -AllowNewSession $true
                }
              }
              # Calculate available capacity of sessions

              $RoleSize = Get-AzureRmVMSize -Location $RoleInstance.Location | Where-Object { $_.Name -eq $RoleInstance.HardwareProfile.VmSize }
              $AvailableSessionCapacity = $AvailableSessionCapacity + $RoleSize.NumberOfCores * $SessionThresholdPerCPU
              $NumberOfRunningHost = $NumberOfRunningHost + 1
              $TotalRunningCores = $TotalRunningCores + $RoleSize.NumberOfCores
              if ($NumberOfRunningHost -ge $MinimumNumberOfRDSH) {
                break;
              }
            }
          }
        }
      }
    }

    else {
      #check if the available capacity meets the number of sessions or not
      Write-Log 1 "Current total number of user sessions: $(($HostPoolUserSessions).Count)" "Info"
      Write-Log 1 "Current available session capacity is: $AvailableSessionCapacity" "Info"
      if ($HostPoolUserSessions.Count -ge $AvailableSessionCapacity) {
        Write-Log 1 "Current available session capacity is less than demanded user sessions, starting session host" "Info"
        # Running out of capacity, we need to start more VMs if there are any 
        foreach ($SessionHost in $AllSessionHosts.SessionHostName) {
          if ($HostPoolUserSessions.Count -ge $AvailableSessionCapacity) {
            $VMName = $SessionHost.Split(".")[0]
            $VmInfo = Get-AzureRmVM | Where-Object { $_.Name -eq $VMName }
            # Check the Session host is in maintenance
            if ($VmInfo.Tags.Keys -contains $MaintenanceTagName) {
              Write-Log 1 "Session Host is in Maintenance: $($SessionHost | Out-String)"
              continue
            }


            $RoleInstance = Get-AzureRmVM -Status | Where-Object { $_.Name.Contains($VMName) }
             if ($SessionHost.ToLower().Contains($RoleInstance.Name.ToLower())) {
              # Check if the Azure VM is running and if the session host is healthy
              $SessionHostInfo = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -Name $SessionHost
              if ($RoleInstance.PowerState -ne "VM running" -and $SessionHostInfo.UpdateState -eq "Succeeded") {
                # Check if the session host is allowing new connections
                if ($SessionHostInfo.AllowNewSession -eq $false) {
                  Set-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -Name $SessionHost -AllowNewSession $true
                }
                # Start the AzureRM VM
                try {
                  Write-Log 1 "Starting Azure VM: $($RoleInstance.Name) and waiting for it to complete ..." "Info"
                  Start-AzureRmVM -Name $RoleInstance.Name -Id $RoleInstance.Id -ErrorAction SilentlyContinue

                }
                catch {
                  Write-Log 1 "Failed to start Azure VM: $($RoleInstance.Name) with error: $($_.exception.message)" "Error"
                  exit 1
                }
                # Wait for the VM to Start
                $IsVMStarted = $false
                while (!$IsVMStarted) {
                  $VMState = Get-AzureRmVM -Status | Where-Object { $_.Name -eq $RoleInstance.Name }

                  if ($VMState.PowerState -eq "VM running" -and $VMState.ProvisioningState -eq "Succeeded") {
                    $IsVMStarted = $true
                    Write-Log 1 "Azure VM has been started: $($RoleInstance.Name) ..." "Info"
                  }
                  else {
                    Write-Log 3 "Waiting for Azure VM to start $($RoleInstance.Name) ..." "Info"
                  }
                }
                # Calculate available capacity of sessions

                $RoleSize = Get-AzureRmVMSize -Location $RoleInstance.Location | Where-Object { $_.Name -eq $RoleInstance.HardwareProfile.VmSize }
                $AvailableSessionCapacity = $AvailableSessionCapacity + $RoleSize.NumberOfCores * $SessionThresholdPerCPU
                $NumberOfRunningHost = $NumberOfRunningHost + 1
                $TotalRunningCores = $TotalRunningCores + $RoleSize.NumberOfCores
                Write-Log 1 "New available session capacity is: $AvailableSessionCapacity" "Info"
                if ($AvailableSessionCapacity -gt $HostPoolUserSessions.Count) {
                  break
                }
              }
              #Break # break out of the inner foreach loop once a match is found and checked
            }
          }
        }
      }
    }
    Write-Log 1 "HostpoolName:$HostpoolName, TotalRunningCores:$TotalRunningCores NumberOfRunningHost:$NumberOfRunningHost" "Info"
    # Write to the usage log
    $DepthBool = $false
    Write-UsageLog -HostPoolName $HostpoolName -Corecount $TotalRunningCores -VMCount $NumberOfRunningHost -DepthBool $DepthBool
  }
  #} 
  else {

    Write-Log 1 "It is Off-peak hours" "Info"
    Write-Log 3 "It is off-peak hours. Starting to scale down RD session hosts..." "Info"
    Write-Log 3 "Processing hostPool $($HostpoolName)"
    # Get the Session Hosts in the hostPool
    $AllSessionHosts = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName
    # Check the sessionhosts are exist in the hostpool
    if ($AllSessionHosts -eq $null) {
      Write-Log 1 "Sessionhosts does not exist in the Hostpool of '$HostpoolName'. Ensure that hostpool have hosts or not?." "Info"
      exit
    }

    # Check the number of running session hosts
    $NumberOfRunningHost = 0

    # Total number of running cores
    $TotalRunningCores = 0

    foreach ($SessionHost in $AllSessionHosts.SessionHostName) {

      $VMName = $SessionHost.Split(".")[0]
      $RoleInstance = Get-AzureRmVM -Status | Where-Object { $_.Name.Contains($VMName) }

      if ($SessionHost.ToLower().Contains($RoleInstance.Name.ToLower())) {
        #check if the Azure VM is running or not

        if ($RoleInstance.PowerState -eq "VM running") {
          $NumberOfRunningHost = $NumberOfRunningHost + 1

          # Calculate available capacity of sessions  
          $RoleSize = Get-AzureRmVMSize -Location $RoleInstance.Location | Where-Object { $_.Name -eq $RoleInstance.HardwareProfile.VmSize }

          $TotalRunningCores = $TotalRunningCores + $RoleSize.NumberOfCores



        }
      }
    }
    # Defined minimum no of rdsh value from JSON file
    [int]$DefinedMinimumNumberOfRDSH = $MinimumNumberOfRDSH

    # Check and Collecting dynamically stored MinimumNoOfRDSH Value																 
    if (Test-Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt) {
      [int]$MinimumNumberOfRDSH = Get-Content $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt
    }

    if ($NumberOfRunningHost -gt $MinimumNumberOfRDSH) {


      # Shutdown VM to meet the minimum requirement
      foreach ($SessionHost in $AllSessionHosts.SessionHostName) {
        if ($NumberOfRunningHost -gt $MinimumNumberOfRDSH) {

          $VMName = $SessionHost.Split(".")[0]
          $RoleInstance = Get-AzureRmVM -Status | Where-Object { $_.Name.Contains($VMName) }

          if ($SessionHost.ToLower().Contains($RoleInstance.Name.ToLower())) {

            # Check if the Azure VM is running
            if ($RoleInstance.PowerState -eq "VM running") {
              # Check if the role isntance status is ReadyRole before setting the session host
              $IsInstanceReady = $false
              $NumerOfRetries = 0

              while (!$IsInstanceReady -and $NumerOfRetries -le 3) {
                $NumerOfRetries = $NumerOfRetries + 1
                $Instance = Get-AzureRmVM -Status | Where-Object { $_.Name -eq $RoleInstance.Name }
                if ($Instance.ProvisioningState -eq "Succeeded" -and $Instance -ne $null) {
                  $IsInstanceReady = $true
                }

              }
              if ($IsInstanceReady) {

                # Ensure the running Azure VM is set as drain mode
                try {
                  Set-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -Name $SessionHost -AllowNewSession $false -ErrorAction SilentlyContinue
                }
                catch {

                  Write-Log 1 "Unable to set it to allow connections on session host: $($SessionHost.SessionHost) with error: $($_.exception.message)" "Error"
                  exit 1

                }
                # Notify user to log off session
                # Get the user sessions in the hostPool
                try {

                  $HostPoolUserSessions = Get-RdsUserSession -TenantName $TenantName -HostPoolName $HostpoolName

                }
                catch {
                  Write-Log 1 "Failed to retrieve user sessions in hostPool: $($HostpoolName) with error: $($_.exception.message)" "Error"
                  exit 1
                }

                $HostUserSessionCount = ($HostPoolUserSessions | Where-Object -FilterScript { $_.SessionHostName -eq $SessionHost }).Count
                Write-Log 1 "Counting the current sessions on the host $SessionHost...:$HostUserSessionCount" "Info"
                #Write-Log 1 "Counting the current sessions on the host..." "Info"
                $ExistingSession = 0

                foreach ($session in $HostPoolUserSessions) {

                  if ($session.SessionHostName -eq $SessionHost) {



                    if ($LimitSecondsToForceLogOffUser -ne 0) {
                      # Send notification
                      try {

                        Send-RdsUserSessionMessage -TenantName $TenantName -HostPoolName $HostpoolName -SessionHostName $SessionHost -SessionId $session.sessionid -MessageTitle $LogOffMessageTitle -MessageBody "$($LogOffMessageBody) You will logged off in $($LimitSecondsToForceLogOffUser) seconds." -NoUserPrompt

                      }
                      catch {

                        Write-Log 1 "Failed to send message to user with error: $($_.exception.message)" "Error"
                        exit 1

                      }
                    }

                    $ExistingSession = $ExistingSession + 1
                  }
                }
                # Wait for n seconds to log off user
                Start-Sleep -Seconds $LimitSecondsToForceLogOffUser

                if ($LimitSecondsToForceLogOffUser -ne 0) {
                  # Force users to log off
                  Write-Log 1 "Force users to log off..." "Info"
                  try {
                    $HostPoolUserSessions = Get-RdsUserSession -TenantName $TenantName -HostPoolName $HostpoolName
                  }
                  catch {
                    Write-Log 1 "Failed to retrieve list of user sessions in hostPool: $($HostpoolName) with error: $($_.exception.message)" "Error"
                    exit 1
                  }
                  foreach ($Session in $HostPoolUserSessions) {
                    if ($Session.SessionHostName -eq $SessionHost) {
                      #Log off user
                      try {

                        Invoke-RdsUserSessionLogoff -TenantName $TenantName -HostPoolName $HostpoolName -SessionHostName $Session.SessionHostName -SessionId $Session.sessionid -NoUserPrompt

                        $ExistingSession = $ExistingSession - 1
                      }
                      catch {
                        Write-Log 1 "Failed to log off user with error: $($_.exception.message)" "Error"
                        exit 1
                      }
                    }
                  }
                }


                # Check the session count before shutting down the VM
                if ($ExistingSession -eq 0) {

                  # Check the Session host is in maintenance
                  $VmInfo = Get-AzureRmVM | Where-Object { $_.Name -eq $VMName }
                  if ($VmInfo.Tags.Keys -contains $MaintenanceTagName) {
                    Write-Log 1 "Session Host is in Maintenance: $($SessionHost | Out-String)"
                    $NumberOfRunningHost = $NumberOfRunningHost - 1
                    continue
                  }

                  # Shutdown the Azure VM
                  try {
                    Write-Log 1 "Stopping Azure VM: $($RoleInstance.Name) and waiting for it to complete ..." "Info"
                    Stop-AzureRmVM -Name $RoleInstance.Name -Id $RoleInstance.Id -Force -ErrorAction SilentlyContinue

                  }
                  catch {
                    Write-Log 1 "Failed to stop Azure VM: $($RoleInstance.Name) with error: $($_.exception.message)" "Error"
                    exit 1
                  }
                  #wait for the VM to stop
                  $IsVMStopped = $false
                  while (!$IsVMStopped) {

                    $vm = Get-AzureRmVM -Status | Where-Object { $_.Name -eq $RoleInstance.Name }

                    if ($vm.PowerState -eq "VM deallocated") {
                      $IsVMStopped = $true
                      Write-Log 1 "Azure VM has been stopped: $($RoleInstance.Name) ..." "Info"
                    }
                    else {
                      Write-Log 3 "Waiting for Azure VM to stop $($RoleInstance.Name) ..." "Info"
                    }
                  }
                  $SessionHostInfo = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -Name $SessionHost
                  if ($SessionHostInfo.UpdateState -eq "Succeeded") {
                    # Ensure the Azure VMs that are off have Allow new connections mode set to True
                    try {
                      Set-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -Name $SessionHost -AllowNewSession $true -ErrorAction SilentlyContinue
                    }
                    catch {
                      Write-Log 1 "Unable to set it to allow connections on session host: $($SessionHost | Out-String) with error: $($_.exception.message)" "Error"
                      exit 1
                    }
                  }
                  $RoleSize = Get-AzureRmVMSize -Location $RoleInstance.Location | Where-Object { $_.Name -eq $RoleInstance.HardwareProfile.VmSize }
                  #decrement number of running session host
                  $NumberOfRunningHost = $NumberOfRunningHost - 1
                  $TotalRunningCores = $TotalRunningCores - $RoleSize.NumberOfCores
                }
              }
            }
          }
        }
      }

    }

    # Check whether minimumNoofRDSH Value stored dynamically and calculate minimumNoOfRDSh value
    if (Test-Path -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt) {
      [int]$MinimumNumberOfRDSH = Get-Content $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt
      $NoConnectionsofhost = 0
      if ($NumberOfRunningHost -le $MinimumNumberOfRDSH) {
        $MinimumNumberOfRDSH = $NumberOfRunningHost
        $AllSessionHosts = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName | Sort-Object sessions | Sort-Object status
        foreach ($SessionHost in $AllSessionHosts) {
          if ($SessionHost.Status -eq "Available" -and $SessionHost.Sessions -eq 0) {
            $NoConnectionsofhost = $NoConnectionsofhost + 1

          }
        }
        if ($NoConnectionsofhost -gt $DefinedMinimumNumberOfRDSH) {
          [int]$MinimumNumberOfRDSH = [int]$MinimumNumberOfRDSH - $NoConnectionsofhost
          Clear-Content -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt
          Set-Content -Path $CurrentPath\OffPeakUsage-MinimumNoOfRDSH.txt $MinimumNumberOfRDSH
        }
      }
    }
    # Calculate the how many sessions will allow in minimum number of RDSH VMs in off peak hours
    $HostpoolMaxSessionLimit = $HostpoolInfo.MaxSessionLimit
    $HostpoolSessionCount = (Get-RdsUserSession -TenantName $TenantName -HostPoolName $HostpoolName).Count
    if ($HostpoolSessionCount -eq 0) {
      Write-Log 1 "HostpoolName:$HostpoolName, TotalRunningCores:$TotalRunningCores NumberOfRunningHost:$NumberOfRunningHost" "Info"
      # Write to the usage log
      $DepthBool = $false
      Write-UsageLog $HostpoolName $TotalRunningCores $NumberOfRunningHost $DepthBool
      Write-Log 3 "End WVD Tenant Scale Optimization." "Info"
      break
    }
    else {
      # Calculate the how many sessions will allow in minimum number of RDSH VMs in off peak hours and calculate TotalAllowSessions Scale Factor
      $TotalAllowSessionsInOffPeak = [int]$MinimumNumberOfRDSH * $HostpoolMaxSessionLimit
      $SessionsScaleFactor = $TotalAllowSessionsInOffPeak * 0.90
      $ScaleFactor = [math]::Floor($SessionsScaleFactor)


      if ($HostpoolSessionCount -ge $ScaleFactor) {

        # Check if the available capacity meets the number of sessions or not
        Write-Log 1 "Current total number of user sessions: $HostpoolSessionCount" "Info"
        Write-Log 1 "Current available session capacity is less than demanded user sessions, starting session host" "Info"
        # Running out of capacity, we need to start more VMs if there are any 
        foreach ($SessionHost in $AllSessionHosts) {
          $SessionHostName = $SessionHost.SessionHostName | Out-String
          $VMName = $SessionHostName.Split(".")[0]

          $VmInfo = Get-AzureRmVM | Where-Object { $_.Name -eq $VMName }
          # Check the Session host is in maintenance
          if ($VmInfo.Tags.Keys -contains $MaintenanceTagName) {
            Write-Log 1 "Session Host is in Maintenance: $SessionHostName"
            continue
          }
          $RoleInstance = Get-AzureRmVM -Status | Where-Object { $_.Name.Contains($VMName) }
          #
          if ($SessionHost.Status -eq "Available" -and $SessionHost.Sessions -eq 0)
          { break }
          if ($SessionHostName.ToLower().Contains($RoleInstance.Name.ToLower())) {
            # Check if the Azure VM is running and if the session host is healthy
            $SessionHostInfo = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -Name $SessionHost.SessionHostName
            if ($RoleInstance.PowerState -ne "VM running" -and $SessionHostInfo.UpdateState -eq "Succeeded") {

              if ($SessionHostInfo.AllowNewSession -eq $false) {
                Set-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -Name $SessionHost.SessionHostName -AllowNewSession $true

              }
              # Start the AzureRM VM
              try {
                Write-Log 1 "Starting Azure VM: $($RoleInstance.Name) and waiting for it to complete ..." "Info"
                Start-AzureRmVM -Name $RoleInstance.Name -Id $RoleInstance.Id -ErrorAction SilentlyContinue

              }
              catch {
                Write-Log 1 "Failed to start Azure VM: $($RoleInstance.Name) with error: $($_.exception.message)" "Error"
                exit 1
              }
              # Wait for the VM to start
              $IsVMStarted = $false
              while (!$IsVMStarted) {
                $VMState = Get-AzureRmVM -Status | Where-Object { $_.Name -eq $RoleInstance.Name }

                if ($VMState.PowerState -eq "VM running" -and $VMState.ProvisioningState -eq "Succeeded") {
                  $IsVMStarted = $true
                  Write-Log 1 "Azure VM has been started: $($RoleInstance.Name) ..." "Info"
                }
                else {
                  Write-Log 3 "Waiting for Azure VM to start $($RoleInstance.Name) ..." "Info"
                }
              }
              # Calculate available capacity of sessions

              $RoleSize = Get-AzureRmVMSize -Location $RoleInstance.Location | Where-Object { $_.Name -eq $RoleInstance.HardwareProfile.VmSize }
              $AvailableSessionCapacity = $TotalAllowSessions + $HostpoolInfo.MaxSessionLimit
              $NumberOfRunningHost = $NumberOfRunningHost + 1
              $TotalRunningCores = $TotalRunningCores + $RoleSize.NumberOfCores
              Write-Log 1 "New available session capacity is: $AvailableSessionCapacity" "Info"

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

    Write-Log 1 "HostpoolName:$HostpoolName, TotalRunningCores:$TotalRunningCores NumberOfRunningHost:$NumberOfRunningHost" "Info"
    #write to the usage log
    $DepthBool = $false
    Write-UsageLog -HostPoolName $HostpoolName -Corecount $TotalRunningCores -VMCount $NumberOfRunningHost -DepthBool $DepthBool
  } #Scale hostPool

  Write-Log 3 "End WVD Tenant Scale Optimization." "Info"
}
