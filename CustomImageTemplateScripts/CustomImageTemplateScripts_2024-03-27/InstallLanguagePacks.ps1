<#Author       : Akash Chawla
# Usage        : Install Language packs
#>

#######################################
#    Install language packs           #
#######################################


[CmdletBinding()]
  Param (
        [Parameter(
            Mandatory
        )]
        [ValidateSet("Arabic (Saudi Arabia)","Bulgarian (Bulgaria)","Chinese (Simplified, China)","Chinese (Traditional, Taiwan)","Croatian (Croatia)","Czech (Czech Republic)","Danish (Denmark)","Dutch (Netherlands)", "English (United Kingdom)", "Estonian (Estonia)", "Finnish (Finland)", "French (Canada)", "French (France)", "German (Germany)", "Greek (Greece)", "Hebrew (Israel)", "Hungarian (Hungary)", "Italian (Italy)", "Japanese (Japan)", "Korean (Korea)", "Latvian (Latvia)", "Lithuanian (Lithuania)", "Norwegian, Bokmål (Norway)", "Polish (Poland)", "Portuguese (Brazil)", "Portuguese (Portugal)", "Romanian (Romania)", "Russian (Russia)", "Serbian (Latin, Serbia)", "Slovak (Slovakia)", "Slovenian (Slovenia)", "Spanish (Mexico)", "Spanish (Spain)", "Swedish (Sweden)", "Thai (Thailand)", "Turkish (Turkey)", "Ukrainian (Ukraine)", "English (Australia)", "English (United States)")]
        [System.String[]]$LanguageList
    )

$osBuildForDispatch = [System.Environment]::OSVersion.Version.Build
if ($osBuildForDispatch -in @(19044, 19045)) {
    $windows10SupportBaseUri = 'https://raw.githubusercontent.com/anshuljswl/RDS-Templates/dcaa3564c8975df11a09e152e3b852cc9277a6cb/CustomImageTemplateScripts/CustomImageTemplateScripts_2024-03-27'
    $windows10WorkingDirectory = 'C:\ProgramData\Windows10MachineLanguage'
    $windows10OrchestratorPath = Join-Path $windows10WorkingDirectory 'Set-Windows10MachineLanguage.ps1'
    $windows10CopyHelperPath = Join-Path $windows10WorkingDirectory 'Copy-UserInternationalSettingsToSystemCompat.ps1'
    $windows10OrchestratorSha256 = '265C26DD99A02FC156F16601F2E071F7978C6E2968063CDEB991C566E2B371DE'
    $windows10CopyHelperSha256 = '627BA579956AF437B2A865A99F4CCFBD8DEF7B6DCEBB2A14AA9CDA88ECBEC250'

    function Save-VerifiedWindows10SupportFile {
        param(
            [Parameter(Mandatory = $true)][uri]$Uri,
            [Parameter(Mandatory = $true)][string]$Destination,
            [Parameter(Mandatory = $true)][string]$ExpectedSha256
        )

        if ($Uri.Scheme -ne 'https' -or $Uri.Host -ne 'raw.githubusercontent.com') {
            throw "Windows 10 support files must use HTTPS from raw.githubusercontent.com."
        }

        $partialPath = "$Destination.partial"
        Remove-Item -LiteralPath $partialPath -Force -ErrorAction SilentlyContinue
        try {
            Invoke-WebRequest `
                -Uri $Uri.AbsoluteUri `
                -OutFile $partialPath `
                -UseBasicParsing `
                -ErrorAction Stop
            $actualSha256 = (Get-FileHash -LiteralPath $partialPath -Algorithm SHA256).Hash
            if ($actualSha256 -ne $ExpectedSha256) {
                throw "Windows 10 support file hash mismatch for '$($Uri.AbsolutePath)'."
            }
            Move-Item -LiteralPath $partialPath -Destination $Destination -Force
        }
        finally {
            Remove-Item -LiteralPath $partialPath -Force -ErrorAction SilentlyContinue
        }
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

    $languageTags = New-Object System.Collections.Generic.List[string]
    $seenLanguageTags = New-Object System.Collections.Generic.HashSet[string](
        [StringComparer]::OrdinalIgnoreCase
    )
    foreach ($language in $LanguageList) {
        $languageTag = [string]$windows10LanguageTags[$language]
        if ([string]::IsNullOrWhiteSpace($languageTag)) {
            throw "Windows 10 language mapping was not found for '$language'."
        }
        if ($seenLanguageTags.Add($languageTag)) {
            [void]$languageTags.Add($languageTag)
        }
    }
    if ($languageTags.Count -eq 0) {
        throw 'At least one Windows 10 language must be requested.'
    }

    New-Item -ItemType Directory -Path $windows10WorkingDirectory -Force | Out-Null
    Save-VerifiedWindows10SupportFile `
        -Uri "$windows10SupportBaseUri/Set-Windows10MachineLanguage.ps1" `
        -Destination $windows10OrchestratorPath `
        -ExpectedSha256 $windows10OrchestratorSha256
    Save-VerifiedWindows10SupportFile `
        -Uri "$windows10SupportBaseUri/Copy-UserInternationalSettingsToSystemCompat.ps1" `
        -Destination $windows10CopyHelperPath `
        -ExpectedSha256 $windows10CopyHelperSha256

    & $windows10OrchestratorPath `
        -LanguageTags $languageTags.ToArray() `
        -UseWindowsUpdate `
        -CopyNewUserSettingsScriptPath $windows10CopyHelperPath `
        -AibPhase InstallAndService `
        -AllowRecognizedNonServicingPendingFileRenames
    return
}

function Install-LanguagePack {
  
   
    <#
    Function to install language packs along with features on demand: 
    https://learn.microsoft.com/en-gb/powershell/module/languagepackmanagement/install-language?view=windowsserver2022-ps
    #>

    BEGIN {
        
        $templateFilePathFolder = "C:\AVDImage"
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        Write-host "Starting AVD AIB Customization: Install Language packs: $((Get-Date).ToUniversalTime()) "

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

         # Disable LanguageComponentsInstaller while installing language packs
         # See Bug 45044965: Installing language pack fails with error: ERROR_SHARING_VIOLATION for more details
         Disable-ScheduledTask -TaskName "\Microsoft\Windows\LanguageComponentsInstaller\Installation"
         Disable-ScheduledTask -TaskName "\Microsoft\Windows\LanguageComponentsInstaller\ReconcileLanguageResources"
    } # Begin
    PROCESS {

        foreach ($Language in $LanguageList) {

            # retry in case we hit transient errors
            for($i=1; $i -le 5; $i++) {
                 try {
                    Write-Host "*** AVD AIB CUSTOMIZER PHASE : Install language packs -  Attempt: $i ***"   
                    $LanguageCode =  $LanguagesDictionary.$Language
                    Install-Language -Language $LanguageCode -ErrorAction Stop
                    Write-Host "*** AVD AIB CUSTOMIZER PHASE : Install language packs -  Installed language $LanguageCode ***"   
                    break
                }
                catch {
                    Write-Host "*** AVD AIB CUSTOMIZER PHASE : Install language packs - Exception occurred***"
                    Write-Host $PSItem.Exception
                    continue
                }
            }
        }
    } #Process
    END {

        #Cleanup
        if ((Test-Path -Path $templateFilePathFolder -ErrorAction SilentlyContinue)) {
            Remove-Item -Path $templateFilePathFolder -Force -Recurse -ErrorAction Continue
        }

        # Enable LanguageComponentsInstaller after language packs are installed
        Enable-ScheduledTask -TaskName "\Microsoft\Windows\LanguageComponentsInstaller\Installation"
        Enable-ScheduledTask -TaskName "\Microsoft\Windows\LanguageComponentsInstaller\ReconcileLanguageResources"
        $stopwatch.Stop()
        $elapsedTime = $stopwatch.Elapsed
        Write-Host "*** AVD AIB CUSTOMIZER PHASE : Install language packs -  Exit Code: $LASTEXITCODE ***"    
        Write-Host "Ending AVD AIB Customization : Install language packs - Time taken: $elapsedTime"
    } 
}

 Install-LanguagePack -LanguageList $LanguageList

 #############
#    END    #
#############