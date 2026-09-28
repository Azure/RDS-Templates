<#
.SYNOPSIS
Configures the validated Windows 10 21H2/22H2 machine language workflow.

.DESCRIPTION
Standalone Windows 10 entry point for builds 19044 and 19045. The workflow
installs or verifies the language pack and Features on Demand, configures user
settings, reapplies the LCU, and completes the two required restart phases.
Windows 11 continues to use the existing SetDefaultLang.ps1 script.

.EXAMPLE
.\SetDefaultLangWin10.ps1 -Language "French (France)" `
    -DownloadLanguagePack -UseWindowsUpdate -RequireRdp -RestartAutomatically

.EXAMPLE
.\SetDefaultLangWin10.ps1 -Language "German (Germany)" `
    -LanguagePackCabPath "<cab-path>" -LcuPackagePath "<lcu-path>" -RequireRdp
#>
#######################################
#    Set default Language             #
#######################################


[CmdletBinding()]
  Param (
        [Parameter(Mandatory)]
        [ValidateSet("Arabic (Saudi Arabia)","Bulgarian (Bulgaria)","Chinese (Simplified, China)","Chinese (Traditional, Taiwan)","Croatian (Croatia)","Czech (Czech Republic)","Danish (Denmark)","Dutch (Netherlands)", "English (United Kingdom)", "Estonian (Estonia)", "Finnish (Finland)", "French (Canada)", "French (France)", "German (Germany)", "Greek (Greece)", "Hebrew (Israel)", "Hungarian (Hungary)", "Italian (Italy)", "Japanese (Japan)", "Korean (Korea)", "Latvian (Latvia)", "Lithuanian (Lithuania)", "Norwegian, Bokmål (Norway)", "Polish (Poland)", "Portuguese (Brazil)", "Portuguese (Portugal)", "Romanian (Romania)", "Russian (Russia)", "Serbian (Latin, Serbia)", "Slovak (Slovakia)", "Slovenian (Slovenia)", "Spanish (Mexico)", "Spanish (Spain)", "Swedish (Sweden)", "Thai (Thailand)", "Turkish (Turkey)", "Ukrainian (Ukraine)", "English (Australia)", "English (United States)")]
        [string]$Language,

        [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
        [string]$LanguagePackCabPath,

        [switch]$DownloadLanguagePack,

        [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
        [string]$LcuPackagePath,

        [switch]$UseWindowsUpdate,

        [switch]$RequireRdp,

        [switch]$RestartAutomatically
)

$osBuildForDispatch = [System.Environment]::OSVersion.Version.Build
if ($osBuildForDispatch -notin @(19044, 19045)) {
  throw "SetDefaultLangWin10.ps1 supports only Windows 10 client builds 19044 and 19045; detected build $osBuildForDispatch."
}
  $windows10LanguageTags = @{
    "Arabic (Saudi Arabia)" = "ar-SA"
    "Bulgarian (Bulgaria)" = "bg-BG"
    "Chinese (Simplified, China)" = "zh-CN"
    "Chinese (Traditional, Taiwan)" = "zh-TW"
    "Croatian (Croatia)" = "hr-HR"
    "Czech (Czech Republic)" = "cs-CZ"
    "Danish (Denmark)" = "da-DK"
    "Dutch (Netherlands)" = "nl-NL"
    "English (Australia)" = "en-AU"
    "English (United Kingdom)" = "en-GB"
    "English (United States)" = "en-US"
    "Estonian (Estonia)" = "et-EE"
    "Finnish (Finland)" = "fi-FI"
    "French (Canada)" = "fr-CA"
    "French (France)" = "fr-FR"
    "German (Germany)" = "de-DE"
    "Greek (Greece)" = "el-GR"
    "Hebrew (Israel)" = "he-IL"
    "Hungarian (Hungary)" = "hu-HU"
    "Italian (Italy)" = "it-IT"
    "Japanese (Japan)" = "ja-JP"
    "Korean (Korea)" = "ko-KR"
    "Latvian (Latvia)" = "lv-LV"
    "Lithuanian (Lithuania)" = "lt-LT"
    "Norwegian, Bokmål (Norway)" = "nb-NO"
    "Polish (Poland)" = "pl-PL"
    "Portuguese (Brazil)" = "pt-BR"
    "Portuguese (Portugal)" = "pt-PT"
    "Romanian (Romania)" = "ro-RO"
    "Russian (Russia)" = "ru-RU"
    "Serbian (Latin, Serbia)" = "sr-Latn-RS"
    "Slovak (Slovakia)" = "sk-SK"
    "Slovenian (Slovenia)" = "sl-SI"
    "Spanish (Mexico)" = "es-MX"
    "Spanish (Spain)" = "es-ES"
    "Swedish (Sweden)" = "sv-SE"
    "Thai (Thailand)" = "th-TH"
    "Turkish (Turkey)" = "tr-TR"
    "Ukrainian (Ukraine)" = "uk-UA"
  }

  if ($LanguagePackCabPath -and $DownloadLanguagePack) {
    throw 'Specify either -LanguagePackCabPath or -DownloadLanguagePack, not both.'
  }
  if ($LcuPackagePath -and $UseWindowsUpdate) {
    throw 'Specify either -LcuPackagePath or -UseWindowsUpdate, not both.'
  }
  if (-not $LcuPackagePath -and -not $UseWindowsUpdate) {
    throw 'Windows 10 requires an explicit LCU mode: specify -LcuPackagePath or -UseWindowsUpdate.'
  }

  $windows10Orchestrator = Join-Path $PSScriptRoot 'Set-Windows10MachineLanguage.ps1'
  $windows10CopyHelper = Join-Path $PSScriptRoot 'Copy-UserInternationalSettingsToSystemCompat.ps1'
  if (-not (Test-Path -LiteralPath $windows10Orchestrator -PathType Leaf)) {
    throw "Windows 10 language orchestrator was not found at '$windows10Orchestrator'."
  }
  if (-not (Test-Path -LiteralPath $windows10CopyHelper -PathType Leaf)) {
    throw "Windows 10 international-settings helper was not found at '$windows10CopyHelper'."
  }

  $windows10Arguments = @{
    LanguageTag                   = $windows10LanguageTags[$Language]
    CopyNewUserSettingsScriptPath = $windows10CopyHelper
    RequireRdp                    = [bool]$RequireRdp
    RestartAutomatically          = [bool]$RestartAutomatically
  }
  if ($LanguagePackCabPath) {
    $windows10Arguments.LanguagePackCabPath = $LanguagePackCabPath
  }
  elseif ($DownloadLanguagePack) {
    $windows10Arguments.DownloadLanguagePack = $true
  }

  if ($LcuPackagePath) {
    $windows10Arguments.LcuPackagePath = $LcuPackagePath
  }
  else {
    $windows10Arguments.UseWindowsUpdate = $true
  }

& $windows10Orchestrator @windows10Arguments
