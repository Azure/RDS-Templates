param variables_newNsgName string /* TODO: fill in correct type */

@description('Whether to create a new network security group or use an existing one')
param createNetworkSecurityGroup bool

@description('Location for all resources to be created in.')
param location string

@description('The tags to be assigned to the network security groups')
param networkSecurityGroupTags object

@description('The rules to be given to the new network security group')
param networkSecurityGroupRules array

resource variables_newNsgName_resource 'Microsoft.Network/networkSecurityGroups@2019-02-01' = if (createNetworkSecurityGroup) {
  name: variables_newNsgName
  location: location
  tags: networkSecurityGroupTags
  properties: {
    securityRules: networkSecurityGroupRules
  }
}
