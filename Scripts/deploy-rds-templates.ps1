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
   file name  : deploy-rds-templates.ps1
   version    : 170817 update parameter names for change 4216303

.EXAMPLE
    .\deploy-rds-templates.ps1 -adminPassword changeme3240e2938r92 -resourceGroup rdsdeptest -location eastus
    Example command to deploy rds-deployment, rds-update-certificate, rds-ha-broker, and rds-ha-gateway with 2 rdsh, rdcb, and rdgw instances using A2 machines. 
    the resource group is rdsdeptest and domain fqdn is rdsdeptest.lab

.EXAMPLE
    .\deploy-rds-templates.ps1 -adminPassword changeme3240e2938r92 -resourceGroup rdsdeptest -admin cloudadmin -instances 5 -rdshVmSize Standard_A4 -imagesku 2012-r2-Datacenter -installOptions rds-deployment
    Example command to deploy rds-deployment with 5 instances using A4 machines. the resource group is rdsdeptest and domain fqdn is rdsdeptest.lab. 
    the admin account is cloudadmin and OS is 2012-r2-datacenter

.EXAMPLE
    .\deploy-rds-templates.ps1 -useJson -parameterFileRdsDeployment c:\temp\rds-deployment.azuredeploy.parameters.json
    Example command to deploy rds-deployment with a custom populated parameter json file c:\temp\rds-deployment.azuredeploy.parameters.json.
    all properties from json file will be used. if no password is supplied, you will be prompted.

.EXAMPLE
    .\deploy-rds-templates.ps1 -adminPassword changeme3240e2938r92 -resourceGroup rdsdeptest -monitor -postConnect
    Example command to deploy rds-deployment with 2 instances using A2 machines. the resource group is rdsdeptest and domain fqdn is rdsdeptest.lab
    before calling New-AzureRmResourceGroupDeployment, the powershell monitor script will be called.
    after successful deployment, the post connect powershell script will be called.

.PARAMETER adminUsername
    the name of the administrator account. 
    default is 'cloudadmin'

.PARAMETER adminPassword
    the administrator account password in clear text. password needs to meet azure password requirements.
    use -credentials to pass credentials securely
    default is 'Password(get-random)!'

.PARAMETER certificateName
    name of certificate to create / use
    default is "$($resourceGroup)Certificate"

.PARAMETER certificatePassword
    password to create / use for certificate access
    default is $adminPassword

.PARAMETER clean
    to clean temporary parameter json files in $env:TEMP
    this will force a new download of parameter json file from templateBaseRepoUrl

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

.PARAMETER installOptions
    array deployment templates to deploy in order specified.
    options are:
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
    default will use eastus

.PARAMETER monitor
    will run "https://aka.ms/azure-rm-log-reader.ps1" before deployment

.PARAMETER numberofRdshInstances
    number of remote desktop session host instances to create. 
    default value is 2

.PARAMETER numberofWebGwInstances
    number of additional remote desktop gateway instances to create for HA gateway mode. 
    default value is 1

.PARAMETER parameterFileRdsDeployment
    path to template json parameter file for rds-deployment
    if -useJson, existing json parameter file will be used without validation or modification
    default is .\rds-deployment.azuredeploy.parameters.json
    if not exists and not -useJson base template from .\rds-deployment\azuredeploy.parameters.json will be used

.PARAMETER parameterFileRdsHaBroker
    path to template json parameter file for rds-deployment-ha-broker
    if -useJson, existing json parameter file will be used without validation or modification
    default is .\rds-deployment-ha-broker.azuredeploy.parameters.json
    if not exists and not -useJson base template from .\rds-deployment-ha-broker\azuredeploy.parameters.json will be used

.PARAMETER parameterFileRdsHaGateway
    path to template json parameter file for rds-deployment-ha-gateway
    if -useJson, existing json parameter file will be used without validation or modification
    default is .\rds-deployment-ha-gateway.azuredeploy.parameters.json
    if not exists and not -useJson base template from .\rds-deployment-ha-gateway\azuredeploy.parameters.json will be used

.PARAMETER parameterFileRdsUber
    path to template json parameter file for rds-deployment-uber
    if -useJson, existing json parameter file will be used without validation or modification
    default is .\rds-deployment-uber.azuredeploy.parameters.json
    if not exists and not -useJson base template from .\rds-deployment-uber\azuredeploy.parameters.json will be used

.PARAMETER parameterFileRdsUpdateCertificate
    path to template json parameter file for rds-update-certificate
    if -useJson, existing json parameter file will be used without validation or modification
    default is .\rds-udpate-certificate.azuredeploy.parameters.json
    if not exists and not -useJson base template from .\rds-deployment-update-certificate\azuredeploy.parameters.json will be used

.PARAMETER parameterFileRdsUpdateRdshCollection
    path to template json parameter file for rds-update-rdsh-collection
    if -useJson, existing json parameter file will be used without validation or modification
    default is .\rds-udpate-rdsh-collection.azuredeploy.parameters.json
    if not exists and not -useJson base template from .\rds-deployment-update-rdsh-collection\azuredeploy.parameters.json will be used

.PARAMETER pause
    switch to enable pausing between deployments for verification

.PARAMETER postConnect
    will run "https://aka.ms/azure-rm-rdp-post-deployment.ps1" following deployment

.PARAMETER primaryDBConnectionString
    ODBC connection string for HA Broker and uber deployments. should be similar to following syntax
    DRIVER=SQL Server Native Client 11.0;Server={enter_sql_server_here},1433;Database={enter_sql_database_here};Uid={enter_sql_admin_here}@{enter_sql_server_here};Pwd={enter_sql_password_here};Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;

.PARAMETER publicIPAddressName
    is the public ip address name. 
    default is 'gwpip'

.PARAMETER rdshVmSize
    size is of the azure vm's to use. 
    default is 'Standard_A2'

.PARAMETER resourceGroup
    resourceGroup is a mandatory parameter and is the azure arm resourcegroup to use / create for this deployment. 
    default is 'resourceGroup(get-random)'

.PARAMETER savePassword
    will save the password in clear text into json file. default is to leave value empty

.PARAMETER subnetName
    name of subnet to create / use.
    default is 'subnet'

.PARAMETER sqlServer
    OS name of existing sql server to use if not using Azure SQL

.PARAMETER templateBaseUrl
    base template path for artifacts / scripts / dsc / templates
    default "https://raw.githubusercontent.com/Azure/RDS-Templates/master/"

.PARAMETER tenantId
    tenantId to be used in subscription for deployment

.PARAMETER useJson
    will use passed json file for arguments when deploying

.PARAMETER vaultName
    name of vault to use / create for certificate use
    default is "$(resourceGroup)Cert"

.PARAMETER vnetName
    name of vnet to create / use
    default is 'vnet'
#>
[CMDLETBINDING()]
param(
    [string]$random = (get-random), # positional requirement
    [string]$adminUserName = "cloudadmin",
    [string]$adminPassword = "Password$($random)!", 
    [string]$brokerName = "rdcb-01",
    [switch]$clean,
    [string]$resourceGroup = "resourceGroup$($random)",
    [string]$domainName = "$($resourceGroup).lab",
    [string]$certificateName = "$($resourceGroup)Certificate",
    [string]$certificatePass = $adminPassword,
    [string]$clientAccessName = "HARDCB",
    [pscredential]$credentials,
    [string]$dnsLabelPrefix = "$($resourceGroup)",
    [string]$dnsServer = "addc-01",
    [string]$gatewayLoadBalancer = "loadbalancer",
    [string]$gwAvailabilitySet = "gw-availabilityset",
    [string[]][ValidateSet("rds-deployment", "rds-update-certificate", "rds-deployment-ha-broker", "rds-deployment-ha-gateway", "rds-deployment-uber", "rds-deployment-existing-ad", "rds-update-rdsh-collection")]
    $installOptions = @("rds-deployment", "rds-update-certificate", "rds-deployment-ha-broker", "rds-deployment-ha-gateway"),
    [string][ValidateSet('2012-R2-Datacenter', '2016-Datacenter')]$imageSku = "2016-Datacenter",
    [string]$location = "eastus",
    [int]$logoffTimeInminutes = 60,
    [switch]$monitor,
    [int]$numberOfRdshInstances = 2,
    [int]$numberOfWebGwInstances = 1,
    [string]$parameterFileRdsDeployment = "$($env:TEMP)\rds-deployment.azuredeploy.parameters.json",
    [string]$parameterFileRdsUpdateCertificate = "$($env:TEMP)\rds-update-certificate.azuredeploy.parameters.json",
    [string]$parameterFileRdsHaBroker = "$($env:TEMP)\rds-deployment-ha-broker.azuredeploy.parameters.json",
    [string]$parameterFileRdsHaGateway = "$($env:TEMP)\rds-deployment-ha-gateway.azuredeploy.parameters.json",
    [string]$parameterFileRdsUber = "$($env:TEMP)\rds-deployment-uber.azuredeploy.parameters.json",
    [string]$parameterFileRdsUpdateRdshCollection = "$($env:TEMP)\rds-update-rdsh-collection.azuredeploy.parameters.json",
    [switch]$pause,
    [switch]$postConnect,
    [string]$publicIpAddressName = "gwpip",
    [string]$primaryDbConnectionString = "",
    [string]$rdshAvailabilitySet = "rdsh-availabilityset",
    [string]$rdshCollectionName = "Desktop Collection",
    [string]$rdshVmSize = "Standard_A2",
    [string]$rdshTemplateImageUri = "",
    [string]$sqlServer = "",
    [string]$subnetName = "subnet",
    [string]$templateBaseRepoUri = "https://raw.githubusercontent.com/Azure/RDS-Templates/master/",
    [string]$templateVmNamePrefix = "templateVm",
    [string]$tenantId = "",
    [switch]$useJson,
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

    write-host "using random: $($random)" -foregroundcolor yellow
    write-host "using password: $($adminPassword)" -foregroundcolor yellow
    write-host "using resource group: $($resourceGroup)" -foregroundcolor yellow
    write-host "authenticating to azure"
    authenticate-azureRm

    write-host "checking parameters"
    check-parameters   
    check-resourceGroup

    foreach ($installOption in $installOptions)
    {
        switch ($installOption.ToString().ToLower())
        {
            "rds-deployment" { start-rds-deployment }
            "rds-update-certificate" {  start-rds-update-certificate }
            "rds-deployment-ha-broker" { start-rds-deployment-ha-broker }
            "rds-deployment-ha-gateway" { start-rds-deployment-ha-gateway }
            "rds-deployment-uber" { start-rds-deployment-uber }
            "rds-deployment-existing-ad" { write-error "$($installOption) not implemented..." }
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
        write-host "$([DateTime]::Now) starting post connect"
        $connectScript = "$($env:TEMP)\azure-rm-rdp-post-deployment.ps1"
        get-urlScriptFile -updateUrl "https://aka.ms/azure-rm-rdp-post-deployment.ps1" -destinationFile $connectScript
        
        write-host "connecting to $($rdWebSite)"
        Invoke-Expression -Command "$($connectScript) -rdWebUrl `"$($rdWebSite)`""
    }

    write-host "errors: $($error | out-string)"
    write-host "-----------------------------------"

    write-host "resource group: $($resourceGroup)" -foregroundcolor yellow
    write-host "domain name: $($domnainName)" -foregroundcolor yellow
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
function check-parameterFile($parameterFile, $deployment)
{
    write-host "checking parameter file $($parameterFile) for $($deployment)" -foregroundcolor Green
    $ret = $false
    
    if ([IO.File]::Exists($parameterFile))
    {
        if($clean)
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
    
    if(!$ret)
    {
        # check repo
        write-host "downloading template from repo"
        if (get-urlJsonFile -updateUrl "$($templateBaseRepoUri)/$($deployment)/$($templateFileName)" -destinationFile $parameterFile)
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
        $newName = "$([IO.Path]::GetFileNameWithoutExtension($domainName).Substring(0, 15))$([IO.Path]::GetExtension($domainName))"
        if ((read-host "base domain name greather than 15 characters. is it ok to shorten domain name to '$($newName)'") -imatch "y")
        {
            $domainName = $newName
        }
        else
        {
            write-host "error: base domain name greater than 15 characters $($domainName). use -domainName with a new shortend name and restart script." -ForegroundColor Yellow
            write-host "exiting"
            exit 1
        }
    }

    write-host "checking dns label"

    if (!$dnsLabelPrefix)
    {
        write-host "dns label prefix '$($dnsLabelPrefix)' should be populated. example: 'rdsgateway' or '$($resourceGroup)'"
        write-host "exiting"
        exit 1
    }

    if ($dnsLabelPrefix.Contains("."))
    {
        write-host "dns label prefix '$($dnsLabelPrefix)' should not contain '.'"
        write-host "exiting"
        exit 1
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
        write-host "$([DateTime]::Now) starting monitor"
        $monitorScript = "$(get-location)\azure-rm-log-reader.ps1"
        
        if (![IO.File]::Exists($monitorScript))
        {
            get-urlJsonFile -updateUrl "https://aka.ms/azure-rm-log-reader.ps1" -destinationFile $monitorScript
        }
    
        if (!$whatIf)
        {
            Start-Process -FilePath "powershell.exe" -ArgumentList "-WindowStyle Minimized -ExecutionPolicy Bypass $($monitorScript)"
        }
    }
    
}

# ----------------------------------------------------------------------------------------------------------------
function check-resourceGroup()
{
    write-host "checking for existing resource group $($resourceGroup)"
    
    if ((Get-AzureRmResourceGroup -Name $resourceGroup -ErrorAction SilentlyContinue))
    {
        if ((read-host "resource group exists! this is normally ok unless resetting resource group which WILL DELETE all items in resource group. Do you want to delete resource group?[y|n]") -ilike 'y')
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

    if (!$whatIf)
    {
        Get-ChildItem -Path cert:\LocalMachine\My -Recurse | where-object Subject -Match $domainName | Remove-Item -Force
        .\ps-certreq.ps1  -subject "*.$($domainName)"
        $mypwd = ConvertTo-SecureString -String $adminPassword -Force -AsPlainText
        $pfxFilePath = "$($env:TEMP)\$($domainName).pfx"
        Get-ChildItem -Path cert:\LocalMachine\My -Recurse | where-object Subject -Match $domainName | Export-PfxCertificate -Password $mypwd -FilePath $pfxFilePath -Force
        # use post import to trusted root
        Get-ChildItem -Path cert:\LocalMachine\My -Recurse | where-object Subject -Match $domainName | Remove-Item -Force
    
        write-host "$(get-date) create-vault..." -foregroundcolor cyan
    }
    write-host ".\azure-rm-aad-add-key-vault.ps1 -pfxFilePath $pfxFilePath `
                    -certPassword $certificatePass `
                    -certNameInVault $certificateName `
                    -vaultName $vaultName `
                    -uri 'https://$($resourceGroup)/$($domainName)' `
                    -resourceGroup $resourceGroup `
                    -adApplicationName 'cert$($resourceGroup)$($domainName)'"
    if (!$whatIf)
    {
        $ret = .\azure-rm-aad-add-key-vault.ps1 -pfxFilePath $pfxFilePath `
            -certPassword $certificatePass `
            -certNameInVault $certificateName `
            -vaultName $vaultName `
            -uri "https://$($resourceGroup)/$($domainName)" `
            -resourceGroup $resourceGroup `
            -adApplicationName "cert$($resourceGroup)$($domainName)"
        return $ret
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

    if (!$whatIf)
    {
        $ret = .\azure-rm-sql-create.ps1 -resourceGroupName $resourceGroup `
            -location $location `
            -databaseName RdsCb `
            -adminPassword $adminPassword `
            -servername "sql-server$($random)" `
            -nolog

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
    
    write-host "$([DateTime]::Now) starting new deployment. this will take a while..." -ForegroundColor Green
    write-host "New-AzureRmResourceGroupDeployment -Name $deployment `
                    -ResourceGroupName $resourceGroup `
                    -DeploymentDebugLogLevel All `
                    -TemplateFile $templateFile `
                    -adminUsername $global:credential.UserName "

    $error.Clear() 
    if (!$whatIf)
    {
        $ret = New-AzureRmResourceGroupDeployment -Name $deployment `
            -ResourceGroupName $resourceGroup `
            -DeploymentDebugLogLevel All `
            -TemplateFile $templateFile `
            -TemplateParameterFile $parameterFile
        #-adminUsername $global:credential.UserName `
        #-adminPassword $global:credential.Password `
            
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
    $scriptFile = $null

    try 
    {
        if ([IO.File]::Exists($destinationFile))
        {
            [IO.File]::Delete($destinationFile)
        }

        $jsonFile = Invoke-RestMethod -UseBasicParsing -Method Get -Uri $updateUrl

        # git may not have carriage return
        # reset by setting all to just lf
        $jsonFile = [regex]::Replace($jsonFile, "`r`n","`n")
        # add cr back
        $jsonFile = [regex]::Replace($jsonFile, "`n", "`r`n")
        
        $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
        [System.IO.File]::WriteAllLines($destinationFile, $jsonFile, $Utf8NoBomEncoding)
        
        return $true
    }
    catch [System.Exception] 
    {
        write-host "get-urlJsonFile:exception: $($error)"
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
        $scriptFile = [regex]::Replace($scriptFile, "`r`n","`n")
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
        write-host "get-urlScriptFile:exception: $($error)" -ForegroundColor Red
        $error.Clear()
        return $false    
    }
}

# ----------------------------------------------------------------------------------------------------------------
function start-rds-deployment()
{
    $deployment = "rds-deployment"
    write-host "$(get-date) starting $($deployment)..." -foregroundcolor cyan
    
    check-parameterFile -parameterFile $parameterFileRdsDeployment -deployment $deployment
    check-deployment -deployment $deployment

    $ujson = ConvertFrom-Json (get-content -Raw -Path $parameterFileRdsDeployment)
    if (!$useJson)
    {
        $ujson.parameters._artifactsLocation.value = "$($templateBaseRepoUri)$($deployment)"
        $ujson.parameters.adminPassword.value = $adminPassword
        $ujson.parameters.adminUserName.value = $adminUserName
        $ujson.parameters.dnsLabelPrefix.value = $dnsLabelPrefix
        $ujson.parameters.domainName.value = $domainName
        $ujson.parameters.imageSku.value = $imageSku
        $ujson.parameters.numberOfRdshInstances.value = $numberOfRdshInstances
        $ujson.parameters.publicIPAddressName.value = $publicIpAddressName
        $ujson.parameters.rdshVmSize.value = $rdshVmSize
        $ujson | ConvertTo-Json | Out-File $parameterFileRdsDeployment
    }
    
    $ujson.parameters
    deploy-template -templateFile "$($templateBaseRepoUri)/$($deployment)/azuredeploy.json" `
        -parameterFile $parameterFileRdsDeployment `
        -deployment $installOption
}

# ----------------------------------------------------------------------------------------------------------------
function start-rds-update-certificate()
{
    $deployment = "rds-update-certificate"
    write-host "$(get-date) starting $($deployment)..." -foregroundcolor cyan

    check-parameterFile -parameterFile $parameterFileRdsUpdateCertificate -deployment $deployment
    check-deployment -deployment $deployment
    $ret = create-cert
    
    $match = [regex]::Match($ret, "application id: (.+?) ")
    $applicationId = ($match.Captures[0].Groups[1].Value)
    $match = [regex]::Match($ret, "tenant id: (.+)")
    $tenantId = ($match.Captures[0].Groups[1].Value)
   
    $ujson = ConvertFrom-Json (get-content -Raw -Path $parameterFileRdsUpdateCertificate)
    if (!$useJson)
    {
        $ujson.parameters._artifactsLocation.value = "$($templateBaseRepoUri)$($deployment)"
        $ujson.parameters.applicationId.value = $applicationId
        $ujson.parameters.applicationPassword.value = $certificatePass
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
function start-rds-deployment-ha-broker()
{
    $deployment = "rds-deployment-ha-broker"
    write-host "$(get-date) starting $($deployment)..." -foregroundcolor cyan

    check-parameterFile -parameterFile $parameterFileRdsHaBroker -deployment $deployment
    check-deployment -deployment $deployment
    $odbcstring = create-sql

    $ujson = ConvertFrom-Json (get-content -Raw -Path $parameterFileRdsHaBroker)
    if (!$useJson)
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
    write-host "$(get-date) starting $($deployment)..." -foregroundcolor cyan

    check-parameterFile -parameterFile $parameterFileRdsHaGateway -deployment $deployment
    check-deployment -deployment $deployment

    $ujson = ConvertFrom-Json (get-content -Raw -Path $parameterFileRdsHaGateway)
    if (!$useJson)
    {
        $ujson.parameters._artifactsLocation.value = "$($templateBaseRepoUri)$($deployment)"
        $ujson.parameters.brokerServer.value = "$($brokerName).$($domainName)"
        $ujson.parameters.existingDomainName.value = $domainName
        $ujson.parameters.existingAdminUserName.value = $adminUserName
        $ujson.parameters.existingAdminPassword.value = $adminPassword
        $ujson.parameters.gatewayLoadbalancer.value = $gatewayLoadBalancer
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
    write-host "$(get-date) starting $($deployment)..." -foregroundcolor cyan

    if (!($installOptions -imatch "rds-deployment"))
    {
        if ((read-host "uber deployment requires an 'existing AD'. do you want to deploy 'rds-deployment' first?[y|n]" -imatch "y"))
        {
            start-rds-deployment
        }
    }

    check-parameterFile -parameterFile $parameterFileRdsUber -deployment $deployment
    check-deployment -deployment $deployment

    $primaryDbConnectionString = create-sql
    $ret = create-cert
    
    $match = [regex]::Match($ret, "application id: (.+?) ")
    $applicationId = ($match.Captures[0].Groups[1].Value)
    $match = [regex]::Match($ret, "tenant id: (.+)")
    $tenantId = ($match.Captures[0].Groups[1].Value)
    
    $ujson = ConvertFrom-Json (get-content -Raw -Path $parameterFileRdsUber)
    if (!$useJson)
    {
        $ujson.parameters._artifactsLocation.value = $templateBaseRepoUri
        $ujson.parameters.adminPassword.value = $adminPassword
        $ujson.parameters.adminUserName.value = $adminUserName
        $ujson.parameters.applicationId.value = $applicationId
        $ujson.parameters.applicationPassword.value = $certificatePass
        $ujson.parameters.certificateName.value = $certificateName
        $ujson.parameters.clientAccessName.value = $clientAccessName
        $ujson.parameters.dnsLabelPrefix.value = $dnsLabelPrefix
        $ujson.parameters.dnsServer.value = $dnsServer
        $ujson.parameters.domainName.value = $domainName
        $ujson.parameters.imageSku.value = $imageSku
        $ujson.parameters.numberOfRdshInstances.value = $numberOfRdshInstances
        $ujson.parameters.numberOfWebGwInstances.value = $numberOfWebGwInstances
        $ujson.parameters.primaryDbConnectionString.value = $primaryDbConnectionString
        $ujson.parameters.rdshVmSize.value = $rdshVmSize
        $ujson.parameters.sqlServer.value = $sqlServer
        $ujson.parameters.subnetName.value = $subnetName
        $ujson.parameters.vaultName.value = $vaultName
        $ujson.parameters.vnetName.value = $vnetName
        $ujson | ConvertTo-Json | Out-File $parameterFileRdsUber
    }
    $ujson.parameters
    
    deploy-template -templateFile "$($templateBaseRepoUri)/$($deployment)/azuredeploy.json" `
        -ParameterFile $parameterFileRdsUber `
        -deployment $installOption

}

# ----------------------------------------------------------------------------------------------------------------
function start-rds-update-rdsh-collection()
{
    $deployment = "rds-update-rdsh-collection"
    write-host "$(get-date) starting $($deployment)..." -foregroundcolor cyan

    check-parameterFile -parameterFile $parameterFileRdsUpdateRdshCollection -deployment $deployment
    check-deployment -deployment $deployment

    $ujson = ConvertFrom-Json (get-content -Raw -Path $parameterFileRdsUpdateRdshCollection)
    
    if(!$useJson)
    {
        if((read-host "Do you want to install a template vm from gallery into $($resourceGroup)?[y|n]") -imatch 'y')
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
                            
            .\azure-rm-vm-create.ps1 -publicIp `
                -resourceGroupName $resourceGroup `
                -location $location `
                -adminUsername $adminUsername `
                -adminPassword $adminpassword `
                -vmBaseName $templateVmNamePrefix `
                -vmStartCount 1 `
                -vmCount 1
        
            write-host "getting vhd location"
            $vm = Get-AzureRmVM -ResourceGroupName $resourceGroup -Name "$($templateVmNamePrefix)-001"
            $vm
            $vhdUri = $vm.StorageProfile.OsDisk.Vhd.Uri
        
            $tpIp = (Get-AzureRmPublicIpAddress -Name ([IO.Path]::GetFileName($vm.NetworkProfile.NetworkInterfaces[0].Id)) -ResourceGroupName $resourceGroup).IpAddress
        
            if([string]::IsNullOrEmpty($vhdUri) -or [string]::IsNullOrEmpty($tpIp))
            {
                write-host "error. something wrong... returning"
                exit 1
            }
        
            write-host "use mstsc connection to run sysprep on template c:\windows\system32\sysprep\sysprep.exe -oobe -generalize" -foregroundcolor Green
            mstsc /v $tpIp /admin
        
            write-host "waiting for machine to shutdown"
        
            while($true)
            {
                $vm = Get-AzureRmVM -ResourceGroupName $resourceGroup -Name "$($templateVmNamePrefix)-001" -Status

                if($vm.Statuses.Code.Contains("PowerState/stopped"))
                {
                    write-host "deallocating vm"
                    stop-azurermvm -name $vm.Name -Force -ResourceGroupName $resourceGroup
                
                    write-host "setting vm to OSState/generalized"
                    set-azurermvm -ResourceGroupName $resourceGroup -Name $vm.Name -Generalized 
                    break    
                }
                elseif($vm.Statuses.Code.Contains("PowerState/deallocated")) 
                {
                    break
                }
        
                start-sleep -Seconds 1
            }
        }
        else
        {
            if(!$useJson)
            {
                $vhdUri = $rdshTemplateImageUri
            }
        
            if(!$vhdUri)
            {
                $vm = Get-AzureRmVM -ResourceGroupName $resourceGroup -Name "$($templateVmNamePrefix)-001"
                $vhdUri = $vm.StorageProfile.OsDisk.Vhd.Uri
            }
        
            if($vhdUri)
            {
                $vhdUri
                if((read-host "Is this the correct path to vhd of template image to be used?[y|n]") -imatch 'n')
                {
                    $ujson.parameters.rdshTemplateImageUri.value = read-host "Enter new vhd path:"

                }
            }
        
        }
        
        if($vhdUri)
        {
            write-host "modifying json of $($quickstartTemplate) template with this path for rdshTemplateImageUri: $($vhdUri)"
            $ujson.parameters.rdshTemplateImageUri.value = $vhdUri
        }
        else
        {
            write-host "error:invalid vhd path. exiting"
            return
        }
        
        # to update iteration. only need to increment if running update multiple times against same collection
        if($ujson.parameters.rdshUpdateIteration.value)
        {
            $nextIteration = "$([int]($ujson.parameters.rdshUpdateIteration.value) + 1)"
        }
        else
        {
            $nextIteration = ""
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
        $ujson.parameters.rdshUpdateIteration.value = $nextIteration
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