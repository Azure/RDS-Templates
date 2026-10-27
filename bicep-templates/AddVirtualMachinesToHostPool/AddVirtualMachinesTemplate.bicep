@description('The base URI where artifacts required by this template are located.')
param nestedTemplatesLocation string = 'https://raw.githubusercontent.com/Azure/RDS-Templates/master/ARM-wvd-templates/nestedtemplates/'

@description('The base URI where artifacts required by this template are located.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/RDS-Templates/master/ARM-wvd-templates/DSC/Configuration.zip'

@description('The name of the Hostpool to be created.')
param hostpoolName string

@description('The token of the host pool where the session hosts will be added.')
@secure()
param hostpoolToken string

@description('The resource group of the host pool to be updated. Used when the host pool was created empty.')
param hostpoolResourceGroup string = ''

@description('The location of the host pool to be updated. Used when the host pool was created empty.')
param hostpoolLocation string = ''

@description('The properties of the Hostpool to be updated. Used when the host pool was created empty.')
param hostpoolProperties object = {
}

@description('The host pool VM template. Used when the host pool was created empty.')
param vmTemplate string = ''

@description('A username in the domain that has privileges to join the session hosts to the domain. For example, \'vmjoiner@contoso.com\'.')
param administratorAccountUsername string = ''

@description('The password that corresponds to the existing domain username.')
@secure()
param administratorAccountPassword string = ''

@description('A username to be used as the virtual machine administrator account. The vmAdministratorAccountUsername and  vmAdministratorAccountPassword parameters must both be provided. Otherwise, domain administrator credentials provided by administratorAccountUsername and administratorAccountPassword will be used.')
param vmAdministratorAccountUsername string = ''

@description('The password associated with the virtual machine administrator account. The vmAdministratorAccountUsername and  vmAdministratorAccountPassword parameters must both be provided. Otherwise, domain administrator credentials provided by administratorAccountUsername and administratorAccountPassword will be used.')
@secure()
param vmAdministratorAccountPassword string = ''

@description('Select the availability options for the VMs.')
@allowed([
  'None'
  'AvailabilitySet'
  'AvailabilityZone'
])
param availabilityOption string = 'None'

@description('The name of avaiability set to be used when create the VMs.')
param availabilitySetName string = ''

@description('Whether to create a new availability set for the VMs.')
param createAvailabilitySet bool = false

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
param availabilitySetUpdateDomainCount int = 5

@description('The platform fault domain count of avaiability set to be created.')
@allowed([
  1
  2
  3
])
param availabilitySetFaultDomainCount int = 2

@description('The number of availability zone to be used when create the VMs.')
@allowed([
  1
  2
  3
])
param availabilityZone int = 1

@description('The resource group of the session host VMs.')
param vmResourceGroup string

@description('The location of the session host VMs.')
param vmLocation string

@description('The size of the session host VMs.')
param vmSize string

@description('VM name prefix initial number.')
param vmInitialNumber int

@description('Number of session hosts that will be created and added to the hostpool.')
param vmNumberOfInstances int

@description('This prefix will be used in combination with the VM number to create the VM name. If using \'rdsh\' as the prefix, VMs would be named \'rdsh-0\', \'rdsh-1\', etc. You should use a unique prefix to reduce name collisions in Active Directory.')
param vmNamePrefix string

@description('Select the image source for the session host vms. VMs from a Gallery image will be created with Managed Disks.')
@allowed([
  'CustomVHD'
  'CustomImage'
  'Gallery'
  'Disk'
])
param vmImageType string = 'Gallery'

@description('(Required when vmImageType = Gallery) Gallery image Offer.')
param vmGalleryImageOffer string = ''

@description('(Required when vmImageType = Gallery) Gallery image Publisher.')
param vmGalleryImagePublisher string = ''

@description('(Required when vmImageType = Gallery) Gallery image SKU.')
param vmGalleryImageSKU string = ''

@description('(Required when vmImageType = Gallery) Gallery image version.')
param vmGalleryImageVersion string = ''

@description('Whether the VM has plan or not')
param vmGalleryImageHasPlan bool = false

@description('(Required when vmImageType = CustomVHD) URI of the sysprepped image vhd file to be used to create the session host VMs. For example, https://rdsstorage.blob.core.windows.net/vhds/sessionhostimage.vhd')
param vmImageVhdUri string = ''

@description('(Required when vmImageType = CustomImage) Resource ID of the image')
param vmCustomImageSourceId string = ''

@description('The VM disk type for the VM: HDD or SSD.')
@allowed([
  'Premium_LRS'
  'StandardSSD_LRS'
  'Standard_LRS'
])
param vmDiskType string = 'Standard_LRS'

@description('True indicating you would like to use managed disks or false indicating you would like to use unmanaged disks.')
param vmUseManagedDisks bool

@description('(Required when vmUseManagedDisks = False) The resource group containing the storage account of the image vhd file.')
param storageAccountResourceGroupName string = ''

@description('The name of the virtual network the VMs will be connected to.')
param existingVnetName string

@description('The subnet the VMs will be placed in.')
param existingSubnetName string

@description('The resource group containing the existing virtual network.')
param virtualNetworkResourceGroupName string

@description('Whether to create a new network security group or use an existing one')
param createNetworkSecurityGroup bool = false

@description('The resource id of an existing network security group')
param networkSecurityGroupId string = ''

@description('The rules to be given to the new network security group')
param networkSecurityGroupRules array = []

@description('The tags to be assigned to the availability set')
param availabilitySetTags object = {
}

@description('The tags to be assigned to the network interfaces')
param networkInterfaceTags object = {
}

@description('The tags to be assigned to the network security groups')
param networkSecurityGroupTags object = {
}

@description('The tags to be assigned to the virtual machines')
param virtualMachineTags object = {
}

@description('The tags to be assigned to the images')
param imageTags object = {
}

@description('GUID for the deployment')
param deploymentId string = ''

@description('WVD api version')
param apiVersion string = '2019-12-10-preview'

@description('OUPath for the domain join')
param ouPath string = ''

@description('Domain to join')
param domain string = ''

@description('True if AAD Join, false if AD join')
param aadJoin bool = false

@description('True if intune enrollment is selected. False otherwise')
param intune bool = false

@description('Boot diagnostics object taken as body of Diagnostics Profile in VM creation')
param bootDiagnostics object = {
  enabled: false
}

@description('The name of user assigned identity that will assigned to the VMs. This is an optional parameter.')
param userAssignedIdentity string = ''

@description('ARM template that contains custom configurations to be run after the virtual machines are created.')
param customConfigurationTemplateUrl string = ''

@description('Url to the ARM template parameter file for the customConfigurationTemplateUrl parameter. This input will be used when the template is ran after the VMs have been deployed.')
param customConfigurationParameterUrl string = ''

@description('System data is used for internal purposes, such as support preview features.')
param systemData object = {
}

var rdshManagedDisks = ((vmImageType == 'CustomVHD') ? vmUseManagedDisks : bool('true'))
var rdshPrefix = '${vmNamePrefix}-'
var avSetSKU = (rdshManagedDisks ? 'Aligned' : 'Classic')
var vhds = 'vhds/${rdshPrefix}'
var var_subnet_id = resourceId(virtualNetworkResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', existingVnetName, existingSubnetName)
var vmTemplateName = '${(rdshManagedDisks ? 'managedDisks' : 'unmanagedDisks')}-${toLower(replace(vmImageType, ' ', ''))}vm'
var vmTemplateUri = '${nestedTemplatesLocation}${vmTemplateName}.json'
var rdshVmNamesCopyNamesArr = [for item in range(0, (vmNumberOfInstances)): {
  name: '${rdshPrefix}${vmInitialNumber + item}'
}]
var rdshVmNamesOutput = {
  rdshVmNamesCopy: rdshVmNamesCopyNamesArr
}
module UpdateHostPool_deploymentId '../nestedtemplates/nested_UpdateHostPool_deploymentId.bicep' = if (!empty(hostpoolResourceGroup)) {
  name: 'UpdateHostPool-${deploymentId}'
  scope: resourceGroup(hostpoolResourceGroup)
  params: {
    hostpoolName: hostpoolName
    hostpoolLocation: hostpoolLocation
    hostpoolProperties: hostpoolProperties
  }
}

module AVSet_linkedTemplate_deploymentId '../nestedtemplates/nested_AVSet_linkedTemplate_deploymentId.bicep' = if ((availabilityOption == 'AvailabilitySet') && createAvailabilitySet) {
  name: 'AVSet-linkedTemplate-${deploymentId}'
  scope: resourceGroup(vmResourceGroup)
  params: {
    avSetSKU: avSetSKU
    availabilitySetName: availabilitySetName
    vmLocation: vmLocation
    availabilitySetTags: availabilitySetTags
    availabilitySetUpdateDomainCount: availabilitySetUpdateDomainCount
    availabilitySetFaultDomainCount: availabilitySetFaultDomainCount
  }
  dependsOn: [
    UpdateHostPool_deploymentId
  ]
}

module vmCreation_managed_customvhdvm '../nestedtemplates/managedDisks-customvhdvm.bicep' = if (vmTemplateUri == 'managedDisks-customvhdvm.bicep') {
  name: 'vmCreation_managed_customvhdvm-${deploymentId}'
  scope: resourceGroup(vmResourceGroup)
  params: {
    artifactsLocation: artifactsLocation
    availabilityOption: availabilityOption
    availabilitySetName: availabilitySetName
    availabilityZone: availabilityZone
    vmImageVhdUri: vmImageVhdUri
    storageAccountResourceGroupName: storageAccountResourceGroupName
    vmGalleryImageOffer: vmGalleryImageOffer
    vmGalleryImagePublisher: vmGalleryImagePublisher
    vmGalleryImageHasPlan: vmGalleryImageHasPlan
    vmGalleryImageSKU: vmGalleryImageSKU
    vmGalleryImageVersion: vmGalleryImageVersion
    rdshPrefix: rdshPrefix
    rdshNumberOfInstances: vmNumberOfInstances
    rdshVMDiskType: vmDiskType
    rdshVmSize: vmSize
    enableAcceleratedNetworking: false
    vmAdministratorAccountUsername: vmAdministratorAccountUsername
    vmAdministratorAccountPassword: vmAdministratorAccountPassword
    administratorAccountUsername: administratorAccountUsername
    administratorAccountPassword: administratorAccountPassword
    subnet_id: var_subnet_id
    vhds: vhds
    rdshImageSourceId: vmCustomImageSourceId
    location: vmLocation
    createNetworkSecurityGroup: createNetworkSecurityGroup
    networkSecurityGroupId: networkSecurityGroupId
    networkSecurityGroupRules: networkSecurityGroupRules
    networkInterfaceTags: networkInterfaceTags
    networkSecurityGroupTags: networkSecurityGroupTags
    virtualMachineTags: virtualMachineTags
    imageTags: imageTags
    vmInitialNumber: vmInitialNumber
    hostpoolName: hostpoolName
    hostpoolToken: hostpoolToken
    domain: domain
    ouPath: ouPath
    aadJoin: aadJoin
    intune: intune
    bootDiagnostics: bootDiagnostics
    guidValue: deploymentId
    userAssignedIdentity: userAssignedIdentity
    customConfigurationTemplateUrl: customConfigurationTemplateUrl
    customConfigurationParameterUrl: customConfigurationParameterUrl
    SessionHostConfigurationVersion: (contains(systemData, 'hostpoolUpdate') ? systemData.sessionHostConfigurationVersion : '')
  }
}

module vmCreation_managed_galleryvm '../nestedtemplates/managedDisks-galleryvm.bicep' = if (vmTemplateUri == 'managedDisks-galleryvm.bicep') {
  name: 'vmCreation_managed_galleryvm-${deploymentId}'
  scope: resourceGroup(vmResourceGroup)
  params: {
    artifactsLocation: artifactsLocation
    availabilityOption: availabilityOption
    availabilitySetName: availabilitySetName
    availabilityZone: availabilityZone
    vmImageVhdUri: vmImageVhdUri
    storageAccountResourceGroupName: storageAccountResourceGroupName
    vmGalleryImageOffer: vmGalleryImageOffer
    vmGalleryImagePublisher: vmGalleryImagePublisher
    vmGalleryImageHasPlan: vmGalleryImageHasPlan
    vmGalleryImageSKU: vmGalleryImageSKU
    vmGalleryImageVersion: vmGalleryImageVersion
    rdshPrefix: rdshPrefix
    rdshNumberOfInstances: vmNumberOfInstances
    rdshVMDiskType: vmDiskType
    rdshVmSize: vmSize
    enableAcceleratedNetworking: false
    vmAdministratorAccountUsername: vmAdministratorAccountUsername
    vmAdministratorAccountPassword: vmAdministratorAccountPassword
    administratorAccountUsername: administratorAccountUsername
    administratorAccountPassword: administratorAccountPassword
    subnet_id: var_subnet_id
    vhds: vhds
    rdshImageSourceId: vmCustomImageSourceId
    location: vmLocation
    createNetworkSecurityGroup: createNetworkSecurityGroup
    networkSecurityGroupId: networkSecurityGroupId
    networkSecurityGroupRules: networkSecurityGroupRules
    networkInterfaceTags: networkInterfaceTags
    networkSecurityGroupTags: networkSecurityGroupTags
    virtualMachineTags: virtualMachineTags
    imageTags: imageTags
    vmInitialNumber: vmInitialNumber
    hostpoolName: hostpoolName
    hostpoolToken: hostpoolToken
    domain: domain
    ouPath: ouPath
    aadJoin: aadJoin
    intune: intune
    bootDiagnostics: bootDiagnostics
    guidValue: deploymentId
    userAssignedIdentity: userAssignedIdentity
    customConfigurationTemplateUrl: customConfigurationTemplateUrl
    customConfigurationParameterUrl: customConfigurationParameterUrl
    SessionHostConfigurationVersion: (contains(systemData, 'hostpoolUpdate') ? systemData.sessionHostConfigurationVersion : '')
  }
}

module vmCreation_unmanaged_customvhd '../nestedtemplates/unmanagedDisks-customvhdvm.bicep' = if (vmTemplateUri == 'unmanagedDisks-customvhdvm.bicep') {
  name: 'vmCreation_unmanaged_customvhd-${deploymentId}'
  scope: resourceGroup(vmResourceGroup)
  params: {
    artifactsLocation: artifactsLocation
    availabilityOption: availabilityOption
    availabilitySetName: availabilitySetName
    availabilityZone: availabilityZone
    vmImageVhdUri: vmImageVhdUri
    storageAccountResourceGroupName: storageAccountResourceGroupName
    vmGalleryImageOffer: vmGalleryImageOffer
    vmGalleryImagePublisher: vmGalleryImagePublisher
    vmGalleryImageHasPlan: vmGalleryImageHasPlan
    vmGalleryImageSKU: vmGalleryImageSKU
    vmGalleryImageVersion: vmGalleryImageVersion
    rdshPrefix: rdshPrefix
    rdshNumberOfInstances: vmNumberOfInstances
    rdshVMDiskType: vmDiskType
    rdshVmSize: vmSize
    enableAcceleratedNetworking: false
    vmAdministratorAccountUsername: vmAdministratorAccountUsername
    vmAdministratorAccountPassword: vmAdministratorAccountPassword
    administratorAccountUsername: administratorAccountUsername
    administratorAccountPassword: administratorAccountPassword
    subnet_id: var_subnet_id
    vhds: vhds
    rdshImageSourceId: vmCustomImageSourceId
    location: vmLocation
    createNetworkSecurityGroup: createNetworkSecurityGroup
    networkSecurityGroupId: networkSecurityGroupId
    networkSecurityGroupRules: networkSecurityGroupRules
    networkInterfaceTags: networkInterfaceTags
    networkSecurityGroupTags: networkSecurityGroupTags
    virtualMachineTags: virtualMachineTags
    imageTags: imageTags
    vmInitialNumber: vmInitialNumber
    hostpoolName: hostpoolName
    hostpoolToken: hostpoolToken
    domain: domain
    ouPath: ouPath
    aadJoin: aadJoin
    intune: intune
    bootDiagnostics: bootDiagnostics
    guidValue: deploymentId
    userAssignedIdentity: userAssignedIdentity
    customConfigurationTemplateUrl: customConfigurationTemplateUrl
    customConfigurationParameterUrl: customConfigurationParameterUrl
    SessionHostConfigurationVersion: (contains(systemData, 'hostpoolUpdate') ? systemData.sessionHostConfigurationVersion : '')
  }
}

output rdshVmNamesObject object = rdshVmNamesOutput
