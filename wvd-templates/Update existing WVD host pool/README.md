[![Deploy](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FRDS-Templates%2Fmaster%2Fwvd-templates%2FUpdate%20existing%20WVD%20host%20pool%2FmainTemplate.json)

# ARM Template for WVD Hostpool Deployment

# Update Existing WVD Hostpool
This template will remove or stop the old instance of WVD Hostpool session hosts and creates new virtual machines and registers them as session hosts to wvd host pool. There are different sets of parameters you must enter to successfully deploy the template:

- ActionOnPreviousVirtualMachines
- VM image Type
- RDSH VM Configuration in Azure
- Domain and Network Properties
- Authentication to Windows Virtual Desktop

Follow the guidance below for entering the appropriate parameters for your scenario.

## ActionOnPreviousVirtualMachines
When you take action on previous virtual machines, you have two options:

- Delete
- Deallocate

Action to be taken on the old Azure VM resources. If delete is selected, the associated network interfaces, managed disks and vhd files in Azure blob storage will also be deleted. If Deallocate is selected, Azure VMs (hosts) will be removed from hostpool and Stopped in Azure.

And provide below parameter values if user is accessing remote resources remotely will be notified to them.

- **UserLogoffDelayInMinutes** Note: Delay before users are automatically logged off from the current VMs in the hostpool.
- **UserNotificationMessege** Note: Message that will be displayed to the user notifying them of the automatic logoff.

## VM Image Type
When creating the new virtual machines, you have three options:

- Azure Gallery Image
- Custom VHD from blob storage
- Custom Azure Image resource from a resource group

Enter the appropriate depending on the image option you choose.

### Azure Gallery Image
By selecting azure gallery Image, provide below parameter values

- **RDSHImageSource** as **Gallery**
- **RdshGalleryImageSKU**
- **Rdsh Use Managed Disks**
- **Storage Account Name**. (Required when rdshImageSource = Gallery and RdshUseManagedDisks = False) The name of the storage account to store the unmanaged disks from an Azure Gallery image. If you decide to use unmanaged disks from a custom vhd, the disks will be stored in the same storage account as the image. 

Ignore the following parameters:
- **Vm Image Vhd Uri**
- **Storage Account Resource Group Name**
- **Rdsh Custom Image Source Name**
- **Rdsh Custom Image Source Resource Group**

### Custom VHD from Blob Storage

By selecting a custom VHD from blob storage, you can create your own image locally through Hyper-V or on an Azure VM. Enter or select values for the following parameters:

- **Rdsh Image Source** select **CustomVHD**.
- **Vm Image Vhd Uri**
- **Rdsh Is Windows Server**. Note: Windows 10 Enterprise multi-session is not considered Windows Server.
- **Rdsh Use Managed Disks**. If you select **false** for **Rdsh Use Managed Disks**, enter the name of the resource group containing the storage account and image for the **Storage Account Resource Group Name** parameter. Otherwise, leave the Storage Account Resource Group Name parameter empty.

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

### RDSH VM Configuration
Enter the remaining configuration parameters for the virtual machines.

- **Rdsh Name Prefix**
- **Rdsh Number Of Instances**
- **Rdsh VM Disk Type**. If you selected **CustomVHD** as the **Rdsh Image Source** and **false** for **Rdsh Use Managed Disks**, ensure that this parameter matches the storage account type where the source image is located.

### Domain and Network Properties

Enter the following properties to connect the virtual machines to the appropriate network and join them to the appropriate domain (and organizational unit, if defined).

- **Domain To Join**
- **Existing Domain UPN**. This UPN must have appropriate permissions to join the virtual machines to the domain and organizational unit.
- **Existing Domain Password**
- **OU Path**. If you do not have a specific organizaiton unit for the virtual machines to join, leave this parameter empty.
- **Existing Vnet Name**
- **Existing Subnet Name**
- **Virtual Network Resource Group Name**

### Authentication to Windows Virtual Desktop

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

[![Deploy](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FRDS-Templates%2Fmaster%2Fwvd-templates%2FUpdate%20existing%20WVD%20host%20pool%2FmainTemplate.json)

