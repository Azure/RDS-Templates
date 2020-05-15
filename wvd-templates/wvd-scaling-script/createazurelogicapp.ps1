<#
.SYNOPSIS
	This is a sample script to deploy the required resources to schedule basic scale in Microsoft Azure.
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
	[Parameter(mandatory = $False)]
	[string]$TenantGroupName = "Default Tenant Group",

	[Parameter(mandatory = $True)]
	[string]$TenantName,

	[Parameter(mandatory = $True)]
	[string]$HostpoolName,

	[Parameter(mandatory = $True)]
	[string]$AutomationAccountName,

	[Parameter(mandatory = $True)]
	[string]$WebhookURI,

	[Parameter(mandatory = $True)]
	[int]$RecurrenceInterval,

	[Parameter(mandatory = $True)]
	[string]$AADTenantId,

	[Parameter(mandatory = $True)]
	[string]$SubscriptionId,

	[Parameter(mandatory = $True)]
	[string]$BeginPeakTime,

	[Parameter(mandatory = $True)]
	[string]$EndPeakTime,

	[Parameter(mandatory = $True)]
	[string]$TimeDifference,

	[Parameter(mandatory = $True)]
	$SessionThresholdPerCPU,

	[Parameter(mandatory = $True)]
	[int]$MinimumNumberOfRDSH,

	[Parameter(mandatory = $True)]
	[string]$MaintenanceTagName,

	[Parameter(mandatory = $True)]
	[int]$LimitSecondsToForceLogOffUser,

	[Parameter(mandatory = $False)]
	[string]$LogAnalyticsWorkspaceId,

	[Parameter(mandatory = $False)]
	[string]$LogAnalyticsPrimaryKey,

	[Parameter(mandatory = $True)]
	[string]$ConnectionAssetName,

	[Parameter(mandatory = $True)]
	[string]$Location,

	[Parameter(mandatory = $True)]
	[string]$ResourcegroupName,

	[Parameter(mandatory = $True)]
	[string]$LogOffMessageTitle,

	[Parameter(mandatory = $True)]
	[string]$LogOffMessageBody
)

#Initializing variables
$RDBrokerURL = "https://rdbroker.wvd.microsoft.com"
$ScriptRepoLocation = "https://raw.githubusercontent.com/Azure/RDS-Templates/master/wvd-templates/wvd-scaling-script"

# Setting ErrorActionPreference to stop script execution when error occurs
$ErrorActionPreference = "Stop"

[System.Collections.Generic.List[System.Object]]$HostpoolNames = $HostpoolName.Split(",")

# Set the ExecutionPolicy
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force -Confirm:$false

# Import Az and AzureAD modules
Import-Module Az.LogicApp
Import-Module Az.Resources
Import-Module Az.Accounts

# Get the context
$Context = Get-AzContext
if (!$Context) {
	throw 'No Azure context found. Please authenticate to Azure using Login-AzAccount cmdlet and then run this script'
}

# Get the WVD context
$WVDContext = Get-RdsContext -DeploymentUrl $RDBrokerURL
if (!$WVDContext) {
	throw "No WVD context found. Please authenticate to WVD using Add-RdsAccount -DeploymentURL 'https://rdbroker.wvd.microsoft.com' cmdlet and then run this script"
}

# Select the subscription
$Subscription = Select-azSubscription -SubscriptionId $SubscriptionId
Set-AzContext -SubscriptionObject $Subscription.ExtendedProperties

# Get the Role Assignment of the authenticated user
$RoleAssignment = Get-AzRoleAssignment -SignInName $Context.Account

if ($RoleAssignment.RoleDefinitionName -notin @('Owner', 'Contributor')) {
	throw 'Authenticated user should have the Owner/Contributor permissions to the subscription'
}

# Check if the automation account exist in your Azure subscription
$CheckRG = Get-AzResourceGroup -Name $ResourcegroupName -Location $Location -ErrorAction SilentlyContinue
if (!$CheckRG) {
	Write-Output "The specified resourcegroup does not exist, creating the resourcegroup $ResourcegroupName"
	New-AzResourceGroup -Name $ResourcegroupName -Location $Location -Force
	Write-Output "ResourceGroup $ResourcegroupName created suceessfully"
}

# Creating Azure logic app to schedule job
foreach ($HPName in $HostpoolNames) {

	# Check if the hostpool load balancer type is persistent.
	$HostPoolInfo = Get-RdsHostPool -TenantName $TenantName -Name $HPName

	# //todo confirm with roop
	if ($HostpoolInfo.LoadBalancerType -eq "Persistent") {
		throw "$HPName hostpool configured with Persistent Load balancer. So scale script doesn't apply for this load balancertype. Scale script will execute only with these load balancer types: BreadthFirst, DepthFirst. Please remove this from 'HostpoolName' input and try again"
	}

	$SessionHostsList = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HPName
	[int]$SessionHostCount = ($SessionHostsList).Count

	#Check if the hostpool have session hosts and compare count with minimum number of rdsh value
	if (!$SessionHostsList) {
		Write-Output "Hostpool '$HPName' doesn't have session hosts. Deployment Script will skip the basic scale script configuration for this hostpool."
		$RmHostpoolnames += $HPName
	}
	elseif ($SessionHostCount -le $MinimumNumberOfRDSH) {
		Write-Output "Hostpool '$HPName' has less than the minimum number of session host required."
		$Confirmation = Read-Host "Do you wish to continue configuring the scale script for these available session hosts? [y/n]"
		if ($Confirmation -eq 'n') {
			Write-Output "Configuring the scale script is skipped for this hostpool '$HPName'."
			$RmHostpoolnames += $HPName
		}
		else {
			Write-Output "Configuring the scale script for the hostpool : '$HPName' and will keep the minimum required session hosts in running mode."
		}
	}

	[PSCustomObject]$RequestBody = @{
		"RDBrokerURL"                   = $RDBrokerURL;
		"AADTenantId"                   = $AADTenantId;
		"subscriptionid"                = $subscriptionid;
		"TimeDifference"                = $TimeDifference;
		"TenantGroupName"               = $TenantGroupName;
		"TenantName"                    = $TenantName;
		"HostPoolName"                  = $HPName;
		"MaintenanceTagName"            = $MaintenanceTagName;
		"LogAnalyticsWorkspaceId"       = $LogAnalyticsWorkspaceId;
		"LogAnalyticsPrimaryKey"        = $LogAnalyticsPrimaryKey;
		"ConnectionAssetName"           = $ConnectionAssetName;
		"BeginPeakTime"                 = $BeginPeakTime;
		"EndPeakTime"                   = $EndPeakTime;
		"MinimumNumberOfRDSH"           = $MinimumNumberOfRDSH;
		"SessionThresholdPerCPU"        = $SessionThresholdPerCPU;
		"LimitSecondsToForceLogOffUser" = $LimitSecondsToForceLogOffUser;
		"LogOffMessageTitle"            = $LogOffMessageTitle;
		"AutomationAccountName"         = $AutomationAccountName;
		"LogOffMessageBody"             = $LogOffMessageBody 
	}
	$RequestBodyJson = $RequestBody | ConvertTo-Json
	$LogicAppName = ($HPName + "_" + "Autoscale" + "_" + "Scheduler").Replace(" ", "")
	
	$SchedulerDeployment = New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateUri "$ScriptRepoLocation/azureLogicAppCreation.json" -logicappname $LogicAppName -webhookURI $WebhookURI.Replace("`n", "").Replace("`r", "") -actionSettingsBody $RequestBodyJson -recurrenceInterval $RecurrenceInterval -Verbose

	if ($SchedulerDeployment.ProvisioningState -eq "Succeeded") {
		Write-Output "$HPName hostpool successfully configured with logic app scheduler"
	}
}