# azure quickstart templates
# rds-update-collection deployment
# 170105 added vhduri checking
# 161216 added params numINstances


param(
    $existingRdshCollectionName = "Desktop Collection",
    $location = "", # if empty will read from deployment being updated (resource group)
    $numInstances = 2,
    [Parameter(Mandatory=$true)]
    $resourceGroup,
    $quickStartTemplate = "rds-update-rdsh-collection",
    $quickStartTemplateToUpdate = "rds-deployment",
    $adminUsername = "cloudadmin",
    $adminpassword = "",
    $templatePrefix = "tpl",
    $templateFile = "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/$($quickstartTemplate)/azuredeploy.json",

    $parameterFile = ".\$($quickStartTemplate).azuredeploy.parameters.json",
    $parameterFileToUpdate = ".\$($quickStartTemplateToUpdate).azuredeploy.parameters.json",

    [switch]$vmss
)

$error.Clear()
#https://github.com/Azure/azure-quickstart-templates/tree/master/rds-update-rdsh-collection

cls
write-host "$(get-date) starting"

if(!(test-path $parameterFile))
{
    write-host "unable to find json file $($parameterFile)"
    exit 1
}

if(!(test-path $parameterFileToUpdate))
{
    write-host "unable to find json file $($parameterFileToUpdate)"
    exit 1
}

write-host "pulling parameters from existing template file for quickstart deployment being updated $($parameterFileToUpdate)"
$ujson = ConvertFrom-Json (get-content -Raw -Path $parameterFileToUpdate)
$pjson = ConvertFrom-Json (get-content -Raw -Path $parameterFile)

$resourceGroup = $ujson.parameters.dnsLabelPrefix.value
$adminUsername = $ujson.parameters.adminUsername.value
$adminpassword = $ujson.parameters.adminPassword.value

# to update iteration. only need to increment if running update multiple times against same collection
$pjson.parameters.rdshUpdateIteration.value = "$([int]($pjson.parameters.rdshUpdateIteration.value) + 1)"

$pjson.parameters.existingRdshCollectionName.value = $existingRdshCollectionName
$pjson.parameters.rdshNumberofInstances.value = $numInstances #$ujson.parameters.numberofRdshInstances.value
$pjson.parameters.rdshVmSize.value = $ujson.parameters.rdshVmSize.value
$pjson.parameters.UserLogoffTimeoutInMinutes.value = 60
$pjson.parameters.existingDomainName.value = $ujson.parameters.adDomainName.value
$pjson.parameters.existingAdminusername.value = $ujson.parameters.adminUsername.value
$pjson.parameters.existingAdminPassword.value = $ujson.parameters.adminPassword.value
$pjson.parameters.existingVnetName.value = "vnet" #"ADVNET$($resourceGroup)"
$pjson.parameters.existingSubnetName.value = "subnet" #"ADStaticSubnet$($resourceGroup)"
$pjson.parameters._artifactsLocation.value = "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/rds-update-rdsh-collection"
$pjson.parameters._artifactsLocationSasToken.value = ""
$pjson.parameters.availabilitySet.value = "rdsh-availabilityset"

$pjson | ConvertTo-Json | Out-File $parameterFile

write-host "running quickstart:$($quickStartTemplate) for group $($resourcegroup) to update existing template $($quickstartTemplateToUpdate)"

# authenticate
try
{
    Get-AzureRmResourceGroup | Out-Null
}
catch
{
    Add-AzureRmAccount
}

# check for existing deployment
if((Get-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroup -Name $quickstarttemplate -ErrorAction SilentlyContinue))
{
    if((read-host "resource group deployment exists! Do you want to delete?[y|n]") -ilike 'y')
    {
        Remove-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroup -Name $quickStartTemplate -Confirm
    }

}

# check for existing resource group
if(!(Get-AzureRmResourceGroup -Name $resourceGroup -ErrorAction SilentlyContinue))
{
    if((read-host "resource does not exist! When running RDS update rdsh collection template, the resource group should exist. Do you want to continue?[y|n]") -ilike 'n')
    {
        exit 1
    }
    else
    {
        if([string]::IsNullOrEmpty($location))
        {
            $location = read-host "enter location. example eastus:"
        }

        New-AzureRmResourceGroup -Name $resourceGroup -Location $location
    }
}

if([string]::IsNullOrEmpty($location))
{
    $location = (Get-AzureRmResourceGroup -Name $resourceGroup).Location
}

if((read-host "Do you want to install a template vm from gallery into $($resourceGroup)?[y|n]") -imatch 'y')
{
    write-host "adding template vm"

    .\azure-rm-vm-create.ps1 -publicIp `
        -resourceGroupName $resourceGroup `
        -location $location `
        -adminUsername $adminUsername `
        -adminPassword $adminpassword `
        -vmBaseName $templatePrefix `
        -vmStartCount 1 `
        -vmCount 1

    write-host "getting vhd location"
    $vm = Get-AzureRmVM -ResourceGroupName $resourceGroup -Name "$($templatePrefix)-001"
    $vm
    $vhdUri = $vm.StorageProfile.OsDisk.Vhd.Uri

    $tpIp = (Get-AzureRmPublicIpAddress -Name ([IO.Path]::GetFileName($vm.NetworkProfile.NetworkInterfaces[0].Id)) -ResourceGroupName $resourceGroup).IpAddress

    if([string]::IsNullOrEmpty($vhdUri) -or [string]::IsNullOrEmpty($tpIp))
    {
        write-host "error. something wrong... returning"
        exit 1
    }

    #write-host "setting local winrm to allow connection to any target '*'"
    #Set-Item WSMan:localhost\Client\TrustedHosts  -value * -Force

    write-host "need to run sysprep on template c:\windows\system32\sysprep\sysprep.exe -oobe -generalize"
    # not working
    #invoke-command -ComputerName $tpIp -Credential $global:credential -ScriptBlock { invoke-expression 'cmd /c c:\windows\system32\sysprep\sysprep.exe -oobe -generalize' }
    mstsc /v $tpIp /admin

    write-host "waiting for machine to shutdown"

    while($true)
    {
    #    write-host "--------------------------"
        $vm = Get-AzureRmVM -ResourceGroupName $resourceGroup -Name "$($templatePrefix)-001" -Status
    #    $vm.Statuses.Code

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
    $ujson = ConvertFrom-Json (get-content -Raw -Path $parameterFile)
    $vhdUri = $ujson.parameters.rdshTemplateImageUri.value

    if([string]::IsNullOrEmpty($vhdUri))
    {
        $vm = Get-AzureRmVM -ResourceGroupName $resourceGroup -Name "$($templatePrefix)-001"
        $vhdUri = $vm.StorageProfile.OsDisk.Vhd.Uri
    }

    if(![string]::IsNullOrEmpty($vhdUri))
    {
        $vhdUri
        if((read-host "Is this the correct path to vhd of template image to be used?[y|n]") -imatch 'n')
        {
            $ujson.parameters.rdshTemplateImageUri.value = read-host "Enter new vhd path:"
            $ujson | ConvertTo-Json | Out-File $parameterFile
        }
    }

}

if(![string]::IsNullOrEmpty($vhdUri))
{
    write-host "modify json of $($quickstartTemplate) template with this path for rdshTemplateImageUri: $($vhdUri)"
    $ujson = ConvertFrom-Json (get-content -Raw -Path $parameterFile)
    $ujson.parameters.rdshTemplateImageUri.value = $vhdUri
    $ujson | ConvertTo-Json | Out-File $parameterFile
}
else
{
    write-host "error:invalid vhd path. exiting"
    return
}

if($vmss)
{
    exit
}

# test
if(Test-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroup `
    -TemplateFile $templateFile `
    -Mode Incremental `
    -TemplateParameterFile $parameterFile)
{
    # create new deployment
    New-AzureRmResourceGroupDeployment -Name  $quickStartTemplate `
      -ResourceGroupName $resourceGroup `
      -DeploymentDebugLogLevel All `
      -TemplateFile $templateFile `
      -TemplateParameterFile $parameterFile 


}
else
{
    write-host "template test failed. exiting"
}

write-host "$(get-date) finished"
