<#Author       : Akash Chawla
# Usage        : Teams Optimization
#>

#######################################
#    Teams Optimization               #
#######################################

# Reference: https://learn.microsoft.com/en-us/azure/virtual-desktop/teams-on-avd

[CmdletBinding()]
  Param (
        [Parameter(Mandatory)]
        [string]$TeamsDownloadLink,

        [Parameter(
            Mandatory
        )]
        [string]$VCRedistributableLink,

        [Parameter(
            Mandatory
        )]
        [string]$WebRTCInstaller
)
 
 function InstallTeamsOptimizationforAVD($TeamsDownloadLink, $VCRedistributableLink, $WebRTCInstaller) {
   
        Begin {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $templateFilePathFolder = "C:\AVDImage"
            Write-host "Starting AVD AIB Customization: Teams Optimization : $((Get-Date).ToUniversalTime()) "
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
                $drive = 'C:\'
                New-Item -Path $drive -Name $appName  -ItemType Directory -ErrorAction SilentlyContinue
                $LocalPath = $drive + '\' + $appName 
                Set-Location $LocalPath
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

                #Install Teams
                $teamsMsi = 'teams.msi'
                $outputPath = $LocalPath + '\' + $teamsMsi
                Invoke-WebRequest -Uri $TeamsDownloadLink -OutFile $outputPath
                Start-Process -FilePath msiexec.exe -Args "/I $outputPath /quiet /norestart /log teams.log ALLUSER=1 ALLUSERS=1" -Wait
                Write-host "AVD AIB Customization: Teams Optimization - Finished installation of Teams"
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

InstallTeamsOptimizationforAVD -TeamsDownloadLink $TeamsDownloadLink -VCRedistributableLink $VCRedistributableLink -WebRTCInstaller $WebRTCInstaller
