<#

.SYNOPSIS
Set up a VM as session host to existing/new host pool.

.DESCRIPTION
This script installs RD agent and verify that it is successfully registered as session host to existing/new host pool.

#>
param(
    [Parameter(mandatory = $true)]
    [string]$HostPoolName,

    [Parameter(Mandatory = $true)]
    [string]$RegistrationInfoToken,

    [Parameter(Mandatory = $false)]
    [bool]$AadJoin = $false,

    [Parameter(Mandatory = $false)]
    [string]$SessionHostConfigurationLastUpdateTime = "",

    [Parameter(mandatory = $false)] 
    [switch]$EnableVerboseMsiLogging
)

$ScriptPath = [system.io.path]::GetDirectoryName($PSCommandPath)

# Dot sourcing Functions.ps1 file
. (Join-Path $ScriptPath "Functions.ps1")
. (Join-Path $ScriptPath "AvdFunctions.ps1")

# Setting ErrorActionPreference to stop script execution when error occurs
$ErrorActionPreference = "Stop"

# Checking if RDInfragent is registered or not in rdsh vm
Write-Log -Message "Checking whether VM was Registered with RDInfraAgent"
$RegistryCheckObj = IsRDAgentRegistryValidForRegistration

if ($RegistryCheckObj.result)
{
    Write-Log -Message "VM was already registered with RDInfraAgent, script execution was stopped"
}
else
{
    Write-Log -Message "Creating a folder inside rdsh vm for extracting deployagent zip file"
    $DeployAgentLocation = "C:\DeployAgent"
    ExtractDeploymentAgentZipFile -ScriptPath $ScriptPath -DeployAgentLocation $DeployAgentLocation

    Write-Log -Message "Changing current folder to Deployagent folder: $DeployAgentLocation"
    Set-Location "$DeployAgentLocation"

    Write-Log -Message "VM not registered with RDInfraAgent, script execution will continue"

    Write-Log "AgentInstaller is $DeployAgentLocation\RDAgentBootLoaderInstall, InfraInstaller is $DeployAgentLocation\RDInfraAgentInstall"

    InstallRDAgents -AgentBootServiceInstallerFolder "$DeployAgentLocation\RDAgentBootLoaderInstall" -AgentInstallerFolder "$DeployAgentLocation\RDInfraAgentInstall" -RegistrationToken $RegistrationInfoToken -EnableVerboseMsiLogging:$EnableVerboseMsiLogging

    Write-Log -Message "The agent installation code was successfully executed and RDAgentBootLoader, RDAgent installed inside VM for existing hostpool: $HostPoolName"
}

Write-Log -Message "Session Host Configuration Last Update Time: $SessionHostConfigurationLastUpdateTime"
$rdInfraAgentRegistryPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent"
if (Test-path $rdInfraAgentRegistryPath) {
    Write-Log -Message ("Write SessionHostConfigurationLastUpdateTime '$SessionHostConfigurationLastUpdateTime' to $rdInfraAgentRegistryPath")
    Set-ItemProperty -Path $rdInfraAgentRegistryPath -Name "SessionHostConfigurationLastUpdateTime" -Value $SessionHostConfigurationLastUpdateTime
}

if ($AadJoin) {
    # 6 Minute sleep to guarantee intune metadata logging
    Write-Log -Message ("Configuration.ps1 complete, sleeping for 6 minutes")
    Start-Sleep -Seconds 360
    Write-Log -Message ("Configuration.ps1 complete, waking up from 6 minute sleep")
}

$SessionHostName = GetAvdSessionHostName
Write-Log -Message "Successfully registered VM '$SessionHostName' to HostPool '$HostPoolName'"