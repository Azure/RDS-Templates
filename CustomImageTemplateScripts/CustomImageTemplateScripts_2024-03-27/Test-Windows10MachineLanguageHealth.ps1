[CmdletBinding()]
param(
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

    [datetime]$EventsSince = (Get-Date).AddHours(-2),

    [switch]$RequireRdp
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$currentVersion = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
$osBuild = "$($currentVersion.CurrentBuild).$($currentVersion.UBR)"
$escapedTag = [regex]::Escape($LanguageTag)
$languagePackages = Get-WindowsPackage -Online |
    Where-Object {
        $_.PackageState -eq 'Installed' -and
        $_.PackageName -match "Client-LanguagePack-Package~31bf3856ad364e35~amd64~$escapedTag~10\.0\.(\d+\.\d+)$"
    } |
    ForEach-Object {
        $match = [regex]::Match($_.PackageName, '~10\.0\.(?<Version>\d+\.\d+)$')
        if ($match.Success) {
            [pscustomobject]@{
                PackageName = $_.PackageName
                Version = [version]$match.Groups['Version'].Value
            }
        }
    } |
    Sort-Object Version -Descending

$languagePackage = $languagePackages | Select-Object -First 1
if ($null -eq $languagePackage) {
    throw "The installed client language package for '$LanguageTag' was not found."
}
$languageVersion = $languagePackage.Version

$services = @{}
foreach ($serviceName in @('BFE', 'mpssvc', 'TermService', 'UmRdpService')) {
    $service = Get-CimInstance Win32_Service -Filter "Name='$serviceName'"
    if ($null -eq $service) {
        throw "Required service '$serviceName' was not found."
    }
    $services[$serviceName] = [ordered]@{
        State                   = $service.State
        StartMode               = $service.StartMode
        ExitCode                = $service.ExitCode
        ServiceSpecificExitCode = $service.ServiceSpecificExitCode
    }
}

$firewallApiHealthy = $true
try {
    [void](Get-NetFirewallProfile -ErrorAction Stop)
}
catch {
    $firewallApiHealthy = $false
}

$rdpListening = [bool](Get-NetTCPConnection `
    -LocalPort 3389 `
    -State Listen `
    -ErrorAction SilentlyContinue)
$rdpLocalTest = $false
if ($rdpListening) {
    $rdpLocalTest = Test-NetConnection 127.0.0.1 -Port 3389 -InformationLevel Quiet
}

$events = Get-WinEvent -FilterHashtable @{
    LogName   = 'System'
    StartTime = $EventsSince
} -ErrorAction SilentlyContinue

$mpssvcDisplayName = [string](Get-CimInstance Win32_Service -Filter "Name='mpssvc'").DisplayName
$mpssvcFailures = @($events | Where-Object {
    $_.Id -eq 7024 -and
    $_.ProviderName -eq 'Service Control Manager' -and
    @($_.Properties | ForEach-Object { [string]$_.Value }) -contains $mpssvcDisplayName
})
$error1168 = @($events | Where-Object {
    $_.ProviderName -eq 'Service Control Manager' -and
    $_.Id -in @(7000, 7001, 7023, 7024, 7026, 7031, 7034) -and
    (
        @($_.Properties | ForEach-Object { [string]$_.Value }) -contains '1168' -or
        $_.Message -match '\b1168\b'
    )
})

$preferredLanguage = [string](Get-SystemPreferredUILanguage)
$systemLocale = [string](Get-WinSystemLocale).Name
$rebootPending = (
    (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') -or
    (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired')
)

$checks = [ordered]@{
    PreferredLanguageMatches = $preferredLanguage -eq $LanguageTag
    SystemLocaleMatches       = $systemLocale -eq $LanguageTag
    LanguageUbrMatches        = $languageVersion.Minor -eq [int]$currentVersion.UBR
    BfeHealthy                = $services.BFE.State -eq 'Running' -and $services.BFE.ExitCode -eq 0
    MpsSvcHealthy             = $services.mpssvc.State -eq 'Running' -and $services.mpssvc.ExitCode -eq 0
    FirewallApiHealthy        = $firewallApiHealthy
    NoMpsSvc7024              = $mpssvcFailures.Count -eq 0
    NoError1168               = $error1168.Count -eq 0
    NoServicingRestartPending = -not $rebootPending
}

if ($RequireRdp) {
    $checks.RdpListening = $rdpListening
    $checks.RdpLocalTest = $rdpLocalTest
}

$succeeded = -not ($checks.Values -contains $false)
$result = [ordered]@{
    Succeeded                  = $succeeded
    CheckedUtc                 = (Get-Date).ToUniversalTime().ToString('o')
    WindowsBuild               = $osBuild
    ExpectedLanguage           = $LanguageTag
    SystemPreferredUILanguage  = $preferredLanguage
    SystemLocale               = $systemLocale
    LanguagePackage            = $languagePackage.PackageName
    LanguagePackageVersion     = $languageVersion.ToString()
    Services                   = $services
    MpsSvcEvent7024Count       = $mpssvcFailures.Count
    Error1168EventCount        = $error1168.Count
    RdpListening               = $rdpListening
    RdpLocalTest               = $rdpLocalTest
    RebootPending              = $rebootPending
    Checks                     = $checks
}

$result | ConvertTo-Json -Depth 8
if (-not $succeeded) {
    exit 1
}
