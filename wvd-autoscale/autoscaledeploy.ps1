<#
.SYNOPSIS 
    This AutoScale Deployment Script will create the below resources in Azure..
        - AzureAutomation Account
        - Azure Scheduler Job
		
.DESCRIPTION
    This AutoScale Deployment Script create the Automation account with RunAs Account enable then create a runbook to update Modules of Automation Account. Then create a BreadthfirstRunbook and DepthfirstRunbook based on condition to import BreadthFirst ScaleScript and DepthFirst ScaleScript then create a BreadthFirst Webhook and DepthFirst Webhook.
    And also it will create the Azure Scheduler job.
          
	This script depends on Azure RM PowerShell Module to get azurerm module execute following command.
	Use "-AllowClobber" parameter if you have more than one version of PS modules installed.

	PS C:\>Install-Module AzureRM  -AllowClobber

.NOTE
    Download/Copy the Script and save local location.
    Run this script with Administrator mode of PowerShell.
    
		  
.EXAMPLE
Set-Location -path "Script Downloaded location"
    .\AutoScaleDeployment.ps1 -RDBrokerURL "https://rdbroker.wvd.microsoft.com" -TenantGroupName "WVD Tenant Group Name" -TenantName: "WVD tenant name" -HostpoolName "WVD Hostpool Name" -BreadthFirst $true `
-AADTenantId "Specifies the Azure Active Directory Tenant Id your azure subscription associated with." -AADApplicationId "The GUID for the Azure Active Directory Application you create for service principal" -AADServicePrincipalSecret "The secret you created for your Azure service principal." -Subscriptionid "The ID of your Azure subscription" -BeginPeakTime "09:00" -EndPeakTime "18:00" -TimeDifference "+5:30" -SessionThresholdPerCPU 2 -MinimumNumberOfRDSH 1 -LimitSecondsToForceLogOffUser 1 -Location "south central us" -LogOffMessageTitle "The title of the notification message sent to a user before forcing the user to log off." -LogOffMessageBody "The body of the message sent to a user before forcing the user to log off." -RecurrenceInterval 15 `
-AutomationAccountName "WVDAutoscaleAutomationAccount" -resourcegroupname "WVDAutoscaleResourceGroup"

     
#>
param(

    [Parameter(Mandatory = $True)]
    $AutomationAccountName,

    [Parameter(Mandatory = $True)]
    $ResourceGroupName,

    [Parameter(Mandatory = $True)]
    $RDBrokerURL,

    [Parameter(Mandatory = $True)]
    $TenantGroupName,

    [Parameter(Mandatory = $True)]
    $TenantName,

    [Parameter(Mandatory = $True)]
    $HostpoolName,

    [Parameter(Mandatory = $True)]
    [bool]$BreadthFirst = "False",

    [Parameter(Mandatory = $True)]
    $RecurrenceInterval,

    [Parameter(Mandatory = $True)]
    $AADTenantId,

    [Parameter(Mandatory = $True)]
    $AADApplicationId,

    [Parameter(Mandatory = $True)]
    $AADServicePrincipalSecret,

    [Parameter(Mandatory = $True)]
    $Subscriptionid,

    [Parameter(Mandatory = $True)]
    $BeginPeakTime,

    [Parameter(Mandatory = $True)]
    $EndPeakTime,

    [Parameter(Mandatory = $True)]
    $TimeDifference,

    [Parameter(Mandatory = $True)]
    $SessionThresholdPerCPU,

    [Parameter(Mandatory = $True)]
    $MinimumNumberOfRDSH,


    [Parameter(Mandatory = $True)]
    $LimitSecondsToForceLogOffUser,

    [Parameter(Mandatory = $false)]
    $Location = "South Central US",


    [Parameter(Mandatory = $True)]
    $LogOffMessageTitle,

    [Parameter(Mandatory = $True)]
    $LogOffMessageBody
)

#Declared All static Variables
$TenantNamevalue = $TenantName.replace(" ", '')
$TenantGroupNameValue = $TenantGroupName.replace(" ", '')
$BreadthFirstRunbook = "$TenantNamevalue" + "-" + "BreadthfirstRunbook"
$DepthFirstRunbook = "$TenantNamevalue" + "-" + "DepthFirstRunbook"
$JobCollectionName = "$TenantGroupNameValue" + "-" + "$TenantNamevalue" + "-" + "WVDAutoScaleJobCollection"
$BreadthFirstWebhook = "$TenantNamevalue" + "-" + "BreadthFirstWebhook"
$DepthFirstWebhook = "$TenantNamevalue" + "-" + "DepthFirstWebhook"
$LoadBalancingBool = ($BreadthFirst -eq "True")
$fileURI = "https://raw.githubusercontent.com/Azure/RDS-Templates/ptg-autoscale/wvd-autoscale/scripts/wvdmodules.zip"


#Authenticate to AzureRm
try {
    Login-AzureRmAccount -SubscriptionId $Subscriptionid
}
catch {
    $_.Exception
}

$CurrentDateTime = Get-Date
$CurrentDateTime = $CurrentDateTime.ToUniversalTime()

$TimeDifferenceInHours = $TimeDifference.Split(":")[0]
$TimeDifferenceInMinutes = $TimeDifference.Split(":")[1]
#Azure is using UTC time, justify it to the local time
$CurrentDateTime = $CurrentDateTime.AddHours($TimeDifferenceInHours).AddMinutes($TimeDifferenceInMinutes)


#Check the resourcegroup exist or not in Azure
$CheckRG = Get-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location -ErrorAction SilentlyContinue
if (!$CheckRG) {
    New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location -Force
}

#Check the Automation Account Name exist or not in Azure
$getAutomationAccount = Get-AzureRmAutomationAccount -ResourceGroupName $ResourceGroupName -Name $AutomationAccountName -ErrorAction SilentlyContinue
if (!$getAutomationAccount) {
    $ApplicationDisplayName = $AutomationAccountName
    $SelfSignedCertPlainPassword = "Welcome@123"
    $SelfSignedCertNoOfMonthsUntilExpired = 12
    $EnvironmentName = "AzureCloud"

    New-AzureRmAutomationAccount -ResourceGroupName $ResourceGroupName -Name $AutomationAccountName -Location $Location


    function CreateSelfSignedCertificate([string] $certificateName, [string] $selfSignedCertPlainPassword,
        [string] $certPath, [string] $certPathCer, [string] $selfSignedCertNoOfMonthsUntilExpired ) {
        $Cert = New-SelfSignedCertificate -DnsName $certificateName -CertStoreLocation cert:\LocalMachine\My -KeyExportPolicy Exportable -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider" -NotAfter (Get-Date).AddMonths($selfSignedCertNoOfMonthsUntilExpired) -HashAlgorithm SHA256

        $CertPassword = ConvertTo-SecureString $selfSignedCertPlainPassword -AsPlainText -Force
        Export-PfxCertificate -Cert ("Cert:\localmachine\my\" + $Cert.Thumbprint) -FilePath $certPath -Password $CertPassword -Force | Write-Verbose
        Export-Certificate -Cert ("Cert:\localmachine\my\" + $Cert.Thumbprint) -FilePath $certPathCer -Type CERT | Write-Verbose
    }

    function CreateServicePrincipal([System.Security.Cryptography.X509Certificates.X509Certificate2] $PfxCert, [string] $applicationDisplayName) {  
        $keyValue = [System.Convert]::ToBase64String($PfxCert.GetRawCertData())
        $keyId = (New-Guid).Guid

        # Create an Azure AD application, AD App Credential, AD ServicePrincipal

        # Requires Application Developer Role, but works with Application administrator or GLOBAL ADMIN
        $Application = New-AzureRmADApplication -DisplayName $ApplicationDisplayName -HomePage ("http://" + $applicationDisplayName) -IdentifierUris ("http://" + $keyId) 
        # Requires Application administrator or GLOBAL ADMIN
        $ApplicationCredential = New-AzureRmADAppCredential -ApplicationId $Application.ApplicationId -CertValue $keyValue -StartDate $PfxCert.NotBefore -EndDate $PfxCert.NotAfter
        # Requires Application administrator or GLOBAL ADMIN
        $ServicePrincipal = New-AzureRMADServicePrincipal -ApplicationId $Application.ApplicationId 
        $GetServicePrincipal = Get-AzureRmADServicePrincipal -ObjectId $ServicePrincipal.Id

        # Sleep here for a few seconds to allow the service principal application to become active (ordinarily takes a few seconds)
        Sleep -s 15
        # Requires User Access Administrator or Owner.
        $NewRole = New-AzureRMRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $Application.ApplicationId -ErrorAction SilentlyContinue
        $Retries = 0;
        While ($NewRole -eq $null -and $Retries -le 6) {
            Sleep -s 10
            New-AzureRMRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $Application.ApplicationId | Write-Verbose -ErrorAction SilentlyContinue
            $NewRole = Get-AzureRMRoleAssignment -ServicePrincipalName $Application.ApplicationId -ErrorAction SilentlyContinue
            $Retries++;
        }
        return $Application.ApplicationId.ToString();
    }

    function CreateAutomationCertificateAsset ([string] $ResourceGroupName, [string] $automationAccountName, [string] $certifcateAssetName, [string] $certPath, [string] $certPlainPassword, [Boolean] $Exportable) {
        $CertPassword = ConvertTo-SecureString $certPlainPassword -AsPlainText -Force   
        Remove-AzureRmAutomationCertificate -ResourceGroupName $ResourceGroupName -AutomationAccountName $automationAccountName -Name $certifcateAssetName -ErrorAction SilentlyContinue
        New-AzureRmAutomationCertificate -ResourceGroupName $ResourceGroupName -AutomationAccountName $automationAccountName -Path $certPath -Name $certifcateAssetName -Password $CertPassword -Exportable:$Exportable  | write-verbose
    }

    function CreateAutomationConnectionAsset ([string] $ResourceGroupName, [string] $automationAccountName, [string] $connectionAssetName, [string] $connectionTypeName, [System.Collections.Hashtable] $connectionFieldValues ) {
        Remove-AzureRmAutomationConnection -ResourceGroupName $ResourceGroupName -AutomationAccountName $automationAccountName -Name $connectionAssetName -Force -ErrorAction SilentlyContinue
        New-AzureRmAutomationConnection -ResourceGroupName $ResourceGroupName -AutomationAccountName $automationAccountName -Name $connectionAssetName -ConnectionTypeName $connectionTypeName -ConnectionFieldValues $connectionFieldValues
    }

    Import-Module AzureRM.Profile
    Import-Module AzureRM.Resources

    $AzureRMProfileVersion = (Get-Module AzureRM.Profile).Version
    if (!(($AzureRMProfileVersion.Major -ge 3 -and $AzureRMProfileVersion.Minor -ge 4) -or ($AzureRMProfileVersion.Major -gt 3))) {
        Write-Error -Message "Please install the latest Azure PowerShell and retry. Relevant doc url : https://docs.microsoft.com/powershell/azureps-cmdlets-docs/ "
        return
    }

    #Connect-AzureRmAccount -Environment $EnvironmentName 
    $Subscription = Select-AzureRmSubscription -SubscriptionId $SubscriptionId

    # Create a Run As account by using a service principal
    $CertifcateAssetName = "AzureRunAsCertificate"
    $ConnectionAssetName = "AzureRunAsConnection"
    $ConnectionTypeName = "AzureServicePrincipal"

    if ($EnterpriseCertPathForRunAsAccount -and $EnterpriseCertPlainPasswordForRunAsAccount) {
        $PfxCertPathForRunAsAccount = $EnterpriseCertPathForRunAsAccount
        $PfxCertPlainPasswordForRunAsAccount = $EnterpriseCertPlainPasswordForRunAsAccount
    }
    else {
        $CertificateName = $AutomationAccountName + $CertifcateAssetName
        $PfxCertPathForRunAsAccount = Join-Path $env:TEMP ($CertificateName + ".pfx")
        $PfxCertPlainPasswordForRunAsAccount = $SelfSignedCertPlainPassword
        $CerCertPathForRunAsAccount = Join-Path $env:TEMP ($CertificateName + ".cer")
        CreateSelfSignedCertificate $CertificateName $PfxCertPlainPasswordForRunAsAccount $PfxCertPathForRunAsAccount $CerCertPathForRunAsAccount $SelfSignedCertNoOfMonthsUntilExpired
    }

    # Create a service principal
    $PfxCert = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList @($PfxCertPathForRunAsAccount, $PfxCertPlainPasswordForRunAsAccount)
    $ApplicationId = CreateServicePrincipal $PfxCert $ApplicationDisplayName

    # Create the Automation certificate asset
    CreateAutomationCertificateAsset $ResourceGroupName $AutomationAccountName $CertifcateAssetName $PfxCertPathForRunAsAccount $PfxCertPlainPasswordForRunAsAccount $true

    # Populate the ConnectionFieldValues
    $SubscriptionInfo = Get-AzureRmSubscription -SubscriptionId $SubscriptionId
    $TenantID = $SubscriptionInfo | Select TenantId -First 1
    $Thumbprint = $PfxCert.Thumbprint
    $ConnectionFieldValues = @{"ApplicationId" = $ApplicationId; "TenantId" = $TenantID.TenantId; "CertificateThumbprint" = $Thumbprint; "SubscriptionId" = $SubscriptionId}

    # Create an Automation connection asset named AzureRunAsConnection in the Automation account. This connection uses the service principal.
    CreateAutomationConnectionAsset $ResourceGroupName $AutomationAccountName $ConnectionAssetName $ConnectionTypeName $ConnectionFieldValues
        
    # Create an Runbook for Updating Modules
    New-AzureRmAutomationRunbook -Name "UpdateModuleRunbook" -Type PowerShell -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName
        
    #Importe powershell file to Runbooks
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Azure/RDS-Templates/ptg-autoscale/wvd-autoscale/scripts/updatemodules.ps1" -OutFile "c:\windows\temp\UpdateModules.ps1" 
    Import-AzureRmAutomationRunbook -Path "c:\windows\temp\UpdateModules.ps1" -Name "UpdateModuleRunbook" -Type PowerShell -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Force
        
    #Publishing Runbook
    Publish-AzureRmAutomationRunbook -Name "UpdateModuleRunbook" -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName

    #Providing parameter values to powershell script file
    $params = @{"AutomationResourceGroup" = $ResourceGroupName; "AutomationAccount" = $AutomationAccountName}
    Start-AzureRmAutomationRunbook -Name "UpdateModuleRunbook" -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Parameters $params
    #To check UpdateModuleRunbook Job executed or not
    Sleep -s 120
    $StatusUpdateModuleRunbookJob = Get-AzureRmAutomationJob -Name "UpdateModuleRunbook" -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName
    if ($StatusUpdateModuleRunbookJob.Status -eq "Completed") {
        Remove-AzureRmAutomationRunbook -Name "UpdateModuleRunbook" -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Force
    }
    Remove-Item -Path "c:\windows\temp\UpdateModules.ps1" -Force
            
}
#Check the Hostpool is DepthFirst or BreadthFirst Loadbalancing
if ($LoadBalancingBool) {
    $runbookName = $BreadthFirstRunbook
            
    $DeploymentStatus = New-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateUri "https://raw.githubusercontent.com/Azure/RDS-Templates/ptg-autoscale/wvd-autoscale/templates/runbookdeploy.json" -DeploymentDebugLogLevel All -existingAutomationAccountName $AutomationAccountName -runbookName $runbookName -breadthfirst $LoadBalancingBool -Force -Verbose
    if ($DeploymentStatus.ProvisioningState -eq "Succeeded") {
        $BFVariable = Get-AzureRmAutomationVariable -Name "BFWebhookURI" -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -ErrorAction SilentlyContinue
        if (!$BFVariable) {
            $Webhook = New-AzureRmAutomationWebhook -Name $BreadthFirstWebhook -RunbookName $runbookName -IsEnabled $True -ExpiryTime (get-date).AddYears(5) -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Force
            $WebhookURI = $Webhook.WebhookURI | Out-String
            $NewBFVariable = New-AzureRmAutomationVariable -Name "BFWebhookURI" -Encrypted $false -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Value $WebhookURI
            $BFVariable = Get-AzureRmAutomationVariable -Name "BFWebhookURI" -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -ErrorAction SilentlyContinue
        }

        $JobCollection = Get-AzureRmSchedulerJobCollection -ResourceGroupName $ResourceGroupName -JobCollectionName $JobCollectionName -ErrorAction SilentlyContinue
                        
        $requestBody = @{"RDBrokerURL" = $RDBrokerURL; "ResourceGroupName" = $ResourceGroupName; "Location" = $Location; "subscriptionid" = $subscriptionid; "TimeDifference" = $TimeDifference; "TenantGroupName" = $TenantGroupName; "fileURI" = $fileURI; "TenantName" = $TenantName; "HostPoolName" = $HostPoolName; "AADTenantId" = $AADTenantId; "AADApplicationId" = $AADApplicationId; "AADServicePrincipalSecret" = $AADServicePrincipalSecret; "BeginPeakTime" = $BeginPeakTime; "EndPeakTime" = $EndPeakTime; "MinimumNumberOfRDSH" = $MinimumNumberOfRDSH; "LimitSecondsToForceLogOffUser" = $LimitSecondsToForceLogOffUser; "LogOffMessageTitle" = $LogOffMessageTitle; "LogOffMessageBody" = $LogOffMessageBody; "SessionThresholdPerCPU" = $SessionThresholdPerCPU}
        $requestBodyJson = $requestBody | ConvertTo-Json
        $SchedulerDeployment = New-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateUri "https://raw.githubusercontent.com/Azure/RDS-Templates/ptg-autoscale/wvd-autoscale/templates/azureschedulerdeploy.json" -JobCollectionName $JobCollectionName -ActionURI $BFVariable.Value -StartTime (get-date).ToUniversalTime()  -JobName $HostpoolName-Job -EndTime Never -RecurrenceInterval $RecurrenceInterval -ActionSettingsBody $requestBodyJson -DeploymentDebugLogLevel All -Verbose


    }
}
            
else {
    $runbookName = $DepthFirstRunbook
    Write-Output $LoadBalancingBool

    $DeploymentStatus = New-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateUri "https://raw.githubusercontent.com/Azure/RDS-Templates/ptg-autoscale/wvd-autoscale/templates/runbookdeploy.json" -DeploymentDebugLogLevel All -existingAutomationAccountName $AutomationAccountName -runbookName $runbookName -breadthfirst $LoadBalancingBool -Force -Verbose
    if ($DeploymentStatus.ProvisioningState -eq "Succeeded") {
        $DFVariable = Get-AzureRmAutomationVariable -Name "DFWebhookURI" -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -ErrorAction SilentlyContinue
        if (!$DFVariable) {
            $Webhook = New-AzureRmAutomationWebhook -Name $DepthFirstWebhook -AutomationAccountName $AutomationAccountName -RunbookName $runbookName -IsEnabled $True -ExpiryTime (get-date).AddYears(5) -ResourceGroupName $ResourceGroupName -Force
            $WebhookURI = $Webhook.WebhookURI | Out-String
            $NewDFVariable = New-AzureRmAutomationVariable -Name "DFWebhookURI" -Encrypted $false -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Value $WebhookURI
            $DFVariable = Get-AzureRmAutomationVariable -Name "DFWebhookURI" -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -ErrorAction SilentlyContinue
        }

        $JobCollection = Get-AzureRmSchedulerJobCollection -ResourceGroupName $ResourceGroupName -JobCollectionName $JobCollectionName -ErrorAction SilentlyContinue
           
        $requestBody = @{"RDBrokerURL" = $RDBrokerURL; "ResourceGroupName" = $ResourceGroupName; "Location" = $Location; "subscriptionid" = $subscriptionid; "TenantGroupName" = $TenantGroupName; "fileURI" = $fileURI; "TenantName" = $TenantName; "HostPoolName" = $HostPoolName; "AADTenantId" = $AADTenantId; "AADApplicationId" = $AADApplicationId; "AADServicePrincipalSecret" = $AADServicePrincipalSecret; "BeginPeakTime" = $BeginPeakTime; "EndPeakTime" = $EndPeakTime; "MinimumNumberOfRDSH" = $MinimumNumberOfRDSH; "LimitSecondsToForceLogOffUser" = $LimitSecondsToForceLogOffUser; "LogOffMessageTitle" = $LogOffMessageTitle; "LogOffMessageBody" = $LogOffMessageBody}
        $requestBodyJson = $requestBody | ConvertTo-Json
        $SchedulerDeployment = New-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateUri "https://raw.githubusercontent.com/Azure/RDS-Templates/ptg-autoscale/wvd-autoscale/templates/azureschedulerdeploy.json" -JobCollectionName $JobCollectionName -ActionURI $DFVariable.Value -JobName $HostpoolName-Job -StartTime (get-date).ToUniversalTime() -EndTime Never -RecurrenceInterval $RecurrenceInterval -ActionSettingsBody $requestBodyJson -DeploymentDebugLogLevel All -Verbose


    }

}
