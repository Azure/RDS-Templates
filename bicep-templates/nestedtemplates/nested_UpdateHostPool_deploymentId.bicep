@description('The name of the Hostpool to be created.')
param hostpoolName string

@description('The location of the host pool to be updated. Used when the host pool was created empty.')
param hostpoolLocation string

@description('The properties of the Hostpool to be updated. Used when the host pool was created empty.')
param hostpoolProperties object

resource hostpoolName_resource 'Microsoft.DesktopVirtualization/hostpools@2019-12-10-preview' = {
  name: hostpoolName
  location: hostpoolLocation
  properties: hostpoolProperties
}
