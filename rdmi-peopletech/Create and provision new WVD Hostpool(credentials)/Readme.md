<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FRDS-Templates%2Fmaster%2Frdmi-peopletech%2FPatch%20an%20existing%20RDmi%20hostpool%2FmainTemplate.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FRDS-Templates%2Fmaster%2Frdmi-peopletech%2FPatch%20an%20existing%20RDmi%20hostpool%2FmainTemplate.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

# Create and provision new WVD Host pool (Credentials)
This template creates virtual machines and registers them as session hosts to a new or existing Windows Virtual Desktop host pool. There are different sets of parameters you must enter to successfully deploy the template:

+ VM image Type
+ RDSH VM Configuration in Azure
+ Domain and Network Properties
+ Authentication to Windows Virtual Desktop

Follow the guidance below for entering the appropriate parameters for your scenario.

# VM Image Type
When creating the virtual machines, you have two options:

+ Azure Gallery Image
+ Custom VHD from blob storage

Enter the appropriate depending on the image option you choose.

## Azure Gallery Image
By selecting azure gallery Image, provide below parameter values

+ 
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FRDS-Templates%2Fmaster%2Frdmi-peopletech%2FPatch%20an%20existing%20RDmi%20hostpool%2FmainTemplate.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FRDS-Templates%2Fmaster%2Frdmi-peopletech%2FPatch%20an%20existing%20RDmi%20hostpool%2FmainTemplate.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>