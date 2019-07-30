<#

.SYNOPSIS
Get the Logs from Diagnostics-UX deployment

.DESCRIPTION
This script is used to get the logs from the Diagnostics-UX deployment

.ROLE
Administrator

#>

Param(

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $WebappName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $SubscriptionId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $DestinationFolderPath

)

# Set the ExecutionPolicy
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine -Force -Confirm:$false 

# Import the Az module
Import-Module Az

# Provide the Azure credentials
$Credential=Get-Credential

# Authenticate to Azure
Login-AzAccount -Credential $Credential

# Select the specified subscription
Select-AzSubscription -SubscriptionId $SubscriptionId

# Fetch the authenticated user role whether Owner or Contributor
$RoleAssignment=Get-AzRoleAssignment -SignInName $Credential.UserName

if($RoleAssignment.RoleDefinitionName -eq "Owner" -or $RoleAssignment.RoleDefinitionName -eq "Contributor")
{
# Fetch the webapp you specified from the list of webapps in your subscription
$webapp = Get-AzWebApp | Where-Object {$_.Name -eq $WebappName}

# Get the resource group of webapp you created
$resourceGroupName= $Webapp.ResourceGroup

if ($webapp) {
    Write-Output "Fetching the logs from the webapp"

    # Function to get Publishing Profile Credentials
	function Get-PublishingProfileCredentials($resourceGroupName, $WebappName)
    {
    $resourceType = "Microsoft.Web/sites/config"
    $resourceName = "$WebappName/publishingcredentials"
    $publishingCredentials = Invoke-AzResourceAction -ResourceGroupName $resourceGroupName -ResourceType $resourceType -ResourceName $resourceName -Action list -ApiVersion 2015-08-01 -Force
    return $publishingCredentials
    } 
 
	# Function to get Kudu Api Authorisation Header Value
	function Get-KuduApiAuthorisationHeaderValue($resourceGroupName, $WebappName, $slotName = $null)
    {
    $publishingCredentials = Get-PublishingProfileCredentials $resourceGroupName $WebappName $slotName
    return ("Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $publishingCredentials.Properties.PublishingUserName, $publishingCredentials.Properties.PublishingPassword))))
    }

	# Function to confirm files are uploaded or not in web app service
	function RunCommand($dir,$command,$resourceGroupName, $WebappName, $slotName = $null)
    {
        $kuduApiAuthorisationToken = Get-KuduApiAuthorisationHeaderValue $resourceGroupName $WebappName $slotName
        $kuduApiUrl="https://$WebappName.scm.azurewebsites.net/api/command"
        $Body = 
          @{
          "command"=$command;
           "dir"=$dir
           } 
        $bodyContent=@($Body) | ConvertTo-Json

        Invoke-RestMethod -Uri $kuduApiUrl -Headers @{"Authorization"=$kuduApiAuthorisationToken;"If-Match"="*"} -Method POST -ContentType "application/json" -Body $bodyContent
    }

    # Fetch the Logs in site\wwwroot directory
    $returnvalue = RunCommand -dir "site\wwwroot\" -command "ls Logs"  -resourceGroupName $resourceGroupName -webAppName $WebappName

    # If the log files exist in directory proceed to download to the DestinationFolderpath
	if($returnvalue.output)
	{
        # Function to Download File From WebApp
        function Download-FileFromWebApp($resourceGroupName, $WebappName, $slotName = "", $kuduPath, $localPath){
        $kuduApiAuthorisationToken = Get-KuduApiAuthorisationHeaderValue $resourceGroupName $webAppName $slotName
        if ($slotName -eq ""){
            $kuduApiUrl = "https://$webAppName.scm.azurewebsites.net/api/vfs/site/wwwroot/$kuduPath"
        }
        else{
            $kuduApiUrl = "https://$webAppName.scm.azurewebsites.net/api/vfs/site/wwwroot/$kuduPath"
        }
        $virtualPath = $kuduApiUrl.Replace(".scm.azurewebsites.", ".azurewebsites.").Replace("/api/vfs/site/wwwroot", "")
        Write-Host "Downloading File from WebApp. Source: '$virtualPath' and Target: '$DestinationFolderPath'"  

        if(!(Get-ChildItem -Path $DestinationFolderPath -ErrorAction SilentlyContinue))
        {
            New-Item -ItemType Directory -Path $DestinationFolderPath -Force 
        }
        $timestamp = Get-Date -f dd-MM-yyyy_HH_mm_ss
        Invoke-RestMethod -Uri $kuduApiUrl `
                            -Headers @{"Authorization"=$kuduApiAuthorisationToken;"If-Match"="*"} `
                            -Method GET `
                           -OutFile "$DestinationFolderPath\diaguxlogs-$timestamp.log" 
                       
        }
        Download-FileFromWebApp $resourceGroupName $WebappName $slotName $kuduPath $localPath
        Write-Output "Diagnostics-ux log file is successfully downloaded to $DestinationFolderPath"
	}
    }
    else
    {
    Write-output "Log files does not exist: $returnvalue.error"
    throw $returnvalue.error
    }
}
else
{
Write-Output "Authenticated user should have the Owner/Contributor permissions"
}


