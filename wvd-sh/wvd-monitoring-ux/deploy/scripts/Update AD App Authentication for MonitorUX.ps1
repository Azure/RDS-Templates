<#

.SYNOPSIS
Update an Azure AD App Authentication

.DESCRIPTION
This script is used to update an Azure AD App Authentication

.ROLE
Administrator

#>

Param(

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $AADApplicationId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $RedirectURI

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

$ReplyURL = "$RedirectURI/security/signin-callback"

# Get Azure AD Application
$AADApplication = Get-AzureADApplication -Filter "AppId eq '$($AADApplicationId)'"

$ReplyURLs = $AADApplication.ReplyUrls


# Add Reply URL if not already in the list 

if ($ReplyURLs -NotContains $ReplyURL) {
    $ReplyURLs.Add($ReplyURL)
    Set-AzureADApplication -ObjectId $AADApplication.ObjectId -ReplyUrls $ReplyURLs -PublicCliet $true -Verbose -ErrorAction Stop -
}

Write-Host "Redirect URI is successfully added to AAD Application Authentication"