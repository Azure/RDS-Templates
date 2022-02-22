# Azure Virtual Desktop - Post Update Custom Configuration solution

## Description

This solution will deploy the Virtual Desktop Optimization Tool to an AVD session host using the Azure Portal with the Post Update Custom Configuration option.  The json and ps1 files must be saved to a publicly accessible storage location, like a public GitHub repository or a public Azure Blob Storage container.

## Implementation

1. Download the json and ps1 files to your computer.
1. Upload the script.ps1 file to your desired storage location.
1. Capture the URL for the script.ps1 file in a text editor.
1. Open the solution.parameters.json file in a text editor and update the values:
    1. Location: input the Azure deployment location for your AVD session hosts, i.e. eastus.
    1. NamePrefix: input the VM name prefix for each session host, i.e. avddeus.
    1. NumberOfVms: input the number of VM's for the deployment, i.e. 10.
    1. ScriptUri: input the URL for the script.ps1 file that was captured in a previous step, i.e. https://storage.blob.core.windows.net/avd/script.ps1.
    1. VirtualMachineIndex: input the number of the first VM in your deployment.  If this is your first deployment or you are performing a "rip and replace" then input 0.  To add VM's to your host pool, input the next number to deploy.  For example, if you deployed session hosts 0 through 5 in your first deployment, in your next deployment the index would be 6.
1. Save and close the solution.parameters.json file.
1. Upload the solution.json and solution.parameters.json files to your desired storage location.
1. Capture the URL's for the json files in a text editor.
1. When deploying AVD session hosts from the Azure Portal, input the URL's to the json files in the input fields for the Post Update Custom Configuration.
