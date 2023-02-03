# MSIX App Attach

This repository contains sample scripts for implementing testing and troubleshooting MSIX app attach.

It also contains the CimDiskImage PowerShell module used in the sample scripts. You can find the [Cim Disk Module documentation here](CimDiskImage-PoSh-Module\README.md).

Microsoft offers support for MSIX App Attach when managed through Azure Virtual Desktop. These demonstration scripts are commmunity supported only.

Please reference the [official documentation for MSIX App Attach](https://learn.microsoft.com/azure/virtual-desktop/what-is-app-attach) before using these scripts.

For specific guidance on testing App Attach packages with PowerShell please refer to the [Create PowerShell scripts for App Attach documentation](https://learn.microsoft.com/azure/virtual-desktop/app-attach)

For help to create an [MSIX package from a desktop installer](https://docs.microsoft.com/windows/msix/packaging-tool/create-app-package-msi-vm) MSI, EXE or App-V on a VM

## Help

| Script      | Description |
| ----------- | ----------- |
| [StagePackageDemo.ps1](Help/StagePackageDemo.ps1.md)      | Stages an App Attach Package on the system       |
| [RegisterPackageDemo.ps1](Help/RegisterPackageDemo.ps1.md)      | Registers an App Attach Package for the user       |
| [DeRegisterPackageDemo.ps1](Help/DeRegisterPackageDemo.ps1.md)      | Registers an App Attach Package for the user       |
| [DeStagePackageDemo.ps1](Help/DeStagePackageDemo.ps1.md)      | Stages an App Attach Package on the system       |

## Additional materials

Please note that the assets below are community supported and best effort. They do not come with support from Microsoft.

* [Mounting Cim Disk Image Files PowerShell Module](https://youtube.com/watch?v=nfFNODPIntE&feature=shares) (Jim Moyle, Youtube.com )
* [Azure Virtual Desktop | Quick Setup](https://youtube.com/watch?v=u99cY0MXZds&feature=shares) (Microsoft Mechanics, Youtube.com)
* [Azure Virtual Desktop Tech Community](https://techcommunity.microsoft.com/t5/Windows-Virtual-Desktop/bd-p/WindowsVirtualDesktop)
* [MSIX app attach will fundamentally change working with application landscapes on Windows Virtual Desktop!](https://blogs.msdn.microsoft.com/rds/2015/07/13/azure-resource-manager-template-for-rds-deployment) (blog series) [Freek Berson]
