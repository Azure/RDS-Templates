<#
.SYNOPSIS
	This is a sample script to deploy the required resources to execute scaling script in Microsoft Azure Automation Account.
.DESCRIPTION
	This sample script will create the scale script execution required resources in Microsoft Azure. Resources are resource group, automation account, automation account runbook,
    automation account webhook, log analytic workspace and customtables.
    Run this PowerShell script in adminstrator mode
    This script depends on Az PowerShell module. To install Az module execute the following commands. Use "-AllowClobber" parameter if you have more than one version of PowerShell modules installed.
	
    PS C:\> Install-Module Az -AllowClobber

.PARAMETER SubscriptionId
 Required
 Provide Subscription Id of the Azure.

.PARAMETER ResourceGroupName
 Optional
 Name of the resource group to use
 If the resource group does not exist it will be created
 
.PARAMETER AutomationAccountName
 Optional
 Provide the name of the automation account name you want to create.

.PARAMETER Location
 Optional
 The datacenter location of the resources

.PARAMETER WorkspaceName
 Optional
 Provide name of the log analytics workspace.

.NOTES
 If you are providing existing automation account, you need to provide existing automation account ResourceGroupName for ResourceGroupName parameter.
 
 Example: .\createazureautomationaccount.ps1 -SubscriptionId "Your Azure SubscriptionId" -ResourceGroupName "Name of the resource group" -AutomationAccountName "Name of the automation account name" -Location "The datacenter location of the resources" -WorkspaceName "Provide existing log analytics workspace name" 
#>
param(
	[Parameter(mandatory = $true)]
	[string]$SubscriptionId,

	[Parameter(mandatory = $false)]
	[string]$ResourceGroupName = "WVDAutoScaleResourceGroup",

	[Parameter(mandatory = $false)]
	[string]$AutomationAccountName = "WVDAutoScaleAutomationAccount",

	[Parameter(mandatory = $false)]
	[string]$Location = "West US2",

	[Parameter(mandatory = $false)]
	[string]$WorkspaceName,
	
	[Parameter(Mandatory = $true)]
	[String]$ApplicationDisplayName,

	[Parameter(mandatory = $false)]
	[int]$SelfSignedCertNoOfMonthsUntilExpired = 12,

	[Parameter(mandatory = $false)]
	[string]$TenantGroupName = 'Default Tenant Group',

	[Parameter(mandatory = $true)]
	[string]$TenantName,

	[Parameter(mandatory = $true)]
	[array]$HostPoolNames,

	[Parameter(mandatory = $true)]
	[int]$RecurrenceInterval,

	[Parameter(mandatory = $true)]
	[string]$BeginPeakTime,

	[Parameter(mandatory = $true)]
	[string]$EndPeakTime,

	[Parameter(mandatory = $true)]
	[string]$TimeDifference,

	[Parameter(mandatory = $true)]
	$SessionThresholdPerCPU,

	[Parameter(mandatory = $true)]
	[int]$MinimumNumberOfRDSH,

	[Parameter(mandatory = $true)]
	[string]$MaintenanceTagName,

	[Parameter(mandatory = $true)]
	[int]$LimitSecondsToForceLogOffUser,

	[Parameter(mandatory = $true)]
	[string]$LogOffMessageTitle,

	[Parameter(mandatory = $true)]
	[string]$LogOffMessageBody
)

# Setting ErrorActionPreference to stop script execution when error occurs
$ErrorActionPreference = "Stop"

if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
	throw 'Not running as Administrator. Please run the script as Administrator'
}

# Initializing variables
# //todo traling '/' or not ?
[string]$ScriptRepoLocation = "https://raw.githubusercontent.com/Azure/RDS-Templates/master/wvd-templates/wvd-scaling-script/"
[string]$RunbookName = "WVDAutoScaleRunbook"
[string]$WebhookName = "WVDAutoScaleWebhook"
[string]$RDBrokerURL = 'https://rdbroker.wvd.microsoft.com'

# Set the ExecutionPolicy
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force -Confirm:$false

# Import Az and AzureAD modules
Import-Module Az.Resources
Import-Module Az.Accounts
Import-Module Az.OperationalInsights
Import-Module Az.Automation
Import-Module Az.LogicApp

# Get the azure context
$Context = Get-AzContext
if (!$Context) {
	throw 'No Azure context found. Please authenticate to Azure using Login-AzAccount cmdlet and then run this script'
}

# Select the subscription
$Subscription = Select-AzSubscription -SubscriptionId $SubscriptionId
Set-AzContext -SubscriptionObject $Subscription.ExtendedProperties

# Get the Role Assignment of the authenticated user
$RoleAssignment = Get-AzRoleAssignment -SignInName $Context.Account -ExpandPrincipalGroups

if ($RoleAssignment.RoleDefinitionName -notin @('Owner', 'Contributor')) {
	throw 'Authenticated user should have the Owner/Contributor permissions to the subscription'
}

# Get the WVD context
$WVDContext = Get-RdsContext -DeploymentUrl $RDBrokerURL
if (!$WVDContext) {
	throw "No WVD context found. Please authenticate to WVD using Add-RdsAccount -DeploymentURL '$RDBrokerURL' cmdlet and then run this script"
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

# Check if the resourcegroup exist
$ResourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -Location $Location -ErrorAction SilentlyContinue
if (!$ResourceGroup) {
	New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force -Verbose
	Write-Output "Resource Group was created with name: $ResourceGroupName"
}

# Check if the Automation Account exist
$AutomationAccount = Get-AzAutomationAccount -ResourceGroupName $ResourceGroupName -Name $AutomationAccountName -ErrorAction SilentlyContinue
if (!$AutomationAccount) {
	New-AzAutomationAccount -ResourceGroupName $ResourceGroupName -Name $AutomationAccountName -Location $Location -Plan Free -Verbose
	Write-Output "Automation Account was created with name: $AutomationAccountName"
}

[array]$RequiredModules = @(
	[PSCustomObject]@{ ModuleName = 'Az.Accounts'; ModuleVersion = '1.6.4' }
	[PSCustomObject]@{ ModuleName = 'Microsoft.RDInfra.RDPowershell'; ModuleVersion = '1.0.1288.1' }
	[PSCustomObject]@{ ModuleName = 'OMSIngestionAPI'; ModuleVersion = '1.6.0' }
	[PSCustomObject]@{ ModuleName = 'Az.Compute'; ModuleVersion = '3.1.0' }
	[PSCustomObject]@{ ModuleName = 'Az.Resources'; ModuleVersion = '1.8.0' }
	[PSCustomObject]@{ ModuleName = 'Az.Automation'; ModuleVersion = '1.3.4' }
)

$SkipHttpErrorCheckParam = (Get-Command Invoke-WebRequest).Parameters.SkipHttpErrorCheck

# Function to add required modules to Azure Automation account
function Add-ModulesToAutoAccount {
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
	if ($SearchResult.Count -and $SearchResult.Length -gt 1) {
		throw "Module name '$ModuleName' returned multiple results. Please specify an exact module name."
	}
	$PackageDetails = Invoke-RestMethod -Method Get -Uri $SearchResult.Id

	if (!$ModuleVersion) {
		$ModuleVersion = $PackageDetails.entry.properties.version
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
		$ModuleContentUrl = $Res.Headers.Location
	} while ($ModuleContentUrl)

	New-AzAutomationModule -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $ModuleName -ContentLink $ActualUrl
}

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

	# //todo add time out ?
	while ($true) {
		$AutoModule = Get-AzAutomationModule -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $ModuleName -ErrorAction SilentlyContinue
		if ($AutoModule.ProvisioningState -eq 'Succeeded') {
			Write-Output "Successfully imported module '$ModuleName' into Automation Account Modules"
			break
		}
		Write-Output "Waiting for module '$ModuleName' to get imported into Automation Account Modules ..."
		Start-Sleep -Seconds 30
	}
}

# Creating a runbook and published the basic Scale script file
$DeploymentStatus = New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateUri "$ScriptRepoLocation/runbookCreationTemplate.json" -existingAutomationAccountName $AutomationAccountName -RunbookName $RunbookName -Force -Verbose

if ($DeploymentStatus.ProvisioningState -ne 'Succeeded') {
	throw "Some error occurred while deploying a runbook. Deployment Provisioning Status: $($DeploymentStatus.ProvisioningState)"
}

# Check if the Webhook URI exists in automation variable
$WebhookURI = Get-AzAutomationVariable -Name "WebhookURI" -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -ErrorAction SilentlyContinue
if (!$WebhookURI) {
	$Webhook = New-AzAutomationWebhook -Name $WebhookName -RunbookName $runbookName -IsEnabled $true -ExpiryTime (Get-Date).AddYears(5) -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Force
	Write-Output "Automation Account Webhook is created with name '$WebhookName'"
	$URIofWebhook = $Webhook.WebhookURI | Out-String
	New-AzAutomationVariable -Name "WebhookURI" -Encrypted $false -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Value $URIofWebhook
	Write-Output "Webhook URI stored in Azure Automation Acccount variables"
	$WebhookURI = Get-AzAutomationVariable -Name "WebhookURI" -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -ErrorAction SilentlyContinue
}

# Required modules imported from Automation Account Modules gallery for Scale Script execution
foreach ($Module in $RequiredModules) {
	# Check if the required modules are imported 
	$ImportedModule = Get-AzAutomationModule -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $Module.ModuleName -ErrorAction SilentlyContinue
	if (!$ImportedModule -or $ImportedModule.version -ne $Module.ModuleVersion) {
		Add-ModulesToAutoAccount -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -ModuleName $Module.ModuleName
		Wait-ForModuleToBeImported -ModuleName $Module.ModuleName -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName
	}
}

if ($WorkspaceName) {
	# Check if the log analytic workspace is exist
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
		$signature = New-Signature -customerId $customerId -sharedKey $sharedKey -Date $rfc1123date -contentLength $contentLength -FileName $fileName -Method $method -ContentType $contentType -resource $resource
		$uri = "https://" + $customerId + ".ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"

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

	Write-Output "Log Analytics workspace id: $LogAnalyticsWorkspaceId"
	Write-Output "Log Analytics workspace primarykey: $LogAnalyticsPrimaryKey"
}

Write-Output "Automation Account Name: $AutomationAccountName"
Write-Output "Webhook URI: $($WebhookURI.value)"

# https://docs.microsoft.com/en-us/azure/automation/manage-runas-account#powershell-script-to-create-a-run-as-account
function New-CustomSelfSignedCertificate([string] $certificateName, [SecureString] $selfSignedCertPassword,
	[string] $certPath, [string] $certPathCer, [string] $SelfSignedCertNoOfMonthsUntilExpired ) {
	$Cert = New-SelfSignedCertificate -DnsName $certificateName -CertStoreLocation cert:\LocalMachine\My -KeyExportPolicy Exportable -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider" -NotAfter (Get-Date).AddMonths($SelfSignedCertNoOfMonthsUntilExpired) -HashAlgorithm SHA256

	Export-PfxCertificate -Cert ("Cert:\localmachine\my\" + $Cert.Thumbprint) -FilePath $certPath -Password $selfSignedCertPassword -Force | Write-Verbose
	Export-Certificate -Cert ("Cert:\localmachine\my\" + $Cert.Thumbprint) -FilePath $certPathCer -Type CERT | Write-Verbose
}

function New-ServicePrincipal([System.Security.Cryptography.X509Certificates.X509Certificate2] $PfxCert, [string] $ApplicationDisplayName) {
	$keyValue = [System.Convert]::ToBase64String($PfxCert.GetRawCertData())
	$keyId = (New-Guid).Guid

	# Create an Azure AD application, AD App Credential, AD ServicePrincipal

	# Requires Application Developer Role, but works with Application administrator or GLOBAL ADMIN
	$Application = New-AzADApplication -DisplayName $ApplicationDisplayName -HomePage ("http://" + $ApplicationDisplayName) -IdentifierUris ("http://" + $keyId)
	# Requires Application administrator or GLOBAL ADMIN
	New-AzADAppCredential -ApplicationId $Application.ApplicationId -CertValue $keyValue -StartDate $PfxCert.NotBefore -EndDate $PfxCert.NotAfter
	# Requires Application administrator or GLOBAL ADMIN
	$ServicePrincipal = New-AzADServicePrincipal -ApplicationId $Application.ApplicationId
	Get-AzADServicePrincipal -ObjectId $ServicePrincipal.Id

	# Sleep here for a few seconds to allow the service principal application to become active (ordinarily takes a few seconds)
	Start-Sleep -Seconds 15
	# Requires User Access Administrator or Owner.
	$NewRole = New-AzRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $Application.ApplicationId -ErrorAction SilentlyContinue
	$Retries = 0;
	While (!$NewRole -and $Retries -le 6) {
		Start-Sleep -Seconds 10
		New-AzRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $Application.ApplicationId | Write-Verbose -ErrorAction SilentlyContinue
		$NewRole = Get-AzRoleAssignment -ServicePrincipalName $Application.ApplicationId -ErrorAction SilentlyContinue
		$Retries++;
	}
	return $Application.ApplicationId.ToString();
}

function New-AutomationCertificateAsset ([string] $ResourceGroupName, [string] $AutomationAccountName, [string] $certifcateAssetName, [string] $certPath, [SecureString] $certPassword, [Boolean] $Exportable) {
	Remove-AzAutomationCertificate -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $certifcateAssetName -ErrorAction SilentlyContinue
	New-AzAutomationCertificate -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Path $certPath -Name $certifcateAssetName -Password $CertPassword -Exportable:$Exportable | write-verbose
}

function New-AutomationConnectionAsset ([string] $ResourceGroupName, [string] $AutomationAccountName, [string] $ConnectionAssetName, [string] $connectionTypeName, [System.Collections.Hashtable] $connectionFieldValues ) {
	Remove-AzAutomationConnection -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $ConnectionAssetName -Force -ErrorAction SilentlyContinue
	New-AzAutomationConnection -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $ConnectionAssetName -ConnectionTypeName $connectionTypeName -ConnectionFieldValues $connectionFieldValues
}

function Get-PasswordCredential {
	[CmdletBinding()]
	[OutputType([PSCustomObject])]
	param()

	$Guid = New-Guid
	$PasswordCredential = New-Object -TypeName Microsoft.Azure.Commands.ActiveDirectory.PSADPasswordCredential
	# this is the same end-date which gets created when you manually create a key with "never expires" in the Azure portal
	$PasswordCredential.StartDate = Get-Date
	$PasswordCredential.EndDate = [datetime]'2299-12-31'
	$PasswordCredential.KeyId = $Guid
	$PasswordCredential.Password = ([System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(($Guid)))) + "="

	return $PasswordCredential
}

Enable-AzureRmAlias

# Create a Run As account by using a service principal
$CertifcateAssetName = "AzureRunAsCertificate"
$ConnectionAssetName = "AzureRunAsConnection"
$ConnectionTypeName = "AzureServicePrincipal"

$CertificateName = $AutomationAccountName + $CertifcateAssetName
$PfxCertPathForRunAsAccount = Join-Path $env:TEMP ($CertificateName + ".pfx")
$SelfSignedCertPlainPassword = (Get-PasswordCredential).Password
$PfxCertPlainPasswordForRunAsAccount = $SelfSignedCertPlainPassword
$CerCertPathForRunAsAccount = Join-Path $env:TEMP ($CertificateName + ".cer")
$PfxCertPasswordForRunAsAccount = ConvertTo-SecureString $PfxCertPlainPasswordForRunAsAccount -AsPlainText -Force
New-CustomSelfSignedCertificate $CertificateName $PfxCertPasswordForRunAsAccount $PfxCertPathForRunAsAccount $CerCertPathForRunAsAccount $SelfSignedCertNoOfMonthsUntilExpired

# Create a service principal
$PfxCert = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList @($PfxCertPathForRunAsAccount, $PfxCertPlainPasswordForRunAsAccount)
$ApplicationId = New-ServicePrincipal $PfxCert $ApplicationDisplayName

# Create the Automation certificate asset
New-AutomationCertificateAsset $ResourceGroupName $AutomationAccountName $CertifcateAssetName $PfxCertPathForRunAsAccount $PfxCertPasswordForRunAsAccount $true

# Populate the ConnectionFieldValues
$SubscriptionInfo = Get-AzSubscription -SubscriptionId $SubscriptionId
$TenantID = $SubscriptionInfo | Select-Object TenantId -First 1
$Thumbprint = $PfxCert.Thumbprint
$ConnectionFieldValues = @{
	'ApplicationId'         = $ApplicationId
	'TenantId'              = $TenantID.TenantId
	'CertificateThumbprint' = $Thumbprint
	'SubscriptionId'        = $SubscriptionId
}

# Create an Automation connection asset named AzureRunAsConnection in the Automation account. This connection uses the service principal.
New-AutomationConnectionAsset $ResourceGroupName $AutomationAccountName $ConnectionAssetName $ConnectionTypeName $ConnectionFieldValues

New-RdsRoleAssignment -RoleDefinitionName 'RDS Contributor' -ApplicationId $ApplicationId -TenantName $TenantName

# Creating Azure logic app to schedule job
# //todo define $HostPoolNames and other params
foreach ($HostPoolName in $HostPoolNames) {

	# Check if the hostpool load balancer type is persistent.
	$HostPoolInfo = Get-RdsHostPool -TenantName $TenantName -Name $HostPoolName

	# //todo confirm with roop
	if ($HostPoolInfo.LoadBalancerType -eq "Persistent") {
		throw "$HostPoolName hostpool configured with Persistent Load balancer. So scale script doesn't apply for this load balancertype. Scale script will execute only with these load balancer types: BreadthFirst, DepthFirst. Please remove this from 'HostpoolName' input and try again"
	}

	$SessionHostsList = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostPoolName

	#Check if the hostpool have session hosts and compare count with minimum number of rdsh value
	if (!$SessionHostsList) {
		Write-Output "Hostpool '$HostPoolName' doesn't have session hosts. Deployment Script will skip the basic scale script configuration for this hostpool."
	}
	elseif ($SessionHostsList.Count -le $MinimumNumberOfRDSH) {
		Write-Output "Hostpool '$HostPoolName' has less than the minimum number of session host required."
		$Confirmation = Read-Host "Do you wish to continue configuring the scale script for these available session hosts? [y/n]"
		if ($Confirmation -eq 'n') {
			Write-Output "Configuring the scale script is skipped for this hostpool '$HostPoolName'."
		}
		else {
			Write-Output "Configuring the scale script for the hostpool : '$HostPoolName' and will keep the minimum required session hosts in running mode."
		}
	}

	[PSCustomObject]$RequestBody = @{
		"LogAnalyticsWorkspaceId"       = $LogAnalyticsWorkspaceId
		"LogAnalyticsPrimaryKey"        = $LogAnalyticsPrimaryKey
		"ConnectionAssetName"           = $ConnectionAssetName
		"AADTenantId"                   = $SubscriptionInfo.TenantId
		"SubscriptionId"                = $SubscriptionId
		"RDBrokerURL"                   = $RDBrokerURL
		"TenantGroupName"               = $TenantGroupName
		"TenantName"                    = $TenantName
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
		"AutomationAccountName"         = $AutomationAccountName
	}
	$RequestBodyJson = $RequestBody | ConvertTo-Json
	$LogicAppName = ($HostPoolName + "_" + "Autoscale" + "_" + "Scheduler").Replace(" ", "")
	
	$SchedulerDeployment = New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateUri "$ScriptRepoLocation/azureLogicAppCreation.json" -LogicAppName $LogicAppName -WebhookURI $WebhookURI.Replace("`n", "").Replace("`r", "") -ActionSettingsBody $RequestBodyJson -RecurrenceInterval $RecurrenceInterval -Verbose

	if ($SchedulerDeployment.ProvisioningState -eq "Succeeded") {
		Write-Output "$HostPoolName hostpool successfully configured with logic app scheduler"
	}
	else {
		throw "Failed to create logic app scheduler. Deployment Provisioning Status: $($SchedulerDeployment.ProvisioningState)"
	}
}