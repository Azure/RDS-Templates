@description('The base URI where artifacts required by this template are located.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/RDS-Templates/master/ARM-wvd-templates/DSC/Configuration.zip'

@description('The name of the Hostpool to be created.')
param hostpoolName string

@description('The friendly name of the Hostpool to be created.')
param hostpoolFriendlyName string = ''

@description('The description of the Hostpool to be created.')
param hostpoolDescription string = ''

@description('The storage uri to put the diagnostic logs')
param hostpoolDiagnosticSettingsStorageAccount string = ''

@description('The description of the Hostpool to be created.')
param hostpoolDiagnosticSettingsLogAnalyticsWorkspaceId string = ''

@description('The event hub name to send logs to')
param hostpoolDiagnosticSettingsEventHubName string = ''

@description('The event hub policy to use')
param hostpoolDiagnosticSettingsEventHubAuthorizationId string = ''

@description('Categories of logs to be created for hostpools')
param hostpoolDiagnosticSettingsLogCategories array = [
  'Checkpoint'
  'Error'
  'Management'
  'Connection'
  'HostRegistration'
  'AgentHealthStatus'
]

@description('Categories of logs to be created for app groups')
param appGroupDiagnosticSettingsLogCategories array = [
  'Checkpoint'
  'Error'
  'Management'
]

@description('Categories of logs to be created for workspaces')
param workspaceDiagnosticSettingsLogCategories array = [
  'Checkpoint'
  'Error'
  'Management'
  'Feed'
]

@description('The location where the resources will be deployed.')
param location string = 'westus2'

@description('The name of the workspace to be attach to new Applicaiton Group.')
param workSpaceName string = ''

@description('The location of the workspace.')
param workspaceLocation string = 'westus2'

@description('The workspace resource group Name.')
param workspaceResourceGroup string = ''

@description('True if the workspace is new. False if there is no workspace added or adding to an existing workspace.')
param isNewWorkspace bool = false

@description('The existing app groups references of the workspace selected.')
param allApplicationGroupReferences string = ''

@description('Whether to add applicationGroup to workspace.')
param addToWorkspace bool = false

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
param vmResourceGroup string = ''

@description('The location of the session host VMs.')
param vmLocation string = 'eastus'

@description('The size of the session host VMs.')
param vmSize string = 'Standard_D2s_v3'

@description('Number of session hosts that will be created and added to the hostpool.')
param vmNumberOfInstances int = 0

@description('This prefix will be used in combination with the VM number to create the VM name. If using \'rdsh\' as the prefix, VMs would be named \'rdsh-0\', \'rdsh-1\', etc. You should use a unique prefix to reduce name collisions in Active Directory.')
param vmNamePrefix string = ''

@description('Select the image source for the session host vms. VMs from a Gallery image will be created with Managed Disks.')
@allowed([
  'CustomVHD'
  'CustomImage'
  'Gallery'
])
param vmImageType string = 'Gallery'
//TODO: Add parameters to override these default values
@description('(Required when vmImageType = Gallery) Gallery image Offer.')
param vmGalleryImageOffer string = 'Windows-10'

@description('(Required when vmImageType = Gallery) Gallery image Publisher.')
param vmGalleryImagePublisher string = 'MicrosoftWindowsDesktop'

@description('Whether the VM has plan or not')
param vmGalleryImageHasPlan bool = false

@description('(Required when vmImageType = Gallery) Gallery image SKU.')
param vmGalleryImageSKU string = '20h2-evd'

@description('(Required when vmImageType = Gallery) Gallery image version.')
param vmGalleryImageVersion string = 'latest'

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
param vmDiskType string = 'StandardSSD_LRS'

@description('True indicating you would like to use managed disks or false indicating you would like to use unmanaged disks.')
param vmUseManagedDisks bool = true

@description('(Required when vmUseManagedDisks = False) The resource group containing the storage account of the image vhd file.')
param storageAccountResourceGroupName string = ''

@description('The name of the virtual network the VMs will be connected to.')
param existingVnetName string = ''

@description('The subnet the VMs will be placed in.')
param existingSubnetName string = ''

@description('The resource group containing the existing virtual network.')
param virtualNetworkResourceGroupName string = ''

@description('Whether to create a new network security group or use an existing one')
param createNetworkSecurityGroup bool = false

@description('The resource id of an existing network security group')
param networkSecurityGroupId string = ''

@description('The rules to be given to the new network security group')
param networkSecurityGroupRules array = []

@description('Set this parameter to Personal if you would like to enable Persistent Desktop experience. Defaults to false.')
@allowed([
  'Personal'
  'Pooled'
])
param hostpoolType string = 'Personal'

@description('Set the type of assignment for a Personal hostpool type')
@allowed([
  'Automatic'
  'Direct'
  ''
])
param personalDesktopAssignmentType string = ''

@description('Maximum number of sessions.')
param maxSessionLimit int = 99999

@description('Type of load balancer algorithm.')
@allowed([
  'BreadthFirst'
  'DepthFirst'
  'Persistent'
])
param loadBalancerType string = 'BreadthFirst'

@description('Hostpool rdp properties')
param customRdpProperty string = ''

@description('The necessary information for adding more VMs to this Hostpool')
param vmTemplate string = ''

@description('A basetime that will be used to calculate tokenExpirationTime')
param baseTime string = utcNow('u')

@description('The tags to be assigned to the hostpool')
param hostpoolTags object = {
}

@description('The tags to be assigned to the application group')
param applicationGroupTags object = {
}

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

@description('Whether to use validation enviroment.')
param validationEnvironment bool = false

@description('Preferred App Group type to display')
param preferredAppGroupType string = 'Desktop'

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

@description('Arm template that contains custom configurations to be run after the Virtual Machines are created.')
param customConfigurationTemplateUrl string = ''

@description('Url to the Arm template parameter file for the customConfigurationTemplateUrl parameter. This input will be used when the template is ran after the VMs have been deployed.')
param customConfigurationParameterUrl string = ''

@description('System data is used for internal purposes, such as support preview features.')
param systemData object = {
}


var tokenExpirationTime = (dateTimeAdd(baseTime, 'P15D'))
var createVMs = (vmNumberOfInstances > 0)
var domain_var = ((domain == '') ? last(split(administratorAccountUsername, '@')) : domain)
var rdshManagedDisks = ((vmImageType == 'CustomVHD') ? vmUseManagedDisks : bool('true'))
var rdshPrefix = '${vmNamePrefix}-'
var avSetSKU = (rdshManagedDisks ? 'Aligned' : 'Classic')
var vhds = 'vhds/${rdshPrefix}'
var var_subnet_id = resourceId(virtualNetworkResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', existingVnetName, existingSubnetName)
var hostpoolName_var = replace(hostpoolName, '"', '')
var vmTemplateName = '${(rdshManagedDisks ? 'managedDisks' : 'unmanagedDisks')}-${toLower(replace(vmImageType, ' ', ''))}vm'
var rdshVmNamesCopyNamesArr = [for item in range(0, (createVMs ? vmNumberOfInstances : 1)): {
  name: '${rdshPrefix}${item}'
}]
var rdshVmNamesOutput = {
  rdshVmNamesCopy: rdshVmNamesCopyNamesArr
}
var appGroupName_var = '${hostpoolName_var}-DAG'
var appGroupResourceId = [
  appGroupName.id
]
var workspaceResourceGroup_var = (empty(workspaceResourceGroup) ? resourceGroup().name : workspaceResourceGroup)
var applicationGroupReferencesArr = (('' == allApplicationGroupReferences) ? appGroupResourceId : concat(split(allApplicationGroupReferences, ','), appGroupResourceId))
var hostpoolRequiredProps = {
  friendlyName: hostpoolFriendlyName
  description: hostpoolDescription
  hostpoolType: hostpoolType
  personalDesktopAssignmentType: personalDesktopAssignmentType
  maxSessionLimit: maxSessionLimit
  loadBalancerType: loadBalancerType
  validationEnvironment: validationEnvironment
  preferredAppGroupType: preferredAppGroupType
  ring: null
  registrationInfo: {
    expirationTime: tokenExpirationTime
    token: null
    registrationTokenOperation: 'Update'
  }
  vmTemplate: vmTemplate
}
var hostpoolOptionalProps = {
  customRdpProperty: customRdpProperty
}
var sessionHostConfigurationImageMarketPlaceInfoProps = {
  publisher: vmGalleryImagePublisher
  offer: vmGalleryImageOffer
  sku: vmGalleryImageSKU
  exactVersion: vmGalleryImageVersion
}
var sendLogsToStorageAccount = (!empty(hostpoolDiagnosticSettingsStorageAccount))
var sendLogsToLogAnalytics = (!empty(hostpoolDiagnosticSettingsLogAnalyticsWorkspaceId))
var sendLogsToEventHub = (!empty(hostpoolDiagnosticSettingsEventHubName))
var storageAccountIdProperty = (sendLogsToStorageAccount ? hostpoolDiagnosticSettingsStorageAccount : null)
var hostpoolDiagnosticSettingsLogProperties = [for item in hostpoolDiagnosticSettingsLogCategories: {
  category: item
  enabled: true
  retentionPolicy: {
    enabled: true
    days: 30
  }
}]
var appGroupDiagnosticSettingsLogProperties = [for item in appGroupDiagnosticSettingsLogCategories: {
  category: item
  enabled: true
  retentionPolicy: {
    enabled: true
    days: 30
  }
}]
var workspaceDiagnosticSettingsLogProperties = [for item in workspaceDiagnosticSettingsLogCategories: {
  category: item
  enabled: true
  retentionPolicy: {
    enabled: true
    days: 30
  }
}]

resource hostpoolName_resource 'Microsoft.DesktopVirtualization/hostpools@2019-12-10-preview' = {
  name: hostpoolName
  location: location
  tags: hostpoolTags
  properties: (empty(customRdpProperty) ? hostpoolRequiredProps : union(hostpoolOptionalProps, hostpoolRequiredProps))
}

resource hostpoolName_default 'Microsoft.DesktopVirtualization/hostpools/sessionHostConfigurations@2019-12-10-preview' = if (createVMs && contains(systemData, 'hostpoolUpdateFeature') && systemData.hostpoolUpdateFeature) {
  name: '${hostpoolName}/default'
  properties: {
    vMSizeId: vmSize
    diskType: vmDiskType
    vmCustomConfigurationUri: (empty(customConfigurationTemplateUrl) ? null : customConfigurationTemplateUrl)
    vmCustomConfigurationParameterUri: (empty(customConfigurationParameterUrl) ? null : customConfigurationParameterUrl)
    imageInfo: {
      type: ((vmImageType == 'CustomVHD') ? 'StorageBlob' : vmImageType)
      marketPlaceInfo: ((vmImageType == 'Gallery') ? sessionHostConfigurationImageMarketPlaceInfoProps : null)
      storageBlobUri: ((vmImageType == 'CustomVHD') ? vmImageVhdUri : null)
      customId: ((vmImageType == 'CustomImage') ? vmCustomImageSourceId : null)
    }
    domainInfo: {
      name: domain_var
      joinType: (aadJoin ? 'AzureActiveDirectory' : 'ActiveDirectory')
      mdmProviderGuid: (intune ? '0000000a-0000-0000-c000-000000000000' : null)
    }
  }
  dependsOn: [
    hostpoolName_resource
  ]
}

resource appGroupName 'Microsoft.DesktopVirtualization/applicationgroups@2019-12-10-preview' = {
  name: appGroupName_var
  location: location
  tags: applicationGroupTags
  properties: {
    hostPoolArmPath: hostpoolName_resource.id
    friendlyName: 'Default Desktop'
    description: 'Desktop Application Group created through the Hostpool Wizard'
    applicationGroupType: 'Desktop'
  }
}

module Workspace_linkedTemplate_deploymentId '../nestedtemplates/nested_Workspace_linkedTemplate_deploymentId.bicep' = if (addToWorkspace) {
  name: 'Workspace-linkedTemplate-${deploymentId}'
  scope: resourceGroup(workspaceResourceGroup_var)
  params: {
    applicationGroupReferencesArr: applicationGroupReferencesArr
    workSpaceName: workSpaceName
    workspaceLocation: workspaceLocation
  }
}

module AVSet_linkedTemplate_deploymentId '../nestedtemplates/nested_AVSet_linkedTemplate_deploymentId.bicep' = if (createVMs && (availabilityOption == 'AvailabilitySet') && createAvailabilitySet) {
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
    appGroupName
  ]
}


module vmCreation_managed_customImagevm '../nestedtemplates/managedDisks-customimagevm.bicep' = if (createVMs && vmTemplateName == 'managedDisks-customimagevm') {
  name: 'vmCreate_man_customImagevm-${deploymentId}'
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
    hostpoolToken: hostpoolName_resource.properties.registrationInfo.token
    hostpoolName: hostpoolName
    domain: domain
    ouPath: ouPath
    aadJoin: aadJoin
    intune: intune
    bootDiagnostics: bootDiagnostics
    guidValue: deploymentId
    userAssignedIdentity: userAssignedIdentity
    customConfigurationTemplateUrl: customConfigurationTemplateUrl
    customConfigurationParameterUrl: customConfigurationParameterUrl
    SessionHostConfigurationVersion: ((createVMs && contains(systemData, 'hostpoolUpdateFeature') && systemData.hostpoolUpdateFeature) ? hostpoolName_default.properties.version : '')
  }
}

module vmCreation_managed_customvhdvm '../nestedtemplates/managedDisks-customvhdvm.bicep' = if (createVMs && vmTemplateName == 'managedDisks-customvhdvm') {
  name: 'vmCreae_man_customvhdvm-${deploymentId}'
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
    hostpoolToken: hostpoolName_resource.properties.registrationInfo.token
    hostpoolName: hostpoolName
    domain: domain
    ouPath: ouPath
    aadJoin: aadJoin
    intune: intune
    bootDiagnostics: bootDiagnostics
    guidValue: deploymentId
    userAssignedIdentity: userAssignedIdentity
    customConfigurationTemplateUrl: customConfigurationTemplateUrl
    customConfigurationParameterUrl: customConfigurationParameterUrl
    SessionHostConfigurationVersion: ((createVMs && contains(systemData, 'hostpoolUpdateFeature') && systemData.hostpoolUpdateFeature) ? hostpoolName_default.properties.version : '')
  }
}

module vmCreation_managed_galleryvm '../nestedtemplates/managedDisks-galleryvm.bicep' = if (createVMs && vmTemplateName == 'managedDisks-galleryvm') {
  name: 'vmCreate_man_galleryvm-${deploymentId}'
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
    hostpoolToken: hostpoolName_resource.properties.registrationInfo.token
    hostpoolName: hostpoolName
    domain: domain
    ouPath: ouPath
    aadJoin: aadJoin
    intune: intune
    bootDiagnostics: bootDiagnostics
    guidValue: deploymentId
    userAssignedIdentity: userAssignedIdentity
    customConfigurationTemplateUrl: customConfigurationTemplateUrl
    customConfigurationParameterUrl: customConfigurationParameterUrl
    SessionHostConfigurationVersion: ((createVMs && contains(systemData, 'hostpoolUpdateFeature') && systemData.hostpoolUpdateFeature) ? hostpoolName_default.properties.version : '')
  }
}

module vmCreation_unmanaged_customvhdvm '../nestedtemplates/unmanagedDisks-customvhdvm.bicep' = if (createVMs && vmTemplateName == 'unmanagedDisks-customvhdvm') {
  name: 'vmCreate_unman_customvhdvm-${deploymentId}'
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
    hostpoolToken: hostpoolName_resource.properties.registrationInfo.token
    hostpoolName: hostpoolName
    domain: domain
    ouPath: ouPath
    aadJoin: aadJoin
    intune: intune
    bootDiagnostics: bootDiagnostics
    guidValue: deploymentId
    userAssignedIdentity: userAssignedIdentity
    customConfigurationTemplateUrl: customConfigurationTemplateUrl
    customConfigurationParameterUrl: customConfigurationParameterUrl
    SessionHostConfigurationVersion: ((createVMs && contains(systemData, 'hostpoolUpdateFeature') && systemData.hostpoolUpdateFeature) ? hostpoolName_default.properties.version : '')
  }
}

resource hostpoolName_Microsoft_Insights_diagnosticSetting 'Microsoft.DesktopVirtualization/hostpools/providers/diagnosticSettings@2017-05-01-preview' = if (sendLogsToEventHub || sendLogsToLogAnalytics || sendLogsToStorageAccount) {
  location: location
  name: '${hostpoolName}/Microsoft.Insights/diagnosticSetting'
  properties: {
    storageAccountId: (sendLogsToStorageAccount ? storageAccountIdProperty : null)
    eventHubAuthorizationRuleId: (sendLogsToEventHub ? hostpoolDiagnosticSettingsEventHubAuthorizationId : null)
    eventHubName: (sendLogsToEventHub ? hostpoolDiagnosticSettingsEventHubName : null)
    workspaceId: (sendLogsToLogAnalytics ? hostpoolDiagnosticSettingsLogAnalyticsWorkspaceId : null)
    logs: hostpoolDiagnosticSettingsLogProperties
  }
  dependsOn: [
    hostpoolName_resource
  ]
}

resource appGroupName_Microsoft_Insights_diagnosticSetting 'Microsoft.DesktopVirtualization/applicationgroups/providers/diagnosticSettings@2017-05-01-preview' = if (sendLogsToEventHub || sendLogsToLogAnalytics || sendLogsToStorageAccount) {
  location: location
  name: '${appGroupName_var}/Microsoft.Insights/diagnosticSetting'
  properties: {
    storageAccountId: (sendLogsToStorageAccount ? storageAccountIdProperty : null)
    eventHubAuthorizationRuleId: (sendLogsToEventHub ? hostpoolDiagnosticSettingsEventHubAuthorizationId : null)
    eventHubName: (sendLogsToEventHub ? hostpoolDiagnosticSettingsEventHubName : null)
    workspaceId: (sendLogsToLogAnalytics ? hostpoolDiagnosticSettingsLogAnalyticsWorkspaceId : null)
    logs: appGroupDiagnosticSettingsLogProperties
  }
  dependsOn: [
    appGroupName
  ]
}

resource isNewWorkspace_workSpaceName_placeholder_Microsoft_Insights_diagnosticSetting 'Microsoft.DesktopVirtualization/workspaces/providers/diagnosticSettings@2017-05-01-preview' = if (isNewWorkspace && (sendLogsToEventHub || sendLogsToLogAnalytics || sendLogsToStorageAccount)) {
  location: location
  name: '${(isNewWorkspace ? workSpaceName : 'placeholder')}/Microsoft.Insights/diagnosticSetting'
  properties: {
    storageAccountId: (sendLogsToStorageAccount ? storageAccountIdProperty : null)
    eventHubAuthorizationRuleId: (sendLogsToEventHub ? hostpoolDiagnosticSettingsEventHubAuthorizationId : null)
    eventHubName: (sendLogsToEventHub ? hostpoolDiagnosticSettingsEventHubName : null)
    workspaceId: (sendLogsToLogAnalytics ? hostpoolDiagnosticSettingsLogAnalyticsWorkspaceId : null)
    logs: workspaceDiagnosticSettingsLogProperties
  }
  dependsOn: [
    Workspace_linkedTemplate_deploymentId
  ]
}

output rdshVmNamesObject object = rdshVmNamesOutput
output vmPath string = vmTemplateName
output create bool = createVMs
