<#

.SYNOPSIS
add an instance to hostpool.

.DESCRIPTION
This script will add an instance to existing hostpool based on a registration token.
The supported Operating Systems Windows Server 2016/windows 10 multisession.

.ROLE
Readers

#>
param(
    [Parameter(mandatory = $true)]
    [string]$Token,

    [Parameter(mandatory = $false)]
    [string]$RDPSModSource = 'attached'
)

$ScriptPath = [System.IO.Path]::GetDirectoryName($PSCommandPath)

# Dot sourcing Functions.ps1 file
. (Join-Path $ScriptPath "Functions.ps1")

# Setting ErrorActionPreference to stop script execution when error occurs
$ErrorActionPreference = "Stop"

write-log -message 'Script being executed: Register session host'

Write-Log -Message "Creating a folder inside rdsh vm for extracting deployagent zip file"
$DeployAgentLocation = "C:\DeployAgent"
ExtractDeploymentAgentZipFile -ScriptPath $ScriptPath -DeployAgentLocation $DeployAgentLocation

Write-Log -Message "Changing current folder to Deployagent folder: $DeployAgentLocation"
Set-Location "$DeployAgentLocation"

ImportRDPSMod -Source $RDPSModSource -ArtifactsPath $ScriptPath

# Getting fqdn (session host name) of rdsh vm
$SessionHostName = GetCurrSessionHostName
Write-Log -Message "Getting fully qualified domain name of RDSH VM: $SessionHostName"

# Executing DeployAgent ps1 file in rdsh vm and add to hostpool
Write-Log "AgentInstaller is $DeployAgentLocation\RDAgentBootLoaderInstall, InfraInstaller is $DeployAgentLocation\RDInfraAgentInstall"

$DAgentInstall = .\DeployAgent.ps1 -AgentBootServiceInstallerFolder "$DeployAgentLocation\RDAgentBootLoaderInstall" `
    -AgentInstallerFolder "$DeployAgentLocation\RDInfraAgentInstall" `
    -RegistrationToken $Token `
    -StartAgent $true

Write-Log -Message "DeployAgent Script was successfully executed and RDAgentBootLoader, RDAgent were installed inside VM:`n$DAgentInstall"

Write-Log -Message "It may take a about a min for the session host to become available but it might take longer for larger deployments because of API calls throttling"

Write-log -Message "Use command 'Get-RdsSessionHost -TenantName 'TenantName' -HostPoolName 'HostPoolName' -Name $SessionHostName' to check if it succeeded"