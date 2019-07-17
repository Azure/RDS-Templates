﻿<#

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
Import-Module Az
Import-Module AzureAD

# Provide the credentials to authenticate to Azure/AzureAD
$Credentials=Get-Credential

#Authenticating to Azure
Login-AzAccount -Credential $Credentials

# Authentcating to AzureAD
Connect-AzureAD -Credential $Credentials

$ReplyUrl = "$RedirectURI/security/signin-callback"

# Get Azure AD App
$AADApp = Get-AzADApplication -ApplicationId $AADApplicationId

$ReplyUrls = $AADApp.ReplyUrls

# Add Reply URL if not already in the list 

if ($ReplyUrls -NotContains $ReplyUrl) {
    $ReplyUrls.Add($ReplyUrl)

    Set-AzADApplication -ObjectId $AADApp.ObjectId -ReplyUrl $ReplyUrls -AvailableToOtherTenants $true
}

Write-Host "Redirect URI is successfully added to AAD Application Authentication"