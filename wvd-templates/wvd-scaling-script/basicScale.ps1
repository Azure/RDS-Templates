param(
	[Parameter(mandatory = $false)]
	[PSCustomObject]$WebHookData,

	# Note: if this is enabled, the script will assume that all the authentication is already done in current or parent scope before calling this script
	[switch]$SkipAuth,

	# Note: optional for simulating user sessions
	[System.Nullable[int]]$OverrideNUserSessions
)
try {
	# //todo fix errs with strict mode
	# //todo support new az wvd api
	#region set err action preference, extract input params, set exec policies, set TLS 1.2 security protocol

	# Setting ErrorActionPreference to stop script execution when error occurs
	$ErrorActionPreference = 'Stop'

	# If runbook was called from Webhook, WebhookData and its RequestBody will not be null.
	if (!$WebHookData -or [string]::IsNullOrWhiteSpace($WebHookData.RequestBody)) {
		throw 'Runbook was not started from Webhook (WebHookData or its RequestBody is empty)'
	}

	# Collect Input converted from JSON request body of Webhook.
	$Input = (ConvertFrom-Json -InputObject $WebHookData.RequestBody)

	$LogAnalyticsWorkspaceId = $Input.LogAnalyticsWorkspaceId
	$LogAnalyticsPrimaryKey = $Input.LogAnalyticsPrimaryKey
	$ConnectionAssetName = $Input.ConnectionAssetName
	$AADTenantId = $Input.AADTenantId
	$SubscriptionId = $Input.SubscriptionId
	$UseRDSAPI = $Input.UseRDSAPI
	$ResourceGroupName = $Input.ResourceGroupName
	if ($UseRDSAPI) {
		$RDBrokerURL = $Input.RDBrokerURL
		$TenantGroupName = $Input.TenantGroupName
		$TenantName = $Input.TenantName
	}
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

	[array]$DesiredRunningStates = @('Available', 'NeedsAssistance')
	# Note: time diff can be '#' or '#:#', so it is appended with ':0' in case its just '#' and so the result will have at least 2 items (hrs and min)
	[array]$TimeDiffHrsMin = "$($TimeDifference):0".Split(':')

	Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope Process -Force -Confirm:$false
	if (!$SkipAuth) {
		# Note: this requires admin priviledges
		Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine -Force -Confirm:$false
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
		# //todo add timeouts
		while ($true) {
			Write-Log "[Check jobs status] Total: $($Jobs.Count), $(($Jobs | Group-Object State | ForEach-Object { "$($_.Name): $($_.Count)" }) -join ', ')"
			if (!($Jobs | Where-Object { $_.State -eq 'Running' })) {
				break
			}
			Start-Sleep 10
		}

		$IncompleteJobs = $Jobs | Where-Object { $_.State -ne 'Completed' }
		if ($IncompleteJobs) {
			throw "Some jobs did not complete successfully: $($IncompleteJobs | Format-List -Force)"
		}
	}

	# //todo support az wvd api
	function Update-SessionHostToAllowNewSession {
		param (
			[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
			[Microsoft.RDInfra.RDManagementData.RdMgmtSessionHost]$SessionHost
		)
		Begin { }
		Process {
			if (!$SessionHost.AllowNewSession) {
				Write-Log "Update session host '$($SessionHost.SessionHostName)' to allow new sessions"
				Set-RdsSessionHost -TenantName $SessionHost.TenantName -HostPoolName $SessionHost.HostPoolName -Name $SessionHost.SessionHostName -AllowNewSession $true
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

		if ($UseRDSAPI) {
			# Authenticating to WVD
			$WVDAuthentication = $null
			try {
				$WVDAuthentication = Add-RdsAccount -DeploymentUrl $RDBrokerURL -ApplicationId $Connection.ApplicationId -CertificateThumbprint $Connection.CertificateThumbprint -AADTenantId $AADTenantId
				if (!$WVDAuthentication) {
					throw $WVDAuthentication
				}
			}
			catch {
				throw [System.Exception]::new('Failed to authenticate WVD', $PSItem.Exception)
			}
			Write-Log "Successfully authenticated with WVD using service principal. Result: `n$($WVDAuthentication | Out-String)"
		}
	}


	#region set az context, WVD tenant context, validate tenant & host pool, validate HostPool load balancer type, ensure there is at least 1 session host

	# Set the Azure context with Subscription
	$AzContext = $null
	try {
		Write-Log 'Set Azure context with the subscription'
		$AzContext = Set-AzContext -SubscriptionId $SubscriptionId
		if (!$AzContext) {
			throw $AzContext
		}
	}
	catch {
		throw [System.Exception]::new("Failed to set Azure context with provided Subscription ID: $SubscriptionId (Please provide a valid subscription)", $PSItem.Exception)
	}
	Write-Log "Successfully set the Azure context with the provided Subscription ID. Result: `n$($AzContext | Out-String)"

	if ($UseRDSAPI) {
		# Set WVD context to the appropriate tenant group
		[string]$CurrentTenantGroupName = (Get-RdsContext).TenantGroupName
		if ($TenantGroupName -ne $CurrentTenantGroupName) {
			try {
				Write-Log "Switch WVD context to tenant group '$TenantGroupName' (current: '$CurrentTenantGroupName')"
				# Note: as of Microsoft.RDInfra.RDPowerShell version 1.0.1534.2001 this throws a System.NullReferenceException when the $TenantGroupName doesn't exist.
				Set-RdsContext -TenantGroupName $TenantGroupName
			}
			catch {
				throw [System.Exception]::new("Error switch WVD context to tenant group '$TenantGroupName' from '$CurrentTenantGroupName'. This may be caused by the tenant group not existing or the user not having access to the tenant group", $PSItem.Exception)
			}
		}
		
		# Validate Tenant
		try {
			$Tenant = $null
			$Tenant = Get-RdsTenant -Name $TenantName
			if (!$Tenant) {
				throw "No tenant with name '$TenantName' exists or the account doesn't have access to it."
			}
		}
		catch {
			throw [System.Exception]::new("Error getting the tenant '$TenantName'. This may be caused by the tenant not existing or the account doesn't have access to the tenant", $PSItem.Exception)
		}
	}

	# Validate and get HostPool info
	$HostPool = $null
	try {
		Write-Log "Get Hostpool info: $HostPoolName in Tenant: $TenantName"
		if ($UseRDSAPI) {
			$HostPool = Get-RdsHostPool -Name $HostPoolName -TenantName $TenantName
		}
		else {
			$HostPool = Get-AzWvdHostPool -Name $HostPoolName -ResourceGroupName $ResourceGroupName
		}
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
	$SessionHosts = $null
	if ($UseRDSAPI) {
		$SessionHosts = Get-RdsSessionHost -HostPoolName $HostPoolName -TenantName $TenantName
	}
	else {
		$SessionHosts = Get-AzWvdSessionHost -HostPoolName $HostPoolName -ResourceGroupName $ResourceGroupName
	}
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
		if ($UseRDSAPI) {
			$HostPool = Set-RdsHostPool -Name $HostPoolName -TenantName $TenantName -BreadthFirstLoadBalancer
		}
		else {
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
		if ($VM.Instance) {
			throw "More than 1 VM found in Azure with same session host name '$($VM.SessionHost.SessionHostName)' (This is not supported):`n$($VMInstance | Out-String)`n$($VM.Instance | Out-String)"
		}

		$VM.Instance = $VMInstance
		$SessionHost = $VM.SessionHost

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

	# Check if we need to override the number of user sessions for simulation / testing purpose
	$nUserSessions = $null
	if ($null -eq $OverrideNUserSessions) {
		Write-Log 'Get number of user sessions in Hostpool'
		$nUserSessions = (Get-RdsUserSession -TenantName $TenantName -HostPoolName $HostPoolName).Count
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
				Write-Log -Warn "Session host '$($VM.SessionHost.SessionHostName)' is not healthy to start"
				continue
			}

			$SessionHostName = $VM.SessionHost.SessionHostName

			# Make sure session host is allowing new user sessions
			Update-SessionHostToAllowNewSession $VM.SessionHost

			$StartSessionHostNames.Add($SessionHostName, $null)
			Write-Log "Start session host '$SessionHostName' as a background job"
			# //todo add timeouts to jobs
			$StartVMjobs += ($VM.Instance | Start-AzVM -AsJob)

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

		Write-Log 'Wait for session hosts to be available'
		while ($true) {
			$SessionHostsToCheck = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostPoolName | Where-Object { $StartSessionHostNames.ContainsKey($_.SessionHostName) }
			Write-Log "[Check session hosts status] Total: $($SessionHostsToCheck.Count), $(($SessionHostsToCheck | Group-Object Status | ForEach-Object { "$($_.Name): $($_.Count)" }) -join ', ')"
			if (!($SessionHostsToCheck | Where-Object { $_.Status -notin $DesiredRunningStates })) {
				break
			}
			Start-Sleep 10
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
	foreach ($VM in ($VMs.Values | Where-Object { $_.Instance.PowerState -eq 'VM running' } | Sort-Object { $_.SessionHost.Sessions })) {
		if (!$nVMsToStop) {
			# Done with stopping session hosts that needed to be
			break
		}
		$SessionHost = $VM.SessionHost
		$SessionHostName = $SessionHost.SessionHostName
		
		if ($SessionHost.Sessions -and !$LimitSecondsToForceLogOffUser) {
			Write-Log -Warn "Session host '$SessionHostName' has $($SessionHost.Sessions) sessions but limit seconds to force log off user is set to 0, so will not stop any more session hosts (https://aka.ms/wvdscale#how-the-scaling-tool-works)"
			# //todo explain why break and not continue
			break
		}

		Write-Log "Session host '$SessionHostName' has $($SessionHost.Sessions) sessions. Set it to disallow new sessions"
		try {
			$VM.SessionHost = $SessionHost = Set-RdsSessionHost -TenantName $TenantName -HostPoolName $HostPoolName -Name $SessionHostName -AllowNewSession $false
		}
		catch {
			throw [System.Exception]::new("Failed to set it to disallow new sessions on session host: $SessionHostName", $PSItem.Exception)
		}

		if ($SessionHost.Sessions) {
			$SessionHostUserSessions = $null
			Write-Log "Get all user sessions from session host '$SessionHostName'"
			try {
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
					Write-Log "Send a log off message to user: $($Session.AdUserName)"
					Send-RdsUserSessionMessage -TenantName $TenantName -HostPoolName $HostPoolName -SessionHostName $SessionHostName -SessionId $Session.SessionId -MessageTitle $LogOffMessageTitle -MessageBody "$LogOffMessageBody You will be logged off in $LimitSecondsToForceLogOffUser seconds" -NoUserPrompt
				}
				catch {
					throw [System.Exception]::new("Failed to send a log off message to user: $($Session.AdUserName)", $PSItem.Exception)
				}
			}
			$VMsToStopAfterLogOffTimeOut += $VM
		}
		else {
			$StopSessionHostNames.Add($SessionHostName, $null)
			Write-Log "Stop session host '$SessionHostName' as a background job"
			# //todo add timeouts to jobs
			$StopVMjobs += ($VM.Instance | Stop-AzVM -Force -AsJob)
		}

		--$nVMsToStop
		if ($nVMsToStop -lt 0) {
			$nVMsToStop = 0
		}
	}

	if ($VMsToStopAfterLogOffTimeOut) {
		Write-Log "Wait $LimitSecondsToForceLogOffUser second(s) for user(s) to log off"
		Start-Sleep -Seconds $LimitSecondsToForceLogOffUser

		Write-Log "Force log off users and stop remaining $VMsToStopAfterLogOffTimeOut session host(s)"
		foreach ($VM in $VMsToStopAfterLogOffTimeOut) {
			$SessionHostName = $VM.SessionHost.SessionHostName
			$SessionHostUserSessions = $VM.UserSessions

			Write-Log "Force log off $($SessionHostUserSessions.Count) user(s) on session host: $SessionHostName"
			foreach ($Session in $SessionHostUserSessions) {
				try {
					Invoke-RdsUserSessionLogoff -TenantName $TenantName -HostPoolName $HostPoolName -SessionHostName $SessionHostName -SessionId $Session.SessionId -NoUserPrompt -Force
				}
				catch {
					throw [System.Exception]::new("Failed to force log off user: $($Session.AdUserName)", $PSItem.Exception)
				}
			}
			
			$StopSessionHostNames.Add($SessionHostName, $null)
			Write-Log "Stop session host '$SessionHostName' as a background job"
			# //todo add timeouts to jobs
			$StopVMjobs += ($VM.Instance | Stop-AzVM -Force -AsJob)
		}
	}

	# Check if there were enough number of session hosts to stop
	if ($nVMsToStop) {
		Write-Log -Warn "Not enough session hosts to stop. Still need to stop $nVMsToStop VMs"
	}

	# Wait for those jobs to stop the session hosts
	Wait-ForJobs $StopVMjobs

	Write-Log 'Wait for session hosts to be unavailable'
	$SessionHostsToCheck = $null
	while ($true) {
		$SessionHostsToCheck = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostPoolName | Where-Object { $StopSessionHostNames.ContainsKey($_.SessionHostName) }
		Write-Log "[Check session hosts status] Total: $($SessionHostsToCheck.Count), $(($SessionHostsToCheck | Group-Object Status | ForEach-Object { "$($_.Name): $($_.Count)" }) -join ', ')"
		if (!($SessionHostsToCheck | Where-Object { $_.Status -in $DesiredRunningStates })) {
			break
		}
		Start-Sleep 10
	}
	# Make sure session hosts are allowing new user sessions & update them to allow if not
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