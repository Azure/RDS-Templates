<#
script to create multiple vm's into existing azure rm infrastructure
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
#170825
#>
param(
    [parameter(Mandatory = $true, HelpMessage = "Enter admin user name: ex:vmadmin")]
    [string]$adminUsername = "",
    [parameter(Mandatory = $true, HelpMessage = "Enter admin password complex 13 char:")]
    [string]$adminPassword = "",
    [switch]$enumerateSub,
    [switch]$force,
    [string]$galleryImage = "2016-Datacenter",
    [parameter(Mandatory = $true, HelpMessage = "Enter location: ex:eastus")]
    [string]$location = "",
    [string]$offername = "WindowsServer",
    [switch]$publicIp,
    [string]$pubName = "MicrosoftWindowsServer",
    [parameter(Mandatory = $true, HelpMessage = "Enter resource group name:")]
    [string]$resourceGroupName,
    [string]$StorageAccountName,
    [string]$StorageType = "Standard_GRS",
    [string]$subnetName = "",
    [string]$subscription,
    
    [string]$vmBaseName = "",
    [int]$vmCount = 1,
    [string]$vmSize = "Standard_A2",
    [int]$vmStartCount = 1,
    [string]$VNetAddressPrefix = "10.0.0.0/16",
    [string]$VNetSubnetAddressPrefix = "10.0.0.0/24",
    [string]$vnetName = ""
)

$vnetNamePrefix = "vnet"
$subnetNamePrefix = "subnet"
$storagePrefix = "storage"
$global:credential
$global:storageAccount
$global:vnet

# ----------------------------------------------------------------------------------------------------------------
function main()
{
    authenticate-azureRm
    manage-credential

    if ($enumerateSub)
    {
        enum-subscription
        return
    }

    if (!($location) -or `
            !($resourceGroupName) -or `
            !($galleryImage) -or `
            !($pubName) -or `
            !($VMSize))
    {
        write-host "missing required argument"
        turn
    }


    # check to make sure vm doesnt exist
    $i = $startCount
    $jobs = @()
    $newVmNames = new-object Collections.ArrayList
    $Error.Clear()

    $resourceGroupName = check-resourceGroupName -resourceGroupName $resourceGroupName
    $storageAccountName = check-storageAccountName -resourceGroupName $resourceGroupName -storageAccountName $storageAccountName
    $vnetName = check-vnetName -resourceGroupName $resourceGroupName -vnetName $vnetName
    $subnetName = check-subnetName -resourceGroupName $resourceGroupName -vnetName $vnetName -subnetName $subnetName

    for ($i = $vmstartCount; $i -lt $vmstartcount + $VMCount; $i++)
    {
        $newVmName = "$($vmBaseName)-$($i.ToString("D2"))"
        
        if (Get-AzureRMVM -resourceGroupName $resourceGroupName -Name $newVMName -ErrorAction SilentlyContinue)
        {
            Write-Host "vm already exists $newVMName. skipping..."
        }
        else
        {
            write-host "adding new machine name to list: $($newvmName)"
            $newVmNames.Add($newVmName)
        }
    }

    foreach ($VMName in $newVMNames)
    {
        # todo make concurrent with start-job?
        # would need cert conn to azure

        Write-Host "creating vm $VMName"
        $OSDiskName = $VMName + "OSDisk"
        $InterfaceName = "$($vmName)Interface1"

        # Network
        if ($publicIp)
        {
            write-host "creating public ip"
            $PIp = New-AzureRmPublicIpAddress -Name $InterfaceName -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod Dynamic
            $Interface = New-AzureRmNetworkInterface -Name $InterfaceName -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $global:vnet.Subnets[0].Id -PublicIpAddressId $PIp.Id
        }
        else
        {
            $Interface = New-AzureRmNetworkInterface -Name $InterfaceName -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $global:vnet.Subnets[0].Id
        }

        # Compute
        ## Setup local VM object

        $VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize
        $VirtualMachine = Set-AzureRmVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $global:Credential -ProvisionVMAgent -EnableAutoUpdate
        $VirtualMachine = Set-AzureRmVMSourceImage -VM $VirtualMachine -PublisherName $pubName -Offer $offerName -Skus $galleryImage -Version "latest"
        $VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $Interface.Id
        $OSDiskUri = $global:StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
        $VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -Name $OSDiskName -VhdUri $OSDiskUri -CreateOption FromImage

        ## Create the VM in Azure
        New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VirtualMachine
    }

    write-host "finished"
    return $newVmNames
}
# ----------------------------------------------------------------------------------------------------------------

function authenticate-azureRm()
{
    # authenticate
    try
    {
        Get-AzureRmResourceGroup | Out-Null
    }
    catch
    {
        Add-AzureRmAccount
    }

    if ($force)
    {
        Login-AzureRmAccount
    }


    #if($force -or (!($adminPassword) -or !($adminUsername)))
    #{
    if ($global:credential -eq $null)
    {
        $global:Credential = Get-Credential
    }
    #}
}
# ----------------------------------------------------------------------------------------------------------------

function check-resourceGroupName($resourceGroupName)
{
    if (!($resourceGroupName) -and @(Get-AzureRmResourceGroup).Count -eq 1)
    {
        $resourceGroupName = (Get-AzureRmResourceGroup).Name
        
    }
    elseif (!($resourceGroupName))
    {
        write-host (Get-AzureRmResourceGroup | fl * | out-string)
        $resourceGroupName = read-host "enter resource group"
    }
    elseif (!(Get-AzureRmResourceGroup $resourceGroupName))
    {
        write-host "creating resource group: $($resourceGroupName)"
        New-AzureRmResourceGroup -Name $resourceGroupName -Location $Location 
    }

    return $resourceGroupName
}
# ----------------------------------------------------------------------------------------------------------------

function check-storageAccountName($resourceGroupName, $StorageAccountName)
{
    # see if only one storage account if name empty and use that
    if (!($storageAccountName) -and @(Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName).Count -eq 1)
    {
        $global:storageAccount = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName
        write-host = "using default storage account:$($storageAccount.Name)"
    }
    elseif (!($storageAccountName) -and @(Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName).Count -gt 1)
    {
        $storageList = @{}
        $count = 1
        foreach ($storageName in Get-AzureRmStorageAccount -resourcegroupname $resourcegroupname)
        {
            $storageList.Add($count,$storageName.StorageAccountName)
            write-host "$($count). $($storageName.StorageAccountName)"
            $count++
        }

        $storageAccountNumber = [int](read-host "enter number of storage account to use:")
        $storageAccountName = $storageList.Item($storageAccountNumber)

        if (!($storageAccountName))
        {
            return
        }

        $global:storageAccount = Get-AzureRmStorageAccount -Name $StorageAccountName -ResourceGroupName $resourceGroupName
    }
    elseif ((!($storageAccountName) -and @(Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName).Count -lt 1) `
            -or !(Get-AzureRmStorageAccount -Name $StorageAccountName -ResourceGroupName $resourceGroupName))
    {
        if (!($storageAccountName))
        {

            $storageAccountName = ("$($storagePrefix)$($resourceGroupName)").ToLower()
            $storageAccountName = $storageAccountName.Substring(0, [Math]::Min($storageAccountName.Length, 23))
        }

        write-host "creating storage account: $($storageAccountName)"
        $global:StorageAccount = New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -Type $StorageType -Location $Location
    }
    elseif ((Get-AzureRmStorageAccount -Name $StorageAccountName -ResourceGroupName $resourceGroupName))
    {
        $global:StorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName
    }
    else
    {
        write-host "need storage account name. exiting"
        return
    }

    return $storageAccountName
}
# ----------------------------------------------------------------------------------------------------------------

function check-vnetName($resourceGroupName, $vnetName)
{
    # see if only one vnet if name empty and use that
    if (!($vnetName) -and @(Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroupName).Count -eq 1)
    {
        $global:vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroupName
        write-host = "using default vnet:$($vnet.Name)"
    }
    elseif (!(Get-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $resourceGroupName))
    {
        if (!($VNetName))
        {
            $VNetName = "$vnetNamePrefix$($resourceGroupName)"
        }

        if (!($subnetName))
        {
            $subNetName = "$subnetNamePrefix$($resourceGroupName)"
        }

        write-host "creating vnet: $($vnetName)"
        write-host "creating subnet: $($subnetName)"
        $SubnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $VNetSubnetAddressPrefix 
        $global:vnet = New-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix $VNetAddressPrefix -Subnet $SubnetConfig
    }
    else
    {
        $global:vnet = Get-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -Location $Location
    }

    return $vnetName
}
# ----------------------------------------------------------------------------------------------------------------

function check-subnetName($resourceGroupName, $vnetName, $subnetName)
{
    # see if only one subnet if name empty and use that
    if (!($subnetName) -and @(Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet).Count -eq 1)
    {
        $subnetConfig = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet
        write-host = "using default subnet:$($subnetConfig.Name)"
    }
    elseif (!(Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnetName))
    {
        write-host "creating subnet: $($subnetName)"
        $SubnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $VNetSubnetAddressPrefix
        $vnet.Subnets.Add($SubnetConfig)
    }
    else
    {
        $SubnetConfig = Get-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $VNetName
    }

}
# ----------------------------------------------------------------------------------------------------------------

function enum-subscription()
{
    If (!($location))
    {
        write-host "AVAILABLE LOCATIONS:" -ForegroundColor Green
        write-host (Get-AzureRmLocation | fl * | out-string)
        write-host "need location:exiting"
        return
    }

    write-host "CURRENT SUBSCRIPTION:" -ForegroundColor Green
    Get-AzureRmSubscription

    write-host "CURRENT VMS:" -ForegroundColor Green
    Get-AzureRmVM | out-gridview

    write-host "AVAILABLE LOCATIONS:" -ForegroundColor Green
    Get-AzureRmLocation | out-gridview
    write-host "AVAILABLE IMAGES:" -ForegroundColor Green
    Get-AzureRMVMImage -Location $location -PublisherName $pubName -Offer $offerName -Skus $galleryImage | out-gridview
    write-host "AVAILABLE ROLES:" -ForegroundColor Green
    Get-AzureRoleSize | out-gridview
    write-host "AVAILABLE STORGE:" -ForegroundColor Green
    Get-AzureRmStorageAccount | out-gridview
    write-host "AVAILABLE NETWORKS:" -ForegroundColor Green
    Get-AzureRmVirtualNetwork | out-gridview
    write-host "AVAILABLE SUBNETS:" -ForegroundColor Green
    #write-host (Get-AzureRmVirtualNetworkSubnetConfig | fl * | out-gridview)
}
# ----------------------------------------------------------------------------------------------------------------

function manage-credential()
{
    
    if (!($adminPassword) -or !($adminUsername))
    {
        write-host "either admin and / or adminpassword were empty, returning."
        return
    }

    $SecurePassword = $adminPassword | ConvertTo-SecureString -AsPlainText -Force  
    $global:credential = new-object System.Management.Automation.PSCredential -ArgumentList $adminUsername, $SecurePassword
}
# ----------------------------------------------------------------------------------------------------------------

main