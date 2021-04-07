
<#
.SYNOPSIS
	This is a sample script to deploy the required resources to schedule basic scale in Microsoft Azure.
	v0.1.6
	# //todo refactor stuff from https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help?view=powershell-5.1
#>
param(
	[Parameter(mandatory = $false)]
	[string]$AADTenantId,
	
	[Parameter(mandatory = $false)]
	[string]$SubscriptionId,
	
	[switch]$UseARMAPI,

	[Parameter(mandatory = $false)]
	[string]$ResourceGroupName = "WVDAutoScaleResourceGroup",

	[Parameter(mandatory = $false)]
	[string]$Location = "West US2",

	# Note: only for rds api
	[Parameter(mandatory = $false)]
	[string]$RDBrokerURL = 'https://rdbroker.wvd.microsoft.com',

	# Note: only for rds api
	[Parameter(mandatory = $false)]
	[string]$TenantGroupName = 'Default Tenant Group',

	# Note: only for rds api
	[Parameter(mandatory = $false)]
	[string]$TenantName,

	[Parameter(mandatory = $true)]
	[string]$HostPoolName,

	# Note: only for az wvd api
	[Parameter(mandatory = $false)]
	[string]$HostPoolResourceGroupName,

	[Parameter(mandatory = $false)]
	[string]$LogAnalyticsWorkspaceId,

	[Parameter(mandatory = $false)]
	[string]$LogAnalyticsPrimaryKey,

	[Parameter(mandatory = $false)]
	[string]$ConnectionAssetName = 'AzureRunAsConnection',

	[Parameter(mandatory = $false)]
	[int]$RecurrenceInterval = 15, # in minutes

	[Parameter(mandatory = $false)]
	[string]$BeginPeakTime = '09:00',

	[Parameter(mandatory = $false)]
	[string]$EndPeakTime = '17:00',

	[Parameter(mandatory = $false)]
	[string]$TimeDifference = '-7:00',

	[Parameter(mandatory = $false)]
	[double]$SessionThresholdPerCPU = 1,

	[Parameter(mandatory = $false)]
	[int]$MinimumNumberOfRDSH = 1,

	[Parameter(mandatory = $false)]
	[string]$MaintenanceTagName,

	[Parameter(mandatory = $false)]
	[int]$LimitSecondsToForceLogOffUser = 15 * 60,

	[Parameter(mandatory = $false)]
	[string]$LogOffMessageTitle = 'Machine is about to shutdown.',

	[Parameter(mandatory = $false)]
	[string]$LogOffMessageBody = 'Your session will be logged off. Please save and close everything.',

	[Parameter(mandatory = $true)]
	[string]$WebhookURI,

	[Parameter(mandatory = $false)]
	[string]$ArtifactsURI = 'https://raw.githubusercontent.com/Azure/RDS-Templates/master/wvd-templates/wvd-scaling-script'
)

$UseRDSAPI = !$UseARMAPI

# //todo refactor, improve error logging, externalize, centralize vars

# Setting ErrorActionPreference to stop script execution when error occurs
$ErrorActionPreference = "Stop"

if ($UseRDSAPI -and [string]::IsNullOrWhiteSpace($TenantName)) {
	throw "TenantName cannot be null or empty space: $TenantName"
}
if (!$HostPoolResourceGroupName) {
	$HostPoolResourceGroupName = $ResourceGroupName
}

# Set the ExecutionPolicy if not being ran in CloudShell as this command fails in CloudShell
if ($env:POWERSHELL_DISTRIBUTION_CHANNEL -ne 'CloudShell') {
	Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force -Confirm:$false
}

# Import Az and AzureAD modules
Import-Module Az.LogicApp
Import-Module Az.Resources
Import-Module Az.Accounts

# Get the azure context
$AzContext = Get-AzContext
if (!$AzContext) {
	throw 'No Azure context found. Please authenticate to Azure using Login-AzAccount cmdlet and then run this script'
}

if (!$AADTenantId) {
	$AADTenantId = $AzContext.Tenant.Id
}
if (!$SubscriptionId) {
	$SubscriptionId = $AzContext.Subscription.Id
}

if ($AADTenantId -ne $AzContext.Tenant.Id -or $SubscriptionId -ne $AzContext.Subscription.Id) {
	# Select the subscription
	$AzContext = Set-AzContext -SubscriptionId $SubscriptionId -TenantId $AADTenantId

	if ($AADTenantId -ne $AzContext.Tenant.Id -or $SubscriptionId -ne $AzContext.Subscription.Id) {
		throw "Failed to set Azure context with subscription ID '$SubscriptionId' and tenant ID '$AADTenantId'. Current context: $($AzContext | Format-List -Force | Out-String)"
	}
}

# Get the Role Assignment of the authenticated user
$RoleAssignments = Get-AzRoleAssignment -SignInName $AzContext.Account -ExpandPrincipalGroups
if (!($RoleAssignments | Where-Object { $_.RoleDefinitionName -in @('Owner', 'Contributor') })) {
	throw 'Authenticated user should have the Owner/Contributor permissions to the subscription'
}

if ($UseRDSAPI) {
	# Get the WVD context
	$WVDContext = Get-RdsContext -DeploymentUrl $RDBrokerURL
	if (!$WVDContext) {
		throw "No WVD context found. Please authenticate to WVD using `"Add-RdsAccount -DeploymentURL '$RDBrokerURL'`" cmdlet and then run this script"
	}

	# Set WVD context to the appropriate tenant group
	[string]$CurrentTenantGroupName = $WVDContext.TenantGroupName
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
}

# Check if the resource group exists
$ResourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -Location $Location -ErrorAction SilentlyContinue
if (!$ResourceGroup) {
	New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force -Verbose
	Write-Output "Resource Group was created with name: $ResourceGroupName"
}

# Check if the hostpool load balancer type is persistent.
$HostPoolInfo = $null
if ($UseRDSAPI) {
	$HostPoolInfo = Get-RdsHostPool -Name $HostPoolName -TenantName $TenantName
}
else {
	$HostPoolInfo = Get-AzWvdHostPool -Name $HostPoolName -ResourceGroupName $HostPoolResourceGroupName
}

if ($HostPoolInfo.LoadBalancerType -eq "Persistent") {
	throw "$HostPoolName HostPool configured with Persistent Load balancer. Scaling tool will only apply to these load balancer types: BreadthFirst, DepthFirst. Please remove this HostPool from 'HostpoolNames' input and try again"
}

$SessionHostsList = $null
if ($UseRDSAPI) {
	$SessionHostsList = Get-RdsSessionHost -HostPoolName $HostPoolName -TenantName $TenantName
}
else {
	$SessionHostsList = Get-AzWvdSessionHost -HostPoolName $HostPoolName -ResourceGroupName $HostPoolResourceGroupName
}

#Check if the hostpool have session hosts and compare count with minimum number of rdsh value
if (!$SessionHostsList) {
	Write-Warning "Hostpool '$HostPoolName' doesn't have any session hosts"
}
elseif ($SessionHostsList.Count -le $MinimumNumberOfRDSH) {
	Write-Warning "Hostpool '$HostPoolName' has less than the minimum number of session host required"
}

[PSCustomObject]$RequestBody = @{
	"LogAnalyticsWorkspaceId"       = $LogAnalyticsWorkspaceId
	"LogAnalyticsPrimaryKey"        = $LogAnalyticsPrimaryKey
	"ConnectionAssetName"           = $ConnectionAssetName
	"AADTenantId"                   = $AADTenantId 		# Note: only used by the basicScale.ps1 v0.1.32 and before, so this is added for backwards compatibility
	"SubscriptionId"                = $SubscriptionId 	# Note: only used by the basicScale.ps1 v0.1.32 and before, so this is added for backwards compatibility
	"EnvironmentName"               = $AzContext.Environment.Name
	"UseARMAPI"                     = $UseARMAPI
	"ResourceGroupName"             = $HostPoolResourceGroupName
	"HostPoolName"                  = $HostPoolName
	"MaintenanceTagName"            = $MaintenanceTagName
	"TimeDifference"                = $TimeDifference
	"BeginPeakTime"                 = $BeginPeakTime
	"EndPeakTime"                   = $EndPeakTime
	"SessionThresholdPerCPU"        = $SessionThresholdPerCPU
	"MinimumNumberOfRDSH"           = $MinimumNumberOfRDSH
	"LimitSecondsToForceLogOffUser" = $LimitSecondsToForceLogOffUser
	"LogOffMessageTitle"            = $LogOffMessageTitle
	"LogOffMessageBody"             = $LogOffMessageBody 
}
if ($UseRDSAPI) {
	$RequestBody.'RDBrokerURL' = $RDBrokerURL
	$RequestBody.'TenantGroupName' = $TenantGroupName
	$RequestBody.'TenantName' = $TenantName
}
[string]$RequestBodyJson = $RequestBody | ConvertTo-Json
[string]$LogicAppName = "$($HostPoolName)_Autoscale_Scheduler".Replace(" ", "-")

$SchedulerDeployment = New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateUri "$ArtifactsURI/logicAppCreationTemplate.json" -logicAppName $LogicAppName -WebhookURI $WebhookURI.Replace("`n", "").Replace("`r", "") -actionSettingsBody $RequestBodyJson -recurrenceInterval $RecurrenceInterval -Verbose

if ($SchedulerDeployment.ProvisioningState -ne 'Succeeded') {
	throw "Failed to create logic app scheduler for HostPool '$HostPoolName'. Deployment Provisioning Status: $($SchedulerDeployment.ProvisioningState)"
}

Write-Output "$HostPoolName hostpool successfully configured with logic app scheduler"
