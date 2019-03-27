<#
Copyright 2019 Microsoft
Version 2.0 March 2019
.SYNOPSIS
This is a sample script for automatically scaling Tenant Environment WVD Host Servers in Microsoft Azure
.Description
This script will start/stop Tenant WVD host VMs based on the number of user sessions and peak/off-peak time period specified in the configuration file.
During the peak hours, the script will start necessary session hosts in the host pool to meet the demands of users.
During the off-peak hours, the script will shut down session hosts and only keep the minimum number of session hosts.
This script depends on two PowerShell modules: Azure RM and Windows Virtual Desktop modules. To install Azure RM module execute the following command. Use "-AllowClobber" parameter if you have more than one version of PowerShell modules installed.
PS C:\>Install-Module AzureRM  -AllowClobber
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
<#
.SYNOPSIS
Function for writing the log
#>
function Write-Log {
  param(
    [int]$level
    ,[string]$Message
    ,[ValidateSet("Info","Warning","Error")] [string]$severity = 'Info'
    ,[string]$logname = $rdmiTenantlog
    ,[string]$color = "white"
  )
  $time = Get-Date
  Add-Content $logname -Value ("{0} - [{1}] {2}" -f $time,$severity,$Message)
  if ($interactive) {
    switch ($severity) {
      'Error' { $color = 'Red' }
      'Warning' { $color = 'Yellow' }
    }
    if ($level -le $VerboseLogging) {
      if ($color -match "Red|Yellow") {
        Write-Host ("{0} - [{1}] {2}" -f $time,$severity,$Message) -ForegroundColor $color -BackgroundColor Black
        if ($severity -eq 'Error') {

          throw $Message
        }
      }
      else {
        Write-Host ("{0} - [{1}] {2}" -f $time,$severity,$Message) -ForegroundColor $color
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
    [string]$logfilename = $RdmiTenantUsagelog
  )
  $time = Get-Date
  if($depthBool){
    
    Add-Content $logfilename -Value ("{0}, {1}, {2}" -f $time,$hostpoolName,$vmcount)
    }
    else
    {
    Add-Content $logfilename -Value ("{0}, {1}, {2}, {3}" -f $time,$hostpoolName,$corecount,$vmcount)
  }
}
<#
.SYNOPSIS
Function for creating a variable from XML
#>
function Set-ScriptVariable ($Name,$Value) {
  Invoke-Expression ("`$Script:" + $Name + " = `"" + $Value + "`"")
}

$CurrentPath = Split-Path $script:MyInvocation.MyCommand.Path

##### XML path #####
$XMLPath = "$CurrentPath\Config.xml"

##### Log path #####
$rdmiTenantlog = "$CurrentPath\WVDTenantScale.log"

##### Usage log path #####
$RdmiTenantUsagelog = "$CurrentPath\WVDTenantUsage.log"

###### Verify XML file ######
if (Test-Path $XMLPath) {
  Write-Verbose "Found $XMLPath"
  Write-Verbose "Validating file..."
  try {
    $Variable = [xml](Get-Content $XMLPath)
  }
  catch {
    $Validate = $false
    Write-Error "$XMLPath is invalid. Check XML syntax - Unable to proceed"
    Write-Log 3 "$XMLPath is invalid. Check XML syntax - Unable to proceed" "Error"
    exit 1
  }
}
else {
  $Validate = $false
  Write-Error "Missing $XMLPath - Unable to proceed"
  Write-Log 3 "Missing $XMLPath - Unable to proceed" "Error"
  exit 1
}
##### Load XML configuration values as variables #####
Write-Verbose "loading values from Config.xml"
$Variable = [xml](Get-Content "$XMLPath")
$Variable.RDMIScale.Azure | ForEach-Object { $_.Variable } | Where-Object { $_.Name -ne $null } | ForEach-Object { Set-ScriptVariable -Name $_.Name -Value $_.Value }
$Variable.RDMIScale.RdmiScaleSettings | ForEach-Object { $_.Variable } | Where-Object { $_.Name -ne $null } | ForEach-Object { Set-ScriptVariable -Name $_.Name -Value $_.Value }
$Variable.RDMIScale.Deployment | ForEach-Object { $_.Variable } | Where-Object { $_.Name -ne $null } | ForEach-Object { Set-ScriptVariable -Name $_.Name -Value $_.Value }

##### Load functions/module #####
. $CurrentPath\Functions-PSStoredCredentials.ps1
Import-Module $CurrentPath\PowershellModules\Microsoft.RdInfra.RdPowershell.dll

##### Login with delegated access in WVD tenant #####
$Credential = Get-StoredCredential -UserName $Username
##### Setting RDS context #####
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$isWVDServicePrincipal = ($isWVDServicePrincipal -eq "True")
##### Check if service principal or user account is being used for WVD #####
if (!$isWVDServicePrincipal) {
  ##### If standard account is provided login in WVD with that account #####
  try {
    $authentication = Add-RdsAccount -DeploymentUrl $RDBroker -Credential $Credential
  }
  catch {
    Write-Log 1 "Failed to authenticate with WVD Tenant with a standard account: $($_.exception.message)" "Error"
    exit 1
  }
  Write-Log 3 "Authenticating as standard account for WVD." "Info"
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
  Write-Log 3 "Authenticating as service principal account for WVD." "Info"
}

##### Authenticating to Azure #####
$appCreds = Get-StoredCredential -UserName $AADApplicationId
try {
     $authentication = Add-AzureRmAccount -SubscriptionId $currentAzureSubscriptionId -Credential $appCreds
  }
catch {
    Write-Log 1 "Failed to authenticate with Azure with a standard account: $($_.exception.message)" "Error"
    exit 1
}

##### Set context to the appropriate tenant group #####
Write-Log  1 "Running switching to the $tenantGroupName context" "Info"
Set-RdsContext -TenantGroupName $tenantGroupName

##### select the current Azure subscription specified in the config #####
Select-AzureRmSubscription -SubscriptionId $currentAzureSubscriptionId
##### Construct Begin time and End time for the Peak period #####
$CurrentDateTime = Get-Date
Write-Log 3 "Starting WVD Tenant Hosts Scale Optimization: Current Date Time is: $CurrentDateTime" "Info"

$BeginPeakDateTime = [datetime]::Parse($CurrentDateTime.ToShortDateString() + ' ' + $BeginPeakTime)

$EndPeakDateTime = [datetime]::Parse($CurrentDateTime.ToShortDateString() + ' ' + $EndPeakTime)

##### Check the calculated end time is later than begin time in case of time zone #####
if ($EndPeakDateTime -lt $BeginPeakDateTime) {
  $EndPeakDateTime = $EndPeakDateTime.AddDays(1)
}
$hostpoolInfo = Get-RdsHostPool -TenantName $tenantName -Name $hostPoolName
if ($hostpoolInfo.LoadBalancerType -eq "DepthFirst") {
Write-Log 1 "$hostPoolName hostpool loadbalancer type is $($hostpoolInfo.LoadBalancerType)" "Info"
  if ($CurrentDateTime -ge $BeginPeakDateTime -and $CurrentDateTime -le $EndPeakDateTime) {

    Write-Log 1  "It is in peak hours now" "Info"
    Write-Log 1 "Peak hours: starting session hosts as needed based on current workloads." "Info"
    $hostpoolMaxSessionLimit = $hostpoolinfo.MaxSessionLimit
    ##### Get the session hosts in the hostpool #####
    try {
      $getHosts = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostpoolname | Sort-Object $_.sessionhostname
    }
    catch {
      Write-Log 1 "Failed to retrieve sessionhost in hostpool $($hostPoolName) : $($_.exception.message)" "Info"
      exit
    }

    if ($hostpoolMaxSessionLimit -le 10) {
        $sessionlimit = $hostpoolMaxSessionLimit - 1
        
        }
    elseif($hostpoolMaxSessionLimit -le 50) {
        $sessionlimitofhost = $hostpoolMaxSessionLimit / 4
        $var = $hostpoolMaxSessionLimit - $sessionlimitofhost
        $sessionlimit = [math]::Round($var)
        
    }
    elseif($hostpoolMaxSessionLimit -gt 50)
    {
       $sessionlimit = $hostpoolMaxSessionLimit - 10
       
    }
 
 Write-Log 1 "Hostpool Maximum Session Limit: $($hostpoolMaxSessionLimit)"

    ##### Check the number of running session hosts #####
    $numberOfRunningHost = 0
    foreach ($sessionHost in $getHosts) {
           
      Write-Log 1 "Checking session host:$($sessionHost.SessionHostName | Out-String)  of sessions:$($sessionHost.Sessions) and status:$($sessionHost.Status)" "Info"

      $sessionCapacityofhost = $sessionhost.Sessions
      if ($sessionlimit -lt $sessionCapacityofhost -or $sessionHost.Status -eq "Available") {

        $numberOfRunningHost = $numberOfRunningHost + 1
      }
    }
    Write-Log 1  "Current number of running hosts: $numberOfRunningHost" "Info"
    if ($numberOfRunningHost -lt $MinimumNumberOfRDSH) {
      Write-Log 1  "Current number of running session hosts is less than minimum requirements, start session host ..." "Info"

      foreach ($sessionhost in $getHosts) {

         if ($numberOfRunningHost -lt $MinimumNumberOfRDSH) {
          $hostsessions = $sessionHost.Sessions
          if ($hostpoolMaxSessionLimit -ne $hostofsessions) {
            if ($sessionhost.Status -eq "UnAvailable") {
              $sessionhostname = $sessionhost.sessionhostname
              ##### Check session host is in drain mode #####
              $checkAllowNewSession = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostpoolname -Name $sessionhostname
              if (!($checkAllowNewSession.AllowNewSession)) {
                Set-RdsSessionHost -TenantName $tenantname -HostPoolName $hostpoolname -Name $sessionhostname -AllowNewSession $true
              }
              $VMName = $sessionHostname.Split(".")[0]
              ##### Start the Azure VM #####
              try {
                Get-AzureRmVM | Where-Object { $_.Name -eq $VMName } | Start-AzureRmVM

              }
              catch {
                Write-Log 1 "Failed to start Azure VM: $($VMName) with error: $($_.exception.message)" "Info"
                exit
              }
              ##### Wait for the sessionhost is available #####
                $IsHostAvailable = $false
                while (!$IsHostAvailable) {

                  $hoststatus = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostpoolname -Name $sessionHost.sessionhostname

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
        if (!($sessionHost.Sessions -eq $hostpoolMaxSessionLimit)) {
          if ($sessionHost.Sessions -ge $sessionlimit) {
          foreach($sHost in $getHosts){
                if ($sHost.Status -eq "Available" -and $sHost.Sessions -eq 0) { break }
                if ($sHost.Status -eq "Unavailable") {
                Write-Log 1 "Existing Sessionhost Sessions value reached near by hostpool maximumsession limit need to start the session host" "Info"
                $sessionhostname = $sHost.sessionhostname
                ##### Check session host is in drain mode #####
                $checkAllowNewSession = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostpoolname -Name $sessionhostname
                if (!($checkAllowNewSession.AllowNewSession)) {
                  Set-RdsSessionHost -TenantName $tenantname -HostPoolName $hostpoolname -Name $sessionhostname -AllowNewSession $true
                }
                $VMName = $sessionHostname.Split(".")[0]

                ##### Start the Azure VM #####
                try {
                  Get-AzureRmVM | Where-Object { $_.Name -eq $VMName } | Start-AzureRmVM
                }
                catch {
                  Write-Log 1 "Failed to start Azure VM: $($VMName) with error: $($_.exception.message)" "Info"
                  exit
                }
                ##### Wait for the sessionhost is available #####
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
    Write-Log 1  "HostpoolName:$hostpoolname, NumberofRunnighosts:$numberOfRunningHost" "Info"
    $depthBool = $true
    Write-UsageLog $hostPoolName $numberOfRunningHost $depthBool
  }
  else {
    Write-Log 1  "It is Off-peak hours" "Info"
    Write-Log 1  "It is off-peak hours. Starting to scale down RD session hosts..." "Info"
    Write-Log 1  ("Processing hostPool {0}" -f $hostPoolName) "Info"
    try {
      $getHosts = Get-RdsSessionHost -TenantName $tenantName -HostPoolName $hostPoolName | Sort-Object Sessions
    }
    catch {
      Write-Log 1 "Failed to retrieve session hosts in hostPool: $($hostPoolName) with error: $($_.exception.message)" "Info"
      exit
    }
    ##### Check number of running session hosts #####
    $numberOfRunningHost = 0
    foreach ($sessionHost in $getHosts) {
       if ($sessionHost.Status -eq "Available") {
        $numberOfRunningHost = $numberOfRunningHost + 1
      }
    }
    if ($numberOfRunningHost -gt $MinimumNumberOfRDSH) {
      foreach ($sessionHost in $getHosts.sessionhostname) {
        if ($numberOfRunningHost -gt $MinimumNumberOfRDSH) {

          $sessionHostinfo1 = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostpoolname -Name $sessionHost
          if ($sessionHostinfo1.Status -eq "Available") {

            ##### Ensure the running Azure VM is set as drain mode #####
            try {

              ##### Setting host in drain mode #####
              Set-RdsSessionHost -TenantName $tenantName -HostPoolName $hostPoolName -Name $sessionHost -AllowNewSession $false -ErrorAction SilentlyContinue
            }
            catch {
              Write-Log 1 "Failed to set drain mode on session host: $($sessionHost.SessionHost) with error: $($_.exception.message)" "Info"
              exit
            }
            ##### Get the user sessions in the host pool #####
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
                  ##### Send notification #####
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
            ##### Wait for n seconds to log off user #####
            Start-Sleep -Seconds $LimitSecondsToForceLogOffUser
            if ($LimitSecondsToForceLogOffUser -ne 0) {
              ##### Force users to log off #####
              Write-Log 1  "Force users to log off..." "Info"
              try {
                $hostPoolUserSessions = Get-RdsUserSession -TenantName $tenantName -HostPoolName $hostPoolName

              }
              catch {
                Write-Log 1 "Failed to retrieve list of user sessions in hostPool: $($hostPoolName) with error: $($_.exception.message)" "Info"
                exit
              }
              foreach ($session in $hostPoolUserSessions) {
                if ($session.sessionhostname -eq $sessionHost) {
                  ##### Log off user #####
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
            ##### Check session count before shutting down the VM #####
            if ($existingSession -eq 0) {
              ##### Shutdown the Azure VM #####
              try {
                Write-Log 1 "Stopping Azure VM: $VMName and waiting for it to complete ..." "Info"
                Get-AzureRmVM | Where-Object { $_.Name -eq $VMName } | Stop-AzureRmVM -Force
              }
              catch {
                Write-Log 1 "Failed to stop Azure VM: $VMName with error: $_.exception.message" "Info"
                exit
              }
            }
            ##### Decrement number of running session host #####
            $numberOfRunningHost = $numberOfRunningHost - 1
          }
        }
      }
      
    }
    Write-Log 1  "HostpoolName:$hostpoolname, NumberofRunnighosts:$numberOfRunningHost" "Info"
    $depthBool = $true
    Write-UsageLog $hostPoolName $numberOfRunningHost $depthBool
}
  Write-Log 3 "End WVD Tenant Scale Optimization." "Info"
}
else {
  Write-Log 3 "$hostPoolName hostpool loadbalancer type is $($hostpoolInfo.LoadBalancerType)" "Info"
  ##### Check if it is during the peak or off-peak time ##### 
  if ($CurrentDateTime -ge $BeginPeakDateTime -and $CurrentDateTime -le $EndPeakDateTime) {
    Write-Host "It is in peak hours now"
    Write-Log 3 "Peak hours: starting session hosts as needed based on current workloads." "Info"
    ##### Get session hosts in the host pool #####
    try {
      $RDSessionHost = Get-RdsSessionHost -TenantName $tenantName -HostPoolName $hostPoolName -ErrorAction SilentlyContinue
    }
    catch {
      Write-Log 1 "Failed to retrieve RDS session hosts in hostPool $($hostPoolName) : $($_.exception.message)" "Error"
      exit 1
    }

    ##### Get the user sessions in the host pool #####
    try {
      $hostPoolUserSessions = Get-RdsUserSession -TenantName $tenantName -HostPoolName $hostPoolName
    }
    catch {
      Write-Log 1 "Failed to retrieve user sessions in hostPool:$($hostPoolName) with error: $($_.exception.message)" "Error"
      exit 1
    }

    ##### Check number of running session hosts #####
    $numberOfRunningHost = 0

	##### Total of running cores #####
    $totalRunningCores = 0

    ##### Total capacity of sessions of running VMs #####
    $AvailableSessionCapacity = 0

    foreach ($sessionHost in $RDSessionHost.sessionhostname) {
      Write-Log 1 "Checking session host: $($sessionHost)" "Info"
           
      $VMName = $sessionHost.Split(".")[0]
      $roleInstance = Get-AzureRmVM -Status | Where-Object { $_.Name.Contains($VMName) }
      if ($sessionHost.ToLower().Contains($roleInstance.Name.ToLower())) {
        ##### Check Azure VM is running #####
        if ($roleInstance.PowerState -eq "VM running") {
          $numberOfRunningHost = $numberOfRunningHost + 1
          ##### Calculate available capacity of sessions #####
          $roleSize = Get-AzureRmVMSize -Location $roleInstance.Location | Where-Object { $_.Name -eq $roleInstance.HardwareProfile.VmSize }
          $AvailableSessionCapacity = $AvailableSessionCapacity + $roleSize.NumberOfCores * $SessionThresholdPerCPU
          $totalRunningCores = $totalRunningCores + $roleSize.NumberOfCores
        }

      }

    }
    Write-Log 1 "Current number of running hosts:$numberOfRunningHost" "Info"

    if ($numberOfRunningHost -lt $MinimumNumberOfRDSH) {

      Write-Log 1 "Current number of running session hosts is less than minimum requirements, start session host ..." "Info"

      ##### Start VM to meet the minimum requirement #####
      foreach ($sessionHost in $RDSessionHost.sessionhostname) {

        ##### Check whether number of running VMs meets the minimum or not #####
        if ($numberOfRunningHost -lt $MinimumNumberOfRDSH) {

          $VMName = $sessionHost.Split(".")[0]
          $roleInstance = Get-AzureRmVM -Status | Where-Object { $_.Name.Contains($VMName) }

          if ($sessionHost.ToLower().Contains($roleInstance.Name.ToLower())) {

            ##### Check if the azure VM is running #####
            if ($roleInstance.PowerState -ne "VM running") {
              $getShsinfo = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostPoolName

              if ($getShsinfo.AllowNewSession -eq $false) {
                Set-RdsSessionHost -TenantName $tenantName -HostPoolName $hostPoolName -Name $sessionHost -AllowNewSession $true

              }
              ##### Start the azure VM #####
              try {
                Start-AzureRmVM -Name $roleInstance.Name -Id $roleInstance.Id -ErrorAction SilentlyContinue
              }
              catch {
                Write-Log 1 "Failed to start Azure VM: $($roleInstance.Name) with error: $($_.exception.message)" "Error"
                exit 1
              }
              ##### Wait for VM to start #####
              $IsVMStarted = $false
              while (!$IsVMStarted) {

                $vm = Get-AzureRmVM -Status | Where-Object { $_.Name -eq $roleInstance.Name }

                if ($vm.PowerState -eq "VM running" -and $vm.ProvisioningState -eq "Succeeded") {
                  $IsVMStarted = $true
                  Set-RdsSessionHost -TenantName $tenantName -HostPoolName $hostPoolName -Name $sessionHost -AllowNewSession $true
                }
              }
              ##### Calculate available capacity of sessions #####
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
      ##### Check if the available capacity meets the number of sessions #####
      Write-Log 1 "Current total number of user sessions: $(($hostPoolUserSessions).Count)" "Info"
      Write-Log 1 "Current available session capacity is: $AvailableSessionCapacity" "Info"
      if ($hostPoolUserSessions.Count -ge $AvailableSessionCapacity) {
        Write-Log 1 "Current available session capacity is less than demanded user sessions, starting session host" "Info"
        ##### Running out of capacity, we need to start more VMs if there are any #####
        foreach ($sessionHost in $RDSessionHost.sessionhostname) {
          if ($hostPoolUserSessions.Count -ge $AvailableSessionCapacity) {
            $VMName = $sessionHost.Split(".")[0]
            $roleInstance = Get-AzureRmVM -Status | Where-Object { $_.Name.Contains($VMName) }

            if ($sessionHost.ToLower().Contains($roleInstance.Name.ToLower())) {
              ##### Check if the Azure VM is running #####

              if ($roleInstance.PowerState -ne "VM running") {
                $getShsinfo = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostPoolName
                if ($getShsinfo.AllowNewSession -eq $false) {
                  Set-RdsSessionHost -TenantName $tenantName -HostPoolName $hostPoolName -Name $sessionHost -AllowNewSession $true

                }
                ##### Start Azure VMs #####
                try {
                  Start-AzureRmVM -Name $roleInstance.Name -Id $roleInstance.Id -ErrorAction SilentlyContinue

                }
                catch {
                  Write-Log 1 "Failed to start Azure VM: $($roleInstance.Name) with error: $($_.exception.message)" "Error"
                  exit 1
                }
                ##### Wait for the VM to start #####
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
                ##### Calculate available capacity of sessions #####
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
              ##### Break out of the inner foreach loop once a match is found and checked #####
            }
          }
        }
      }
    }
    Write-Log 1 "HostpoolName:$hostpoolName, TotalRunningCores:$totalRunningCores NumberOfRunningHost:$numberOfRunningHost" "Info"
    ##### Write to the usage log #####
    $depthBool = $false
    Write-UsageLog $hostPoolName $totalRunningCores $numberOfRunningHost $depthBool
  }
  #####Peak or not peak hour #####
  else
  {
    Write-Host "It is Off-peak hours"
    Write-Log 3 "It is off-peak hours. Starting to scale down RD session hosts..." "Info"
    Write-Host ("Processing hostPool {0}" -f $hostPoolName)
    Write-Log 3 "Processing hostPool $($hostPoolName)"
    ##### Get the Session Hosts in the hostPool #####
    try {
      $RDSessionHost = Get-RdsSessionHost -TenantName $tenantName -HostPoolName $hostPoolName
    }
    catch {
      Write-Log 1 "Failed to retrieve session hosts in hostPool: $($hostPoolName) with error: $($_.exception.message)" "Error"
      exit 1
    }
    ##### Check the number of running session hosts #####
    $numberOfRunningHost = 0

    ##### Total of running cores #####
    $totalRunningCores = 0

    foreach ($sessionHost in $RDSessionHost.sessionhostname) {

      $VMName = $sessionHost.Split(".")[0]
      $roleInstance = Get-AzureRmVM -Status | Where-Object { $_.Name.Contains($VMName) }

      if ($sessionHost.ToLower().Contains($roleInstance.Name.ToLower())) {
        ##### Check if the Azure VM is running #####

        if ($roleInstance.PowerState -eq "VM running") {
          $numberOfRunningHost = $numberOfRunningHost + 1

          ##### Calculate available capacity of sessions #####
          $roleSize = Get-AzureRmVMSize -Location $roleInstance.Location | Where-Object { $_.Name -eq $roleInstance.HardwareProfile.VmSize }

          $totalRunningCores = $totalRunningCores + $roleSize.NumberOfCores
        }
      }
    }
    if ($numberOfRunningHost -gt $MinimumNumberOfRDSH) {
      ##### Shutdown VM to meet the minimum requirement #####

      foreach ($sessionHost in $RDSessionHost.sessionhostname) {
        if ($numberOfRunningHost -gt $MinimumNumberOfRDSH) {

          $VMName = $sessionHost.Split(".")[0]
          $roleInstance = Get-AzureRmVM -Status | Where-Object { $_.Name.Contains($VMName) }

          if ($sessionHost.ToLower().Contains($roleInstance.Name.ToLower())) {
            ##### check if the Azure VM is running #####

            if ($roleInstance.PowerState -eq "VM running") {
              ##### Check the role isntance status is ReadyRole or not, before setting the session host #####
              $isInstanceReady = $false
              $numOfRetries = 0

              while (!$isInstanceReady -and $num -le 3) {
                $numOfRetries = $numOfRetries + 1
                $instance = Get-AzureRmVM -Status | Where-Object { $_.Name -eq $roleInstance.Name }
                if ($instance -ne $null -and $instance.ProvisioningState -eq "Succeeded") {
                  $isInstanceReady = $true
                }
            
              }

              if ($isInstanceReady) {
                ##### Ensure the running Azure VM is set to drain mode #####
                try {
                  Set-RdsSessionHost -TenantName $tenantName -HostPoolName $hostPoolName -Name $sessionHost -AllowNewSession $false -ErrorAction SilentlyContinue
                }
                catch {

                  Write-Log 1 "Failed to set drain mode on session host: $($sessionHost.SessionHost) with error: $($_.exception.message)" "Error"
                  exit 1

                }
                
                ##### Get the user sessions in the host pool #####
                try {

                  $hostPoolUserSessions = Get-RdsUserSession -TenantName $tenantName -HostPoolName $hostPoolName

                }
                catch {
                  Write-Log 1 "Failed to retrieve user sessions in hostPool: $($hostPoolName) with error: $($_.exception.message)" "Error"
                  exit 1
                }

                $hostUserSessionCount = ($hostPoolUserSessions | Where-Object -FilterScript { $_.sessionhostname -eq $sessionHost }).Count
                Write-Log 1 "Counting the current sessions on the host $sessionhost...:$hostUserSessionCount" "Info"
                
                $existingSession = 0

                foreach ($session in $hostPoolUserSessions) {

                  if ($session.sessionhostname -eq $sessionHost) {

                    if ($LimitSecondsToForceLogOffUser -ne 0) {
                      ##### Send notification #####
                      try {

                        Send-RdsUserSessionMessage -TenantName $tenantName -HostPoolName $hostPoolName -SessionHostName $sessionHost -SessionId $session.sessionid -MessageTitle $LogOffMessageTitle -MessageBody "$($LogOffMessageBody) You will logged off in $($LimitSecondsToForceLogOffUser) seconds." -NoUserPrompt #:$false

                      }
                      catch {

                        Write-Log 1 "Failed to send message to user with error: $($_.exception.message)" "Error"
                        exit 1

                      }
                    }

                    $existingSession = $existingSession + 1
                  }
                }
                ##### Wait for n seconds to log off user #####
                Start-Sleep -Seconds $LimitSecondsToForceLogOffUser

                if ($LimitSecondsToForceLogOffUser -ne 0) {
                  ##### Force users to log off #####
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
                      ##### Log off user #####
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
                ##### Check session count before shutting down VM #####
                if ($existingSession -eq 0) {

                  ##### Shutdown the Azure VM ##### 
                  try {
                    Write-Log 1 "Stopping Azure VM: $($roleInstance.Name) and waiting for it to complete ..." "Info"
                    Stop-AzureRmVM -Name $roleInstance.Name -Id $roleInstance.Id -Force -ErrorAction SilentlyContinue

                  }
                  catch {
                    Write-Log 1 "Failed to stop Azure VM: $($roleInstance.Name) with error: $($_.exception.message)" "Error"
                    exit 1
                  }
                  ##### Wait for the VM to stop ##### 
                  $IsVMStopped = $false
                  while (!$IsVMStopped) {

                    $vm = Get-AzureRmVM -Status | Where-Object { $_.Name -eq $roleInstance.Name }

                    if ($vm.PowerState -eq "VM deallocated") {
                      $IsVMStopped = $true
                      Write-Log 1 "Azure VM has been stopped: $($roleInstance.Name) ..." "Info"
                    } else {
                      Write-Log 3 "Waiting for Azure VM to stop $($roleInstance.Name) ..." "Info"
                    }
                  }
                  ##### Ensure Azure VMs that are off have AllowNewSession mode set to True #####
                  try {
                    Set-RdsSessionHost -TenantName $tenantName -HostPoolName $hostPoolName -Name $sessionHost -AllowNewSession $true -ErrorAction SilentlyContinue
                  }
                  catch {
                    Write-Log 1 "Failed to set drain mode on session host: $($sessionHost.SessionHost) with error: $($_.exception.message)" "Error"
                    exit 1
                  }
                  $vm = Get-AzureRmVM -Status | Where-Object { $_.Name -eq $roleInstance.Name }
                  $roleSize = Get-AzureRmVMSize -Location $roleInstance.Location | Where-Object { $_.Name -eq $roleInstance.HardwareProfile.VmSize }
                  ##### Decrement number of running session host #####
                  $numberOfRunningHost = $numberOfRunningHost - 1
                  $totalRunningCores = $totalRunningCores - $roleSize.NumberOfCores
                }
              }
            }
          }
        }
      }

    }
    ##### Write to the usage log #####
	Write-Log 1 "HostpoolName:$hostpoolName, TotalRunningCores:$totalRunningCores NumberOfRunningHost:$numberOfRunningHost" "Info"
    
    $depthBool = $false
    Write-UsageLog $hostPoolName $totalRunningCores $numberOfRunningHost $depthBool
  } 
  ##### Scale host pools ##### 
  Write-Log 3 "End WVD Tenant Scale Optimization." "Info"
}