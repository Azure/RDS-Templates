[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$windows10WorkingDirectory = 'C:\ProgramData\Windows10MachineLanguage'
$windows10OrchestratorPath = Join-Path $windows10WorkingDirectory 'Set-Windows10MachineLanguage.ps1'
$windows10CopyHelperPath = Join-Path $windows10WorkingDirectory 'Copy-UserInternationalSettingsToSystemCompat.ps1'
$windows10OrchestratorSha256 = '3E30467BEDD23E8A81AEAD21D2C97C0AC50E5243813FAB463DCBFDA9B74C7D47'
$windows10CopyHelperSha256 = '627BA579956AF437B2A865A99F4CCFBD8DEF7B6DCEBB2A14AA9CDA88ECBEC250'

if (-not (Test-Path -LiteralPath $windows10OrchestratorPath -PathType Leaf)) {
    throw "Windows 10 language servicing state was not staged by InstallLanguagePacks.ps1."
}
if (-not (Test-Path -LiteralPath $windows10CopyHelperPath -PathType Leaf)) {
    throw "Windows 10 international-settings support was not staged by InstallLanguagePacks.ps1."
}
$actualOrchestratorSha256 = (Get-FileHash -LiteralPath $windows10OrchestratorPath -Algorithm SHA256).Hash
if ($actualOrchestratorSha256 -ne $windows10OrchestratorSha256) {
    throw 'The staged Windows 10 language orchestrator failed integrity validation before LCU resume.'
}
$actualCopyHelperSha256 = (Get-FileHash -LiteralPath $windows10CopyHelperPath -Algorithm SHA256).Hash
if ($actualCopyHelperSha256 -ne $windows10CopyHelperSha256) {
    throw 'The staged Windows 10 international-settings helper failed integrity validation before LCU resume.'
}

& $windows10OrchestratorPath `
    -Resume `
    -AibPhase InstallLcu `
    -WorkingDirectory $windows10WorkingDirectory
