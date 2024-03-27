<#Author       : Akash Chawla
# Usage        : Configure session timeouts
#>

#######################################
#   Configure session timeouts        #
#######################################


[CmdletBinding()]
  Param (
        [Parameter(Mandatory=$false)]
        [string] $MaxDisconnectionTime,

        [Parameter(Mandatory=$false)]
        [string] $MaxIdleTime,

        [Parameter(Mandatory=$false)]
        [string] $MaxConnectionTime,

        [Parameter(Mandatory=$false)]
        [string] $RemoteAppLogoffTimeLimit,

        [Parameter(Mandatory=$false)]
        [string] $fResetBroken
 )

 
 function ConvertToMilliSecond($timeInMinutes) {
    return (60 * 1000 * $timeInMinutes)
 }

 function Set-RegKey($registryPath, $registryKey, $registryValue) {
    try {
         Write-Host "*** AVD AIB CUSTOMIZER PHASE *** Configure session timeouts - Setting  $registryKey with value $registryValue ***"
         New-ItemProperty -Path $registryPath -Name $registryKey -Value $registryValue -PropertyType DWORD -Force -ErrorAction Stop
    }
    catch {
         Write-Host "*** AVD AIB CUSTOMIZER PHASE *** Configure session timeouts - Cannot add the registry key  $registryKey *** : [$($_.Exception.Message)]"
    }
 }

 $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

 $templateFilePathFolder = "C:\AVDImage"
 $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
 Write-host "Starting AVD AIB Customization: Configure session timeouts"

 IF(!(Test-Path $registryPath)) {
   New-Item -Path $registryPath -Force | Out-Null
 }

foreach($parameter in $PSBoundParameters.GetEnumerator()) {

    $registryKey = $parameter.Key

    if($registryKey.Equals("fResetBroken")) {
        $registryValue = "1"
        Set-RegKey -registryPath $registryPath -registryKey $registryKey -registryValue $registryValue
        break
    } 

    $registryValue = ConvertToMilliSecond -time $parameter.Value
    Set-RegKey -registryPath $registryPath -registryKey $registryKey -registryValue $registryValue
}

if ((Test-Path -Path $templateFilePathFolder -ErrorAction SilentlyContinue)) {
    Remove-Item -Path $templateFilePathFolder -Force -Recurse -ErrorAction Continue
}

$stopwatch.Stop()
$elapsedTime = $stopwatch.Elapsed
Write-Host "*** AVD AIB CUSTOMIZER PHASE: Configure session timeouts - Exit Code: $LASTEXITCODE ***"
Write-host "Ending AVD AIB Customization: Configure session timeouts - Time taken: $elapsedTime "

