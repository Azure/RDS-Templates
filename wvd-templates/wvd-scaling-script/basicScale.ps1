param(
	[Parameter(mandatory = $false)]
	[object]$WebHookData,

	# note: if this is enabled, the script will assume that all the authentication is already done in current or parent scope before calling this script
	[switch]$SkipAuth,

	# note: optional for simulating user sessions
	[System.Nullable[int]]$OverrideUserSessions
)
try {
	# Setting ErrorActionPreference to stop script execution when error occurs
	$ErrorActionPreference = "Stop"

	# If runbook was called from Webhook, WebhookData and its RequestBody will not be null.
	if (!$WebHookData -or [string]::IsNullOrWhiteSpace($WebHookData.RequestBody)) {
		throw 'Runbook was not started from Webhook (WebHookData or its RequestBody is empty)'
	}

	# Collect Input converted from JSON request body of Webhook.
	$Input = (ConvertFrom-Json -InputObject $WebHookData.RequestBody)

	$AADTenantId = $Input.AADTenantId
	$SubscriptionID = $Input.SubscriptionID
	$TenantGroupName = $Input.TenantGroupName
	$TenantName = $Input.TenantName
	$HostpoolName = $Input.hostpoolname
	$BeginPeakTime = $Input.BeginPeakTime
	$EndPeakTime = $Input.EndPeakTime
	$TimeDifference = $Input.TimeDifference
	$SessionThresholdPerCPU = $Input.SessionThresholdPerCPU
	[int]$MinimumNumberOfRDSH = $Input.MinimumNumberOfRDSH
	$LimitSecondsToForceLogOffUser = $Input.LimitSecondsToForceLogOffUser
	$LogOffMessageTitle = $Input.LogOffMessageTitle
	$LogOffMessageBody = $Input.LogOffMessageBody
	$MaintenanceTagName = $Input.MaintenanceTagName
	$LogAnalyticsWorkspaceId = $Input.LogAnalyticsWorkspaceId
	$LogAnalyticsPrimaryKey = $Input.LogAnalyticsPrimaryKey
	$RDBrokerURL = $Input.RDBrokerURL
	# $AutomationAccountName = $Input.AutomationAccountName
	$ConnectionAssetName = $Input.ConnectionAssetName

	$DesiredRunningStates = ('Available', 'NeedsAssistance')

	Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope Process -Force -Confirm:$false
	if (!$SkipAuth) {
		Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine -Force -Confirm:$false
	}

	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

	# Function to return local time converted from UTC
	function Convert-UTCtoLocalTime {
		param(
			[string]$TimeDifferenceInHours
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
		# Azure is using UTC time, justify it to the local time
		$ConvertedTime = $UniversalTime.AddHours($TimeDifferenceHours).AddMinutes($TimeDifferenceMinutes)
		return $ConvertedTime
	}

	# Function to add logs to log analytics workspace
	function Add-LogEntry {
		param(
			[Object]$LogMessageObj,
			[string]$LogAnalyticsWorkspaceId,
			[string]$LogAnalyticsPrimaryKey,
			[string]$LogType,
			[string]$TimeDifferenceInHours
		)

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
		$TimeStamp = Convert-UTCtoLocalTime -TimeDifferenceInHours $TimeDifferenceInHours
		$LogData = $LogData + '"TimeStamp":"' + $TimeStamp + '"'

		# Write-Verbose "LogData: $($LogData)"
		$json = "{$($LogData)}"

		$PostResult = Send-OMSAPIIngestionFile -customerId $LogAnalyticsWorkspaceId -sharedKey $LogAnalyticsPrimaryKey -Body "$json" -logType $LogType -TimeStampField "TimeStamp"
		# Write-Verbose "PostResult: $($PostResult)"
		if ($PostResult -ne "Accepted") {
			throw "Error posting to OMS: Result: $PostResult"
		}
	}

	function Write-Log {
		[CmdletBinding()]
		param(
			[Parameter(Mandatory = $true)]
			[string]$Message,
		
			[switch]$Err
		)

		# $WriteMessage = "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) [$($MyInvocation.MyCommand.Source): $($MyInvocation.ScriptLineNumber)] $Message"
		$WriteMessage = "$((Convert-UTCtoLocalTime -TimeDifferenceInHours $TimeDifference).ToString('yyyy-MM-dd HH:mm:ss')) [$($MyInvocation.ScriptLineNumber)] $Message"
		if ($Err) {
			Write-Error $WriteMessage
		}
		else {
			Write-Output $WriteMessage
		}
			
		if (!$LogAnalyticsWorkspaceId -or !$LogAnalyticsPrimaryKey) {
			return
		}
		$LogMessageObj = @{ hostpoolName_s = $HostpoolName; logmessage_s = $Message }
		Add-LogEntry -LogMessageObj $LogMessageObj -LogAnalyticsWorkspaceId $LogAnalyticsWorkspaceId -LogAnalyticsPrimaryKey $LogAnalyticsPrimaryKey -logType 'WVDTenantScale_CL' -TimeDifferenceInHours $TimeDifference
	}

	# Function to wait for background jobs
	function WaitForJobs {
		param (
			[array]$Jobs = @()
		)

		Write-Log "Wait for $($Jobs.Count) jobs to complete"
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

	if (!$SkipAuth) {
		# Collect the credentials from Azure Automation Account Assets
		$Connection = Get-AutomationConnection -Name $ConnectionAssetName

		# Authenticate to Azure
		Clear-AzContext -Force
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

		# Authenticating to WVD
		$WVDAuthentication = $null
		try {
			$WVDAuthentication = Add-RdsAccount -DeploymentUrl $RDBrokerURL -ApplicationId $Connection.ApplicationId -CertificateThumbprint $Connection.CertificateThumbprint -AADTenantId $AadTenantId
			if (!$WVDAuthentication) {
				throw $WVDAuthentication
			}
		}
		catch {
			throw [System.Exception]::new('Failed to authenticate WVD', $PSItem.Exception)
		}
		Write-Log "Successfully authenticated with WVD using service principal. Result: `n$($WVDAuthentication | Out-String)"
	}

	# Set the Azure context with Subscription
	$AzContext = $null
	try {
		Write-Log 'Set Azure context with the subscription'
		$AzContext = Set-AzContext -SubscriptionId $SubscriptionID
		if (!$AzContext) {
			throw $AzContext
		}
	}
	catch {
		throw [System.Exception]::new("Failed to set Azure context with provided Subscription ID: $SubscriptionID (Please provide a valid subscription)", $PSItem.Exception)
	}
	Write-Log "Successfully set the Azure context with the provided Subscription ID. Result: `n$($AzContext | Out-String)"

	# Set WVD context to the appropriate tenant group
	[string]$CurrentTenantGroupName = (Get-RdsContext).TenantGroupName
	if ($TenantGroupName -ne $CurrentTenantGroupName) {
		try {
			Write-Log "Switch WVD context to tenant group '$TenantGroupName' (current: '$CurrentTenantGroupName')"
			# note: as of Microsoft.RDInfra.RDPowerShell version 1.0.1534.2001 this throws a System.NullReferenceException when the $TenantGroupName doesn't exist.
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

	# Validate and get HostPool info
	$HostPool = $null
	try {
		Write-Log "Get Hostpool info: $HostpoolName in Tenant: $TenantName"
		$HostPool = Get-RdsHostPool -TenantName $TenantName -Name $HostpoolName
		if (!$HostPool) {
			throw $HostPool
		}
	}
	catch {
		throw [System.Exception]::new("Hostpool '$HostpoolName' does not exist in the tenant '$TenantName'. Ensure that you have entered the correct values.", $PSItem.Exception)
	}

	# Get session hosts & check if it has session hosts
	Write-Log 'Get all session hosts'
	$SessionHosts = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName
	if (!$SessionHosts) {
		Write-Log "There are no session hosts in the Hostpool '$HostpoolName'. Ensure that hostpool have session hosts."
		return
	}
	
	# Convert local time, begin peak time * end peak time from UTC to local time
	$CurrentDateTime = Convert-UTCtoLocalTime -TimeDifferenceInHours $TimeDifference
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

	# Set up appropriate load balacing type
	# note: both of the if else blocks are same. Breadth 1st is enforced on AND off peak hours to simplify the things with scaling in the start/end of peak hours
	if ($HostPool.LoadBalancerType -ne 'BreadthFirst') {
		Write-Log "Update HostPool with BreadthFirstLoadBalancer type (current: '$($HostPool.LoadBalancerType)')"
		$HostPool = Set-RdsHostPool -TenantName $TenantName -Name $HostpoolName -BreadthFirstLoadBalancer
	}

	Write-Log "HostPool info:`n$($HostPool | Out-String)"
	Write-Log "Number of session hosts in the HostPool: $($SessionHosts.Count)"

	# Number of session hosts that are running
	[int]$nRunningVMs = 0
	# Number of cores that are running
	[int]$nRunningCores = 0
	# Object that contains all session host objects, VM instance objects except the ones that are under maintenance
	$VMs = @{}
	# Object that contains the number of cores for each VM size SKU
	$VMSizeCores = @{}
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
			# this VM is not a WVD session host
			return
		}
		$VMName = $VMInstance.Name.ToLower()
		# Check if VM is in maintenance
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
		# Check if the Azure vm is running
		if ($VMInstance.PowerState -eq 'VM running') {
			if ($SessionHost.Status -notin $DesiredRunningStates) {
				Write-Log "[WARN] VM is in running state but session host is not (this could be because the VM was just started and has not connected to broker yet)"
			}

			++$nRunningVMs
			$nRunningCores += $VMSizeCores[$VMInstance.HardwareProfile.VmSize]
		}
	}
		
	$HostPoolUserSessions = $null
	if ($null -eq $OverrideUserSessions) {
		Write-Log 'Get user sessions in Hostpool'
		$HostPoolUserSessions = Get-RdsUserSession -TenantName $TenantName -HostPoolName $HostpoolName
	}
	else {
		$HostPoolUserSessions = @{ Count = $OverrideUserSessions }
	}

	# Calculate available capacity of sessions on running VMs
	$AvailableSessionCapacity = $nRunningCores * $SessionThresholdPerCPU

	Write-Log "Number of running session hosts: $nRunningVMs of total $($VMs.Count)"
	Write-Log "Number of user sessions: $($HostPoolUserSessions.Count) of total threshold capacity: $AvailableSessionCapacity"
	
	if ($BeginPeakDateTime -le $CurrentDateTime -and $CurrentDateTime -le $EndPeakDateTime) {
		if ($HostPoolUserSessions.Count -ge $AvailableSessionCapacity) {
			$nCoresToStart = [math]::Ceiling(($HostPoolUserSessions.Count - $AvailableSessionCapacity) / $SessionThresholdPerCPU)
			Write-Log "[In peak hours] Number of user sessions is more than the threshold capacity. Need to start $nCoresToStart cores"
		}
	}
	else {
		[int]$OffPeakSessionsThreshold = [math]::Floor($MinimumNumberOfRDSH * $HostPool.MaxSessionLimit * 0.9)
		if ($HostPoolUserSessions.Count -ge $OffPeakSessionsThreshold) {
			# //todo may want to set it appropriately and not just increment by 1
			++$MinimumNumberOfRDSH
			Write-Log "[Off peak hours] Number of user sessions is near the max number of sessions allowed with minimum number of session hosts ($OffPeakSessionsThreshold). Adjusting minimum number of session hosts required to $MinimumNumberOfRDSH"
		}
	}

	Write-Log "Minimum number of session hosts required: $MinimumNumberOfRDSH"
	if ($VMs.Count -le $MinimumNumberOfRDSH) {
		Write-Log '[WARN] Minimum number of RDSH is set higher than total number of session hosts'
		if ($nRunningVMs -eq $VMs.Count) {
			Write-Log 'All session hosts are running'
			return
		}
	}

	if ($nRunningVMs -lt $MinimumNumberOfRDSH) {
		$nVMsToStart = $MinimumNumberOfRDSH - $nRunningVMs
		Write-Log "Number of running session host is less than minimum required. Need to start $nVMsToStart VMs"
	}

	# //todo create funcs for repeated stuff
	if ($nVMsToStart -or $nCoresToStart) {
		$StartSessionHostNames = @{}
		[array]$StartVMjobs = @()

		Write-Log 'Find session hosts that are stopped and healthy'
		foreach ($VM in $VMs.Values) {
			if (!$nVMsToStart -and !$nCoresToStart) {
				break
			}
			if ($VM.Instance.PowerState -eq 'VM running') {
				continue
			}
			if ($VM.SessionHost.UpdateState -ne 'Succeeded') {
				Write-Log "[WARN] Session host '$($VM.SessionHost.SessionHostName)' is not healthy to start"
				continue
			}

			$SessionHostName = $VM.SessionHost.SessionHostName

			if (!$VM.SessionHost.AllowNewSession) {
				Write-Log "Update session host '$SessionHostName' to allow new sessions"
				Set-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -Name $SessionHostName -AllowNewSession $true
			}

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

		if ($nVMsToStart -or $nCoresToStart) {
			Write-Log "[WARN] not enough session hosts to start. Still need to start $nVMsToStart VMs or $nCoresToStart cores"
		}

		WaitForJobs $StartVMjobs

		Write-Log 'Wait for session hosts to be available'
		while ($true) {
			$SessionHostsToCheck = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName | Where-Object { $StartSessionHostNames.ContainsKey($_.SessionHostName) }
			Write-Log "[Check session hosts status] Total: $($SessionHostsToCheck.Count), $(($SessionHostsToCheck | Group-Object Status | ForEach-Object { "$($_.Name): $($_.Count)" }) -join ', ')"
			if (!($SessionHostsToCheck | Where-Object { $_.Status -notin $DesiredRunningStates })) {
				break
			}
			Start-Sleep 10
		}
		return
	}

	if ($BeginPeakDateTime -le $CurrentDateTime -and $CurrentDateTime -le $EndPeakDateTime) {
		return
	}

	if ($nRunningVMs -le $MinimumNumberOfRDSH) {
		return
	}
	
	[int]$nVMsToStop = $nRunningVMs - $MinimumNumberOfRDSH
	Write-Log "[Off peak hours] Number of running session host is greater than minimum required. Need to stop $nVMsToStop VMs"

	$StopSessionHostNames = @{}
	[array]$StopVMjobs = @()

	Write-Log 'Find session hosts that are running, sort them by number of user sessions'
	foreach ($VM in ($VMs.Values | Where-Object { $_.Instance.PowerState -eq 'VM running' } | Sort-Object { $_.SessionHost.Sessions })) {
		if (!$nVMsToStop) {
			break
		}
		if ($VM.SessionHost.Sessions -ne 0) {
			if ($LimitSecondsToForceLogOffUser -eq 0) {
				Write-Log "[WARN] Session host '$($VM.SessionHost.SessionHostName)' has sessions but limit seconds to force log off user is set to 0, so this session host will be ignored (https://aka.ms/wvdscale#how-the-scaling-tool-works)"
				continue
			}
			# //todo ?
		}

		$SessionHostName = $VM.SessionHost.SessionHostName

		$StopSessionHostNames.Add($SessionHostName, $null)
		Write-Log "Stop session host '$SessionHostName' as a background job"
		# //todo add timeouts to jobs
		$StopVMjobs += ($VM.Instance | Stop-AzVM -Force -AsJob)

		--$nVMsToStop
		if ($nVMsToStop -lt 0) {
			$nVMsToStop = 0
		}
	}

	Write-Log "after: nVMsToStop: $nVMsToStop"
	if ($nVMsToStop) {
		Write-Log "[WARN] Not enough session hosts to stop. Still need to stop $nVMsToStop VMs"
	}

	WaitForJobs $StartVMjobs

	Write-Log 'Wait for session hosts to be unavailable'
	$SessionHostsToCheck = $null
	while ($true) {
		$SessionHostsToCheck = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName | Where-Object { $StopSessionHostNames.ContainsKey($_.SessionHostName) }
		Write-Log "[Check session hosts status] Total: $($SessionHostsToCheck.Count), $(($SessionHostsToCheck | Group-Object Status | ForEach-Object { "$($_.Name): $($_.Count)" }) -join ', ')"
		if (!($SessionHostsToCheck | Where-Object { $_.Status -in $DesiredRunningStates })) {
			break
		}
		Start-Sleep 10
	}
	$SessionHostsToCheck | ForEach-Object {
		if (!$SessionHost.AllowNewSession) {
			Write-Log "Update session host '$($SessionHost.SessionHostName)' to allow new sessions"
			Set-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -Name $SessionHost.SessionHostName -AllowNewSession $true
		}
	}
	return

	# Check if it is during the peak or off-peak time
	if ($CurrentDateTime -ge $BeginPeakDateTime -and $CurrentDateTime -le $EndPeakDateTime) {
	}
	else {
		# Breadth first session hosts shutdown in off peak hours
		if ($NumberOfRunningHost -gt $MinimumNumberOfRDSH) {
			foreach ($SessionHost in $AllSessionHosts) {
				# Check the status of the session host
				if ($SessionHost.Status -in $DesiredRunningStates) {
					if ($NumberOfRunningHost -gt $MinimumNumberOfRDSH) {
						$SessionHostName = $SessionHost.SessionHostName
						$VMName = $SessionHostName.Split(".")[0]
						if ($SessionHost.Sessions -eq 0) {
							# Shutdown the Azure VM session host that has 0 sessions
							Write-Log "Stopping Azure VM: $VMName and waiting for it to complete ..."
							# //todo do this in parallel
							Stop-SessionHost -VMName $VMName
						}
						else {
							# changes from https://github.com/Azure/RDS-Templates/pull/439/, https://github.com/Azure/RDS-Templates/pull/467/
							if ($LimitSecondsToForceLogOffUser -eq 0) {
								continue
							}
							# Ensure the running Azure VM is set as drain mode
							try {
								# changes from https://github.com/Azure/RDS-Templates/pull/439/, https://github.com/Azure/RDS-Templates/pull/467/
								# //todo this may need to be prevented from logging as it may get logged at a lot
								Set-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -Name $SessionHostName -AllowNewSession $false
								# Set-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -Name $SessionHostName -AllowNewSession $false | Out-Null
							}
							catch {
								throw [System.Exception]::new("Unable to set it to disallow connections on session host: $SessionHostName", $PSItem.Exception)
							}
							# Notify user to log off session
							# Get the user sessions in the hostpool
							try {
								$HostPoolUserSessions = Get-RdsUserSession -TenantName $TenantName -HostPoolName $HostpoolName | Where-Object { $_.SessionHostName -eq $SessionHostName }
							}
							catch {
								throw [System.Exception]::new("Failed to retrieve user sessions in hostpool: $($HostpoolName)", $PSItem.Exception)
							}
							$HostUserSessionCount = ($HostPoolUserSessions | Where-Object -FilterScript { $_.SessionHostName -eq $SessionHostName }).Count
							Write-Log "Counting the current sessions on the host $SessionHostName :$HostUserSessionCount"
							$ExistingSession = 0
							foreach ($session in $HostPoolUserSessions) {
								if ($session.SessionHostName -eq $SessionHostName -and $session.SessionState -eq "Active") {
									# changes from https://github.com/Azure/RDS-Templates/pull/439/
									# if ($LimitSecondsToForceLogOffUser -ne 0) {
									# Send notification
									try {
										Send-RdsUserSessionMessage -TenantName $TenantName -HostPoolName $HostpoolName -SessionHostName $SessionHostName -SessionId $session.SessionId -MessageTitle $LogOffMessageTitle -MessageBody "$($LogOffMessageBody) You will be logged off in $($LimitSecondsToForceLogOffUser) seconds." -NoUserPrompt
									}
									catch {
										throw [System.Exception]::new('Failed to send message to user', $PSItem.Exception)
									}
									# changes from https://github.com/Azure/RDS-Templates/pull/439/
									Write-Log "Script sent a log off message to user: $($Session.AdUserName | Out-String)"
									# }
								}
								$ExistingSession = $ExistingSession + 1
							}
							# Wait for n seconds to log off user
							Start-Sleep -Seconds $LimitSecondsToForceLogOffUser

							# changes from https://github.com/Azure/RDS-Templates/pull/439/
							# if ($LimitSecondsToForceLogOffUser -ne 0) {
							# Force users to log off
							Write-Log "Force users to log off ..."
							foreach ($Session in $HostPoolUserSessions) {
								if ($Session.SessionHostName -eq $SessionHostName) {
									# Log off user
									try {
										# note: the following command was called with -force in log analytics workspace version of this code
										Invoke-RdsUserSessionLogoff -TenantName $TenantName -HostPoolName $HostpoolName -SessionHostName $Session.SessionHostName -SessionId $Session.SessionId -NoUserPrompt
										$ExistingSession = $ExistingSession - 1
									}
									catch {
										throw [System.Exception]::new('Failed to log off user', $PSItem.Exception)
									}
									# changes from https://github.com/Azure/RDS-Templates/pull/439/
									Write-Log "Forcibly logged off the user: $($Session.AdUserName | Out-String)"
								}
							}
							# }
							# Check the session count before shutting down the VM
							if ($ExistingSession -eq 0) {
								# Shutdown the Azure VM
								Write-Log "Stopping Azure VM: $VMName and waiting for it to complete ..."
								Stop-SessionHost -VMName $VMName
							}
						}
					}
				}
			}
		}
	}
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