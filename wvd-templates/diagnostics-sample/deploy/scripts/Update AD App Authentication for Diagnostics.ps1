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
    [string] $ClientId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $RedirectURI,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $SubscriptionId

)

# Set the ExecutionPolicy
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine -Force -Confirm:$false

# Import Az an AzureAD modules
Import-Module Az
Import-Module AzureAD

# Provide the Azure credentials to authenticate to Azure and AzureAD
$Credentials=Get-Credential

#Authenticating to Azure
Login-AzAccount -Credential $Credentials

# Authentcating to AzureAD
Connect-AzureAD -Credential $Credentials

# Select the specified subscription
Select-AzSubscription -SubscriptionId $SubscriptionId

# Get the web app URLs list
$Hostnames=(Get-AzWebApp).DefaultHostName
$URL = $RedirectURI.Trim("https://")

# check the RedirectURI exist in the web app URLs list
if($Hostnames -match $URL)
{
$ReplyUrl = "$RedirectURI/security/signin-callback"

# Get Azure AD App
$AADApp = Get-AzADApplication -ApplicationId $ClientId

$ReplyUrls = $AADApp.ReplyUrls

# Add Reply URL if not already in the list 

if ($ReplyUrls -NotContains $ReplyUrl) {
    $ReplyUrls.Add($ReplyUrl)

    Set-AzADApplication -ObjectId $AADApp.ObjectId -ReplyUrl $ReplyUrls -AvailableToOtherTenants $true
}

Write-Output "Redirect URI is successfully added to AAD Application Authentication"
}
else
{
Write-Output "Please provide the valid RedirectURI"
}
