<#
.SYNOPSIS
Deploys RD Infra agent into target VM

.DESCRIPTION
This script will get the registration token for the target pool name, copy the installer into target VM and execute the installer with the registration token and broker URI

If the pool name is not specified it will retreive first one (treat this as random) from the deployment.

.PARAMETER ComputerName
Required the FQDN or IP of target VM

.PARAMETER AgentInstallerFolder
Required path to MSI installer file

.PARAMETER AgentBootServiceInstallerFolder
Required path to MSI installer file

.PARAMETER Session
Optional Powershell session into target VM

.PARAMETER StartAgent
Start the agent service (RdInfraAgent) immediately

.EXAMPLE

.\DeployAgent.ps1 -AgentInstallerFolder '.\RDInfraAgentInstall\' -AgentBootServiceInstallerFolder '.\RDAgentBootLoaderInstall\'" 
#>
#Requires -Version 4.0

Param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$AgentInstallerFolder,
    
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$AgentBootServiceInstallerFolder,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$RegistrationToken,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [bool]$StartAgent
)

function Test-IsAdmin {
    ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Convert relative paths to absolute paths if needed
Write-Output "Boot loader folder is $AgentBootServiceInstallerFolder"
$AgentBootServiceInstaller = (dir $AgentBootServiceInstallerFolder\ -Filter *.msi | Select-Object).FullName
if ((-not $AgentBootServiceInstaller) -or (-not (Test-Path $AgentBootServiceInstaller)))
{
    throw "RD Infra Agent Installer package is not found '$AgentBootServiceInstaller'"
}

# Convert relative paths to absolute paths if needed
Write-Output "Agent folder is $AgentInstallerFolder"
$AgentInstaller = (dir $AgentInstallerFolder\ -Filter *.msi | Select-Object).FullName
if ((-not $AgentInstaller) -or (-not (Test-Path $AgentInstaller)))
{
    throw "RD Infra Agent Installer package is not found '$AgentInstaller'"
}

if (!$RegistrationToken)
{
    throw "No registration token specified"
}

# Uninstalling previous versions of RDAgentBootLoader
Write-Output "Uninstalling any previous versions of RDAgentBootLoader on VM`n"
$bootloader_uninstall_status = Start-Process -FilePath "msiexec.exe" -ArgumentList "/x {A38EE409-424D-4A0D-B5B6-5D66F20F62A5}", "/quiet", "/qn", "/norestart", "/passive", "/l* C:\Users\AgentBootLoaderInstall.txt" -Wait -Passthru
$sts = $bootloader_uninstall_status.ExitCode
Write-Output "Uninstalling RD Infra Agent on VM Complete. Exit code=$sts`n"

# Uninstalling previous versions of RDInfraAgent
Write-Output "Uninstalling any previous versions of RD Infra Agent on VM"
$legacy_agent_uninstall_status = Start-Process -FilePath "msiexec.exe" -ArgumentList "/x {5389488F-551D-4965-9383-E91F27A9F217}", "/quiet", "/qn", "/norestart", "/passive", "/l* C:\Users\AgentUninstall.txt" -Wait -Passthru
$sts = $legacy_agent_uninstall_status.ExitCode
Write-Output "Uninstalling RD Infra Agent on VM Complete. Exit code=$sts`n"

# Uninstalling previous versions of RDInfraAgent DLLs
Write-Output "Uninstalling any previous versions of RD Infra Agent DLL on VM"
$agent_uninstall_status = Start-Process -FilePath "msiexec.exe" -ArgumentList "/x {CB1B8450-4A67-4628-93D3-907DE29BF78C}", "/quiet", "/qn", "/norestart", "/passive", "/l* C:\Users\AgentUninstall.txt" -Wait -Passthru
$sts = $agent_uninstall_status.ExitCode
Write-Output "Uninstalling RD Infra Agent on VM Complete. Exit code=$sts`n"    

#install the package
Write-Output "Installing RDAgent BootLoader on VM $AgentBootServiceInstaller"

$bootloader_deploy_status = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $AgentBootServiceInstaller", "/quiet", "/qn", "/norestart", "/passive", "/l* C:\Users\AgentBootLoaderInstall.txt" -Wait -Passthru
$sts = $bootloader_deploy_status.ExitCode
Write-Output "Installing RDAgentBootLoader on VM Complete. Exit code=$sts`n"

#install the package
Write-Output "Installing RD Infra Agent on VM $AgentInstaller`n"

$agent_deploy_status = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $AgentInstaller", "/quiet", "/qn", "/norestart", "/passive", "REGISTRATIONTOKEN=$RegistrationToken", "/l* C:\Users\AgentInstall.txt" -Wait -Passthru
$sts = $agent_deploy_status.ExitCode
Write-Output "Installing RD Infra Agent on VM Complete. Exit code=$sts`n"

if ($StartAgent)
{
    write-output "Starting service"
    Start-Service RDAgentBootLoader
}

$agent_deploy_status = $agent_deploy_status.ExitCode
