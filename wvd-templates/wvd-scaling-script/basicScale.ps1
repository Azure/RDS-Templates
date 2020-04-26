param(
	[Parameter(mandatory = $false)]
	[object]$WebHookData,

	# note: if this is enabled, the script will assume that all the authentication is done in current context before calling this script
	[switch]$SkipAuth
)
try {
	# Setting ErrorActionPreference to stop script execution when error occurs
	$ErrorActionPreference = "Stop"

	# If runbook was called from Webhook, WebhookData and its RequestBody will not be null.
	if (!$WebHookData -or !$WebHookData.RequestBody -or !$WebHookData.RequestBody.Count) {
		throw 'Runbook was not started from Webhook (WebHookData or its RequestBody is empty)'
	}
	# //todo maybe remove this ?
	if ($SkipAuth) {
		# Set-StrictMode -Version Latest
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
	$MinimumNumberOfRDSH = $Input.MinimumNumberOfRDSH
	$LimitSecondsToForceLogOffUser = $Input.LimitSecondsToForceLogOffUser
	$LogOffMessageTitle = $Input.LogOffMessageTitle
	$LogOffMessageBody = $Input.LogOffMessageBody
	$MaintenanceTagName = $Input.MaintenanceTagName
	$LogAnalyticsWorkspaceId = $Input.LogAnalyticsWorkspaceId
	$LogAnalyticsPrimaryKey = $Input.LogAnalyticsPrimaryKey
	$RDBrokerURL = $Input.RDBrokerURL
	$AutomationAccountName = $Input.AutomationAccountName
	$ConnectionAssetName = $Input.ConnectionAssetName

	Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope Process -Force -Confirm:$false
	if (!$SkipAuth) {
		Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine -Force -Confirm:$false
	}

	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
	# Function to convert from UTC to Local time
	function Convert-UTCtoLocalTime {
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
			$TimeDifferenceInHours
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

		if ($Err) {
			Write-Error $Message
		}
		else {
			Write-Output $Message
		}
			
		if (!$LogAnalyticsWorkspaceId -or !$LogAnalyticsPrimaryKey) {
			return
		}
		$LogMessageObj = @{ hostpoolName_s = $HostpoolName; logmessage_s = $Message }
		Add-LogEntry -LogMessageObj $LogMessageObj -LogAnalyticsWorkspaceId $LogAnalyticsWorkspaceId -LogAnalyticsPrimaryKey $LogAnalyticsPrimaryKey -logType 'WVDTenantScale_CL' -TimeDifferenceInHours $TimeDifference
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
	$CurrentTenantGroupName = (Get-RdsContext).TenantGroupName
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
	
	try {
		$tenant = $null
		$tenant = Get-RdsTenant -Name $TenantName
		if (!$tenant) {
			throw "No tenant with name '$TenantName' exists or the account doesn't have access to it."
		}
	}
	catch {
		throw [System.Exception]::new("Error getting the tenant '$TenantName'. This may be caused by the tenant not existing or the account doesn't have access to the tenant", $PSItem.Exception)
	}

	<#
	.Description
	Helper functions
	#>
	# Function to check and update the loadbalancer type to BreadthFirst
	function UpdateLoadBalancerTypeInPeakandOffPeakwithBreadthFirst {
		param(
			[string]$HostpoolLoadbalancerType,
			[string]$TenantName,
			[string]$HostpoolName,
			[int]$MaxSessionLimitValue
		)
		if ($HostpoolLoadbalancerType -ne "BreadthFirst") {
			Write-Log "Update HostPool with LoadBalancerType: 'BreadthFirst' (current: '$HostpoolLoadbalancerType'), MaxSessionLimit: $MaxSessionLimitValue. Current Date Time is: $CurrentDateTime"
			Set-RdsHostPool -TenantName $TenantName -Name $HostpoolName -BreadthFirstLoadBalancer -MaxSessionLimit $MaxSessionLimitValue
		}
	}

	# Function to update session host to allow new sessions
	function UpdateSessionHostToAllowNewSessions {
		param(
			[string]$TenantName,
			[string]$HostpoolName,
			[string]$SessionHostName
		)

		$StateOftheSessionHost = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -Name $SessionHostName
		if (!($StateOftheSessionHost.AllowNewSession)) {
			Write-Log "Update session host '$SessionHostName' to allow new sessions"
			Set-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -Name $SessionHostName -AllowNewSession $true
		}
	}

	# Function to start the Session Host
	function Start-SessionHost {
		param(
			[string]$TenantName,
			[string]$HostpoolName,
			[string]$SessionHostName
		)
		
		# Update session host to allow new sessions
		UpdateSessionHostToAllowNewSessions -TenantName $TenantName -HostPoolName $HostpoolName -SessionHostName $SessionHostName

		# Get the status of the VM
		$VMName = $SessionHostName.Split(".")[0]
		$VM = $null
		$StartVMJob = $null
		try {
			$VM = Get-AzVM -Name $VMName -Status
			if (!$VM) {
				throw "Session host VM '$VMName' not found in Azure"
			}
			if ($VM.Count -gt 1) {
				throw "More than 1 VM found in Azure with same Session host name '$VMName' (This is not supported):`n$($VM | Out-String)"
			}

			# Start the VM as a background job
			# //todo why as a background job ?
			Write-Log "Start VM '$VMName' as a background job"
			$StartVMJob = $VM | Start-AzVM -AsJob
			if (!$StartVMJob -or $StartVMJob.State -eq 'Failed') {
				throw $StartVMJob.Error
			}
		}
		catch {
			throw [System.Exception]::new("Failed to start Azure VM '$($VMName)'", $PSItem.Exception)
		}

		# Wait for the VM to start
		Write-Log "Wait for VM '$VMName' to start"
		# //todo may be add a timeout
		while (!$VM -or $VM.PowerState -ne 'VM running') {
			if ($StartVMJob.State -eq 'Failed') {
				throw [System.Exception]::new("Failed to start Azure VM '$($VMName)'", $StartVMJob.Error)
			}

			Write-Log "VM power state: '$($VM.PowerState)', continue waiting"
			$VM = Get-AzVM -Name $VMName -Status # this takes at least about 15 sec
		}
		Write-Log "VM '$($VM.Name)' is now in '$($VM.PowerState)' power state"

		# Wait for the session host to be available
		$SessionHost = $null
		Write-Log "Wait for session host '$SessionHostName' to be available"
		# //todo may be add a timeout
		# //todo check for multi desired states including 'NeedsAssistance'
		while (!$SessionHost -or $SessionHost.Status -ne 'Available') {
			Write-Log "Session host status: '$($SessionHost.Status)', continue waiting"
			Start-Sleep -Seconds 5
			$SessionHost = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -Name $SessionHostName
		}
		Write-Log "Session host '$SessionHostName' is now in '$($SessionHost.Status)' state"
	}

	# Function to stop the Session Host as a background job
	function Stop-SessionHost {
		param(
			[string]$VMName
		)
		try {
			Write-Log "Stop VM '$VMName' as a background job"
			# //todo why can't we use the other one ?
			Get-AzVM | Where-Object { $_.Name -eq $VMName } | Stop-AzVM -Force -AsJob | Out-Null
			# Get-AzVM -Name $VMName | Stop-AzVM -Force -AsJob | Out-Null
		}
		catch {
			throw [System.Exception]::new("Failed to stop Azure VM: $($VMName)", $PSItem.Exception)
		}
	}
	
	# Convert date time from UTC to Local
	$CurrentDateTime = Convert-UTCtoLocalTime -TimeDifferenceInHours $TimeDifference

	$BeginPeakDateTime = [datetime]::Parse($CurrentDateTime.ToShortDateString() + ' ' + $BeginPeakTime)
	$EndPeakDateTime = [datetime]::Parse($CurrentDateTime.ToShortDateString() + ' ' + $EndPeakTime)

	# Check: the calculated end time is later than begin time in case of time zone
	if ($EndPeakDateTime -lt $BeginPeakDateTime) {
		$EndPeakDateTime = $EndPeakDateTime.AddDays(1)
	}

	# Check given HostPool name exists in Tenant
	$HostpoolInfo = $null
	try {
		$HostpoolInfo = Get-RdsHostPool -TenantName $TenantName -Name $HostpoolName
		if (!$HostpoolInfo) {
			throw $HostpoolInfo
		}
	}
	catch {
		throw [System.Exception]::new("Hostpool '$HostpoolName' does not exist in the tenant '$TenantName'. Ensure that you have entered the correct values.", $PSItem.Exception)
	}

	# Check if the hostpool has session hosts
	$ListOfSessionHosts = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -ErrorAction Stop | Sort-Object SessionHostName
	if (!$ListOfSessionHosts) {
		Write-Log "There are no session hosts in the Hostpool '$HostpoolName'. Ensure that hostpool have session hosts."
		exit
	}

	# Set up appropriate load balacing type
	$HostpoolLoadbalancerType = $HostpoolInfo.LoadBalancerType
	[int]$MaxSessionLimitValue = $HostpoolInfo.MaxSessionLimit
	# note: both of the if else blocks are same. Breadth 1st is enforced on AND off peak hours to simplify the things with scaling in the start/end of peak hours
	if ($CurrentDateTime -ge $BeginPeakDateTime -and $CurrentDateTime -le $EndPeakDateTime) {
		UpdateLoadBalancerTypeInPeakandOffPeakwithBreadthFirst -TenantName $TenantName -HostPoolName $HostpoolName -MaxSessionLimitValue $MaxSessionLimitValue -HostpoolLoadbalancerType $HostpoolLoadbalancerType
	}
	else {
		UpdateLoadBalancerTypeInPeakandOffPeakwithBreadthFirst -TenantName $TenantName -HostPoolName $HostpoolName -MaxSessionLimitValue $MaxSessionLimitValue -HostpoolLoadbalancerType $HostpoolLoadbalancerType
	}

	Write-Log "HostPool info:`n$($HostpoolInfo | Out-String)"
	Write-Log "Number of session hosts in the HostPool: $($ListOfSessionHosts.Count)"

	Write-Log "Start WVD session hosts scale optimization: Current Date Time is: $CurrentDateTime"
	# Get the HostPool info after changing hostpool loadbalancer type
	$HostpoolInfo = Get-RdsHostPool -TenantName $TenantName -Name $HostPoolName

	# Check if it is during the peak or off-peak time
	if ($CurrentDateTime -ge $BeginPeakDateTime -and $CurrentDateTime -le $EndPeakDateTime) {
		Write-Log "It is in peak hours now"
		Write-Log "Starting session hosts as needed based on current workloads."

		# Peak hours: check and remove the MinimumNoOfRDSH value dynamically stored in automation variable
		$AutomationAccount = Get-AzAutomationAccount -ErrorAction Stop | Where-Object { $_.AutomationAccountName -eq $AutomationAccountName }
		$OffPeakUsageMinimumNoOfRDSH = Get-AzAutomationVariable -Name "$HostpoolName-OffPeakUsage-MinimumNoOfRDSH" -ResourceGroupName $AutomationAccount.ResourceGroupName -AutomationAccountName $AutomationAccount.AutomationAccountName -ErrorAction SilentlyContinue
		if ($OffPeakUsageMinimumNoOfRDSH) {
			Remove-AzAutomationVariable -Name "$HostpoolName-OffPeakUsage-MinimumNoOfRDSH" -ResourceGroupName $AutomationAccount.ResourceGroupName -AutomationAccountName $AutomationAccount.AutomationAccountName
		}
		# Number of running session hosts
		[int]$NumberOfRunningHost = 0
		# Total number of running cores
		[int]$TotalRunningCores = 0
		# Total capacity of sessions on running VMs
		$AvailableSessionCapacity = 0
		# Initialize variable to skip the session host which is in maintenance.
		$SkipSessionhosts = 0
		$SkipSessionhosts = @()

		$HostPoolUserSessions = Get-RdsUserSession -TenantName $TenantName -HostPoolName $HostpoolName

		foreach ($SessionHost in $ListOfSessionHosts) {

			$SessionHostName = $SessionHost.SessionHostName | Out-String
			$VMName = $SessionHostName.Split(".")[0]
			# Check if VM is in maintenance
			$RoleInstance = Get-AzVM -Status | Where-Object { $_.Name.Contains($VMName) }
			if ($RoleInstance.Tags.Keys -contains $MaintenanceTagName) {
				Write-Log "Session host is in maintenance: $VMName, so script will skip this VM"
				$SkipSessionhosts += $SessionHost
				continue
			}
			#$AllSessionHosts = Compare-Object $ListOfSessionHosts $SkipSessionhosts | Where-Object { $_.SideIndicator -eq '<=' } | ForEach-Object { $_.InputObject }
			$AllSessionHosts = $ListOfSessionHosts | Where-Object { $SkipSessionhosts -notcontains $_ }

			Write-Log "Checking session host: $($SessionHost.SessionHostName | Out-String) with sessions: $($SessionHost.Sessions) and status: $($SessionHost.Status)"
			if ($SessionHostName.ToLower().Contains($RoleInstance.Name.ToLower())) {
				# Check if the Azure vm is running       
				if ($RoleInstance.PowerState -eq "VM running") {
					[int]$NumberOfRunningHost = [int]$NumberOfRunningHost + 1
					# Calculate available capacity of sessions						
					$RoleSize = Get-AzVMSize -Location $RoleInstance.Location | Where-Object { $_.Name -eq $RoleInstance.HardwareProfile.VmSize }
					$AvailableSessionCapacity = $AvailableSessionCapacity + $RoleSize.NumberOfCores * $SessionThresholdPerCPU
					[int]$TotalRunningCores = [int]$TotalRunningCores + $RoleSize.NumberOfCores
				}
			}
		}
		Write-Log "Current number of running hosts: $NumberOfRunningHost"
		if ($NumberOfRunningHost -lt $MinimumNumberOfRDSH) {
			Write-Log "Current number of running session hosts is less than minimum requirements, start session host ..."
			# Start VM to meet the minimum requirement            
			foreach ($SessionHost in $AllSessionHosts.SessionHostName) {
				# Check whether the number of running VMs meets the minimum or not
				if ($NumberOfRunningHost -lt $MinimumNumberOfRDSH) {
					$VMName = $SessionHost.Split(".")[0]
					$RoleInstance = Get-AzVM -Status | Where-Object { $_.Name.Contains($VMName) }
					if ($SessionHost.ToLower().Contains($RoleInstance.Name.ToLower())) {
						# Check if the Azure VM is running and if the session host is healthy
						$SessionHostInfo = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -Name $SessionHost
						if ($RoleInstance.PowerState -ne "VM running" -and $SessionHostInfo.UpdateState -eq "Succeeded") {

							Start-SessionHost -TenantName $TenantName -HostPoolName $HostpoolName -SessionHostName $SessionHost
							
							# Calculate available capacity of sessions
							$RoleSize = Get-AzVMSize -Location $RoleInstance.Location | Where-Object { $_.Name -eq $RoleInstance.HardwareProfile.VmSize }
							$AvailableSessionCapacity = $AvailableSessionCapacity + $RoleSize.NumberOfCores * $SessionThresholdPerCPU
							[int]$NumberOfRunningHost = [int]$NumberOfRunningHost + 1
							[int]$TotalRunningCores = [int]$TotalRunningCores + $RoleSize.NumberOfCores
							if ($NumberOfRunningHost -ge $MinimumNumberOfRDSH) {
								break;
							}
						}
					}
				}
			}
		}
		else {
			# check if the available capacity meets the number of sessions or not
			Write-Log "Current total number of user sessions: $(($HostPoolUserSessions).Count)"
			Write-Log "Current available session capacity is: $AvailableSessionCapacity"
			if ($HostPoolUserSessions.Count -ge $AvailableSessionCapacity) {
				Write-Log "Current available session capacity is less than demanded user sessions, starting session host"
				# Running out of capacity, we need to start more VMs if there are any 
				foreach ($SessionHost in $AllSessionHosts.SessionHostName) {
					if ($HostPoolUserSessions.Count -ge $AvailableSessionCapacity) {
						$VMName = $SessionHost.Split(".")[0]
						$RoleInstance = Get-AzVM -Status | Where-Object { $_.Name.Contains($VMName) }

						if ($SessionHost.ToLower().Contains($RoleInstance.Name.ToLower())) {
							# Check if the Azure VM is running and if the session host is healthy
							$SessionHostInfo = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -Name $SessionHost
							if ($RoleInstance.PowerState -ne "VM running" -and $SessionHostInfo.UpdateState -eq "Succeeded") {

								Start-SessionHost -TenantName $TenantName -HostPoolName $HostpoolName -SessionHostName $SessionHost

								# Calculate available capacity of sessions
								$RoleSize = Get-AzVMSize -Location $RoleInstance.Location | Where-Object { $_.Name -eq $RoleInstance.HardwareProfile.VmSize }
								$AvailableSessionCapacity = $AvailableSessionCapacity + $RoleSize.NumberOfCores * $SessionThresholdPerCPU
								[int]$NumberOfRunningHost = [int]$NumberOfRunningHost + 1
								[int]$TotalRunningCores = [int]$TotalRunningCores + $RoleSize.NumberOfCores
								Write-Log "New available session capacity is: $AvailableSessionCapacity"
								if ($AvailableSessionCapacity -gt $HostPoolUserSessions.Count) {
									break
								}
							}
							# Break out of the inner foreach loop once a match is found and checked
						}
					}
				}
			}
		}
	}
	else {
		Write-Log "It is Off-peak hours"
		Write-Log "Starting to scale down WVD session hosts ..."
		Write-Log "Processing hostpool $($HostpoolName)"
		# Number of running session hosts
		[int]$NumberOfRunningHost = 0
		# Total number of running cores
		[int]$TotalRunningCores = 0
		# Initialize variable to skip the session host which is in maintenance.
		$SkipSessionhosts = 0
		$SkipSessionhosts = @()
		# Check if minimum number rdsh vm's are running in off peak hours
		$CheckMinimumNumberOfRDShIsRunning = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName | Where-Object { $_.Status -eq "Available" }
		$ListOfSessionHosts = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName
		if (!$CheckMinimumNumberOfRDShIsRunning) {
			$NumberOfRunningHost = 0
			foreach ($SessionHostName in $ListOfSessionHosts.SessionHostName) {
				if ($NumberOfRunningHost -lt $MinimumNumberOfRDSH) {
					$VMName = $SessionHostName.Split(".")[0]
					$RoleInstance = Get-AzVM -Status | Where-Object { $_.Name.Contains($VMName) }
					# Check if the session host is in maintenance
					if ($RoleInstance.Tags.Keys -contains $MaintenanceTagName) {
						continue
					}

					Start-SessionHost -TenantName $TenantName -HostPoolName $HostpoolName -SessionHostName $SessionHostName

					[int]$NumberOfRunningHost = [int]$NumberOfRunningHost + 1
					if ($NumberOfRunningHost -ge $MinimumNumberOfRDSH) {
						break;
					}
				}
			}
		}

		$ListOfSessionHosts = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName | Sort-Object Sessions
		foreach ($SessionHost in $ListOfSessionHosts) {
			$SessionHostName = $SessionHost.SessionHostName
			$VMName = $SessionHostName.Split(".")[0]
			$RoleInstance = Get-AzVM -Status | Where-Object { $_.Name.Contains($VMName) }
			# Check if the session host is in maintenance
			if ($RoleInstance.Tags.Keys -contains $MaintenanceTagName) {
				Write-Log "Session host is in maintenance: $VMName, so script will skip this VM"
				$SkipSessionhosts += $SessionHost
				continue
			}
			# Maintenance VMs skipped and stored into a variable
			$AllSessionHosts = $ListOfSessionHosts | Where-Object { $SkipSessionhosts -notcontains $_ }
			if ($SessionHostName.ToLower().Contains($RoleInstance.Name.ToLower())) {
				# Check if the Azure VM is running
				if ($RoleInstance.PowerState -eq "VM running") {
					Write-Log "Checking session host: $($SessionHost.SessionHostName | Out-String) with sessions: $($SessionHost.Sessions) and status: $($SessionHost.Status)"
					[int]$NumberOfRunningHost = [int]$NumberOfRunningHost + 1
					# Calculate available capacity of sessions  
					$RoleSize = Get-AzVMSize -Location $RoleInstance.Location | Where-Object { $_.Name -eq $RoleInstance.HardwareProfile.VmSize }
					[int]$TotalRunningCores = [int]$TotalRunningCores + $RoleSize.NumberOfCores
				}
			}
		}
		# Defined minimum no of rdsh value from webhook data
		[int]$DefinedMinimumNumberOfRDSH = [int]$MinimumNumberOfRDSH
		# Check and collect dynamically stored MinimumNoOfRDSH value																 
		$AutomationAccount = Get-AzAutomationAccount -ErrorAction Stop | Where-Object { $_.AutomationAccountName -eq $AutomationAccountName }
		$OffPeakUsageMinimumNoOfRDSH = Get-AzAutomationVariable -Name "$HostpoolName-OffPeakUsage-MinimumNoOfRDSH" -ResourceGroupName $AutomationAccount.ResourceGroupName -AutomationAccountName $AutomationAccount.AutomationAccountName -ErrorAction SilentlyContinue
		if ($OffPeakUsageMinimumNoOfRDSH) {
			[int]$MinimumNumberOfRDSH = $OffPeakUsageMinimumNoOfRDSH.Value
			if ($MinimumNumberOfRDSH -lt $DefinedMinimumNumberOfRDSH) {
				throw "Don't enter the value of '$HostpoolName-OffPeakUsage-MinimumNoOfRDSH' manually, which is dynamically stored value by script. You have entered manually, so script will stop now."
			}
		}

		# Breadth first session hosts shutdown in off peak hours
		if ($NumberOfRunningHost -gt $MinimumNumberOfRDSH) {
			foreach ($SessionHost in $AllSessionHosts) {
				# Check the status of the session host
				if ($SessionHost.Status -ne "NoHeartbeat" -or $SessionHost.Status -ne "Unavailable") {
					if ($NumberOfRunningHost -gt $MinimumNumberOfRDSH) {
						$SessionHostName = $SessionHost.SessionHostName
						$VMName = $SessionHostName.Split(".")[0]
						if ($SessionHost.Sessions -eq 0) {
							# Shutdown the Azure VM session host that has 0 sessions
							Write-Log "Stopping Azure VM: $VMName and waiting for it to complete ..."
							Stop-SessionHost -VMName $VMName
						}
						else {
							# Ensure the running Azure VM is set as drain mode
							try {
								# //todo this may need to be prevented from logging as it may get logged at a lot
								Set-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -Name $SessionHostName -AllowNewSession $false -ErrorAction Stop
								# Set-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -Name $SessionHostName -AllowNewSession $false -ErrorAction Stop | Out-Null
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
									if ($LimitSecondsToForceLogOffUser -ne 0) {
										# Send notification
										try {
											Send-RdsUserSessionMessage -TenantName $TenantName -HostPoolName $HostpoolName -SessionHostName $SessionHostName -SessionId $session.SessionId -MessageTitle $LogOffMessageTitle -MessageBody "$($LogOffMessageBody) You will be logged off in $($LimitSecondsToForceLogOffUser) seconds." -NoUserPrompt -ErrorAction Stop
										}
										catch {
											throw [System.Exception]::new('Failed to send message to user', $PSItem.Exception)
										}
										Write-Log "Script sent a log off message to user: $($Session.UserPrincipalName | Out-String)"
									}
								}
								$ExistingSession = $ExistingSession + 1
							}
							# Wait for n seconds to log off user
							Start-Sleep -Seconds $LimitSecondsToForceLogOffUser

							if ($LimitSecondsToForceLogOffUser -ne 0) {
								# Force users to log off
								Write-Log "Force users to log off ..."
								foreach ($Session in $HostPoolUserSessions) {
									if ($Session.SessionHostName -eq $SessionHostName) {
										# Log off user
										try {
											# note: the following command was called with -force in log analytics workspace version of this code
											Invoke-RdsUserSessionLogoff -TenantName $TenantName -HostPoolName $HostpoolName -SessionHostName $Session.SessionHostName -SessionId $Session.SessionId -NoUserPrompt -ErrorAction Stop
											$ExistingSession = $ExistingSession - 1
										}
										catch {
											throw [System.Exception]::new('Failed to log off user', $PSItem.Exception)
										}
										Write-Log "Forcibly logged off the user: $($Session.UserPrincipalName | Out-String)"
									}
								}
							}
							# Check the session count before shutting down the VM
							if ($ExistingSession -eq 0) {
								# Shutdown the Azure VM
								Write-Log "Stopping Azure VM: $VMName and waiting for it to complete ..."
								Stop-SessionHost -VMName $VMName
							}
						}
						# wait for the VM to stop
						$IsVMStopped = $false
						while (!$IsVMStopped) {
							$RoleInstance = Get-AzVM -Status | Where-Object { $_.Name -eq $VMName }
							if ($RoleInstance.PowerState -eq "VM deallocated") {
								$IsVMStopped = $true
								Write-Log "Azure VM has been stopped: $($RoleInstance.Name) ..."
							}
						}
						# Check if the session host status is NoHeartbeat or Unavailable                          
						$IsSessionHostNoHeartbeat = $false
						while (!$IsSessionHostNoHeartbeat) {
							$SessionHostInfo = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName -Name $SessionHostName
							if ($SessionHostInfo.UpdateState -eq "Succeeded" -and $SessionHostInfo.Status -eq "NoHeartbeat" -or $SessionHostInfo.Status -eq "Unavailable") {
								$IsSessionHostNoHeartbeat = $true
								# Ensure the Azure VMs that are off have allow new connections mode set to True
								if ($SessionHostInfo.AllowNewSession -eq $false) {
									UpdateSessionHostToAllowNewSessions -TenantName $TenantName -HostPoolName $HostpoolName -SessionHostName $SessionHostName
								}
							}
						}
						$RoleSize = Get-AzVMSize -Location $RoleInstance.Location | Where-Object { $_.Name -eq $RoleInstance.HardwareProfile.VmSize }
						# decrement number of running session host
						[int]$NumberOfRunningHost = [int]$NumberOfRunningHost - 1
						[int]$TotalRunningCores = [int]$TotalRunningCores - $RoleSize.NumberOfCores
					}
				}
			}
		}
		$AutomationAccount = Get-AzAutomationAccount -ErrorAction Stop | Where-Object { $_.AutomationAccountName -eq $AutomationAccountName }
		$OffPeakUsageMinimumNoOfRDSH = Get-AzAutomationVariable -Name "$HostpoolName-OffPeakUsage-MinimumNoOfRDSH" -ResourceGroupName $AutomationAccount.ResourceGroupName -AutomationAccountName $AutomationAccount.AutomationAccountName -ErrorAction SilentlyContinue
		if ($OffPeakUsageMinimumNoOfRDSH) {
			[int]$MinimumNumberOfRDSH = $OffPeakUsageMinimumNoOfRDSH.Value
			$NoConnectionsofhost = 0
			if ($NumberOfRunningHost -le $MinimumNumberOfRDSH) {
				foreach ($SessionHost in $AllSessionHosts) {
					if ($SessionHost.Status -eq "Available" -and $SessionHost.Sessions -eq 0) {
						$NoConnectionsofhost = $NoConnectionsofhost + 1
					}
				}
				$NoConnectionsofhost = $NoConnectionsofhost - $DefinedMinimumNumberOfRDSH
				if ($NoConnectionsofhost -gt $DefinedMinimumNumberOfRDSH) {
					[int]$MinimumNumberOfRDSH = [int]$MinimumNumberOfRDSH - $NoConnectionsofhost
					Set-AzAutomationVariable -Name "$HostpoolName-OffPeakUsage-MinimumNoOfRDSH" -ResourceGroupName $AutomationAccount.ResourceGroupName -AutomationAccountName $AutomationAccount.AutomationAccountName -Encrypted $false -Value $MinimumNumberOfRDSH
				}
			}
		}
		$HostpoolMaxSessionLimit = $HostpoolInfo.MaxSessionLimit
		$HostpoolSessionCount = (Get-RdsUserSession -TenantName $TenantName -HostPoolName $HostpoolName).Count
		if ($HostpoolSessionCount -ne 0) {
			# Calculate how many sessions will be allowed in minimum number of RDSH VMs in off peak hours and calculate TotalAllowSessions Scale Factor
			$TotalAllowSessionsInOffPeak = [int]$MinimumNumberOfRDSH * $HostpoolMaxSessionLimit
			$SessionsScaleFactor = $TotalAllowSessionsInOffPeak * 0.90
			$ScaleFactor = [math]::Floor($SessionsScaleFactor)

			if ($HostpoolSessionCount -ge $ScaleFactor) {
				$ListOfSessionHosts = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostpoolName | Where-Object { $_.Status -eq "NoHeartbeat" -or $_.Status -eq "Unavailable" }
				#$AllSessionHosts = Compare-Object $ListOfSessionHosts $SkipSessionhosts | Where-Object { $_.SideIndicator -eq '<=' } | ForEach-Object { $_.InputObject }
				$AllSessionHosts = $ListOfSessionHosts | Where-Object { $SkipSessionhosts -notcontains $_ }
				foreach ($SessionHost in $AllSessionHosts) {
					# Check the session host status and if the session host is healthy before starting the host
					if ($SessionHost.UpdateState -eq "Succeeded") {
						Write-Log "Existing sessionhost sessions value reached near by hostpool maximumsession limit, need to start the session host"
						$SessionHostName = $SessionHost.SessionHostName | Out-String

						Start-SessionHost -TenantName $TenantName -HostPoolName $HostpoolName -SessionHostName $SessionHost.SessionHostName

						# Increment the number of running session host
						[int]$NumberOfRunningHost = [int]$NumberOfRunningHost + 1
						# Increment the number of minimumnumberofrdsh
						[int]$MinimumNumberOfRDSH = [int]$MinimumNumberOfRDSH + 1
						$OffPeakUsageMinimumNoOfRDSH = Get-AzAutomationVariable -Name "$HostpoolName-OffPeakUsage-MinimumNoOfRDSH" -ResourceGroupName $AutomationAccount.ResourceGroupName -AutomationAccountName $AutomationAccount.AutomationAccountName -ErrorAction SilentlyContinue
						if (!$OffPeakUsageMinimumNoOfRDSH) {
							New-AzAutomationVariable -Name "$HostpoolName-OffPeakUsage-MinimumNoOfRDSH" -ResourceGroupName $AutomationAccount.ResourceGroupName -AutomationAccountName $AutomationAccount.AutomationAccountName -Encrypted $false -Value $MinimumNumberOfRDSH -Description "Dynamically generated minimumnumber of RDSH value"
						}
						else {
							Set-AzAutomationVariable -Name "$HostpoolName-OffPeakUsage-MinimumNoOfRDSH" -ResourceGroupName $AutomationAccount.ResourceGroupName -AutomationAccountName $AutomationAccount.AutomationAccountName -Encrypted $false -Value $MinimumNumberOfRDSH
						}
						# Calculate available capacity of sessions
						$RoleSize = Get-AzVMSize -Location $RoleInstance.Location | Where-Object { $_.Name -eq $RoleInstance.HardwareProfile.VmSize }
						$AvailableSessionCapacity = $TotalAllowSessions + $HostpoolInfo.MaxSessionLimit
						[int]$TotalRunningCores = [int]$TotalRunningCores + $RoleSize.NumberOfCores
						Write-Log "New available session capacity is: $AvailableSessionCapacity"
						break
					}
				}
			}

		}
	}

	Write-Log "HostPool: $HostpoolName, Total running cores: $TotalRunningCores, Number of running session hosts: $NumberOfRunningHost"
	Write-Log "End WVD HostPool scale optimization."
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