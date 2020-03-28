[int]$desiredPoolVMCount=100
[int]$allocationBatchSize=25
[string]$batchNamingPrefix="WVDDeploymentBatch"
[string]$vmNamingPrefix="WVDVM"
[int]$sleepTimeMin=0
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
#if so, then kick off a deployment of the allocation batch size or the rest of the VMs needed - whichever is smaller
#if not, do nothing

#start looping through creating VMs
[int]$deploymentIteration=0
do {

    #loop through all the deployments which aren't already marked as completed
    #if they are done, update the Completed property
    foreach ($deployment in $deployments) {
        if ($deployment.Completed -ne $false) {
            $runningOperationsCount = (get-azresourcegroupdeploymentoperation `
            -DeploymentName "$($batchNamingPrefix)$($deploymentIteration)" -ResourceGroupName $resourceGroupName `
            | Select-Object -ExpandProperty properties `
            | Where-Object {($_.provisioningState -match "Running")}).count

            if ($runningOperationsCount -eq 0)
            {
                $deployment.Completed=$true
            }
        }
    }

    #see if we need to kick off any deployments
    $needMoreDeployments = $false
    if ($deployments | Where-Object {$_.Completed = $false} -lt $maxSimulanteousDeployments) {
        $needMoreDeployments = $true
    }

    #kick of any necessary deployments to ensure we are always running $maxSimulanteousDeployments
    [int]$vmsToDeploy = 0
    if ($needMoreDeployments)
    {
        #see how many VMs exist
        $countExistingVMs = (Get-AzVM -ResourceGroupName $resourceGroupName).Count

        #now, figure out how many more VMs need created
        $countAdditionalVMs = $desiredPoolVMCount - $countExistingVMs

        #deploy either the total desired or the allocation pool count - whichever is smaller
        Switch ($allocationBatchSize > $countAdditionalVMs)
        {
            $true { $vmsToDeploy = $countAdditionalVMs }
            $false { $vmsToDeploy = $allocationBatchSize }
        }

        #kick off an ARM deployment to deploy a batch of VMs
        $deploymentName="$($batchNamingPrefix)$($deploymentIteration)"
        New-AzResourceGroupDeployment `
        -Name $deploymentName `
        -ResourceGroupName $resourceGroupName `
        -virtualMachineCount $vmsToDeploy `
        -AsJob `
        -virtualMachineNamePrefix $($vmNamingPrefix)-$($ARMBatch)
        -TemplateUri "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vm-copy-managed-disks/azuredeploy.json" `
    #        -TemplateParameterFile "C:\Users\evanba\source\repos\RDS-Templates\wvd-templates\Create and provision WVD pool VMs\parameters.json" 

        #add the new deployment to the array for tracking purposes
        $deployment = New-Object -TypeName PSObject
        $deployment | Add-Member -Name 'Name' -MemberType Noteproperty -Value $deploymentName
        $deployment | Add-Member -Name 'Completed' -MemberType Noteproperty -Value $false
        $deployments += $deployment
    }

    #sleep for a bit
    Start-Sleep -s 60*$sleepTimeMin

    #increment the loop counter so the next iteration gets a different deployment name
    $deploymentIteration += 1

} while ($countAdditionalVMs > $allocationPoolSize)

#after everything is done, redeploy any deployed with failed VMs
#this will ensure any transient failures are addressed