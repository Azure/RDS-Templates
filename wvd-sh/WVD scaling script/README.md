This sample PowerShell script that can be used as a starting point for developing a solution to automatically scale a session host virtual machiness in Windows Virtual Desktop deployment. 

For many Windows Virtual Desktop deployments in Azure, the virtual machine costs of the Windows Virtual Desktop session host VM represent the most significant portion of the total deployment cost. To reduce cost, the script automatically shuts down and de-allocates RDSH server VMs during off-peak usage hours and then restarts them during peak usage hours.

The  PowerShell script (basicScale.ps1), a json file to control the script's behavior (Config.json), and documentation explaining how to deploy the script (Azure WVD Auto-Scaling-v1.docx). 

**Reporting issues:**
Microsoft Support is not handling issues for any published tools in this repository. These tools are published as is with no implied support. However, we would like to welcome you to open issues using GitHub issues to collaborate and improve these tools. You can open [an issue](https://github.com/Azure/rds-templates/issues) and add the label **4-WVD-scaling-script** to associate it with this tool.
