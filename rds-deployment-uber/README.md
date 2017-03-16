# Create a FULL HA RDS environment

This template deploys the following nested templates:

* RDS farm deployment using existing active directory
* RDS Gateway High Availability deployment
* Update SSL certifiocates
* RDS Broker High Availability deployment

### Prerequisites

This template expects the same names of resources from RDS deployment, if resource names are changed in your deployment then please edit the parameters and resources accordingly, example of such resources are below:
<ul>
<li>storageAccountName: Resource must be exact same to existing RDS deployment.</li>
<li>publicIpRef: Resource must be exact same to existing RDS deployment.</li>
<li>availabilitySets: Resource must be exact same to existing RDS deployment.</li>
<li>Load-balancer: Load balancer name, Backend pool, LB-rules, Nat-Rule and NIC.</li>
<li>VM’s – VM name classification which is using copy index function.</li>
<li>NIC – NIC naming convention.</li>
</ul>


Click the button below to deploy

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fazure-quickstart-templates%2Fmaster%2Frds-deployment-HA%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fazure-quickstart-templates%2Fmaster%2Frds-deployment-HA%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>
