<#Author       : Akash Chawla
# Usage        : Set default Language 
#>

#######################################
#    Set default Language             #
#######################################


[CmdletBinding()]
  Param (
        [Parameter(Mandatory)]
        [ValidateSet("Arabic (Saudi Arabia)","Bulgarian (Bulgaria)","Chinese (Simplified, China)","Chinese (Traditional, Taiwan)","Croatian (Croatia)","Czech (Czech Republic)","Danish (Denmark)","Dutch (Netherlands)", "English (United Kingdom)", "Estonian (Estonia)", "Finnish (Finland)", "French (Canada)", "French (France)", "German (Germany)", "Greek (Greece)", "Hebrew (Israel)", "Hungarian (Hungary)", "Italian (Italy)", "Japanese (Japan)", "Korean (Korea)", "Latvian (Latvia)", "Lithuanian (Lithuania)", "Norwegian, Bokmål (Norway)", "Polish (Poland)", "Portuguese (Brazil)", "Portuguese (Portugal)", "Romanian (Romania)", "Russian (Russia)", "Serbian (Latin, Serbia)", "Slovak (Slovakia)", "Slovenian (Slovenia)", "Spanish (Mexico)", "Spanish (Spain)", "Swedish (Sweden)", "Thai (Thailand)", "Turkish (Turkey)", "Ukrainian (Ukraine)", "English (Australia)", "English (United States)")]
        [string]$Language
)

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