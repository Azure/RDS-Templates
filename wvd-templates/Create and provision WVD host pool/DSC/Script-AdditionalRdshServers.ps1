﻿<#

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
    [string]$DefinedTenantGroupName,

    [Parameter(mandatory = $true)]
    [string]$TenantName,

    [Parameter(mandatory = $true)]
    [string]$HostPoolName,

    [Parameter(mandatory = $true)]
    [PSCredential]$TenantAdminCredentials,

    [Parameter(mandatory = $true)]
    [PSCredential]$ADAdminCredentials,

    [Parameter(mandatory = $false)]
    [string]$IsServicePrincipal = "False",

    [Parameter(Mandatory = $false)]
    [string]$AadTenantId
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

    # Importing WVD PowerShell module
    Import-Module .\PowershellModules\Microsoft.RDInfra.RDPowershell.dll

    Write-Log -Message "Imported RDMI PowerShell modules successfully"

    # Getting fqdn of rdsh vm
    $SessionHostName = (Get-WmiObject win32_computersystem).DNSHostName + "." + (Get-WmiObject win32_computersystem).Domain
    Write-Log  -Message "Getting fully qualified domain name of RDSH VM: $SessionHostName"

    # Performing WVD Authentication and Setting Context
    #AuthenticateOnWvd -IsServicePrincipal $isServicePrincipal -TenantAdminCredentials $TenantAdminCredentials -AadTenantId $AadTenantId -RDBrokerURL $RDBrokerURL -DefinedTenantGroupName $DefinedTenantGroupName -TenantName $TenantName

    # Authenticating to WVD
    if ($isServicePrincipal -eq "True")
    {
        Write-Log  -Message "Authenticating using service principal $TenantAdminCredentials.username and Tenant id: $AadTenantId "
        $authentication = Add-RdsAccount -DeploymentUrl $RDBrokerURL -Credential $TenantAdminCredentials -ServicePrincipal -TenantId $AadTenantId 
    }
    else
    {
        Write-Log  -Message "Authenticating using user $($TenantAdminCredentials.username) "
        $authentication = Add-RdsAccount -DeploymentUrl $RDBrokerURL -Credential $TenantAdminCredentials
    }

    Write-Log  -Message "Authentication object: $($authentication | Out-String)"
    $obj = $authentication | Out-String

    if ($authentication)
    {
        Write-Log -Message "RDMI Authentication successfully Done. Result:`n$obj"  
    }
    else
    {
        Write-Log -Error "RDMI Authentication Failed, Error:`n$obj"
        throw "RDMI Authentication Failed, Error:`n$obj"
    }

    # Set context to the appropriate tenant group
    Write-Log "Running switching to the $definedTenantGroupName context"
    Set-RdsContext -TenantGroupName $definedTenantGroupName
    try
    {
        $tenants = Get-RdsTenant -Name $TenantName
        if(!$tenants)
        {
            Write-Log "No tenants exist or you do not have proper access."
        }
    }
    catch
    {
        Write-Log -Message $_
        throw $_
    }

    # Export registration info
    $Registered = Export-RdsRegistrationInfo -TenantName $TenantName -HostPoolName $HostPoolName -ErrorAction SilentlyContinue
    if (!$Registered)
    {
        $obj =  $Registered | Out-String
        Write-Log -Message "Exported Rds RegistrationInfo into variable 'Registered': $obj"
    }
    else
    {
        Write-Log -Message "An error ocurred trying to export RegistrationInfo."
    }

    # Executing DeployAgent psl file in rdsh vm and add to hostpool
    Write-Log "AgentInstaller is $DeployAgentLocation\RDAgentBootLoaderInstall, InfraInstaller is $DeployAgentLocation\RDInfraAgentInstall, SxS is $DeployAgentLocation\RDInfraSxSStackInstall"
    $DAgentInstall = .\DeployAgent.ps1 -ComputerName $SessionHostName `
                                       -AgentBootServiceInstallerFolder "$DeployAgentLocation\RDAgentBootLoaderInstall" `
                                       -AgentInstallerFolder "$DeployAgentLocation\RDInfraAgentInstall" `
                                       -SxSStackInstallerFolder "$DeployAgentLocation\RDInfraSxSStackInstall" `
                                       -EnableSxSStackScriptFolder "$DeployAgentLocation\EnableSxSStackScript" `
                                       -AdminCredentials $ADAdminCredentials `
                                       -TenantName $TenantName `
                                       -PoolName $HostPoolName `
                                       -RegistrationToken $Registered.Token `
                                       -StartAgent $true `
                                       -rdshIs1809OrLater $rdshIs1809OrLaterBool
    
    Write-Log -Message "DeployAgent Script was successfully executed and RDAgentBootLoader,RDAgent,StackSxS installed inside VM for existing hostpool: $HostPoolName`n$DAgentInstall"

    # Get Session Host Info
    Write-Log -Message "Getting rdsh host $SessionHostName information"

    [Microsoft.RDInfra.RDManagementData.RdMgmtSessionHost]$rdsh = ([PsRdsSessionHost]::new($TenantName,$HostPoolName,$SessionHostName)).GetSessionHost()
    Write-Log -Message "RDSH object content: `n$($rdsh | Out-String)"

    $rdshName = $rdsh.SessionHostName | Out-String -Stream
    $poolName = $rdsh.hostpoolname | Out-String -Stream
  
    Write-Log -Message "Successfully added $rdshName VM to $poolName"
}