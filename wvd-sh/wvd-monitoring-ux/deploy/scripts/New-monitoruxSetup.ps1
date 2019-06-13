
$subscriptionid = Get-AutomationVariable -Name 'subscriptionid'
$ResourceGroupName = Get-AutomationVariable -Name 'ResourceGroupName'
$fileURI = Get-AutomationVariable -Name 'fileURI'
$Username = Get-AutomationVariable -Name 'Username'
$Password = Get-AutomationVariable -Name 'Password'
$automationAccountName = Get-AutomationVariable -Name 'accountName'
$WebApp = Get-AutomationVariable -Name 'webApp'
$WorkspaceID = Get-AutomationVariable -Name 'WorkspaceID'

Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope Process -Force -Confirm:$false
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine -Force -Confirm:$false
Get-ExecutionPolicy -List

Invoke-WebRequest -Uri $fileURI -OutFile "C:\wvd-monitoring-ux.zip"
$modules=$fileuri.Replace('wvd-monitoring-ux.zip','AzureModules.zip')
Invoke-WebRequest -Uri $modules -OutFile "C:\AzureModules.zip"
New-Item -Path "C:\AzureModules" -ItemType directory -Force -ErrorAction SilentlyContinue
Expand-Archive "C:\AzureModules.zip" -DestinationPath "C:\Modules\Global" -ErrorAction SilentlyContinue

#Importing Azure Modules
Import-Module AzureRM.Resources
Import-Module AzureRM.Profile
Import-Module AzureRM.Websites
Import-Module Azure
Import-Module AzureRM.Automation
Import-Module AzureAD
   
#The name of the Automation Credential Asset this runbook will use to authenticate to Azure.
$CredentialAssetName = 'DefaultAzureCredential'

#Get the credential with the above name from the Automation Asset store
$Cred = Get-AutomationPSCredential -Name $CredentialAssetName

#Authenticate to Azure and select the subscriptionId
Add-AzureRmAccount -Environment 'AzureCloud' -Credential $Cred
Select-AzureRmSubscription -SubscriptionId $subscriptionid

Write-Output "Getting the Publishing profile information from Web-App"
$WebAppXML = (Get-AzureRmWebAppPublishingProfile -Name $WebApp `
-ResourceGroupName $ResourceGroupName  `
-OutputFile null)
$WebAppXML = [xml]$WebAppXML

# Extract connection information from publishing profile

Write-Output "Gathering the username, password and publishurl from the Web-App Publishing Profile"
$WebAppUserName = $WebAppXML.SelectNodes("//publishProfile[@publishMethod=`"MSDeploy`"]/@userName").value
$WebAppPassword = $WebAppXML.SelectNodes("//publishProfile[@publishMethod=`"MSDeploy`"]/@userPWD").value
$WebAppURL = $WebAppXML.SelectNodes("//publishProfile[@publishMethod=`"MSDeploy`"]/@publishUrl").value

# Publish Web-App Package files recursively
Write-Output "Uploading zip file to web-App"
test-path -path 'C:\wvd-monitoring-ux.zip'
$filePath = 'C:\wvd-monitoring-ux.zip'
$apiURL = "https://$WebAppURL/api/zipdeploy"
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $WebAppUserName, $WebAppPassword)))
$userAgent = "powershell/1.0"
Invoke-RestMethod -Uri $apiURL -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -UserAgent $userAgent -Method POST -InFile $filePath -ContentType "multipart/form-data"

# Adding Application Settings to WebApp
Write-Output "Adding App settings to Web-App"
$WebAppSettings = @{"AzureAd:ClientId" = "$ClientId"
"AzureAd:ClientSecret" = "$ClientSecret"
"AzureAd:WorkspaceID" = "$WorkspaceID"
}
Set-AzureRmWebApp -AppSettings $WebAppSettings -Name $WebApp -ResourceGroupName $ResourceGroupName

# Get Url of Web-App
$GetWebApp = Get-AzureRmWebApp -Name $WebApp -ResourceGroupName $ResourceGroupName
$WebURL = $GetWebApp.DefaultHostName

$redirectURL="https://"+"$WebURL"

Connect-AzureAD -AzureEnvironmentName AzureCloud -Credential $Credential

# Create a new App registration with service principal
$createappregistrationURI=$fileuri.Replace('wvd-monitoring-ux.zip','CreateAAdAppregistration.ps1')
Invoke-WebRequest -Uri $createappregistrationURI -OutFile "C:\CreateAAdAppregistration.ps1"
Set-Location "C:\"
.\testappreg1106.ps1 -subscriptionid $subscriptionid -Username $Username -Password $Password -WebApp $WebApp -redirectURL $redirectURL
$appreg=Get-AzureADApplication -SearchString $WebApp

$ClientId=$appreg.AppId

# Adding App Settings to WebApp
Write-Output "Adding App settings to Web-App"
$WebAppSettings = @{
    "AzureAd:ClientID"="$ClientId"
    "AzureAd:WorkspaceID" = "$WorkspaceID"
}
Set-AzureRmWebApp -AppSettings $WebAppSettings -Name $WebApp -ResourceGroupName $ResourceGroupName

$newReplyUrl = "$redirectURL/security/signin-callback"
# Get Azure AD App
$app = Get-AzureADApplication -Filter "AppId eq '$($ClientId)'"

$replyUrls = $app.ReplyUrls

# Add Reply URL if not already in the list 

if ($replyUrls -NotContains $newReplyUrl) {
    $replyUrls.Add($newReplyUrl)
    Set-AzureADApplication -ObjectId $app.ObjectId -ReplyUrls $replyUrls -PublicClient $true -AvailableToOtherTenants $false -Verbose -ErrorAction Stop
}
#set windows virtual desktop API permission to Client App Registration
$resourceAppId = Get-AzureADServicePrincipal -SearchString "Windows Virtual Desktop" | Where-Object {$_.DisplayName -eq "Windows Virtual Desktop"}
$AzureWVDApiAccess = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
$AzureWVDApiAccess.ResourceAppId = $resourceAppId.AppId
foreach($permission in $resourceAppId.Oauth2Permissions){
    $AzureWVDApiAccess.ResourceAccess += New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList $permission.Id,"Scope"
}
#set Log Analytics API permission to Client App Registration
$AzureLogAnalyticsApiPrincipal = Get-AzureADServicePrincipal -SearchString "Log Analytics API"
$AzureLogAnalyticsApiAccess = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
$AzureLogAnalyticsApiAccess.ResourceAppId = $AzureLogAnalyticsApiPrincipal.AppId
foreach($permission in $AzureLogAnalyticsApiPrincipal.Oauth2Permissions){
    $AzureLogAnalyticsApiAccess.ResourceAccess += New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList $permission.Id,"Scope"
}
Set-AzureADApplication -ObjectId $app.ObjectId -RequiredResourceAccess $AzureLogAnalyticsApiAccess,$AzureWVDApiAccess -ErrorAction Stop

New-PSDrive -Name RemoveAccount -PSProvider FileSystem -Root "C:\" | Out-Null
@"
Param(
    [Parameter(Mandatory=`$True)]
    [string] `$SubscriptionId,
    [Parameter(Mandatory=`$True)]
    [String] `$Username,
    [Parameter(Mandatory=`$True)]
    [string] `$Password,
    [Parameter(Mandatory=`$True)]
    [string] `$ResourceGroupName,
    [Parameter(Mandatory=`$True)]
    [string] `$automationAccountName
 
)
Import-Module AzureRM.profile
Import-Module AzureRM.Automation
`$Securepass=ConvertTo-SecureString -String `$Password -AsPlainText -Force
`$Azurecred=New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList(`$Username, `$Securepass)
`$login=Login-AzureRmAccount -Credential `$Azurecred -SubscriptionId `$SubscriptionId
Remove-AzureRmAutomationAccount -Name `$automationAccountName -ResourceGroupName `$ResourceGroupName -Force 
"@| Out-File -FilePath RemoveAccount:\RemoveAccount.ps1 -Force

    $runbookName='removemonitoruxacctbook'
    #Create a Run Book
    New-AzureRmAutomationRunbook -Name $runbookName -Type PowerShell -ResourceGroupName $ResourceGroupName -AutomationAccountName $automationAccountName

    #Import modules to Automation Account
    $modules="AzureRM.profile,Azurerm.compute,azurerm.resources"
    $modulenames=$modules.Split(",")
    foreach($modulename in $modulenames){
    Set-AzureRmAutomationModule -Name $modulename -AutomationAccountName $automationAccountName -ResourceGroupName $ResourcegroupName
    }

    #Importe powershell file to Runbooks
    Import-AzureRmAutomationRunbook -Path "C:\RemoveAccount.ps1" -Name $runbookName -Type PowerShell -ResourceGroupName $ResourcegroupName -AutomationAccountName $automationAccountName -Force

    #Publishing Runbook
    Publish-AzureRmAutomationRunbook -Name $runbookName -ResourceGroupName $ResourcegroupName -AutomationAccountName $automationAccountName

    #Providing parameter values to powershell script file
    $params=@{"UserName"=$UserName;"Password"=$Password;"ResourcegroupName"=$ResourcegroupName;"SubscriptionId"=$subscriptionid;"automationAccountName"=$automationAccountName}
    Start-AzureRmAutomationRunbook -Name $runbookName -ResourceGroupName $ResourcegroupName -AutomationAccountName $automationAccountName -Parameters $params | Out-Null