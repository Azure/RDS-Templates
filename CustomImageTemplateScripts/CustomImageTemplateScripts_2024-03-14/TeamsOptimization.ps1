 <#Author       : Akash Chawla
# Usage        : Teams Optimization
#>

#######################################
#    Teams Optimization               #
#######################################

# Reference: https://learn.microsoft.com/en-us/azure/virtual-desktop/teams-on-avd

[CmdletBinding()]
  Param (
        [Parameter()]
        [string]$TeamsDownloadLink,

        [Parameter(Mandatory)]
        [string]$VCRedistributableLink,

        [Parameter(Mandatory)]
        [string]$WebRTCInstaller,

        [Parameter()]
        [string]$TeamsBootStrapperUrl
)
 
 function InstallTeamsOptimizationforAVD($TeamsDownloadLink, $VCRedistributableLink, $WebRTCInstaller, $TeamsBootStrapperUrl) {
   
        Begin {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $templateFilePathFolder = "C:\AVDImage"
            Write-host "Starting AVD AIB Customization: Teams Optimization : $((Get-Date).ToUniversalTime()) "

            $guid = [guid]::NewGuid().Guid
            $tempFolder = (Join-Path -Path "C:\temp\" -ChildPath $guid)

            if (!(Test-Path -Path $tempFolder)) {
                New-Item -Path $tempFolder -ItemType Directory
            }
    
            Write-Host "AVD AIB Customization: Teams Optimization: Created temp folder $tempFolder"
        }

        Process {
            
            try {     
                # Set reg key
                New-Item -Path HKLM:\SOFTWARE\Microsoft -Name "Teams" 
                $registryPath = "HKLM:\SOFTWARE\Microsoft\Teams"
                $registryKey = "IsWVDEnvironment"
                $registryValue = "1"
                Set-RegKey -registryPath $registryPath -registryKey $registryKey -registryValue $registryValue 
                
                # Install the latest version of the Microsoft Visual C++ Redistributable
                Write-host "AVD AIB Customization: Teams Optimization - Starting the installation of latest Microsoft Visual C++ Redistributable"
                $appName = 'teams'
                New-Item -Path $tempFolder -Name $appName  -ItemType Directory -ErrorAction SilentlyContinue
                $LocalPath = $tempFolder + '\' + $appName 
                $VCRedistExe = 'vc_redist.x64.exe'
                $outputPath = $LocalPath + '\' + $VCRedistExe
                Invoke-WebRequest -Uri $VCRedistributableLink -OutFile $outputPath
                Start-Process -FilePath $outputPath -Args "/install /quiet /norestart /log vcdist.log" -Wait
                Write-host "AVD AIB Customization: Teams Optimization - Finished the installation of latest Microsoft Visual C++ Redistributable"

                # Install the Remote Desktop WebRTC Redirector Service
                $webRTCMSI = 'webSocketSvc.msi'
                $outputPath = $LocalPath + '\' + $webRTCMSI
                Invoke-WebRequest -Uri $WebRTCInstaller -OutFile $outputPath
                Start-Process -FilePath msiexec.exe -Args "/I $outputPath /quiet /norestart /log webSocket.log" -Wait
                Write-host "AVD AIB Customization: Teams Optimization - Finished the installation of the Teams WebSocket Service"

                # Install Teams
                if (-not [string]::IsNullOrWhiteSpace($TeamsBootStrapperUrl)) {
                    Write-host "AVD AIB Customization: Teams Optimization - Requested to install Teams 2.0"

                    # Allow side-loading for trusted apps
                    New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows" -Name "Appx" -Force -ErrorAction Ignore
                    New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\Appx" -Name "AllowAllTrustedApps" -Value 1 -force
                    New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\Appx" -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -force

                    # https://learn.microsoft.com/en-us/microsoftteams/new-teams-troubleshooting-installation#windows-10-users-can-receive-an-error-message
                    Write-host "AVD AIB Customization: Teams Optimization - Starting to install WebView2"
                    $EdgeWebView = Join-Path -Path $LocalPath -ChildPath 'WebView.exe'
                    $webviewUrl = "https://go.microsoft.com/fwlink/p/?LinkId=2124703"
                    Invoke-WebRequest -Uri $webviewUrl -OutFile $EdgeWebView
                    Start-Process -FilePath $EdgeWebView -NoNewWindow -Wait -ArgumentList "/silent /install"

                    Write-host "AVD AIB Customization: Teams Optimization - Finished the installation of Edge WebView2"

                    Write-host "AVD AIB Customization: Teams Optimization - Using teams bootstrapper to install Teams 2.0"
                    $teamsBootStrapperPath = Join-Path -Path $LocalPath -ChildPath 'teamsbootstrapper.exe'
                    Invoke-WebRequest -Uri $TeamsBootStrapperUrl -OutFile $teamsBootStrapperPath
                    Start-Process -FilePath $teamsBootStrapperPath -Wait -ArgumentList "-p" -NoNewWindow 

                    Write-host "AVD AIB Customization: Teams Optimization - Finished installation of Teams"

                    $provisionedPackages = Get-AppxProvisionedPackage -Online
                    $isTeamsInstalled = $provisionedPackages | Where-Object { $_.PackageName -like '*MSTeams*8wekyb3d8bbwe' }

                    if ($isTeamsInstalled) {
                        Write-Host "AVD AIB Customization: Teams Optimization - Get-AppxProvisionedPackage returned MSTeams."
                    } else {
                        Write-Host "AVD AIB Customization: Teams Optimization - Get-AppxProvisionedPackage did not return MSTeams."
                    }
                } 
                else {
                    Write-host "AVD AIB Customization: Teams Optimization - Requested to install Teams 1.0"
                    $teamsMsi = 'teams.msi'
                    $outputPath = $LocalPath + '\' + $teamsMsi
                    Invoke-WebRequest -Uri $TeamsDownloadLink -OutFile $outputPath
                    Start-Process -FilePath msiexec.exe -Args "/I $outputPath /quiet /norestart /log teams.log ALLUSER=1 ALLUSERS=1" -Wait
                    Write-host "AVD AIB Customization: Teams Optimization - Finished installation of Teams"
                }
            }
            catch {
                Write-Host "*** AVD AIB CUSTOMIZER PHASE ***  Teams Optimization  - Exception occured  *** : [$($_.Exception.Message)]"
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
            Write-Host "*** AVD AIB CUSTOMIZER PHASE : Teams Optimization -  Exit Code: $LASTEXITCODE ***"    
            Write-Host "Ending AVD AIB Customization : Teams Optimization - Time taken: $elapsedTime"
        }
 }

function Set-RegKey($registryPath, $registryKey, $registryValue) {
    try {
         Write-Host "*** AVD AIB CUSTOMIZER PHASE ***  Teams Optimization  - Setting  $registryKey with value $registryValue ***"
         New-ItemProperty -Path $registryPath -Name $registryKey -Value $registryValue -PropertyType DWORD -Force -ErrorAction Stop
    }
    catch {
         Write-Host "*** AVD AIB CUSTOMIZER PHASE ***  Teams Optimization  - Cannot add the registry key  $registryKey *** : [$($_.Exception.Message)]"
    }
 }

InstallTeamsOptimizationforAVD -TeamsDownloadLink $TeamsDownloadLink -VCRedistributableLink $VCRedistributableLink -WebRTCInstaller $WebRTCInstaller -TeamsBootStrapperUrl $TeamsBootStrapperUrl

 