# Create MSFT-WVD-SAAS-UX Environment

Deploy the web app to your azure environment.

Click the button below to deploy:

[![Deploy to Azure](https://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FRDS-Templates%2Fmaster%2Fwvd-templates%2Fwvd-management-ux%2Fdeploy%2FmainTemplate.json)

## Azure resouces deployed
- Azure App Services (Web App &  API App)
- Azure App Service Service Plan (S1- Standard)


# Update MSFT-WVD-SAAS-UX Environment

Update the existing management-ux deployment with latest build release follow the below steps:

1. Click  the button below to deploy and update the ManagementUX Tool with latest build release files:

    You need to provide existing depoyment details for to update the existing webapp and APIApp with latest build release files. Enter following parameter values to template.

    - ResourceGroupName: Application existing Resourcegroupname.
    - ExistingApplicationName: Name of the existing Application.

    [![Deploy to Azure](https://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FRDS-Templates%2Fmaster%2Fwvd-templates%2Fwvd-management-ux%2Fdeploy%2FupdateTemplate.json)




2. Copy **updateWvdMgmtUxApiUrl.ps1** script file from **scripts** folder to your local machine and then run the powershell script in administrator mode.
    
    - Make sure before executing script in your local machine "Az" module is installed and Log in to your Azure account.

        ```PowerShell

        Login-AzAccount

        ```
    - Enter the following parameter values to updateWvdMgmtUxApiUrl.ps1 script
        - AppName: Name of the existing appname
        - SubscriptionID: Provide subscription id where resources are exist. Azure Subscription ID, which you can find in the Azure portal under Subscriptions.

        ```PowerShell

        .\updateWvdMgmtUxApiUrl -AppName "Existing AppName" -SubscriptionID "ID of the Subscription"

        ```