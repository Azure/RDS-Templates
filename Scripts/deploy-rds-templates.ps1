<#
.SYNOPSIS
    powershell script to test and deploy azure rds quickstart templates

.DESCRIPTION
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
     
.NOTES
   file author: jagilber
   file name  : deploy-rds-templates.ps1
   version    : 170825 v1.0

.EXAMPLE
    .\deploy-rds-templates.ps1 -adminPassword changeme3240e2938r92 -resourceGroup rdsdeptest -location eastus -installOptions rds-deployment-uber
    Example command to deploy ad-domain-only-test,rds-deployment-existing-ad,rds-update-certificate,rds-ha-broker,rds-ha-gateway with 2 rdsh, 2 rdcb, and 2 rdgw instances using A2 machines. 
    the resource group is rdsdeptest and domain fqdn is rdsdeptest.lab

.EXAMPLE
    .\deploy-rds-templates.ps1 -adminPassword changeme3240e2938r92 -resourceGroup rdsdeptest -admin cloudadmin -numberOfRdshInstances 5 -rdshVmSize Standard_A4 -imagesku 2012-r2-Datacenter -installOptions rds-deployment -location westus
    Example command to deploy rds-deployment with 5 instances using A4 machines. the resource group is rdsdeptest and domain fqdn is rdsdeptest.lab. 
    the admin account is cloudadmin and OS is 2012-r2-datacenter

.EXAMPLE
    .\deploy-rds-templates.ps1 -useExistingJson -parameterFileRdsDeployment c:\temp\rds-deployment.azuredeploy.parameters.json -location centralUs -installOptions rds-deployment-existing-ad
    Example command to deploy rds-deployment-existing-ad with a custom populated parameter json file c:\temp\rds-deployment.azuredeploy.parameters.json.
    since rds-deployment-existing-ad requires an existing domain, it will prompt to also install ad-domain-only-test.
    all properties from json file will be used. if no password is supplied, it will prompt.

.EXAMPLE
    .\deploy-rds-templates.ps1 -adminPassword changeme3240e2938r92 -resourceGroup rdsdeptest -monitor -postConnect -location eastus
    Example command to deploy rds-deployment,rds-ha-broker,rds-ha-gateway,rds-update-certificate with 2 instances using A2 machines. 
    the resource group is rdsdeptest and domain fqdn is rdsdeptest.lab
    before calling New-AzureRmResourceGroupDeployment, the powershell monitor script will be called.
    after successful deployment, the post connect powershell script will be called.

.PARAMETER adminUsername
    the name of the administrator account. 
    default is 'cloudadmin'

.PARAMETER adminPassword
    the administrator account password in clear text. password needs to meet azure password requirements.
    use -credentials to pass credentials securely
    default is 'Password(get-random)!'

.PARAMETER applicationPassword
    password to create / use for certificate access
    default is $adminPassword

.PARAMETER certificateName
    name of certificate to create / use
    default is "$($resourceGroup)Certificate"

.PARAMETER clientAccessName
    rds client access name for HA only.
    non-ha will use rdcb-01
    default for HA is 'hardcb'

.PARAMETER credentials
    can be used for administrator account password. password needs to meet azure password requirements.

.PARAMETER dnsLabelPrefix
    public DNS name label prefix for gateway. 
    default is <%resourceGroup%>.

.PARAMETER dnsServer
    DNS server OS name
    default is addc-01

.PARAMETER domainName
    new AD domain fqdn used for this deployment. 
    NOTE: base domain name for example 'contoso' can not be longer than 15 chars
    default is contoso.com.

.PARAMETER imageSKU
    default 2016-datacenter or optional 2012-r2-datacenter for OS selection type
    NOTE: for HA Broker, 2016 is required

.PARAMETER installOptions
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

.PARAMETER location
    is the azure regional datacenter location. 
    default will display list of locations for use

.PARAMETER monitor
    will run "https://aka.ms/azure-rm-log-reader.ps1" before deployment in separate powershell process

.PARAMETER numberofRdshInstances
    number of remote desktop session host instances to create. 
    default value is 2

.PARAMETER numberofWebGwInstances
    number of additional remote desktop gateway instances to create for HA gateway mode. 
    default value is 1

.PARAMETER parameterFileRdsDeployment
    path to template json parameter file for rds-deployment
    if -useExistingJson, existing json parameter file will be used without validation or modification
    default is $env:TEMP\rds-deployment.azuredeploy.parameters.json
    if not exists and not -useExistingJson base template from $templateBaseRepoUri/rds-deployment/azuredeploy.parameters.json will be used

.PARAMETER parameterFileRdsDeployment
    path to template json parameter file for rds-deployment-existing-ad
    if -useExistingJson, existing json parameter file will be used without validation or modification
    default is $env:TEMP\rds-deployment-existing-ad.azuredeploy.parameters.json
    if not exists and not -useExistingJson base template from $templateBaseRepoUri/rds-deployment/azuredeploy.parameters.json will be used

.PARAMETER parameterFileRdsHaBroker
    path to template json parameter file for rds-deployment-ha-broker
    if -useExistingJson, existing json parameter file will be used without validation or modification
    default is $env:TEMP\rds-deployment-ha-broker.azuredeploy.parameters.json
    if not exists and not -useExistingJson base template from $templateBaseRepoUri/rds-deployment-ha-broker/azuredeploy.parameters.json will be used

.PARAMETER parameterFileRdsHaGateway
    path to template json parameter file for rds-deployment-ha-gateway
    if -useExistingJson, existing json parameter file will be used without validation or modification
    default is $env:TEMP\rds-deployment-ha-gateway.azuredeploy.parameters.json
    if not exists and not -useExistingJson base template from $templateBaseRepoUri/rds-deployment-ha-gateway/azuredeploy.parameters.json will be used

.PARAMETER parameterFileRdsUber
    path to template json parameter file for rds-deployment-uber
    if -useExistingJson, existing json parameter file will be used without validation or modification
    default is $env:TEMP\rds-deployment-uber.azuredeploy.parameters.json
    if not exists and not -useExistingJson base template from $templateBaseRepoUri/rds-deployment-uber/azuredeploy.parameters.json will be used

.PARAMETER parameterFileRdsUpdateCertificate
    path to template json parameter file for rds-update-certificate
    if -useExistingJson, existing json parameter file will be used without validation or modification
    default is $env:TEMP\rds-udpate-certificate.azuredeploy.parameters.json
    if not exists and not -useExistingJson base template from $templateBaseRepoUri/rds-deployment-update-certificate/azuredeploy.parameters.json will be used

.PARAMETER parameterFileRdsUpdateRdshCollection
    path to template json parameter file for rds-update-rdsh-collection
    if -useExistingJson, existing json parameter file will be used without validation or modification
    default is $env:TEMP\rds-udpate-rdsh-collection.azuredeploy.parameters.json
    if not exists and not -useExistingJson base template from $templateBaseRepoUri/rds-deployment-update-rdsh-collection/azuredeploy.parameters.json will be used

.PARAMETER pause
    switch to enable pausing between deployments for verification

.PARAMETER pfxFilePath
    path to existing certificate to use with rds-update-certificate
    certificate should have private key
    default will generate a wildcard '*.contoso.com' self signed cert for testing purposes only

.PARAMETER postConnect
    will run "https://aka.ms/azure-rm-rdp-post-deployment.ps1" following deployment

.PARAMETER primaryDBConnectionString
    ODBC connection string for HA Broker and uber deployments. should be similar to following syntax
    DRIVER=SQL Server Native Client 11.0;Server={enter_sql_server_here},1433;Database={enter_sql_database_here};Uid={enter_sql_admin_here}@{enter_sql_server_here};Pwd={enter_sql_password_here};Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;

.PARAMETER publicIPAddressName
    is the public ip address name. 
    default is 'gwpip'

.PARAMETER rdshCollectionName
    name of rds collection for use with rds-update-rdsh-collection

.PARAMETER rdshVmSize
    size is of the azure vm's to use. 
    default is 'Standard_A2'

.PARAMETER rdshTemplateImageUri
    uri to blob storage containing a vhd of image to use for rds-update-rdsh-collection
    vhd OS image should have been sysprepped with c:\windows\system32\sysprep.exe -oobe -generalize
    also, in azure, set-azurermvm -ResourceGroupName $resourceGroup -Name $vm.Name -Generalized 

.PARAMETER rdshUpdateIteration
    used to designate new deployment vm / OS name
    example:
        rdsh-01 (default)
        rdsh-101 (name of vm with rdshUpdateIteration set to 1)
    default is null

.PARAMETER resourceGroup
    resourceGroup is a mandatory parameter and is the azure arm resourcegroup to use / create for this deployment. 
    default is 'resourceGroup(get-random)'

.PARAMETER sqlServer
    OS name of existing sql server to use if not using Azure SQL
    
.PARAMETER subnetName
    name of subnet to create / use.
    default is 'subnet'

.PARAMETER templateBaseRepoUri
    base template path for artifacts / scripts / dsc / templates
    default "https://raw.githubusercontent.com/Azure/RDS-Templates/master/"

.PARAMETER tenantId
    tenantId to be used in subscription for deployment
    default will be enumerated

.PARAMETER useExistingJson
    will use existing json file for arguments when deploying instead of overwriting

.PARAMETER vaultName
    name of vault to use / create for certificate use
    default is "$(resourceGroup)Cert"

.PARAMETER vnetName
    name of vnet to create / use
    default is 'vnet'

.PARAMETER whatIf
    to test script actions with configuration but will not deploy
#>
[CMDLETBINDING()]
param(
    [string]$random = ((get-random).ToString().Substring(0, 9)), # positional requirement
    [string]$adminUserName = "cloudadmin",
    [string]$adminPassword = "Password$($random)!", 
    [string]$applicationId, 
    [string]$brokerName = "rdcb-01",
    [string]$resourceGroup = "resgrp$($random)",
    [string]$domainName = "$($resourceGroup).lab",
    [string]$certificateName = "$($resourceGroup)Certificate",
    [string]$applicationPassword = $adminPassword,
    [string]$clientAccessName = "HARDCB",
    [pscredential]$credentials,
    [string]$dnsLabelPrefix = "$($resourceGroup.ToLower())", # has to be unique
    [string]$dnsServer = "addc-01",
    [string]$gatewayLoadBalancer = "loadbalancer",
    [string]$gwAvailabilitySet = "gw-availabilityset",
    [string[]][ValidateSet("ad-domain-only-test", "rds-deployment", "rds-update-certificate", "rds-deployment-ha-broker", "rds-deployment-ha-gateway", "rds-deployment-uber", "rds-deployment-existing-ad", "rds-update-rdsh-collection")]
    $installOptions = @("rds-deployment", "rds-update-certificate", "rds-deployment-ha-broker", "rds-deployment-ha-gateway"),
    [string][ValidateSet('2012-R2-Datacenter', '2016-Datacenter')]$imageSku = "2016-Datacenter",
    [string]$location = "",
    [int]$logoffTimeInminutes = 60,
    [switch]$monitor,
    [int]$numberOfRdshInstances = 2,
    [int]$numberOfWebGwInstances = 1,
    [string]$parameterFileAdDeployment = "$($env:TEMP)\ad-deployment-only-test.azuredeploy.parameters.json",
    [string]$parameterFileRdsDeployment = "$($env:TEMP)\rds-deployment.azuredeploy.parameters.json",
    [string]$parameterFileRdsDeploymentExistingAd = "$($env:TEMP)\rds-deployment-existing-ad.azuredeploy.parameters.json",
    [string]$parameterFileRdsUpdateCertificate = "$($env:TEMP)\rds-update-certificate.azuredeploy.parameters.json",
    [string]$parameterFileRdsHaBroker = "$($env:TEMP)\rds-deployment-ha-broker.azuredeploy.parameters.json",
    [string]$parameterFileRdsHaGateway = "$($env:TEMP)\rds-deployment-ha-gateway.azuredeploy.parameters.json",
    [string]$parameterFileRdsUber = "$($env:TEMP)\rds-deployment-uber.azuredeploy.parameters.json",
    [string]$parameterFileRdsUpdateRdshCollection = "$($env:TEMP)\rds-update-rdsh-collection.azuredeploy.parameters.json",
    [switch]$pause,
    [string]$pfxFilePath,
    [switch]$postConnect,
    [string]$gatewayPublicIp = "gwpip",
    [string]$primaryDbConnectionString = "",
    [string]$rdshAvailabilitySet = "rdsh-availabilityset",
    [string]$rdshCollectionName = "Desktop Collection",
    [string]$rdshVmSize = "Standard_A2",
    [string]$rdshTemplateImageUri = "",
    [string]$rdshUpdateIteration = "1",
    [string]$sqlServer = "",
    [string]$subnetName = "subnet",
    [string]$templateBaseRepoUri = "https://raw.githubusercontent.com/Azure/RDS-Templates/master/",
    [string]$templateVmNamePrefix = "templateVm",
    [string]$tenantId,
    [switch]$useExistingJson,
    [string]$vaultName = "$($resourceGroup)Cert",
    [string]$vnetName = "vnet",
    [switch]$whatIf
)

$maxRdshTestInstances = 10
$templateFileName = "azuredeploy.parameters.json"


# ----------------------------------------------------------------------------------------------------------------
function main()
{
    $error.Clear()
    write-host "$(get-date) starting" -foregroundcolor cyan
    $timer = (get-date)
    get-variable | out-string

    if(!(runas-admin))
    {
        exit 1
    }
    
    write-host "using random: $($random)" -foregroundcolor yellow
    write-host "using password: $($adminPassword)" -foregroundcolor yellow
    write-host "using resource group: $($resourceGroup)" -foregroundcolor yellow
    write-host "authenticating to azure"

    authenticate-azureRm

    write-host "checking tenant id"
    if (!$tenantId)
    {
        $tenantId = (Get-AzureRmSubscription -warningAction SilentlyContinue).TenantId
    }

    write-host "checking parameters"
    check-parameters   
    check-resourceGroup

    foreach ($installOption in $installOptions)
    {
        switch ($installOption.ToString().ToLower())
        {
            "ad-domain-only-test" { start-ad-domain-only-test }
            "rds-deployment" { start-rds-deployment }
            "rds-update-certificate" {  start-rds-update-certificate }
            "rds-deployment-ha-broker" { start-rds-deployment-ha-broker }
            "rds-deployment-ha-gateway" { start-rds-deployment-ha-gateway }
            "rds-deployment-uber" { start-rds-deployment-uber }
            "rds-deployment-existing-ad" { start-rds-deployment-existing-ad }
            "rds-update-rdsh-collection" { start-rds-update-rdsh-collection }
            default: { Write-Error "unknown option $($installOption)" }
        } # end switch

        if ($pause)
        {
            pause
        }
    } # end foreach

    $rdWebSite = "https://$($dnsLabelPrefix).$($location).cloudapp.azure.com/RDWeb"

    if ($postConnect)
    {
        run-postConnect
    }

    write-host "errors: $($error | out-string)"
    write-host "-----------------------------------"

    write-host "resource group: $($resourceGroup)" -foregroundcolor yellow
    write-host "domain name: $($domainName)" -foregroundcolor yellow
    write-host "admin user name: $($adminUsername)" -foregroundcolor yellow
    write-host "admin password: $($adminPassword)" -foregroundcolor yellow
    write-host "rdweb site: $($rdWebSite)"
    write-host "$(get-date) finished. total time: $((get-date) -$timer)" -foregroundcolor cyan
}

# ----------------------------------------------------------------------------------------------------------------
function authenticate-azureRm()
{
    # make sure at least wmf 5.0 installed

    if ($PSVersionTable.PSVersion -lt [version]"5.0.0.0")
    {
        write-host "update version of powershell to at least wmf 5.0. exiting..." -ForegroundColor Yellow
        start-process "https://www.bing.com/search?q=download+windows+management+framework+5.0"
        exit
    }

    #  verify NuGet package
    $nuget = get-packageprovider nuget -Force

    if (-not $nuget -or ($nuget.Version -lt [version]::New("2.8.5.22")))
    {
        write-host "installing nuget package..."
        install-packageprovider -name NuGet -minimumversion ([version]::New("2.8.5.201")) -force
    }

    $allModules = (get-module azure* -ListAvailable).Name
    #  install AzureRM module
    if ($allModules -inotcontains "AzureRM")
    {
        # each has different azurerm module requirements
        # installing azurerm slowest but complete method
        # if wanting to do minimum install, run the following script against script being deployed
        # https://raw.githubusercontent.com/jagilber/powershellScripts/master/script-azurerm-module-enumerator.ps1
        # this will parse scripts in given directory and output which azure modules are needed to populate the below

        # at least need profile, resources, insights, logicapp for this script
        if ($allModules -inotcontains "AzureRM.profile")
        {
            write-host "installing AzureRm.profile powershell module..."
            install-module AzureRM.profile -force
        }
        if ($allModules -inotcontains "AzureRM.resources")
        {
            write-host "installing AzureRm.resources powershell module..."
            install-module AzureRM.resources -force
        }
        if ($allModules -inotcontains "AzureRM.compute")
        {
            write-host "installing AzureRm.compute powershell module..."
            install-module AzureRM.compute -force
        }
        if ($allModules -inotcontains "AzureRM.network")
        {
            write-host "installing AzureRm.network powershell module..."
            install-module AzureRM.network -force

        }
        if ($allModules -inotcontains "AzureRM.storage")
        {
            write-host "installing AzureRm.storage powershell module..."
            install-module AzureRM.storage -force

        }
        if ($allModules -inotcontains "AzureRM.sql")
        {
            write-host "installing AzureRm.sql powershell module..."
            install-module AzureRM.sql -force

        }
        if ($allModules -inotcontains "AzureRM.logicapp")
        {
            write-host "installing AzureRm.logicapp powershell module..."
            install-module AzureRM.logicapp -force

        }
        if ($allModules -inotcontains "AzureRM.insights")
        {
            write-host "installing AzureRm.insights powershell module..."
            install-module AzureRM.insights -force

        }   
        Import-Module azurerm.profile        
        Import-Module azurerm.resources        
        Import-Module azurerm.compute
        Import-Module azurerm.network
        Import-Module azurerm.storage
        Import-Module azurerm.sql
        Import-Module AzureRM.LogicApp
        Import-Module AzureRM.Insights
    }
    else
    {
        Import-Module azurerm
    }

    # authenticate
    try
    {
        $rg = @(Get-AzureRmTenant)
                
        if ($rg)
        {
            write-host "auth passed $($rg.Count)"
        }
        else
        {
            write-host "auth error $($error)" -ForegroundColor Yellow
            throw [Exception]
        }
    }
    catch
    {
        try
        {
            Add-AzureRmAccount
        }
        catch
        {
            write-host "exception authenticating. exiting $($error)" -ForegroundColor Yellow
            exit 1
        }
    }
}

# ----------------------------------------------------------------------------------------------------------------
function check-deployment($deployment)
{
    write-host "checking for existing deployment $($deployment)"
    
    if ((Get-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroup -Name $deployment -ErrorAction SilentlyContinue))
    {
        if ((read-host "resource group deployment exists! Do you want to delete?[y|n]") -ilike 'y')
        {
            write-host "Remove-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroup -Name $deployment -Confirm"

            if (!$whatIf)
            {
                Remove-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroup -Name $deployment -Confirm
            }
        }
    }
    
}

# ----------------------------------------------------------------------------------------------------------------
function check-forExistingAdDeployment()
{
    if (!($installOptions -imatch "ad-domain-only-test"))
    {
        if ((read-host "this deployment requires an 'existing AD'. do you want to deploy 'ad-domain-only-test' first?[y|n]") -imatch "y")
        {
            start-ad-domain-only-test
        }
    }
}
# ----------------------------------------------------------------------------------------------------------------
function check-parameterFile($parameterFile, $deployment, $updateUrl = "")
{
    write-host "checking parameter file $($parameterFile) for $($deployment)" -foregroundcolor Green
    $ret = $false
    
    if ([IO.File]::Exists($parameterFile))
    {
        if (!$useExistingJson)
        {
            write-host "removing previous parameter file $($parameterFile)"
            write-host (get-content -Raw -Path $parameterFile) | out-string
            [IO.File]::Delete($parameterFile)
        }
        else 
        {
            $ret = $true    
        }
    }
    
    if (!$ret)
    {
        # check repo
        if(!$updateUrl)
        {
            $updateUrl = "$($templateBaseRepoUri)/$($deployment)/$($templateFileName)"
        }

        write-host "downloading template from repo $($updateUrl)"

        if (get-urlJsonFile -updateUrl $updateUrl -destinationFile $parameterFile)
        {
            $ret = $true
        }
    }

    if ($ret)
    {
        write-host "parameter file:"
        write-host (get-content -Raw -Path $parameterFile) | out-string
        return $true
    }
    else
    {
        write-error "missing parameter file $($parameterFile)"
        write-host "exiting"
        exit 1
    }

    return $ret
}

# ----------------------------------------------------------------------------------------------------------------
function check-parameters()
{
    try 
    {
        
    
    
        write-host "checking number of instances"
        if ($numberofRdshInstances -lt 1 -or $numberofRdshInstances -gt $maxRdshTestInstances)
        {
            write-host "numberOfRdshInstances should be greater than 1 and less than 100. exiting"
            exit 1
        }

        if (!$deploymentName)
        {
            $deploymentName = $resourceGroup
        }

        write-host "checking resource group"

        if (!$resourceGroup)
        {
            write-warning "resourcegroup is a mandatory argument. supply -resourceGroup argument and restart script."
            exit 1
        }

        if ($resourceGroup -ne $resourceGroup.ToLower())
        {
            write-warning "resourcegroup currently needs to be lower case due to issue 43. exiting script."
            exit 1
        }

        if ($resourceGroup.Contains("-"))
        {
            write-warning "resourcegroup currently needs not have '-' due to issue 43. exiting script."
            exit 1
        }

        write-host "checking ad domain name"

        if (!$domainName)
        {
            $domainName = "$($resourceGroup.ToLower()).lab"
            write-host "domain name '$($domainName)' should populated. example: contoso.com"
            write-host "exiting"
            exit 1
        }

        if (!$domainName.Contains("."))
        {
            write-host "domain name '$($domainName)' should be fqdn. example: contoso.com"
            write-host "exiting"
            exit 1
        }

        if ($domainName.IndexOf(".") -gt 15)
        {
            write-host "error: base domain name greater than 15 characters $($domainName). use -domainName with a new shortend name and restart script." -ForegroundColor Yellow
            write-host "exiting"
            exit 1
        }

        write-host "checking dns label"

        if (!$dnsLabelPrefix)
        {
            write-host "dns label prefix '$($dnsLabelPrefix)' should be populated. example: 'rdsgateway' or '$($resourceGroup)'"
            write-host "exiting"
            exit 1
        }

        if ($dnsLabelPrefix -ne $dnsLabelPrefix.ToLower())
        {
            write-host "dns label prefix '$($dnsLabelPrefix)' should be lower case. example: 'rdsgateway' or '$($resourceGroup.ToLower())'"
            write-host "exiting"
            exit 1
        }

        if ($dnsLabelPrefix.Contains("."))
        {
            write-host "dns label prefix '$($dnsLabelPrefix)' should not contain '.'"
            write-host "exiting"
            exit 1
        }

        $cloudAppDns = "$($dnsLabelPrefix).$($location).cloudapp.azure.com"
        if (Resolve-DnsName -Name $cloudAppDns -ErrorAction SilentlyContinue)
        {
            Write-Warning "dns name already exists! '$($cloudAppDns)'. if not recreating deployment, you may need to select new unique name."
        }

        write-host "checking location"

        if (!(Get-AzureRmLocation | Where-Object Location -Like $location) -or !$location)
        {
            (Get-AzureRmLocation).Location
            write-warning "location: $($location) not found. supply -location using one of the above locations and restart script."
            exit 1
        }

        write-host "checking vm size"

        if (!(Get-AzureRmVMSize -Location $location | Where-Object Name -Like $rdshVmSize))
        {
            Get-AzureRmVMSize -Location $location
            write-warning "rdshVmSize: $($rdshVmSize) not found in $($location). correct -rdshVmSize using one of the above options and restart script."
            exit 1
        }

        write-host "checking sku"

        if (!(Get-AzureRmVMImageSku -Location $location -PublisherName MicrosoftWindowsServer -Offer WindowsServer | Where-Object Skus -Like $imageSKU))
        {
            Get-AzureRmVMImageSku -Location $location -PublisherName MicrosoftWindowsServer -Offer WindowsServer 
            write-warning "image sku: $($imageSku) not found in $($location). correct -imageSKU using one of the above options and restart script."
            exit 1
        }

        write-host "checking password"

        if (!$credentials)
        {
            if (!$adminPassword)
            {
                $global:credential = Get-Credential
            }
            else
            {
                $SecurePassword = $adminPassword | ConvertTo-SecureString -AsPlainText -Force  
                $global:credential = new-object Management.Automation.PSCredential -ArgumentList $adminUsername, $SecurePassword
            }
        }
        else
        {
            $global:credential = $credentials
        }

        $adminUsername = $global:credential.UserName
        $adminPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($global:credential.Password)) 

        $count = 0
        # uppercase check
        if ($adminPassword -match "[A-Z]") { $count++ }
        # lowercase check
        if ($adminPassword -match "[a-z]") { $count++ }
        # numeric check
        if ($adminPassword -match "\d") { $count++ }
        # specialKey check
        if ($adminPassword -match "\W") { $count++ } 

        if ($adminPassword.Length -lt 8 -or $adminPassword.Length -gt 123 -or $count -lt 3)
        {
            Write-warning @"
            azure password requirements at time of writing (3/2017):
            The supplied password must be between 8-123 characters long and must satisfy at least 3 of password complexity requirements from the following: 
                1) Contains an uppercase character
                2) Contains a lowercase character
                3) Contains a numeric digit
                4) Contains a special character.
            
            correct password and restart script. 
"@
            exit 1
        }

        if ($monitor)
        {
            run-monitor
        }
    }
    catch
    {
        Write-Warning "exception checking parameters. continuing WITHOUT parameter validation!"
        write-error "$($error | out-string)"
        $error.clear()
    }
}

# ----------------------------------------------------------------------------------------------------------------
function check-resourceGroup()
{
    write-host "checking for existing resource group $($resourceGroup)"
    
    if ((Get-AzureRmResourceGroup -Name $resourceGroup -ErrorAction SilentlyContinue))
    {
        write-host "resource group exists! this is normally ok unless intent is to delete resource group which WILL DELETE all items in resource group. " -ForegroundColor Yellow
        if ((read-host "Do you want to delete resource group?[y|n]") -ilike 'y')
        {
            write-host "Remove-AzureRmResourceGroup -Name $resourceGroup"
            if (!$whatIf)
            {
                Remove-AzureRmResourceGroup -Name $resourceGroup
            }
        }
    }
    
    # create resource group if it does not exist
    if (!(Get-AzureRmResourceGroup -Name $resourceGroup -ErrorAction SilentlyContinue))
    {
        Write-Host "creating resource group $($resourceGroup) in location $($location)"   
        write-host "New-AzureRmResourceGroup -Name $resourceGroup -Location $location"

        if (!$whatIf)
        {
            New-AzureRmResourceGroup -Name $resourceGroup -Location $location
        }
    }
    
}

# ----------------------------------------------------------------------------------------------------------------
function create-cert
{
    write-host "$(get-date) create-cert..." -foregroundcolor cyan
    
    if (!$pfxFilePath)
    {
        write-warning "this is a standalone cert that should only be used for test and NOT production"
        write-host "Get-ChildItem -Path cert:\LocalMachine\My -Recurse | where-object Subject -Match $domainName | Remove-Item -Force"
        write-host ".\ps-certreq.ps1  -subject `"*.$($domainName)`" -outputDir $($env:TEMP)"
        $pfxFilePath = "$($env:TEMP)\$($domainName).pfx"
        write-host "Get-ChildItem -Path cert:\LocalMachine\My -Recurse | where-object Subject -Match $domainName | Export-PfxCertificate -Password $mypwd -FilePath $pfxFilePath -Force"
        write-host "Get-ChildItem -Path cert:\LocalMachine\My -Recurse | where-object Subject -Match $domainName | Remove-Item -Force"

        $ret = $null

        if (!$whatIf)
        {
            Get-ChildItem -Path cert:\LocalMachine\My -Recurse | where-object Subject -Match $domainName | Remove-Item -Force
            $ret = .\ps-certreq.ps1  -subject "*.$($domainName)" -outputDir $env:TEMP
            write-host $ret
            $mypwd = ConvertTo-SecureString -String $adminPassword -Force -AsPlainText
            Get-ChildItem -Path cert:\LocalMachine\My -Recurse | where-object Subject -Match $domainName | Export-PfxCertificate -Password $mypwd -FilePath $pfxFilePath -Force
            # use post import to trusted root
            Get-ChildItem -Path cert:\LocalMachine\My -Recurse | where-object Subject -Match $domainName | Remove-Item -Force
        }
    }

    if (!$applicationId)
    {
        write-host "$(get-date) create-vault..." -foregroundcolor cyan
        write-host ".\azure-rm-aad-add-key-vault.ps1 -pfxFilePath $pfxFilePath `
                        -certPassword $applicationPassword `
                        -certNameInVault $certificateName `
                        -vaultName $vaultName `
                        -uri 'https://$($resourceGroup)/$($domainName)' `
                        -resourceGroup $resourceGroup `
                        -adApplicationName 'rdscert$($resourceGroup)'"
        if (!$whatIf)
        {
            $ret = .\azure-rm-aad-add-key-vault.ps1 -pfxFilePath $pfxFilePath `
                -certPassword $applicationPassword `
                -certNameInVault $certificateName `
                -vaultName $vaultName `
                -uri "https://$($resourceGroup)/$($domainName)" `
                -resourceGroup $resourceGroup `
                -adApplicationName "rdscert$($resourceGroup)"
            return $ret
        }
    }
    else
    {
        return "application id: $($applicationId) "
    }
}

# ----------------------------------------------------------------------------------------------------------------
function create-sql
{
    write-host "$(get-date) sql..." -foregroundcolor cyan
    write-host ".\azure-rm-sql-create.ps1 -resourceGroupName $resourceGroup `
                    -location $location `
                    -databaseName RdsCb `
                    -adminPassword $adminPassword `
                    -generateUniqueName `
                    -nolog "
    #-nsgStartIpAllow '10.0.0.4' `
    #-nsgEndIpAllow '10.0.0.254' "

    if (!$whatIf)
    {
        $ret = .\azure-rm-sql-create.ps1 -resourceGroupName $resourceGroup `
            -location $location `
            -databaseName RdsCb `
            -adminPassword $adminPassword `
            -servername "sql-server$($random)" `
            -nolog #`
        #-nsgStartIpAllow "10.0.0.4" `
        #-nsgEndIpAllow "10.0.0.254"

        $match = [regex]::Match($ret, "connection string ODBC Native client:`r`n(DRIVER.+;)", [Text.RegularExpressions.RegexOptions]::Singleline -bor [Text.RegularExpressions.RegexOptions]::IgnoreCase)
        $odbcstring = ($match.Captures[0].Groups[1].Value).Replace("`r`n", "")
        return $odbcstring
    }
}

# ----------------------------------------------------------------------------------------------------------------
function deploy-template($templateFile, $parameterFile, $deployment)
{
    write-host "validating template"
    write-host "Test-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroup `
                    -TemplateFile $templateFile `
                    -Mode Complete `
                    -TemplateParameterFile $parameterFile "
    $ret = $null
    $ret = Test-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroup `
        -TemplateFile $templateFile `
        -Mode Complete `
        -TemplateParameterFile $parameterFile 

    if ($ret)
    {
        Write-Error "template validation failed. error: `n`n$($ret.Code)`n`n$($ret.Message)`n`n$($ret.Details)"
        Write-Error "error: $($error | out-string)"
        write-host "exiting"
        exit 1
    }

    $error.Clear() 
    
    write-host "$([DateTime]::Now) starting deployment '$($deployment)'. this will take a while..." -ForegroundColor Green
    write-host "New-AzureRmResourceGroupDeployment -Name $deployment `
                    -ResourceGroupName $resourceGroup `
                    -DeploymentDebugLogLevel All `
                    -TemplateFile $templateFile `
                    -TemplateParameterFile $parameterFile "

    $error.Clear() 

    if (!$whatIf)
    {
        if($VerbosePreference -ne "SilentlyContinue")
        {
            $ret = New-AzureRmResourceGroupDeployment -Name $deployment `
                -ResourceGroupName $resourceGroup `
                -DeploymentDebugLogLevel All `
                -TemplateFile $templateFile `
                -TemplateParameterFile $parameterFile `
                -Verbose
        }
        else 
        {
            $ret = New-AzureRmResourceGroupDeployment -Name $deployment `
                -ResourceGroupName $resourceGroup `
                -DeploymentDebugLogLevel All `
                -TemplateFile $templateFile `
                -TemplateParameterFile $parameterFile            
        }
    }
    else
    {
        $ret = New-AzureRmResourceGroupDeployment -Name $deployment `
            -ResourceGroupName $resourceGroup `
            -DeploymentDebugLogLevel All `
            -TemplateFile $templateFile `
            -TemplateParameterFile $parameterFile `
            -WhatIf
    }

    if ($error)
    {
        Write-Error "template deployment failed. error: `n`n$($ret.Code)`n`n$($ret.Message)`n`n$($ret.Details)"
        Write-Error "error: $($error | out-string)"
        write-host "exiting"
        exit 1
    }

    write-host "$([DateTime]::Now) finished deployment" -ForegroundColor Magenta
}

# ----------------------------------------------------------------------------------------------------------------
function get-urlJsonFile($updateUrl, $destinationFile)
{
    write-host "get-urlJsonFile:checking for remote file: $($updateUrl)"
    $jsonFile = $null
    
    try 
    {
        if ([IO.File]::Exists($destinationFile))
        {
            [IO.File]::Delete($destinationFile)
        }

        $jsonFile = (Invoke-WebRequest -Method Get -Uri $updateUrl).Content

        # git may not have carriage return
        # reset by setting all to just lf
        $jsonFile = [regex]::Replace($jsonFile, "`r`n", "`n")
        # add cr back
        $jsonFile = [regex]::Replace($jsonFile, "`n", "`r`n")
        
        # convertfrom-json does not like BOM. so remove            
        [IO.File]::WriteAllLines($destinationFile, $jsonFile, (new-object Text.UTF8Encoding $false))
    
        return $true
    }
    catch [System.Exception] 
    {
        write-host "get-urlJsonFile:exception: $($error | out-string)"
        $error.Clear()
        return $false    
    }
}

# ----------------------------------------------------------------------------------------------------------------
function get-urlScriptFile($updateUrl, $destinationFile)
{
    write-host "get-urlScriptFile:checking for updated script: $($updateUrl)"
    $file = ""
    $scriptFile = $null

    try 
    {
        $scriptFile = Invoke-RestMethod -Method Get -Uri $updateUrl 

        # gallery has bom 
        $scriptFile = $scriptFile.Replace("???", "")

        # git may not have carriage return
        # reset by setting all to just lf
        $scriptFile = [regex]::Replace($scriptFile, "`r`n", "`n")
        # add cr back
        $scriptFile = [regex]::Replace($scriptFile, "`n", "`r`n")

        if ([IO.File]::Exists($destinationFile))
        {
            $file = [IO.File]::ReadAllText($destinationFile)
        }

        if (([string]::Compare($scriptFile, $file) -ne 0))
        {
            write-host "copying script $($destinationFile)"
            [IO.File]::WriteAllText($destinationFile, $scriptFile)
            return $true
        }
        else
        {
            write-host "script is up to date"
        }
        
        return $false
    }
    catch [System.Exception] 
    {
        write-host "get-urlScriptFile:exception: $($error | out-string)" -ForegroundColor Red
        $error.Clear()
        return $false    
    }
}

# ----------------------------------------------------------------------------------------------------------------
function run-monitor()
{
    write-host "$([DateTime]::Now) starting monitor"
    $monitorScript = "$($env:TEMP)\azure-rm-log-reader.ps1"
    
    if (![IO.File]::Exists($monitorScript))
    {
        get-urlScriptFile -updateUrl "https://aka.ms/azure-rm-log-reader.ps1" -destinationFile $monitorScript
    }

    write-host "Start-Process -FilePath `"powershell.exe`" -ArgumentList `"-WindowStyle Minimized -ExecutionPolicy Bypass $($monitorScript)`""

    if (!$whatIf)
    {
        Start-Process -FilePath "powershell.exe" -ArgumentList "-WindowStyle Minimized -ExecutionPolicy Bypass $($monitorScript)"
    }
}

# ----------------------------------------------------------------------------------------------------------------
function run-postConnect()
{
    write-host "$([DateTime]::Now) starting post connect"
    $connectScript = "$($env:TEMP)\azure-rm-rdp-post-deployment.ps1"
    get-urlScriptFile -updateUrl "https://aka.ms/azure-rm-rdp-post-deployment.ps1" -destinationFile $connectScript
    
    write-host "connecting to $($rdWebSite)"
    
    if (!$whatIf)
    {
        Invoke-Expression -Command "$($connectScript) -rdWebUrl `"$($rdWebSite)`""
    }
}

# ----------------------------------------------------------------------------------------------------------------
function runas-admin()
{
    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
    {   
        Write-Warning "please restart script in administrator powershell session. exiting..."
        return $false
    }

    return $true
}

# ----------------------------------------------------------------------------------------------------------------
function start-ad-domain-only-test()
{
    $deployment = "ad-domain-only-test"
    write-warning "$($deployment) should only be used for testing and NOT production"
    write-host "$(get-date) starting '$($deployment)' configuration..." -foregroundcolor cyan
    $templateFile = "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/bb24e0c10dd73b818dc492133522ceaf72887cd5/active-directory-new-domain/azuredeploy.json"
    $deployFile = "$($env:TEMP)\azuredeploy.json"
    check-parameterFile -parameterFile $deployFile -deployment $deployment -updateUrl $templateFile
    check-deployment -deployment $deployment

    $ajson = get-content -raw -Path $deployFile
    $ajson = $ajson.Replace("`"adVMName`": `"adVM`"", "`"adVMName`": `"$($dnsServer)`"")
    # convertfrom-json does not like BOM. so remove            
    [IO.File]::WriteAllLines($deployFile, $ajson, (new-object Text.UTF8Encoding $false))
    $templateFile = $deployFile

    if (!$useExistingJson)
    {
        $ujson = @{'$schema' = "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#";
            "contentVersion" = "1.0.0.0";
            "parameters"     = @{
                "adminPassword"      = @{ "value" = $adminPassword };
                "adminUsername"      = @{ "value" = $adminUsername };
                "adSubnetName"       = @{ "value" = $subnetName };
                "adVMSize"           = @{ "value" = "Standard_D2_v2"};
                "dnsPrefix"          = @{ "value" = "addc-$($dnsLabelPrefix)" };
                "domainName"         = @{ "value" = $domainName };
                "virtualNetworkName" = @{ "value" = $vnetName };
            }
        }
        $ujson | ConvertTo-Json | Out-File $parameterFileAdDeployment
    }

    $ujson.parameters
    deploy-template -templateFile $templateFile `
        -parameterFile $parameterFileAdDeployment `
        -deployment $installOption
}

# ----------------------------------------------------------------------------------------------------------------
function start-rds-deployment()
{
    $deployment = "rds-deployment"
    write-host "$(get-date) starting '$($deployment)' configuration..." -foregroundcolor cyan
    
    check-parameterFile -parameterFile $parameterFileRdsDeployment -deployment $deployment
    check-deployment -deployment $deployment
    $templateFile = "$($templateBaseRepoUri)/$($deployment)/azuredeploy.json"
    $ujson = ConvertFrom-Json (get-content -Raw -Path $parameterFileRdsDeployment)

    if (!$useExistingJson)
    {
        $ujson.parameters._artifactsLocation.value = "$($templateBaseRepoUri)$($deployment)"
        $ujson.parameters.adminPassword.value = $adminPassword
        $ujson.parameters.adminUserName.value = $adminUserName
        $ujson.parameters.dnsLabelPrefix.value = $dnsLabelPrefix
        $ujson.parameters.domainName.value = $domainName
        $ujson.parameters.imageSku.value = $imageSku
        $ujson.parameters.numberOfRdshInstances.value = $numberOfRdshInstances
        $ujson.parameters.rdshVmSize.value = $rdshVmSize
        $ujson | ConvertTo-Json | Out-File $parameterFileRdsDeployment
    }

    $ujson.parameters

    deploy-template -templateFile $templateFile `
        -parameterFile $parameterFileRdsDeployment `
        -deployment $installOption
}

# ----------------------------------------------------------------------------------------------------------------
function start-rds-deployment-existing-ad()
{
    $deployment = "rds-deployment-existing-ad"
    write-host "$(get-date) starting '$($deployment)' configuration..." -foregroundcolor cyan
    check-parameterFile -parameterFile $parameterFileRdsDeploymentExistingAd -deployment $deployment
    check-deployment -deployment $deployment
    check-forExistingAdDeployment

    $ujson = ConvertFrom-Json (get-content -Raw -Path $parameterFileRdsDeploymentExistingAd)

    if (!$useExistingJson)
    {
        $ujson.parameters._artifactsLocation.value = "$($templateBaseRepoUri)$($deployment)"
        $ujson.parameters.dnsLabelPrefix.value = $dnsLabelPrefix
        $ujson.parameters.existingAdminPassword.value = $adminPassword
        $ujson.parameters.existingAdminUserName.value = $adminUserName
        $ujson.parameters.existingDomainName.value = $domainName
        $ujson.parameters.existingSubnetName.value = $subnetName
        $ujson.parameters.existingVnetName.value = $vnetName
        $ujson.parameters.imageSku.value = $imageSku
        $ujson.parameters.numberOfRdshInstances.value = $numberOfRdshInstances
        $ujson.parameters.rdshVmSize.value = $rdshVmSize
        $ujson | ConvertTo-Json | Out-File $parameterFileRdsDeploymentExistingAd
    }

    $ujson.parameters
    
    deploy-template -templateFile "$($templateBaseRepoUri)/$($deployment)/azuredeploy.json" `
        -parameterFile $parameterFileRdsDeploymentExistingAd `
        -deployment $installOption
}

# ----------------------------------------------------------------------------------------------------------------
function start-rds-deployment-ha-broker()
{
    $deployment = "rds-deployment-ha-broker"
    write-host "$(get-date) starting '$($deployment)' configuration..." -foregroundcolor cyan

    check-parameterFile -parameterFile $parameterFileRdsHaBroker -deployment $deployment
    check-deployment -deployment $deployment
    $odbcstring = create-sql

    $ujson = ConvertFrom-Json (get-content -Raw -Path $parameterFileRdsHaBroker)
    if (!$useExistingJson)
    {
        $ujson.parameters._artifactsLocation.value = "$($templateBaseRepoUri)$($deployment)"
        $ujson.parameters.clientAccessName.value = $clientAccessName
        $ujson.parameters.existingDomainName.value = $domainName
        $ujson.parameters.existingAdminUserName.value = $adminUserName
        $ujson.parameters.existingAdminPassword.value = $adminPassword
        $ujson.parameters.primaryDbConnectionString.value = $odbcstring
        $ujson | ConvertTo-Json | Out-File $parameterFileRdsHaBroker
    }
    
    $ujson.parameters
    
    deploy-template -templateFile "$($templateBaseRepoUri)/$($deployment)/azuredeploy.json" `
        -parameterFile $parameterFileRdsHaBroker `
        -deployment $installOption
}

# ----------------------------------------------------------------------------------------------------------------
function start-rds-deployment-ha-gateway()
{
    $deployment = "rds-deployment-ha-gateway"
    write-host "$(get-date) starting '$($deployment)' configuration..." -foregroundcolor cyan

    check-parameterFile -parameterFile $parameterFileRdsHaGateway -deployment $deployment
    check-deployment -deployment $deployment

    $ujson = ConvertFrom-Json (get-content -Raw -Path $parameterFileRdsHaGateway)
    if (!$useExistingJson)
    {
        $ujson.parameters._artifactsLocation.value = "$($templateBaseRepoUri)$($deployment)"
        $ujson.parameters.brokerServer.value = "$($brokerName).$($domainName)"
        $ujson.parameters.existingDomainName.value = $domainName
        $ujson.parameters.existingAdminUserName.value = $adminUserName
        $ujson.parameters.existingAdminPassword.value = $adminPassword
        $ujson.parameters.gatewayLoadbalancer.value = $gatewayLoadBalancer
        $ujson.parameters.gatewayPublicIp.value = $gatewayPublicIp
        $ujson.parameters.externalFqdn.value = "$($resourceGroup).$($domainName)"
        $ujson.parameters.dnsLabelPrefix.value = $resourceGroup
        $ujson.parameters.'gw-availabilitySet'.value = $gwAvailabilitySet
        $ujson.parameters.storageAccountName.value = "storage$($random)" # <---- TODO query for real account???
        $ujson | ConvertTo-Json | Out-File $parameterFileRdsHaGateway
    }
    $ujson.parameters
    
    deploy-template -templateFile "$($templateBaseRepoUri)/$($deployment)/azuredeploy.json" `
        -parameterFile $parameterFileRdsHaGateway `
        -deployment $installOption
}

# ----------------------------------------------------------------------------------------------------------------
function start-rds-deployment-uber()
{
    $deployment = "rds-deployment-uber"
    write-host "$(get-date) starting '$($deployment)' configuration..." -foregroundcolor cyan
    check-parameterFile -parameterFile $parameterFileRdsUber -deployment $deployment
    check-deployment -deployment $deployment
    check-forExistingAdDeployment
    
    $primaryDbConnectionString = create-sql
    $ret = create-cert
    
    $match = [regex]::Match($ret, "application id: (.+?) ")
    $applicationId = ($match.Captures[0].Groups[1].Value)
    
    $ujson = ConvertFrom-Json (get-content -Raw -Path $parameterFileRdsUber)
    if (!$useExistingJson)
    {
        $ujson.parameters._artifactsLocation.value = $templateBaseRepoUri
        $ujson.parameters.applicationId.value = $applicationId
        $ujson.parameters.applicationPassword.value = $applicationPassword
        $ujson.parameters.certificateName.value = $certificateName
        $ujson.parameters.clientAccessName.value = $clientAccessName
        $ujson.parameters.dnsLabelPrefix.value = $dnsLabelPrefix
        $ujson.parameters.dnsServer.value = $dnsServer
        $ujson.parameters.existingAdminPassword.value = $adminPassword
        $ujson.parameters.existingAdminUserName.value = $adminUserName
        $ujson.parameters.existingDomainName.value = $domainName
        $ujson.parameters.existingSubnetName.value = $subnetName
        $ujson.parameters.existingVnetName.value = $vnetName
        $ujson.parameters.imageSku.value = $imageSku
        $ujson.parameters.numberOfRdshInstances.value = $numberOfRdshInstances
        $ujson.parameters.numberOfWebGwInstances.value = $numberOfWebGwInstances
        $ujson.parameters.primaryDbConnectionString.value = $primaryDbConnectionString
        $ujson.parameters.rdshVmSize.value = $rdshVmSize
        $ujson.parameters.sqlServer.value = $sqlServer
        $ujson.parameters.tenantid.value = $tenantId
        $ujson.parameters.vaultName.value = $vaultName
        
        $ujson | ConvertTo-Json | Out-File $parameterFileRdsUber
    }
    $ujson.parameters
    
    deploy-template -templateFile "$($templateBaseRepoUri)/$($deployment)/azuredeploy.json" `
        -ParameterFile $parameterFileRdsUber `
        -deployment $installOption

}

# ----------------------------------------------------------------------------------------------------------------
function start-rds-update-certificate()
{
    $deployment = "rds-update-certificate"
    write-host "$(get-date) starting '$($deployment)' configuration..." -foregroundcolor cyan

    check-parameterFile -parameterFile $parameterFileRdsUpdateCertificate -deployment $deployment
    check-deployment -deployment $deployment
    $ret = create-cert
    
    $match = [regex]::Match($ret, "application id: (.+?) ")
    $applicationId = ($match.Captures[0].Groups[1].Value)
   
    $ujson = ConvertFrom-Json (get-content -Raw -Path $parameterFileRdsUpdateCertificate)
    if (!$useExistingJson)
    {
        $ujson.parameters._artifactsLocation.value = "$($templateBaseRepoUri)$($deployment)"
        $ujson.parameters.applicationId.value = $applicationId
        $ujson.parameters.applicationPassword.value = $applicationPassword
        $ujson.parameters.existingAdminPassword.value = $adminPassword
        $ujson.parameters.existingAdminUserName.value = $adminUserName
        $ujson.parameters.existingDomainName.value = $domainName
        $ujson.parameters.certificateName.value = $certificateName
        $ujson.parameters.tenantId.value = $tenantId
        $ujson.parameters.vaultName.value = $vaultName
        $ujson | ConvertTo-Json | Out-File $parameterFileRdsUpdateCertificate
    }

    $ujson.parameters
    
    deploy-template -templateFile "$($templateBaseRepoUri)/$($deployment)/azuredeploy.json" `
        -parameterFile $parameterFileRdsUpdateCertificate `
        -deployment $installOption

}

# ----------------------------------------------------------------------------------------------------------------
function start-rds-update-rdsh-collection()
{
    $deployment = "rds-update-rdsh-collection"
    write-host "$(get-date) starting '$($deployment)' configuration..." -foregroundcolor cyan

    check-parameterFile -parameterFile $parameterFileRdsUpdateRdshCollection -deployment $deployment
    check-deployment -deployment $deployment
    #check-forExistingAdDeployment
    
    $ujson = ConvertFrom-Json (get-content -Raw -Path $parameterFileRdsUpdateRdshCollection)
    
    if (!$useExistingJson)
    {
        if ((read-host "Do you want to create a new template vm from gallery into $($resourceGroup)?[y|n]") -imatch 'y')
        {
            write-host "adding template vm. this will take a while..." -ForegroundColor Green
            write-host ".\azure-rm-vm-create.ps1 -publicIp `
                            -resourceGroupName $resourceGroup `
                            -location $location `
                            -adminUsername $adminUsername `
                            -adminPassword $adminpassword `
                            -vmBaseName $templateVmNamePrefix `
                            -vmStartCount 1 `
                            -vmCount 1 "
                            
            if (!$whatIf)
            {
                .\azure-rm-vm-create.ps1 -publicIp `
                    -resourceGroupName $resourceGroup `
                    -location $location `
                    -adminUsername $adminUsername `
                    -adminPassword $adminpassword `
                    -vmBaseName $templateVmNamePrefix `
                    -vmStartCount 1 `
                    -vmCount 1
            }

            write-host "getting vhd location"
            $vm = Get-AzureRmVM -ResourceGroupName $resourceGroup -Name "$($templateVmNamePrefix)-01"
            $vm
            $vhdUri = $vm.StorageProfile.OsDisk.Vhd.Uri
        
            $tpIp = (Get-AzureRmPublicIpAddress -Name ([IO.Path]::GetFileName($vm.NetworkProfile.NetworkInterfaces[0].Id)) -ResourceGroupName $resourceGroup).IpAddress
        
            if ([string]::IsNullOrEmpty($vhdUri) -or [string]::IsNullOrEmpty($tpIp))
            {
                write-host "unable to find template public ip. exiting"
                exit 1
            }
        
            write-host "use mstsc connection to run sysprep on template c:\windows\system32\sysprep\sysprep.exe -oobe -generalize" -foregroundcolor Green
            mstsc /v $tpIp /admin
        
            write-host "waiting for machine to shutdown"
        
            while ($true)
            {
                $vm = Get-AzureRmVM -ResourceGroupName $resourceGroup -Name "$($templateVmNamePrefix)-01" -Status

                if ($vm.Statuses.Code.Contains("PowerState/stopped"))
                {
                    write-host "deallocating vm"
                    stop-azurermvm -name $vm.Name -Force -ResourceGroupName $resourceGroup
                
                    write-host "setting vm to OSState/generalized"
                    set-azurermvm -ResourceGroupName $resourceGroup -Name $vm.Name -Generalized 
                    break    
                }
                elseif ($vm.Statuses.Code.Contains("PowerState/deallocated")) 
                {
                    break
                }
        
                start-sleep -Seconds 1
            }
        }
        else
        {
            $vhdUri = $rdshTemplateImageUri

            if (!$vhdUri)
            {
                $vm = Get-AzureRmVM -ResourceGroupName $resourceGroup -Name "$($templateVmNamePrefix)-01"
                $vhdUri = $vm.StorageProfile.OsDisk.Vhd.Uri
            }
        
            if ($vhdUri)
            {
                write-host $vhdUri -foregroundcolor Magenta

                if ((read-host "Is this the correct path to vhd of template image to be used?[y|n]") -imatch 'n')
                {
                    $ujson.parameters.rdshTemplateImageUri.value = read-host "Enter new vhd path:"

                }
            }
        
        }
        
        if ($vhdUri)
        {
            write-host "modifying json of $($quickstartTemplate) template with this path for rdshTemplateImageUri: $($vhdUri)"
            $ujson.parameters.rdshTemplateImageUri.value = $vhdUri
        }
        else
        {
            write-host "error:invalid vhd path. exiting"
            return
        }
        
        write-host "checking list of vm's in $($resourceGroup) for possible duplicate"
        $vms = Get-AzureRmVM -ResourceGroupName $resourceGroup 
        
        if ($vms)
        {
            # format is rdsh-$($rdshUpdateIteration)01
            $count = [int]$rdshUpdateIteration

            while ($true)
            {
                if ($vms.Name -ieq "rdsh-$($count)01")
                {
                    $count = $count + 1
                    continue
                }
                
                write-host "updating rdshUpdateIteration to $($count) due to name conflict." -ForegroundColor Yellow
                $rdshUpdateIteration = $count.ToString()            
                break
            }
        }

        $ujson.parameters._artifactsLocation.value = "$($templateBaseRepoUri)$($deployment)"
        $ujson.parameters._artifactsLocationSasToken.value = ""
        $ujson.parameters.availabilitySet.value = $rdshAvailabilitySet
        $ujson.parameters.existingDomainName.value = $domainName
        $ujson.parameters.existingAdminusername.value = $adminUsername
        $ujson.parameters.existingAdminPassword.value = $adminPassword
        $ujson.parameters.existingRdshCollectionName.value = $rdshCollectionName
        $ujson.parameters.existingSubnetName.value = $subnetName
        $ujson.parameters.existingVnetName.value = $vnetName
        $ujson.parameters.numberOfRdshInstances.value = $numberOfRdshInstances
        $ujson.parameters.rdshUpdateIteration.value = $rdshUpdateIteration
        $ujson.parameters.rdshVmSize.value = $rdshVmSize
        $ujson.parameters.UserLogoffTimeoutInMinutes.value = $logoffTimeInminutes
        
        $ujson | ConvertTo-Json | Out-File $parameterFileRdsUpdateRdshCollection

        $ujson.parameters
        
        deploy-template -templateFile "$($templateBaseRepoUri)/$($deployment)/azuredeploy.json" `
            -ParameterFile $parameterFileRdsUpdateRdshCollection `
            -deployment $installOption
    }
}

# ----------------------------------------------------------------------------------------------------------------
main