<#

.SYNOPSIS
Test if Session Host was registered to the Host Pool.

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
    [PSCredential]$TenantAdminCredentials,

    [Parameter(mandatory = $false)]
    [string]$isServicePrincipal = "False",

    [Parameter(mandatory = $false)]
    [AllowEmptyString()]
    [string]$AadTenantId = "",

    [Parameter(mandatory = $false)]
    [string]$RDPSModSource = 'attached'
)

$ScriptPath = [System.IO.Path]::GetDirectoryName($PSCommandPath)

# Dot sourcing Functions.ps1 file
. (Join-Path $ScriptPath "Functions.ps1")

# Setting ErrorActionPreference to stop script execution when error occurs
$ErrorActionPreference = "Stop"

write-log -message 'Script being executed: Test if Session Host is registered to the Host Pool'

Write-Log -Message "Check if RD Infra registry exists"
$RegistryCheckObj = IsRDAgentRegistryValidForRegistration
if (!$RegistryCheckObj.result) {
    Write-Log -Err "Session Host is not registered to the Host Pool ($($RegistryCheckObj.msg))"
    return $false
}

Write-Log -Message "Accoring to RD Infra registry, RD Agent appears to be registered"

# Testing if it is a ServicePrincipal and validade that AadTenant ID in this case is not null or empty
ValidateServicePrincipal -IsServicePrincipal $isServicePrincipal -AADTenantId $AadTenantId

ImportRDPSMod -Source $RDPSModSource -ArtifactsPath $ScriptPath

# Authenticating to Windows Virtual Desktop
. AuthenticateRdsAccount -DeploymentUrl $RDBrokerURL -Credential $TenantAdminCredentials -ServicePrincipal:($isServicePrincipal -eq 'True') -TenantId $AadTenantId

SetTenantGroupContextAndValidate -TenantGroupName $definedTenantGroupName -TenantName $TenantName

# Getting fqdn of rdsh vm
$SessionHostName = GetCurrSessionHostName
Write-Log -Message "Fully qualified domain name of RDSH VM: $SessionHostName"

$SessionHost = Get-RdsSessionHost -TenantName "$TenantName" -HostPoolName "$HostPoolName" -Name "$SessionHostName" -ErrorAction SilentlyContinue
Write-Log -Message "Check if SessionHost '$SessionHostName' is registered to Host Pool '$HostPoolName' in Tenant '$TenantName'"
if (!$SessionHost) {
    Write-Log -Err "SessionHost '$SessionHostName' does not exist in Host Pool '$HostPoolName' in Tenant '$TenantName'"
    return $false
}
$DesiredStates = GetSessionHostDesiredStates
if ($SessionHost.Status -notin $DesiredStates) {
    Write-Log -Err "SessionHost '$SessionHostName' is in '$($SessionHost.Status)' state but not in any of the desired states: $($DesiredStates -join ', ')"
    return $false
}

Write-Log -Message "SessionHost '$SessionHostName' is registered. $($SessionHost | Out-String)"

return $true