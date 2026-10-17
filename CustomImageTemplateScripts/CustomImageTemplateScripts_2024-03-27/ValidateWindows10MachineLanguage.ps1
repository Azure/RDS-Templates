#requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$WorkingDirectory = 'C:\ProgramData\Windows10MachineLanguage',

    [Parameter()]
    [string]$OrchestratorPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$WorkingDirectory = [IO.Path]::GetFullPath($WorkingDirectory)
if ([string]::IsNullOrWhiteSpace($OrchestratorPath)) {
    $OrchestratorPath = Join-Path $WorkingDirectory 'Set-Windows10MachineLanguage.ps1'
}
$OrchestratorPath = [IO.Path]::GetFullPath($OrchestratorPath)

if (-not (Test-Path -LiteralPath $OrchestratorPath -PathType Leaf)) {
    throw "The staged Windows 10 language orchestrator was not found at '$OrchestratorPath'."
}

$statePath = Join-Path $WorkingDirectory 'state.json'
if (-not (Test-Path -LiteralPath $statePath -PathType Leaf)) {
    throw "The durable language-install state was not found at '$statePath'."
}

$state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
foreach ($requiredProperty in @('Phase', 'WorkingDirectory', 'OrchestratorSha256', 'CopyHelperSha256')) {
    if (
        $state.PSObject.Properties.Name -notcontains $requiredProperty -or
        [string]::IsNullOrWhiteSpace([string]$state.$requiredProperty)
    ) {
        throw "The durable language-install state is missing required property '$requiredProperty'."
    }
}
if ([string]$state.Phase -ne 'PostLanguageRestart') {
    throw "Final validation requires durable state 'PostLanguageRestart', found '$($state.Phase)'."
}
if ([IO.Path]::GetFullPath([string]$state.WorkingDirectory) -ne $WorkingDirectory) {
    throw 'The requested working directory does not match the directory pinned in durable state.'
}

$orchestratorHash = (Get-FileHash -LiteralPath $OrchestratorPath -Algorithm SHA256).Hash
if ($orchestratorHash -cne [string]$state.OrchestratorSha256) {
    throw 'The staged Windows 10 language orchestrator failed its durable SHA-256 integrity check.'
}
$copyHelperPath = Join-Path $WorkingDirectory 'Copy-UserInternationalSettingsToSystemCompat.ps1'
if (-not (Test-Path -LiteralPath $copyHelperPath -PathType Leaf)) {
    throw "The staged Default User compatibility helper was not found at '$copyHelperPath'."
}
$copyHelperHash = (Get-FileHash -LiteralPath $copyHelperPath -Algorithm SHA256).Hash
if ($copyHelperHash -cne [string]$state.CopyHelperSha256) {
    throw 'The staged Default User compatibility helper failed its durable SHA-256 integrity check.'
}

& $OrchestratorPath `
    -Resume `
    -AibPhase Validate `
    -WorkingDirectory $WorkingDirectory
