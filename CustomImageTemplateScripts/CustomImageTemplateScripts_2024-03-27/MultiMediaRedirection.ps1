<#Author       : Akash Chawla
# Usage        : Install and enable multimedia redirection
#>

###########################################################
#      Install and enable multimedia redirection         #
###########################################################

[CmdletBinding()] Param (
    [Parameter(
        Mandatory
    )]
    [string]$VCRedistributableLink,

    [Parameter(
        Mandatory
    )]
    [string]$EnableEdge,

    [Parameter(
        Mandatory
    )]
    [string]$EnableChrome
)

function InstallAndEnableMMR($VCRedistributableLink, $EnableChrome, $EnableEdge) {
   
        Begin {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $templateFilePathFolder = "C:\AVDImage"
            Write-host "Starting AVD AIB Customization: MultiMedia Redirection: $((Get-Date).ToUniversalTime()) "

            $guid = [guid]::NewGuid().Guid
            $tempFolder = (Join-Path -Path "C:\temp\" -ChildPath $guid)

            if (!(Test-Path -Path $tempFolder)) {
                New-Item -Path $tempFolder -ItemType Directory
            }

            $mmrHostUrl = "https://aka.ms/avdmmr/msi"
            $mmrExePath = Join-Path -Path $tempFolder -ChildPath "mmrtool.msi"
        }

        Process {
            
            try {     
                # Set reg key while the feature is in preview

                New-Item -Path "HKLM:\SOFTWARE\Microsoft\MSRDC\Policies" -Force
                New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\MSRDC\Policies" -Name ReleaseRing -PropertyType String -Value insider -Force
                
                # Install the latest version of the Microsoft Visual C++ Redistributable
                Write-host "AVD AIB Customization:  MultiMedia Redirection - Starting the installation of provided Microsoft Visual C++ Redistributable"
                $appName = 'mmr'
                $drive = 'C:\'
                New-Item -Path $drive -Name $appName  -ItemType Directory -ErrorAction SilentlyContinue
                $LocalPath = $drive + '\' + $appName 
                Set-Location $LocalPath
                $VCRedistExe = 'vc_redist.x64.exe'
                $outputPath = $LocalPath + '\' + $VCRedistExe
                Invoke-WebRequest -Uri $VCRedistributableLink -OutFile $outputPath
                Start-Process -FilePath $outputPath -Args "/install /quiet /norestart /log vcdist.log" -Wait -NoNewWindow
                Write-host "AVD AIB Customization: MultiMedia Redirection - Finished the installation of provided Microsoft Visual C++ Redistributable"

                #Install the host component
                Write-host "AVD AIB Customization:  MultiMedia Redirection - Starting the installation of host component"
                Write-Host "AVD AIB Customization:  MultiMedia Redirection - Downloading MMR host into folder $mmrExePath"
                $mmrHostResponse = Invoke-WebRequest -Uri "$mmrHostUrl" -UseBasicParsing -UseDefaultCredentials -OutFile $mmrExePath -PassThru

                if ($mmrHostResponse.StatusCode -ne 200) { 
                    throw "MMR host failed to download -- Response $($mmrHostResponse.StatusCode) ($($mmrHostResponse.StatusDescription))"
                }

                $arguments = "/i `"$mmrExePath`" /quiet"
                Start-Process msiexec.exe -ArgumentList $arguments -Wait -NoNewWindow

                Write-Host "AVD AIB Customization:  MultiMedia Redirection - Finished installing the mmr host agent"

                #Enable Edge extension

                if([System.Convert]::ToBoolean($EnableEdge)) {
                    Write-host "AVD AIB Customization:  MultiMedia Redirection - Starting to enable extension for Microsoft Edge" 
                    $registryValue = '{ "joeclbldhdmoijbaagobkhlpfjglcihd": { "installation_mode": "force_installed", "update_url": "https://edge.microsoft.com/extensionwebstorebase/v1/crx" } }';
                    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Force
                    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name ExtensionSettings -PropertyType String -Value $registryValue -Force  
                    Write-host "AVD AIB Customization:  MultiMedia Redirection - Finished enabling extension for Microsoft Edge" 
                }

                if([System.Convert]::ToBoolean($EnableChrome)) {
                     #Install Chrome and enable extension
                    Write-host "AVD AIB Customization:  MultiMedia Redirection - Checking if Google Chrome is installed"

                    try {
                        $chrome = $(Get-Package -Name "Google Chrome")
                    }
                    catch {
                        Write-host "AVD AIB Customization:  MultiMedia Redirection - Google Chrome is not installed"
                    }

                    if([string]::IsNullOrEmpty($chrome)) {
                        Write-host "AVD AIB Customization:  MultiMedia Redirection - Installing latest version of chrome"
                        $chromeInstallerPath = Join-Path -Path $tempFolder -ChildPath "chromeInstaller.exe"
                        $chromeResponse = Invoke-WebRequest "https://dl.google.com/chrome/install/latest/chrome_installer.exe" -UseBasicParsing -UseDefaultCredentials -OutFile $chromeInstallerPath -PassThru

                        if ($chromeResponse.StatusCode -ne 200) { 
                            throw "Google chrome failed to download -- Response $($chromeResponse.StatusCode) ($($chromeResponse.StatusDescription))"
                        }

                        Start-Process -FilePath $chromeInstallerPath -Args "/silent /install" -Verb RunAs -Wait
                        Write-host "AVD AIB Customization:  MultiMedia Redirection - Finished installing Google Chrome"
                    }

                    $registryValue = '{ "lfmemoeeciijgkjkgbgikoonlkabmlno": { "installation_mode": "force_installed", "update_url": "https://clients2.google.com/service/update2/crx" } }';
                    New-Item -Path "HKLM:\SOFTWARE\Policies\Google\Chrome" -Force
                    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Google\Chrome" -Name ExtensionSettings -PropertyType String -Value $registryValue -Force

                    Write-host "AVD AIB Customization:  MultiMedia Redirection - Finished enabling extension for Google Chrome"
                }
            }
            catch {
                Write-Host "*** AVD AIB CUSTOMIZER PHASE ***   MultiMedia Redirection  - Exception occured  *** : [$($_.Exception.Message)]"
            }    
        }
        
        End {

            #Cleanup
            if ((Test-Path -Path $templateFilePathFolder -ErrorAction SilentlyContinue)) {
                Remove-Item -Path $templateFilePathFolder -Force -Recurse -ErrorAction Continue
            }

           if ((Test-Path -Path $tempFolder -ErrorAction SilentlyContinue)) {
               Remove-Item -Path $tempFolder -Force -Recurse -ErrorAction Continue
           }
    
            $stopwatch.Stop()
            $elapsedTime = $stopwatch.Elapsed
            Write-Host "*** AVD AIB CUSTOMIZER PHASE :  MultiMedia Redirection -  Exit Code: $LASTEXITCODE ***"    
            Write-Host "Ending AVD AIB Customization :  MultiMedia Redirection - Time taken: $elapsedTime"
        }
 }

InstallAndEnableMMR -VCRedistributableLink $VCRedistributableLink -EnableChrome $EnableChrome -EnableEdge $EnableEdge

#############
#    END    #
#############