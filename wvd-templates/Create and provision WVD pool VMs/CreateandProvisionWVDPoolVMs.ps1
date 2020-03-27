[int]$desiredPoolVMCount=100
[int]$allocationBatchSize=25
$sleepIntervalMin=5
$resourceGroupName="WVDTestRG"
$location="EastUS"
$VMNamingPrefix="megaVM"
$targetVNETName="megaVNET"
$targetSubnetName="default"


Connect-AzAccount

#create resource group if necessary
Get-AzResourceGroup -Name $resourceGroupname -ErrorVariable notPresent -ErrorAction SilentlyContinue
if ($notPresent)
{
    #resource group doesn't exist, so create
    New-AzResourceGroup `
        -Name $resourceGroupname `
        -Location $location
}

#create VNET and subnet if necessary
Get-AzVirtualNetwork -Name $targetVNETName -ResourceGroup $resourceGroupName -ErrorVariable notPresent -ErrorAction SilentlyContinue
if ($notPresent)
{
    #VNET doesn't exist, so create
    $virtualNetwork = New-AzVirtualNetwork `
        -ResourceGroupName $resourceGroupName `
        -Location $location `
        -Name $targetVNETName `
        -AddressPrefix 10.0.0.0/16

    Add-AzVirtualNetworkSubnetConfig `
        -Name $targetSubnetName `
        -AddressPrefix 10.0.0.0/24 `
        -VirtualNetwork $virtualNetwork

    $virtualNetwork | Set-AzVirtualNetwork
}


[int]$countExistingVMs=0
[int]$countAdditionalVMs=0

#since we know how many VMs we want, let's figure out how many we need to deploy
#first, query to see how many already exist
$existingVMs = Get-AzVM -ResourceGroupName $resourceGroupName
$countExistingVMs = $existingVMs.count

#now, figure out how many more VMs need created
$countAdditionalVMs = $desiredPoolVMCount - $countExistingVMs

#generate logic flow is as follows:
#deploy up to the allocation batch size
#sleep for a bit
#wake up and check if we have less deployments running than 80% of the batch size 
#if so, then kick off a deployment of VMs equal to the delta
#if not, do nothing

#start looping through creating VMs
do {

    #deploy either the total desired or the allocation pool count - whichever is smaller
    [int]$vmsToDeploy
    Switch ($allocationBatchSize > $countAdditionalVMs)
    {
        $false { $vmsToDeploy = $countAdditionalVMs }
        $true { $vmsToDeploy = $allocationBatchSize }
    }

    #kick off an ARM deployment to deploy the number of VMs just calculated
    New-AzResourceGroupDeployment `
        -ResourceGroupName $resourceGroupName `
        -TemplateFile <path-to-template> `
        -vmcount $vmsToDeploy

    #update the count of existing
    $existingVMs = Get-AzVM -ResourceGroupName $resourceGroupName
    $countExistingVMs = $existingVMs.count

    #update the count of how many more we need
    $countAdditionalVMs = $desiredPoolVMCount - $countExistingVMs

} while ($countAdditionalVMs > $allocationPoolSize)