<#
.SYNOPSIS
    Enables Azure VM Backup on all Sesion Hosts within a Host Pool (Persistent Desktops)
.DESCRIPTION
    Enables Azure VM Backup on all Sesion Hosts within a Host Pool (Persistent Desktops).
    This script requres Azure Recovery Services Vault already deployed in the same Azure Region as the Session Hosts, it also will be 
    enabled only if the Host Pool is configured for Persitent Desktops.
    
    Note:
    
    For this script to run you must already be authenticated on Azure with Add-AzAccount, authenticated against a WVD Tenant with Add-RdsAccount
    and switched tenant group context where your host pools were deployed with Set-RdsContext.  
.PARAMETER TenantName
    Windows Virtual Desktop Tenant Name
.PARAMETER HostPoolName
    Host Pool Name where Session Hosts will have Backup enabled
.PARAMETER SessionHostsResourceGroup
    Resource Group where the Session Hosts are located
.PARAMETER RecoveryVaultResourceGroup
    Resource Group Name where Recovery Services Vault is located. 
.PARAMETER RecoveryVaultName
    Name of Recovery Services Vault that will provide Azure VM Backup service to the VMs. 
.PARAMETER BackupPolicyName
    Name of Backup Policy to apply to the Session Hosts VMs. This is optional if policy has the exact same name as the Host Pool. 
.PARAMETER OverridePersistencyCheck
    Ignores Persistent Desktop option and enable backup anyways for non-persistent desktops
.EXAMPLE

#>

#Requires -Modules Az.RecoveryServices, Microsoft.RDInfra.RDPowerShell

[CmdletBinding()]
param
(
    [Parameter(Mandatory=$true)]
    [string]$TenantName,

    [Parameter(Mandatory=$true)]
    [string]$HostPoolName,

    [Parameter(Mandatory=$true)]
    [string]$SessionHostsResourceGroup,

    [Parameter(Mandatory=$true)]
    [string]$RecoveryVaultName,
    
    [Parameter(Mandatory=$true)]
    [string]$RecoveryVaultResourceGroup,

    [Parameter(Mandatory=$false)]
    [string]$BackupPolicyName="",

    [Parameter(Mandatory=$false)]
    [switch]$OverridePersistencyCheck
)

$ErrorActionPreference="Stop"

# Checking if BackupPolicyName should match HostPoolName
if ([string]::IsNullOrEmpty($BackupPolicyName))
{
    $BackupPolicyName = $HostPoolName
}

# Setting vault context
$RecoveryVault = Get-AzRecoveryServicesVault -Name $RecoveryVaultName -ResourceGroupName $RecoveryVaultResourceGroup

# Getting Policy
$Policy = Get-AzRecoveryServicesBackupProtectionPolicy -Name $BackupPolicyName -VaultId $RecoveryVault.ID

$HostPool = Get-RdsHostPool -TenantName $TenantName -Name $HostPoolName

if ((-not $HostPool.Persistent) -and (-not $OverridePersistecyCheck) )
{
    throw "Found a non-persistent desktop host pool, ideally users must be prevented from writting to local disks in this scenario. If you want to bypass this check and enable it anyways, please use the -OverridePersistecyCheck switch."
}

foreach ($SessionHost in (Get-rdssessionhost -TenantName $TenantName -HostPoolName $HostPool.HostPoolName))
{
    $VmName = $SessionHost.SessionHostName.Split(".")[0]
    Write-Verbose -Verbose "Enabling Azure VM Backup on: $VmName"
    
    try
    {
        Enable-AzRecoveryServicesBackupProtection -ResourceGroupName $SessionHostsResourceGroup -Name $VmName -Policy $Policy -VaultId $RecoveryVault.ID
    }
    catch 
    {
        if ($_.Exception.HResult -eq -2146233088)
        {
            Write-Warning -Verbose "Backup not enabled on VM due to one of the followig reasons: VM is already protected (most probable), VM does not exist or VM name or service name needs to be case sensitive"
        }
        else
        {
            throw $_.Exception    
        }
    }
}
