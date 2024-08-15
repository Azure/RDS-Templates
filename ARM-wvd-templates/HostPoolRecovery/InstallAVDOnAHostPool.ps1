param(
    [Parameter(Mandatory=$true)]
    [string]$subscriptionId,

    [Parameter(Mandatory=$true)]
    [string]$resourceGroupName,

    [Parameter(Mandatory=$true)]
    [string]$hostPoolName
)

# Login to Azure
Write-Output "Logging in to Azure..."
# need to use usedeviceauthentication because without, it is broken
Connect-AzAccount -UseDeviceAuthentication

# Select the subscription
Write-Output "Selecting subscription..."
Select-AzSubscription -SubscriptionId $subscriptionId

# Get all session hosts in the host pool
Write-Output "Retrieving session hosts"
$sessionHosts = Get-AzWvdSessionHost -ResourceGroupName $resourceGroupName -HostPoolName $hostPoolName
Write-Output "Session Hosts Retrieved: $sessionHosts"
$configurationZipUri = "https://raw.githubusercontent.com/Azure/RDS-Templates/master/ARM-wvd-templates/DSC/Configuration.zip"

#remove this and switch to azure storage blob
$fileUri = "https://raw.githubusercontent.com/Azure/RDS-Templates/master/ARM-wvd-templates/HostPoolRecovery/FallBackBootloaderDownload.ps1"

# Iterate over each session host
foreach ($sessionHost in $sessionHosts) {
    # Get the name of the session host    
    $virtualMachineResourceId = $sessionHost.ResourceId
    # parse the name from the ARM resource id sessionHost.ResourceId
    $virtualMachineName = $virtualMachineResourceId -split '/' | Select-Object -Last 1

    # get virtual machine using $virtualMachineResourceId
    $virtualMachine = Get-AzVM -ResourceGroupName $resourceGroupName -Name $virtualMachineName

    $location = $virtualMachine.Location
    Write-Output "Virtual Machine Name: $virtualMachineName"
    # potential hard disk space issue

    # set-azcustomscriptextension to run the function InstallAVDOnVirtualMachine on the virtual machine
    $fileName = "FallBackBootloaderDownload.ps1"
    
    Set-AzVMCustomScriptExtension -ResourceGroupName $resourceGroupName -VMName $virtualMachineName -Location $location -FileUri $fileUri, $configurationZipUri -Run $fileName -Name "InstallAVDOnVirtualMachine"
}

