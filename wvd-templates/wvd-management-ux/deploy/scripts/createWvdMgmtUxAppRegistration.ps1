<#
.SYNOPSIS
Create an Azure AD App Registration
.DESCRIPTION
This script is used to create an Azure AD App Registration
This script depends on two PowerShell modules: Az and AzureAD . To install Az and AzureAD modules execute the following commands. Use "-AllowClobber" parameter if you have more than one version of PowerShell modules installed.
	PS C:\>Install-Module Az  -AllowClobber
    PS C:\>Install-Module AzureAD  -AllowClobber

.ROLE
Administrator

.PARAMETER AppName
 Required
 Provide name of the application name, enter a unique app name.

.PARAMETER AzureSubscriptionId
 Required
 Provide Subscription Id of the Azure.

 Example: .\createWvdMgmtUxAppRegistration.ps1  -AppName "Name of the Application" -AzureSubscriptionID "Your Azure SubscriptionID"
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
	# Check whether the AD Application exist/ not
	$existingApplication = Get-AzADApplication -DisplayName $AppName -ErrorAction SilentlyContinue
	if ($existingApplication -ne $null)
	{
		$appId = $existingApplication.ApplicationId
		Write-Output "An AAD Application already exists with AppName $AppName(Application Id: $appId). Choose a different AppName" -Verbose
		exit
	}

	try
	{
		# Create a new AD Application with provided AppName
		$azAdApplication = New-AzureADApplication -DisplayName $AppName -PublicClient $false -AvailableToOtherTenants $false
	}
	catch
	{
		Write-Error "You must call the Connect-AzureAD cmdlet before calling any other cmdlets"
		exit
	}

	# Create a Client Secret
	$StartDate = Get-Date
	$EndDate = $StartDate.AddYears(280)
	$Guid = New-Guid
	$PasswordCredential = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordCredential
	$PasswordCredential.StartDate = $StartDate
	$PasswordCredential.EndDate = $EndDate
	$PasswordCredential.KeyId = $Guid
	$PasswordCredential.Value = ([System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(($Guid)))) + "="
	$ClientSecret = $PasswordCredential.Value

	Write-Output "Creating a new Application in AAD" -Verbose

	# Create an app credential to the Application
	$SecureClientSecret = ConvertTo-SecureString -String $ClientSecret -AsPlainText -Force
	New-AzADAppCredential -ObjectId $azAdApplication.ObjectId -Password $SecureClientSecret -StartDate $StartDate -EndDate $EndDate

	# Get the ClientId
	$ClientId = $azAdApplication.AppId
	Write-Output "Azure AAD Application creation completed successfully with AppName $AppName (Application Id is: $ClientId)" -Verbose

	# Create new Service Principal
	Write-Output "Creating a new Service Principal" -Verbose
	$ServicePrincipal = New-AzADServicePrincipal -ApplicationId $ClientId

	# Get the Service Principal
	Get-AzADServicePrincipal -ApplicationId $ClientId
	$ServicePrincipalName = $ServicePrincipal.ServicePrincipalNames
	Write-Output "Service Principal creation completed successfully with $ServicePrincipalName)" -Verbose

	#Collecting WVD Serviceprincipal Api Permission and set to client app registration
	$WVDServPrincipalApi = Get-AzADServicePrincipal -ApplicationId "5a0aa725-4958-4b0c-80a9-34562e23f3b7"
	$WVDServicePrincipal = Get-AzureADServicePrincipal -ObjectId $WVDServPrincipalApi.Id
	$AzureAdResouceAcessObject = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
	$AzureAdResouceAcessObject.ResourceAppId = $WVDServicePrincipal.AppId
	foreach ($permission in $WVDServicePrincipal.Oauth2Permissions) {
		$AzureAdResouceAcessObject.ResourceAccess += New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList $permission.Id,"Scope"
	}
	#Collecting AzureService Management Api permission and set to client app registration
	$AzureServMgmtApi = Get-AzADServicePrincipal -ApplicationId "797f4846-ba00-4fd7-ba43-dac1f8f63013"
	$AzureAdServMgmtApi = Get-AzureADServicePrincipal -ObjectId $AzureServMgmtApi.Id
	$AzureServMgmtApiResouceAcessObject = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
	$AzureServMgmtApiResouceAcessObject.ResourceAppId = $AzureAdServMgmtApi.AppId
	foreach ($SerVMgmtAPipermission in $AzureAdServMgmtApi.Oauth2Permissions) {
		$AzureServMgmtApiResouceAcessObject.ResourceAccess += New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList $SerVMgmtAPipermission.Id,"Scope"
	}

	# Set Microsoft Graph API permission to Client App Registration
	$MsftGraphApi = Get-AzADServicePrincipal -ApplicationId "00000003-0000-0000-c000-000000000000"
	$AzureGraphApiPrincipal = Get-AzureADServicePrincipal -ObjectId $MsftGraphApi.Id
	$AzureGraphApiAccessObject = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
	$AzureGraphApiAccessObject.ResourceAppId = $AzureGraphApiPrincipal.AppId
	$permission = $AzureGraphApiPrincipal.Oauth2Permissions | Where-Object { $_.Value -eq "User.Read" }
	$AzureGraphApiAccessObject.ResourceAccess = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList $permission.Id,"Scope"


	# Add the WVD API,Log Analytics API and Microsoft Graph API permissions to the ADApplication
	Set-AzureADApplication -ObjectId $azAdApplication.ObjectId -RequiredResourceAccess $AzureAdResouceAcessObject,$AzureServMgmtApiResouceAcessObject,$AzureGraphApiAccessObject -ErrorAction Stop

	# Get the Client Id/Application Id and Client Secret
	Write-Output "Client Id : $ClientId"
	Write-Output "Client Secret Key: $ClientSecret"
}
else
{
	Write-Output "Authenticated user should have the Owner/Contributor permissions"
}
