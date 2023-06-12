<#Author       : Akash Chawla
# Usage        : Screen capture protection
#>

#######################################
#     Screen capture protection       #
#######################################

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
Write-Host '*** AVD AIB CUSTOMIZER PHASE: Screen capture protection ***'

$screenCaptureRegistryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
$screenCaptureRegistryName = "fEnableScreenCaptureProtection"
$screenCaptureRegistryValue = "1"

IF(!(Test-Path $screenCaptureRegistryPath)) {
    New-Item -Path $screenCaptureRegistryPath -Force | Out-Null
}

try {
    New-ItemProperty -Path $screenCaptureRegistryPath -Name $screenCaptureRegistryName -Value $screenCaptureRegistryValue -PropertyType DWORD -Force | Out-Null
}
catch {
    Write-Host "*** AVD AIB CUSTOMIZER PHASE:  Screen capture protection - Cannot add the registry key *** : [$($_.Exception.Message)]"
    Write-Host "Message: [$($_.Exception.Message)"]
}


$stopwatch.Stop()
$elapsedTime = $stopwatch.Elapsed
Write-Host "*** AVD AIB CUSTOMIZER PHASE: Screen capture protection - Exit Code: $LASTEXITCODE ***"
Write-Host "*** AVD AIB CUSTOMIZER PHASE: Screen capture protection - Time taken: $elapsedTime ***"


#############
#    END    #
#############