# Windows Virtual Desktop Auto Scalling
Automatic Scaling of Session Hosts in Window Virtual Desktop. Reducing Costs of Desktop Hosting on Microsoft Azure Infrastructure Services. For deployment plese follow below steps.
### Prerequisites
The environment to be used to execute the script must meet the following requirements.

- Microsoft Azure Resource Manager PowerShell Module installed in your Local Machine for deploying WVD AutoScale.
- Windows Virtual Desktop tenant and account / service principal with permissions to query that tenant (e.g. RDS Contributor).
- Session host pool VMs configured and registered with the Windows Virtual Desktop service. 

## Steps to Deploy WVD AutoScale

#### Follow below steps to Download the autoscaledeploy powershell script.
- Launch your command-line interface. In Windows, open the Start menu, type cmd in the search box, and press Enter.
- Copy this cURL statement
    #### cURL -s AutoScaleDeployment.ps1 > "provide your local path with same name AutoScaleDeployment.ps1" and paste it at the command prompt.
    Example: cURL -s AutoScaleDeployment.ps1 > "C:\windows\temp\AutoScaleDeployment.ps1"

- Press Enter to run the cURL statement
- Open PowerShell Console or IDE in Administrator mode then execute downloaded autoscaledeploy script.

Set-Location -path "Script Downloaded location"
- .\AutoScaleDeployment.ps1 -RDBrokerURL "https://rdbroker.wvd.microsoft.com" -TenantGroupName "Name of the Tenant Group" -TenantName: "Name of the Tenant" -HostpoolName "WVD Hostpool Name" -BreadthFirst $true 
-AADTenantId "Specifies the Azure Active Directory Tenant Id your azure subscription associated with." -AADApplicationId "The GUID for the Azure Active Directory Application you create for service principal" -AADServicePrincipalSecret "The secret you created for your Azure service principal." -Subscriptionid "The ID of your Azure subscription" -BeginPeakTime "Begin Peak Time" -EndPeakTime "End Peak Time" -TimeDifference "your local time zone" -SessionThresholdPerCPU "Maximum number of sessions per CPU threshold used to determine when a new RDSH server needs to be started during peak hours" -MinimumNumberOfRDSH "Minimum number of host pool VMs to keep running during off-peak usage time" -LimitSecondsToForceLogOffUser "Number of seconds to wait before forcing users to logoff. If 0, don't force users to logoff" -Location "south central us" -LogOffMessageTitle "The title of the notification message sent to a user before forcing the user to log off." -LogOffMessageBody "The body of the message sent to a user before forcing the user to log off." -RecurrenceInterval "Schedule Job Recurrence in Minutes" 
-AutomationAccountName "Name of the Automation Account" -resourcegroupname "Name of the Resource Group"

Example:
- Set-Location -path "Script Downloaded location"
    .\AutoScaleDeployment.ps1 -RDBrokerURL "https://rdbroker.wvd.microsoft.com" -TenantGroupName "WVD Tenant Group Name" -TenantName: "WVD tenant name" -HostpoolName "WVD Hostpool Name" -BreadthFirst $true 
-AADTenantId "Specifies the Azure Active Directory Tenant Id your azure subscription associated with." -AADApplicationId "The GUID for the Azure Active Directory Application you create for service principal" -AADServicePrincipalSecret "The secret you created for your Azure service principal." -Subscriptionid "The ID of your Azure subscription" -BeginPeakTime "09:00" -EndPeakTime "18:00" -TimeDifference "+5:30" -SessionThresholdPerCPU 2 -MinimumNumberOfRDSH 1 -LimitSecondsToForceLogOffUser 60 -Location "south central us" -LogOffMessageTitle "The title of the notification message sent to a user before forcing the user to log off." -LogOffMessageBody "The body of the message sent to a user before forcing the user to log off." -RecurrenceInterval 15 
-AutomationAccountName "WVDAutoscaleAutomationAccount" -resourcegroupname "WVDAutoscaleResourceGroup"

Note: When you deploy Depth First loadbalacning make sure you provide BreadthFirst parameter value as $False and ignore below parameter.
- SessionThresholdPerCPU

Note1: This Script will create an automation account with runbooks(TenantName-BreadthfirstRunbook, TenantName-DepthFirstRunbook) and webhooks(TenantName-BreadthFirstWebhook, TenantName-DepthfirstWebhook) and azure scheduler job collections only once, so provide same automation account name and resource group name when deploy further instances. For each hostpool will create an azure scheduler job.



