<#

.SYNOPSIS
Creating Hostpool.

.DESCRIPTION
The supported Operating Systems Windows Server 2016.

.ROLE
Readers

#>
param(
    [Parameter(mandatory = $true)]
    [string]$RDBrokerURL,

    [Parameter(mandatory = $true)]
    [string]$definedTenantGroupName,

    [Parameter(mandatory = $true)]
    [string]$TenantName,

    [Parameter(mandatory = $true)]
    [string]$HostPoolName,

    [Parameter(mandatory = $true)]
    [string]$Description,

    [Parameter(mandatory = $true)]
    [string]$FriendlyName,

    [Parameter(mandatory = $true)]
    [PSCredential]$TenantAdminCredentials,

    [Parameter(mandatory = $false)]
    [string]$isServicePrincipal = "False",

    [Parameter(mandatory = $false)]
    [AllowEmptyString()]
    [string]$AadTenantId = "",

    [Parameter(mandatory = $false)]
    [string]$EnablePersistentDesktop = "False",

    [Parameter(mandatory = $false)]
    [string]$RDPSModSource = 'attached'
)

$ScriptPath = [System.IO.Path]::GetDirectoryName($PSCommandPath)

# Dot sourcing Functions.ps1 file
. (Join-Path $ScriptPath "Functions.ps1")

# Setting ErrorActionPreference to stop script execution when error occurs
$ErrorActionPreference = "Stop"

write-log -message 'Script being executed: Create Host Pool'

# Testing if it is a ServicePrincipal and validade that AadTenant ID in this case is not null or empty
ValidateServicePrincipal -IsServicePrincipal $isServicePrincipal -AADTenantId $AadTenantId

ImportRDPSMod -Source $RDPSModSource -ArtifactsPath $ScriptPath

# Authenticating to Windows Virtual Desktop
. AuthenticateRdsAccount -DeploymentUrl $RDBrokerURL -Credential $TenantAdminCredentials -ServicePrincipal:($isServicePrincipal -eq 'True') -TenantId $AadTenantId

# Set context to the appropriate tenant group
$currentTenantGroupName = (Get-RdsContext).TenantGroupName
if ($definedTenantGroupName -ne $currentTenantGroupName) {
    Write-Log -Message "Running switching to the $definedTenantGroupName context"
    Set-RdsContext -TenantGroupName $definedTenantGroupName
}
try {
    $tenants = Get-RdsTenant -Name "$TenantName"
    if (!$tenants) {
        Write-Log "No tenants exist or you do not have proper access."
    }
}
catch {
    Write-Log -Message $_
    throw $_
}

# Checking if host pool exists. If not, create a new one with the given HostPoolName
Write-Log -Message "Checking Hostpool exists inside the Tenant"
$HostPool = Get-RdsHostPool -TenantName "$TenantName" -Name "$HostPoolName" -ErrorAction SilentlyContinue
if ($HostPool) {
    Write-Log -Message "Hostpool exists inside tenant: $TenantName"
    return
}

Write-Log -Message "$HostpoolName Hostpool does not exist in $TenantName Tenant"

$HostPool = New-RdsHostPool -TenantName "$TenantName" -Name "$HostPoolName" -Description $Description -FriendlyName $FriendlyName -Persistent:($EnablePersistentDesktop -ieq "true") -ValidationEnv $false
$HName = $HostPool.HostPoolName | Out-String -Stream
Write-Log -Message "Successfully created new Hostpool: $HName"

$ApplicationGroupName = "Desktop Application Group"
Write-Log -Message "Changing Application Group: $ApplicationGroupName FriendlyName to: $HostPoolName"
Set-RdsRemoteDesktop -TenantName $TenantName -HostPoolName $HostPoolName -AppGroupName $ApplicationGroupName -FriendlyName $HostPoolName