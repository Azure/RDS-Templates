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

# Get the context
$context= Get-AzContext
if($context -eq $null)
{
  Write-Error "Please authenticate to Azure & Azure AD using Login-AzAccount and Connect-AzureAD cmdlets and then run this script"
  exit
}

# Select the specified subscription
Select-AzSubscription -SubscriptionId $SubscriptionId

if($RoleAssignment.RoleDefinitionName -eq "Owner" -or $RoleAssignment.RoleDefinitionName -eq "Contributor")
{
# Get the web app URLs list
$Hostnames=(Get-AzWebApp).DefaultHostName
$URL = $RedirectURI.Trim("https://")

# check the RedirectURI exist in the web app URLs list
if($Hostnames -match $URL)
{
$ReplyUrl = "$RedirectURI/security/signin-callback"

#Check if the user is authenticated AzureAD
$ListAllADApps = Get-AzADApplication
if($ListAllADApps -eq $null){
		Write-Error "You must call the Connect-AzureAD cmdlet before calling any other cmdlets"
        exit
}

# Get Azure AD App
$AADApp = Get-AzADApplication -ApplicationId $ClientId


$ReplyUrls = $AADApp.ReplyUrls

# Add Reply URL if not already in the list 

if ($ReplyUrls -NotContains $ReplyUrl) {
    $ReplyUrls.Add($ReplyUrl)

    Set-AzADApplication -ObjectId $AADApp.ObjectId -ReplyUrl $ReplyUrls 
}

Write-Output "Redirect URI is successfully added to AAD Application Authentication"
}
else
{
Write-Output "Please provide the valid RedirectURI"
}
}
else
{
Write-Output "Authenticated user should have the Owner/Contributor permissions"
}
