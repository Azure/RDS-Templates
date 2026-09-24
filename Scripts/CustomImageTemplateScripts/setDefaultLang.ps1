<#
.SYNOPSIS
Sets the default Windows language.

.DESCRIPTION
Windows 11 retains the original Install-Language and machine-language behavior.

Windows 10 21H2/22H2 (builds 19044/19045) uses the validated servicing sequence:
language-pack CAB, Features on Demand, current/Default User configuration, LCU
reapplication, restart and health validation, machine-wide language activation,
then a second restart and final validation.

If the language pack is not already installed, explicitly choose either
-LanguagePackCabPath or -DownloadLanguagePack. For automatic download, the
workflow downloads and extracts the matching CAB from the official Microsoft
Windows 10 language-pack ISO. Customers obtaining media themselves should use
the Windows 10 Languages and Optional Features ISO available through Microsoft
Volume Licensing or Visual Studio Subscriptions and pass the extracted CAB.

For the LCU, explicitly choose either -LcuPackagePath or -UseWindowsUpdate.
Initial Windows 10 execution must be from an elevated, interactive, non-SYSTEM
64-bit Windows PowerShell 5.1 session. Startup resumes run as SYSTEM. Azure
Image Builder customizers running as SYSTEM must use
Invoke-Windows10MachineLanguageAib.ps1 with three explicit AIB-managed Windows Restart
customizers.

.EXAMPLE
.\setDefaultLang.ps1 -Language "French (France)" -DownloadLanguagePack `
    -UseWindowsUpdate -RequireRdp -RestartAutomatically

.EXAMPLE
.\setDefaultLang.ps1 -Language "German (Germany)" `
    -LanguagePackCabPath "<cab-path>" `
    -LcuPackagePath "<lcu-path>" -RequireRdp

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
if ($osBuildForDispatch -in @(19044, 19045)) {
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
  return
}

function Get-RegionInfo($Name='*')
{
  try {
    $cultures = [System.Globalization.CultureInfo]::GetCultures('InstalledWin32Cultures')

    foreach($culture in $cultures)
    {        
      if($culture.DisplayName -eq $Name) {
        $languageTag = $culture.Name
        break;
      }
    }

    if($null -eq $languageTag) {
        return
    } else {
        $region = [System.Globalization.RegionInfo]$culture.Name
        return @($languageTag, $region.GeoId)
    }
  }
  catch {
    Write-Host "*** AVD AIB CUSTOMIZER PHASE: Set default Language - Exception occurred while getting region information***"
    Write-Host $PSItem.Exception
    return
  }
}

function UpdateUserLanguageList($languageTag)
{
  try {
    # Enable language Keyboard for Windows.
    $userLanguageList = New-WinUserLanguageList -Language $languageTag
    $installedUserLanguagesList = Get-WinUserLanguageList

    foreach($language in $installedUserLanguagesList)
    {
        $userLanguageList.Add($language.LanguageTag)
    }

    Set-WinUserLanguageList -LanguageList $userLanguageList -f
  }
  catch 
  {
    Write-Host "***Starting AVD AIB CUSTOMIZER PHASE: Set default Language - UpdateUserLanguageList: Error occurred: [$($_.Exception.Message)]"
  }
}

function UpdateRegionSettings($GeoID) 
{
  try {
    try {
      # try deleting reg key for deviceRegion for DMA compliance.
      Write-Host "***Starting AVD AIB CUSTOMIZER PHASE: Set default Language - Try deleting reg key"
      Remove-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Control Panel\DeviceRegion" -Name "DeviceRegion" -Force -ErrorAction Continue
      Write-Host "***Starting AVD AIB CUSTOMIZER PHASE: Set default Language - Remove DeviceRegion registry key succeeded."
    }
    catch 
    {
      Write-Host "***Starting AVD AIB CUSTOMIZER PHASE: Set default Language - Try deleting reg key failed with error: [$($_.Exception.Message)]"
    }

    #Set Region in Default User Profile (applies to all new users)
    New-ItemProperty -Path "HKU\.DEFAULT\Control Panel\International\Geo" -Name "Nation" -Value $GeoID -PropertyType String -Force
    Set-WinHomeLocation -GeoId $GeoID
    Write-Host "***Starting AVD AIB CUSTOMIZER PHASE: Set default Language - Region update completed."
  }
  catch {
      Write-Host "***Starting AVD AIB CUSTOMIZER PHASE: Set default Language - UpdateRegionSettings: Error occurred: [$($_.Exception.Message)]"
      Exit 1
  }
}

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
Write-Host "*** Starting AVD AIB CUSTOMIZER PHASE: Set default Language ***"

$templateFilePathFolder = "C:\AVDImage"
# Reference: https://learn.microsoft.com/en-gb/powershell/module/languagepackmanagement/set-systempreferreduilanguage?view=windowsserver2022-ps
# populate dictionary
$LanguagesDictionary = @{}
$LanguagesDictionary.Add("Arabic (Saudi Arabia)", "ar-SA")
$LanguagesDictionary.Add("Bulgarian (Bulgaria)", "bg-BG")
$LanguagesDictionary.Add("Chinese (Simplified, China)", "zh-CN")
$LanguagesDictionary.Add("Chinese (Traditional, Taiwan)", "zh-TW")
$LanguagesDictionary.Add("Croatian (Croatia)",	"hr-HR")
$LanguagesDictionary.Add("Czech (Czech Republic)",	"cs-CZ")
$LanguagesDictionary.Add("Danish (Denmark)",	"da-DK")
$LanguagesDictionary.Add("Dutch (Netherlands)",	"nl-NL")
$LanguagesDictionary.Add("English (United States)",	"en-US")
$LanguagesDictionary.Add("English (United Kingdom)",	"en-GB")
$LanguagesDictionary.Add("Estonian (Estonia)",	"et-EE")
$LanguagesDictionary.Add("Finnish (Finland)",	"fi-FI")
$LanguagesDictionary.Add("French (Canada)",	"fr-CA")
$LanguagesDictionary.Add("French (France)",	"fr-FR")
$LanguagesDictionary.Add("German (Germany)",	"de-DE")
$LanguagesDictionary.Add("Greek (Greece)",	"el-GR")
$LanguagesDictionary.Add("Hebrew (Israel)",	"he-IL")
$LanguagesDictionary.Add("Hungarian (Hungary)",	"hu-HU")
$LanguagesDictionary.Add("Indonesian (Indonesia)",	"id-ID")
$LanguagesDictionary.Add("Italian (Italy)",	"it-IT")
$LanguagesDictionary.Add("Japanese (Japan)",	"ja-JP")
$LanguagesDictionary.Add("Korean (Korea)",	"ko-KR")
$LanguagesDictionary.Add("Latvian (Latvia)",	"lv-LV")
$LanguagesDictionary.Add("Lithuanian (Lithuania)",	"lt-LT")
$LanguagesDictionary.Add("Norwegian, Bokmål (Norway)",	"nb-NO")
$LanguagesDictionary.Add("Polish (Poland)",	"pl-PL")
$LanguagesDictionary.Add("Portuguese (Brazil)",	"pt-BR")
$LanguagesDictionary.Add("Portuguese (Portugal)",	"pt-PT")
$LanguagesDictionary.Add("Romanian (Romania)",	"ro-RO")
$LanguagesDictionary.Add("Russian (Russia)",	"ru-RU")
$LanguagesDictionary.Add("Serbian (Latin, Serbia)",	"sr-Latn-RS")
$LanguagesDictionary.Add("Slovak (Slovakia)",	"sk-SK")
$LanguagesDictionary.Add("Slovenian (Slovenia)",	"sl-SI")
$LanguagesDictionary.Add("Spanish (Mexico)",	"es-MX")
$LanguagesDictionary.Add("Spanish (Spain)",	"es-ES")
$LanguagesDictionary.Add("Swedish (Sweden)",	"sv-SE")
$LanguagesDictionary.Add("Thai (Thailand)",	"th-TH")
$LanguagesDictionary.Add("Turkish (Turkey)",	"tr-TR")
$LanguagesDictionary.Add("Ukrainian (Ukraine)",	"uk-UA")
$LanguagesDictionary.Add("English (Australia)",	"en-AU")

try {
  # Disable LanguageComponentsInstaller while installing language packs
  # See Bug 45044965: Installing language pack fails with error: ERROR_SHARING_VIOLATION for more details
  Disable-ScheduledTask -TaskName "\Microsoft\Windows\LanguageComponentsInstaller\Installation"
  Disable-ScheduledTask -TaskName "\Microsoft\Windows\LanguageComponentsInstaller\ReconcileLanguageResources"

  $languageDetails = Get-RegionInfo -Name $Language

  if($null -eq $languageDetails) {
    $LanguageTag = $LanguagesDictionary.$Language 
  } else {
    $languageTag = $languageDetails[0]
    $GeoID = $languageDetails[1]
  }

  $foundLanguage = $false;

  try {
    #install language pack in case the provided language is not installed
    $installedLanguages = Get-InstalledLanguage
    foreach($languagePack in $installedLanguages) {
      $languageID = $languagePack.LanguageId
      if($languageID -eq $LanguageTag) {
        $foundLanguage = $true
        break
      }
    } 
  }
  catch {
    Write-Host "*** AVD AIB CUSTOMIZER PHASE: Set default Language - Exception occurred while installing language packs***"
    Write-Host $PSItem.Exception
  }

  if(-Not $foundLanguage) {
    # retry in case we hit transient errors
    for($i=1; $i -le 5; $i++) {
        try {
            Write-Host "*** AVD AIB CUSTOMIZER PHASE : Set default language - Install language packs -  Attempt: $i ***"   
            Install-Language -Language $LanguageTag -ErrorAction Stop
            Write-Host "*** AVD AIB CUSTOMIZER PHASE : Set default language - Install language packs -  Installed language $LanguageCode ***"   
            break
        }
        catch {
            Write-Host "*** AVD AIB CUSTOMIZER PHASE : Set default language - Install language packs - Exception occurred***"
            Write-Host $PSItem.Exception
            continue
        }
    }
  }
  else {
     Write-Host "*** AVD AIB CUSTOMIZER PHASE : Set default language - Language pack for $LanguageTag is installed already***"
  }
  
  Set-systempreferreduilanguage -Language $LanguageTag
  Set-WinSystemLocale -SystemLocale $LanguageTag
  Set-Culture -CultureInfo $LanguageTag
  
  # Enable language Keyboard for Windows.
  UpdateUserLanguageList -languageTag $LanguageTag

  Write-Host "*** AVD AIB CUSTOMIZER PHASE: Set default Language - $Language with $LanguageTag has been set as the default System Preferred UI Language***"

  $GeoID = (new-object System.Globalization.RegionInfo($languageTag.Split("-")[1])).GeoId
  UpdateRegionSettings($GeoID)

  # Copy user international settings to system for welcome screen and new users
  Write-Host "*** AVD AIB CUSTOMIZER PHASE: Set default Language - Copying user international settings to system ***"
  Copy-UserInternationalSettingsToSystem -WelcomeScreen $true -NewUser $true
  Write-Host "*** AVD AIB CUSTOMIZER PHASE: Set default Language - Successfully copied settings to welcome screen and new user defaults ***"
} 
catch {
    Write-Host "*** AVD AIB CUSTOMIZER PHASE: Set default Language - Exception occurred***"
    Write-Host $PSItem.Exception
}

if ((Test-Path -Path $templateFilePathFolder -ErrorAction SilentlyContinue)) {
    Remove-Item -Path $templateFilePathFolder -Force -Recurse -ErrorAction Continue
}

# Enable LanguageComponentsInstaller after language packs are installed
Enable-ScheduledTask -TaskName "\Microsoft\Windows\LanguageComponentsInstaller\Installation"
Enable-ScheduledTask -TaskName "\Microsoft\Windows\LanguageComponentsInstaller\ReconcileLanguageResources"

$stopwatch.Stop()
$elapsedTime = $stopwatch.Elapsed
Write-Host "*** AVD AIB CUSTOMIZER PHASE: Set default Language - Exit Code: $LASTEXITCODE ***"
Write-Host "*** AVD AIB CUSTOMIZER PHASE: Set default Language - Time taken: $elapsedTime ***"


#############
#    END    #
#############