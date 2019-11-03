<#

.SYNOPSIS
Create an Azure AD App Registration

.DESCRIPTION
This script is used to create an Azure AD App Registration

.ROLE
Administrator

#>

Param(

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $AppName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $SubscriptionId

)

# Set the ExecutionPolicy
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force -Confirm:$false

# Import Az and AzureAD modules
Import-Module Az
Import-Module AzureAD

# Get the context
$context= Get-AzContext
if($context -eq $null)
{
  Write-Error "Please authenticate to Azure & Azure AD using Login-AzAccount and Connect-AzureAD cmdlets and then run this script"
  exit
}

# Select the subscription
$Subscription = Select-AzSubscription -SubscriptionId $SubscriptionId
Set-AzContext -SubscriptionObject $Subscription.ExtendedProperties

# Get the Role Assignment of the authenticated user
$RoleAssignment = Get-AzRoleAssignment -SignInName $context.Account

# Validate whether the authenticated user having the Owner or Contributor role
if($RoleAssignment.RoleDefinitionName -eq "Owner" -or $RoleAssignment.RoleDefinitionName -eq "Contributor")
{
    # Check whether the AD Application exist/ not
    $existingApplication = Get-AzADApplication -DisplayName $AppName -ErrorAction SilentlyContinue
    if ($existingApplication -ne $null) 
    {
        $appId = $existingApplication.ApplicationId
        Write-Output "An AAD Application already exists with AppName $AppName(Application Id: $appId). Choose a different AppName"  -Verbose
        exit
    }

    Try
    {
        # Create a new AD Application with provided AppName
        $azAdApplication=New-AzureADApplication -DisplayName $AppName -PublicClient $false -AvailableToOtherTenants $false 
    }
    catch
    {
        Write-Error "You must call the Connect-AzureAD cmdlet before calling any other cmdlets"
        exit
    }

    # Create a Client Secret
    $startDate = Get-Date
    $endDate = $startDate.AddYears(1)
    $Guid = New-Guid
    $PasswordCredential = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordCredential
    $PasswordCredential.StartDate = $startDate
    $PasswordCredential.EndDate = $startDate.AddYears(1)
    $PasswordCredential.KeyId = $Guid
    $PasswordCredential.Value = ([System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(($Guid))))+"="
    $ClientSecret=$PasswordCredential.Value

    Write-Output "Creating a new Application in AAD" -Verbose

    # Create an app credential to the Application
    $SecureClientSecret=ConvertTo-SecureString -String $ClientSecret -AsPlainText -Force
    New-AzADAppCredential -ObjectId $azAdApplication.ObjectId -Password $SecureClientSecret -StartDate $startDate -EndDate $startDate.AddYears(1)

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

    # Set windows virtual desktop permission to Client App Registration
    $WVDApiPrincipal = Get-AzureADServicePrincipal -SearchString "Windows Virtual Desktop" | Where-Object {$_.DisplayName -eq "Windows Virtual Desktop"}
    $AzureWVDApiAccess = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
    $AzureWVDApiAccess.ResourceAppId = $WVDApiPrincipal.AppId
    foreach($permission in $WVDApiPrincipal.Oauth2Permissions)
    {
        $AzureWVDApiAccess.ResourceAccess += New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList $permission.Id,"Scope"
    }
    # Set windows virtual desktop permission to Client App Registration
    $AzureLogAnalyticsApiPrincipal = Get-AzureADServicePrincipal -SearchString "Log Analytics API"
    $AzureLogAnalyticsApiAccess = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
    $AzureLogAnalyticsApiAccess.ResourceAppId = $AzureLogAnalyticsApiPrincipal.AppId
    foreach($permission in $AzureLogAnalyticsApiPrincipal.Oauth2Permissions)
    {
        $AzureLogAnalyticsApiAccess.ResourceAccess += New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList $permission.Id,"Scope"
    }

    # Set Microsoft Graph API permission to Client App Registration
    $AzureGraphApiPrincipal = Get-AzureADServicePrincipal -SearchString "Microsoft Graph"
    $AzureGraphApiAccess = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
    $AzureGraphApiAccess.ResourceAppId = $AzureGraphApiPrincipal.AppId
    $permission = $AzureGraphApiPrincipal.Oauth2Permissions | Where-Object {$_.Value -eq "User.Read"}
    $AzureGraphApiAccess.ResourceAccess += New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList $permission.Id,"Scope"

    # Add the WVD API,Log Analytics API and Microsoft Graph API permissions to the ADApplication
    Set-AzureADApplication -ObjectId $azAdApplication.ObjectId -RequiredResourceAccess $AzureLogAnalyticsApiAccess,$AzureWVDApiAccess,$AzureGraphApiAccess -ErrorAction Stop

    # Get the Client Id/Application Id and Client Secret
    Write-Output "Client Id : $ClientId"
    Write-Output "Client Secret Key: $ClientSecret"
}
else
{
   Write-Output "Authenticated user should have the Owner/Contributor permissions"
}
