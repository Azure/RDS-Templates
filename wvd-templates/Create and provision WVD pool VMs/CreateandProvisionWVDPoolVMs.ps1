$desiredPoolVMCount=100
$allocationPoolSize=25
$sleepIntervalMin=5
$resourceGroupName="WVDTestRG"
$location="EastUS"
$VMNamingPrefix="megaVM"
$targetVNETName="megaVNET"
$targetSubnetName="default"

New-AzResourceGroup `
  -Name $resourceGroupname `
  -Location $location

$virtualNetwork = New-AzVirtualNetwork `
  -ResourceGroupName $resourceGroupName `
  -Location $location `
  -Name $targetVNETName `
  -AddressPrefix 10.0.0.0/16

$subnetConfig = Add-AzVirtualNetworkSubnetConfig `
-Name $targetSubnetName `
-AddressPrefix 10.0.0.0/24 `
-VirtualNetwork $virtualNetwork

$virtualNetwork | Set-AzVirtualNetwork

New-AzVm `
    -ResourceGroupName $resourceGroupName `
    -Name $VMNamingPrefix `
    -Location $location `
    -VirtualNetworkName $targetVNETName `
    -SubnetName $targetSubnetName