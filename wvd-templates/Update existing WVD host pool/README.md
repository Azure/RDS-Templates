Click the button below to deploy:

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FRDS-Templates%2Fmaster%2Fwvd-templates%2FUpdate%20existing%20WVD%20host%20pool%2FmainTemplate.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FRDS-Templates%2Fmaster%2Fwvd-templates%2FUpdate%20existing%20WVD%20host%20pool%2FmainTemplate.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

# ARM Template to Update an existing Windows Virtual Desktop hostpool

This template will remove or stop the old instance of Windows Virtual Desktop Hostpool session hosts and creates new virtual machines and registers them as session hosts to Windows Virtual Desktop host pool. There are different sets of parameters you must enter to successfully deploy the template:
- VM image
- VM configuration
- Domain and network properties
- Authentication to Windows Virtual Desktop
- Update action

Follow the guidance below for entering the appropriate parameters for your scenario.

> **Reporting issues:**
> Microsoft Support is not handling issues for any published tools in this repository. These tools are published as is with no implied support. However, we would like to welcome you to open issues using GitHub issues to collaborate and improve these tools. You can open [an issue](https://github.com/Azure/rds-templates/issues) and add the label **2-Update-existing-WVD-host-pool** to associate it with this tool.

## VM image
When creating the new virtual machines, you have three options:
- Azure Gallery image
- Custom VHD from blob storage
- Custom Azure Image resource from a resource group

Enter the appropriate parameters depending on the image option you choose.

### Azure Gallery Image
By selecting Azure Gallery Image, you can select up-to-date images provided by Microsoft and other publishers. Enter or select values for the following parameters:
- **Rdsh Image Source**, select **Gallery**.
- **Rdsh Gallery Image SKU**

Ignore the following parameters:
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
  
  > [!WARNING]
  **Rdsh Use Managed Disks** will **not** be allowed to be **false**, starting **March 1st, 2020**.

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
- **Vm Size**
- **Enable Accelerated Networking**. Please notice that VM size must support it, this is supported in most of general purpose and compute-optimized instances with 2 or more vCPUs, on instances that supports hyperthreading it is required minimum of 4 vCPUs. Default value is `false`.
- **Rdsh Name Prefix**
  > [!WARNING]
  Starting from **June 1st 2020**, this parameter will be renamed to **newRdshNamePrefix** and the default value for this parameter will be removed, so the value will need to be specified.
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

## Authentication to Windows Virtual Desktop
Enter the following information to authenticate to Windows Virtual Desktop and register the new virtual machines as session hosts to a new or existing host pool.

- **Rd Broker URL**
- **Existing Tenant Group Name**. If you were not given a specific tenant group name, leave this value as "Default Tenant Group".
- **Existing Tenant Name**
- **Existing Host Pool Name**
- **Tenant Admin Upn or Application Id**. If you are creating a new host pool, this principal must be assigned either the *RDS Owner* or *RDS Contributor* role at the tenant scope (or higher). If you are registering these virtual machines to an existing host pool, this principal must be assigned either the *RDS Owner* or *RDS Contributor* role at the host pool scope (or higher).

  > [!WARNING]
  You cannot enter a UPN that requires MFA to successfully authenticate. If you do, this template will create the virtual machines but fail to register them to a host pool.

- **Tenant Admin Password**
- **Is Service Principal**. If you select **True** for **Is Service Principal**, enter your Azure AD tenant ID for the **Aad Tenant Id** parameter to properly identify the directory of your service principal and successfully authenticate to Windows Virtual Desktop. Otherwise, leave the **Aad Tenant Id** parameter empty.

## Update Actions
When updating a host pool, you can choose how to notify users who are currently connected and how to handle the previous session host VMs.
- **ActionOnPreviousVirtualMachines**. Select **Delete** or **Deallocate**. If **Delete** is selected, the previous session host VMs will be deleted, along with the associated network interfaces and OS disk. If **Deallocate** is selected, Azure VMs (hosts) will be removed from hostpool and simply de-allocated in Azure, allowing you to preserve or connect to them later.
- **UserLogoffDelayInMinutes**. The delay before users are automatically logged off from existing sessions in the host pool.
- **UserNotificationMessage**. The message that will be sent to users with existing sessions before the logoff delay counter starts ticking. You can use this message to notify users to save their work or logoff themselves, before they will be logged off automatically. 

[![Deploy](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FRDS-Templates%2Fstaging%2Fwvd-templates%2FUpdate%20existing%20WVD%20host%20pool%2FmainTemplate.json)
