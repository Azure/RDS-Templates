<#
.SYNOPSIS
Runs the Windows 10 language workflow as Azure Image Builder SYSTEM customizers.

.DESCRIPTION
Invoke this script in three PowerShell customizers with an Azure Image Builder
Windows Restart customizer after InstallAndService and ApplyMachineLanguage.
The script delegates all servicing and validation to
Set-Windows10MachineLanguage.ps1 and never initiates a restart itself. Before
returning from a phase that requires restart, the orchestrator arms a local
startup guard that keeps the AIB WinRM communicator unavailable until Windows
servicing is continuously stable.

.EXAMPLE
.\Invoke-Windows10MachineLanguageAib.ps1 -Phase InstallAndService `
    -LanguageTag fr-FR -DownloadLanguagePack -UseWindowsUpdate -RequireRdp

.EXAMPLE
.\Invoke-Windows10MachineLanguageAib.ps1 -Phase InstallAndService `
    -LanguageTag de-DE `
    -LanguagePackCabPath "<cab-path>" `
    -LcuPackagePath "<lcu-path>" -RequireRdp

.EXAMPLE
.\Invoke-Windows10MachineLanguageAib.ps1 -Phase AdoptServicedLanguage `
    -LanguageTag fr-FR -RequireRdp

.EXAMPLE
.\Invoke-Windows10MachineLanguageAib.ps1 -Phase ApplyMachineLanguage -LanguageTag fr-FR

.EXAMPLE
.\Invoke-Windows10MachineLanguageAib.ps1 -Phase Validate -LanguageTag fr-FR
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('InstallAndService', 'AdoptServicedLanguage', 'ApplyMachineLanguage', 'Validate')]
    [string]$Phase,

    [Parameter(Mandatory = $true)]
    [ValidateScript({
        try {
            $culture = [Globalization.CultureInfo]::GetCultureInfo($_)
        }
        catch {
            throw "'$_' is not a recognized Windows culture tag."
        }
        if ($culture.IsNeutralCulture -or [string]::IsNullOrWhiteSpace($culture.Name)) {
            throw "'$_' is not a specific Windows culture tag."
        }
        $true
    })]
    [string]$LanguageTag,

    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$LanguagePackCabPath,

    [switch]$DownloadLanguagePack,

    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$LcuPackagePath,

    [switch]$UseWindowsUpdate,

    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$CopyNewUserSettingsScriptPath,

    [switch]$RequireRdp,

    [string]$WorkingDirectory = 'C:\ProgramData\Windows10MachineLanguageAib'
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$orchestratorPath = Join-Path $PSScriptRoot 'Set-Windows10MachineLanguage.ps1'
$statePath = Join-Path $WorkingDirectory 'state.json'
if ([string]::IsNullOrWhiteSpace($CopyNewUserSettingsScriptPath)) {
    $CopyNewUserSettingsScriptPath = Join-Path $PSScriptRoot 'Copy-UserInternationalSettingsToSystemCompat.ps1'
}

foreach ($requiredPath in @($orchestratorPath, $CopyNewUserSettingsScriptPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Required AIB language workflow file was not found at '$requiredPath'."
    }
}

$sourceParametersSpecified = (
    -not [string]::IsNullOrWhiteSpace($LanguagePackCabPath) -or
    $DownloadLanguagePack -or
    -not [string]::IsNullOrWhiteSpace($LcuPackagePath) -or
    $UseWindowsUpdate -or
    $RequireRdp -or
    $PSBoundParameters.ContainsKey('CopyNewUserSettingsScriptPath')
)

if ($Phase -in @('ApplyMachineLanguage', 'Validate')) {
    if ($sourceParametersSpecified) {
        throw "AIB phase '$Phase' accepts only -LanguageTag and -WorkingDirectory."
    }

    & $orchestratorPath `
        -Resume `
        -AibPhase $Phase `
        -ExpectedLanguageTag $LanguageTag `
        -WorkingDirectory $WorkingDirectory
    return
}

if ($Phase -eq 'AdoptServicedLanguage') {
    if (
        -not [string]::IsNullOrWhiteSpace($LanguagePackCabPath) -or
        $DownloadLanguagePack -or
        -not [string]::IsNullOrWhiteSpace($LcuPackagePath) -or
        $UseWindowsUpdate
    ) {
        throw "AIB phase 'AdoptServicedLanguage' consumes only language and updates already completed by CIT built-in customizers."
    }

    & $orchestratorPath `
        -AdoptServicedLanguage `
        -LanguageTag $LanguageTag `
        -CopyNewUserSettingsScriptPath $CopyNewUserSettingsScriptPath `
        -RequireRdp:$RequireRdp `
        -WorkingDirectory $WorkingDirectory
    return
}

if ($LanguagePackCabPath -and $DownloadLanguagePack) {
    throw 'Specify only one language-pack source: -LanguagePackCabPath or -DownloadLanguagePack.'
}
if ($LcuPackagePath -and $UseWindowsUpdate) {
    throw 'Specify only one LCU source: -LcuPackagePath or -UseWindowsUpdate.'
}
if (-not $LcuPackagePath -and -not $UseWindowsUpdate) {
    throw "AIB phase 'InstallAndService' requires an explicit LCU source: -LcuPackagePath or -UseWindowsUpdate."
}

$existingState = $null
if (Test-Path -LiteralPath $statePath -PathType Leaf) {
    $existingState = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
}
if ($null -ne $existingState) {
    if ([string]$existingState.Phase -ne 'InstallingLanguageAndLcu') {
        throw "AIB phase 'InstallAndService' cannot resume state '$($existingState.Phase)'. Invoke the documented next phase or use a new working directory."
    }
    if ([string]$existingState.LanguageTag -ne $LanguageTag) {
        throw "Existing state language '$($existingState.LanguageTag)' does not match requested '$LanguageTag'."
    }

    $requestedLcuMode = if ($LcuPackagePath) { 'Package' } else { 'WindowsUpdate' }
    if ([string]$existingState.LcuMode -ne $requestedLcuMode) {
        throw "Existing LCU mode '$($existingState.LcuMode)' does not match requested '$requestedLcuMode'."
    }
    $requestedLanguagePackSource = if ($LanguagePackCabPath) {
        'LocalCab'
    }
    elseif ($DownloadLanguagePack) {
        'MicrosoftDownload'
    }
    else {
        'AlreadyInstalled'
    }
    if ([string]$existingState.LanguagePackSource -ne $requestedLanguagePackSource) {
        throw "Existing language-pack source '$($existingState.LanguagePackSource)' does not match requested '$requestedLanguagePackSource'."
    }
    if ([bool]$existingState.RequireRdp -ne [bool]$RequireRdp) {
        throw "Existing RequireRdp value '$($existingState.RequireRdp)' does not match the retry request."
    }

    & $orchestratorPath `
        -Resume `
        -AibPhase InstallAndService `
        -ExpectedLanguageTag $LanguageTag `
        -WorkingDirectory $WorkingDirectory
    return
}

$arguments = @{
    AibPhase                     = 'InstallAndService'
    LanguageTag                  = $LanguageTag
    CopyNewUserSettingsScriptPath = $CopyNewUserSettingsScriptPath
    RequireRdp                   = [bool]$RequireRdp
    WorkingDirectory             = $WorkingDirectory
}
if ($LanguagePackCabPath) {
    $arguments.LanguagePackCabPath = $LanguagePackCabPath
}
elseif ($DownloadLanguagePack) {
    $arguments.DownloadLanguagePack = $true
}

if ($LcuPackagePath) {
    $arguments.LcuPackagePath = $LcuPackagePath
}
else {
    $arguments.UseWindowsUpdate = $true
}

& $orchestratorPath @arguments
