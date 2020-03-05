Follow the guidance below for entering the appropriate parameters for your scenario.

> **Reporting issues:**
> Microsoft Support is not handling issues for any published tools in this repository. These tools are published as is with no implied support. However, we would like to welcome you to open issues using GitHub issues to collaborate and improve these tools. You can open [an issue](https://github.com/Azure/rds-templates/issues) and add the label **4a-WVD-scaling-logicapps ** to associate it with this tool.

This scaledeployment script will create the auto scale script execution required resources in Microsoft Azure. Resources are 
- Resourcegroup
- Azure Automation Account
- Automation Account Runbook and publish the basic scale script. 
- Automation Account Webhook and store the WebhookURI in Azure Automation Account Variable.
- Log Analytic Workspace Custom Tables and Field Names.
- Azure LogicApp Scheduler.

Review the [Scale session hosts automatically](https://aka.ms/wvdscale) article for deployment guidance.
