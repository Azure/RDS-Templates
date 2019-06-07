$subscriptionid = Get-AutomationVariable -Name 'subscriptionid'
$ResourceGroupName = Get-AutomationVariable -Name 'ResourceGroupName'
$fileURI = Get-AutomationVariable -Name 'fileURI'
$Username = Get-AutomationVariable -Name 'Username'
$Password = Get-AutomationVariable -Name 'Password'
$automationAccountName = Get-AutomationVariable -Name 'accountName'
$WebApp = Get-AutomationVariable -Name 'webApp'
$ClientId = Get-AutomationVariable -Name 'ClientId'
$ClientSecret = Get-AutomationVariable -Name 'ClientSecret'
$WorkspaceID = Get-AutomationVariable -Name 'WorkspaceID'

Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope Process -Force -Confirm:$false
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine -Force -Confirm:$false
Get-ExecutionPolicy -List

Invoke-WebRequest -Uri $fileURI -OutFile "C:\wvd-monitoring-ux.zip"
#New-Item -Path "C:\wvd-monitoring-ux" -ItemType directory -Force -ErrorAction SilentlyContinue
#Expand-Archive "C:\wvd-monitoring-ux.zip" -DestinationPath "C:\wvd-monitoring-ux" -ErrorAction SilentlyContinue

$modules="https://raw.githubusercontent.com/Azure/RDS-Templates/wvd-mgmt-ux/wvd-templates/wvd-management-ux/deploy/scripts/msft-wvd-saas-offering.zip"
Invoke-WebRequest -Uri $modules -OutFile "C:\msft-rdmi-saas-offering.zip"
New-Item -Path "C:\msft-rdmi-saas-offering" -ItemType directory -Force -ErrorAction SilentlyContinue
Expand-Archive "C:\msft-rdmi-saas-offering.zip" -DestinationPath "C:\msft-rdmi-saas-offering" -ErrorAction SilentlyContinue
$AzureModulesPath = Get-ChildItem -Path "C:\msft-rdmi-saas-offering\msft-wvd-saas-offering"| Where-Object {$_.FullName -match 'AzureModules.zip'}
Expand-Archive $AzureModulesPath.fullname -DestinationPath 'C:\Modules\Global' -ErrorAction SilentlyContinue

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
#Get-ChildItem $appdirectory -recurse | Compress-Archive -update -DestinationPath 'c:\WebApp-Monitor-UX.zip' -Verbose 
test-path -path 'C:\wvd-monitoring-ux.zip'
$filePath = 'C:\wvd-monitoring-ux.zip'
$apiURL = "https://$WebAppURL/api/zipdeploy"
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $WebAppUserName, $WebAppPassword)))
$userAgent = "powershell/1.0"
Invoke-RestMethod -Uri $apiURL -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -UserAgent $userAgent -Method POST -InFile $filePath -ContentType "multipart/form-data"
                
# Adding App Settings to WebApp
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

$Psswd = $Password | ConvertTo-SecureString -asPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential($Username,$Psswd)
Install-Module -Name AzureAD
Connect-AzureAD -AzureEnvironmentName AzureCloud -Credential $Credential

$newReplyUrl = "$redirectURL/security/signin-callback"
# Get Azure AD App
$app = Get-AzureADApplication -Filter "AppId eq '$($ClientId)'"

# Get the Reply URL
$replyUrls = $app.ReplyUrls

# Add Reply URL if not already in the list 

if ($replyUrls -NotContains $newReplyUrl) {
    $replyUrls.Add($newReplyUrl)
    Set-AzureADApplication -ObjectId $app.ObjectId -ReplyUrls $replyUrls
}


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

    $runbookName='removewvdsaasacctbook'
    #Create a Run Book
    New-AzureRmAutomationRunbook -Name $runbookName -Type PowerShell -ResourceGroupName $ResourceGroupName -AutomationAccountName $automationAccountName

    #Import modules to Automation Account
    $modules="AzureRM.profile,Azurerm.compute,azurerm.resources"
    $modulenames=$modules.Split(",")
    foreach($modulename in $modulenames){
    Set-AzureRmAutomationModule -Name $modulename -AutomationAccountName $automationAccountName -ResourceGroupName $ResourcegroupName
    }

    #Import powershell file to Runbooks
    Import-AzureRmAutomationRunbook -Path "C:\RemoveAccount.ps1" -Name $runbookName -Type PowerShell -ResourceGroupName $ResourcegroupName -AutomationAccountName $automationAccountName -Force

    #Publishing Runbook
    Publish-AzureRmAutomationRunbook -Name $runbookName -ResourceGroupName $ResourcegroupName -AutomationAccountName $automationAccountName

    #Providing parameter values to powershell script file
    $params=@{"UserName"=$UserName;"Password"=$Password;"ResourcegroupName"=$ResourcegroupName;"SubscriptionId"=$subscriptionid;"automationAccountName"=$automationAccountName}
    Start-AzureRmAutomationRunbook -Name $runbookName -ResourceGroupName $ResourcegroupName -AutomationAccountName $automationAccountName -Parameters $params | Out-Null