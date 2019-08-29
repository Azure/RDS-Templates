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

# Get the context
$context= Get-AzContext
if($context -eq $null)
{
  Write-Error "Please authenticate to Azure using Login-AzAccount cmdlet and then run this script"
  exit
}

# Select the specified subscription
Select-AzSubscription -SubscriptionId $SubscriptionId

# Fetch the authenticated user role whether Owner or Contributor
$RoleAssignment=Get-AzRoleAssignment -SignInName $Credential.UserName

if($RoleAssignment.RoleDefinitionName -eq "Owner" -or $RoleAssignment.RoleDefinitionName -eq "Contributor")
{
    # Fetch the webapp you specified from the list of webapps in your subscription
    $webapp = Get-AzWebApp | Where-Object {$_.Name -eq $WebappName}

    # Get the resource group of webapp you created
    $resourceGroupName= $webapp.ResourceGroup
    if ($webapp) 
        {
            Write-Output "Fetching logs from Web Application"

            # Function to get Publishing Profile Credentials
	        function Get-PublishingProfileCredentials($resourceGroupName, $WebappName)
            {
            $resourceType = "Microsoft.Web/sites/config"
            $resourceName = "$WebappName/publishingcredentials"
            $publishingCredentials = Invoke-AzResourceAction -ResourceGroupName $resourceGroupName -ResourceType $resourceType -ResourceName $resourceName -Action list -ApiVersion 2015-08-01 -Force
            return $publishingCredentials
            } 
 
	        # Function to get Kudu Api Authorisation Header Value
	        function Get-KuduApiAuthorisationHeaderValue($resourceGroupName, $WebappName)
            {
            $publishingCredentials = Get-PublishingProfileCredentials $resourceGroupName $WebappName
            $base64AuthInfo = ("Basic {0}" -f [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes((“{0}:{1}” -f $publishingCredentials.properties.publishingUserName, $publishingCredentials.properties.publishingPassword))))
            return $base64AuthInfo
            }

	        # Function to confirm files are uploaded or not in web app service
	        function RunCommand($dir,$command,$resourceGroupName, $WebappName)
            {
                $kuduApiAuthorisationToken = Get-KuduApiAuthorisationHeaderValue $resourceGroupName $WebappName 
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
    
            # If the log files exist in directory proceed to download log files to the DestinationFolderpath
	        if($returnvalue.output)
	        {
                # Function to Download log files From WebApp
                function Download-FileFromWebApp($resourceGroupName, $WebappName, $DestinationFolderPath)
                {
                    # Get the kuduApiAuthorisationToken
                    $kuduApiAuthorisationToken = Get-KuduApiAuthorisationHeaderValue $resourceGroupName $webAppName 

                    # Set the kuduApiUrl
                    $kuduApiUrl = "https://$webAppName.scm.azurewebsites.net/api/vfs/site/wwwroot/Logs/"

                    # Define the webapp url
                    $webappurl = $kuduApiUrl.Replace(".scm.azurewebsites.", ".azurewebsites.").Replace("/api/vfs/site/wwwroot", "")
                    Write-Host "Downloading File from WebApp. Source: '$webappurl' and Target: '$DestinationFolderPath'"  

                    # Check whether the DestinationFolderPath exist/not
                    if(!(Test-Path $DestinationFolderPath))
                    {
                        New-Item -ItemType Directory -Path $DestinationFolderPath -Force 
                    }
                    $userAgent = “powershell/2.0”

                    # Get the log fils existed in webapp filesystem
                    $rootContent = Invoke-RestMethod –Uri $kuduApiUrl –Headers @{"Authorization"=$kuduApiAuthorisationToken;"If-Match"="*"} –UserAgent $userAgent –Method GET –ContentType “application/json” 

                    # Download the log files to the DestinationFolderPath recursively
                    for($i=0; $i -lt $rootContent.Count; $i++)
                    {
                        $timestamp = Get-Date -f dd-MM-yyyy_HH_mm_ss

                        # Get the content of the log files
                        $childContent = Invoke-RestMethod –Uri $rootContent[$i].href –Headers @{"Authorization"=$kuduApiAuthorisationToken;"If-Match"="*"} –UserAgent $userAgent –Method GET –ContentType “text/plain”
                        $path = "$DestinationFolderPath\diaguxlogs-$timestamp.txt"
                        Start-Sleep 2
                        set-content -path $path $childContent

                    }              
                }
                Download-FileFromWebApp -resourceGroupName $resourceGroupName -WebappName $WebappName -DestinationFolderPath $DestinationFolderPath
                Write-Output "Diagnostics-ux log files are successfully downloaded to $DestinationFolderPath"
	        }
        }
    else
    {
        Write-output $returnvalue.error
    }
}
else
{
Write-Output "Authenticated user should have the Owner/Contributor permissions"
}
