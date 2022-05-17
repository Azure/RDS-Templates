param variables_applicationGroupReferencesArr ? /* TODO: fill in correct type */

@description('WVD api version')
param apiVersion string

@description('The name of the workspace to be attach to new Applicaiton Group.')
param workSpaceName string

@description('The location of the workspace.')
param workspaceLocation string

resource workSpaceName_resource 'Microsoft.DesktopVirtualization/workspaces@[parameters(\'apiVersion\')]' = {
  name: workSpaceName
  location: workspaceLocation
  properties: {
    applicationGroupReferences: variables_applicationGroupReferencesArr
  }
}