param avSetSKU string

@description('The name of avaiability set to be used when create the VMs.')
param availabilitySetName string

@description('The location of the session host VMs.')
param vmLocation string

@description('The tags to be assigned to the availability set')
param availabilitySetTags object

@description('The platform update domain count of avaiability set to be created.')
@allowed([
  1
  2
  3
  4
  5
  6
  7
  8
  9
  10
  11
  12
  13
  14
  15
  16
  17
  18
  19
  20
])
param availabilitySetUpdateDomainCount int

@description('The platform fault domain count of avaiability set to be created.')
@allowed([
  1
  2
  3
])
param availabilitySetFaultDomainCount int

resource availabilitySetName_resource 'Microsoft.Compute/availabilitySets@2018-10-01' = {
  name: availabilitySetName
  location: vmLocation
  tags: availabilitySetTags
  properties: {
    platformUpdateDomainCount: availabilitySetUpdateDomainCount
    platformFaultDomainCount: availabilitySetFaultDomainCount
  }
  sku: {
    name: avSetSKU
  }
}
