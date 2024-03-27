<#Author       : Akash Chawla
# Usage        : Screen capture protection
#>

#######################################
#     Screen capture protection       #
#######################################
[CmdletBinding()]
  Param (
        [Parameter(Mandatory=$false)]
        [string] $BlockOption
 )

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
Write-Host '*** AVD AIB CUSTOMIZER PHASE: Screen capture protection ***'

$screenCaptureRegistryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
$screenCaptureRegistryName = "fEnableScreenCaptureProtect"

# by default, block both client and server - registry value 2 refers to block both client and server
$screenCaptureRegistryValue = "2" 

if(($PSBoundParameters.ContainsKey('BlockOption'))) {
    if($BlockOption -eq "BlockClient") {
        # registry value 1 refers to block only client
        $screenCaptureRegistryValue = "1"  
    } 
    else {
        $screenCaptureRegistryValue = "2"
    }
}

IF(!(Test-Path $screenCaptureRegistryPath)) {
    New-Item -Path $screenCaptureRegistryPath -Force | Out-Null
}

try {
    Write-Host "*** AVD AIB CUSTOMIZER PHASE ***  Screen capture protection - Setting  $screenCaptureRegistryName with value $screenCaptureRegistryValue ***"
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