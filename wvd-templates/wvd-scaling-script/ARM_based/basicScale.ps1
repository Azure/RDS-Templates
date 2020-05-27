﻿
<#
.SYNOPSIS
	v0.1.0
.DESCRIPTION
	# //todo add stuff from https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help?view=powershell-5.1
#>    
[CmdletBinding(SupportsShouldProcess)]
param(
	[Parameter(mandatory = $false)]
	[PSCustomObject]$WebHookData,

	# Note: if this is enabled, the script will assume that all the authentication is already done in current or parent scope before calling this script
	[switch]$SkipAuth,

	# Note: optional for simulating user sessions
	[System.Nullable[int]]$OverrideNUserSessions
)
try {
	# //todo support new az wvd api
	#region set err action preference, extract input params, set exec policies, set TLS 1.2 security protocol

	# Setting ErrorActionPreference to stop script execution when error occurs
	$ErrorActionPreference = 'Stop'

	# If runbook was called from Webhook, WebhookData and its RequestBody will not be null.
	if (!$WebHookData -or [string]::IsNullOrWhiteSpace($WebHookData['RequestBody'])) {
		throw 'Runbook was not started from Webhook (WebHookData or its RequestBody is empty)'
	}

	# Collect Input converted from JSON request body of Webhook.
	$Input = (ConvertFrom-Json -InputObject $WebHookData.RequestBody)

	$LogAnalyticsWorkspaceId = $Input.LogAnalyticsWorkspaceId
	$LogAnalyticsPrimaryKey = $Input.LogAnalyticsPrimaryKey
	$ConnectionAssetName = $Input.ConnectionAssetName
	$AADTenantId = $Input.AADTenantId
	$SubscriptionId = $Input.SubscriptionId
	$ResourceGroupName = $Input.ResourceGroupName
	$HostPoolName = $Input.HostPoolName
	$MaintenanceTagName = $Input.MaintenanceTagName
	$TimeDifference = $Input.TimeDifference
	$BeginPeakTime = $Input.BeginPeakTime
	$EndPeakTime = $Input.EndPeakTime
	[double]$SessionThresholdPerCPU = $Input.SessionThresholdPerCPU
	[int]$MinimumNumberOfRDSH = $Input.MinimumNumberOfRDSH
	[int]$LimitSecondsToForceLogOffUser = $Input.LimitSecondsToForceLogOffUser
	$LogOffMessageTitle = $Input.LogOffMessageTitle
	$LogOffMessageBody = $Input.LogOffMessageBody

	[int]$StatusCheckTimeOut = 60*7 # 7 min
	[int]$SessionHostStatusCheckSleepSecs = 30
	[array]$DesiredRunningStates = @('Available', 'NeedsAssistance')
	# Note: time diff can be '#' or '#:#', so it is appended with ':0' in case its just '#' and so the result will have at least 2 items (hrs and min)
	[array]$TimeDiffHrsMin = "$($TimeDifference):0".Split(':')

	if ($PSCmdlet.ShouldProcess('PS execution policies', 'Set')) {
		Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope Process -Force -Confirm:$false
		if (!$SkipAuth) {
			# Note: this requires admin priviledges
			Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine -Force -Confirm:$false
		}
	}

	# Note: https://stackoverflow.com/questions/41674518/powershell-setting-security-protocol-to-tls-1-2
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

	#endregion


	#region helper/common functions

	# Function to return local time converted from UTC
	function Get-LocalDateTime {
		return (Get-Date).ToUniversalTime().AddHours($TimeDiffHrsMin[0]).AddMinutes($TimeDiffHrsMin[1])
	}

	function Write-Log {
		[CmdletBinding()]
		param(
			[Parameter(Mandatory = $true)]
			[string]$Message,

			[switch]$Err,

			[switch]$Warn
		)

		$LocalDateTime = Get-LocalDateTime
		# $WriteMessage = "$($LocalDateTime.ToString('yyyy-MM-dd HH:mm:ss')) [$($MyInvocation.MyCommand.Source): $($MyInvocation.ScriptLineNumber)] $Message"
		$WriteMessage = "$($LocalDateTime.ToString('yyyy-MM-dd HH:mm:ss')) [$($MyInvocation.ScriptLineNumber)] $Message"
		if ($Err) {
			Write-Error $WriteMessage
		}
		elseif ($Warn) {
			Write-Warning $WriteMessage
		}
		else {
			Write-Output $WriteMessage
		}
			
		if (!$LogAnalyticsWorkspaceId -or !$LogAnalyticsPrimaryKey) {
			return
		}
		$LogMessageObj = @{
			'hostpoolName_s' = $HostPoolName
			'logmessage_s'   = $Message
		}

		# //todo use ConvertTo-JSON instead of manually converting using strings
		$LogData = ''
		foreach ($Key in $LogMessageObj.Keys) {
			switch ($Key.substring($Key.Length - 2)) {
				'_s' { $sep = '"'; $trim = $Key.Length - 2 }
				'_t' { $sep = '"'; $trim = $Key.Length - 2 }
				'_b' { $sep = ''; $trim = $Key.Length - 2 }
				'_d' { $sep = ''; $trim = $Key.Length - 2 }
				'_g' { $sep = '"'; $trim = $Key.Length - 2 }
				default { $sep = '"'; $trim = $Key.Length }
			}
			$LogData = $LogData + '"' + $Key.substring(0, $trim) + '":' + $sep + $LogMessageObj.Item($Key) + $sep + ','
		}
		$LogData = $LogData + '"TimeStamp":"' + $LocalDateTime + '"'

		# Write-Verbose "LogData: $LogData"
		$json = "{$($LogData)}"

		$PostResult = Send-OMSAPIIngestionFile -customerId $LogAnalyticsWorkspaceId -sharedKey $LogAnalyticsPrimaryKey -Body "$json" -logType 'WVDTenantScale_CL' -TimeStampField 'TimeStamp'
		# Write-Verbose "PostResult: $PostResult"
		if ($PostResult -ne 'Accepted') {
			throw "Error posting to OMS: $PostResult"
		}
	}

	# Function to wait for background jobs
	function Wait-ForJobs {
		param ([array]$Jobs = @())

		Write-Log "Wait for $($Jobs.Count) jobs"
		$StartTime = Get-Date
		while ($true) {
			if ((Get-Date).Subtract($StartTime).TotalSeconds -ge $StatusCheckTimeOut) {
				throw "Status check timed out. Taking more than $StatusCheckTimeOut seconds"
			}
			Write-Log "[Check jobs status] Total: $($Jobs.Count), $(($Jobs | Group-Object State | ForEach-Object { "$($_.Name): $($_.Count)" }) -join ', ')"
			if (!($Jobs | Where-Object { $_.State -eq 'Running' })) {
				break
			}
			Start-Sleep -Seconds 15
		}

		$IncompleteJobs = $Jobs | Where-Object { $_.State -ne 'Completed' }
		if ($IncompleteJobs) {
			throw "$($IncompleteJobs.Count) jobs did not complete successfully: $($IncompleteJobs | Format-List -Force)"
		}
	}

	function Update-SessionHostToAllowNewSession {
		param (
			[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
			# //todo support az wvd api
			[Microsoft.RDInfra.RDManagementData.RdMgmtSessionHost]$SessionHost
		)
		Begin { }
		Process {
			if (!$SessionHost.AllowNewSession) {
				# //todo support az wvd api
				Write-Log "Update session host '$($SessionHost.SessionHostName)' to allow new sessions"
				# //todo support az wvd api
				Set-RdsSessionHost -TenantName $SessionHost.TenantName -HostPoolName $SessionHost.HostPoolName -Name $SessionHost.SessionHostName -AllowNewSession $true | Write-Verbose
			}
		}
		End { }
	}

	#endregion


	if (!$SkipAuth) {
		# Collect the credentials from Azure Automation Account Assets
		$Connection = Get-AutomationConnection -Name $ConnectionAssetName

		# Authenticate to Azure
		$AZAuthentication = $null
		try {
			$AZAuthentication = Connect-AzAccount -ApplicationId $Connection.ApplicationId -TenantId $AADTenantId -CertificateThumbprint $Connection.CertificateThumbprint -ServicePrincipal
			if (!$AZAuthentication) {
				throw $AZAuthentication
			}
		}
		catch {
			throw [System.Exception]::new('Failed to authenticate Azure', $PSItem.Exception)
		}
		Write-Log "Successfully authenticated with Azure using service principal. Result: `n$($AZAuthentication | Out-String)"
	}


	#region set az context, WVD tenant context, validate tenant & host pool, validate HostPool load balancer type, ensure there is at least 1 session host

	if ($PSCmdlet.ShouldProcess($SubscriptionId, 'Set Azure context with the subscription ID')) {
		# Set the Azure context with Subscription
		$AzContext = $null
		try {
			Write-Log "Set Azure context with the subscription ID '$SubscriptionId'"
			$AzContext = Set-AzContext -SubscriptionId $SubscriptionId
			if (!$AzContext) {
				throw $AzContext
			}
		}
		catch {
			throw [System.Exception]::new("Failed to set Azure context with provided Subscription ID: $SubscriptionId (Please provide a valid subscription)", $PSItem.Exception)
		}
		Write-Log "Successfully set the Azure context with the provided Subscription ID. Result: `n$($AzContext | Out-String)"
	}

	# Validate and get HostPool info
	$HostPool = $null
	try {
		Write-Log "Get Hostpool info: $HostPoolName in Tenant: $TenantName"
		$HostPool = Get-AzWvdHostPool -Name $HostPoolName -ResourceGroupName $ResourceGroupName
		if (!$HostPool) {
			throw $HostPool
		}
	}
	catch {
		throw [System.Exception]::new("Hostpool '$HostPoolName' does not exist in the tenant '$TenantName'. Ensure that you have entered the correct values.", $PSItem.Exception)
	}

	# Ensure HostPool load balancer type is not persistent
	if ($HostPool.LoadBalancerType -eq 'Persistent') {
		throw "HostPool '$HostPoolName' is configured with 'Persistent' load balancer type. Scaling tool only supports these load balancer types: BreadthFirst, DepthFirst"
	}

	Write-Log 'Get all session hosts'
	$SessionHosts = Get-AzWvdSessionHost -HostPoolName $HostPoolName -ResourceGroupName $ResourceGroupName
	if (!$SessionHosts) {
		Write-Log "There are no session hosts in the Hostpool '$HostPoolName'. Ensure that hostpool have session hosts."
		return
	}

	#endregion
	

	#region determine if on/off peak hours

	# Convert local time, begin peak time & end peak time from UTC to local time
	$CurrentDateTime = Get-LocalDateTime
	$BeginPeakDateTime = [datetime]::Parse($CurrentDateTime.ToShortDateString() + ' ' + $BeginPeakTime)
	$EndPeakDateTime = [datetime]::Parse($CurrentDateTime.ToShortDateString() + ' ' + $EndPeakTime)

	# Adjust peak times to make sure begin peak time is always before end peak time
	if ($EndPeakDateTime -lt $BeginPeakDateTime) {
		if ($CurrentDateTime -lt $EndPeakDateTime) {
			$BeginPeakDateTime = $BeginPeakDateTime.AddDays(-1)
		}
		else {
			$EndPeakDateTime = $EndPeakDateTime.AddDays(1)
		}
	}

	Write-Log "Using current time: $($CurrentDateTime.ToString('yyyy-MM-dd HH:mm:ss')), begin peak time: $($BeginPeakDateTime.ToString('yyyy-MM-dd HH:mm:ss')), end peak time: $($EndPeakDateTime.ToString('yyyy-MM-dd HH:mm:ss'))"
	if ($BeginPeakDateTime -le $CurrentDateTime -and $CurrentDateTime -le $EndPeakDateTime) {
		Write-Log "In peak hours"
	}
	else {
		Write-Log "Off peak hours"
	}

	#endregion


	#region set up load balancing type, get all session hosts, VMs & user sessions info and compute workload

	# Set up breadth 1st load balacing type
	# Note: breadth 1st is enforced on AND off peak hours to simplify the things with scaling in the start/end of peak hours
	if ($HostPool.LoadBalancerType -ne 'BreadthFirst') {
		Write-Log "Update HostPool with BreadthFirstLoadBalancer type (current: '$($HostPool.LoadBalancerType)')"
		if ($PSCmdlet.ShouldProcess($HostPoolName, "Update HostPool with BreadthFirstLoadBalancer type (current: '$($HostPool.LoadBalancerType)')")) {
			$HostPool = Update-AzWvdHostPool -Name $HostPoolName -ResourceGroupName $ResourceGroupName -LoadBalancerType 'BreadthFirst'
		}
	}

	Write-Log "HostPool info:`n$($HostPool | Format-List -Force | Out-String)"
	Write-Log "Number of session hosts in the HostPool: $($SessionHosts.Count)"

	# Number of session hosts that are running
	[int]$nRunningVMs = 0
	# Number of cores that are running
	[int]$nRunningCores = 0
	# Object that contains all session host objects, VM instance objects except the ones that are under maintenance
	[PSCustomObject]$VMs = @{ }
	# Object that contains the number of cores for each VM size SKU
	[PSCustomObject]$VMSizeCores = @{ }
	# Number of cores to start
	[int]$nCoresToStart = 0
	# Number of VMs to start
	[int]$nVMsToStart = 0

	# Popoluate all session hosts objects
	$SessionHosts | ForEach-Object {
		# //todo support az wvd api
		$VMs.Add($_.SessionHostName.Split('.')[0].ToLower(), @{ 'SessionHost' = $_; 'Instance' = $null })
	}
	
	Write-Log 'Get all VMs, check session host status and get usage info'
	Get-AzVM -Status | ForEach-Object {
		$VMInstance = $_
		if (!$VMs.ContainsKey($VMInstance.Name.ToLower())) {
			# This VM is not a WVD session host
			return
		}
		$VMName = $VMInstance.Name.ToLower()
		if ($VMInstance.Tags.Keys -contains $MaintenanceTagName) {
			Write-Log "VM '$VMName' is in maintenance and will be ignored"
			$VMs.Remove($VMName)
			return
		}

		$VM = $VMs[$VMName]
		$SessionHost = $VM.SessionHost
		if ($VMInstance.VmId -ne $SessionHost.AzureVmId) {
			# This VM is not a WVD session host
			return
		}
		if ($VM.Instance) {
			# //todo support az wvd api
			throw "More than 1 VM found in Azure with same session host name '$($VM.SessionHost.SessionHostName)' (This is not supported):`n$($VMInstance | Out-String)`n$($VM.Instance | Out-String)"
		}

		$VM.Instance = $VMInstance

		# //todo support az wvd api
		Write-Log "Session host '$($SessionHost.SessionHostName)' with power state: $($VMInstance.PowerState), status: $($SessionHost.Status), update state: $($SessionHost.UpdateState), sessions: $($SessionHost.Sessions)"
		# Check if we know how many cores are in this VM
		if (!$VMSizeCores.ContainsKey($VMInstance.HardwareProfile.VmSize)) {
			Write-Log "Get all VM sizes in location: $($VMInstance.Location)"
			Get-AzVMSize -Location $VMInstance.Location | ForEach-Object { $VMSizeCores.Add($_.Name, $_.NumberOfCores) }
		}

		if ($VMInstance.PowerState -eq 'VM running') {
			if ($SessionHost.Status -notin $DesiredRunningStates) {
				Write-Log -Warn "VM is in running state but session host is not (this could be because the VM was just started and has not connected to broker yet)"
			}

			++$nRunningVMs
			$nRunningCores += $VMSizeCores[$VMInstance.HardwareProfile.VmSize]
		}
	}

	# Make sure VM instance was found in Azure for every session host
	$VMsWithoutInstance = $VMs.Values | Where-Object { !$_.Instance }
	if ($VMsWithoutInstance) {
		throw "There are $($VMsWithoutInstance.Count) session hosts whose VM instance was not found in Azure"
	}

	# Check if we need to override the number of user sessions for simulation / testing purpose
	$nUserSessions = $null
	if ($null -eq $OverrideNUserSessions) {
		Write-Log 'Get number of user sessions in Hostpool'
		# //todo support az wvd api
		$nUserSessions = @(Get-RdsUserSession -TenantName $TenantName -HostPoolName $HostPoolName).Count
	}
	else {
		$nUserSessions = $OverrideNUserSessions
	}

	# Calculate available capacity of sessions on running VMs
	$AvailableSessionCapacity = $nRunningCores * $SessionThresholdPerCPU

	Write-Log "Number of running session hosts: $nRunningVMs of total $($VMs.Count)"
	Write-Log "Number of user sessions: $nUserSessions of total threshold capacity: $AvailableSessionCapacity"

	#endregion


	#region determine number of session hosts to start if any

	# Now that we have all the info about the session hosts & their usage, figure how many session hosts to start/stop depending on in/off peak hours and the demand
	
	if ($BeginPeakDateTime -le $CurrentDateTime -and $CurrentDateTime -le $EndPeakDateTime) {
		# In peak hours: check if current capacity is meeting the user demands
		if ($nUserSessions -ge $AvailableSessionCapacity) {
			$nCoresToStart = [math]::Ceiling(($nUserSessions - $AvailableSessionCapacity) / $SessionThresholdPerCPU)
			Write-Log "[In peak hours] Number of user sessions is more than the threshold capacity. Need to start $nCoresToStart cores"
		}
	}
	else {
		# Off peak hours: check if need to adjust minimum number of session hosts running if the number of user sessions is close to the max allowed
		[double]$MaxSessionsThreshold = 0.9
		[int]$OffPeakSessionsThreshold = [math]::Floor($MinimumNumberOfRDSH * $HostPool.MaxSessionLimit * $MaxSessionsThreshold)
		if ($nUserSessions -ge $OffPeakSessionsThreshold) {
			$MinimumNumberOfRDSH = [math]::Ceiling($nUserSessions / ($HostPool.MaxSessionLimit * $MaxSessionsThreshold))
			Write-Log "[Off peak hours] Number of user sessions is near the max number of sessions allowed with minimum number of session hosts ($OffPeakSessionsThreshold). Adjusting minimum number of session hosts required to $MinimumNumberOfRDSH"
		}
	}

	Write-Log "Minimum number of session hosts required: $MinimumNumberOfRDSH"
	# Check if minimum number of session hosts running is higher than max allowed
	if ($VMs.Count -le $MinimumNumberOfRDSH) {
		Write-Log -Warn 'Minimum number of RDSH is set higher than total number of session hosts'
		if ($nRunningVMs -eq $VMs.Count) {
			Write-Log 'All session hosts are running'
			return
		}
	}

	# Check if minimum number of session hosts are running
	if ($nRunningVMs -lt $MinimumNumberOfRDSH) {
		$nVMsToStart = $MinimumNumberOfRDSH - $nRunningVMs
		Write-Log "Number of running session host is less than minimum required. Need to start $nVMsToStart VMs"
	}

	#endregion


	#region start any session hosts if need to

	# Check if we have any session hosts to start
	if ($nVMsToStart -or $nCoresToStart) {
		# Object that contains names of session hosts that will be started
		$StartSessionHostNames = @{ }
		# Array that contains jobs of starting the session hosts
		[array]$StartVMjobs = @()

		Write-Log 'Find session hosts that are stopped and healthy'
		foreach ($VM in $VMs.Values) {
			if (!$nVMsToStart -and !$nCoresToStart) {
				# Done with starting session hosts that needed to be
				break
			}
			if ($VM.Instance.PowerState -eq 'VM running') {
				continue
			}
			if ($VM.SessionHost.UpdateState -ne 'Succeeded') {
				# //todo support az wvd api
				Write-Log -Warn "Session host '$($VM.SessionHost.SessionHostName)' is not healthy to start"
				continue
			}

			# //todo support az wvd api
			$SessionHostName = $VM.SessionHost.SessionHostName

			if ($PSCmdlet.ShouldProcess($SessionHostName, 'Update session host to allow new sessions')) {
				# Make sure session host is allowing new user sessions
				# //todo support az wvd api
				Update-SessionHostToAllowNewSession $VM.SessionHost
			}

			Write-Log "Start session host '$SessionHostName' as a background job"
			if ($PSCmdlet.ShouldProcess($SessionHostName, 'Start session host as a background job')) {
				$StartSessionHostNames.Add($SessionHostName, $null)
				# //todo add timeouts to jobs
				$StartVMjobs += ($VM.Instance | Start-AzVM -AsJob)
			}

			--$nVMsToStart
			if ($nVMsToStart -lt 0) {
				$nVMsToStart = 0
			}
			$nCoresToStart -= $VMSizeCores[$VM.Instance.HardwareProfile.VmSize]
			if ($nCoresToStart -lt 0) {
				$nCoresToStart = 0
			}
		}

		# Check if there were enough number of session hosts to start
		if ($nVMsToStart -or $nCoresToStart) {
			Write-Log -Warn "Not enough session hosts to start. Still need to start maximum of either $nVMsToStart VMs or $nCoresToStart cores"
		}

		# Wait for those jobs to start the session hosts
		Wait-ForJobs $StartVMjobs

		Write-Log "Wait for $($StartSessionHostNames.Count) session hosts to be available"
		$StartTime = Get-Date
		while ($true) {
			if ((Get-Date).Subtract($StartTime).TotalSeconds -ge $StatusCheckTimeOut) {
				throw "Status check timed out. Taking more than $StatusCheckTimeOut seconds"
			}
			# //todo support az wvd api
			$SessionHostsToCheck = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostPoolName | Where-Object { $StartSessionHostNames.ContainsKey($_.SessionHostName) }
			Write-Log "[Check session hosts status] Total: $(@($SessionHostsToCheck).Count), $(($SessionHostsToCheck | Group-Object Status | ForEach-Object { "$($_.Name): $($_.Count)" }) -join ', ')"
			if (!($SessionHostsToCheck | Where-Object { $_.Status -notin $DesiredRunningStates })) {
				break
			}
			Start-Sleep -Seconds $SessionHostStatusCheckSleepSecs
		}
		return
	}

	#endregion


	#region determine number of session hosts to stop if any

	# If in peak hours, exit because no session hosts will need to be stopped
	if ($BeginPeakDateTime -le $CurrentDateTime -and $CurrentDateTime -le $EndPeakDateTime) {
		return
	}

	# Off peak hours, already running minimum number of session hosts, exit
	if ($nRunningVMs -le $MinimumNumberOfRDSH) {
		return
	}
	
	# Calculate the number of session hosts to stop
	[int]$nVMsToStop = $nRunningVMs - $MinimumNumberOfRDSH
	Write-Log "[Off peak hours] Number of running session host is greater than minimum required. Need to stop $nVMsToStop VMs"

	#endregion


	#region stop any session hosts if need to

	# Object that contains names of session hosts that will be stopped
	$StopSessionHostNames = @{ }
	# Array that contains jobs of stopping the session hosts
	[array]$StopVMjobs = @()
	[array]$VMsToStopAfterLogOffTimeOut = @()

	Write-Log 'Find session hosts that are running, sort them by number of user sessions'
	# //todo support az wvd api
	foreach ($VM in ($VMs.Values | Where-Object { $_.Instance.PowerState -eq 'VM running' } | Sort-Object { $_.SessionHost.Sessions })) {
		if (!$nVMsToStop) {
			# Done with stopping session hosts that needed to be
			break
		}
		$SessionHost = $VM.SessionHost
		# //todo support az wvd api
		$SessionHostName = $SessionHost.SessionHostName
		
		# //todo support az wvd api
		if ($SessionHost.Sessions -and !$LimitSecondsToForceLogOffUser) {
			# //todo support az wvd api
			Write-Log -Warn "Session host '$SessionHostName' has $($SessionHost.Sessions) sessions but limit seconds to force log off user is set to 0, so will not stop any more session hosts (https://aka.ms/wvdscale#how-the-scaling-tool-works)"
			# //todo explain why break and not continue
			break
		}

		# //todo support az wvd api
		Write-Log "Session host '$SessionHostName' has $($SessionHost.Sessions) sessions. Set it to disallow new sessions"
		if ($PSCmdlet.ShouldProcess($SessionHostName, 'Set session host to disallow new sessions')) {
			try {
				# //todo support az wvd api
				$VM.SessionHost = $SessionHost = Set-RdsSessionHost -TenantName $TenantName -HostPoolName $HostPoolName -Name $SessionHostName -AllowNewSession $false
			}
			catch {
				throw [System.Exception]::new("Failed to set it to disallow new sessions on session host: $SessionHostName", $PSItem.Exception)
			}
		}

		# //todo support az wvd api
		if ($SessionHost.Sessions) {
			$SessionHostUserSessions = $null
			Write-Log "Get all user sessions from session host '$SessionHostName'"
			try {
				# //todo support az wvd api
				$VM.UserSessions = $SessionHostUserSessions = Get-RdsUserSession -TenantName $TenantName -HostPoolName $HostPoolName | Where-Object { $_.SessionHostName -eq $SessionHostName }
			}
			catch {
				throw [System.Exception]::new("Failed to retrieve user sessions of session host: $SessionHostName", $PSItem.Exception)
			}

			Write-Log "Send active user sessions log off message on session host: $SessionHostName"
			foreach ($Session in $SessionHostUserSessions) {
				if ($Session.SessionState -ne "Active") {
					continue
				}
				try {
					# //todo support az wvd api
					Write-Log "Send a log off message to user: $($Session.AdUserName)"
					if ($PSCmdlet.ShouldProcess($Session.AdUserName, 'Send a log off message to user')) {
						# //todo support az wvd api
						Send-RdsUserSessionMessage -TenantName $TenantName -HostPoolName $HostPoolName -SessionHostName $SessionHostName -SessionId $Session.SessionId -MessageTitle $LogOffMessageTitle -MessageBody "$LogOffMessageBody You will be logged off in $LimitSecondsToForceLogOffUser seconds" -NoUserPrompt
					}
				}
				catch {
					# //todo support az wvd api
					throw [System.Exception]::new("Failed to send a log off message to user: $($Session.AdUserName)", $PSItem.Exception)
				}
			}
			$VMsToStopAfterLogOffTimeOut += $VM
		}
		else {
			Write-Log "Stop session host '$SessionHostName' as a background job"
			if ($PSCmdlet.ShouldProcess($SessionHostName, 'Stop session host as a background job')) {
				$StopSessionHostNames.Add($SessionHostName, $null)
				# //todo add timeouts to jobs
				$StopVMjobs += ($VM.Instance | Stop-AzVM -Force -AsJob)
			}
		}

		--$nVMsToStop
		if ($nVMsToStop -lt 0) {
			$nVMsToStop = 0
		}
	}

	if ($VMsToStopAfterLogOffTimeOut) {
		Write-Log "Wait $LimitSecondsToForceLogOffUser seconds for users to log off"
		if ($PSCmdlet.ShouldProcess("for $LimitSecondsToForceLogOffUser seconds", 'Wait for users to log off')) {
			Start-Sleep -Seconds $LimitSecondsToForceLogOffUser
		}

		Write-Log "Force log off users and stop remaining $($VMsToStopAfterLogOffTimeOut.Count) session hosts"
		foreach ($VM in $VMsToStopAfterLogOffTimeOut) {
			# //todo support az wvd api
			$SessionHostName = $VM.SessionHost.SessionHostName
			$SessionHostUserSessions = $VM.UserSessions

			Write-Log "Force log off $($SessionHostUserSessions.Count) users on session host: $SessionHostName"
			foreach ($Session in $SessionHostUserSessions) {
				try {
					Write-Log "Force log off user with session ID $($Session.SessionId)"
					if ($PSCmdlet.ShouldProcess($Session.SessionId, 'Force log off user with session ID')) {
						# //todo support az wvd api
						Invoke-RdsUserSessionLogoff -TenantName $TenantName -HostPoolName $HostPoolName -SessionHostName $SessionHostName -SessionId $Session.SessionId -NoUserPrompt -Force
					}
				}
				catch {
					# //todo support az wvd api
					throw [System.Exception]::new("Failed to force log off user: $($Session.AdUserName)", $PSItem.Exception)
				}
			}
			
			Write-Log "Stop session host '$SessionHostName' as a background job"
			if ($PSCmdlet.ShouldProcess($SessionHostName, 'Stop session host as a background job')) {
				$StopSessionHostNames.Add($SessionHostName, $null)
				# //todo add timeouts to jobs
				$StopVMjobs += ($VM.Instance | Stop-AzVM -Force -AsJob)
			}
		}
	}

	# Check if there were enough number of session hosts to stop
	if ($nVMsToStop) {
		Write-Log -Warn "Not enough session hosts to stop. Still need to stop $nVMsToStop VMs"
	}

	# Wait for those jobs to stop the session hosts
	Wait-ForJobs $StopVMjobs

	Write-Log "Wait for $($StopSessionHostNames.Count) session hosts to be unavailable"
	$SessionHostsToCheck = $null
	$StartTime = Get-Date
	while ($true) {
		if ((Get-Date).Subtract($StartTime).TotalSeconds -ge $StatusCheckTimeOut) {
			throw "Status check timed out. Taking more than $StatusCheckTimeOut seconds"
		}
		# //todo support az wvd api
		$SessionHostsToCheck = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostPoolName | Where-Object { $StopSessionHostNames.ContainsKey($_.SessionHostName) }
		Write-Log "[Check session hosts status] Total: $(@($SessionHostsToCheck).Count), $(($SessionHostsToCheck | Group-Object Status | ForEach-Object { "$($_.Name): $($_.Count)" }) -join ', ')"
		if (!($SessionHostsToCheck | Where-Object { $_.Status -in $DesiredRunningStates })) {
			break
		}
		Start-Sleep -Seconds $SessionHostStatusCheckSleepSecs
	}

	# Make sure session hosts are allowing new user sessions & update them to allow if not
	# //todo support az wvd api
	$SessionHostsToCheck | Update-SessionHostToAllowNewSession

	#endregion
}
catch {
	$ErrContainer = $PSItem
	# $ErrContainer = $_

	$ErrMsg = $ErrContainer | Format-List -force | Out-String
	if (Get-Command 'Write-Log' -ErrorAction:SilentlyContinue) {
		Write-Log -Err $ErrMsg -ErrorAction:Continue
	}
	else {
		Write-Error $ErrMsg -ErrorAction:Continue
	}

	throw
	# throw [System.Exception]::new($ErrMsg, $ErrContainer.Exception)
}