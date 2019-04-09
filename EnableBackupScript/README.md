# Enable-RecoveryServicesSessionHostBackup.ps1

This script helps enabling Azure Recovery Services (Backup and Site Recovery) VM backup on all Session Hosts within a Host Pool. For more information on how to configure Backup and Site Recovery for WVD, please refer to \<TBD\>.

## Requirements

* Windows PowerShell 5.0 and 5.1
* Az PowerShell module 1.6 or greater
* Microsoft.RDInfra.RDPowerShell PowerShell module
* Azure Recovery Services Vault already deployed within the same region as the Session Hosts

## Script Parameters

* **TenantName** - Windows Virtual Desktop Tenant Name.
* **HostPoolName** - Host Pool Name where Session Hosts will have Backup enabled.
* **SessionHostsResourceGroup** - Resource Group where the Session Hosts are located.
* **RecoveryVaultResourceGroup** - Resource Group Name where Recovery Services Vault is located.
* **RecoveryVaultName** - Name of Recovery Services Vault that will provide Azure VM Backup service to the VMs.
* **BackupPolicyName** - Name of Backup Policy to apply to the Session Hosts VMs. This is optional if policy has the exact same name as the Host Pool.
* **OverridePersistencyCheck** - Switch that ignores Persistent Desktop option and enable backup anyways for non-persistent desktops

## Usage

```powershell
# Authenticate on Azure
Add-AzAccount

# Authenticate on WVD Tenant
Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com"
Set-RdsContext -TenantGroupName "<WVD Tenant Name>"

# Enabling VM Backup
.\Enable-RecoveryServicesSessionHostBackup.ps1 -TenantName <tenant name> `
                                               -HostPoolName <host pool name> `
                                               -SessionHostsResourceGroup <session hosts resource group name> `
                                               -RecoveryVaultName <recovery services vault name>
                                               -RecoveryVaultResourceGroup <recovery services vault resource group name>
                                               -BackupPolicyName <backup policy name>
```

## References

* [Install the Azure PowerShell module](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-1.6.0)
* [Windows Virtual Desktop Cmdlets for Windows PowerShell](https://docs.microsoft.com/en-us/powershell/windows-virtual-desktop/overview)
* [Enabling WVD Session Hosts Backup]()
* [What is Azure Backup?](https://docs.microsoft.com/en-us/azure/backup/backup-overview)
* [Back up Azure VMs in a Recovery Services vault](https://docs.microsoft.com/en-us/azure/backup/backup-azure-arm-vms-prepare)