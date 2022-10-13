<#Author       : Akash Chawla
# Usage        : Set default Language 
#>

#######################################
#    Set default Language             #
#######################################


[CmdletBinding()]
  Param (
        [Parameter(Mandatory)]
        [ValidateSet("Arabic (Saudi Arabia)","Bulgarian (Bulgaria)","Chinese (Simplified, China)","Chinese (Traditional, Taiwan)","Croatian (Croatia)","Czech (Czech Republic)","Danish (Denmark)","Dutch (Netherlands)", "English (United Kingdom)", "Estonian (Estonia)", "Finnish (Finland)", "French (Canada)", "French (France)", "German (Germany)", "Greek (Greece)", "Hebrew (Israel)", "Hungarian (Hungary)", "Italian (Italy)", "Japanese (Japan)", "Korean (Korea)", "Latvian (Latvia)", "Lithuanian (Lithuania)", "Norwegian, Bokmål (Norway)", "Polish (Poland)", "Portuguese (Brazil)", "Portuguese (Portugal)", "Romanian (Romania)", "Russian (Russia)", "Serbian (Latin, Serbia)", "Slovak (Slovakia)", "Slovenian (Slovenia)", "Spanish (Mexico)", "Spanish (Spain)", "Swedish (Sweden)", "Thai (Thailand)", "Turkish (Turkey)", "Ukrainian (Ukraine)")]
        [string]$Language
)

function Set-RegKey($registryPath, $registryKey, $registryValue) {
  try {
       New-ItemProperty -Path $registryPath -Name $registryKey -Value $registryValue -PropertyType DWORD -Force -ErrorAction Stop
  }
  catch {
       Write-Host "*** AVD AIB CUSTOMIZER PHASE: Set default Language - Cannot add the registry key  $registryKey *** : [$($_.Exception.Message)]"
  }
}

function Set-DefaultLanguage($Language) {

  BEGIN {

      $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
      Write-Host "*** Starting AVD AIB CUSTOMIZER PHASE: Set default Language ***"

      $templateFilePathFolder = "C:\AVDImage"
      # Reference: https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-lcid/a9eac961-e77d-41a6-90a5-ce1a8b0cdb9c?redirectedfrom=MSDN
      # populate dictionary
      $LanguagesRegKeyMapping = @{}
      $LanguagesRegKeyMapping.Add("Arabic (Saudi Arabia)", "0x0401")
      $LanguagesRegKeyMapping.Add("Bulgarian (Bulgaria)", "0x0402")
      $LanguagesRegKeyMapping.Add("Chinese (Simplified, China)", "0x0804")
      $LanguagesRegKeyMapping.Add("Chinese (Traditional, Taiwan)", "0x0404")
      $LanguagesRegKeyMapping.Add("Croatian (Croatia)",	"0x041A")
      $LanguagesRegKeyMapping.Add("Czech (Czech Republic)",	"0x0405")
      $LanguagesRegKeyMapping.Add("Danish (Denmark)",	"0x0406")
      $LanguagesRegKeyMapping.Add("Dutch (Netherlands)",	"0x0413")
      $LanguagesRegKeyMapping.Add("English (United States)",	"0x0409")
      $LanguagesRegKeyMapping.Add("English (United Kingdom)",	"0x0809")
      $LanguagesRegKeyMapping.Add("Estonian (Estonia)",	"0x0425")
      $LanguagesRegKeyMapping.Add("Finnish (Finland)",	"0x040B")
      $LanguagesRegKeyMapping.Add("French (Canada)",	"0x0c0C")
      $LanguagesRegKeyMapping.Add("French (France)",	"0x040C")
      $LanguagesRegKeyMapping.Add("German (Germany)",	"0x0407")
      $LanguagesRegKeyMapping.Add("Greek (Greece)",	"0x0408")
      $LanguagesRegKeyMapping.Add("Hebrew (Israel)",	"0x040D")
      $LanguagesRegKeyMapping.Add("Hungarian (Hungary)",	"0x040E")
      $LanguagesRegKeyMapping.Add("Indonesian (Indonesia)",	"0x0421")
      $LanguagesRegKeyMapping.Add("Italian (Italy)",	"0x0410")
      $LanguagesRegKeyMapping.Add("Japanese (Japan)",	"0x0411")
      $LanguagesRegKeyMapping.Add("Korean (Korea)",	"0x0412")
      $LanguagesRegKeyMapping.Add("Latvian (Latvia)",	"0x0426")
      $LanguagesRegKeyMapping.Add("Lithuanian (Lithuania)",	"0x0427")
      $LanguagesRegKeyMapping.Add("Norwegian, Bokmål (Norway)",	"0x0414")
      $LanguagesRegKeyMapping.Add("Polish (Poland)",	"0x0415")
      $LanguagesRegKeyMapping.Add("Portuguese (Brazil)",	"0x0416")
      $LanguagesRegKeyMapping.Add("Portuguese (Portugal)",	"0x0816")
      $LanguagesRegKeyMapping.Add("Romanian (Romania)",	"0x0418")
      $LanguagesRegKeyMapping.Add("Russian (Russia)",	"0x0419")
      $LanguagesRegKeyMapping.Add("Serbian (Latin, Serbia)",	"0x241A")
      $LanguagesRegKeyMapping.Add("Slovak (Slovakia)",	"0x041B")
      $LanguagesRegKeyMapping.Add("Slovenian (Slovenia)",	"0x0424")
      $LanguagesRegKeyMapping.Add("Spanish (Mexico)",	"0x080A")
      $LanguagesRegKeyMapping.Add("Spanish (Spain)",	"0x0c0A")
      $LanguagesRegKeyMapping.Add("Swedish (Sweden)",	"0x041D")
      $LanguagesRegKeyMapping.Add("Thai (Thailand)",	"0x041E")
      $LanguagesRegKeyMapping.Add("Turkish (Turkey)",	"0x041F")
      $LanguagesRegKeyMapping.Add("Ukrainian (Ukraine)",	"0x0422")

      $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Nls\Language"
      $registryKey = "InstallLanguage"
      $registryValue = $LanguagesRegKeyMapping.$Language 

      IF(!(Test-Path $registryPath)) {
        New-Item -Path $registryPath -Force | Out-Null
      }
  }

  PROCESS {
      Set-RegKey -registryPath $registryPath -registryKey $registryKey -registryValue $registryValue
  }

  END {

      if ((Test-Path -Path $templateFilePathFolder -ErrorAction SilentlyContinue)) {
          Remove-Item -Path $templateFilePathFolder -Force -Recurse -ErrorAction Continue
      }

      $stopwatch.Stop()
      $elapsedTime = $stopwatch.Elapsed
      Write-Host "*** AVD AIB CUSTOMIZER PHASE: Set default Language - Exit Code: $LASTEXITCODE ***"
      Write-Host "*** AVD AIB CUSTOMIZER PHASE: Set default Language - Time taken: $elapsedTime ***"
  }
}

Set-DefaultLanguage -Language $Language

#############
#    END    #
#############






