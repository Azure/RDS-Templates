# Scripts to Enable and Execute Backup Jobs for WVD

## Requirements

* Host Pool and Session Hosts deployed
* Windows PowerShell 5.0 and 5.1
* Az PowerShell module 1.6 or greater
* Microsoft.RDInfra.RDPowerShell PowerShell module
* Azure Recovery Services Vault already deployed within the same region as the Session Hosts

## Enable-RecoveryServicesSessionHostBackup.ps1

This script helps enabling Azure Recovery Services (Backup and Site Recovery) VM backup on all Session Hosts within a Host Pool.

### Script Parameters

* **TenantName** - Windows Virtual Desktop Tenant Name.
* **HostPoolName** - Host Pool Name where Session Hosts will have Backup enabled.
* **SessionHostsResourceGroup** - Resource Group where the Session Hosts are located.
* **RecoveryVaultResourceGroup** - Resource Group Name where Recovery Services Vault is located.
* **RecoveryVaultName** - Name of Recovery Services Vault that will provide Azure VM Backup service to the VMs.
* **BackupPolicyName** - Name of Backup Policy to apply to the Session Hosts VMs. This is optional if policy has the exact same name as the Host Pool.
* **OverridePersistencyCheck** - Switch that ignores Persistent Desktop option and enable backup anyways for non-persistent desktops

### Usage

```powershell
# Authenticate on Azure
Add-AzAccount

# Authenticate on WVD Tenant
Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com"
Set-RdsContext -TenantGroupName "<WVD Tenant Group Name>"

# Enabling VM Backup
.\Enable-RecoveryServicesSessionHostBackup.ps1 -TenantName <tenant name> `
                                               -HostPoolName <host pool name> `
                                               -SessionHostsResourceGroup <session hosts resource group name> `
                                               -RecoveryVaultName <recovery services vault name> `
                                               -RecoveryVaultResourceGroup <recovery services vault resource group name> `
                                               -BackupPolicyName <backup policy name>
```

## Start-SessionHostBackup.ps1

This script start a VM backup job on Session Hosts specific to a particular user, a specific Session Host or all Session Hosts within a Host Pool.

### Script Parameters

* **TenantName** - Windows Virtual Desktop Tenant Name.
* **HostPoolName** - Host Pool Name where Session Hosts will have Backup enabled.
* **RecoveryVaultResourceGroup** - Resource Group Name where Recovery Services Vault is located.
* **RecoveryVaultName** - Name of Recovery Services Vault that will provide Azure VM Backup service to the VMs.
* **BackupType** - Backup type, valid backup types are Full, Differential, Log or CopyOnlyFull.
* **ExpireDateTimeUTC** - Sets expiration date, maximum value is up to 99 years.
* **UserPrincipalName** - User Principal Name that will identify the Session Host to start the backup, this will be enabled only if persistent desktop option is enabled.
* **SessionHostName** - Session Host FQDN to start the backup.
* **BackupAllSessionHosts** - Switch that makes this script backup all session hosts within a host pool

### Usage

```powershell
# Authenticate on Azure
Add-AzAccount

# Authenticate on WVD Tenant
Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com"
Set-RdsContext -TenantGroupName "<WVD Tenant Group Name>"

# Starting a backup job
.\Start-SessionHostBackup.ps1 -TenantName <tenant name> `
        -HostPoolName <host pool name> `
        -RecoveryVaultName <recovery services vault name> `
        -RecoveryVaultResourceGroup <recovery services vault resource group name> `
        -BackupType <Full | Differential | Log | CopyOnlyFull> `
        -UserPrincipalName <user principal name> `
        -ExpireDateTimeUTC <date and time object in UTC>
```

## References

* [Install the Azure PowerShell module](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-1.6.0)
* [Windows Virtual Desktop Cmdlets for Windows PowerShell](https://docs.microsoft.com/en-us/powershell/windows-virtual-desktop/overview)
* [Enabling WVD Session Hosts Backup]()
* [What is Azure Backup?](https://docs.microsoft.com/en-us/azure/backup/backup-overview)
* [Back up Azure VMs in a Recovery Services vault](https://docs.microsoft.com/en-us/azure/backup/backup-azure-arm-vms-prepare)