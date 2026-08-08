<#

.SYNOPSIS
Verify a VM is setup correctly and registered to existing/new host pool.

.DESCRIPTION
This script verifies RD agent installed and the VM is registered successfully as session host to existing/new host pool.

#>
param(
    [Parameter(mandatory = $true)]
    [string]$HostPoolName
)

$ScriptPath = [system.io.path]::GetDirectoryName($PSCommandPath)

# Dot sourcing Functions.ps1 file
. (Join-Path $ScriptPath "Functions.ps1")
. (Join-Path $ScriptPath "AvdFunctions.ps1")

Write-Log -Message "Check if RD Infra registry exists"
$RegistryCheckObj = IsRDAgentRegistryValidForRegistration
if (!$RegistryCheckObj.result) {
    Write-Log -Err "RD agent registry check failed ($($RegistryCheckObj.msg))"
    return $false;
}

$SessionHostName = GetAvdSessionHostName
Write-Log -Message "SessionHost '$SessionHostName' is registered. $($SessionHost | Out-String)"
return $true;