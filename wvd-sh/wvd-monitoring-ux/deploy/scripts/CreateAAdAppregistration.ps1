Param(
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string] $subscriptionid,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string] $Username,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string] $Password,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string] $WebApp,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string] $redirectURL
)

#Initialize
$ErrorActionPreference = "Stop"
$VerbosePreference = "SilentlyContinue"
$homePage = "$redirectURL"
$identifierUri = $homePage
$spnRole = "contributor"

$securedPassword = ConvertTo-SecureString $Password -AsPlainText -Force
#Create a Credentials Object
$credentials = New-Object System.Management.Automation.PSCredential ($Username, $securedPassword)
# Authenticate to Azure

Login-AzureRmAccount -SubscriptionId $subscriptionId -Credential $credentials
$azureSubscription = Get-AzureRmSubscription -SubscriptionId $subscriptionId
$connectionName = $azureSubscription.SubscriptionName

#Check if AD Application Identifier URI is unique
Write-Output "Verifying App URI is unique ($identifierUri)" -Verbose
$existingApplication = Get-AzureRmADApplication -IdentifierUri $identifierUri
if ($existingApplication -ne $null) {
    $appId = $existingApplication.ApplicationId
    Write-Output "An AAD Application already exists with App URI $identifierUri Application Id: $appId . Choose a different app display name"  -Verbose
    return
}

$startDate = Get-Date
$endDate = $startDate.AddYears($script:yearsOfExpiration)
#$aadAppKeyPwd = New-AzureADApplicationPasswordCredential -ObjectId $existingApplication.ObjectId -CustomKeyIdentifier "Primary" -StartDate $startDate -EndDate $endDate
$Guid = New-Guid
$PasswordCredential = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordCredential
$PasswordCredential.StartDate = $startDate
$PasswordCredential.EndDate = $startDate.AddYears(1)
$PasswordCredential.KeyId = $Guid
$PasswordCredential.Value = ([System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(($Guid))))+"="
$appPassword=$PasswordCredential.Value

#Create a new AD Application
Write-Output "Creating a new Application in AAD (App URI - $identifierUri)" -Verbose
$secureAppPassword = $appPassword | ConvertTo-SecureString -AsPlainText -Force
#$azureAdApplication = New-AzureRmADApplication -DisplayName $WebApp -HomePage $homePage -IdentifierUris $identifierUri -Password $secureAppPassword -Verbose
$azureAdApplication=New-AzureADApplication -DisplayName $WebApp -ReplyUrls $redirectURL -PublicClient $true -AvailableToOtherTenants $false -Verbose -ErrorAction Stop
$appId = $azureAdApplication.ApplicationId
Write-Output "Azure AAD Application creation completed successfully...Application Id: $appId" -Verbose

#Create new SPN
Write-Output "Creating a new SPN" -Verbose
$spn = New-AzureRmADServicePrincipal -ApplicationId $appId
$spnName = $spn.ServicePrincipalNames
Write-Output "SPN creation completed successfully (SPN Name: $spnName)" -Verbose

#Assign role to SPN
Write-Output "Waiting for Service Principal creation to reflect in Directory before Role assignment"
Start-Sleep 20
Write-Output "Assigning role $spnRole to SPN App $appId" -Verbose
New-AzureRmRoleAssignment -RoleDefinitionName $spnRole -ServicePrincipalName $appId
Write-Output "SPN role assignment completed successfully" -Verbose

#Print the values
Write-Output "`nCopy and Paste below values for Service Connection" -Verbose
Write-Output "Service Principal Id: $appId"
Write-Output "Service Principal Key: $appPassword"
