Param
(
    [Parameter(Mandatory=$True)]
    [String] $AutomationResourceGroup,

    [Parameter(Mandatory=$True)]
    [String] $AutomationAccount,

    [Parameter(Mandatory=$False)]
    [object] $ModuleVersionOverrides,

    [Parameter(Mandatory=$False)]
    [String] $AzureEnvironment = 'AzureCloud'
    )

$versionOverrides = ""
# Try to parse module version overrides
if ($ModuleVersionOverrides) {
    if ($ModuleVersionOverrides.GetType() -eq [HashTable]) {
        $versionOverrides = ConvertTo-Json $ModuleVersionOverrides
    } elseif ($ModuleVersionOverrides.GetType() -eq [String]) {
        # Verify that the ModuleVersionOverrides can be deserialized
        try{
            $temp = ConvertFrom-Json $ModuleVersionOverrides -ErrorAction Stop
        }
        catch [System.ArgumentException] {
            $ex = $_ 
            # rethrow intended
            throw "The value of the parameter ModuleVersionOverrides is not a valid JSON string: ", $ex
        }
        $versionOverrides = $ModuleVersionOverrides
    } else {
        $ex = [System.ArgumentException]::new("The value of the parameter ModuleVersionOverrides should be a PowerShell HashTable or a JSON string")
        throw $ex
    }
}

try
{
    # Pull Azure environment settings
    $AzureEnvironmentSettings = Get-AzureRmEnvironment -Name $AzureEnvironment

    # Azure management uri
    $ResourceAppIdURI = $AzureEnvironmentSettings.ActiveDirectoryServiceEndpointResourceId

    # Path to modules in automation container
    $ModulePath = "C:\Modules"

    # Login uri for Azure AD
    $LoginURI = $AzureEnvironmentSettings.ActiveDirectoryAuthority

    # Find AzureRM.Profile module and load the Azure AD client library
    $PathToProfileModule = Get-ChildItem (Join-Path $ModulePath AzureRM.Profile) -Recurse
    Add-Type -Path (Join-Path $PathToProfileModule "Microsoft.IdentityModel.Clients.ActiveDirectory.dll")

    # Get RunAsConnection
    $RunAsConnection = Get-AutomationConnection -Name "AzureRunAsConnection"
    $Certifcate = Get-AutomationCertificate -Name "AzureRunAsCertificate"
    $SubscriptionId = $RunAsConnection.SubscriptionId


    # Set up authentication using service principal client certificate
    $Authority = $LoginURI + $RunAsConnection.TenantId
    $AuthContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $Authority
    $ClientCertificate = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate" -ArgumentList $RunAsConnection.ApplicationId, $Certifcate
    $AuthResult = $AuthContext.AcquireToken($ResourceAppIdURI, $ClientCertificate)

    # Set up header with authorization token
    $AuthToken = $AuthResult.CreateAuthorizationHeader()
    $RequestHeader = @{
      "Content-Type" = "application/json";
      "Authorization" = "$AuthToken"
    }
 
    # Create a runbook job
    $JobId = [GUID]::NewGuid().ToString()
    $URI =  "$($AzureEnvironmentSettings.ResourceManagerUrl)subscriptions/$SubscriptionId/"`
         +"resourceGroups/$($AutomationResourceGroup)/providers/Microsoft.Automation/"`
         +"automationAccounts/$AutomationAccount/jobs/$($JobId)?api-version=2015-10-31"
 
    # Runbook and parameters
    if($versionOverrides){
        $Body = @"
            {
               "properties":{
               "runbook":{
                   "name":"Update-AutomationAzureModulesForAccount"
               },
               "parameters":{
                    "AzureEnvironment":"$AzureEnvironment",
                    "ResourceGroupName":"$AutomationResourceGroup",
                    "AutomationAccountName":"$AutomationAccount",
                    "ModuleVersionOverrides":"$versionOverrides"
               }
              }
           }
"@
    } else {
        $Body = @"
            {
               "properties":{
               "runbook":{
                   "name":"Update-AutomationAzureModulesForAccount"
               },
               "parameters":{
                    "AzureEnvironment":"$AzureEnvironment",
                    "ResourceGroupName":"$AutomationResourceGroup",
                    "AutomationAccountName":"$AutomationAccount"
               }
              }
           }
"@
    }

    # Start runbook job
    Invoke-RestMethod -Uri $URI -Method Put -body $body -Headers $requestHeader        

}
catch 
{
        throw $_.Exception
} 
