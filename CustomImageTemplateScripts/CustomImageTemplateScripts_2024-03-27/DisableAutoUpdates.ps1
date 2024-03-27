<#Author       : Akash Chawla
# Usage        : Disable auto updates for MSIX app attach applications
#>

#############################################
#        Disable auto updates               #
#############################################

function Set-RegKey($registryPath, $registryKey, $registryValue) {
    try {
        IF(!(Test-Path $registryPath)) {
            New-Item -Path $registryPath -Force
        }

        Write-Host "*** AVD AIB CUSTOMIZER PHASE ***  Disable auto updates for MSIX AA applications - Setting  $registryKey with value $registryValue ***"
        New-ItemProperty -Path $registryPath -Name $registryKey -Value $registryValue -PropertyType DWORD -Force -ErrorAction Stop
    }
    catch {
         Write-Host "*** AVD AIB CUSTOMIZER PHASE ***   Disable Storage Sense  - Cannot add the registry key  $registryKey *** : [$($_.Exception.Message)]"
    }
 }

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
Write-Host "***Starting AVD AIB CUSTOMIZER PHASE: Disable auto updates for MSIX AA applications -  $((Get-Date).ToUniversalTime()) "

Set-RegKey -registryPath "HKLM\Software\Policies\Microsoft\WindowsStore" -registryKey "AutoDownload" -registryValue "2"
Set-RegKey -registryPath "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -registryKey "PreInstalledAppsEnabled" -registryValue "0"
Set-RegKey -registryPath "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\Debug" -registryKey "ContentDeliveryAllowedOverride" -registryValue "0x2"

Disable-ScheduledTask -TaskPath "\Microsoft\Windows\WindowsUpdate\" -TaskName "Scheduled Start"

$stopwatch.Stop()
$elapsedTime = $stopwatch.Elapsed
Write-Host "*** AVD AIB CUSTOMIZER PHASE: Disable auto updates for MSIX AA applications - Exit Code: $LASTEXITCODE ***"
Write-Host "*** Ending AVD AIB CUSTOMIZER PHASE: Disable auto updates for MSIX AA applications - Time taken: $elapsedTime "

#############
#    END    #
#############
