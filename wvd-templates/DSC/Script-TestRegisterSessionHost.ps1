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
$RDInfraReg = Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent" -ErrorAction SilentlyContinue
if (!$RDInfraReg) {
    Write-Log -Error "Session Host is not registered to the Host Pool (RD Infra registry missing)"
    return $false
}
Write-Log -Message "RD Infra registry exists"

Write-Log -Message "Check RD Infra registry to see if RD Agent is registered"
if ($RDInfraReg.RegistrationToken -ne '') {
    Write-Log -Error "Session Host is not registered to the Host Pool (RegistrationToken in RD Infra registry is not empty: '$($RDInfraReg.RegistrationToken)')"
    return $false
}
if ($RDInfraReg.IsRegistered -ne 1) {
    Write-Log -Error "Session Host is not registered to the Host Pool (Value of 'IsRegistered' in RD Infra registry is not 1: $($RDInfraReg.IsRegistered))"
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
    Write-Log -Error "SessionHost '$SessionHostName' does not exist in Host Pool '$HostPoolName' in Tenant '$TenantName'"
    return $false
}
if ($SessionHost.Status -ne 'Available') {
    Write-Log -Error "SessionHost '$SessionHostName' is not available. $($SessionHost | Out-String)"
    return $false
}

Write-Log -Message "SessionHost '$SessionHostName' is registered. $($SessionHost | Out-String)"

return $true