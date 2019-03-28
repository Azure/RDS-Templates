$subsriptionid = Get-AutomationVariable -Name 'subsriptionid'
$ResourceGroupName = Get-AutomationVariable -Name 'ResourceGroupName'
$RDBrokerURL = Get-AutomationVariable -Name 'RDBrokerURL'
$ResourceURL = Get-AutomationVariable -Name 'ResourceURL'
$fileURI = Get-AutomationVariable -Name 'fileURI'
$Username = Get-AutomationVariable -Name 'Username'
$Password = Get-AutomationVariable -Name 'Password'
$automationAccountName = Get-AutomationVariable -Name 'accountName'
$WebApp = Get-AutomationVariable -Name 'webApp'
$ApiApp = Get-AutomationVariable -Name 'apiApp'

Invoke-WebRequest -Uri $fileURI -OutFile "C:\msft-rdmi-saas-offering.zip"
New-Item -Path "C:\msft-rdmi-saas-offering" -ItemType directory -Force -ErrorAction SilentlyContinue
Expand-Archive "C:\msft-rdmi-saas-offering.zip" -DestinationPath "C:\msft-rdmi-saas-offering" -ErrorAction SilentlyContinue
$AzureModulesPath = Get-ChildItem -Path "C:\msft-rdmi-saas-offering\msft-rdmi-saas-offering"| Where-Object {$_.FullName -match 'AzureModules.zip'}
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
    Select-AzureRmSubscription -SubscriptionId $subsriptionid
    $CodeBitPath= "C:\msft-rdmi-saas-offering\msft-rdmi-saas-offering"
    $WebAppDirectory = ".\msft-rdmi-saas-web"
    $WebAppExtractionPath = ".\msft-rdmi-saas-web\msft-rdmi-saas-web.zip"
    $ApiAppDirectory = ".\msft-rdmi-saas-api"
    $ApiAppExtractionPath = ".\msft-rdmi-saas-api\msft-rdmi-saas-api.zip"
try
{
                # Get Url of Web-App
                $GetWebApp = Get-AzureRmWebApp -Name $WebApp -ResourceGroupName $ResourceGroupName
                $WebUrl = $GetWebApp.DefaultHostName
                 
                #$requiredAccessName=$ResourceURL.Split("/")[3]
                $redirectURL="https://"+"$WebUrl"+"/"
                
                #Static value of RDMIInfra web appname
                $wvdinfraWebAppId = "5a0aa725-4958-4b0c-80a9-34562e23f3b7"
                $serviceIdinfo = Get-AzureRmADServicePrincipal -ApplicationId $wvdinfraWebAppId
                $rdmiInfraWebAppName = $serviceIdinfo.DisplayName
                #generate unique ID based on subscription ID
                $unique_subscription_id = ($subsriptionid).Replace('-', '').substring(0, 19)
                

                #generate the display name for native app in AAD
                $rdmiSaaS_clientapp_display_name = "RdmiSaaS" + $ResourceGroupName.ToLowerInvariant() + $unique_subscription_id.ToLowerInvariant()
                #Creating Client application in azure ad
                Connect-AzureAD -Credential $Cred
                $clientAdApp = New-AzureADApplication -DisplayName $rdmiSaaS_clientapp_display_name -ReplyUrls $redirectURL -PublicClient $true -AvailableToOtherTenants $false -Verbose -ErrorAction Stop
                $resourceAppId = Get-AzureADServicePrincipal -SearchString $rdmiInfraWebAppName | Where-Object {$_.DisplayName -eq $rdmiInfraWebAppName}
                $clientappreq = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
                $clientappreq.ResourceAppId = $resourceAppId.AppId
               
                foreach($permission in $resourceAppId.Oauth2Permissions){
                    $clientappreq.ResourceAccess += New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList $permission.Id,"Scope"
                }
                Set-AzureADApplication -ObjectId $clientAdApp.ObjectId -RequiredResourceAccess $clientappreq -ErrorAction Stop


        if($ApiApp)
        {
            try
            {
                ## PUBLISHING API-APP PACKAGE ##
                
                Set-Location $CodeBitPath

                # Extract the Api-App ZIP file content.
            
                Write-Output "Extracting the Api-App Zip File"
                Expand-Archive -Path $ApiAppExtractionPath -DestinationPath $ApiAppDirectory -Force 
                $ApiAppExtractedPath = Get-ChildItem -Path $ApiAppDirectory| Where-Object {$_.FullName -notmatch '\\*.zip($|\\)'} | Resolve-Path -Verbose
                
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
                Get-ChildItem $ApiAppExtractedPath  | Compress-Archive -update -DestinationPath 'c:\msft-rdmi-saas-Api.zip' -Verbose 
                test-path -path 'c:\msft-rdmi-saas-Api.zip'
                $filePath = 'C:\msft-rdmi-saas-Api.zip'
                $apiUrl = "https://$ApiAppURL/api/zipdeploy"
                $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $ApiAppUserName, $ApiAppPassword)))
                $userAgent = "powershell/1.0"
                Invoke-RestMethod -Uri $apiUrl -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -UserAgent $userAgent -Method POST -InFile $filePath -ContentType "multipart/form-data"
                Write-Output "Uploading of Extracted files to Api-App is Successful"
                $ApplicationId=$clientAdApp.AppID
                # Adding App Settings to Api-App
                Write-Output "Adding App settings to Api-App"
                $ApiAppSettings = @{"ApplicationId" = "$ApplicationId";
                                    "RDBrokerUrl" = "$RDBrokerURL";
                                    "ResourceUrl" = "$ResourceURL";
                                    "RedirectURI" = "https://"+"$WebUrl"+"/";
            }
                Set-AzureRmWebApp -AppSettings $ApiAppSettings -Name $ApiApp -ResourceGroupName $ResourceGroupName
            }
            catch [Exception]
            {
                Write-Output $_.Exception.Message
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
                $WebAppExtractedPath = Get-ChildItem -Path $WebAppDirectory| Where-Object {$_.FullName -notmatch '\\*.zip($|\\)'} | Resolve-Path -Verbose

                # Get the main.bundle.js file Path 

                $MainbundlePath = Get-ChildItem $WebAppExtractedPath -recurse | where {($_.FullName -match "main.bundle.js" ) -and ($_.FullName -notmatch "main.bundle.js.map")} | % {$_.FullName}
 
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
                Get-ChildItem $WebAppExtractedPath  | Compress-Archive -update  -DestinationPath 'c:\msft-rdmi-saas-web.zip' -Verbose 
                test-path -path 'c:\msft-rdmi-saas-web.zip'
                $filePath = 'C:\msft-rdmi-saas-web.zip'
                $apiUrl = "https://$WebAppUrl/api/zipdeploy"
                $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $WebAppUserName, $WebApppassword)))
                $userAgent = "powershell/1.0"
                Invoke-RestMethod -Uri $apiUrl -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -UserAgent $userAgent -Method POST -InFile $filePath -ContentType "multipart/form-data"
                Write-Output "Uploading of Extracted files to Web-App is Successful"
            }
            catch [Exception]
            {
                Write-Output $_.Exception.Message
            }

            Write-Output "Api URL : https://$ApiUrl"
            Write-Output "Web URL : https://$WebUrl"
        }
}

catch [Exception]
{
    Write-Output $_.Exception.Message
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

    #Importe powershell file to Runbooks
    Import-AzureRmAutomationRunbook -Path "C:\RemoveAccount.ps1" -Name $runbookName -Type PowerShell -ResourceGroupName $ResourcegroupName -AutomationAccountName $automationAccountName -Force

    #Publishing Runbook
    Publish-AzureRmAutomationRunbook -Name $runbookName -ResourceGroupName $ResourcegroupName -AutomationAccountName $automationAccountName

    #Providing parameter values to powershell script file
    $params=@{"UserName"=$UserName;"Password"=$Password;"ResourcegroupName"=$ResourcegroupName;"SubscriptionId"=$subsriptionid;"automationAccountName"=$automationAccountName}
    Start-AzureRmAutomationRunbook -Name $runbookName -ResourceGroupName $ResourcegroupName -AutomationAccountName $automationAccountName -Parameters $params