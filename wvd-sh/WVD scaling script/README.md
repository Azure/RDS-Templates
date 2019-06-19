This sample PowerShell script that can be used as a starting point for developing a solution to automatically scale a session host virtual machiness in Windows Virtual Desktop deployment. 

For many Windows Virtual Desktop deployments in Azure, the virtual machine costs of the Windows Virtual Desktop session host VM represent the most significant portion of the total deployment cost. To reduce cost, the script automatically shuts down and de-allocates RDSH server VMs during off-peak usage hours and then restarts them during peak usage hours.

The  PowerShell script (basicScale-MSI.ps1), a json file to control the script's behavior (Config-MSI.json), and documentation explaining how to deploy the script (Azure WVD Auto-Scaling-v1.docx). 