# Create and provision new WVD hostpool

This template creates virtual machines and registers them as session hosts to a new or existing Windows Virtual Desktop host pool. There are multiple sets of parameters you must enter to successfully deploy the template:
- VM image
- VM configuration
- Domain and network properties
- Authentication to Windows Virtual Desktop

Follow the guidance below for entering the appropriate parameters for your scenario.

## VM image
When creating the virtual machines, you have three options:
- Azure Gallery image
- Custom VHD from blob storage
- Custom Azure Image resource from a resource group

Enter the appropriate parameters depending on the image option you choose.

### Azure Gallery
By selecting Azure Gallery, you can select up-to-date images provided by Microsoft and other publishers. Enter or select values for the following parameters:
- **Rdsh Image Source**, select **Gallery**.
- **Rdsh Gallery Image SKU**

Ignore the following parameters :
- **Vm Image Vhd Uri**
- **Rdsh Custom Image Source Name**
- **Rdsh Custom Image Source Resource Group**
- **Rdsh Use Managed Disks**
- **Storage Account Resource Group Name**

### Custom VHD from blob storage
By selecting a custom VHD from blob storage, you can create your own image locally through Hyper-V or on an Azure VM. Enter or select values for the following parameters:
- **Rdsh Image Source**, select **CustomVHD**.
- **Vm Image Vhd Uri**
- **Rdsh Use Managed Disks**. If you select **false** for **Rdsh Use Managed Disks**, enter the name of the resource group containing the storage account and image for the **Storage Account Resource Group Name** parameter. Otherwise, leave the **Storage Account Resource Group Name** parameter empty.

Ignore the following parameters:
- **Rdsh Gallery Image SKU**
- **Rdsh Custom Image Source Name**
- **Rdsh Custom Image Source Resource Group**

### Custom Azure Image resource from a resource group
By selecting a custom Azure Image resource from a resource group, you can create your own image locally through Hyper-V or an Azure VM but have the portability and flexibility of image management through an Azure Image resource. Enter or select values for the following parameters:
- **Rdsh Image Source**, select **CustomImage**.
- **Rdsh Custom Image Source Name**
- **Rdsh Custom Image Source Resource Group**

Ignore the following parameters:
- **Vm Image Vhd Uri**
- **Rdsh Gallery Image SKU**
- **Rdsh Use Managed Disks**
- **Storage Account Resource Group Name**

## VM configuration
Enter the remaining configuration parameters for the virtual machines.
- **Rdsh Name Prefix**
- **Rdsh Number Of Instances**
- **Rdsh VM Disk Type**. If you selected **CustomVHD** as the **Rdsh Image Source** and **false** for **Rdsh Use Managed Disks**, ensure that this parameter matches the storage account type where the source image is located.

## Domain and network properties
Enter the following properties to connect the virtual machines to the appropriate network and join them to the appropriate domain (and organizational unit, if defined).

- **Domain To Join**
- **Existing Domain UPN**. This UPN must have appropriate permissions to join the virtual machines to the domain and organizational unit.
- **Existing Domain Password**
- **OU Path**. If you do not have a specific organizaiton unit for the virtual machines to join, leave this parameter empty.
- **Existing Vnet Name**
- **Existing Subnet Name**
- **Virtual Network Resource Group Name**

## Windows Virtual Desktop host pool type
The following property will change the default template behavior from setting up a non-persistent environment to persistent if changed to True.

- **Enable Persistent Desktop**. Default value is False, change to True to creat the host pool with persistent desktops.

## Authentication to Windows Virtual Desktop
Enter the following information to authenticate to Windows Virtual Desktop and register the new virtual machines as session hosts to a new or existing host pool.

- **Rd Broker URL**
- **Existing Tenant Group Name**. If you were not given a specific tenant group name, leave this value as "Default Tenant Group".
- **Existing Tenant Name**
- **Host Pool Name**
- **Tenant Admin Upn or Application Id**. If you are creating a new host pool, this principal must be assigned either the *RDS Owner* or *RDS Contributor* role at the tenant scope (or higher). If you are registering these virtual machines to an existing host pool, this principal must be assigned either the *RDS Owner* or *RDS Contributor* role at the host pool scope (or higher).
  
  > [!WARNING]
  You cannot enter a UPN that requires MFA to successfully authenticate. If you do, this template will create the virtual machines but fail to register them to a host pool.

- **Tenant Admin Password**
- **Is Service Principal**. If you select **True** for **Is Service Principal**, enter your Azure AD tenant ID for the **Aad Tenant Id** parameter to properly identify the directory of your service principal and successfully authenticate to Windows Virtual Desktop. Otherwise, leave the **Aad Tenant Id** parameter empty.


Click the button below to deploy:


<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FRDS-Templates%2Fmaster%2Fwvd-templates%2FCreate%20and%20provision%20WVD%20host%20pool%2FmainTemplate.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FRDS-Templates%2Fmaster%2Fwvd-templates%2FCreate%20and%20provision%20WVD%20host%20pool%2FmainTemplate.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>
