
<#
.SYNOPSIS
	This is a sample script to deploy the required resources to execute scaling script in Microsoft Azure Automation Account.
	v0.1.7
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
	[string]$AutomationAccountName = "WVDAutoScaleAutomationAccount",

	[Parameter(mandatory = $false)]
	[string]$Location = "West US2",

	[Parameter(mandatory = $false)]
	[string]$WorkspaceName,

	[Parameter(mandatory = $false)]
	[string]$ArtifactsURI = 'https://raw.githubusercontent.com/Azure/RDS-Templates/master/wvd-templates/wvd-scaling-script'
)

$UseRDSAPI = !$UseARMAPI

# //todo refactor, improve error logging, externalize, centralize vars

# Setting ErrorActionPreference to stop script execution when error occurs
$ErrorActionPreference = "Stop"

# Initializing variables
[string]$RunbookName = "WVDAutoScaleRunbook"
[string]$WebhookName = "WVDAutoScaleWebhook"

if (!$UseRDSAPI) {
	$RunbookName += 'ARMBased'
	$WebhookName += 'ARMBased'
}

# Set the ExecutionPolicy if not being ran in CloudShell as this command fails in CloudShell
if ($env:POWERSHELL_DISTRIBUTION_CHANNEL -ne 'CloudShell') {
	Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force -Confirm:$false
}

# Import Az and AzureAD modules
Import-Module Az.Resources
Import-Module Az.Accounts
Import-Module Az.OperationalInsights
Import-Module Az.Automation

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

# Check if the resourcegroup exist
$ResourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -Location $Location -ErrorAction SilentlyContinue
if (!$ResourceGroup) {
	New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force -Verbose
	Write-Output "Resource Group was created with name: $ResourceGroupName"
}

[array]$RequiredModules = @(
	'Az.Accounts'
	'Az.Compute'
	'Az.Resources'
	'Az.Automation'
	'OMSIngestionAPI'
)
if ($UseRDSAPI) {
	$RequiredModules += 'Microsoft.RDInfra.RDPowershell'
}
else {
	$RequiredModules += 'Az.DesktopVirtualization'
}

$SkipHttpErrorCheckParam = (Get-Command Invoke-WebRequest).Parameters['SkipHttpErrorCheck']

# Function to check if the module is imported
function Wait-ForModuleToBeImported {
	param(
		[Parameter(mandatory = $true)]
		[string]$ResourceGroupName,

		[Parameter(mandatory = $true)]
		[string]$AutomationAccountName,

		[Parameter(mandatory = $true)]
		[string]$ModuleName
	)

	$StartTime = Get-Date
	$TimeOut = 30*60 # 30 min

	while ($true) {
		if ((Get-Date).Subtract($StartTime).TotalSeconds -ge $TimeOut) {
			throw "Wait timed out. Taking more than $TimeOut seconds"
		}
		$AutoModule = Get-AzAutomationModule -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $ModuleName -ErrorAction SilentlyContinue
		if ($AutoModule.ProvisioningState -eq 'Succeeded') {
			Write-Output "Successfully imported module '$ModuleName' into Automation Account Modules"
			break
		}
		Write-Output "Waiting for module '$ModuleName' to get imported into Automation Account Modules ..."
		Start-Sleep -Seconds 30
	}
}

# Function to add required modules to Azure Automation account
function Add-ModuleToAutoAccount {
	param(
		[Parameter(mandatory = $true)]
		[string]$ResourceGroupName,

		[Parameter(mandatory = $true)]
		[string]$AutomationAccountName,

		[Parameter(mandatory = $true)]
		[string]$ModuleName,

		# if not specified latest version will be imported
		[Parameter(mandatory = $false)]
		[string]$ModuleVersion
	)

	[string]$Url = "https://www.powershellgallery.com/api/v2/Search()?`$filter=IsLatestVersion&searchTerm=%27$ModuleName $ModuleVersion%27&targetFramework=%27%27&includePrerelease=false&`$skip=0&`$top=40"

	[array]$SearchResult = Invoke-RestMethod -Method Get -Uri $Url
	if ($SearchResult.Count -gt 1) {
		$SearchResult = $SearchResult[0]
	}

	if (!$SearchResult) {
		throw "Could not find module '$ModuleName' on PowerShell Gallery."
	}
	if ($SearchResult.Length -gt 1) {
		throw "Module name '$ModuleName' returned multiple results. Please specify an exact module name."
	}
	$PackageDetails = Invoke-RestMethod -Method Get -Uri $SearchResult.Id

	if (!$ModuleVersion) {
		$ModuleVersion = $PackageDetails.entry.properties.version
	}

	# Check if the required modules are imported
	$ImportedModule = Get-AzAutomationModule -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $ModuleName -ErrorAction SilentlyContinue
	if ($ImportedModule -and $ImportedModule.Version -ge $ModuleVersion) {
		return
	}

	[string]$ModuleContentUrl = "https://www.powershellgallery.com/api/v2/package/$ModuleName/$ModuleVersion"

	# Test if the module/version combination exists
	try {
		Invoke-RestMethod $ModuleContentUrl | Out-Null
	}
	catch {
		throw [System.Exception]::new("Module with name '$ModuleName' of version '$ModuleVersion' does not exist. Are you sure the version specified is correct?", $PSItem.Exception)
	}

	# Find the actual blob storage location of the module
	$Res = $null
	do {
		$ActualUrl = $ModuleContentUrl
		if ($SkipHttpErrorCheckParam) {
			$Res = Invoke-WebRequest -Uri $ModuleContentUrl -MaximumRedirection 0 -UseBasicParsing -SkipHttpErrorCheck -ErrorAction Ignore
		}
		else {
			$Res = Invoke-WebRequest -Uri $ModuleContentUrl -MaximumRedirection 0 -UseBasicParsing -ErrorAction Ignore
		}
		$ModuleContentUrl = $Res.Headers['Location']
	} while ($ModuleContentUrl)

	New-AzAutomationModule -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $ModuleName -ContentLink $ActualUrl -Verbose
	Wait-ForModuleToBeImported -ModuleName $ModuleName -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName
}

# Note: the URL for the scaling script will be suffixed with current timestamp in order to force the ARM template to update the existing runbook script in the auto account if any
$URISuffix = "?time=$(get-date -f "yyyy-MM-dd_HH-mm-ss")"
$ScriptURI = "$ArtifactsURI/basicScale.ps1"
if (!$UseRDSAPI) {
	$ScriptURI = "$ArtifactsURI/ARM_based/basicScale.ps1"
}

# Creating an automation account & runbook and publish the scaling script file
$DeploymentStatus = New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateUri "$ArtifactsURI/runbookCreationTemplate.json" -automationAccountName $AutomationAccountName -RunbookName $RunbookName -location $Location -scriptUri "$ScriptURI$($URISuffix)" -Force -Verbose

if ($DeploymentStatus.ProvisioningState -ne 'Succeeded') {
	throw "Some error occurred while deploying a runbook. Deployment Provisioning Status: $($DeploymentStatus.ProvisioningState)"
}

# Check if the Webhook URI exists in automation variable
$WebhookURIAutoVarName = 'WebhookURI'
if (!$UseRDSAPI) {
	$WebhookURIAutoVarName += 'ARMBased'
}
$WebhookURI = Get-AzAutomationVariable -Name $WebhookURIAutoVarName -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -ErrorAction SilentlyContinue
if (!$WebhookURI) {
	$Webhook = New-AzAutomationWebhook -Name $WebhookName -RunbookName $RunbookName -IsEnabled $true -ExpiryTime (Get-Date).AddYears(5) -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Force -Verbose
	Write-Output "Automation Account Webhook is created with name '$WebhookName'"
	New-AzAutomationVariable -Name $WebhookURIAutoVarName -Encrypted $false -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Value $Webhook.WebhookURI
	Write-Output "Webhook URI stored in Azure Automation Acccount variables"
	$WebhookURI = Get-AzAutomationVariable -Name $WebhookURIAutoVarName -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -ErrorAction SilentlyContinue
}

# Required modules imported from Automation Account Modules gallery for Scale Script execution
foreach ($ModuleName in $RequiredModules) {
	Add-ModuleToAutoAccount -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -ModuleName $ModuleName
}

if (!$WorkspaceName) {
	Write-Output "Azure Automation Account Name: $AutomationAccountName"
	Write-Output "Webhook URI: $($WebhookURI.value)"
	return
}

# Check if the log analytic workspace exists
$LAWorkspace = Get-AzOperationalInsightsWorkspace | Where-Object { $_.Name -eq $WorkspaceName }
if (!$LAWorkspace) {
	throw "Provided log analytic workspace doesn't exist in your Subscription."
}

$WorkSpace = Get-AzOperationalInsightsWorkspaceSharedKeys -ResourceGroupName $LAWorkspace.ResourceGroupName -Name $WorkspaceName -WarningAction Ignore
$LogAnalyticsPrimaryKey = $Workspace.PrimarySharedKey
$LogAnalyticsWorkspaceId = (Get-AzOperationalInsightsWorkspace -ResourceGroupName $LAWorkspace.ResourceGroupName -Name $WorkspaceName).CustomerId.GUID

# Create the function to create the authorization signature
function New-Signature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource) {
	$xHeaders = "x-ms-date:" + $date
	$stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource

	$bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
	$keyBytes = [Convert]::FromBase64String($sharedKey)

	$sha256 = New-Object System.Security.Cryptography.HMACSHA256
	$sha256.Key = $keyBytes
	$calculatedHash = $sha256.ComputeHash($bytesToHash)
	$encodedHash = [Convert]::ToBase64String($calculatedHash)
	$authorization = 'SharedKey {0}:{1}' -f $customerId, $encodedHash
	return $authorization
}

# Create the function to create and post the request
function Send-LogAnalyticsData ($customerId, $sharedKey, $body, $logType) {
	$method = "POST"
	$contentType = "application/json"
	$resource = "/api/logs"
	$rfc1123date = [datetime]::UtcNow.ToString("r")
	$contentLength = $body.Length
	$signature = New-Signature -customerId $customerId -sharedKey $sharedKey -Date $rfc1123date -contentLength $contentLength -Method $method -ContentType $contentType -resource $resource
	$uri = "https://$($customerId).ods.opinsights.azure.$(if ($AzContext.Environment.Name -eq 'AzureUSGovernment') { 'us' } else { 'com' })$($resource)?api-version=2016-04-01"

	$headers = @{
		"Authorization"        = $signature;
		"Log-Type"             = $logType;
		"x-ms-date"            = $rfc1123date;
		"time-generated-field" = $TimeStampField;
	}

	$response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $body -UseBasicParsing
	return $response.StatusCode
}

# Specify the name of the record type that you'll be creating
[string]$TenantScaleLogType = "WVDTenantScale_CL"
# Specify a field with the created time for the records
$TimeStampField = (Get-Date).GetDateTimeFormats(115)
# Custom WVDTenantScale Table
$CustomLogWVDTenantScale = @"
[
	{
		"hostpoolName":" ",
		"logmessage": " "
	}
]
"@

# Submit the data to the API endpoint
Send-LogAnalyticsData -customerId $LogAnalyticsWorkspaceId -sharedKey $LogAnalyticsPrimaryKey -Body ([System.Text.Encoding]::UTF8.GetBytes($CustomLogWVDTenantScale)) -logType $TenantScaleLogType

Write-Output "Log Analytics Workspace ID: $LogAnalyticsWorkspaceId"
Write-Output "Log Analytics Primary Key: $LogAnalyticsPrimaryKey"

Write-Output "Azure Automation Account Name: $AutomationAccountName"
Write-Output "Webhook URI: $($WebhookURI.value)"
