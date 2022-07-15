# Scripts to Enable and Execute Backup Jobs for WVD

## FirewallPolicyForAVD-template.json

This template will create a sample Azure Firewall Policy with all the application and network rules necessary to enable an Azure Virtual Desktop Host Pool to operate. The template is based on the requirements listed in the article below:

[Required URLs for Azure Virtual Desktop](https://docs.microsoft.com/azure/virtual-desktop/safe-url-list)

Once created the Azure Policy, it is possible to inspect and review the rules contained using [Azure Firewall Manager](https://docs.microsoft.com/azure/firewall-manager/overview) UI in the Azure Portal:

:::image type="content" source="media/firewall-manager-overview.jpg" alt-text="Image Showing the list of Firewall Policies" lightbox="media/firewall-manager-overview.jpg":::

The policy created contains two distinct Rule Collection Groups:

1. **AVD-Core**: this group contains the rules that are listed as mandatory for the AVD Host Pool to function at the very basic. Be sure to review the list of rules created in the policy with the list contained in the [official AVD documentation](https://docs.microsoft.com/azure/virtual-desktop/safe-url-list).
2. **AVD-Optional**: this group contains optional URLs that your session host virtual machines might also need to access for other services. This list is based on the recommendations container in [this article](https://docs.microsoft.com/azure/virtual-desktop/safe-url-list) and should be carefully reviewed to eventually add or remove, based on the specific customer scenario.

:::image type="content" source="media/list-of-rule-collection-groups.jpg" alt-text="Image Showing the list of Firewall Policies" lightbox="media/list-of-rule-collection-groups.jpg":::

### Script Parameters

* **firewallPolicies_AVD_DefaultPolicy_name** - Name of the Azure Firewall Policy to create (*default value "AVD-FirewallPolicy"*).
* **location** - The Azure region where to create the Azure Firewall Policy.
* **firewall-policy-tier** - Azure Firewall Policy "Premium" or "Standard" SKUs (*default value "standard"*).
* **dns-server** - Internal IP address of the custom DNS that Azure Firewall will use to resolve network names.
* **avd-hostpool-subnet** - The subnet IP address range of the AVD Host Pool.

A sample file ***FirewallPolicyForAVD-parameters.json*** is provided in this folder as an example. 

### Usage
Using the sample code below, a new Azure Firewall Policy will be created with the necessary parameters.

Once created, it is highly recommended to review all the rules to ensure everything is as desired for the specific environment.

The final step is to associate the policy created with an instance of the Azure Firewall.

```powershell
Connect-AzAccount
Select-AzSubscription -Subscription "<<<Your Subscription ID >>>"

# Variable definition
$ResourceGroupName = "<<<Your Resource Group Name>>>"
$Location = "<<<Your Azure Region>>>"

# Run the deployment
New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -Location $Location -TemplateFile ".\FirewallPolicyForAVD-template.json" -TemplateParameterFile ".\FirewallPolicyForAVD-parameters-.json"

# Once completed, review all the Policy settings and rules, then associate to an existing Firewall: #

$fwpolicyname = "<<<Your AVD Firewall Policy Name>>>"
$fwpolicyresourcegroup = "<<<Resource Group where the Policy has been created>>>"
$fwname = "<<<Your Firewall Name>>>"
$fwresourcegroup = "<<<Resource Group where the Azure Firewall is located>>>"

$azFw = Get-AzFirewall -Name $fwname -ResourceGroupName $fwresourcegroup
$azPolicy = Get-AzFirewallPolicy -Name $fwpolicyname -ResourceGroupName $fwpolicyresourcegroup

$azFw.FirewallPolicy = $azPolicy.Id
$azFw | Set-AzFirewall
```

## References

* [Required URLs for Azure Virtual Desktop](https://docs.microsoft.com/azure/virtual-desktop/safe-url-list)
* [Use Azure Firewall to protect Azure Virtual Desktop deployments](https://docs.microsoft.com/azure/firewall/protect-azure-virtual-desktop)
* [Azure Firewall Premium and Standard](https://docs.microsoft.com/azure/firewall/overview)
* [Azure Firewall DNS settings](https://docs.microsoft.com/azure/firewall/dns-settings)
* [What is Azure Firewall Manager?](https://docs.microsoft.com/azure/firewall-manager/overview)
