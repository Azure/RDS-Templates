# Overview
These are the scripts and files required to configure AVD session hosts; and will be executed by the [Azure Desired State Configuration extension](https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/dsc-overview) defined in the ARM templates.

## Integration
We recommend that you only rely on the Configuration.ps1 file and the Script-SetupSessionHost.ps1 file as the other files in the Configuration.zip are subject to change. We will only consider breaking changes as changes in the signature for the Configuration.ps1 file and the Script-SetupSessionHost.ps1 file. Though we always strive to ensure backwards compatibility, there are times when we must make a breaking change. In those scenarios, we will communicate that here on [Tech Community](https://techcommunity.microsoft.com/t5/forums/recentpostspage/post-type/thread/board-id/AzureVirtualDesktopForum) and in the PR on GitHub for the change that is being made. If you have any questions, comments, or concerns about this, please feel free to post a comment.

We also highly recommend to refer to a specific commit of the scripts/zip files instead of the latest version.  This will make sure even latest release version has breaking changes, it will not cause any problem to your integration.

## Files

- Configuration.zip - This is what is deployed by the [Azure Desired State Configuration extension](https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/dsc-overview) defined in the ARM templates (it is currently named Microsoft.PowerShell.DSC in the templates). This file is created by zipping all of the other files in this directory plus a file named Functions.ps1 from [wvd-templates/DSC/Functions.ps1](https://github.com/Azure/RDS-Templates/blob/master/wvd-templates/DSC/Functions.ps1). Functions.ps1 contains some code that is shared between the [WVD classic ARM templates](https://github.com/Azure/RDS-Templates/tree/master/wvd-templates) and [WVD non-classic ARM templates](https://github.com/Azure/RDS-Templates/tree/master/ARM-wvd-templates).

- DeployAgent.zip - contains installers for the WVD Agent and WVD Agent Bootloader.

