﻿<#
    script to add certificate to azure arm AAD key vault
    to enable script execution, you may need to Set-ExecutionPolicy Bypass -Force

    Copyright 2017 Microsoft Corporation

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    # Note: Certificates stored in Key Vault as secrets with content type 'application/x-pkcs12', this is why Set-AzureRmKeyVaultAccessPolivy cmdlet grants -PremissionsToSecrets (rather than -PermissionsToCertificates).
    # You will need 1) application id ($app.ApplicationId), and 2) the password from above step supplied as input parameters to the Template.
    # https://www.sslforfree.com/
    # 170825
#>

[cmdletbinding()]
param(
$pfxFilePath, # existing pfx file and path
$certPassword,           # password that was used to secure the pfx file at the time of export 
$certNameInVault,    # cert name in vault, has to be '^[0-9a-zA-Z-]+$' pattern (digits, letters or dashes only, no spaces)
$vaultName, # has to be unique?
$resourceGroup,
$uri,   #  a valid formatted URL, not validated for single-tenant deployments used for identification
$adApplicationName
)

# authenticate
try
{
    Get-AzureRmResourceGroup | Out-Null
}
catch
{
    try
    {
        Add-AzureRmAccount
    }
    catch [System.Management.Automation.CommandNotFoundException]
    {
        write-host "installing azurerm sdk. this will take a while..."
        install-module azurerm
        import-module azurerm
        Add-AzureRmAccount
    }
}


if(!(Get-AzureRmResourceGroup -Name $resourceGroup))
{
    New-AzureRmResourceGroup -Name $resourceGroup -location eastus
}
    
if(!(Get-AzureRmKeyVault -VaultName $vaultName -ResourceGroupName $resourceGroup))
{
    New-AzureRmKeyVault -VaultName $vaultName -ResourceGroupName $resourceGroup -Location eastus
}

if(Get-AzureKeyVaultCertificate -vaultname $vaultName -name $certNameInVault)
{
    write-host "removing old cert from existing vault."
    remove-AzureKeyVaultCertificate -vaultname $vaultName -name $certNameInVault -Force
}

Import-AzureKeyVaultCertificate -vaultname $vaultName -name $certNameInVault -filepath $pfxFilePath -password ($certPassword | convertto-securestring -asplaintext -force)

if($oldapp = Get-AzureRmADApplication -IdentifierUri $uri -ErrorAction SilentlyContinue)
{
    Remove-AzureRmADApplication -ObjectId $oldapp.ObjectId -Force

    if($sp = get-AzureRmADServicePrincipal -ServicePrincipalName $oldapp.applicationid)
    {
        Remove-AzureRmADServicePrincipal -ObjectId $sp.ObjectId -Force
    }
}

$app = New-AzureRmADApplication -DisplayName $adApplicationName -HomePage $uri -IdentifierUris $uri -password $certPassword
$sp = New-AzureRmADServicePrincipal -ApplicationId $app.ApplicationId

Set-AzureRmKeyVaultAccessPolicy -vaultname $vaultName -serviceprincipalname $sp.ApplicationId -permissionstosecrets get
$tenantId = (Get-AzureRmSubscription).TenantId | Select-Object -Unique

write-output "application id: $($app.ApplicationId)"
write-output "tenant id: $($tenantId)"

