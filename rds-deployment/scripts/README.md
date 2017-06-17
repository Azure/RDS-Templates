## Validation / Example deployment script
[art-rds-deployment-test.ps1](art-rds-deployment-test.ps1) script is used for rds-deployment template testing. It performs basic validation of given parameters and will by default deploy a new deployment. It requires WMF 5.0 + and Azure PowerShell SDK.

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
        if specified, the name of the administrator account. by default cloudadmin is used
        Required?                    false
        Default value                cloudadmin
        
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
    PS C:\>.\art-rds-deployment-test.ps1 -adminPassword changeme3240e2938r92 -resourceGroup rdsdeptest -admin cloudadmin -instances 5 -size Standard_A4 -imagesku 2012-r2-Datacenter
    Example command to deploy rds-deployment with 5 instances using A4 machines. the resource group is rdsdeptest and domain fqdn is rdsdeptest.lab. 
    the admin account is cloudadmin and OS is 2012-r2-datacenter
    
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