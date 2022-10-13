# Azure Virtual Desktop with Stack HCI

Use the Full Configuration ARM templates if you are looking for more configurations in your Azure Virtual Desktop session hosts deployed on Azure Stack HCI. 

## Deploy  Azure Virtual Desktop on Azure Stack HCI
This ARM template will setup Azure Virtual Desktop on Azure Stack HCI by creating a new host pool and workspace, creating the session hosts on the HCI cluster, joining the domain to downloading and installing the Azure Virtual Desktop agents and register them to the host pool. 
Check out the template [here](https://github.com/Azure/RDS-Templates/blob/master/ARM-wvd-templates/HCI/CreateHciHostpoolTemplate.json)

<a  href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FRDS-Templates%2Fmaster%2FARM-wvd-templates%2FHCI%2FCreateHciHostpoolTemplate.json"  target="_blank">
	<img  src="http://azuredeploy.net/deploybutton.png"/>
</a>

<a  href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FRDS-Templates%2Fmaster%2FARM-wvd-templates%2FHCI%2FCreateHciHostpoolTemplate.json"  target="_blank">
<img  src="http://armviz.io/visualizebutton.png"/>
</a>

## Add new Azure Virtual Desktop session hosts to an existing host pool
This ARM template will add new Azure Virtual Desktop machines to your existing host pool.
Check out the template [here](https://github.com/Azure/RDS-Templates/blob/master/ARM-wvd-templates/HCI/AddHciVirtualMachinesTemplate.json)

<a  href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FRDS-Templates%2Fmaster%2FARM-wvd-templates%2FHCI%2FAddHciVirtualMachinesTemplate.json"  target="_blank">
	<img  src="http://azuredeploy.net/deploybutton.png"/>
</a>

<a  href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FRDS-Templates%2Fmaster%2FARM-wvd-templates%2FHCI%2FAddHciVirtualMachinesTemplate.json"  target="_blank">
	<img  src="http://armviz.io/visualizebutton.png"/>
</a>