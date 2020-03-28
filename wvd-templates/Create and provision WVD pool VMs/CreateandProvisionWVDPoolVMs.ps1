[int]$desiredPoolVMCount=24
[int]$allocationBatchSize=1
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
[string]$userName="user01"
#create a random password that meet's Azure's rules - https://gallery.technet.microsoft.com/office/Generate-Random-Password-ca4c9f07
[string]$password=(-join(65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90|%{[char]$_}|Get-Random -C 2)) + (-join(97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122|%{[char]$_}|Get-Random -C 2)) + (-join(65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90|%{[char]$_}|Get-Random -C 2)) + (-join(97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122|%{[char]$_}|Get-Random -C 2)) + (-join(64,33,35,36|%{[char]$_}|Get-Random -C 1))  + (-join(49,50,51,52,53,54,55,56,57|%{[char]$_}|Get-Random -C 3)) 
[string]$dnsPrefixForPublicIP

#Connect-AzAccount
#for testing
$resourceGroupName += New-Guid

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
    #NOTE: for some reason Get-AzDeployment doesn't return any results (RBAC?) so am forced to use custom array
    foreach ($deployment in $deployments) {
        if ($deployment.Completed -eq $false) {

            #get all the operations running
            $runningOperations = get-azresourcegroupdeploymentoperation `
            -DeploymentName $deployment.Name -ResourceGroupName $resourceGroupName `
            | Select-Object -ExpandProperty properties `
            | Where-Object {($_.provisioningState -match "Running")}

            #if there are any, then see if any are VMs
            #there HAVE to be VM operations at some point so if none exist then we haven't gotten far enough just bail
            if ($runningOperations.Count -gt 0) {
                
                #filter down to just VMs
                $vmOperations = $runningOperationsCount | Where-Object {$_.properties.targetResource -match "virtualMachines"}
                if ($vmOperations.Count -gt 0) {

                    #find just the VM operations that are still running
                    $runningVMOperations = $vmOperations | Select-Object -ExpandProperty properties `
                    | Where-Object {$_.provisioningState -match "Running"}

                    #if none are still running, then we either fully completed or failed - either is good here
                    if ($runningVMOperations.Count -eq 0)
                    {
                        $deployment.Completed=$true
                    }
                }
            }
        }
    }

    #see if we need to kick off any deployments
    $needMoreDeployments = $false
    if (($deployments | Where-Object {$_.Completed -eq $false}).Count -lt $maxSimulanteousDeployments) {
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
        Switch ($allocationBatchSize -gt $countAdditionalVMs)
        {
            $true { $vmsToDeploy = $countAdditionalVMs }
            $false { $vmsToDeploy = $allocationBatchSize }
        }

        #build the creds
        [securestring]$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force

        #build a DNS name
        $dnsPrefixForPublicIP = -join ((65..90) + (97..122) | Get-Random -Count 10 | % {[char]$_})

        #TODO: Need to add error handling for when the deployment is invalid for some reason (quota, validation failure, etc.)
        #kick off an ARM deployment to deploy a batch of VMs
        [string]$uniqueIDforBatch = New-Guid
        $deploymentName="$($batchNamingPrefix)$($deploymentIteration)-$($uniqueIDforBatch)"
        New-AzResourceGroupDeployment `
        -Name $deploymentName `
        -ResourceGroupName $resourceGroupName `
        -virtualMachineCount $vmsToDeploy `
        -virtualMachineAdminUserName $userName `
        -virtualMachineAdminPassword $securePassword `
        -AsJob `
        -virtualMachineNamePrefix "$($vmNamingPrefix)-$($deploymentIteration)-" `
        -dnsPrefixForPublicIP "$($dnsPrefixForPublicIP)".ToLower() `
        -TemplateUri "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vm-copy-managed-disks/azuredeploy.json" `
    #        -TemplateParameterFile "C:\Users\evanba\source\repos\RDS-Templates\wvd-templates\Create and provision WVD pool VMs\parameters.json" 

        #add the new deployment to the array for tracking purposes
        $deployment = New-Object -TypeName PSObject
        $deployment | Add-Member -Name 'Name' -MemberType Noteproperty -Value $deploymentName
        $deployment | Add-Member -Name 'Completed' -MemberType Noteproperty -Value $false
        $deployments += $deployment
    }

    #sleep for a bit
    Start-Sleep -s (60*$sleepTimeMin)

    #increment the loop counter so the next iteration gets a different deployment name
    $deploymentIteration += 1

} while ($countAdditionalVMs -gt $allocationBatchSize)

#after everything is done, redeploy any deployed with failed VMs
#this will ensure any transient failures are addressed