Configuration.zip - This is what is deployed by the [Azure Desired State Configuration extension](https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/dsc-overview) defined in the ARM templates (it is currently named dscextension in the templates). This file is created by zipping all of the other files in this directory.

DeployAgent.zip - contains installers for the WVD Agent and WVD Agent Bootloader.

Functions.ps1 - contains some code that is shared between the [WVD classic ARM templates](https://github.com/Azure/RDS-Templates/tree/master/wvd-templates) and [WVD non-classic ARM templates](https://github.com/Azure/RDS-Templates/tree/master/ARM-wvd-templates).

PowerShellModules.zip - contains the WVD classic powershell module  [Microsoft.RDInfra.RDPowerShell](https://docs.microsoft.com/en-us/powershell/windows-virtual-desktop/overview).