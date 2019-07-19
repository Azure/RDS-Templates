param(
      [string]$registrationToken
)

#Extract MSIs
Expand-Archive -path .\Agents.zip 
$msiFile =  Get-ChildItem .\Agents -name 'Microsoft.RDInfra.RDAgent.Installer*'

write-host $msiFile

cd .\Agents

$execarg = @(
    "/i"
    "$msiFile"
    "/passive"
    "REGISTRATIONTOKEN=$registrationToken"
)

write-host "Installing RDAgent..."
Start-Process msiexec.exe -Wait -ArgumentList $execarg


write-host "Installing BootLoader..."
$execarg = @(
    "/i"
    "Microsoft.RDInfra.RDAgentBootLoader.Installer-x64.msi" 
    "/passive"
)
Start-Process msiexec.exe -Wait -ArgumentList $execarg

write-host "Agent Status:$((Get-Service rdagentbootloader).Status)"

write-host "Verifiying RDAgent registry keys"
if ((Test-Path -Path "HKLM:\SOFTWARE\Microsoft\RDInfraAgent") -eq $false) {(Start-Sleep -s 60)} ELSE {write-host "RDinfraAgent Registry entry found"}
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\RDInfraAgent"


if ((Test-Path -Path "HKLM:\SOFTWARE\Microsoft\RDAgentBootLoader") -eq $false) {(Start-Sleep -s 60)} ELSE {write-host "RDAgentBootLoader Registry entry found"}
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\RDAgentBootLoader"

write-host "Installation completed"


