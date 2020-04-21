<#

.SYNOPSIS
Removing old hosts from Existing Hostpool.

.DESCRIPTION
This script will Remove/Stop old sessionhost servers from existing Hostpool.
The supported Operating Systems Windows Server 2016/windows 10 multisession.

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
    [pscredential]$TenantAdminCredentials,

    [Parameter(mandatory = $false)]
    [string]$isServicePrincipal = "False",

    [Parameter(mandatory = $false)]
    [AllowEmptyString()]
    [string]$AadTenantId = "",

    [Parameter(mandatory = $true)]
    [string]$DomainName,

    [Parameter(mandatory = $true)]
    [int]$rdshNumberOfInstances,

    [Parameter(mandatory = $true)]
    [string]$rdshPrefix,

    [Parameter(mandatory = $false)]
    [string]$RDPSModSource = 'attached'
)

$ScriptPath = [System.IO.Path]::GetDirectoryName($PSCommandPath)

# Dot sourcing Functions.ps1 file
. (Join-Path $ScriptPath "Functions.ps1")

# Setting ErrorActionPreference to stop script execution when error occurs
$ErrorActionPreference = "Stop"

write-log -message 'Script being executed: Test cleanup old session hosts'

# Testing if it is a ServicePrincipal and validade that AadTenant ID in this case is not null or empty
ValidateServicePrincipal -IsServicePrincipal $isServicePrincipal -AADTenantId $AadTenantId

ImportRDPSMod -Source $RDPSModSource -ArtifactsPath $ScriptPath

# Authenticating to Windows Virtual Desktop
. AuthenticateRdsAccount -DeploymentUrl $RDBrokerURL -Credential $TenantAdminCredentials -ServicePrincipal:($isServicePrincipal -eq 'True') -TenantId $AadTenantId

SetTenantGroupContextAndValidate -TenantGroupName $definedTenantGroupName -TenantName $TenantName

# Checking if host pool exists.
Write-Log -Message "Checking Hostpool exists inside the Tenant"
$HostPool = Get-RdsHostPool -TenantName "$TenantName" -Name "$HostPoolName" -ErrorAction SilentlyContinue
if (!$HostPool) {
    throw "$HostpoolName Hostpool does not exist in $TenantName Tenant"
}

Write-Log -Message "Hostpool exists inside tenant: $TenantName"

# collect new session hosts
$NewSessionHostNames = @{ }
for ($i = 0; $i -lt $rdshNumberOfInstances; ++$i) {
    $NewSessionHostNames.Add("${rdshPrefix}${i}.${DomainName}".ToLower(), $true)
}

Write-Log -Message "New Session Host servers in hostpool $HostPoolName :`n$($NewSessionHostNames.Keys | Out-String)"

$SessionHosts = Get-RdsSessionHost -TenantName "$TenantName" -HostPoolName "$HostPoolName"
$OldSessionHosts = $SessionHosts.SessionHostName | Where-Object { !$NewSessionHostNames.ContainsKey($_.ToLower()) }

Write-Log -Message "Old Session Host servers (if any) in hostpool: $HostPoolName :`n$($OldSessionHosts | Out-String)"

if ($OldSessionHosts) {
    Write-Log -Err "Old Session Hosts exist in hostpool $HostPoolName"
    return $false
}

return $true