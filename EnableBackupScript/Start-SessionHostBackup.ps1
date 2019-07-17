<#
.SYNOPSIS
    Starts adhoc Session Host Backups.
.DESCRIPTION
    This scripts starts an "Azure VM Backup" adhoc backup job within one or more session hosts depending on parameters used,
    it can backup a persistent session host based on user principal name, all session hosts within a host pool or a specific session host.
    
    Backup by UPN applies only when host pool is configured for persistent desktops usage.
    
    Note:
    
    For this script to run you must already be authenticated on Azure with Add-AzAccount, authenticated against a WVD Tenant with Add-RdsAccount
    and switched tenant group context where your host pools were deployed with Set-RdsContext.  
.PARAMETER TenantName
    Windows Virtual Desktop Tenant Name.
.PARAMETER HostPoolName
    Host Pool Name where Session Hosts will have Backup enabled.
.PARAMETER RecoveryVaultResourceGroup
    Resource Group Name where Recovery Services Vault is located. 
.PARAMETER RecoveryVaultName
    Name of Recovery Services Vault that will provide Azure VM Backup service to the VMs. 
.PARAMETER BackupType
    Backup type, valid backup types are Full, Differential, Log or CopyOnlyFull.
.PARAMETER ExpireDateTimeUTC
    Sets expiration date, maximum value is up to 99 years.
.PARAMETER UserPrincipalName
    User Principal Name that will identify the Session Host to start the backup, this will be enabled only if persistent desktop option is enabled.
.PARAMETER SessionHostName
    Session Host FQDN to start the backup.
.PARAMETER BackupAllSessionHosts
    makes this script backup all session hosts within host pool

.EXAMPLE 
    # Starting a backup job for a specific user session host with 1 year retention period
    .\Start-SessionHostBackup.ps1 -TenantName pmarques `
        -HostPoolName "Backup Test Pool 01" `
        -RecoveryVaultName PMC-EUS-RecoveryVault-01 `
        -RecoveryVaultResourceGroup RecoveryServicesVaults-rg `
        -BackupType Full `
        -UserPrincipalName wvduser01@pmcglobal.me `
        -ExpireDateTimeUTC (Get-Date).ToUniversalTime().AddYears(1)

.EXAMPLE
    # Starting a backup job for a specific session host with 6 months retention period
    .\Start-SessionHostBackup.ps1 -TenantName pmarques `
        -HostPoolName "Backup Test Pool 01" `
        -RecoveryVaultName PMC-EUS-RecoveryVault-01 `
        -RecoveryVaultResourceGroup RecoveryServicesVaults-rg `
        -BackupType Full `
        -SessionHostName rdsh-pd-1.testdomain.local `
        -ExpireDateTimeUTC (Get-Date).ToUniversalTime().AddMonths(6)

.EXAMPLE
    # Starting a backup job for all session hosts within a host pool with 10 years retention period
    .\Start-SessionHostBackup.ps1 -TenantName pmarques `
        -HostPoolName "Backup Test Pool 01" `
        -RecoveryVaultName PMC-EUS-RecoveryVault-01 `
        -RecoveryVaultResourceGroup RecoveryServicesVaults-rg `
        -BackupType Full `
        -BackupAllSessionHosts `
        -ExpireDateTimeUTC (Get-Date).ToUniversalTime().AddYears(10)
    
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
    [string]$RecoveryVaultName,
    
    [Parameter(Mandatory=$true)]
    [string]$RecoveryVaultResourceGroup,

    [Parameter(Mandatory=$true)]
    [ValidateSet("Full", "Differential", "Log" ,"CopyOnlyFull")]
    [string]$BackupType="Full",

    [Parameter(Mandatory=$true, ParameterSetName="ByUPN")]
    [string]$UserPrincipalName,

    [Parameter(Mandatory=$true, ParameterSetName="BySessionHost")]
    [string]$SessionHostName,

    [Parameter(Mandatory=$true, ParameterSetName="AllSessionHosts")]
    [switch]$BackupAllSessionHosts,

    [Parameter(Mandatory=$true)]
    [DateTime]$ExpireDateTimeUTC
)

$ErrorActionPreference="Stop"

function GetSessionHostByUPN
{
    param
    (
        $HostPoolName,
        $TenantName,
        $Upn
    )

    $SessionHost = @()
    $SessionHost += Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostPoolName | Where-Object { $_.AssignedUser -eq $UPN }

    return $SessionHost
}

function GetSessionHostByHostName
{
    param
    (
        $HostPoolName,
        $TenantName,
        $SessionHostName
    )

    $SessionHost = @()
    $SessionHost += Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostPoolName -Name $SessionHostName

    return $SessionHost
}

# Getting host pool and identifying persistent desktop scenario
$HostPool = Get-RdsHostPool -TenantName $TenantName -Name $HostPoolName
if ((-not $HostPool.Persistent) -and ($PSCmdlet.ParameterSetName -eq "ByUPN"))
{
    throw "Found a non-persistent desktop host pool while requesting backup of a session host that belongs to a specific UPN. Please make sure you pass a persistent desktop host pool for this type of backup."
}

# Getting Session Host List
$SessionHosts = @()

if ($PSCmdlet.ParameterSetName -eq "ByUPN")
{
    $SessionHosts += GetSessionHostByUPN -HostPoolName $HostPool.HostPoolName -TenantName $TenantName -Upn $UserPrincipalName
}
elseif ($PSCmdlet.ParameterSetName -eq "BySessionHost")
{
    $SessionHosts += GetSessionHostByHostName -HostPoolName $HostPool.HostPoolName -TenantName $TenantName -SessionHostName $SessionHostName
}
else
{
    $SessionHosts += Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostPool.HostPoolName
}

Write-Verbose -Verbose "Session Host(s) to enable backup: $($SessionHosts | Format-Table | Out-String)"

# Starting Backup Jobs
$RecoveryVault = Get-AzRecoveryServicesVault -Name $RecoveryVaultName -ResourceGroupName $RecoveryVaultResourceGroup

$JobList = @()

foreach ($SessionHost in $SessionHosts)
{
    $VmName = $SessionHost.SessionHostName.Split(".")[0]
    Write-Verbose -Verbose "Starting backup job on: $VmName"
    
    try
    {
        $NamedContainer = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVM -Status Registered -FriendlyName $VmName -VaultId $RecoveryVault.ID
        $ProtectedItem = Get-AzRecoveryServicesBackupItem -Container $NamedContainer -WorkloadType AzureVM -VaultId $RecoveryVault.ID
        $JobList += Backup-AzRecoveryServicesBackupItem -Item $ProtectedItem -VaultId $RecoveryVault.ID
    }
    catch 
    {
        throw $_.Exception    
    }
}

# Returning Jobs

return $JobList