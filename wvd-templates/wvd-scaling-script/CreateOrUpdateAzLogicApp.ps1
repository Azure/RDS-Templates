
# //todo refactor
<#
.SYNOPSIS
	This is a sample script to deploy the required resources to schedule basic scale in Microsoft Azure.
	v0.1.2
	
.DESCRIPTION
	This sample script will create the scale script execution trigger required resources in Microsoft Azure. Resources are azure logic app for each hostpool.
    Run this PowerShell script in adminstrator mode
    This script depends on Az PowerShell module. To install Az module execute the following command. Use "-AllowClobber" parameter if you have more than one version of PowerShell modules installed.
	
    PS C:\> Install-Module Az -AllowClobber
    
.PARAMETER TenantGroupName
 Optional
 Provide the name of the tenant group in the Windows Virtual Desktop deployment.
.PARAMETER TenantName
 Required
 Provide the name of the tenant in the Windows Virtual Desktop deployment.
.PARAMETER HostpoolName
 Required
 Provide the name of the WVD Host Pool.
.PARAMETER AutomationAccountName
 Required
 Provide the name of the name of the automation account which has the published basic scale script.
.PARAMETER RecurrenceInterval
 Required
 Provide the RecurrenceInterval. Scheduler job will run on recurrence basis, so provide RecurrenceInterval in minutes.
.PARAMETER AADTenantId
 Required
 Provide Tenant ID of Azure Active Directory.
.PARAMETER SubscriptionId
 Required
 Provide Subscription Id of the Azure.
.PARAMETER BeginPeakTime
 Required
 Provide begin of the peak usage time.
.PARAMETER EndPeakTime
 Required
 Provide end of the peak usage time.
.PARAMETER TimeDifference
 Required
 Provide the Time difference between local time and UTC, in hours (Example: India Standard Time is +5:30).
.PARAMETER SessionThresholdPerCPU
 Required
 Provide the Maximum number of sessions per CPU threshold used to determine when a new RDSH server needs to be started.
.PARAMETER MinimumNumberOfRDSH
 Required
 Provide the Minimum number of host pool VMs to keep running during off-peak usage time.
.PARAMETER MaintenanceTagName
 Required
 Provide the name of the MaintenanceTagName. Any session host VM with this tag will be ignored
.PARAMETER LimitSecondsToForceLogOffUser
 Required
 Provide the number of seconds to wait before forcing users to logoff. If 0, the session host will skipped, nothing will be done. (https://aka.ms/wvdscale#how-the-scaling-tool-works)
.PARAMETER Location
 Required
 Provide the name of the Location to create azure resources.
.PARAMETER LogOffMessageTitle
 Required
 Provide the Message title sent to a user before forcing logoff.
.PARAMETER LogOffMessageBody
 Required
 Provide the Message body to send to a user before forcing logoff.
.PARAMETER LogAnalyticsWorkspaceId
 Optional
 Provide the log anayltics workspace id.
.PARAMETER LogAnalyticsPrimaryKey
 Optional
 Provide the log anayltics workspace primary key.
.PARAMETER ResourcegroupName
 Required
 Provide the name of the resouce gorup name to create logic app.
.PARAMETER ConnectionAssetName
 Required
 Provide name of the AzureRunAsAccount which is created manually from azure portal.
.PARAMETER WebhookURI
 Required
 Provide URI of the azure automation account webhook

 Example: .\createazurelogicapp.ps1 -AADTenantID "Your Azure TenantID" -SubscriptionID "Your Azure SubscriptionID" -TenantGroupName "Name of the WVD Tenant Group Name" -TenantName "Name of the WVD Tenant Name" -HostPoolName "Name of the HostPoolName" -PeakLoadBalancingType "Load balancing type in Peak hours" -MaintenanceTagName "Name of the Tag Name" -RecurrenceInterval "Repeat job every and select the appropriate period of time in minutes (Ex. 15)" -BeginPeakTime "9:00" -EndPeakTime "18:00" -TimeDifference "+5:30" -SessionThresholdPerCPU 6 -MinimumNumberOfRDSH 2 -LimitSecondsToForceLogOffUser 20 –LogOffMessageTitle "System Under Maintenance" -LogOffMessageBody "Please save your work and logoff!" –Location "Central US" -LogAnalyticsWorkspaceId "log analytic workspace id" -LogAnalyticsPrimaryKey "log analytic workspace primary key" -ResourcegroupName "Name of the resoure group" -ConnectionAssetName "Name of the azure automation account connection" -WebhookURI "URI of the Azure automation account Webhook" -AutomationAccountName	"Name of the automation account which is basic scale script published"

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
	[int]$LimitSecondsToForceLogOffUser = 15*60,

	[Parameter(mandatory = $false)]
	[string]$LogOffMessageTitle = 'Machine is about to shutdown.',

	[Parameter(mandatory = $false)]
	[string]$LogOffMessageBody = 'Your session will be logged off. Please save and close everything.',

	[Parameter(mandatory = $true)]
	[string]$WebhookURI,

	[Parameter(mandatory = $false)]
	# //todo change this to use master branch when we go GA
	[string]$ArtifactsURI = 'https://raw.githubusercontent.com/Azure/RDS-Templates/wvd_scaling/wvd-templates/wvd-scaling-script'
)

$UseRDSAPI = !$UseARMAPI

# //todo improve error logging, externalize, centralize vars

# Setting ErrorActionPreference to stop script execution when error occurs
$ErrorActionPreference = "Stop"

if ($UseRDSAPI -and [string]::IsNullOrWhiteSpace($TenantName)) {
	throw "TenantName cannot be null or empty space: $TenantName"
}
if (!$HostPoolResourceGroupName) {
	$HostPoolResourceGroupName = $ResourceGroupName
}

# Set the ExecutionPolicy
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force -Confirm:$false

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
	"AADTenantId"                   = $AADTenantId
	"SubscriptionId"                = $SubscriptionId
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