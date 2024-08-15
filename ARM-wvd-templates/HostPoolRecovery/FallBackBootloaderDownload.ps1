$bootloaderKeyPath = "HKLM:\SOFTWARE\Microsoft\RDAgentBootLoader"
$backupBootloaderKeyPath = "HKLM:\SOFTWARE\Microsoft\RDAgentBootLoader_Backup"

$agentKeyPath = "HKLM:\SOFTWARE\Microsoft\RDInfraAgent"
$backupAgentKeyPath = "HKLM:\SOFTWARE\Microsoft\RDInfraAgent_Backup"

if (Test-Path $backupBootloaderKeyPath) {
    Write-Output "Removing backup bootloader registry keys"
    Remove-Item -Path $backupBootloaderKeyPath -Recurse -Force
}

if (Test-Path $backupAgentKeyPath) {
    Write-Output "Removing backup agent registry keys"
    Remove-Item -Path $backupAgentKeyPath -Recurse -Force
}

if (Test-Path $bootloaderKeyPath) {
   Copy-Item -Path $bootloaderKeyPath -Destination $backupBootloaderKeyPath -Force -Recurse
}

if (Test-Path $agentKeyPath) {
   Copy-Item -Path $agentKeyPath -Destination $backupAgentKeyPath -Force -Recurse
}

# uninstall all rdagentbootloaders
# gets all subkeys under registry key path Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
$uninstallKeys = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | ForEach-Object { Get-ItemProperty $_.PsPath }
# for each uninstallKey in uninstallKeys, check if the DisplayName key equals "Remote Desktop Agent Boot Loader"
Write-Output "Attempting to uninstall every bootloader"
foreach ($uninstallKey in $uninstallKeys) {
    if ($uninstallKey.DisplayName -eq "Remote Desktop Agent Boot Loader") {
		# get the UninstallString key value
		$productId = $uninstallKey.PSChildName
		# uninstall the Remote Desktop Agent Boot Loader
        Write-Output "Uninstalling $productId"
        # run msiexec.exe /X $productId
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/X $productId /quiet /qn /norestart" -Wait
    }
}

# verify that the registry key Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDAgentBootLoader does not exist
if (Test-Path "HKLM:\SOFTWARE\Microsoft\RDAgentBootLoader") {
    # log a warning that the reg key still exists
    Write-Output "The registry key Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDAgentBootLoader still exists. Attempting to remove it."
	# remove the registry key Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDAgentBootLoader
    Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\RDAgentBootLoader" -Recurse
}

Write-Output "Attempting to extract configuration zip"
# unzip the file that starts wtih .\Configuration_*
Expand-Archive -Path ".\Configuration_*" -DestinationPath "C:\Program Files\Microsoft RDInfra\ConfigurationZip" -Force

Write-Output "Attempting to extract DeployAgent.zip"
# unzip DeployAgent.zip located in C:\Program Files\Microsoft RDInfra\ConfigurationZip\DeployAgent.zip
Expand-Archive -Path "C:\Program Files\Microsoft RDInfra\ConfigurationZip\DeployAgent.zip" -DestinationPath "C:\Program Files\Microsoft RDInfra\ConfigurationZip\DeployAgent" -Force

# install the RDAgentBootloader* msi located in C:\Program Files\Microsoft RDInfra\ConfigurationZip\DeployAgent\
$msiFiles = Get-ChildItem -Path "C:\Program Files\Microsoft RDInfra\ConfigurationZip\DeployAgent\RDAgentBootLoaderInstall" -Filter "*RDAgentBootloader*.msi"
foreach ($msiFile in $msiFiles) 
{
    Write-Output "Attempting to install the msi $msiFile"
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i ""$($msiFiles.FullName)"" /quiet /qn /norestart " -Wait 
}

# copy default agent because we need to in order to load the agent
if (Test-Path $backupBootloaderKeyPath) {
    $currentBootloader = Get-ItemProperty -Path $bootloaderKeyPath -Name CurrentBootLoaderVersion
    Write-Output "Removing bootloader registry keys"
    Remove-Item -Path $bootloaderKeyPath -Recurse -Force
    Write-Output "Copying backup bootloader keys to bootloader keys"
    Copy-Item -Path $backupBootloaderKeyPath -Destination $bootloaderKeyPath -Force -Recurse
    # set $bootloaderKeyPath\CurrentBootLoaderVersion to $currentBootloader
    Write-Output "Setting current bootloader version to $currentBootloader"
    Set-ItemProperty -Path $bootloaderKeyPath -Name CurrentBootLoaderVersion -Value $currentBootloader.CurrentBootLoaderVersion
}

# reset agent reg keys
if (Test-Path $agentKeyPath) {
    Write-Output "Copying backup agent keys to agent keys"
    Copy-Item -Path $backupAgentKeyPath -Destination $agentKeyPath -Force -Recurse
}

if (Test-Path $backupBootloaderKeyPath) {
    Write-Output "Removing backup bootloader registry keys"
    Remove-Item -Path $backupBootloaderKeyPath -Recurse -Force
}

if (Test-Path $backupAgentKeyPath) {
    Write-Output "Removing backup agent registry keys"
    Remove-Item -Path $backupAgentKeyPath -Recurse -Force
}
