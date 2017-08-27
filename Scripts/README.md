# Validation / Example deployment script
This folder contains scripts used to assist with testing / deploying rds-templates.
[deploy-rds-templates.ps1](deploy-rds-templates.ps1) script is the main script used for rds-deployment template testing. It performs basic validation of given parameters and will by default deploy a new HA deployment. It requires WMF 5.0 + and Azure PowerShell SDK which will be installed if missing.

deploy-rds-templates.ps1 script has many parameters but only a few are needed for basic testing. See below for some examples on how to call script for different scenarios and for detailed information on all parameters.

To test individual templates, supply a single template name or a comma separated list of template names in order for '-installOptions' switch. Most installOptions will install just the template argument. Exceptions to this are below:

| -installOptions      | installs                                   |
|---------------|---------------------------------------------------|
| default (null)       | rds-deployment                             |
|                      | rds-deployment-ha-broker                   |
|                      | rds-deployment-ha-gateway                  |
|                      | rds-update-certificate                     |
| rds-deployment-existing-ad       | ad-domain-only-test (will prompt in case domain does not exist)     |
|                      | rds-deployment-existing-ad                   |
| rds-deployment-uber  | ad-domain-only-test (will prompt in case domain does not exist)          |
|                      | rds-deployment-existing-ad                 |
|                      | rds-deployment-ha-broker                   |
|                      | rds-deployment-ha-gateway                  |
|                      | rds-update-certificate                     |


To test with a branch other than 'master', supply the base repo Uri (not base template directory) to be used for deployment. See examples below.

## Minimal deployment non HA with new Active Directory, vnet, subnet. 
| Total vms: 4|                                                     |
|---------------|---------------------------------------------------|
| addc-01       | domain controller                                 |
| rdcb-01       | remote desktop connection broker / licensing      |
| rdgw-01       | remote desktop gateway / web                      |
| rdsh-01       | remote session host                               |
---
| Required Parameters:  |                           |
|-----------------------|---------------------------|
| location              | %valid azure location%    |
| numberOfRdshInstances | 1                         |
| installOptions        |rds-deployment             |
---
| Recommended Parameters:   |                       |
|---------------------------|-----------------------|
| resourceGroup             |
| adminPassword             |
| pfxFilePath               |
| domainName                |
---
### Example Commands:
### production deployment with real X509 .pfx certificate:
```powershell
.\deploy-rds-templates.ps1 -location westus `
    -numberOfRdshInstances 1 `
    -installOptions rds-deployment `
    -resourceGroup rdscontosolab `
    -domainName contoso.com `
    -pfxFilePath c:\temp\star.contoso.com.pfx
```
### test deployment with minimal parameters. non defined parameters will be auto-generated:
```powershell
.\deploy-rds-templates.ps1 -location westus `
    -numberOfRdshInstances 1 `
    -installOptions rds-deployment
```
### test deployment without real certificate:
```powershell
.\deploy-rds-templates.ps1 -location westus `
    -numberOfRdshInstances 1 `
    -installOptions rds-deployment `
    -resourceGroup rdscontosolab `
    -domainName contoso.com
```
### development deployment with build branch:
```powershell
.\deploy-rds-templates.ps1 -location westus `
    -numberOfRdshInstances 1 `
    -installOptions rds-deployment `
    -templateBaseRepoUri "https://raw.githubusercontent.com/jagilber/RDS-Templates/issue61/"
```
## Full HA deployment with new Active Directory, Azure SQL, vnet, subnet. 
| Total vms: 8  |                                                 |
|---------------|---------------------------------------------------|
| addc-01       | domain controller                                 |
| rdcb-01       | remote desktop connection broker / licensing      |
| rdcb-02       | remote desktop connection broker                  |
| rdgw-01       | remote desktop gateway / web                      |
| rdgw-02       | remote desktop gateway / web                      |
| rdsh-01       | remote session host                               |
| rdsh-02       | remote session host                               |
| sql-server    | azure sql server (paas)                           |
---
| Required Parameters:  |                           |
|-----------------------|---------------------------|
| location              | %valid azure location%    |
---
| Recommended Parameters:   |                       |
|---------------------------|-----------------------|
| resourceGroup             |
| adminPassword             |
| pfxFilePath               |
| domainName                |
---

### Example Commands:
### production HA deployment with real X509 .pfx certificate:
```powershell
.\deploy-rds-templates.ps1 -location westus `
    -resourceGroup rdscontosolab `
    -domainName contoso.com `
    -pfxFilePath c:\temp\star.contoso.com.pfx
```
### test HA deployment with minimal parameters. non defined parameters will be auto-generated:
```powershell
.\deploy-rds-templates.ps1 -location westus 
```
### test HA deployment without real certificate:
```powershell
.\deploy-rds-templates.ps1 -location westus `
    -resourceGroup rdscontosolab `
    -domainName contoso.com
```
### development HA deployment with build branch:
```powershell
.\deploy-rds-templates.ps1 -location westus `
    -templateBaseRepoUri "https://raw.githubusercontent.com/jagilber/RDS-Templates/issue61/"
```

## Minimal deployment non HA with existing Active Directory, vnet, subnet. 
| Total vms: 3  |                                                     |
|---------------|---------------------------------------------------|
| rdcb-01       | remote desktop connection broker / licensing      |
| rdgw-01       | remote desktop gateway / web                      |
| rdsh-01       | remote session host                               |
---
| Required Parameters (Production):  |                  |
|-----------------------|-------------------------------|
| location              | %valid azure location%        |
| numberOfRdshInstances | 1                             |
| installOptions        | rds-deployment-existing-ad    |
| domainName            | %existing domain name%        |
| adminPassword         | %existing admin password%     |
| adminUsername         | %existing admin user name%    |

| Required Parameters (Test):  |                  |
|-----------------------|-------------------------------|
| location              | %valid azure location%        |
| numberOfRdshInstances | 1                             |
| installOptions        | rds-deployment-existing-ad    |
---
| Recommended Parameters:   |                       |
|---------------------------|-----------------------|
| resourceGroup             |
| pfxFilePath               |
---
### Example Commands:
### production deployment with existing AD, real X509 .pfx certificate:
```powershell
.\deploy-rds-templates.ps1 -location westus `
    -numberOfRdshInstances 1 `
    -installOptions rds-deployment-existing-ad `
    -resourceGroup rdscontosolab `
    -domainName contoso.com `
    -adminPassword Password4341275! `
    -adminUsername administrator `
    -pfxFilePath c:\temp\star.contoso.com.pfx
```
### test deployment with minimal parameters. non defined parameters will be auto-generated. will be prompted to create test domain:
```powershell
.\deploy-rds-templates.ps1 -location westus `
    -numberOfRdshInstances 1 `
    -installOptions rds-deployment-existing-ad
```
### test deployment without real certificate. will be prompted to create test domain:
```powershell
.\deploy-rds-templates.ps1 -location westus `
    -numberOfRdshInstances 1 `
    -installOptions rds-deployment-existing-ad `
    -resourceGroup rdscontosolab `
    -domainName contoso.com
```
### development deployment with build branch. will be prompted to create test domain:
```powershell
.\deploy-rds-templates.ps1 -location westus `
    -numberOfRdshInstances 1 `
    -installOptions rds-deployment-existing-ad `
    -templateBaseRepoUri "https://raw.githubusercontent.com/jagilber/RDS-Templates/issue61/"
```
## Full HA deployment with existing Active Directory, Azure SQL, vnet, subnet. 
| Total vms: 7  |                                                 |
|---------------|---------------------------------------------------|
| rdcb-01       | remote desktop connection broker / licensing      |
| rdcb-02       | remote desktop connection broker                  |
| rdgw-01       | remote desktop gateway / web                      |
| rdgw-02       | remote desktop gateway / web                      |
| rdsh-01       | remote session host                               |
| rdsh-02       | remote session host                               |
| sql-server    | azure sql server (paas)                           |
---
| Required Parameters (Production):  |                  |
|-----------------------|-------------------------------|
| location              | %valid azure location%        |
| installOptions        | rds-deployment-uber    |
| domainName            | %existing domain name%        |
| adminPassword         | %existing admin password%     |
| adminUsername         | %existing admin user name%    |

| Required Parameters (Test):  |                  |
|-----------------------|-------------------------------|
| location              | %valid azure location%        |
| installOptions        | rds-deployment-uber           |
---
| Recommended Parameters:   |                       |
|---------------------------|-----------------------|
| resourceGroup             |
| adminPassword             |
| pfxFilePath               |
| domainName                |
---

### Example Commands:
### production HA deployment with existing AD, real X509 .pfx certificate:
```powershell
.\deploy-rds-templates.ps1 -location westus `
    -resourceGroup rdscontosolab `
    -installOptions rds-deployment-uber `
    -domainName contoso.com `
    -adminPassword Password4341275! `
    -adminUsername administrator `
    -pfxFilePath c:\temp\star.contoso.com.pfx
```
### test HA deployment with minimal parameters. non defined parameters will be auto-generated. will be prompted to create test domain:
```powershell
.\deploy-rds-templates.ps1 -location westus `
    -installOptions rds-deployment-uber
```
### test HA deployment without real certificate. will be prompted to create test domain:
```powershell
.\deploy-rds-templates.ps1 -location westus `
    -resourceGroup rdscontosolab `
    -installOptions rds-deployment-uber `
    -domainName contoso.com
```
### development HA deployment with build branch. will be prompted to create test domain:
```powershell
.\deploy-rds-templates.ps1 -location westus `
    -installOptions rds-deployment-uber `
    -templateBaseRepoUri "https://raw.githubusercontent.com/jagilber/RDS-Templates/issue61/"
```

## Script Help File
```
PS G:\github\RDS-Templates\Scripts> help .\deploy-rds-templates.ps1 -Full

NAME
    G:\github\RDS-Templates\Scripts\deploy-rds-templates.ps1
    
SYNOPSIS
    powershell script to test and deploy azure rds quickstart templates
    
    
SYNTAX
    G:\github\RDS-Templates\Scripts\deploy-rds-templates.ps1 [[-random] <String>] [[-adminUserName] <String>] [[-adminPassword] <String>] [[-applicationId] <String>] [[-brokerName] <String>] [[-resourceGroup] <String>] 
    [[-domainName] <String>] [[-certificateName] <String>] [[-applicationPassword] <String>] [[-clientAccessName] <String>] [[-credentials] <PSCredential>] [[-dnsLabelPrefix] <String>] [[-dnsServer] <String>] 
    [[-gatewayLoadBalancer] <String>] [[-gwAvailabilitySet] <String>] [[-installOptions] <String[]>] [[-imageSku] <String>] [[-location] <String>] [[-logoffTimeInminutes] <Int32>] [-monitor] [[-numberOfRdshInstances] 
    <Int32>] [[-numberOfWebGwInstances] <Int32>] [[-parameterFileAdDeployment] <String>] [[-parameterFileRdsDeployment] <String>] [[-parameterFileRdsDeploymentExistingAd] <String>] [[-parameterFileRdsUpdateCertificate] 
    <String>] [[-parameterFileRdsHaBroker] <String>] [[-parameterFileRdsHaGateway] <String>] [[-parameterFileRdsUber] <String>] [[-parameterFileRdsUpdateRdshCollection] <String>] [-pause] [[-pfxFilePath] <String>] 
    [-postConnect] [[-gatewayPublicIp] <String>] [[-primaryDbConnectionString] <String>] [[-rdshAvailabilitySet] <String>] [[-rdshCollectionName] <String>] [[-rdshVmSize] <String>] [[-rdshTemplateImageUri] <String>] 
    [[-rdshUpdateIteration] <String>] [[-sqlServer] <String>] [[-subnetName] <String>] [[-templateBaseRepoUri] <String>] [[-templateVmNamePrefix] <String>] [[-tenantId] <String>] [-useExistingJson] [[-vaultName] <String>] 
    [[-vnetName] <String>] [-whatIf] [<CommonParameters>]
    
    
DESCRIPTION
    powershell script to test and deploy azure rds quickstart templates
    https://github.com/Azure/rds-templates/
    
    to enable script execution, you may need to Set-ExecutionPolicy Bypass -Force
    
    Copyright 2017 Microsoft Corporation
    
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    
        http://www.apache.org/licenses/LICENSE-2.0
    
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
    

PARAMETERS
    -random <String>
        
        Required?                    false
        Position?                    1
        Default value                (get-random)
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -adminUserName <String>
        the name of the administrator account. 
        default is 'cloudadmin'
        
        Required?                    false
        Position?                    2
        Default value                cloudadmin
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -adminPassword <String>
        the administrator account password in clear text. password needs to meet azure password requirements.
        use -credentials to pass credentials securely
        default is 'Password(get-random)!'
        
        Required?                    false
        Position?                    3
        Default value                "Password$($random)!"
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -applicationId <String>
        
        Required?                    false
        Position?                    4
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -brokerName <String>
        
        Required?                    false
        Position?                    5
        Default value                rdcb-01
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -resourceGroup <String>
        resourceGroup is a mandatory parameter and is the azure arm resourcegroup to use / create for this deployment. 
        default is 'resourceGroup(get-random)'
        
        Required?                    false
        Position?                    6
        Default value                "resourceGroup$($random)"
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -domainName <String>
        new AD domain fqdn used for this deployment. 
        NOTE: base domain name for example 'contoso' can not be longer than 15 chars
        default is contoso.com.
        
        Required?                    false
        Position?                    7
        Default value                "$($resourceGroup).lab"
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -certificateName <String>
        name of certificate to create / use
        default is "$($resourceGroup)Certificate"
        
        Required?                    false
        Position?                    8
        Default value                "$($resourceGroup)Certificate"
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -applicationPassword <String>
        password to create / use for certificate access
        default is $adminPassword
        
        Required?                    false
        Position?                    9
        Default value                $adminPassword
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -clientAccessName <String>
        rds client access name for HA only.
        non-ha will use rdcb-01
        default for HA is 'hardcb'
        
        Required?                    false
        Position?                    10
        Default value                HARDCB
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -credentials <PSCredential>
        can be used for administrator account password. password needs to meet azure password requirements.
        
        Required?                    false
        Position?                    11
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -dnsLabelPrefix <String>
        public DNS name label prefix for gateway. 
        default is <%resourceGroup%>.
        
        Required?                    false
        Position?                    12
        Default value                "$($resourceGroup.ToLower())"
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -dnsServer <String>
        DNS server OS name
        default is addc-01
        
        Required?                    false
        Position?                    13
        Default value                addc-01
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -gatewayLoadBalancer <String>
        
        Required?                    false
        Position?                    14
        Default value                loadbalancer
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -gwAvailabilitySet <String>
        
        Required?                    false
        Position?                    15
        Default value                gw-availabilityset
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -installOptions <String[]>
        array deployment templates to deploy in order specified.
        options are:
            "ad-domain-only-test", (for testing purposes only)
            "rds-deployment",
            "rds-update-certificate",
            "rds-deployment-ha-broker",
            "rds-deployment-ha-gateway",
            "rds-existing-ad",
            "rds-deployment-uber",
            "rds-update-rdsh-collection"
        
        default is rds full rds-deployment: "rds-deployment", "rds-update-certificate", "rds-deployment-ha-broker", "rds-deployment-ha-gateway"
        
        Required?                    false
        Position?                    16
        Default value                @("rds-deployment", "rds-update-certificate", "rds-deployment-ha-broker", "rds-deployment-ha-gateway")
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -imageSku <String>
        default 2016-datacenter or optional 2012-r2-datacenter for OS selection type
        NOTE: for HA Broker, 2016 is required
        
        Required?                    false
        Position?                    17
        Default value                2016-Datacenter
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -location <String>
        is the azure regional datacenter location. 
        default will display list of locations for use
        
        Required?                    false
        Position?                    18
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -logoffTimeInminutes <Int32>
        
        Required?                    false
        Position?                    19
        Default value                60
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -monitor [<SwitchParameter>]
        will run "https://aka.ms/azure-rm-log-reader.ps1" before deployment in separate powershell process
        
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -numberOfRdshInstances <Int32>
        number of remote desktop session host instances to create. 
        default value is 2
        
        Required?                    false
        Position?                    20
        Default value                2
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -numberOfWebGwInstances <Int32>
        number of additional remote desktop gateway instances to create for HA gateway mode. 
        default value is 1
        
        Required?                    false
        Position?                    21
        Default value                1
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -parameterFileAdDeployment <String>
        
        Required?                    false
        Position?                    22
        Default value                "$($env:TEMP)\ad-deployment-only-test.azuredeploy.parameters.json"
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -parameterFileRdsDeployment <String>
        path to template json parameter file for rds-deployment
        if -useExistingJson, existing json parameter file will be used without validation or modification
        default is $env:TEMP\rds-deployment.azuredeploy.parameters.json
        if not exists and not -useExistingJson base template from $templateBaseRepoUri/rds-deployment/azuredeploy.parameters.json will be used
        
        Required?                    false
        Position?                    23
        Default value                "$($env:TEMP)\rds-deployment.azuredeploy.parameters.json"
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -parameterFileRdsDeploymentExistingAd <String>
        
        Required?                    false
        Position?                    24
        Default value                "$($env:TEMP)\rds-deployment-existing-ad.azuredeploy.parameters.json"
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -parameterFileRdsUpdateCertificate <String>
        path to template json parameter file for rds-update-certificate
        if -useExistingJson, existing json parameter file will be used without validation or modification
        default is $env:TEMP\rds-udpate-certificate.azuredeploy.parameters.json
        if not exists and not -useExistingJson base template from $templateBaseRepoUri/rds-deployment-update-certificate/azuredeploy.parameters.json will be used
        
        Required?                    false
        Position?                    25
        Default value                "$($env:TEMP)\rds-update-certificate.azuredeploy.parameters.json"
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -parameterFileRdsHaBroker <String>
        path to template json parameter file for rds-deployment-ha-broker
        if -useExistingJson, existing json parameter file will be used without validation or modification
        default is $env:TEMP\rds-deployment-ha-broker.azuredeploy.parameters.json
        if not exists and not -useExistingJson base template from $templateBaseRepoUri/rds-deployment-ha-broker/azuredeploy.parameters.json will be used
        
        Required?                    false
        Position?                    26
        Default value                "$($env:TEMP)\rds-deployment-ha-broker.azuredeploy.parameters.json"
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -parameterFileRdsHaGateway <String>
        path to template json parameter file for rds-deployment-ha-gateway
        if -useExistingJson, existing json parameter file will be used without validation or modification
        default is $env:TEMP\rds-deployment-ha-gateway.azuredeploy.parameters.json
        if not exists and not -useExistingJson base template from $templateBaseRepoUri/rds-deployment-ha-gateway/azuredeploy.parameters.json will be used
        
        Required?                    false
        Position?                    27
        Default value                "$($env:TEMP)\rds-deployment-ha-gateway.azuredeploy.parameters.json"
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -parameterFileRdsUber <String>
        path to template json parameter file for rds-deployment-uber
        if -useExistingJson, existing json parameter file will be used without validation or modification
        default is $env:TEMP\rds-deployment-uber.azuredeploy.parameters.json
        if not exists and not -useExistingJson base template from $templateBaseRepoUri/rds-deployment-uber/azuredeploy.parameters.json will be used
        
        Required?                    false
        Position?                    28
        Default value                "$($env:TEMP)\rds-deployment-uber.azuredeploy.parameters.json"
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -parameterFileRdsUpdateRdshCollection <String>
        path to template json parameter file for rds-update-rdsh-collection
        if -useExistingJson, existing json parameter file will be used without validation or modification
        default is $env:TEMP\rds-udpate-rdsh-collection.azuredeploy.parameters.json
        if not exists and not -useExistingJson base template from $templateBaseRepoUri/rds-deployment-update-rdsh-collection/azuredeploy.parameters.json will be used
        
        Required?                    false
        Position?                    29
        Default value                "$($env:TEMP)\rds-update-rdsh-collection.azuredeploy.parameters.json"
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -pause [<SwitchParameter>]
        switch to enable pausing between deployments for verification
        
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -pfxFilePath <String>
        path to existing certificate to use with rds-update-certificate
        certificate should have private key
        default will generate a wildcard '*.contoso.com' self signed cert for testing purposes only
        
        Required?                    false
        Position?                    30
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -postConnect [<SwitchParameter>]
        will run "https://aka.ms/azure-rm-rdp-post-deployment.ps1" following deployment
        
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -gatewayPublicIp <String>
        
        Required?                    false
        Position?                    31
        Default value                gwpip
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -primaryDbConnectionString <String>
        ODBC connection string for HA Broker and uber deployments. should be similar to following syntax
        DRIVER=SQL Server Native Client 
        11.0;Server={enter_sql_server_here},1433;Database={enter_sql_database_here};Uid={enter_sql_admin_here}@{enter_sql_server_here};Pwd={enter_sql_password_here};Encrypt=yes;TrustServerCertificate=no;Connection 
        Timeout=30;
        
        Required?                    false
        Position?                    32
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -rdshAvailabilitySet <String>
        
        Required?                    false
        Position?                    33
        Default value                rdsh-availabilityset
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -rdshCollectionName <String>
        name of rds collection for use with rds-update-rdsh-collection
        
        Required?                    false
        Position?                    34
        Default value                Desktop Collection
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -rdshVmSize <String>
        size is of the azure vm's to use. 
        default is 'Standard_A2'
        
        Required?                    false
        Position?                    35
        Default value                Standard_A2
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -rdshTemplateImageUri <String>
        uri to blob storage containing a vhd of image to use for rds-update-rdsh-collection
        vhd OS image should have been sysprepped with c:\windows\system32\sysprep.exe -oobe -generalize
        also, in azure, set-azurermvm -ResourceGroupName $resourceGroup -Name $vm.Name -Generalized
        
        Required?                    false
        Position?                    36
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -rdshUpdateIteration <String>
        used to designate new deployment vm / OS name
        example:
            rdsh-01 (default)
            rdsh-101 (name of vm with rdshUpdateIteration set to 1)
        default is null
        
        Required?                    false
        Position?                    37
        Default value                1
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -sqlServer <String>
        OS name of existing sql server to use if not using Azure SQL
        
        Required?                    false
        Position?                    38
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -subnetName <String>
        name of subnet to create / use.
        default is 'subnet'
        
        Required?                    false
        Position?                    39
        Default value                subnet
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -templateBaseRepoUri <String>
        base template path for artifacts / scripts / dsc / templates
        default "https://raw.githubusercontent.com/Azure/RDS-Templates/master/"
        
        Required?                    false
        Position?                    40
        Default value                https://raw.githubusercontent.com/Azure/RDS-Templates/master/
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -templateVmNamePrefix <String>
        
        Required?                    false
        Position?                    41
        Default value                templateVm
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -tenantId <String>
        tenantId to be used in subscription for deployment
        default will be enumerated
        
        Required?                    false
        Position?                    42
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -useExistingJson [<SwitchParameter>]
        will use existing json file for arguments when deploying instead of overwriting
        
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -vaultName <String>
        name of vault to use / create for certificate use
        default is "$(resourceGroup)Cert"
        
        Required?                    false
        Position?                    43
        Default value                "$($resourceGroup)Cert"
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -vnetName <String>
        name of vnet to create / use
        default is 'vnet'
        
        Required?                    false
        Position?                    44
        Default value                vnet
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -whatIf [<SwitchParameter>]
        to test script actions with configuration but will not deploy
        
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see 
        about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216). 
    
INPUTS
    
OUTPUTS
    
NOTES
    
    
        file author: jagilber
        file name  : deploy-rds-templates.ps1
        version    : 170825 v1.0
    
    -------------------------- EXAMPLE 1 --------------------------
    
    PS C:\>.\deploy-rds-templates.ps1 -adminPassword changeme3240e2938r92 -resourceGroup rdsdeptest -location eastus -installOptions rds-deployment-uber
    
    Example command to deploy ad-domain-only-test,rds-deployment-existing-ad,rds-update-certificate,rds-ha-broker,rds-ha-gateway with 2 rdsh, 2 rdcb, and 2 rdgw instances using A2 machines. 
    the resource group is rdsdeptest and domain fqdn is rdsdeptest.lab
    
    
    
    
    -------------------------- EXAMPLE 2 --------------------------
    
    PS C:\>.\deploy-rds-templates.ps1 -adminPassword changeme3240e2938r92 -resourceGroup rdsdeptest -admin cloudadmin -numberOfRdshInstances 5 -rdshVmSize Standard_A4 -imagesku 2012-r2-Datacenter -installOptions 
    rds-deployment -location westus
    
    Example command to deploy rds-deployment with 5 instances using A4 machines. the resource group is rdsdeptest and domain fqdn is rdsdeptest.lab. 
    the admin account is cloudadmin and OS is 2012-r2-datacenter
    
    
    
    
    -------------------------- EXAMPLE 3 --------------------------
    
    PS C:\>.\deploy-rds-templates.ps1 -useExistingJson -parameterFileRdsDeployment c:\temp\rds-deployment.azuredeploy.parameters.json -location centralUs -installOptions rds-deployment-existing-ad
    
    Example command to deploy rds-deployment-existing-ad with a custom populated parameter json file c:\temp\rds-deployment.azuredeploy.parameters.json.
    since rds-deployment-existing-ad requires an existing domain, it will prompt to also install ad-domain-only-test.
    all properties from json file will be used. if no password is supplied, it will prompt.
    
    
    
    
    -------------------------- EXAMPLE 4 --------------------------
    
    PS C:\>.\deploy-rds-templates.ps1 -adminPassword changeme3240e2938r92 -resourceGroup rdsdeptest -monitor -postConnect -location eastus
    
    Example command to deploy rds-deployment,rds-ha-broker,rds-ha-gateway,rds-update-certificate with 2 instances using A2 machines. 
    the resource group is rdsdeptest and domain fqdn is rdsdeptest.lab
    before calling New-AzureRmResourceGroupDeployment, the powershell monitor script will be called.
    after successful deployment, the post connect powershell script will be called.
    
```
`Tags: Remote Desktop Services, RDS`