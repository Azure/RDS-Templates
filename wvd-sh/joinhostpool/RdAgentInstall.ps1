param(
      [string]$registrationToken
)

#Extract MSIs
Expand-Archive -path .\Agents.zip 
$msiFile =  Get-ChildItem .\Agents -name 'Microsoft.RDInfra.RDAgent*'

write-host "Installing RDAgent..."
msiexec /i ".\Agent\$msiFile" /passive REGISTRATIONTOKEN=$registrationToken

write-host "Verifiying RDAgent registry keys"
if ((Test-Path -Path "HKLM:\SOFTWARE\Microsoft\RDInfraAgent") -eq $false) {(Start-Sleep -s 60)} ELSE {write-host "RDinfraAgent Registry entry found"}
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\RDInfraAgent"

write-host "Installing BootLoader..."
msiexec /i ".\Atent\Microsoft.RDInfra.RDAgentBootLoader.Installer-x64.msi" /passive
if ((Test-Path -Path "HKLM:\SOFTWARE\Microsoft\RDAgentBootLoader") -eq $false) {(Start-Sleep -s 60)} ELSE {write-host "RDAgentBootLoader Registry entry found"}
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\RDAgentBootLoader"

write-host "Installation completed"


