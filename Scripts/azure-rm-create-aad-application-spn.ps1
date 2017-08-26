<#
    creates new azurermadapplication for use with logging in to azurerm using password or cert
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

    # can be used with scripts for example
    # cert auth. put in ps script
    # Add-AzureRmAccount -ServicePrincipal -CertificateThumbprint $cert.Thumbprint -ApplicationId $app.ApplicationId -TenantId $tenantId
    # requires free AAD base subscription
    # https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-authenticate-service-principal#provide-credentials-through-automated-powershell-script

    # 170609
#>
param(
    [bool]$usecert = $true,
    [string]$password,
    [Parameter(Mandatory=$true)]
    [string]$aadDisplayName,
    [string]$uri,
    [switch]$list
)

# ----------------------------------------------------------------------------------------------------------------
function main()
{
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

    if (!$uri)
    {
        $uri = "https://$($env:Computername)/$($aadDisplayName)"
    }

    $tenantId = (Get-AzureRmSubscription).TenantId

    if ((Get-AzureRmADApplication -DisplayNameStartWith $aadDisplayName))
    {
        $app = Get-AzureRmADApplication -DisplayNameStartWith $aadDisplayName

        if ((read-host "AAD application exists: $($aadDisplayName). Do you want to delete?[y|n]") -imatch "y")
        {
            remove-AzureRmADApplication -objectId $app.objectId -Force
        
            $id = Get-AzureRmADServicePrincipal -SearchString $aadDisplayName
        
            if (@($id).Count -eq 1)
            {
                Remove-AzureRmADServicePrincipal -ObjectId $id
            }
        }
    }
    elseif (!$list)
    {
        if ($usecert)
        {
            if (!$password)
            {
                $password = (Get-Credential).Password
            }

            $cert = New-SelfSignedCertificate -CertStoreLocation "cert:\CurrentUser\My" -Subject "CN=$($aadDisplayName)" -KeySpec KeyExchange
            $keyValue = [System.Convert]::ToBase64String($cert.GetRawCertData())
            $app = New-AzureRmADApplication -DisplayName $aadDisplayName -HomePage $uri -IdentifierUris $uri -CertValue $keyValue -EndDate $cert.NotAfter -StartDate $cert.NotBefore
        }
        else
        {
            # to use password
            $app = New-AzureRmADApplication -DisplayName $aadDisplayName -HomePage $uri -IdentifierUris $uri -Password $password
        }

        New-AzureRmADServicePrincipal -ApplicationId $app.ApplicationId
        Start-Sleep 15
        New-AzureRmRoleAssignment -RoleDefinitionName Reader -ServicePrincipalName $app.ApplicationId
        New-AzureRmRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $app.ApplicationId

        if ($usecert)
        {
            write-host "for use in script: Add-AzureRmAccount -ServicePrincipal -CertificateThumbprint $($cert.Thumbprint) -ApplicationId $($app.ApplicationId) -TenantId $($tenantId)"
            write-host "certificate thumbprint: $($cert.Thumbprint)"
            
        }
    } # else

    write-host "application id: $($app.ApplicationId)"
    write-host "tenant id: $($tenantId)"
    write-hsot "application identifier Uri: $($uri)"
}
# ----------------------------------------------------------------------------------------------------------------

main