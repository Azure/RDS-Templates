### This list of PowerShell commands will set up a User assigned managed identity, a role definition and associate the required permissions. It also creates an Azure Compute gallery and a VM image definition. This allows you to then use AVD custom image templates to create an image version within that image definition from where you can create an AVD host pool.
### Tom Hickling Senior Product Manager Microsoft - 18 October 2022

## First check resource providers.
# Check to ensure that you're registered for the providers and RegistrationState is set to 'Registered'
Get-AzResourceProvider -ProviderNamespace Microsoft.VirtualMachineImages
Get-AzResourceProvider -ProviderNamespace Microsoft.Storage 
Get-AzResourceProvider -ProviderNamespace Microsoft.Compute
Get-AzResourceProvider -ProviderNamespace Microsoft.KeyVault

# If they don't show as 'Registered', run the following commented-out code

## Register-AzResourceProvider -ProviderNamespace Microsoft.VirtualMachineImages
## Register-AzResourceProvider -ProviderNamespace Microsoft.Storage
## Register-AzResourceProvider -ProviderNamespace Microsoft.Compute
## Register-AzResourceProvider -ProviderNamespace Microsoft.KeyVault 


## Now define your variables and create a resource group
# Import module
Import-Module Az.Accounts

# Get your Azure Subscription ID
$subscriptionID = (Get-AzContext).Subscription.Id
Write-Output $subscriptionID

# Specify the destination image resource group used for Custom Image Templates
$imageResourceGroup = 'AVDCustomImageTemplate'

# Location (see possible locations in the main Azure docs, or run get-azlocation)
$location = 'northeurope'

#Create the Resource Group
New-AzResourceGroup -Name $imageResourceGroup -Location $location


## Create a user assigned managed identity
# Add Azure PowerShell modules to support AzUserAssignedIdentity and Azure VM Image Builder
'Az.ImageBuilder', 'Az.ManagedServiceIdentity' | ForEach-Object {Install-Module -Name $_ -AllowPrerelease}

# Setup managed identity and role definition (used later) names, these need to be unique in your subscription. 
$CITidentityName = "DesktopVirtualizationCustomImageTemplateIdentity"
$CITRoleDefName = "Desktop Virtualization Custom Image Template Role"

# Create the managed identity. This creates an AAD Enterprise application, the PrincipalID is the AAD Object ID.
New-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $CITidentityName

# Store the identity resource and principal IDs in variables.
$identityNameResourceId = (Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $CITidentityName).Id
$identityNamePrincipalId = (Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $CITidentityName).PrincipalId 


## Assign permissions for the identity to distribute the images
# Specify the CIT JSON with the required permissions
$CITRoleImageCreationUrl = 'https://raw.githubusercontent.com/Azure/RDS-Templates/master/Custom-Image-Templates/CITRoleImageCreation.json'
$CITRoleImageCreationPath = "CITRoleImageCreation.json"

# Download the JSON locally
Invoke-WebRequest -Uri $CITRoleImageCreationUrl -OutFile $CITRoleImageCreationPath -UseBasicParsing

# Replace the default settings with your own specific subscription, Resource Group and Custom role you just created
$Content = Get-Content -Path $CITRoleImageCreationPath -Raw
$Content = $Content -replace '<subscriptionID>', $subscriptionID
$Content = $Content -replace '<rgName>', $imageResourceGroup
$Content | Out-File -FilePath $CITRoleImageCreationPath -Force

# Create the new role definition
New-AzRoleDefinition -InputFile $CITRoleImageCreationPath

# Grant the role definition to the VM Image Builder service principal
$RoleAssignParams = @{
  ObjectId = $identityNamePrincipalId
  RoleDefinitionName = $CITRoleDefName
  Scope = "/subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup"
}
New-AzRoleAssignment @RoleAssignParams


## Create an Azure Compute Gallery, start with defining the names you want
$myGalleryName = 'CITImageGallery'
$imageDefName = 'AVDWin10ImageDefinitionGen'

New-AzGallery -GalleryName $myGalleryName -ResourceGroupName $imageResourceGroup -Location $location

# Create the gallery definition. *Note, HyperVGeneration is to specify the required generation for the VM image defintion.
$GalleryParams = @{
  GalleryName = $myGalleryName
  ResourceGroupName = $imageResourceGroup
  Location = $location
  Name = $imageDefName
  HyperVGeneration = 'V2'
  OsState = 'generalized'
  OsType = 'Windows'
  Publisher = 'myCo'
  Offer = 'Windows'
  Sku = 'Win10'
}
New-AzGalleryImageDefinition @GalleryParams




