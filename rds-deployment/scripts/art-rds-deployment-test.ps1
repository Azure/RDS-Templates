<#
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

.SYNOPSIS
    powershell script to test azure quickstart template rds-deployment
    this script requires WMF 5.0+ and Azure PowerShell SDK (install-module azure)

.DESCRIPTION
    powershell script to test azure quickstart template rds-deployment
    https://github.com/Azure/azure-quickstart-templates/tree/master/rds-deployment

    to enable script execution, you may need to Set-ExecutionPolicy Bypass -Force
     
.NOTES
   file name  : art-rds-deployment-test.ps1
   version    : 170314 changed assumed $adDomainName to lowercase

.EXAMPLE
    .\art-rds-deployment-test.ps1 -adminPassword changeme3240e2938r92 -resourceGroup rdsdeptest
    Example command to deploy rds-deployment with 2 instances using A1 machines. the resource group is rdsdeptest and domain fqdn is rdsdeptest.lab

.EXAMPLE
    .\art-rds-deployment-test.ps1 -adminPassword changeme3240e2938r92 -resourceGroup rdsdeptest -admin vmadministrator -instances 5 -size Standard_A4 -imagesku 2012-r2-Datacenter
    Example command to deploy rds-deployment with 5 instances using A4 machines. the resource group is rdsdeptest and domain fqdn is rdsdeptest.lab. 
    the admin account is vmadministrator and OS is 2012-r2-datacenter

.EXAMPLE
    .\art-rds-deployment-test.ps1 -useJson .\myexistingparameterfile.json
    Example command to deploy rds-deployment with a populated parameter json file.
    all properties from json file will be used. if no password is supplied, you will be prompted.

.EXAMPLE
    .\art-rds-deployment-test.ps1 -adminPassword changeme3240e2938r92 -resourceGroup rdsdeptest -monitor -postConnect
    Example command to deploy rds-deployment with 2 instances using A1 machines. the resource group is rdsdeptest and domain fqdn is rdsdeptest.lab
    before calling New-AzureRmResourceGroupDeployment, the powershell monitor script will be called.
    after successful deployment, the post connect powershell script will be called.

.PARAMETER adDomainName
    if specified, is the new AD domain fqdn used for this deployment. by default %resourceGroup%.lab will be used.

.PARAMETER adminUsername
    if specified, the name of the administrator account. by default vmadmin is used

.PARAMETER adminPassword
    if specified, the administrator account password in clear text. password needs to meet azure password requirements.
    use -credentials to pass credentials securely

.PARAMETER credentials
    can be used for administrator account password. password needs to meet azure password requirements.

.PARAMETER gwdnsLabelPrefix
    If specified, is the public DNS name label for gateway. default is the AD Domain prefix.

.PARAMETER gwpublicIPAddressName
    If specified, is the public ip address name. by default will use gwpip

.PARAMETER imageSKU
    default 2016-datacenter or optional 2012-r2-datacenter for OS selection type

.PARAMETER location
    If specified, is the azure regional datacenter location. by default will use eastus

.PARAMETER monitor
    If specified, will run "https://aka.ms/azure-rm-log-reader.ps1" before deployment

.PARAMETER numberofRdshInstances
    number of rdsh instances to create. by default this is 2

.PARAMETER postConnect
    If specified, will run "https://aka.ms/azure-rm-rdp-post-deployment.ps1" following deployment

.PARAMETER rdshVmSize
    size is the size of the azure vm's to use. If not specified, A1 will be used.

.PARAMETER resourceGroup
    resourceGroup is a mandatory paramenter and is the azure arm resourcegroup to use / create for this deployment

.PARAMETER savePassword
    if specified, will save the password in clear text into json file. default is to leave value empty

.PARAMETER test
    If specified, will test script and parameters but will not start deployment

.PARAMETER useJson
    If specified, will use passed json file for arguments when deploying

#>

param(
    [Parameter(Mandatory=$false)]
    [string]$adDomainName = "",
    [Parameter(Mandatory=$false)]
    [string]$adminUsername = "vmadmin",
    [Parameter(Mandatory=$false)]
    [string]$adminPassword = "", 
    [Parameter(Mandatory=$false)]
    [pscredential]$credentials,
    [Parameter(Mandatory=$false)]
    [string]$deploymentName,
    [Parameter(Mandatory=$false)]
    [string]$gwdnsLabelPrefix,
    [Parameter(Mandatory=$false)]
    [string]$gwpublicIPAddressName = "gwpip",
    [Parameter(Mandatory=$false)]
    [string][ValidateSet('2012-R2-Datacenter', '2016-Datacenter')]
    [string]$imageSKU = "2016-Datacenter",
    [Parameter(Mandatory=$false)]
    [int]$numberofRdshInstances = 2,
    [Parameter(Mandatory=$false)]
    [string]$location,
    [Parameter(Mandatory=$false)]
    [switch]$monitor,
    [Parameter(Mandatory=$false)]
    [switch]$postConnect,
    [Parameter(Mandatory=$false)]
    [string]$rdshVmSize = "Standard_A1",
    [Parameter(Mandatory=$true)]
    [string]$resourceGroup,
    [Parameter(Mandatory=$false)]
    [switch]$savePassword,
    [Parameter(Mandatory=$false)]
    [switch]$test,
    [Parameter(Mandatory=$false)]
    [string]$useJson
)

# shouldnt need modification
$error.Clear()
$ErrorActionPreference = "Continue"
$quickStartTemplate = "rds-deployment"
$parameterFile = ".\$($quickStartTemplate).azuredeploy.parameters.json" 
$templateFile = "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/$($quickstartTemplate)/azuredeploy.json" 

if([string]::IsNullOrEmpty($deploymentName))
{
    $deploymentName = $resourceGroup
}

if(![string]::IsNullOrEmpty($useJson))
{
    $parameterFile = $useJson
}

if(!(test-path $parameterFile))
{
    write-host "unable to find json file $($parameterFile)"

    # create new json if not exist
    if(![IO.File]::Exists($parameterFile))
    {
        $ujson = @{'$schema'="https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#";
            "contentVersion"="1.0.0.0";
            "parameters"= @{
            "adDomainName" = @{ "value"= $adDomainName };
            "adminPassword" = @{ "value"= "" };
            "adminUsername" = @{ "value"= $adminUsername };
            "gwdnsLabelPrefix" = @{ "value"= $gwdnsLabelPrefix };
            "gwpublicIPAddressName" = @{ "value"= $gwpublicIPAddressName };
            "imageSKU" = @{ "value"= $imageSKU };
            "numberOfRdshInstances" = @{ "value"= $numberofRdshInstances };
            "rdshVmSize" = @{ "value"= $rdshVmSize };
        }}

        $ujson | ConvertTo-Json | Out-File $parameterFile
    }
}

write-host "running quickstart:$($quickStartTemplate) for group $($resourceGroup)"

write-host "authenticating to azure"
try
{
    Get-AzureRmResourceGroup | Out-Null
}
catch
{
    Add-AzureRmAccount

    try
    {
        Get-AzureRmResourceGroup | Out-Null
    }
    catch
    {
        write-warning "authentication failed. verify authentiation and restart script."
        exit 1
    }
}

write-host "reading parameter file $($parameterFile)"
$ujson = ConvertFrom-Json (get-content -Raw -Path $parameterFile)

if(![string]::IsNullOrEmpty($useJson))
{
    $adDomainName = $ujson.parameters.adDomainName.value
    $adminPassword = $ujson.parameters.adminPassword.value
    $adminUsername = $ujson.parameters.adminUsername.value
    $gwdnsLabelPrefix = $ujson.parameters.gwdnsLabelPrefix.value
    $gwpublicIPAddressName = $ujson.parameters.gwpublicIPAddressName.value
    $imageSKU = $ujson.parameters.imageSKU.value
    $numberofRdshInstances = $ujson.parameters.numberofRdshInstances.value
    $rdshVmSize = $ujson.parameters.rdshVmSize.value
    #$resourceGroup = $ujson.parameters.gwdnsLabelPrefix.value
}

write-host "checking resource group"

if([string]::IsNullOrEmpty($resourceGroup))
{
    write-warning "resourcegroup is a mandatory argument. supply -resourceGroup argument and restart script."
    exit 1
}

write-host "checking ad domain name"

if([string]::IsNullOrEmpty($adDomainName))
{
    $adDomainName = "$($resourceGroup.ToLower()).lab"
    write-host "setting adDomainName to $($adDomainName)"
}

if([string]::IsNullOrEmpty($adDomainName.Split(".")[1]))
{
    $adDomainName = "$($adDomainName).lab"
    write-host "setting adDomainName to $($adDomainName)"
}

write-host "checking dns label"

if([string]::IsNullOrEmpty($gwdnsLabelPrefix))
{
    $gwdnsLabelPrefix = $adDomainName.Split(".")[0]
    write-host "setting gwdnsLabelPrefix to $($gwdnsLabelPrefix)"
}

if($gwdnsLabelPrefix.Length -gt 15)
{
    write-warning "error: domain name greater than 15 characters $($gwdnsLabelPrefix). shorten name and restart script." -ForegroundColor Yellow
    return
}

write-host "checking location"

if(!(Get-AzureRmLocation | Where-Object Location -Like $location) -or [string]::IsNullOrEmpty($location))
{
    (Get-AzureRmLocation).Location
    write-warning "location: $($location) not found. supply -location using one of the above locations and restart script."
    exit 1
}

write-host "checking vm size"

if(!(Get-AzureRmVMSize -Location $location | Where-Object Name -Like $rdshVmSize))
{
    Get-AzureRmVMSize -Location $location
    write-warning "rdshVmSize: $($rdshVmSize) not found in $($location). correct -rdshVmSize using one of the above options and restart script."
    exit 1
}

write-host "checking sku"

if(!(Get-AzureRmVMImageSku -Location $location -PublisherName MicrosoftWindowsServer -Offer WindowsServer | Where-Object Skus -Like $imageSKU))
{
    Get-AzureRmVMImageSku -Location $location -PublisherName MicrosoftWindowsServer -Offer WindowsServer 
    write-warning "image sku: $($imageSku) not found in $($location). correct -imageSKU using one of the above options and restart script."
    exit 1
}

write-host "checking password"

if(!$credentials)
{
    if([string]::IsNullOrEmpty($adminPassword))
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
if($adminPassword -match "[A-Z]") { $count++ }
# lowercase check
if($adminPassword -match "[a-z]") { $count++ }
# numeric check
if($adminPassword -match "\d") { $count++ }
# specialKey check
if($adminPassword -match "\W") { $count++ } 

if($adminPassword.Length -lt 8 -or $adminPassword.Length -gt 123 -or $count -lt 3)
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

write-host "modifying json of $($parameterFile) template with params"

$ujson.parameters.adDomainName.value = $adDomainName

if($savePassword)
{
    write-warning "saving password into json in clear text. this is not best practice"
    $ujson.parameters.adminPassword.value = $adminPassword
}

$ujson.parameters.adminUsername.value = $adminUsername
$ujson.parameters.gwdnsLabelPrefix.value = $gwdnsLabelPrefix
$ujson.parameters.gwpublicIPAddressName.value = $gwpublicIPAddressName
$ujson.parameters.imageSKU.value = $imageSKU
$ujson.parameters.numberOfRdshInstances.value = $numberofRdshInstances
$ujson.parameters.rdshVmSize.value = $rdshVmSize

$ujson | ConvertTo-Json | Out-File $parameterFile

$ujson | ConvertTo-Json

write-host "checking for existing deployment"

if((Get-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroup -Name $deploymentName -ErrorAction SilentlyContinue))
{
    if((read-host "resource group deployment exists! Do you want to delete?[y|n]") -ilike 'y')
    {
        Remove-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroup -Name $deploymentName -Confirm
    }
}

write-host "checking for existing resource group"

if((Get-AzureRmResourceGroup -Name $resourceGroup -ErrorAction SilentlyContinue))
{
    if((read-host "resource group exists! Do you want to delete?[y|n]") -ilike 'y')
    {
        Remove-AzureRmResourceGroup -Name $resourceGroup
    }
}

# create resource group if it does not exist
if(!(Get-AzureRmResourceGroup -Name $resourceGroup -ErrorAction SilentlyContinue))
{
    Write-Host "creating resource group $($resourceGroup) in location $($location)"   
    New-AzureRmResourceGroup -Name $resourceGroup -Location $location
}

write-host "validating template"
$error.Clear() 
$ret = $null
$ret = Test-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroup `
    -TemplateFile $templateFile `
    -Mode Complete `
    -adminUsername $global:credential.UserName `
    -adminPassword $global:credential.Password `
    -TemplateParameterFile $parameterFile 

if(![string]::IsNullOrEmpty($ret))
{
    Write-Error "template validation failed. error: `n`n$($ret.Code)`n`n$($ret.Message)`n`n$($ret.Details)"
    exit 1
}

if($monitor)
{
    write-host "$([DateTime]::Now) starting monitor"
    $monitorScript = "$(get-location)\azure-rm-log-reader.ps1"
    
    if(![IO.File]::Exists($monitorScript))
    {
        [IO.File]::WriteAllText($monitorScript, 
            (Invoke-WebRequest -UseBasicParsing -Uri "https://aka.ms/azure-rm-log-reader.ps1").ToString().Replace("???",""))
    }

    Start-Process -FilePath "powershell.exe" -ArgumentList "-WindowStyle Minimized -ExecutionPolicy Bypass $($monitorScript)"
}

if(!$test)
{
    write-host "$([DateTime]::Now) creating deployment"
    $error.Clear() 
   
    New-AzureRmResourceGroupDeployment -Name $deploymentName `
      -ResourceGroupName $resourceGroup `
      -DeploymentDebugLogLevel All `
      -TemplateFile $templateFile `
      -adminUsername $global:credential.UserName `
      -adminPassword $global:credential.Password `
      -TemplateParameterFile $parameterFile 

    if(!$error -and $postConnect)
    {
        write-host "$([DateTime]::Now) starting post connect"
        $connectScript = "$(get-location)\azure-rm-rdp-post-deployment.ps1"
    
        if(![IO.File]::Exists($connectScript))
        {
            # get script content from url and remove BOM
            string $scriptContent = (Invoke-WebRequest -UseBasicParsing -Uri "https://aka.ms/azure-rm-rdp-post-deployment.ps1").ToString().Replace("???","")
            [IO.File]::WriteAllText($connectScript, $scriptContent)
        }
        
        $rdWebSite = "https://$($gwdnsLabelPrefix).$($location).cloudapp.azure.com/RDWeb"
        write-host "connecting to $($rdWebSite)"
        Invoke-Expression -Command "$($connectScript) -rdWebUrl `"$($rdWebSite)`""
    }
}

write-host "$([DateTime]::Now) finished"
