<#
.SYNOPSIS
Update the main bundle js file with API URL
.DESCRIPTION
This script is used to Update the main bundle js file of web application with API URL.
This script depends on two PowerShell modules: Az and AzureAD . To install Az and AzureAD modules execute the following commands. Use "-AllowClobber" parameter if you have more than one version of PowerShell modules installed.
	PS C:\>Install-Module Az  -AllowClobber
    PS C:\>Install-Module AzureAD  -AllowClobber

.ROLE
Administrator

.PARAMETER AppName
 Required
 Provide name of the web application which you have used to deploy webapp through ARM Template.

.PARAMETER AzureSubscriptionId
 Required
 Provide Subscription Id of the Azure.

 Example: .\updateWvdMgmtUxApiUrl.ps1  -AppName "Name of the Application" -AzureSubscriptionID "Your Azure SubscriptionID"
#>

param(

	[Parameter(Mandatory = $true)]
	[ValidateNotNullOrEmpty()]
	[string]$AppName,

	[Parameter(Mandatory = $true)]
	[ValidateNotNullOrEmpty()]
	[string]$AzureSubscriptionId

)

# Set the ExecutionPolicy
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine -Force -Confirm:$false

# Import Az and AzureAD modules
Import-Module Az
Import-Module AzureAD


# Function to get the publishing profile credentials
function Get-PublishingProfileCredentials ($resourceGroupName,$AppName) {

	$resourceType = "Microsoft.Web/sites/config"
	$resourceName = "$AppName/publishingcredentials"

	$publishingCredentials = Invoke-AzResourceAction -ResourceGroupName $resourceGroupName -ResourceType $resourceType -ResourceName $resourceName -Action list -ApiVersion 2015-08-01 -Force

	return $publishingCredentials
}
# Function to get kudu api Authorisation Header Value
function Get-KuduApiAuthorisationHeaderValue ($resourceGroupName,$AppName) {

	$publishingCredentials = Get-PublishingProfileCredentials $resourceGroupName $AppName

	return ("Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $publishingCredentials.Properties.PublishingUserName,$publishingCredentials.Properties.PublishingPassword))))
}


# Get the context
$context = Get-AzContext
if ($context -eq $null)
{
	Write-Error "Please authenticate to Azure & Azure AD using Login-AzAccount and Connect-AzureAD cmdlets and then run this script"
	exit
}

# Select the subscription
Select-AzSubscription -SubscriptionId $AzureSubscriptionId

# Get the Role Assignment of the authenticated user
$RoleAssignment = Get-AzRoleAssignment -SignInName $context.Account

# Validate whether the authenticated user having the Owner or Contributor role
if ($RoleAssignment.RoleDefinitionName -eq "Owner" -or $RoleAssignment.RoleDefinitionName -eq "Contributor")
{

	$ListWebApp = Get-AzWebApp | Where-Object { $_.Name -eq $AppName }
	$resourceGroupName = $ListWebApp.ResourceGroup

	$kuduApiAuthorisationToken = Get-KuduApiAuthorisationHeaderValue $resourceGroupName $AppName


	$ApiUrl = "https://$AppName-api.azurewebsites.net"
	$kuduApiUrl = "https://$AppName.scm.azurewebsites.net/api/vfs/site/wwwroot/"
	[array]$AllPublishedFiles = Invoke-RestMethod -Uri $kuduApiUrl `
 		-Headers @{ "Authorization" = $kuduApiAuthorisationToken; "If-Match" = "*" } `
 		-Method GET `
 		-ContentType "multipart/form-data"
	if (!($AllPublishedFiles.href -like "*/main*")) {
		Write-Error "main.bundle.js file doesn't exist in web app file system"
		exit
	}
	foreach ($Publishedfile in $AllPublishedFiles) {
		if ($Publishedfile.href -like "*/main*") {
			$MainBundleJsonURL = $Publishedfile.href
			$MainBundleJsonFileName = Split-Path $MainBundleJsonURL -Leaf
			$ListkuduApiUrl = "https://$AppName.scm.azurewebsites.net/api/vfs/site/wwwroot/$MainBundleJsonFileName"
			$MainBundleJsonFile = Invoke-RestMethod -Uri $ListkuduApiUrl `
 				-Headers @{ "Authorization" = $kuduApiAuthorisationToken; "If-Match" = "*" } `
 				-Method GET `
 				-ContentType "multipart/form-data"

			$LocalPath = [environment]::GetEnvironmentVariable('TEMP','Machine')
			New-Item -Path $LocalPath -Name $MainBundleJsonFileName -Value $MainBundleJsonFile
			# Change the Url in the main.bundle.js file with the ApiURL
			Write-Output "Updating the Url in main.bundle.js file with Api-app Url"
			(Get-Content "$LocalPath\$MainBundleJsonFileName").Replace("[api_url]",$ApiUrl + "/") | Out-File "$LocalPath\$MainBundleJsonFileName"

			$kuduApiUrlUpdate = "https://$AppName.scm.azurewebsites.net/api/vfs/site/wwwroot/$MainBundleJsonFileName"
			$result = Invoke-RestMethod -Uri $kuduApiUrlUpdate `
 				-Headers @{ "Authorization" = $kuduApiAuthorisationToken; "If-Match" = "*" } `
 				-Method PUT `
 				-InFile "$LocalPath\$MainBundleJsonFileName" `
 				-ContentType "multipart/form-data"

			Write-Output "$MainBundleJsonFileName has been updated with API URL successfully..."

			if (Test-Path -Path "$LocalPath\$MainBundleJsonFileName") {
				Remove-Item -Path "$LocalPath\$MainBundleJsonFileName" -Force
			}
		}

	}
}
else {
	Write-Output "Authenticated user should have the Owner/Contributor permissions"
}
