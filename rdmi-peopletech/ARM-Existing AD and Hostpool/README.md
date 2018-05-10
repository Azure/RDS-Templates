# Update or New hostpool

This template updates RDSH servers in existing or new hostpool.

This template deploys the following resources:
+ `<rdshNumberOfInstances`> new virtual machines as RDSH servers


Note: Template does **not** delete or deallocate old RDSH instances, so you may still incur compute charges. These virtual machine instances may need to be deleted manually.

Click the button below to deploy:

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FRDS-Templates%2Fmaster%2Frdmi-peopletech%2FARM-Existing%20AD%20and%20Hostpool%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https://raw.githubusercontent.com/PeopleTechRDS/msft-rdmi-templates/master/ARM-Existing%20AD%20and%20Hostpool/azuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>