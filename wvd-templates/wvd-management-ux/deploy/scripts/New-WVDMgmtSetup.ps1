﻿$subscriptionid = Get-AutomationVariable -Name 'subscriptionid'
$ResourceGroupName = Get-AutomationVariable -Name 'ResourceGroupName'
$RDBrokerURL = Get-AutomationVariable -Name 'RDBrokerURL'
$ResourceURL = Get-AutomationVariable -Name 'ResourceURL'
$fileURI = Get-AutomationVariable -Name 'fileURI'
$Username = Get-AutomationVariable -Name 'Username'
$Password = Get-AutomationVariable -Name 'Password'
$automationAccountName = Get-AutomationVariable -Name 'accountName'
$WebApp = Get-AutomationVariable -Name 'webApp'
$ApiApp = Get-AutomationVariable -Name 'apiApp'

Invoke-WebRequest -Uri $fileURI -OutFile "C:\msft-wvd-saas-offering.zip"
New-Item -Path "C:\msft-wvd-saas-offering" -ItemType directory -Force -ErrorAction SilentlyContinue
Expand-Archive "C:\msft-wvd-saas-offering.zip" -DestinationPath "C:\msft-wvd-saas-offering" -ErrorAction SilentlyContinue
$AzureModulesPath = Get-ChildItem -Path "C:\msft-wvd-saas-offering\msft-wvd-saas-offering"| Where-Object {$_.FullName -match 'AzureModules.zip'}
Expand-Archive $AzureModulesPath.fullname -DestinationPath 'C:\Modules\Global' -ErrorAction SilentlyContinue

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
    $CredentialAssetName = 'DefaultAzureCredential'

    #Get the credential with the above name from the Automation Asset store
    $Cred = Get-AutomationPSCredential -Name $CredentialAssetName
    Add-AzureRmAccount -Environment 'AzureCloud' -Credential $Cred
    Select-AzureRmSubscription -SubscriptionId $subscriptionid
    $CodeBitPath= "C:\msft-wvd-saas-offering\msft-wvd-saas-offering"
    $WebAppDirectory = ".\msft-wvd-saas-web"
    $WebAppExtractionPath = ".\msft-wvd-saas-web\msft-wvd-saas-web.zip"
    $ApiAppDirectory = ".\msft-wvd-saas-api"
    $ApiAppExtractionPath = ".\msft-wvd-saas-api\msft-wvd-saas-api.zip"

	#Function to get PublishingProfileCredentials
	function Get-PublishingProfileCredentials($resourceGroupName, $webAppName){
 
    $resourceType = "Microsoft.Web/sites/config"
    $resourceName = "$webAppName/publishingcredentials"
 
    $publishingCredentials = Invoke-AzureRmResourceAction -ResourceGroupName $resourceGroupName -ResourceType $resourceType -ResourceName $resourceName -Action list -ApiVersion 2015-08-01 -Force
 
       return $publishingCredentials
} 
 
	#Function to get KuduApiAuthorisationHeaderValue
	function Get-KuduApiAuthorisationHeaderValue($resourceGroupName, $webAppName, $slotName = $null){
    $publishingCredentials = Get-PublishingProfileCredentials $resourceGroupName $webAppName $slotName
    return ("Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $publishingCredentials.Properties.PublishingUserName, $publishingCredentials.Properties.PublishingPassword))))
}

	#Function to confirm files are uploaded or not in both azure app services
	function RunCommand($dir,$command,$resourceGroupName, $webAppName, $slotName = $null){
        $kuduApiAuthorisationToken = Get-KuduApiAuthorisationHeaderValue $resourceGroupName $webAppName $slotName
        $kuduApiUrl="https://$webAppName.scm.azurewebsites.net/api/command"
        $Body = 
          @{
          "command"=$command;
           "dir"=$dir
           } 
        $bodyContent=@($Body) | ConvertTo-Json
        #Write-output $bodyContent
         Invoke-RestMethod -Uri $kuduApiUrl `
                            -Headers @{"Authorization"=$kuduApiAuthorisationToken;"If-Match"="*"} `
                            -Method POST -ContentType "application/json" -Body $bodyContent
    }

try
{
                # Get Url of Web-App
                $GetWebApp = Get-AzureRmWebApp -Name $WebApp -ResourceGroupName $ResourceGroupName
                $WebUrl = $GetWebApp.DefaultHostName
                 
                #$requiredAccessName=$ResourceURL.Split("/")[3]
                $redirectURL="https://"+"$WebUrl"+"/"
                
                #Static value of wvdInfra web appname/appid
                $wvdinfraWebAppId = "5a0aa725-4958-4b0c-80a9-34562e23f3b7"
                $serviceIdinfo = Get-AzureRmADServicePrincipal -ErrorAction SilentlyContinue | Where-Object {$_.ApplicationId -eq $wvdinfraWebAppId}
                
                if(!$serviceIdinfo){
                $wvdinfraWebApp = "Windows Virtual Desktop"
                
                $serviceIdinformation = Get-AzureRmADServicePrincipal -DisplayName $wvdinfraWebApp -ErrorAction SilentlyContinue
                foreach($servicePName in $serviceIdinformation){
                if($servicePName.ApplicationId -eq $wvdinfraWebAppId){
                $serviceIdinfo = $servicePName
                }                
                }
                }
                	
                $wvdInfraWebAppName = $serviceIdinfo.DisplayName
                #generate unique ID based on subscription ID
                $unique_subscription_id = ($subscriptionid).Replace('-', '').substring(0, 19)
                

                #generate the display name for native app in AAD
                $wvdSaaS_clientapp_display_name = "wvdSaaS" + $ResourceGroupName.ToLowerInvariant() + $unique_subscription_id.ToLowerInvariant()
                #Creating Client application in azure ad
                Connect-AzureAD -Credential $Cred
                $clientAdApp = New-AzureADApplication -DisplayName $wvdSaaS_clientapp_display_name -ReplyUrls $redirectURL -PublicClient $true -AvailableToOtherTenants $false -Verbose -ErrorAction Stop
                $resourceAppId = Get-AzureADServicePrincipal -SearchString $wvdInfraWebAppName | Where-Object {$_.DisplayName -eq $wvdInfraWebAppName}
                $clientappreq = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
                $clientappreq.ResourceAppId = $resourceAppId.AppId
                foreach($permission in $resourceAppId.Oauth2Permissions){
                    $clientappreq.ResourceAccess += New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList $permission.Id,"Scope"
                }
                #Setting up the WVD Required Access to Client Application
				 Set-AzureADApplication -ObjectId $clientAdApp.ObjectId -RequiredResourceAccess $clientappreq -ErrorAction Stop

				}
                
        catch
        {
            Write-Output $_.Exception.Message
            throw $_.Exception.Message
        }

        if($ApiApp)
        {
            try
            {
                ## PUBLISHING API-APP PACKAGE ##
                
                Set-Location $CodeBitPath

                # Extract the Api-App ZIP file content.
            
                Write-Output "Extracting the Api-App Zip File"
                Expand-Archive -Path $ApiAppExtractionPath -DestinationPath $ApiAppDirectory -Force 
                $ApiAppExtractedPath = Get-ChildItem -Path $ApiAppDirectory | Where-Object {$_.FullName -notmatch '\\*.zip($|\\)'} | Resolve-Path -Verbose
                
                # Get publishing profile from Api-App

                Write-Output "Getting the Publishing profile information from Api-App"
                $ApiAppXML = (Get-AzureRmWebAppPublishingProfile -Name $ApiApp `
                -ResourceGroupName $ResourceGroupName  `
                -OutputFile null)
                $ApiAppXML = [xml]$ApiAppXML

                # Extract connection information from publishing profile

                Write-Output "Gathering the username, password and publishurl from the Web-App Publishing Profile"
                $ApiAppUserName = $ApiAppXML.SelectNodes("//publishProfile[@publishMethod=`"MSDeploy`"]/@userName").value
                $ApiAppPassword = $ApiAppXML.SelectNodes("//publishProfile[@publishMethod=`"MSDeploy`"]/@userPWD").value
                $ApiAppURL = $ApiAppXML.SelectNodes("//publishProfile[@publishMethod=`"MSDeploy`"]/@publishUrl").value
                
                # Publish Api-App Package files recursively

                Write-Output "Uploading the Extracted files to Api-App"
                Get-ChildItem $ApiAppExtractedPath  | Compress-Archive -update -DestinationPath 'c:\msft-wvd-saas-Api.zip' -Verbose 
                test-path -path 'c:\msft-wvd-saas-Api.zip'
                $filePath = 'C:\msft-wvd-saas-Api.zip'
                $apiUrl = "https://$ApiAppURL/api/zipdeploy"
                $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $ApiAppUserName, $ApiAppPassword)))
                $userAgent = "powershell/1.0"
                Invoke-RestMethod -Uri $apiUrl -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -UserAgent $userAgent -Method POST -InFile $filePath -ContentType "multipart/form-data"
                
                $ApplicationId=$clientAdApp.AppID
                # Adding App Settings to Api-App
                Write-Output "Adding App settings to Api-App"
                $ApiAppSettings = @{"ApplicationId" = "$ApplicationId";
                                    "RDBrokerUrl" = "$RDBrokerURL";
                                    "ResourceUrl" = "$ResourceURL";
                                    "RedirectURI" = "https://"+"$WebUrl"+"/";
				}
                Set-AzureRmWebApp -AppSettings $ApiAppSettings -Name $ApiApp -ResourceGroupName $ResourceGroupName
				
				#Checking Extracted files are uploaded or not
				$returnvalue = RunCommand -dir "site\wwwroot\" -command "ls web.config"  -resourceGroupName $resourceGroupName -webAppName $ApiApp
				if($returnvalue.output){
				Write-Output "Uploading of Extracted files to Api-App is Successful"
				write-output "Published files are uploaded successfully"
				}
				else{
				Write-output "published files are not uploaded Error: $returnvalue.error"
				throw $returnvalue.error
				}
            }
            catch
            {
                Write-Output $_.Exception.Message
                throw $_.Exception.Message
            }
        }
        if($WebApp -and $ApiApp)
        {
            try
            {
                ## PUBLISHING WEB-APP PACKAGE ##
                
                Set-Location $CodeBitPath

                Write-Output "Extracting the Web-App Zip File"
 
                # Extract the Web-App ZIP file content.

                Expand-Archive -Path $WebAppExtractionPath -DestinationPath $WebAppDirectory -Force 
                $WebAppExtractedPath = Get-ChildItem -Path $WebAppDirectory | Where-Object {$_.FullName -notmatch '\\*.zip($|\\)'} | Resolve-Path -Verbose

                # Get the main.bundle.js file Path 

                $MainbundlePath = Get-ChildItem $WebAppExtractedPath -recurse | where {($_.FullName -match "main\.(\w+).bundle.js$")} | % {$_.FullName}

 
                # Get Url of Api-App 

                $GetUrl = Get-AzureRmResource -ResourceName $ApiApp -ResourceGroupName $ResourceGroupName -ExpandProperties
                $GetApiUrl = $GetUrl.Properties | select defaultHostName
                $ApiUrl = $GetApiUrl.defaultHostName

                # Change the Url in the main.bundle.js file with the ApiURL

                Write-Output "Updating the Url in main.bundle.js file with Api-app Url"
                (Get-Content $MainbundlePath).replace( "[api_url]", "https://"+$ApiUrl) | Set-Content $MainbundlePath

                # Get publishing profile from web app
                
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

                Write-Output "Uploading the Extracted files to Web-App"
                Get-ChildItem $WebAppExtractedPath  | Compress-Archive -update  -DestinationPath 'c:\msft-wvd-saas-web.zip' -Verbose 
                test-path -path 'c:\msft-wvd-saas-web.zip'
                $filePath = 'C:\msft-wvd-saas-web.zip'
                $apiUrl = "https://$WebAppUrl/api/zipdeploy"
                $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $WebAppUserName, $WebApppassword)))
                $userAgent = "powershell/1.0"
                Invoke-RestMethod -Uri $apiUrl -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -UserAgent $userAgent -Method POST -InFile $filePath -ContentType "multipart/form-data"
                
				#Checking Extracted files are uploaded or not
				$returnvalue = RunCommand -dir "site\wwwroot\" -command "ls web.config"  -resourceGroupName $resourceGroupName -webAppName $WebApp
				if($returnvalue.output)
				{
				Write-Output "Uploading of Extracted files to Web-App is Successful"
				Write-Output "Published files are uploaded successfully"
				}
				else{
				Write-output "Extracted files are not uploaded Error: $returnvalue.error"
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
Import-Module AzureRM.Resources
`$Securepass=ConvertTo-SecureString -String `$Password -AsPlainText -Force
`$Azurecred=New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList(`$Username, `$Securepass)
`$login=Login-AzureRmAccount -Credential `$Azurecred -SubscriptionId `$SubscriptionId
`$AutomationAccount = Get-AzureRmAutomationAccount -ResourceGroupName `$ResourceGroupName -Name `$automationAccountName
if(`$AutomationAccount){
#Remove-AzureRmAutomationAccount -Name `$automationAccountName -ResourceGroupName `$ResourceGroupName -Force
`$resourcedetails = Get-AzureRmResource -Name `$automationAccountName -ResourceGroupName `$ResourceGroupName
Remove-AzureRmResource -ResourceId `$resourcedetails.ResourceId -Force
}else{
exit
}
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

    #Importe powershell file to Runbooks
    Import-AzureRmAutomationRunbook -Path "C:\RemoveAccount.ps1" -Name $runbookName -Type PowerShell -ResourceGroupName $ResourcegroupName -AutomationAccountName $automationAccountName -Force

    #Publishing Runbook
    Publish-AzureRmAutomationRunbook -Name $runbookName -ResourceGroupName $ResourcegroupName -AutomationAccountName $automationAccountName

    #Providing parameter values to powershell script file
    $params=@{"UserName"=$UserName;"Password"=$Password;"ResourcegroupName"=$ResourcegroupName;"SubscriptionId"=$subscriptionid;"automationAccountName"=$automationAccountName}
    Start-AzureRmAutomationRunbook -Name $runbookName -ResourceGroupName $ResourcegroupName -AutomationAccountName $automationAccountName -Parameters $params | Out-Null