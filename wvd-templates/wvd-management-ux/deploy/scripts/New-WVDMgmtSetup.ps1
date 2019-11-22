#Initializing variables
$SubscriptionId = Get-AutomationVariable -Name 'subscriptionid'
$ResourceGroupName = Get-AutomationVariable -Name 'ResourceGroupName'
$RDBrokerURL = Get-AutomationVariable -Name 'RDBrokerURL'
$ResourceURL = Get-AutomationVariable -Name 'ResourceURL'
$fileURI = Get-AutomationVariable -Name 'fileURI'
$AutomationAccountName = Get-AutomationVariable -Name 'accountName'
$WebApp = Get-AutomationVariable -Name 'webApp'
$ApiApp = Get-AutomationVariable -Name 'apiApp'

$FileNames = "msft-wvd-saas-api.zip,msft-wvd-saas-web.zip,AzureModules.zip"
$SplitFilenames = $FileNames.split(",")
foreach($Filename in $SplitFilenames){
if($Filename -eq "AzureModules.zip"){
Invoke-WebRequest -Uri $fileURI/scripts/$Filename -OutFile "C:\$Filename"
}else{
Invoke-WebRequest -Uri $fileURI/$Filename -OutFile "C:\$Filename"
}
}
#New-Item -Path "C:\msft-wvd-saas-offering" -ItemType directory -Force -ErrorAction SilentlyContinue
Expand-Archive "C:\AzureModules.zip" -DestinationPath 'C:\Modules\Global' -ErrorAction SilentlyContinue

Import-Module AzureRM.Resources
Import-Module AzureRM.Profile
Import-Module AzureRM.Websites
Import-Module Azure
Import-Module AzureRM.Automation
Import-Module AzureAD

Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope Process -Force -Confirm:$false
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine -Force -Confirm:$false
Get-ExecutionPolicy -List
#The name of the Automation Credential Asset this runbook will use to authenticate to Azure.
$CredentialAssetName = 'ManagementUXDeploy'

#Get the credential with the above name from the Automation Asset store
$Credentials = Get-AutomationPSCredential -Name $CredentialAssetName
Add-AzureRmAccount -Environment 'AzureCloud' -Credential $Credentials
Select-AzureRmSubscription -SubscriptionId $SubscriptionId

New-Item -Path "C:\msft-wvd-saas-web" -ItemType directory -Force -ErrorAction SilentlyContinue
$WebAppDirectory = "C:\msft-wvd-saas-web"

#Function to get PublishingProfileCredentials
function Get-PublishingProfileCredentials ($resourceGroupName,$webAppName) {

	$resourceType = "Microsoft.Web/sites/config"
	$resourceName = "$webAppName/publishingcredentials"

	$publishingCredentials = Invoke-AzureRmResourceAction -ResourceGroupName $resourceGroupName -ResourceType $resourceType -ResourceName $resourceName -Action list -ApiVersion 2015-08-01 -Force

	return $publishingCredentials
}

#Function to get KuduApiAuthorisationHeaderValue
function Get-KuduApiAuthorisationHeaderValue ($resourceGroupName,$webAppName,$slotName = $null) {
	$publishingCredentials = Get-PublishingProfileCredentials $resourceGroupName $webAppName $slotName
	return ("Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $publishingCredentials.Properties.PublishingUserName,$publishingCredentials.Properties.PublishingPassword))))
}

#Function to confirm files are uploaded or not in both azure app services
function RunCommand ($dir,$command,$resourceGroupName,$webAppName,$slotName = $null) {
	$kuduApiAuthorisationToken = Get-KuduApiAuthorisationHeaderValue $resourceGroupName $webAppName $slotName
	$kuduApiUrl = "https://$webAppName.scm.azurewebsites.net/api/command"
	$Body =
	@{
		"command" = $command;
		"dir" = $dir
	}
	$bodyContent = @($Body) | ConvertTo-Json
	#Write-output $bodyContent
	Invoke-RestMethod -Uri $kuduApiUrl `
 		-Headers @{ "Authorization" = $kuduApiAuthorisationToken; "If-Match" = "*" } `
 		-Method POST -ContentType "application/json" -Body $bodyContent
}

try
{
	# Get Url of Web-App
	$GetWebApp = Get-AzureRmWebApp -Name $WebApp -ResourceGroupName $ResourceGroupName
	$WebUrl = $GetWebApp.DefaultHostName

	#$requiredAccessName=$ResourceURL.Split("/")[3]
	$redirectURL = "https://" + "$WebUrl" + "/"

	#Static value of wvdInfra web appname/appid
	$wvdinfraWebAppId = "5a0aa725-4958-4b0c-80a9-34562e23f3b7"
	$serviceIdinfo = Get-AzureRmADServicePrincipal -ErrorAction SilentlyContinue | Where-Object { $_.ApplicationId -eq $wvdinfraWebAppId }

	$wvdInfraWebAppObjId = $serviceIdinfo.Id.GUID
	#generate unique ID based on subscription ID
	$unique_subscription_id = ($SubscriptionId).Replace('-','').substring(0,19)


	#generate the display name for native app in AAD
	$wvdSaaS_clientapp_display_name = "wvdSaaS" + $ResourceGroupName.ToLowerInvariant() + $unique_subscription_id.ToLowerInvariant()
	
	#Creating ClientApp Ad application in azure Active Directory
	Connect-AzureAD -Credential $Credentials
	$clientAdApp = New-AzureADApplication -DisplayName $wvdSaaS_clientapp_display_name -ReplyUrls $redirectURL -PublicClient $true -AvailableToOtherTenants $false -Verbose -ErrorAction Stop

	#Collecting WVD Serviceprincipal Api Permission
	$WVDServicePrincipal = Get-AzureADServicePrincipal -ObjectId $wvdInfraWebAppObjId #-SearchString $wvdInfraWebAppName | Where-Object {$_.DisplayName -eq $wvdInfraWebAppName}
	$AzureAdResouceAcessObject = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
	$AzureAdResouceAcessObject.ResourceAppId = $WVDServicePrincipal.AppId
	foreach ($permission in $WVDServicePrincipal.Oauth2Permissions) {
		$AzureAdResouceAcessObject.ResourceAccess += New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList $permission.Id,"Scope"
	}

	#Collecting AzureService Management Api permission
	$AzureServMgmtApi = Get-AzureRmADServicePrincipal -ApplicationId "797f4846-ba00-4fd7-ba43-dac1f8f63013"
	$AzureAdServMgmtApi = Get-AzureADServicePrincipal -ObjectId $AzureServMgmtApi.Id.GUID
	$AzureServMgmtApiResouceAcessObject = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
	$AzureServMgmtApiResouceAcessObject.ResourceAppId = $AzureAdServMgmtApi.AppId
	foreach ($SerVMgmtAPipermission in $AzureAdServMgmtApi.Oauth2Permissions) {
		$AzureServMgmtApiResouceAcessObject.ResourceAccess += New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList $SerVMgmtAPipermission.Id,"Scope"
	}

	#Adding WVD Api Required Access and Azure Service Management Api required access Permissions to ClientAPP AD Application.
	Set-AzureADApplication -ObjectId $clientAdApp.ObjectId -RequiredResourceAccess $AzureAdResouceAcessObject,$AzureServMgmtApiResouceAcessObject -ErrorAction Stop
	
}

catch
{
	Write-Output $_.Exception.Message
	throw $_.Exception.Message
}

if ($ApiApp)
{
	try
	{
	    # Get publishing profile from Api-App

		Write-Output "Getting the Publishing profile information from Api-App"
		$ApiAppXML = (Get-AzureRmWebAppPublishingProfile -Name $ApiApp `
 				-ResourceGroupName $ResourceGroupName `
 				-OutputFile null)
		$ApiAppXML = [xml]$ApiAppXML

		# Extract connection information from publishing profile

		Write-Output "Gathering the username, password and publishurl from the Web-App Publishing Profile"
		$ApiAppUserName = $ApiAppXML.SelectNodes("//publishProfile[@publishMethod=`"MSDeploy`"]/@userName").value
		$ApiAppPassword = $ApiAppXML.SelectNodes("//publishProfile[@publishMethod=`"MSDeploy`"]/@userPWD").value
		$ApiAppURL = $ApiAppXML.SelectNodes("//publishProfile[@publishMethod=`"MSDeploy`"]/@publishUrl").value

		# Publish Api-App Package files recursively

		Write-Output "Uploading the Extracted files to Api-App"
		#Get-ChildItem $ApiAppExtractedPath | Compress-Archive -update -DestinationPath 'c:\msft-wvd-saas-Api.zip' -Verbose
		Test-Path -Path 'C:\msft-wvd-saas-Api.zip'
		$filePath = 'C:\msft-wvd-saas-Api.zip'
		$apiUrl = "https://$ApiAppURL/api/zipdeploy"
		$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $ApiAppUserName,$ApiAppPassword)))
		$userAgent = "powershell/1.0"
		Invoke-RestMethod -Uri $apiUrl -Headers @{ Authorization = ("Basic {0}" -f $base64AuthInfo) } -UserAgent $userAgent -Method POST -InFile $filePath -ContentType "multipart/form-data"

		$ApplicationId = $clientAdApp.AppId
		# Adding App Settings to Api-App
		Write-Output "Adding App settings to Api-App"
		$ApiAppSettings = @{ "ApplicationId" = "$ApplicationId";
			"RDBrokerUrl" = "$RDBrokerURL";
			"ResourceUrl" = "$ResourceURL";
			"RedirectURI" = "https://" + "$WebUrl" + "/";
		}
		Set-AzureRmWebApp -AppSettings $ApiAppSettings -Name $ApiApp -ResourceGroupName $ResourceGroupName

		#Checking Extracted files are uploaded or not
		$returnvalue = RunCommand -dir "site\wwwroot\" -Command "ls web.config" -ResourceGroupName $resourceGroupName -webAppName $ApiApp
		if ($returnvalue.output) {
			Write-Output "Uploading of Extracted files to Api-App is Successful"
			Write-Output "Published files are uploaded successfully"
		}
		else {
			Write-Output "published files are not uploaded Error: $returnvalue.error"
			throw $returnvalue.error
		}
	}
	catch
	{
		Write-Output $_.Exception.Message
		throw $_.Exception.Message
	}
}
if ($WebApp -and $ApiApp)
{
	try
	{
		## PUBLISHING WEB-APP PACKAGE ##
		Write-Output "Extracting the Web-App Zip File"
		# Extract the Web-App ZIP file content.
		Expand-Archive -Path "C:\msft-wvd-saas-web.zip" -DestinationPath $WebAppDirectory -Force
																																  

		# Get the main.bundle.js file Path 
		$MainbundlePath = Get-ChildItem $WebAppDirectory -Recurse | Where-Object { ($_.FullName -match "main\.(\w+).bundle.js$") } | ForEach-Object { $_.FullName }


		# Get Url of Api-App 
		$GetUrl = Get-AzureRmResource -ResourceName $ApiApp -ResourceGroupName $ResourceGroupName -ExpandProperties
		$GetApiUrl = $GetUrl.Properties | Select-Object defaultHostName
		$ApiUrl = $GetApiUrl.DefaultHostName

		# Change the Url in the main.bundle.js file with the ApiURL
		Write-Output "Updating the Url in main.bundle.js file with Api-app Url"
		(Get-Content $MainbundlePath).Replace("[api_url]","https://" + $ApiUrl) | Set-Content $MainbundlePath

		# Get publishing profile from web app
		Write-Output "Getting the Publishing profile information from Web-App"
		$WebAppXML = (Get-AzureRmWebAppPublishingProfile -Name $WebApp `
 				-ResourceGroupName $ResourceGroupName `
 				-OutputFile null)

		$WebAppXML = [xml]$WebAppXML

		# Extract connection information from publishing profile

		Write-Output "Gathering the username, password and publishurl from the Web-App Publishing Profile"
		$WebAppUserName = $WebAppXML.SelectNodes("//publishProfile[@publishMethod=`"MSDeploy`"]/@userName").value
		$WebAppPassword = $WebAppXML.SelectNodes("//publishProfile[@publishMethod=`"MSDeploy`"]/@userPWD").value
		$WebAppURL = $WebAppXML.SelectNodes("//publishProfile[@publishMethod=`"MSDeploy`"]/@publishUrl").value
        Remove-Item "C:\msft-wvd-saas-web.zip" -Force
		# Publish Web-App Package files recursively
		Write-Output "Uploading the Extracted files to Web-App"
		Get-ChildItem $WebAppDirectory | Compress-Archive -update -DestinationPath 'c:\msft-wvd-saas-web.zip' -Verbose
		Test-Path -Path 'c:\msft-wvd-saas-web.zip'
		$filePath = 'C:\msft-wvd-saas-web.zip'
		$apiUrl = "https://$WebAppUrl/api/zipdeploy"
		$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $WebAppUserName,$WebApppassword)))
		$userAgent = "powershell/1.0"
		Invoke-RestMethod -Uri $apiUrl -Headers @{ Authorization = ("Basic {0}" -f $base64AuthInfo) } -UserAgent $userAgent -Method POST -InFile $filePath -ContentType "multipart/form-data"

		#Checking Extracted files are uploaded or not
		$returnvalue = RunCommand -dir "site\wwwroot\" -Command "ls web.config" -ResourceGroupName $resourceGroupName -webAppName $WebApp
		if ($returnvalue.output)
		{
			Write-Output "Uploading of Extracted files to Web-App is Successful"
			Write-Output "Published files are uploaded successfully"
		}
		else {
			Write-Output "Extracted files are not uploaded Error: $returnvalue.error"
			throw $returnvalue.error
		}
	}
	catch
	{
		Write-Output $_.Exception.Message
		throw $_.Exception.Message
	}

	Write-Output "Api URL : https://$ApiUrl"
	Write-Output "Web URL : https://$WebUrl"
}



New-PSDrive -Name RemoveAccount -PSProvider FileSystem -Root "C:\" | Out-Null
@"
Param(
    [Parameter(Mandatory=`$True)]
    [string] `$SubscriptionId,
    [Parameter(Mandatory=`$True)]
    [string] `$ResourceGroupName,
    [Parameter(Mandatory=`$True)]
    [string] `$AutomationAccountName,
    [Parameter(Mandatory=`$True)]
    [string] `$fileURI
 
)


Invoke-WebRequest -Uri `$fileURI/scripts/AzureModules.zip -OutFile "C:\AzureModules.zip"

Expand-Archive "C:\AzureModules.zip" -DestinationPath 'C:\Modules\Global' -ErrorAction SilentlyContinue

Import-Module AzureRM.profile
Import-Module AzureRM.Automation
Import-Module AzureRM.Resources
#The name of the Automation Credential Asset this runbook will use to authenticate to Azure.
`$CredentialAssetName = 'ManagementUXDeploy'
#Get the credential with the above name from the Automation Asset store
`$Credentials = Get-AutomationPSCredential -Name `$CredentialAssetName
Add-AzureRmAccount -Environment "AzureCloud" -Credential `$Credentials
Select-AzureRmSubscription -SubscriptionId `$SubscriptionId
`$AutomationAccount = Get-AzureRmAutomationAccount -ResourceGroupName `$ResourceGroupName -Name `$AutomationAccountName
if(`$AutomationAccount){
#Remove-AzureRmAutomationAccount -Name `$AutomationAccountName -ResourceGroupName `$ResourceGroupName -Force
`$resourcedetails = Get-AzureRmResource -Name `$AutomationAccountName -ResourceGroupName `$ResourceGroupName
Remove-AzureRmResource -ResourceId `$resourcedetails.ResourceId -Force
}else{
exit
}
"@ | Out-File -FilePath RemoveAccount:\RemoveAccount.ps1 -Force

$runbookName = 'removewvdsaasacctbook'
#Create a Run Book
New-AzureRmAutomationRunbook -Name $runbookName -Type PowerShell -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName

#Import modules to Automation Account
$modules = "AzureRM.profile,Azurerm.compute,azurerm.resources"
$modulenames = $modules.Split(",")
foreach ($modulename in $modulenames) {
	Set-AzureRmAutomationModule -Name $modulename -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourcegroupName
}

#Importe powershell file to Runbooks
Import-AzureRmAutomationRunbook -Path "C:\RemoveAccount.ps1" -Name $runbookName -Type PowerShell -ResourceGroupName $ResourcegroupName -AutomationAccountName $AutomationAccountName -Force

#Publishing Runbook
Publish-AzureRmAutomationRunbook -Name $runbookName -ResourceGroupName $ResourcegroupName -AutomationAccountName $AutomationAccountName

#Providing parameter values to powershell script file
$params = @{ "ResourcegroupName" = $ResourcegroupName; "SubscriptionId" = $SubscriptionId; "AutomationAccountName" = $AutomationAccountName; "fileURI" = $fileURI }
Start-AzureRmAutomationRunbook -Name $runbookName -ResourceGroupName $ResourcegroupName -AutomationAccountName $AutomationAccountName -Parameters $params | Out-Null
