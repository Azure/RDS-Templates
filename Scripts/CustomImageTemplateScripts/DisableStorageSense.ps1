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

IF(!(Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force
}

try {
    New-ItemProperty -Path $registryPath -Name $registryKey -Value $registryValue -PropertyType DWORD -Force -ErrorAction Stop
}
catch {
     Write-Host "*** AVD AIB CUSTOMIZER PHASE *** Disable Storage Sense - Cannot add the registry key $registryKey *** : [$($_.Exception.Message)]"
     Write-Host "Message: [$($_.Exception.Message)"]
}

$stopwatch.Stop()
$elapsedTime = $stopwatch.Elapsed
Write-Host "*** AVD AIB CUSTOMIZER PHASE: Disable Storage Sense - Exit Code: $LASTEXITCODE ***"
Write-Host "*** Ending AVD AIB CUSTOMIZER PHASE: Disable Storage Sense - Time taken: $elapsedTime "

#############
#    END    #
#############