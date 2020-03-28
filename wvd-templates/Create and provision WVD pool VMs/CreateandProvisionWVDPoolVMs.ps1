[int]$desiredPoolVMCount=100
[int]$allocationBatchSize=25
[string]$batchNamingPrefix="WVDDeploymentBatch"
[string]$vmNamingPrefix="WVDVM"
[single]$minimumConcurrentAllocationsPercentage=0.8
[int]$sleepTimeMin=1
$resourceGroupName="WVDTestRG"
$location="EastUS"
$VMNamingPrefix="megaVM"
$targetVNETName="megaVNET"
$targetSubnetName="default"
[int]$maxSimulanteousDeployments=3
[array]$deployments = @()


#Connect-AzAccount

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

#general logic flow is as follows:
#deploy up to maxSimulanteousDeployments each one having the allocation batch size
#sleep for a bit
#wake up and check if we have less than maxSimulanteousDeployments deployments running
#if so, then kick off a deployment of the allocation batch size
#if not, do nothing

#start looping through creating VMs
[int]$deploymentIteration=0
do {

    #get the count of active deployments from the *previous* batch
    $countofVMDeployments = get-azresourcegroupdeploymentoperation `
        -DeploymentName "$($batchNamingPrefix)$($deploymentIteration)" -ResourceGroupName $resourceGroupName `
        | Where-Object {$_.properties.targetResource -match "virtualMachines"} `
        | Select-Object -ExpandProperty properties 

    #get the count of the completed deployments from the *previous* batch
    $countofVMDeploymentsCompleted = get-azresourcegroupdeploymentoperation -DeploymentName testdeploy10 -ResourceGroupName wvdrg3 `
    | Where-Object {$_.properties.targetResource -match "virtualMachines"} `
    | Select-Object -ExpandProperty properties `
    | Where-Object {$_.provisioningState -match "Succeeded"}

    #see if ratio is below target ratio
    [int]$vmsToDeployIncrement = 0
    [int]$ARMBatch = 0
    if (1-$countofVMDeploymentsCompleted/$countofVMDeployments -lt $minimumConcurrentAllocationsPercentage)
    {
        #deploy more VMs

        #see how many VMs exist
        $existingVMs = Get-AzVM -ResourceGroupName $resourceGroupName
        $countExistingVMs = $existingVMs.count

        #now, figure out how many more VMs need created
        $countAdditionalVMs = $desiredPoolVMCount - $countExistingVMs

        #deploy either the total desired or the allocation pool count - whichever is smaller
        Switch ($allocationBatchSize > $countAdditionalVMs)
        {
            $true { $vmsToDeployIncrement = $countAdditionalVMs }
            $false { $vmsToDeployIncrement = $allocationBatchSize * (1-$minimumConcurrentAllocationsPercentage)}
        }

        #if the ARM deployment is more than 200, tweak the naming prefix
        #otherwise, all we do is redeploy the ones already out there
        if ($vmsToDeployIncrement -gt 200) {
            $ARMBatch += 1
        }

        #kick off an ARM deployment to deploy the number of VMs just calculated
        #because we are doing this via a template, just increment the total VM count
        #it has the additional benefit of potentially fixing up any busted VMs
        #because ARM templates are declarative
        $vmsToDeploy += $vmsToDeployIncrement
        New-AzResourceGroupDeployment `
        -Name $deployment.Name `
        -ResourceGroupName $resourceGroupName `
        -virtualMachineCount $vmsToDeploy `
        -AsJob `
        -virtualMachineNamePrefix $($vmNamingPrefix)-$($ARMBatch)
        -TemplateUri "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vm-copy-managed-disks/azuredeploy.json" `
    #        -TemplateParameterFile "C:\Users\evanba\source\repos\RDS-Templates\wvd-templates\Create and provision WVD pool VMs\parameters.json" 
        
        #add the new deployment to the array for tracking purposes
        $deployment = New-Object -TypeName PSObject
        $deployment | Add-Member -Name 'Name' -MemberType Noteproperty -Value "$($batchNamingPrefix)$($deploymentIteration)"
        $deployment | Add-Member -Name 'Completed' -MemberType Noteproperty -Value $false
        $deployments += $deployment
    }

    #sleep for a bit
    Start-Sleep -s 60*$sleepTimeMin

    #wake up and check if we have less deployments running than specified percentage of the batch size 

    #get the count of active deployments from the *previous* batch
    $countofVMDeployments = get-azresourcegroupdeploymentoperation -DeploymentName testdeploy10 -ResourceGroupName wvdrg3 `
    | Where-Object {$_.properties.targetResource -match "virtualMachines"} `
    | Select-Object -ExpandProperty properties `

    #gets all the deployments that have succeeded
    $countofVMDeploymentsCompleted = get-azresourcegroupdeploymentoperation -DeploymentName testdeploy10 -ResourceGroupName wvdrg3 `
        | Where-Object {$_.properties.targetResource -match "virtualMachines"} `
        | Select-Object -ExpandProperty properties `
        | Where-Object {$_.provisioningState -match "Succeeded"}

    #if so, then drop through the while loop so we can kick off another batch
    #update the count of existing
    $existingVMs = Get-AzVM -ResourceGroupName $resourceGroupName
    $countExistingVMs = $existingVMs.count

    #update the count of how many more we need
    $countAdditionalVMs = $desiredPoolVMCount - $countExistingVMs

    #increment the loop counter so the next iteration gets a different deployment name
    $deploymentIteration += 1

} while ($countAdditionalVMs > $allocationPoolSize)