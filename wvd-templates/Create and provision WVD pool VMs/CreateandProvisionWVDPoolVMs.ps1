$isTesting = $true
[int]$desiredPoolVMCount=10
[int]$allocationBatchSize=1
[int]$maxSimulanteousDeployments = 3
[string]$batchNamingPrefix="WVDDeploymentBatch"
[int]$sleepTimeMin=3
$resourceGroupName="WVDTestRG"
$location="EastUS"
$VMNamingPrefix="megaVM"
$targetVNETName="megaVNET"
$targetSubnetName="default"
[string]$userName="user01"
[bool]$isTesting=$true
#build a random DNS name that meets Azure's criteria
[string]$dnsPrefixForPublicIP = -join ((65..90) + (97..122) | Get-Random -Count 10 | % {[char]$_})
#create a random password that meet's Azure's rules - https://gallery.technet.microsoft.com/office/Generate-Random-Password-ca4c9f07
[string]$password=(-join(65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90|%{[char]$_}|Get-Random -C 2)) + (-join(97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122|%{[char]$_}|Get-Random -C 2)) + (-join(65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90|%{[char]$_}|Get-Random -C 2)) + (-join(97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122|%{[char]$_}|Get-Random -C 2)) + (-join(64,33,35,36|%{[char]$_}|Get-Random -C 1))  + (-join(49,50,51,52,53,54,55,56,57|%{[char]$_}|Get-Random -C 3)) 
#build the password as a secure string
[securestring]$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
$deployments = @()

#enforce most current rules to help catch run-time failures
Set-StrictMode -Version Latest

#Connect-AzAccount
#for testing
if ($isTesting) {
    Write-Debug "Running in Testing mode"
    $resourceGroupName += New-Guid
}

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
#query to see how many VMs already exist
$existingVMs = @()
$existingVMs = Get-AzVM -ResourceGroupName $resourceGroupName
if (!$existingVMs) {
    #no VMs in the resource group yet
    $countExistingVMs = 0
}
else {
    #VMs already exist, so use the count
    $countExistingVMs = $existingVMs.Count
}

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
    #TODO: Switch this to checking on the job status
    foreach ($deployment in $deployments) {
        if ($deployment.Completed -eq $false) {

            #get all the operations running
            $runningOperations = @(get-azresourcegroupdeploymentoperation `
            -DeploymentName $deployment.Name -ResourceGroupName $resourceGroupName `
            | Select-Object -ExpandProperty properties)
#            | Where-Object {(($_.provisioningState -match "Running") -or ($_.provisioningState -match "Succeeded"))}

            #if there are any, then see if any are VMs
            #there HAVE to be VM operations at some point so if none exist then we haven't gotten far enough
            if (($runningOperations | Measure-Object).Count -gt 0) {
                
                #filter down to just VMs
                $vmOperations = @($runningOperations | Where-Object {$_.targetResource -match "virtualMachines"})
                if (($vmOperations | Measure-Object).Count -gt 0) {

                    #find just the VM operations that are still running
                    $runningVMOperations = @($vmOperations | Where-Object {$_.provisioningState -match "Running"})

                    #if none are still running, then we either fully completed or failed - either is acceptable here
                    if (($runningVMOperations | Measure-Object).Count -eq 0)
                    {
                        $deployment.Completed=$true
                    }
                }
            }
        }
    }

    #see if we need to kick off any deployments
    #if $deployments is null or current count less than $maxSimultaneousDeployments, then we need to allow deployments
    $needMoreDeployments = $false
    if (!$deployments) {
        #if no deployments at all, then allow more to kick off
        $needMoreDeployments = $true
    }
    else {
        #if we have deployments already, then count all where not complete
        if ((($deployments | Where-Object {$_.Completed -eq $false}) | Measure-Object).Count -lt $maxSimulanteousDeployments) {

            #less than $maxSimultaneousDeployments, so allow more to kick off
            $needMoreDeployments = $true
        }
    }

    #kick of any necessary deployments to ensure we are always running $maxSimulanteousDeployments
    [int]$vmsToDeploy = 0
    if ($needMoreDeployments)
    {
        #now, figure out how many more VMs need created
        $countAdditionalVMs = $desiredPoolVMCount - $countExistingVMs

        #deploy either the total desired or the allocation pool count - whichever is smaller
        Switch ($allocationBatchSize -gt $countAdditionalVMs)
        {
            $true { $vmsToDeploy = $countAdditionalVMs }
            $false { $vmsToDeploy = $allocationBatchSize }
        }

        #TODO: Need to add error handling for when the deployment is invalid for some reason (quota, validation failure, etc.)
        #kick off an ARM deployment to deploy a batch of VMs
        [string]$uniqueIDforBatch = New-Guid
        $deploymentName="$($batchNamingPrefix)$($deploymentIteration)-$($uniqueIDforBatch)"
        (New-AzResourceGroupDeployment `
        -Name $deploymentName `
        -ResourceGroupName $resourceGroupName `
        -virtualMachineCount $vmsToDeploy `
        -virtualMachineAdminUserName $userName `
        -virtualMachineAdminPassword $securePassword `
        -AsJob `
        -virtualMachineNamePrefix "$($vmNamingPrefix)-$($deploymentIteration)-" `
        -dnsPrefixForPublicIP "$($dnsPrefixForPublicIP)".ToLower() `
        -TemplateUri "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vm-copy-managed-disks/azuredeploy.json" ).Name = $deploymentName
    #        -TemplateParameterFile "C:\Users\evanba\source\repos\RDS-Templates\wvd-templates\Create and provision WVD pool VMs\parameters.json" 

        #make sure the deployment started OK. If not, then dump the error to the screen
        if ((Get-Job -Name "$($deploymentName)").State -ne "Failed") {

            #add the new deployment to the array for tracking purposes
            Write-Host "Successfully started deployment $($deploymentName)"
            $deployment = New-Object -TypeName PSObject
            $deployment | Add-Member -Name 'Name' -MemberType Noteproperty -Value $deploymentName
            $deployment | Add-Member -Name 'Completed' -MemberType Noteproperty -Value $false
            $deployments += $deployment
            Write-Debug "Added $($deploymentName) to tracking array"
    
            #increment the loop counter so the next iteration gets a different deployment name
            $deploymentIteration += 1
        }    
        else {
            Write-Debug "$($deploymentName) failed validation"
            #job is in a failed state - report the reason
            $job = Get-Job -Name "$($deploymentName)"
            throw Receive-Job -Job $job -Keep
        }

        Write-Debug ""
    }

    #sleep for a bit
    Start-Sleep -s (60*$sleepTimeMin)

} while ($countAdditionalVMs -gt $allocationBatchSize)

#after everything is done, redeploy any deployed with failed VMs
#this will ensure any transient failures are addressed