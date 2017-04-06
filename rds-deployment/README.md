# Create Remote Desktop Session Collection deployment

This template deploys the following resources:

* storage account
* vnet, public ip, load balancer
* domain controller vm
* RD Gateway and Web Access vm
* RD Connection Broker/RD Licensing Server vm
* a number of RD Session hosts (number defined by 'numberOfRdshInstances' parameter)

The template will deploy DC, join all virtual machines to the domain, and configure RDS roles in the deployment.

Click the button below to deploy

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fazure-quickstart-templates%2Fmaster%2Frds-deployment%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fazure-quickstart-templates%2Fmaster%2Frds-deployment%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

## Documentation
[Basic RDS farm Deployment](https://azure.microsoft.com/en-us/documentation/templates/rds-deployment/) contains additional information about this template.

[Azure Resource Naming Conventions](https://docs.microsoft.com/en-us/azure/architecture/best-practices/naming-conventions) contains naming rules and restrictions for Azure resource conventsions.

[Naming conventions in Active Directory](https://support.microsoft.com/en-us/help/909264/naming-conventions-in-active-directory-for-computers,-domains,-sites,-and-ous) contains information about Active Directory object conventions.

### Base parameters:

* Location - location for new deployment. 
    * PowerShell enumeration: ```Get-AzureRmLocation```
* ResourceGroup - name of new or existing resource group. 
    * PowerShell new resource group: ```New-AzureRmResourceGroup -Location $location```
* ResourceGroupDeployment - name of new or existing resource group deployment. 
    * PowerShell new deployment: ```New-AzureRmResourceGroupDeployment -Location $location <...>```
 
* adDomainName - active directory domain name. Limited to netbios naming conventions (15 alphanumeric characters).
* adminPassword - password for administrator account both locally and in domain.
    * The supplied password must be between 8-123 characters long and must satisfy at least 3 of password complexity requirements from the following: 
        * Contains an uppercase character
        * Contains a lowercase character
        * Contains a numeric digit
        * Contains a special character.
* adminUsername - Active Directory and local administrator account name. User name conforms to Active Directory user name convention.
* gwdnsLabelPrefix -  DNS domain name which is typically the same as the Active Directory name but is not a requirement. See [Naming conventions in Active Directory](https://support.microsoft.com/en-us/help/909264/naming-conventions-in-active-directory-for-computers,-domains,-sites,-and-ous)
* gwpublicIPAddressName - Azure resource name for the public load balanced address for RDS gateway. this is set to 'gwpip' by default.
* imageSKU - operating system version for all instances. '2016-Datacenter' or '2012-R2-Datacenter'.
    * PowerShell enumeration: ```Get-AzureRmVMImageSku -Location $location -PublisherName MicrosoftWindowsServer -Offer WindowsServer```
* numberOfRdshInstances - number of RDS host servers to deploy. Other instances dc, gateway, and broker are set to 1 instance.
* rdshVmSize - virtual machine size for the RDS host server instances only. Other instances dc, gateway, and broker are set to size Standard_A2. 
    * PowerShell enumeration: ```Get-AzureRmVMSize -Location $location```

## Custom Configuration
This template has optional parameters that can be specified for custom deployments such as DNS servers and VNET subnet information. 
In the Azure portal, these optional parameters (variables) are not exposed directly through the interface. To modify these variables in the Azure portal,
select 'Edit' to edit the deployment template and modify the variables that need customization. To provide custom parameters (variables) using PowerShell,
a 'parameter' json file (TemplateParameterFile) can be used. Both 'azuredeploy.parameters.json' and 'vnet-with-dns-servers.json' are example parameter json files. 

**Custom Configuration Example:**

Note: The following commands require at least Windows Management Framework 5.0 and Azure RM SDK.   
```   
New-AzureRmResourceGroup -Name ExampleResourceGroup -Location "westus"  
New-AzureRmResourceGroupDeployment -Name ExampleDeployment `
  -ResourceGroupName ExampleResourceGroup `
  -TemplateFile https://raw.githubusercontent.com/azure/azure-quickstart-templates/master/rds-deployment/azuredeploy.json `
  -TemplateParameterFile c:\temp\rds-deployment\azuredeploy.parameters.json  
```
## Post Deployment
After deployment completes successfully, use one of the options below to connect to the new deployment.
After deploying this template, the following will need to be configured:

* Remote Desktop Services Licensing (there is an initial 120 day grace period). 
    * See [License your RDS deployment with client access licenses](https://technet.microsoft.com/en-us/windows-server-docs/compute/remote-desktop-services/rds-client-access-license) for information on licensing and steps to configure.
* Trusted certificates for connectivity and RDS infrastructure (optional best practice)
* User Profile Disks (optional best practice)

### Connect to new deployment
After successful deployment, the URL for the Remote Desktop Gateway (RDGW) and RDWeb site will be https://%gwdnsLabelPrefix%.%location%.cloudapp.azure.com/RDWeb. A self-signed certificate will be used for the deployment. To prevent certificate mismatch issues when connecting using a self-signed certificate, the certificate will need to be installed on the local client machines 'Trusted Root' certificate store. Best practice for a production environment is to configure the deployment to use a trusted certificate.

**To install the self-signed certificate into local machine 'Trusted Root' certificate store:**
1. From administrative Internet Explorer, browse to URL.
   * Example from above: 'https://contoso.westus.cloudapp.azure.com'
2. In address bar, click on 'Certificate Error' -> 'View Certificates'
3. Select 'Install Certificate...'
    * certificate name should be in the format of 'CN=%gwdnsLabelPrefix%.%location%.cloudapp.azure.com'
    * Example from above: 'CN=contoso.westus.cloudapp.azure.com'
6. Store location is 'Local Machine'
7. Select 'Browse' for 'Place all certificates in the following store'
8. Select 'Trusted Root Certification Authorities'
9. After the certificate has been installed, in RDWeb, logon with the domain credentials that were configured when deploying template.
10. Launch 'Desktop Collection'

### Connect to new deployment with PowerShell script
This script can be used configure and connect to new deployment automatically. This script requires at least Windows Management Framework 5.0 and Azure RM SDK.  
[Azure Resource Manager Post Deployment RDP Connectivity](https://aka.ms/azure-rm-rdp-post-deployment.ps1)

## Troubleshooting
If the deployment did not complete successfully or if you are having issues connecting to the environment, use one of the options below:

### Review deployment events in Azure portal
In [Azure Portal](https://portal.azure.com), select the 'Resource Group' containing the deployment. Select 'Overview' if not selected, and the 'Deployments' summary link will be displayed. Selecting the link will navigate to the individual deployments and associated events.

### Review deployment events with PowerShell
In PowerShell, the following azurerm module commandlets can be used to gather deployment events:
- Get-AzureRmLog 
- Get-AzureRmResourceGroupDeployment
- Get-AzureRmResourceGroupDeploymentOperation

### Review deployment events with PowerShell script
This script can be used review deployment events. This script requires at least Windows Management Framework 5.0 and Azure RM SDK.  
[Azure Resource Manager Deployment Log Reader](https://aka.ms/azure-rm-log-reader.ps1)

## Validation / Example deployment script
This script is used for rds-deployment template testing. It performs basic validation of given parameters and will by default deploy a new deployment.

[art-rds-deployment-test.ps1](https://raw.githubusercontent.com/azure/azure-quickstart-templates/master/rds-deployment/scripts/art-rds-deployment-test.ps1)
```
SYNTAX

    .\art-rds-deployment-test.ps1 [[-adDomainName] <String>] [[-adminUsername] <String>] [[-adminPassword] <String>] [[-credentials] <PSCredential>] [[-deploymentName] <String>] [[-gwdnsLabelPrefix] <String>] 
    [[-gwpublicIPAddressName] <String>] [[-imageSKU] <String>] [[-numberofRdshInstances] <Int32>] [[-location] <String>] [-monitor] [-postConnect] [[-rdshVmSize] <String>] [-resourceGroup] <String> [-savePassword] [-test] 
    [[-useJson] <String>] [<CommonParameters>]
    
PARAMETERS  

    -adDomainName <String>
        if specified, is the new AD domain fqdn used for this deployment. by default %resourceGroup%.lab will be used.
        Required?                    false
        Default value                %resourceGroup%
        
    -adminUsername <String>
        if specified, the name of the administrator account. by default vmadmin is used
        Required?                    false
        Default value                vmadmin
        
    -adminPassword <String>
        if specified, the administrator account password in clear text. password needs to meet azure password requirements.
        use -credentials to pass credentials securely
        Required?                    false
        Default value                
        
    -credentials <PSCredential>
        can be used for administrator account password. password needs to meet azure password requirements.
        Required?                    false
        Default value                
        
    -deploymentName <String>
        Required?                    false
        Default value                %resourceGroup%
        
    -gwdnsLabelPrefix <String>
        If specified, is the public DNS name label for gateway. default is the AD Domain prefix.
        Required?                    false
        Default value                %resourceGroup%
        
    -gwpublicIPAddressName <String>
        If specified, is the public ip address name. by default will use gwpip
        Required?                    false
        Default value                gwpip
        
    -imageSKU <String>
        default 2016-datacenter or optional 2012-r2-datacenter for OS selection type
        Required?                    false
        Default value                2016-Datacenter
        
    -numberofRdshInstances <Int32>
        number of rdsh instances to create. by default this is 2
        Required?                    false
        Default value                2
        
    -location <String>
        If specified, is the azure regional datacenter location. by default will use eastus
        Required?                    true
        Default value                
        
    -monitor [<SwitchParameter>]
        If specified, will run "https://aka.ms/azure-rm-log-reader.ps1" before deployment
        Required?                    false
        Default value                False
        
    -postConnect [<SwitchParameter>]
        If specified, will run "https://aka.ms/azure-rm-rdp-post-deployment.ps1" following deployment
        Required?                    false
        Default value                False
        
    -rdshVmSize <String>
        size is the size of the azure vm's to use. If not specified, A1 will be used.
        Required?                    false
        Default value                Standard_A1
        
    -resourceGroup <String>
        resourceGroup is a mandatory paramenter and is the azure arm resourcegroup to use / create for this deployment
        Required?                    true
        
    -savePassword [<SwitchParameter>]
        if specified, will save the password in clear text into json file. default is to leave value empty
        Required?                    false
        Default value                False

    -test [<SwitchParameter>]
        If specified, will test script and parameters but will not start deployment
        Required?                    false
        Default value                False

    -useJson <String>
        If specified, will use passed json file for arguments when deploying
        Required?                    false
    
    -------------------------- EXAMPLE 1 --------------------------
    PS C:\>.\art-rds-deployment-test.ps1 -adminPassword changeme3240e2938r92 -resourceGroup rdsdeptest
    Example command to deploy rds-deployment with 2 instances using A1 machines. the resource group is rdsdeptest and domain fqdn is rdsdeptest.lab
    
    -------------------------- EXAMPLE 2 --------------------------
    PS C:\>.\art-rds-deployment-test.ps1 -adminPassword changeme3240e2938r92 -resourceGroup rdsdeptest -admin vmadministrator -instances 5 -size Standard_A4 -imagesku 2012-r2-Datacenter
    Example command to deploy rds-deployment with 5 instances using A4 machines. the resource group is rdsdeptest and domain fqdn is rdsdeptest.lab. 
    the admin account is vmadministrator and OS is 2012-r2-datacenter
    
    -------------------------- EXAMPLE 3 --------------------------
    PS C:\>.\art-rds-deployment-test.ps1 -useJson .\myexistingparameterfile.json
    Example command to deploy rds-deployment with a populated parameter json file.
    all properties from json file will be used. if no password is supplied, you will be prompted.
    
    -------------------------- EXAMPLE 4 --------------------------
    PS C:\>.\art-rds-deployment-test.ps1 -adminPassword changeme3240e2938r92 -resourceGroup rdsdeptest -monitor -postConnect
    Example command to deploy rds-deployment with 2 instances using A1 machines. the resource group is rdsdeptest and domain fqdn is rdsdeptest.lab
    before calling New-AzureRmResourceGroupDeployment, the powershell monitor script will be called.
    after successful deployment, the post connect powershell script will be called.

```
`Tags: Remote Desktop Services, RDS`