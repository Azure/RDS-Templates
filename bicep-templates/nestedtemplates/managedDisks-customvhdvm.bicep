@description('The base URI where artifacts required by this template are located.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/RDS-Templates/master/ARM-wvd-templates/DSC/Configuration.zip'

@description('The availability option for the VMs.')
@allowed([
  'None'
  'AvailabilitySet'
  'AvailabilityZone'
])
param availabilityOption string = 'None'

@description('The name of avaiability set to be used when create the VMs.')
param availabilitySetName string = ''

@description('The number of availability zone to be used when create the VMs.')
@allowed([
  1
  2
  3
])
param availabilityZone int = 1

@description('URI of the sysprepped image vhd file to be used to create the session host VMs. For example, https://rdsstorage.blob.core.windows.net/vhds/sessionhostimage.vhd')
param vmImageVhdUri string

@description('The storage account containing the custom VHD.')
param storageAccountResourceGroupName string

@description('(Required when vmImageType = Gallery) Gallery image Offer.')
param vmGalleryImageOffer string = ''

@description('(Required when vmImageType = Gallery) Gallery image Publisher.')
param vmGalleryImagePublisher string = ''

@description('Whether the VM image has a plan or not')
param vmGalleryImageHasPlan bool = false

@description('(Required when vmImageType = Gallery) Gallery image SKU.')
param vmGalleryImageSKU string = ''

@description('(Required when vmImageType = Gallery) Gallery image version.')
param vmGalleryImageVersion string = ''

@description('This prefix will be used in combination with the VM number to create the VM name. This value includes the dash, so if using “rdsh” as the prefix, VMs would be named “rdsh-0”, “rdsh-1”, etc. You should use a unique prefix to reduce name collisions in Active Directory.')
param rdshPrefix string = take(toLower(resourceGroup().name), 10)

@description('Number of session hosts that will be created and added to the hostpool.')
param rdshNumberOfInstances int

@description('The VM disk type for the VM: HDD or SSD.')
@allowed([
  'Premium_LRS'
  'StandardSSD_LRS'
  'Standard_LRS'
])
param rdshVMDiskType string

@description('The size of the session host VMs.')
param rdshVmSize string = 'Standard_A2'

@description('Enables Accelerated Networking feature, notice that VM size must support it, this is supported in most of general purpose and compute-optimized instances with 2 or more vCPUs, on instances that supports hyperthreading it is required minimum of 4 vCPUs.')
param enableAcceleratedNetworking bool = false

@description('The username for the domain admin.')
param administratorAccountUsername string

@description('The password that corresponds to the existing domain username.')
@secure()
param administratorAccountPassword string

@description('A username to be used as the virtual machine administrator account. The vmAdministratorAccountUsername and  vmAdministratorAccountPassword parameters must both be provided. Otherwise, domain administrator credentials provided by administratorAccountUsername and administratorAccountPassword will be used.')
param vmAdministratorAccountUsername string = ''

@description('The password associated with the virtual machine administrator account. The vmAdministratorAccountUsername and  vmAdministratorAccountPassword parameters must both be provided. Otherwise, domain administrator credentials provided by administratorAccountUsername and administratorAccountPassword will be used.')
@secure()
param vmAdministratorAccountPassword string = ''

@description('The URL to store unmanaged disks.')
param vhds string

@description('The unique id of the subnet for the nics.')
param subnet_id string

@description('Resource ID of the image.')
param rdshImageSourceId string = ''

@description('Location for all resources to be created in.')
param location string = ''

@description('Whether to create a new network security group or use an existing one')
param createNetworkSecurityGroup bool = false

@description('The resource id of an existing network security group')
param networkSecurityGroupId string = ''

@description('The rules to be given to the new network security group')
param networkSecurityGroupRules array = []

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

@description('VM name prefix initial number.')
param vmInitialNumber int = 0
param guidValue string = newGuid()

@description('The token for adding VMs to the hostpool')
param hostpoolToken string

@description('The name of the hostpool')
param hostpoolName string

@description('OUPath for the domain join')
param ouPath string = ''

@description('Domain to join')
param domain string = ''

@description('True if AAD Join, false if AD join')
param aadJoin bool = false

@description('True if intune enrollment is selected.  False otherwise')
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

@description('Session host configuration version of the host pool.')
param SessionHostConfigurationVersion string = ''

var emptyArray = []
var domain_var = ((domain == '') ? last(split(administratorAccountUsername, '@')) : domain)
var storageAccountType = rdshVMDiskType
var imageName_var = '${rdshPrefix}image'
var newNsgName = '${rdshPrefix}nsg-${guidValue}'
var newNsgDeploymentName_var = 'NSG-linkedTemplate-${guidValue}'
var nsgId = (createNetworkSecurityGroup ? resourceId('Microsoft.Network/networkSecurityGroups', newNsgName) : networkSecurityGroupId)
var isVMAdminAccountCredentialsProvided = ((vmAdministratorAccountUsername != '') && (vmAdministratorAccountPassword != ''))
var vmAdministratorUsername = (isVMAdminAccountCredentialsProvided ? vmAdministratorAccountUsername : first(split(administratorAccountUsername, '@')))
var vmAdministratorPassword = (isVMAdminAccountCredentialsProvided ? vmAdministratorAccountPassword : administratorAccountPassword)
var vmAvailabilitySetResourceId = {
  id: resourceId('Microsoft.Compute/availabilitySets/', availabilitySetName)
}
var planInfoEmpty = (empty(vmGalleryImageSKU) || empty(vmGalleryImagePublisher) || empty(vmGalleryImageOffer))
var marketplacePlan = {
  name: vmGalleryImageSKU
  publisher: vmGalleryImagePublisher
  product: vmGalleryImageOffer
}
var vmPlan = ((planInfoEmpty || (!vmGalleryImageHasPlan)) ? json('null') : marketplacePlan)
var vmIdentityType = (aadJoin ? ((!empty(userAssignedIdentity)) ? 'SystemAssigned, UserAssigned' : 'SystemAssigned') : ((!empty(userAssignedIdentity)) ? 'UserAssigned' : 'None'))
var vmIdentityTypeProperty = {
  type: vmIdentityType
}
var vmUserAssignedIdentityProperty = {
  userAssignedIdentities: {
    '${resourceId('Microsoft.ManagedIdentity/userAssignedIdentities/', userAssignedIdentity)}': {
    }
  }
}
var vmIdentity = ((!empty(userAssignedIdentity)) ? union(vmIdentityTypeProperty, vmUserAssignedIdentityProperty) : vmIdentityTypeProperty)
var postDeploymentCustomConfigurationTemplateProperty = {
  mode: 'Incremental'
  templateLink: {
    uri: customConfigurationTemplateUrl
    contentVersion: '1.0.0.0'
  }
}
var postDeploymentCustomConfigurationParameterProperty = {
  parametersLink: {
    uri: customConfigurationParameterUrl
  }
}
var customConfigurationParameter = (empty(customConfigurationParameterUrl) ? postDeploymentCustomConfigurationTemplateProperty : union(postDeploymentCustomConfigurationTemplateProperty, postDeploymentCustomConfigurationParameterProperty))

resource imageName 'Microsoft.Compute/images@2018-10-01' = {
  name: imageName_var
  location: location
  tags: imageTags
  properties: {
    storageProfile: {
      osDisk: {
        osType: 'Windows'
        osState: 'Generalized'
        blobUri: vmImageVhdUri
        storageAccountType: storageAccountType
      }
    }
  }
}

module newNsgDeploymentName './nested_newNsgDeploymentName.bicep' = {
  name: newNsgDeploymentName_var
  params: {
    variables_newNsgName: newNsgName
    createNetworkSecurityGroup: createNetworkSecurityGroup
    location: location
    networkSecurityGroupTags: networkSecurityGroupTags
    networkSecurityGroupRules: networkSecurityGroupRules
  }
}

resource rdshPrefix_vmInitialNumber_nic 'Microsoft.Network/networkInterfaces@2018-11-01' = [for i in range(0, rdshNumberOfInstances): {
  name: '${rdshPrefix}${(i + vmInitialNumber)}-nic'
  location: location
  tags: networkInterfaceTags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet_id
          }
        }
      }
    ]
    enableAcceleratedNetworking: enableAcceleratedNetworking
    networkSecurityGroup: (empty(networkSecurityGroupId) ? json('null') : json('{"id": "${nsgId}"}'))
  }
  dependsOn: [
    newNsgDeploymentName
  ]
}]

resource rdshPrefix_vmInitialNumber 'Microsoft.Compute/virtualMachines@2020-06-01' = [for i in range(0, rdshNumberOfInstances): {
  name: concat(rdshPrefix, (i + vmInitialNumber))
  location: location
  tags: virtualMachineTags
  plan: vmPlan
  identity: vmIdentity
  properties: {
    hardwareProfile: {
      vmSize: rdshVmSize
    }
    availabilitySet: ((availabilityOption == 'AvailabilitySet') ? vmAvailabilitySetResourceId : json('null'))
    osProfile: {
      computerName: concat(rdshPrefix, (i + vmInitialNumber))
      adminUsername: vmAdministratorUsername
      adminPassword: vmAdministratorPassword
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: storageAccountType
        }
      }
      imageReference: {
        id: imageName.id
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${rdshPrefix}${(i + vmInitialNumber)}-nic')
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: bootDiagnostics
    }
    licenseType: 'Windows_Client'
  }
  zones: ((availabilityOption == 'AvailabilityZone') ? array(availabilityZone) : emptyArray)
}]

resource rdshPrefix_vmInitialNumber_Microsoft_PowerShell_DSC 'Microsoft.Compute/virtualMachines/extensions@2018-10-01' = [for i in range(0, rdshNumberOfInstances): {
  name: '${rdshPrefix}${(i + vmInitialNumber)}/Microsoft.PowerShell.DSC'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.73'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: artifactsLocation
      configurationFunction: 'Configuration.ps1\\AddSessionHost'
      properties: {
        hostPoolName: hostpoolName
        registrationInfoToken: hostpoolToken
        aadJoin: aadJoin
        sessionHostConfigurationLastUpdateTime: SessionHostConfigurationVersion
      }
    }
  }
  dependsOn: [
    rdshPrefix_vmInitialNumber
  ]
}]

resource rdshPrefix_vmInitialNumber_AADLoginForWindows 'Microsoft.Compute/virtualMachines/extensions@2018-10-01' = [for i in range(0, rdshNumberOfInstances): if (aadJoin) {
  name: '${rdshPrefix}${(i + vmInitialNumber)}/AADLoginForWindows'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: (intune ? {
      mdmId: '0000000a-0000-0000-c000-000000000000'
    } : json('null'))
  }
  dependsOn: [
    rdshPrefix_vmInitialNumber_Microsoft_PowerShell_DSC
  ]
}]

resource rdshPrefix_vmInitialNumber_joindomain 'Microsoft.Compute/virtualMachines/extensions@2018-10-01' = [for i in range(0, rdshNumberOfInstances): if (!aadJoin) {
  name: '${rdshPrefix}${(i + vmInitialNumber)}/joindomain'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      name: domain_var
      ouPath: ouPath
      user: administratorAccountUsername
      restart: 'true'
      options: '3'
    }
    protectedSettings: {
      password: administratorAccountPassword
    }
  }
  dependsOn: [
    rdshPrefix_vmInitialNumber_Microsoft_PowerShell_DSC
  ]
}]

/*module post_deployment_custom_configuration '?' /*TODO: replace with correct path to What should this be = if (!empty(customConfigurationTemplateUrl)) {
  name: 'post-deployment-custom-configuration'
  params: {
  }
  dependsOn: [
    rdshPrefix_vmInitialNumber_Microsoft_PowerShell_DSC
    rdshPrefix_vmInitialNumber_AADLoginForWindows
    rdshPrefix_vmInitialNumber_joindomain
  ]
}*/
