<#

.SYNOPSIS
Creating Hostpool and add sessionhost servers to existing/new Hostpool.

.DESCRIPTION
This script add sessionhost servers to existing/new Hostpool
The supported Operating Systems Windows Server 2016.

.ROLE
Readers

#>
param(
    [Parameter(mandatory = $true)]
    [string]$RDBrokerURL,

    [Parameter(mandatory = $true)]
    [string]$definedTenantGroupName,

    [Parameter(mandatory = $true)]
    [string]$TenantName,

    [Parameter(mandatory = $true)]
    [string]$HostPoolName,

    [Parameter(mandatory = $false)]
    [string]$Description,

    [Parameter(mandatory = $false)]
    [string]$FriendlyName,

    [Parameter(mandatory = $true)]
    [string]$Hours,

    [Parameter(mandatory = $true)]
    [PSCredential]$TenantAdminCredentials,

    [Parameter(mandatory = $false)]
    [string]$isServicePrincipal = "False",

    [Parameter(Mandatory = $false)]
    [AllowEmptyString()]
    [string]$AadTenantId="",

    [Parameter(Mandatory = $false)]
    [string]$EnablePersistentDesktop="False",

    [Parameter(Mandatory = $false)]
    [string]$DefaultDesktopUsers=""
)

$ScriptPath = [system.io.path]::GetDirectoryName($PSCommandPath)

# Dot sourcing Functions.ps1 file
. (Join-Path $ScriptPath "Functions.ps1")

# Setting ErrorActionPreference to stop script execution when error occurs
$ErrorActionPreference = "Stop"

# Testing if it is a ServicePrincipal and validade that AadTenant ID in this case is not null or empty
ValidateServicePrincipal -IsServicePrincipal $isServicePrincipal -AadTenantId $AadTenantId

Write-Log -Message "Identifying if this VM is Build >= 1809"
$rdshIs1809OrLaterBool = Is1809OrLater

Write-Log -Message "Creating a folder inside rdsh vm for extracting deployagent zip file"
$DeployAgentLocation = "C:\DeployAgent"
ExtractDeploymentAgentZipFile -ScriptPath $ScriptPath -DeployAgentLocation $DeployAgentLocation

Write-Log -Message "Changing current folder to Deployagent folder: $DeployAgentLocation"
Set-Location "$DeployAgentLocation"

# Checking if RDInfragent is registered or not in rdsh vm
$CheckRegistry = Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent" -ErrorAction SilentlyContinue

Write-Log -Message "Checking whether VM was Registered with RDInfraAgent"

if ($CheckRegistry)
{
    Write-Log -Message "VM was already registered with RDInfraAgent, script execution was stopped"
}
else
{
    Write-Log -Message "VM not registered with RDInfraAgent, script execution will continue"

    # Executing DeployAgent psl file in rdsh vm and add to hostpool
    Write-Log "AgentInstaller is $DeployAgentLocation\RDAgentBootLoaderInstall, InfraInstaller is $DeployAgentLocation\RDInfraAgentInstall, SxS is $DeployAgentLocation\RDInfraSxSStackInstall"
    $DAgentInstall = .\DeployAgent.ps1 -AgentBootServiceInstallerFolder "$DeployAgentLocation\RDAgentBootLoaderInstall" `
                                       -AgentInstallerFolder "$DeployAgentLocation\RDInfraAgentInstall" `
                                       -SxSStackInstallerFolder "$DeployAgentLocation\RDInfraSxSStackInstall" `
                                       -EnableSxSStackScriptFolder "$DeployAgentLocation\EnableSxSStackScript" `
                                       -RegistrationToken "eyJhbGciOiJSUzI1NiIsImtpZCI6IkRPU0d3RExqdTVPWWhxV2JBclUxd19GTzYwbyIsInR5cCI6IkpXVCJ9.eyJSZWdpc3RyYXRpb25JZCI6IjRkMmNlMzRiLTU2NjYtNGI5MS04NTYzLTc2NDRkY2MxYTUwMCIsIkJyb2tlclVyaSI6Imh0dHBzOi8vbXJzLXNjdXNyMGMwMDEtcmRicm9rZXItc2FtcGEuYXp1cmV3ZWJzaXRlcy5uZXQvIiwiRGlhZ25vc3RpY3NVcmkiOiJodHRwczovL21ycy1zY3VzcjBjMDAxLXJkZGlhZ25vc3RpY3Mtc2FtcGEuYXp1cmV3ZWJzaXRlcy5uZXQvIiwibmJmIjoxNTU1MDg5NzUyLCJleHAiOjE1NjkwNzQ1MTQsImlzcyI6IlJESW5mcmFUb2tlbk1hbmFnZXIiLCJhdWQiOiJSRG1pIn0.G2VbV_bUfV1cm03pQB-BWUqDiyhhOzqhb_i02u0v8mh1EjRO_srck_kUJm6EoBF22EK0uvV83UTE_zK5_jlPv2ymE7Etj7P-24PY6n3a85E6cK2kEC-hxuBECzozGh1eUnZiIxGJTRwsOW6VT8ONlhvqID-MDmyVO5CrtfkCmAYlttGNtqf4Y0A56uO9Z3mAQqqdqw2aX65utKowTUm8FV36FDU8g-XrZV3tKY7z9vlNQtHjVHVSlOoXwkdwKb_TSONytOD2lGcqqEbJ2cqm7MZ9XaHaB0nZ2NcZyR8o-j_5OcyS6LL4mF5utaj_mOdODIu0aVmE3k_CvZtrMdyLZQ" `
                                       -StartAgent $true `
                                       -rdshIs1809OrLater $rdshIs1809OrLaterBool
    
    Write-Log -Message "DeployAgent Script was successfully executed and RDAgentBootLoader,RDAgent,StackSxS installed inside VM for existing hostpool: $HostPoolName`n$DAgentInstall"
   
    Write-Log -Message "Successfully added $rdshName VM to $poolName"
}