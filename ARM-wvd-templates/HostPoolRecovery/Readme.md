# Host Pool Recovery Scripts
These scripts can be used to recover a host pool if it is unavailable due to an internal agent failure. It works by running a custom script via CustomScriptExtension on all session hosts in a host pool which will reinstall the AVD Agent.

## How to use
You can use the script "InstallAVDOnAHostPoo.ps1" by downloading it onto your local machine, then running it in powershell. Please specifying the subscription id, resource group name, and host pool name. Authenticate into an azure account that has the permissions to deploy the virtual machine extension.

## Example
InstallAVDOnAHostPoo.ps1 -subscriptionId "MySubscriptionId" -resourceGroupName "MyResourceGroup" -hostPoolName "myHostPool"