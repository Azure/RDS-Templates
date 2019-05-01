<#
Copyright 2019 Microsoft
Version 2.0 March 2019
.SYNOPSIS
	This is a sample script for automatically scaling Tenant Environment WVD Host Servers in Microsoft Azure
.DESCRIPTION
	This script will start/stop Tenant WVD host VMs based on the number of user sessions and peak/off-peak time period specified in the configuration file.
	During the peak hours, the script will start necessary session hosts in the host pool to meet the demands of users.
	During the off-peak hours, the script will shut down session hosts and only keep the minimum number of session hosts.
	This script depends on two PowerShell modules: Azure RM and Windows Virtual Desktop modules. To install Azure RM module execute the following command. Use "-AllowClobber" parameter if you have more than one version of PowerShell modules installed.
	PS C:\>Install-Module Az  -AllowClobber
#>
#Requires -Modules AzTable, Microsoft.RDInfra.RDPowerShell

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$ErrorActionPreference = "Stop"

#region Functions and other supporting elements

function Write-Log
{
	<#
	.SYNOPSIS
		Function for writing the log
	#>
    param
    (
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error")] [string]$severity = 'Info',
        [string]$logname = $rdmiTenantlog,
        [string]$color = "white"
    )

    $time = ([System.DateTime]::UtcNow)

    Add-Content $logname -Value ("{0} - [{1}] {2}" -f $time, $severity, $Message)
}


function Write-UsageLog
{
	<# 
	.SYNOPSIS
		Function for writing the usage log
	#>
    param
    (
        [string]$hostpoolName,
        [int]$corecount,
        [int]$vmcount,
        [bool]$depthBool = $True,
        [string]$logfilename = $RdmiTenantUsagelog
    )

    $time = ([System.DateTime]::UtcNow)

    if ($depthBool)
    {
        Add-Content $logfilename -Value ("{0}, {1}, {2}" -f $time, $hostpoolName, $vmcount)
    }
    else
    {
        Add-Content $logfilename -Value ("{0}, {1}, {2}, {3}" -f $time, $hostpoolName, $corecount, $vmcount)
    }
}

function LogCleanUp
{
	<#
	.SYNOPSIS
		Cleaning up Execution and TenantLog logs after a certain threshold in days
	#>
	param
	(
		[string[]]$LogFiles,
		[int]$TruncateFilesThresholdDays
	)

	$firstlogdate = $null
	foreach ($FileName in $LogFiles)
	{
		if ($FileName.Contains("WVDTenantScale"))
		{
			$content = (Get-Content -Path $FileName)[0]

			try
			{
				$firstlogdate = [datetime]$content.split("-")[0]
			}
			catch {}
		}

		if ($firstlogdate -ne $null)
		{
			if ((Get-Date).Subtract($firstlogdate).TotalDays -gt $TruncateFilesThresholdInDays)
			{
				if ($FileName.Contains("ExecutionTranscript"))
				{
				 	Stop-Transcript
					Start-Transcript -Path $FileName -Force
				}
				else
				{
					Clear-Content $FileName
				}
			}
		}
	}
}

#endregion

$CurrentPath = Split-Path $script:MyInvocation.MyCommand.Path

# Files path
$XMLPath = "$CurrentPath\Config.xml"
$rdmiTenantlog = "$CurrentPath\WVDTenantScale.log"
$RdmiTenantUsagelog = "$CurrentPath\WVDTenantUsage.log"
$ExecutionStranscriptLog = "$CurrentPath\ExecutionTranscript.log"
$LogFiles = @($rdmiTenantlog,$ExecutionStranscriptLog)

# Starting Execution Transcript - This allows us to check for unhandled exceptions
Start-Transcript -Path $ExecutionStranscriptLog -Append

Write-Verbose -Verbose "Execution time in UTC: $([System.DateTime]::UtcNow)"

# Verify XML file 
if (Test-Path $XMLPath)
{
    Write-Verbose "Found $XMLPath"
    Write-Verbose "Validating file..."
    try
    {
        $Variable = [xml](Get-Content $XMLPath)
    }
    catch
    {
        $Validate = $false
        Write-Log "$XMLPath is invalid. Check XML syntax - Unable to proceed" "Info"
        Write-Error "$XMLPath is invalid. Check XML syntax - Unable to proceed"
    }
}
else
{
    $Validate = $false
    Write-Log "Missing $XMLPath - Unable to proceed" "Error"
    Write-Error "Missing $XMLPath - Unable to proceed"
}

# Load XML configuration values as variables 
Write-Log "Loading values from Config.xml" "Info"

$Variable.RDMIScale.Azure | ForEach-Object { $_.Variable } | Where-Object { $_.Name -ne $null } | ForEach-Object { Set-Variable -Name $_.Name -Value $_.Value -Scope Global }
$Variable.RDMIScale.RdmiScaleSettings | ForEach-Object { $_.Variable } | Where-Object { $_.Name -ne $null } | ForEach-Object { Set-Variable -Name $_.Name -Value $_.Value -Scope Global}
$Variable.RDMIScale.Deployment | ForEach-Object { $_.Variable } | Where-Object { $_.Name -ne $null } | ForEach-Object { Set-Variable -Name $_.Name -Value $_.Value -Scope Global }

LogCleanUp -LogFiles $LogFiles -TruncateFilesThresholdInDays $TruncateFilesThresholIndDays

# Load functions/module
Import-Module Az.Accounts -MinimumVersion 1.5.1
Import-Module AzTable
Import-Module Microsoft.RdInfra.RdPowershell
. $CurrentPath\ScalingScriptHACoreHelper.ps1

# Getting credentials
if ([string]::IsNullOrEmpty($WVDTenantAdminAadTenantId))
{
    $WVDTenantAdminAadTenantId = $AADTenantId
}

# MSI based authentication
#    - In order to rely on this, please add the MSI accounts as VM contributors at resource group level
#    - Also, assign storage account contributors to MSI accounts at the storage account holding the tables
Add-AzAccount -Identity
Select-AzSubscription -SubscriptionId $currentAzureSubscriptionId

# HA - Decision to exit if running or take ownership
$PartitionKey = "ScalingOwnership"
$RowKey = "ScalingOwnerEntity"

# Sanitizing HostPoolName to become part of table name
$CharsToCleanUp =" !@#$%^&*()_+-=~:;/\[]{}<>,.?|`"```'"

$SanitizedHostPoolName = (Get-Culture).TextInfo.ToTitleCase($HostPoolName)
for ($i=0;$i -lt $CharsToCleanUp.Length;$i++)
{
    $SanitizedHostPoolName = $SanitizedHostPoolName.Replace($CharsToCleanUp[$i].ToString(),"")
}

$ScalingHATableName = [string]::Format("WVDScalingHa{0}",$SanitizedHostPoolName)
$ScalingLogTableName = [string]::Format("WVDScalingLog{0}",$SanitizedHostPoolName)
$ActivityId = ([guid]::NewGuid().Guid)

Write-Log "ActivityId: $ActivityId - Please use this guid to query this execution on $ScalingLogTableName table." "Info"

# Get tables
$ScalingHATable = Get-AzTableTable -resourceGroup $StorageAccountRG -TableName $ScalingHATableName -storageAccountName $StorageAccountName
$ScalingLogTable = Get-AzTableTable -resourceGroup $StorageAccountRG -TableName $ScalingLogTableName -storageAccountName $StorageAccountName

if ($ScalingHATable -eq $null) 
{
    Write-Log "An error ocurred trying to obtain table $ScalingHATableName in Storage Account $StorageAccountName at Resource Group $StorageAccountRG" "Error"
    exit 1
}
elseif ($ScalingLogTable -eq $null)
{
    Write-Log "An error ocurred trying to obtain table $ScalingLogTable in Storage Account $StorageAccountName at Resource Group $StorageAccountRG" "Error"
    exit 1
}

# Testing if executing should continue due to HA
if ([string]::IsNullOrEmpty($HAOwnerName))
{
    $HAOwnerName = [system.environment]::MachineName
}

$OwnerToken = GetHaOwnerToken -PartitionKey $PartitionKey `
                              -RowKey $RowKey `
                              -HaTable $ScalingHATable `
                              -LogTable $ScalingLogTable `
                              -Owner $HAOwnerName `
                              -TakeOverMin $TakeOverThresholdMin `
                              -LongRunningTakeOverMin $LongRunningTakeOverThresholdMin `
                              -ActivityId $ActivityId

if ($OwnerToken.ShouldExit)
{
    $msg = "After evaluation, no further execution will take place at $HAOwnerName"
    GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable -Owner $HAOwnerName -ActivityId $ActivityId
    exit
}

$msg = "`($HAOwnerName`) Executing scaling script..."
GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable

# Update token if applicable
$OwnerToken.Status = [HAStatuses]::Running
UpdateOwnerToken -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken

#region Scaling Logic

# Setting RDS context
$isWVDServicePrincipal = ($isWVDServicePrincipal -eq "True")

# Building credentials from KeyVault
$WVDPrincipalPwd = (Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $KeyVaultSecretName).SecretValue
$WVDCreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList($Username, $WVDPrincipalPwd)

# WVD Authentication
if (!$isWVDServicePrincipal)
{
    try
    {
        Add-RdsAccount -DeploymentUrl $RDBroker -Credential $WVDCreds
        $msg = "Authenticated as standard account for WVD."
        GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
    }
    catch
    {
        $msg = "Failed to authenticate with WVD Tenant with a standard account: $($_.exception.message)" 
        GlobalLog -Message $msg -LogLevel ([LogLevel]::Error) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
        exit 1
    }
}
else
{
    try
    {
        Add-RdsAccount -DeploymentUrl $RDBroker -TenantId $WVDTenantAdminAadTenantId -Credential $WVDCreds -ServicePrincipal
        $msg = "Authenticated as service principal account for WVD."
        GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
    }
    catch
    {
        $msg = "Failed to authenticate with WVD Tenant with the service principal: $($_.exception.message)" 
        GlobalLog -Message $msg -LogLevel ([LogLevel]::Error) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
        exit 1
    }
}

# Set context to the appropriate tenant group #
$msg = "Switching RDS Context to the $tenantGroupName context"
GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
Set-RdsContext -TenantGroupName $tenantGroupName

# Construct Begin time and End time for the Peak period #
$CurrentDateTime = Get-Date
$msg = "Starting WVD Tenant Hosts Scale Optimization: Current time in local timezone `'$(([System.TimeZoneInfo]::Local).DisplayName)`' is: $CurrentDateTime"
GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable

$BeginPeakDateTime = [datetime]::Parse($CurrentDateTime.ToShortDateString() + ' ' + $BeginPeakTime)
$EndPeakDateTime = [datetime]::Parse($CurrentDateTime.ToShortDateString() + ' ' + $EndPeakTime)

# Check the calculated end time is later than begin time in case of time zone #
if ($EndPeakDateTime -lt $BeginPeakDateTime)
{
    $EndPeakDateTime = $EndPeakDateTime.AddDays(1)
}

ExitIfNotOwner -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken
$hostpoolInfo = Get-RdsHostPool -TenantName $tenantName -Name $hostPoolName

if ($hostpoolInfo.LoadBalancerType -eq "DepthFirst")
{
    $msg = "$hostPoolName hostpool loadbalancer type is $($hostpoolInfo.LoadBalancerType)"
    GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable

    $msg = "Starting WVD Tenant Hosts Scale Optimization: Current in local timezone `'$(([System.TimeZoneInfo]::Local).DisplayName)`' Date Time is: $CurrentDateTime"
    GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable

    if ($CurrentDateTime -ge $BeginPeakDateTime -and $CurrentDateTime -le $EndPeakDateTime)
    {
        $msg = "It is in peak hours now"
        GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable

        $msg = "Peak hours: starting session hosts as needed based on current workloads."
        GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable

        $hostpoolMaxSessionLimit = $hostpoolinfo.MaxSessionLimit

        # Get the session hosts in the hostpool #
        try
        {
            ExitIfNotOwner -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken
            $getHosts = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostpoolname | Sort-Object $_.sessionhostname
        }
        catch
        {
            $OwnerToken.Status = [HAStatuses]::Failed
            UpdateOwnerToken -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken
            $msg = "Failed to retrieve sessionhost in hostpool $($hostPoolName) : $($_.exception.message)"
            GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
            exit 1
        }

        if ($hostpoolMaxSessionLimit -le 10)
        {
            $sessionlimit = $hostpoolMaxSessionLimit - 1
        }
        elseif ($hostpoolMaxSessionLimit -le 50)
        {
            $sessionlimitofhost = $hostpoolMaxSessionLimit / 4
            $var = $hostpoolMaxSessionLimit - $sessionlimitofhost
            $sessionlimit = [math]::Round($var)
        }
        elseif ($hostpoolMaxSessionLimit -gt 50)
        {
            $sessionlimit = $hostpoolMaxSessionLimit - 10
        }
 
        $msg = "Hostpool Maximum Session Limit: $($hostpoolMaxSessionLimit)"
        GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable

        # Check the number of running session hosts #
        $numberOfRunningHost = 0
        foreach ($sessionHost in $getHosts)
        {
            $msg = "Checking session host:$($sessionHost.SessionHostName | Out-String)  of sessions:$($sessionHost.Sessions) and status:$($sessionHost.Status)"
            GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable

            $sessionCapacityofhost = $sessionhost.Sessions
            if ($sessionlimit -lt $sessionCapacityofhost -or $sessionHost.Status -eq "Available")
            {
                $numberOfRunningHost = $numberOfRunningHost + 1
            }
        }

        $msg = "Current number of running hosts: $numberOfRunningHost"
        GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable

        if ($numberOfRunningHost -lt $MinimumNumberOfRDSH)
        {
            $msg =  "Current number of running session hosts is less than minimum requirements, start session host ..."
            GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable

            foreach ($sessionhost in $getHosts)
            {
                if ($numberOfRunningHost -lt $MinimumNumberOfRDSH)
                {
                    $hostsessions = $sessionHost.Sessions

                    if ($hostpoolMaxSessionLimit -ne $hostsessions)
                    {
                        if ($sessionhost.Status -eq "Unavailable")
                        {
                            $sessionhostname = $sessionhost.sessionhostname

                            # Check session host is in drain mode
                            ExitIfNotOwner -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken
                            $checkAllowNewSession = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostpoolname -Name $sessionhostname

                            if (!($checkAllowNewSession.AllowNewSession))
                            {
                                $Action = "Set-RdsSessionHost -TenantName `$tenantname -HostPoolName `$hostpoolname -Name `$sessionhostname -AllowNewSession `$true"
                                RunActionIfOwnerOrExit -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken -Action $Action
                            }

                            $VMName = $sessionHostname.Split(".")[0]
                            # Start the Azure VM
                            try
                            {
                                $Action = "Get-AzVM -Name $VMName | Start-AzVM"
                                RunActionIfOwnerOrExit -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken -Action $Action
                             }
                            catch
                            {
                                $OwnerToken.Status = [HAStatuses]::Failed
                                UpdateOwnerToken -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken
                                $msg = "Failed to start Azure VM: $($VMName) with error: $($_.exception.message)"
                                GlobalLog -Message $msg -LogLevel ([LogLevel]::Error) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
                                exit 1
                            }

                            # Wait for the sessionhost is available
                            $IsHostAvailable = $false
                            while (!$IsHostAvailable)
                            {
                                $hoststatus = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostpoolname -Name $sessionHost.sessionhostname

                                if ($hoststatus.Status -eq "Available")
                                {
                                    $IsHostAvailable = $true
                                }

                                Start-Sleep -Seconds 30
                            }
                        }
                    }
                    $numberOfRunningHost = $numberOfRunningHost + 1
                }
            }
        }
        else
        {
            ExitIfNotOwner -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken
            $getHosts = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostpoolname | Sort-Object "Sessions" -Descending | Sort-Object Status

            foreach ($sessionhost in $getHosts)
            {
                if (!($sessionHost.Sessions -eq $hostpoolMaxSessionLimit))
                {
                    if ($sessionHost.Sessions -ge $sessionlimit)
                    {
                        foreach ($sHost in $getHosts)
                        {
                            if ($sHost.Status -eq "Available" -and $sHost.Sessions -eq 0) { break }

                            if ($sHost.Status -eq "Unavailable")
                            {
                                $msg = "Existing Sessionhost Sessions value reached near by hostpool maximumsession limit need to start the session host"
                                GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable

                                $sessionhostname = $sHost.sessionhostname

                                # Check session host is in drain mode
                                ExitIfNotOwner -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken
                                $checkAllowNewSession = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostpoolname -Name $sessionhostname

                                if (!($checkAllowNewSession.AllowNewSession))
                                {
                                    $Action = "Set-RdsSessionHost -TenantName `$tenantname -HostPoolName `$hostpoolname -Name `$sessionhostname -AllowNewSession `$true"
                                    RunActionIfOwnerOrExit -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken -Action $Action
                                }

                                $VMName = $sessionHostname.Split(".")[0]

                                # Start the Azure VM
                                try
                                {
                                    $Action = "Get-AzVM -Name $VMName | Start-AzVM"
                                    RunActionIfOwnerOrExit -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken -Action $Action
                                }
                                catch
                                {
                                    $OwnerToken.Status = [HAStatuses]::Failed
                                    UpdateOwnerToken -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken
                                    $msg = "Failed to start Azure VM: $($VMName) with error: $($_.exception.message)"
                                    GlobalLog -Message $msg -LogLevel ([LogLevel]::Error) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
                                    exit 1
                                }

                                # Wait for the sessionhost is available
                                $IsHostAvailable = $false
                                while (!$IsHostAvailable)
                                {
                                    $hoststatus = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostpoolname -Name $sHost.sessionhostname

                                    if ($hoststatus.Status -eq "Available")
                                    {
                                        $IsHostAvailable = $true
                                    }

                                    Start-Sleep -Seconds 30
                                }

                                $numberOfRunningHost = $numberOfRunningHost + 1
                            }
                        }
                    }
                }
            }
        }

        $msg =  "HostpoolName:$hostpoolname, NumberofRunnighosts:$numberOfRunningHost"
        GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable

        $depthBool = $true
        Write-UsageLog $hostPoolName $numberOfRunningHost $depthBool
    }
    else
    {
        $msg =  "It is off-peak hours. Starting to scale down RD session hosts..."
        GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable

        $msg =  [string]::Format("Processing hostPool {0}", $hostPoolName)
        GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable

        try
        {
            ExitIfNotOwner -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken
            $getHosts = Get-RdsSessionHost -TenantName $tenantName -HostPoolName $hostPoolName | Sort-Object Sessions
        }
        catch
        {
            $OwnerToken.Status = [HAStatuses]::Failed
            UpdateOwnerToken -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken
            $msg = "Failed to retrieve session hosts in hostPool: $($hostPoolName) with error: $($_.exception.message)"
            GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
            exit 1
        }

        # Check number of running session hosts
        $numberOfRunningHost = 0
        foreach ($sessionHost in $getHosts)
        {
            if ($sessionHost.Status -eq "Available")
            {
                $numberOfRunningHost = $numberOfRunningHost + 1
            }
        }

        if ($numberOfRunningHost -gt $MinimumNumberOfRDSH)
        {
            foreach ($sessionHost in $getHosts.sessionhostname)
            {
                if ($numberOfRunningHost -gt $MinimumNumberOfRDSH)
                {
                    ExitIfNotOwner -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken
                    $sessionHostinfo1 = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostpoolname -Name $sessionHost

                    if ($sessionHostinfo1.Status -eq "Available")
                    {
                        # Ensure the running Azure VM is set as drain mode
                        try
                        {
                            $Action = "Set-RdsSessionHost -TenantName `$tenantName -HostPoolName `$hostPoolName -Name `$sessionHost -AllowNewSession `$false"
                            RunActionIfOwnerOrExit -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken -Action $Action
                        }
                        catch
                        {
                            $OwnerToken.Status = [HAStatuses]::Failed
                            UpdateOwnerToken -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken                            
                            $msg = "Failed to set drain mode on session host: $($sessionHost.SessionHost) with error: $($_.exception.message)"
                            GlobalLog -Message $msg -LogLevel ([LogLevel]::Error) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
                            exit 1
                        }

                        # Get the user sessions in the host pool
                        try
                        {
                            ExitIfNotOwner -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken
                            $hostPoolUserSessions = Get-RdsUserSession -TenantName $tenantName -HostPoolName $hostPoolName
                        }
                        catch
                        {
                            $OwnerToken.Status = [HAStatuses]::Failed
                            UpdateOwnerToken -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken
                            $msg = "Failed to retrieve user sessions in hostPool: $($hostPoolName) with error: $($_.exception.message)"
                            GlobalLog -Message $msg -LogLevel ([LogLevel]::Error) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
                            exit 1
                        }

                        $hostUserSessionCount = ($hostPoolUserSessions | Where-Object -FilterScript { $_.sessionhostname -eq $sessionHost }).Count
                        $msg = "Counting the current sessions on the host $sessionhost...:$hostUserSessionCount"
                        GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
            
                        $existingSession = 0
                        foreach ($session in $hostPoolUserSessions)
                        {
                            if ($session.sessionhostname -eq $sessionHost)
                            {
                                if ($LimitSecondsToForceLogOffUser -ne 0)
                                {
                                    # Send notification
                                    try
                                    {
                                        ExitIfNotOwner -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken
                                        Send-RdsUserSessionMessage -TenantName $tenantName -HostPoolName $hostPoolName -SessionHostName $session.sessionhostname -SessionId $session.sessionid -MessageTitle $LogOffMessageTitle -MessageBody "$($LogOffMessageBody) You will logged off in $($LimitSecondsToForceLogOffUser) seconds." -NoUserPrompt
                                    }
                                    catch
                                    {
                                        $OwnerToken.Status = [HAStatuses]::Failed
                                        UpdateOwnerToken -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken  
                                        $msg = "Failed to send message to user with error: $($_.exception.message)"
                                        GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
                                        exit 1
                                    }
                                }

                                $existingSession = $existingSession + 1
                            }
                        }

                        # Wait for n seconds to log off user
                        Start-Sleep -Seconds $LimitSecondsToForceLogOffUser
                        
                        if ($LimitSecondsToForceLogOffUser -ne 0)
                        {
                            # Force users to log off
                            $msg =  "Force users to log off..."
                            GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
                            try
                            {
                                ExitIfNotOwner -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken
                                $hostPoolUserSessions = Get-RdsUserSession -TenantName $tenantName -HostPoolName $hostPoolName
                            }
                            catch
                            {
                                $OwnerToken.Status = [HAStatuses]::Failed
                                UpdateOwnerToken -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken       
                                $msg = "Failed to retrieve list of user sessions in hostPool: $($hostPoolName) with error: $($_.exception.message)"
                                GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
                                exit 1
                            }

                            foreach ($session in $hostPoolUserSessions)
                            {
                                if ($session.sessionhostname -eq $sessionHost)
                                {
                                    # Log off user
                                    try
                                    {
                                        $Action = "Invoke-RdsUserSessionLogoff -TenantName `$tenantName -HostPoolName `$hostPoolName -SessionHostName `$session.sessionhostname -SessionId `$session.sessionid -NoUserPrompt"
                                        RunActionIfOwnerOrExit -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken -Action $Action
                                        $existingSession = $existingSession - 1
                                    }
                                    catch
                                    {
                                        $OwnerToken.Status = [HAStatuses]::Failed
                                        UpdateOwnerToken -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken       
                                        $msg = "Failed to log off user with error: $($_.exception.message)"
                                        GlobalLog -Message $msg -LogLevel ([LogLevel]::Error) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
                                        exit 1
                                    }
                                }
                            }
                        }

                        $VMName = $sessionHost.Split(".")[0]

                        # Check session count before shutting down the VM
                        if ($existingSession -eq 0)
                        {
                            try
                            {
                                $msg = "Stopping Azure VM: $VMName and waiting for it to complete ..."
                                GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
                                $Action = "Get-AzVM -Name $VMName | Stop-AzVM -Force"
                                RunActionIfOwnerOrExit -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken -Action $Action
                            }
                            catch
                            {
                                $OwnerToken.Status = [HAStatuses]::Failed
                                UpdateOwnerToken -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken                                   
                                $msg = "Failed to stop Azure VM: $VMName with error: $_.exception.message"
                                GlobalLog -Message $msg -LogLevel ([LogLevel]::Error) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
                                exit 1
                            }
                        }
                        # Decrement number of running session host
                        $numberOfRunningHost = $numberOfRunningHost - 1
                    }
                }
            }
        }

        $msg =  "HostpoolName:$hostpoolname, NumberofRunnighosts:$numberOfRunningHost"
        GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable

        $depthBool = $true
        Write-UsageLog $hostPoolName $numberOfRunningHost $depthBool
    }

    $msg = "End WVD Tenant Scale Optimization."
    GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
}
else
{
    $msg = "$hostPoolName hostpool loadbalancer type is $($hostpoolInfo.LoadBalancerType)"
    GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable

    # Check if it is during the peak or off-peak time
    if ($CurrentDateTime -ge $BeginPeakDateTime -and $CurrentDateTime -le $EndPeakDateTime)
    {
        $msg = "Peak hours: starting session hosts as needed based on current workloads."
        GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable

        # Get session hosts in the host pool
        try
        {
            ExitIfNotOwner -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken
            $RDSessionHost = Get-RdsSessionHost -TenantName $tenantName -HostPoolName $hostPoolName
        }
        catch
        {
            $OwnerToken.Status = [HAStatuses]::Failed
            UpdateOwnerToken -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken      
            $msg = "Failed to retrieve RDS session hosts in hostPool $($hostPoolName) : $($_.exception.message)"
            GlobalLog -Message $msg -LogLevel ([LogLevel]::Error) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
            
            exit 1
        }

        # Get the user sessions in the host pool
        try
        {
            ExitIfNotOwner -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken
            $hostPoolUserSessions = Get-RdsUserSession -TenantName $tenantName -HostPoolName $hostPoolName
        }
        catch
        {
            $OwnerToken.Status = [HAStatuses]::Failed
            UpdateOwnerToken -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken      
            $msg = "Failed to retrieve user sessions in hostPool:$($hostPoolName) with error: $($_.exception.message)"
            GlobalLog -Message $msg -LogLevel ([LogLevel]::Error) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
            exit 1
        }

        $numberOfRunningHost = 0
        $totalRunningCores = 0
        $AvailableSessionCapacity = 0

        foreach ($sessionHost in $RDSessionHost.sessionhostname)
        {
            $msg = "Checking session host: $($sessionHost)"
            GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
           
            $VMName = $sessionHost.Split(".")[0]

            ExitIfNotOwner -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken
            $roleInstance = Get-AzVM -Status -Name $VMName

            if ($sessionHost.ToLower().Contains($roleInstance.Name.ToLower()))
            {
                # Check Azure VM is running
                if ($roleInstance.PowerState -eq "VM running")
                {
                    $numberOfRunningHost = $numberOfRunningHost + 1

                    # Calculate available capacity of sessions
                    $roleSize = Get-AzVMSize -Location $roleInstance.Location | Where-Object { $_.Name -eq $roleInstance.HardwareProfile.VmSize }
                    $AvailableSessionCapacity = $AvailableSessionCapacity + $roleSize.NumberOfCores * $SessionThresholdPerCPU
                    $totalRunningCores = $totalRunningCores + $roleSize.NumberOfCores
                }
            }
        }

        $msg = "Current number of running hosts:$numberOfRunningHost"
        GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable

        if ($numberOfRunningHost -lt $MinimumNumberOfRDSH)
        {
            $msg = "Current number of running session hosts is less than minimum requirements, start session host ..."
            GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable

            # Start VM to meet the minimum requirement
            foreach ($sessionHost in $RDSessionHost.sessionhostname)
            {
                # Check whether number of running VMs meets the minimum or not
                if ($numberOfRunningHost -lt $MinimumNumberOfRDSH)
                {
                    $VMName = $sessionHost.Split(".")[0]
                    ExitIfNotOwner -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken
                    $roleInstance = Get-AzVM -Status -Name $VMName

                    if ($sessionHost.ToLower().Contains($roleInstance.Name.ToLower()))
                    {
                        # Check if the azure VM is running
                        if ($roleInstance.PowerState -ne "VM running")
                        {
                            ExitIfNotOwner -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken
                            $getShsinfo = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostPoolName

                            if ($getShsinfo.AllowNewSession -eq $false)
                            {
                                $Action = "Set-RdsSessionHost -TenantName `$tenantName -HostPoolName `$hostPoolName -Name `$sessionHost -AllowNewSession `$true"
                                RunActionIfOwnerOrExit -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken -Action $Action
                            }

                            # Start the azure VM
                            try
                            {
                                $Action = "Start-AzVM -Name `$roleInstance.Name -Id `$roleInstance.Id"
                                RunActionIfOwnerOrExit -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken -Action $Action
                            }
                            catch
                            {
                                $OwnerToken.Status = [HAStatuses]::Failed
                                UpdateOwnerToken -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken      
                                $msg = "Failed to start Azure VM: $($roleInstance.Name) with error: $($_.exception.message)"
                                GlobalLog -Message $msg -LogLevel ([LogLevel]::Error) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
                                exit 1
                            }

                            # Wait for VM to start
                            $IsVMStarted = $false
                            while (!$IsVMStarted)
                            {
                                $vm = Get-AzVM -Status -Name $roleInstance.Name
                                if ($vm.PowerState -eq "VM running" -and $vm.ProvisioningState -eq "Succeeded")
                                {
                                    $IsVMStarted = $true
                                    Set-RdsSessionHost -TenantName $tenantName -HostPoolName $hostPoolName -Name $sessionHost -AllowNewSession $true
                                }

                                Start-Sleep -Seconds 30
                            }

                            # Calculate available capacity of sessions
                            $vm = Get-AzVM -Status -Name $roleInstance.Name
                            $roleSize = Get-AzVMSize -Location $roleInstance.Location | Where-Object { $_.Name -eq $roleInstance.HardwareProfile.VmSize }
                            $AvailableSessionCapacity = $AvailableSessionCapacity + $roleSize.NumberOfCores * $SessionThresholdPerCPU
                            $numberOfRunningHost = $numberOfRunningHost + 1
                            $totalRunningCores = $totalRunningCores + $roleSize.NumberOfCores
                            
                            if ($numberOfRunningHost -ge $MinimumNumberOfRDSH)
                            {
                                break
                            }
                        }
                    }
                }
            }
        }
        else
        {
            # Check if the available capacity meets the number of sessions
            $msg = "Current total number of user sessions: ($($hostPoolUserSessions).Count)"
            GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable

            $msg = "Current available session capacity is: $AvailableSessionCapacity"
            GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
        
            if ($hostPoolUserSessions.Count -ge $AvailableSessionCapacity)
            {
                $msg = "Current available session capacity is less than demanded user sessions, starting session host"
                GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable

                # Running out of capacity, we need to start more VMs if there are any
                foreach ($sessionHost in $RDSessionHost.sessionhostname)
                {
                    if ($hostPoolUserSessions.Count -ge $AvailableSessionCapacity)
                    {
                        $VMName = $sessionHost.Split(".")[0]

                        ExitIfNotOwner -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken
                        $roleInstance = Get-AzVM -Status -Name $VMName

                        if ($sessionHost.ToLower().Contains($roleInstance.Name.ToLower()))
                        {
                            # Check if the Azure VM is running

                            if ($roleInstance.PowerState -ne "VM running")
                            {
                                ExitIfNotOwner -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken
                                $getShsinfo = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostPoolName
                                if ($getShsinfo.AllowNewSession -eq $false)
                                {
                                    $Action = "Set-RdsSessionHost -TenantName `$tenantName -HostPoolName `$hostPoolName -Name `$sessionHost -AllowNewSession $true"
                                    RunActionIfOwnerOrExit -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken -Action $Action
                                }

                                # Start Azure VMs
                                try
                                {
                                    $Action = "Start-AzVM -Name `$roleInstance.Name -Id `$roleInstance.Id"
                                    RunActionIfOwnerOrExit -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken -Action $Action
                                }
                                catch
                                {
                                    $OwnerToken.Status = [HAStatuses]::Failed
                                    UpdateOwnerToken -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken      
                                    $msg = "Failed to start Azure VM: $($roleInstance.Name) with error: $($_.exception.message)"
                                    GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
                                    exit 1
                                }

                                # Wait for the VM to start
                                $IsVMStarted = $false
                                while (!$IsVMStarted)
                                {
                                    $vm = Get-AzVM -Status -Name $roleInstance.Name

                                    if ($vm.PowerState -eq "VM running" -and $vm.ProvisioningState -eq "Succeeded")
                                    {
                                        $IsVMStarted = $true
                                        $msg = "Azure VM has been started: $($roleInstance.Name) ..."
                                        GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
                                    }
                                    else
                                    {
                                        $msg = "Waiting for Azure VM to start $($roleInstance.Name) ..."
                                        GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
                                    }

                                    Start-Sleep 
                                }

                                # Calculate available capacity of sessions
                                $vm = Get-AzVM -Status -Name $roleInstance.Name
                                $roleSize = Get-AzVMSize -Location $roleInstance.Location | Where-Object { $_.Name -eq $roleInstance.HardwareProfile.VmSize }

                                $AvailableSessionCapacity = $AvailableSessionCapacity + $roleSize.NumberOfCores * $SessionThresholdPerCPU
                                $numberOfRunningHost = $numberOfRunningHost + 1
                                $totalRunningCores = $totalRunningCores + $roleSize.NumberOfCores

                                $msg = "new available session capacity is: $AvailableSessionCapacity"
                                GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
                                
                                if ($AvailableSessionCapacity -gt $hostPoolUserSessions.Count)
                                {
                                    break
                                }
                            }
                            # Break out of the inner foreach loop once a match is found and checked
                        }
                    }
                }
            }
        }

        $msg = "HostpoolName:$hostpoolName, TotalRunningCores:$totalRunningCores NumberOfRunningHost:$numberOfRunningHost"
        GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable

        # Write to the usage log
        $depthBool = $false
        Write-UsageLog $hostPoolName $totalRunningCores $numberOfRunningHost $depthBool
    }
    else
    {
        $msg = "It is off-peak hours. Starting to scale down RD session hosts..."
        GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable

        $msg = [string]::Format("Processing hostPool {0}", $hostPoolName)
        GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable

        # Get the Session Hosts in the hostPool
        try
        {
            ExitIfNotOwner -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken
            $RDSessionHost = Get-RdsSessionHost -TenantName $tenantName -HostPoolName $hostPoolName
        }
        catch
        {
            $OwnerToken.Status = [HAStatuses]::Failed
            UpdateOwnerToken -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken      
            $msg = "Failed to retrieve session hosts in hostPool: $($hostPoolName) with error: $($_.exception.message)"
            GlobalLog -Message $msg -LogLevel ([LogLevel]::Error) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
            exit 1
        }

        $numberOfRunningHost = 0
        $totalRunningCores = 0

        foreach ($sessionHost in $RDSessionHost.sessionhostname)
        {
            $VMName = $sessionHost.Split(".")[0]

            ExitIfNotOwner -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken
            $roleInstance = Get-AzVM -Status -Name $VMName

            if ($sessionHost.ToLower().Contains($roleInstance.Name.ToLower()))
            {
                # Check if the Azure VM is running

                if ($roleInstance.PowerState -eq "VM running")
                {
                    $numberOfRunningHost = $numberOfRunningHost + 1

                    # Calculate available capacity of sessions
                    ExitIfNotOwner -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken
                    $roleSize = Get-AzVMSize -Location $roleInstance.Location | Where-Object { $_.Name -eq $roleInstance.HardwareProfile.VmSize }

                    $totalRunningCores = $totalRunningCores + $roleSize.NumberOfCores
                }
            }
        }

        if ($numberOfRunningHost -gt $MinimumNumberOfRDSH)
        {
            # Shutdown VM to meet the minimum requirement

            foreach ($sessionHost in $RDSessionHost.sessionhostname)
            {
                if ($numberOfRunningHost -gt $MinimumNumberOfRDSH)
                {
                    $VMName = $sessionHost.Split(".")[0]

                    ExitIfNotOwner -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken
                    $roleInstance = Get-AzVM -Status -Name $VMName

                    if ($sessionHost.ToLower().Contains($roleInstance.Name.ToLower()))
                    {
                        # check if the Azure VM is running

                        if ($roleInstance.PowerState -eq "VM running")
                        {
                            # Check the role instance status is ReadyRole or not, before setting the session host
                            $isInstanceReady = $false
                            $numOfRetries = 0

                            while (!$isInstanceReady -and $num -le 3)
                            {
                                $numOfRetries = $numOfRetries + 1

                                ExitIfNotOwner -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken
                                $instance = Get-AzVM -Status -Name $roleInstance.Name
                                if ($instance -ne $null -and $instance.ProvisioningState -eq "Succeeded")
                                {
                                    $isInstanceReady = $true
                                }

                                Start-Sleep -Seconds 30
                            }

                            if ($isInstanceReady)
                            {
                                # Ensure the running Azure VM is set to drain mode
                                try
                                {
                                    $Action = "Set-RdsSessionHost -TenantName `$tenantName -HostPoolName `$hostPoolName -Name `$sessionHost -AllowNewSession `$false"
                                    RunActionIfOwnerOrExit -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken -Action $Action
                                }
                                catch
                                {
                                    $OwnerToken.Status = [HAStatuses]::Failed
                                    UpdateOwnerToken -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken   
                                    $msg = "Failed to set drain mode on session host: $($sessionHost.SessionHost) with error: $($_.exception.message)"
                                    GlobalLog -Message $msg -LogLevel ([LogLevel]::Error) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
                                    exit 1
                                }
                
                                # Get the user sessions in the host pool
                                try
                                {
                                    ExitIfNotOwner -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken
                                    $hostPoolUserSessions = Get-RdsUserSession -TenantName $tenantName -HostPoolName $hostPoolName
                                }
                                catch
                                {
                                    $OwnerToken.Status = [HAStatuses]::Failed
                                    UpdateOwnerToken -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken   
                                    $msg = "Failed to retrieve user sessions in hostPool: $($hostPoolName) with error: $($_.exception.message)"
                                    GlobalLog -Message $msg -LogLevel ([LogLevel]::Error) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
                                    exit 1
                                }

                                $hostUserSessionCount = ($hostPoolUserSessions | Where-Object -FilterScript { $_.sessionhostname -eq $sessionHost }).Count

                                $msg = "Counting the current sessions on the host $sessionhost...:$hostUserSessionCount"
                                GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
                
                                $existingSession = 0

                                foreach ($session in $hostPoolUserSessions)
                                {
                                    if ($session.sessionhostname -eq $sessionHost)
                                    {
                                        if ($LimitSecondsToForceLogOffUser -ne 0)
                                        {
                                            # Send notification
                                            try
                                            {
                                                ExitIfNotOwner -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken
                                                Send-RdsUserSessionMessage -TenantName $tenantName -HostPoolName $hostPoolName -SessionHostName $sessionHost -SessionId $session.sessionid -MessageTitle $LogOffMessageTitle -MessageBody "$($LogOffMessageBody) You will logged off in $($LimitSecondsToForceLogOffUser) seconds." -NoUserPrompt
                                            }
                                            catch
                                            {
                                                $OwnerToken.Status = [HAStatuses]::Failed
                                                UpdateOwnerToken -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken   
                                                $msg = "Failed to send message to user with error: $($_.exception.message)"
                                                GlobalLog -Message $msg -LogLevel ([LogLevel]::Error) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
                                                exit 1
                                            }
                                        }

                                        $existingSession = $existingSession + 1
                                    }
                                }

                                # Wait for n seconds to log off user
                                Start-Sleep -Seconds $LimitSecondsToForceLogOffUser

                                if ($LimitSecondsToForceLogOffUser -ne 0)
                                {
                                    # Force users to log off
                                    $msg = "Force users to log off..."
                                    GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
                                    try
                                    {
                                        ExitIfNotOwner -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken
                                        $hostPoolUserSessions = Get-RdsUserSession -TenantName $tenantName -HostPoolName $hostPoolName
                                    }
                                    catch
                                    {
                                        $msg = "Failed to retrieve list of user sessions in hostPool: $($hostPoolName) with error: $($_.exception.message)"
                                        GlobalLog -Message $msg -LogLevel ([LogLevel]::Error) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
                                        exit 1
                                    }
                                    foreach ($session in $hostPoolUserSessions)
                                    {
                                        if ($session.sessionhostname -eq $sessionHost)
                                        {
                                            # Log off user
                                            try
                                            {                                             
                                                $Action = "Invoke-RdsUserSessionLogoff -TenantName `$tenantName -HostPoolName `$hostPoolName -SessionHostName `$session.sessionhostname -SessionId `$session.sessionid -NoUserPrompt"
                                                RunActionIfOwnerOrExit -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken -Action $Action
            
                                                $existingSession = $existingSession - 1
                                            }
                                            catch
                                            {
                                                $OwnerToken.Status = [HAStatuses]::Failed
                                                UpdateOwnerToken -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken   
                                                $msg = "Failed to log off user with error: $($_.exception.message)"
                                                GlobalLog -Message $msg -LogLevel ([LogLevel]::Error) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
                                                exit 1
                                            }
                                        }
                                    }
                                }

                                # Check session count before shutting down VM
                                if ($existingSession -eq 0)
                                {
                                    # Shutdown the Azure VM
                                    try
                                    {
                                        $msg = "Stopping Azure VM: $($roleInstance.Name) and waiting for it to complete ..."
                                        GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
                                       
                                        $Action = "Stop-AzVM -Id `$roleInstance.Id -Force"
                                        RunActionIfOwnerOrExit -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken -Action $Action
                                    }
                                    catch
                                    {
                                        $OwnerToken.Status = [HAStatuses]::Failed
                                        UpdateOwnerToken -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken   
                                        $msg = "Failed to stop Azure VM: $($roleInstance.Name) with error: $($_.exception.message)"
                                        GlobalLog -Message $msg -LogLevel ([LogLevel]::Error) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
                                        exit 1
                                    }

                                    # Wait for the VM to stop
                                    $IsVMStopped = $false
                                    while (!$IsVMStopped)
                                    {
                                        $vm = Get-AzVM -Status -Name $roleInstance.Name

                                        if ($vm.PowerState -eq "VM deallocated")
                                        {
                                            $IsVMStopped = $true
                                            $msg = "Azure VM has been stopped: $($roleInstance.Name) ..."
                                            GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
                                        }
                                        else
                                        {
                                            $msg = "Waiting for Azure VM to stop $($roleInstance.Name) ..."
                                            GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
                                        }

                                        Start-Sleep -Seconds 30
                                    }

                                    # Ensure Azure VMs that are off have AllowNewSession mode set to True
                                    try
                                    {
                                        $Action = "Set-RdsSessionHost -TenantName `$tenantName -HostPoolName `$hostPoolName -Name `$sessionHost -AllowNewSession `$true"
                                        RunActionIfOwnerOrExit -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken -Action $Action
                                    }
                                    catch
                                    {
                                        $OwnerToken.Status = [HAStatuses]::Failed
                                        UpdateOwnerToken -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken   
                                        $msg = "Failed to set drain mode on session host: $($sessionHost.SessionHost) with error: $($_.exception.message)"
                                        GlobalLog -Message $msg -LogLevel ([LogLevel]::Error) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
                                        exit 1
                                    }

                                    $vm = Get-AzVM -Status -Name $roleInstance.Name
                                    $roleSize = Get-AzVMSize -Location $roleInstance.Location | Where-Object { $_.Name -eq $roleInstance.HardwareProfile.VmSize }
                                    
                                    # Decrement number of running session host
                                    $numberOfRunningHost = $numberOfRunningHost - 1
                                    $totalRunningCores = $totalRunningCores - $roleSize.NumberOfCores
                                }
                            }
                        }
                    }
                }
            }
        }
        # Write to the usage log
        $msg = "HostpoolName:$hostpoolName, TotalRunningCores:$totalRunningCores NumberOfRunningHost:$numberOfRunningHost"
        GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
    
        $depthBool = $false
        Write-UsageLog $hostPoolName $totalRunningCores $numberOfRunningHost $depthBool
    }

	# Cleaning up old log entries
	$msg = "Cleaning up old log entries"
    GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
	LogTableCleanUp -LogTable $ScalingLogTable -LogTableKeepLastDays $LogTableKeepLastDays -ActivityId $ActivityId

    # Execution completed
    $OwnerToken.Status = [HAStatuses]::Completed
    UpdateOwnerToken -HaTable $ScalingHATable -LogTable $ScalingLogTable -PartitionKey $PartitionKey -RowKey $RowKey -OwnerToken $OwnerToken   
    $msg = "End WVD Tenant Scale Optimization."
    GlobalLog -Message $msg -LogLevel ([LogLevel]::Info) -OwnerToken $OwnerToken -LogTable $ScalingLogTable
}

#endregion