Connect-AzAccount
Select-AzSubscription -Subscription "<<<Your Subscription ID >>>"

# Variable definition
$ResourceGroupName = "<<<Your Resource Group Name>>>"
$Location = "<<<Your Azure Region>>>"

# Run the deployment
New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -Location $Location -TemplateFile ".\FirewallPolicyForAVD-template.json" -TemplateParameterFile ".\FirewallPolicyForAVD-parameters.json"

# Once completed, review all the Policy settings and rules, then associate to an existing Firewall: #

$fwpolicyname = "<<<Your AVD Firewall Policy Name>>>"
$fwpolicyresourcegroup = "<<<Resource Group where the Policy has been created>>>"
$fwname = "<<<Your Firewall Name>>>"
$fwresourcegroup = "<<<Resource Group where the Azure Firewall is located>>>"

$azFw = Get-AzFirewall -Name $fwname -ResourceGroupName $fwresourcegroup
$azPolicy = Get-AzFirewallPolicy -Name $fwpolicyname -ResourceGroupName $fwpolicyresourcegroup

$azFw.FirewallPolicy = $azPolicy.Id
$azFw | Set-AzFirewall


