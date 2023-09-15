<#Author       : Akash Chawla
# Usage        : RDP Shortpath
#>

#######################################
#    RDP Shortpath            #
#######################################


# Reference: https://docs.microsoft.com/en-us/azure/virtual-desktop/shortpath

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
write-host 'AVD AIB Customization: Configure RDP shortpath and Windows Defender Firewall'

# rdp shortpath reg key
$WinstationsKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations'

$regKeyName = "fUseUdpPortRedirector"
$regKeyValue = "1"

$portName = "UdpPortNumber"
$portValue = "3390"


IF(!(Test-Path $WinstationsKey)) {
    New-Item -Path $WinstationsKey -Force | Out-Null
}

try {
    New-ItemProperty -Path $WinstationsKey -Name $regKeyName -ErrorAction:SilentlyContinue -PropertyType:dword -Value $regKeyValue -Force | Out-Null
    New-ItemProperty -Path $WinstationsKey -Name $portName -ErrorAction:SilentlyContinue -PropertyType:dword -Value $portValue -Force | Out-Null
}
catch {
    Write-Host "*** AVD AIB CUSTOMIZER PHASE *** RDP Shortpath - Cannot add the registry key *** : [$($_.Exception.Message)]"
    Write-Host "Message: [$($_.Exception.Message)"]
}

# set up windows defender firewall

try {
    New-NetFirewallRule -DisplayName 'Remote Desktop - Shortpath (UDP-In)'  -Action Allow -Description 'Inbound rule for the Remote Desktop service to allow RDP traffic. [UDP 3390]' -Group '@FirewallAPI.dll,-28752' -Name 'RemoteDesktop-UserMode-In-Shortpath-UDP'  -PolicyStore PersistentStore -Profile Domain, Private -Service TermService -Protocol udp -LocalPort 3390 -Program '%SystemRoot%\system32\svchost.exe' -Enabled:True
}
catch {
    Write-Host "*** AVD AIB CUSTOMIZER PHASE *** Cannot create firewall rule *** : [$($_.Exception.Message)]"
}
 

$stopwatch.Stop()
$elapsedTime = $stopwatch.Elapsed
Write-Host "*** AVD AIB CUSTOMIZER PHASE : Configure RDP shortpath and Windows Defender Firewall  - Exit Code: $LASTEXITCODE ***"
Write-Host "*** AVD AIB CUSTOMIZER PHASE: Configure RDP shortpath and Windows Defender Firewall - Time taken: $elapsedTime ***"
 
#############
#    END    #
#############