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
    [string] $AADAppDisplayName

)

# Set the ExecutionPolicy
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine -Force -Confirm:$false

# Importing the modules
Import-Module Azure
Import-Module AzureAD

# Provide the credentials to authenticate to Azure/AzureAD
$Credentials=Get-Credential

#Authenticating to Azure
Login-AzureRmAccount -Credential $Credentials

# Authentcating to AzureAD
Connect-AzureAD -Credential $Credentials

# Check if AD Application exist
$existingApplication = Get-AzureRmADApplication -DisplayName $AADAppDisplayName -ErrorAction SilentlyContinue
if ($existingApplication -ne $null) {
    $appId = $existingApplication.ApplicationId
    Write-Output "An AAD Application already exists with (Application Id: $appId). Choose a different app display name"  -Verbose
    return
}
# Create an application secret
$startDate = Get-Date
$endDate = $startDate.AddYears($script:yearsOfExpiration)
$Guid = New-Guid
$PasswordCredential = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordCredential
$PasswordCredential.StartDate = $startDate
$PasswordCredential.EndDate = $startDate.AddYears(1)
$PasswordCredential.KeyId = $Guid
$PasswordCredential.Value = ([System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(($Guid))))+"="
$ClientSecret=$PasswordCredential.Value

Write-Output "Creating a new Application in AAD" -Verbose

# Create an unique App Registration Name
$date=Get-Date -UFormat %d%m%y
$DisplayName=$AADAppDisplayName+"-"+($date)

# Create a new AD Application
$azureAdApplication=New-AzureADApplication -DisplayName $DisplayName -AvailableToOtherTenants $false -Verbose -ErrorAction Stop

# Create an app creadential to the Application
$SecureClientSecret=ConvertTo-SecureString -String $ClientSecret -AsPlainText -Force
New-AzureRmADAppCredential -ObjectId $azureAdApplication.ObjectId -Password $SecureClientSecret

$ClientId = $azureAdApplication.AppId
Write-Output "Azure AAD Application creation completed successfully (Application Id: $ClientId)" -Verbose

# Create new Service Principal
Write-Output "Creating a new Service Principal" -Verbose
$ServicePrincipal = New-AzureRmADServicePrincipal -ApplicationId $ClientId
$ServicePrincipalName = $ServicePrincipal.ServicePrincipalNames
Write-Output "Service Principal creation completed successfully with $ServicePrincipalName)" -Verbose

# Assign role to Service Principal
Write-Output "Waiting for SPN creation to reflect in Directory before Role assignment"
Start-Sleep 25
Write-Output "Assigning contributor role to Service Principal App ($ClientId)" -Verbose
New-AzureRmRoleAssignment -RoleDefinitionName "contributor" -ServicePrincipalName $ClientId
Write-Output "Service Principal role assignment completed successfully" -Verbose 

# Set windows virtual desktop permission to Client App Registration
$WVDApiPrincipal = Get-AzureADServicePrincipal -SearchString "Windows Virtual Desktop" | Where-Object {$_.DisplayName -eq "Windows Virtual Desktop"}
$AzureWVDApiAccess = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
$AzureWVDApiAccess.ResourceAppId = $WVDApiPrincipal.AppId
foreach($permission in $WVDApiPrincipal.Oauth2Permissions){
    $AzureWVDApiAccess.ResourceAccess += New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList $permission.Id,"Scope"
}
# Set windows virtual desktop permission to Client App Registration
$AzureLogAnalyticsApiPrincipal = Get-AzureADServicePrincipal -SearchString "Log Analytics API"
$AzureLogAnalyticsApiAccess = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
$AzureLogAnalyticsApiAccess.ResourceAppId = $AzureLogAnalyticsApiPrincipal.AppId
foreach($permission in $AzureLogAnalyticsApiPrincipal.Oauth2Permissions){
    $AzureLogAnalyticsApiAccess.ResourceAccess += New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList $permission.Id,"Scope"
}

# Set Microsoft Graph API permission to Client App Registration
$AzureGraphApiPrincipal = Get-AzureADServicePrincipal -SearchString "Microsoft Graph"
$AzureGraphApiAccess = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
$AzureGraphApiAccess.ResourceAppId = $AzureGraphApiPrincipal.AppId
$permission=$AzureGraphApiPrincipal.Oauth2Permissions | Where-Object {$_.Value -eq "User.Read"}
$AzureGraphApiAccess.ResourceAccess += New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList $permission.Id,"Scope"


# Add the WVD API,Log Analytics API and Microsoft Graph API permissions to the ADApplication
Set-AzureADApplication -ObjectId $azureAdApplication.ObjectId -RequiredResourceAccess $AzureLogAnalyticsApiAccess,$AzureWVDApiAccess,$AzureGraphApiAccess -ErrorAction Stop

#Get the Client Id/Application Id and Client Secret
Write-Output "Client Id : $ClientId"
Write-Output "Client Secret Key: $ClientSecret"