This scaledeployment script will create the auto scale script execution required resources in Microsoft Azure. Resources are 
- Resourcegroup
- Azure Automation Account
- Automation Account Runbook and publish the basic scale script. 
- Automation Account Webhook and store the WebhookURI in Azure Automation Account Variable.
- Log Analytic Workspace Custom Tables and Field Names.
- Azure LogicApp Scheduler.

Copy or download the **scaledeployment.ps1** script file to your local machine and then run the powershell script in administrator mode.
