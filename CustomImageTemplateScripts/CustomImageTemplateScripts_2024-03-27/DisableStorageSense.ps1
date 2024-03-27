<#Author       : Akash Chawla
# Usage        : Disable Storage Sense
#>

#######################################
#    Disable Storage Sense            #
#######################################

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
Write-Host "***Starting AVD AIB CUSTOMIZER PHASE: Disable Storage Sense Start -  $((Get-Date).ToUniversalTime()) "

$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense"
$registryKey = "AllowStorageSenseGlobal"
$registryValue = "0"

$registryPathWin11 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\StorageSense"

IF(!(Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force
}

IF(!(Test-Path $registryPathWin11)) {
    New-Item -Path $registryPathWin11 -Force
}

Set-RegKey -registryPath $registryPath -registryKey $registryKey -registryValue $registryValue
Set-RegKey -registryPath $registryPathWin11 -registryKey $registryKey -registryValue $registryValue

$stopwatch.Stop()
$elapsedTime = $stopwatch.Elapsed
Write-Host "*** AVD AIB CUSTOMIZER PHASE: Disable Storage Sense - Exit Code: $LASTEXITCODE ***"
Write-Host "*** Ending AVD AIB CUSTOMIZER PHASE: Disable Storage Sense - Time taken: $elapsedTime "

function Set-RegKey($registryPath, $registryKey, $registryValue) {
    try {
         Write-Host "*** AVD AIB CUSTOMIZER PHASE ***  Disable Storage Sense - Setting  $registryKey with value $registryValue ***"
         New-ItemProperty -Path $registryPath -Name $registryKey -Value $registryValue -PropertyType DWORD -Force -ErrorAction Stop
    }
    catch {
         Write-Host "*** AVD AIB CUSTOMIZER PHASE ***   Disable Storage Sense  - Cannot add the registry key  $registryKey *** : [$($_.Exception.Message)]"
    }
 }

#############
#    END    #
#############