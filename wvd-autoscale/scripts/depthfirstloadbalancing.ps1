Param(

[Parameter(Mandatory = $false)]
[object]$WebHookData

)

# If runbook was called from Webhook, WebhookData will not be null.
if ($WebHookData){

    # Collect properties of WebhookData
    $WebhookName = $WebHookData.WebhookName
    $WebhookHeaders = $WebHookData.RequestHeader
    $WebhookBody = $WebHookData.RequestBody

    # Collect individual headers. Input converted from JSON.
    $From = $WebhookHeaders.From
    $Input = (ConvertFrom-Json -InputObject $WebhookBody)
    Write-Verbose "WebhookBody: $Input"
}
else
{
   Write-Error -Message 'Runbook was not started from Webhook' -ErrorAction stop
}

$RDBrokerURL = $Input.RDBrokerURL
$AADTenantId = $Input.AADTenantId
$AADApplicationId = $Input.AADApplicationId
$AADServicePrincipalSecret = $Input.AADServicePrincipalSecret
$SubscriptionID = $Input.SubscriptionID
$ResourceGroupName = $Input.ResourceGroupName
$Location = $Input.Location
$TenantGroupName = $Input.TenantGroupName
$TenantName = $Input.TenantName
$BeginPeakTime = $Input.BeginPeakTime
$fileURI = $Input.fileURI
$EndPeakTime = $Input.EndPeakTime
$TimeDifference = $Input.TimeDifference
$MinimumNumberOfRDSH = $Input.MinimumNumberOfRDSH
$LimitSecondsToForceLogOffUser = $Input.LimitSecondsToForceLogOffUser
$LogOffMessageTitle = $Input.LogOffMessageTitle
$LogOffMessageBody = $Input.LogOffMessageBody
$HostpoolName = $Input.HostpoolName


Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope Process -Force -Confirm:$false
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine -Force -Confirm:$false
$PolicyList=Get-ExecutionPolicy -List
$log = $PolicyList | Out-String


if(!(Test-Path -Path "C:\WVDAutoScale-$HostpoolName")){
  
    Invoke-WebRequest -Uri $fileURI -OutFile "C:\WVDAutoScale-$HostpoolName.zip"
    New-Item -Path "C:\WVDAutoScale-$HostpoolName" -ItemType Directory -Force -ErrorAction SilentlyContinue
    Expand-Archive "C:\WVDAutoScale-$HostpoolName.zip" -DestinationPath "C:\WVDAutoScale-$HostpoolName" -ErrorAction SilentlyContinue
    }

 $DateTime = Get-Date -Format "MM-dd-yy HH:mm"
 $DateFilename = $DateTime.Replace(":","-")
function Write-Log {
  [CmdletBinding()]
  param(
      [Parameter(mandatory = $false)]
    [string]$Message,
    [Parameter(mandatory = $false)]
    [string]$Error
  )
  try {
    $DateTime = Get-Date -Format "MM-dd-yy HH:mm:ss"
    $Invocation = "$($MyInvocation.MyCommand.Source):$($MyInvocation.ScriptLineNumber)"
    if ($Message) {
     Add-Content -Value "$DateTime - $Invocation - $Message" -Path "C:\WVDAutoScale-$hostpoolname\ScriptLog-$DateFilename.log"
    }
    else {
     Add-Content -Value "$DateTime - $Invocation - $Error" -Path "C:\WVDAutoScale-$hostpoolname\ScriptLog-$DateFilename.log"
    }
  }
  catch {
  Write-Error $_.Exception.Message
  }
}




#$CurrentPath = Split-Path $script:MyInvocation.MyCommand.Path
$CurrentPath = "C:\WVDAutoScale-$HostpoolName"

#Load WVD Modules
Set-Location "$CurrentPath\RDPowershell"
Import-Module ".\Microsoft.RdInfra.RdPowershell.dll"

#The the following three lines is to use password/secret based authentication for service principal, to use certificate based authentication, please comment those lines, and uncomment the above line
$secpasswd = ConvertTo-SecureString $AADServicePrincipalSecret -AsPlainText -Force
$appCredentials = New-Object System.Management.Automation.PSCredential ($AADApplicationId, $secpasswd)


$CurrentDateTime = Get-Date
$BeginPeakDateTime = [DateTime]::Parse($CurrentDateTime.ToShortDateString() + ' ' + $BeginPeakTime)
$EndPeakDateTime = [DateTime]::Parse($CurrentDateTime.ToShortDateString() + ' ' + $EndPeakTime)
	
    
#check the calculated end time is later than begin time in case of time zone
if ($EndPeakDateTime -lt $BeginPeakDateTime) {
    $EndPeakDateTime = $EndPeakDateTime.AddDays(1)
}	


# Setting to Tls12 due to Azure web app security requirements
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


#Authenticating to WVD
$authentication = Add-RdsAccount -DeploymentUrl $RDBrokerURL -Credential $appCredentials -ServicePrincipal -TenantId $AadTenantId 
$obj = $authentication | Out-String

if ($authentication) {
    Write-Log -Message "WVD Authentication successfully Done. Result:`n$obj"  
}
else {
    Write-Log -Error "WVD Authentication Failed, Error:`n$obj"
        
}

#Authenticating to Azure
$TenantLogin = connect-AzureRmAccount -Credential $appCredentials -TenantId $AadTenantId -ServicePrincipal
$obj1 = $TenantLogin | Out-String

if ($authentication) {
    Write-Log -Message "AzureRm Authentication successfully Done. Result:`n$obj1"  
}
else {
    Write-Log -Error "AzureRm Authentication Failed, Error:`n$obj1"
        
}				

# Set context to the appropriate tenant group
Write-Log -Message "Running switching to the $TenantGroupName context"
Set-RdsContext -TenantGroupName $TenantGroupName

#Get the Hostpool in the tenant
try {
        
    $hostpoolinfo = Get-RdsHostPool -TenantName $tenantname -Name $hostpoolname
    #validate hostpool is depth first or not
    if ($hostpoolinfo.LoadBalancerType -ne "DepthFirst") {
        Write-Log -Message "Hostpool '$hostpoolname' loadbalancing type is $($hostpoolinfo.LoadBalancerType | out-string), script execution will stop"
        exit        
    }
        
}
catch {
        
    Write-Log -Error  "Failed to retrieve hostpool in Tenant $($hostPoolName) : $($_.exception.message)"
    Exit
}




if ($CurrentDateTime -ge $BeginPeakDateTime -and $CurrentDateTime -le $EndPeakDateTime) {
    
    Write-Host "It is in peak hours now"
    Write-Log -Message "Peak hours: starting session hosts as needed based on current workloads."
    
    $hostpoolMaxSessionLimit = $hostpoolinfo.MaxSessionLimit
    #Get the session hosts in the hostpool
    try {
    
        $getHosts = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostpoolname | Sort-Object $_.sessionhostname
        
    }
    catch {
        Write-Log -Error  "Failed to retrieve sessionhost in hostpool $($hostPoolName) : $($_.exception.message)"
        Exit
    }

    if ($hostpoolMaxSessionLimit -eq 2) {
        $sessionlimit = $hostpoolMaxSessionLimit - 1
    }
    else {
        $sessionlimitofhost = $hostpoolMaxSessionLimit / 4
        $var = $hostpoolMaxSessionLimit - $sessionlimitofhost
        $sessionlimit = [math]::Round($var)
    }

   
    #check the number of running session hosts
    $numberOfRunningHost = 0
		
       
    foreach ($sessionHost in $getHosts) {
        Write-Log -Message  "Checking session host: `n $($sessionHost.SessionHostName | Out-String)"
        $sessionhost.Sessions
        $sessionCapacityofhost = $sessionhost.Sessions
        if ($sessionlimit -lt $sessionCapacityofhost -or $sessionHost.Status -eq "Available") {
                   
            $numberOfRunningHost = $numberOfRunningHost + 1
                           
        }
       
    }
    write-log -Message "Current number of running hosts: $numberOfRunningHost"
    if ($numberOfRunningHost -lt $MinimumNumberOfRDSH) {
        Write-Log -Message  "Current number of running session hosts is less than minimum requirements, start session host ..."
    
        foreach ($sessionhost in $getHosts) {
            #$hostofsessions = read-host "enter session value" # $sessionhost.sessions
            if ($numberOfRunningHost -lt $MinimumNumberOfRDSH) {
            $hostsessions = $sessionHost.Sessions
            if ($hostpoolMaxSessionLimit -ne $hostofsessions) {
                if ($sessionhost.Status -eq "UnAvailable") {
                    $sessionhostname = $sessionhost.sessionhostname
                    #Check session host is in Drain Mode
                    $checkAllowNewSession = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostpoolname -Name $sessionhostname
                    if (!($checkAllowNewSession.AllowNewSession)) {
                        Set-RdsSessionHost -TenantName $tenantname -HostPoolName $hostpoolname -Name $sessionhostname -AllowNewSession $true
                    }
                    $VMName = $sessionHostname.Split(".")[0]
           
                    #start the azureRM VM
                    try {
                     Get-AzureRmVM | Where-Object {$_.Name -eq $VMName} | Start-AzureRmVM
									
                    }
                    catch {
                        Write-Log -Error  "Failed to start Azure VM: $($VMName) with error: $($_.exception.message)"                            
                        Exit
                    }
                    
                    }
                   
                }
                $numberOfRunningHost = $numberOfRunningHost + 1
            }
                        
        }
        write-log -Message "$hostPoolName $numberOfRunningHost"
    }
    
    else {
            $getHosts = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostpoolname | Sort-Object "Sessions" -Descending
           
            foreach ($sessionhost in $getHosts) {
              if (!($sessionHost.Sessions -eq $hostpoolMaxSessionLimit)) {
                if ($sessionHost.Sessions -ge $sessionlimit) {
                foreach ($sessionhost in $getHosts) {
                    if($sessionhost.Status -eq "Available" -and $sessionHost.Sessions -eq 0){break}                    
                    if ($sessionhost.Status -eq "Unavailable") {
                        
                        Write-Log -Message "Sessionhost Sessions value reached 75% of hostpool maximumsession limit need to start the session host"
                        $sessionhostname = $sessionhost.sessionhostname
                        #Check session host is in Drain Mode
                        $checkAllowNewSession = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostpoolname -Name $sessionhostname
                        if (!($checkAllowNewSession.AllowNewSession)) {
                            Set-RdsSessionHost -TenantName $tenantname -HostPoolName $hostpoolname -Name $sessionhostname -AllowNewSession $true
                        }
                        $VMName = $sessionHostname.Split(".")[0]
           
                        #start the azureRM VM
                        try {
                            Get-AzureRmVM | Where-Object {$_.Name -eq $VMName} | Start-AzureRmVM
									
                        }
                        catch {
                            Write-Log -Error  "Failed to start Azure VM: $($VMName) with error: $($_.exception.message)"                            
                            Exit
                        }
                        #wait for the sessionhost is available
                        $IsHostAvailable = $false
                        while (!$IsHostAvailable) {
									
                            $hoststatus = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostpoolname -Name $sessionHost.SessionHostName
									
                            if ($hoststatus.Status -eq "Available") {
                                $IsHostAvailable = $true
                            }
                            }
                        $numberOfRunningHost = $numberOfRunningHost + 1
                        break
                        }
                    }
                }
            }
                        

        }
    }
    Write-Log -Message $hostpoolname $numberOfRunningHost
    
} 
    
else {
    Write-Log -Message "It is Off-peak hours"
    Write-Log -Message "It is off-peak hours. Starting to scale down RD session hosts..."
    Write-Log -Message ("Processing hostPool {0}" -f $hostPoolName)
    try {
        $getHosts = Get-RdsSessionHost -TenantName $tenantName -HostPoolName $hostPoolName | Sort-Object Sessions
                       
    }
    catch {
        Write-Log -Error "Failed to retrieve session hosts in hostPool: $($hostPoolName) with error: $($_.exception.message)"
        Exit
    }

    #check the number of running session hosts
    $numberOfRunningHost = 0
    
    
    foreach ($sessionHost in $getHosts) {
       
        if ($sessionHost.Status -eq "Available") {
                   
            $numberOfRunningHost = $numberOfRunningHost + 1
            
            
        }

        
    }

    if ($numberOfRunningHost -gt $MinimumNumberOfRDSH) {
    
        foreach ($sessionHost in $getHosts.SessionHostName) {
            if ($numberOfRunningHost -gt $MinimumNumberOfRDSH) {

                $sessionHostinfo1 = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostpoolname -Name $sessionHost
                if ($sessionHostinfo1.status -eq "Available") {
                         
                    #ensure the running Azure VM is set as drain mode
                    try {
                                                                               
                        #setting host in drain mode
                        Set-RdsSessionHost -TenantName $tenantName -HostPoolName $hostPoolName -Name $sessionHost -AllowNewSession $false -ErrorAction SilentlyContinue
                    } 
                    catch {
                        Write-Log -Error  "Failed to set drain mode on session host: $($sessionHost.SessionHost) with error: $($_.exception.message)"
                        Exit
                    }
								
                    #notify user to log off session
                    #Get the user sessions in the hostPool
                    try {
                                        
                        $hostPoolUserSessions = Get-RdsUserSession -TenantName $tenantName -HostPoolName $hostPoolName
                                       
                    }
                    catch {
                        Write-ouput "Failed to retrieve user sessions in hostPool: $($hostPoolName) with error: $($_.exception.message)"
                        Exit
                    }
									
                    Write-Log -Message "Counting the current sessions on the host..."
                    $existingSession = 0
                    foreach ($session in $hostPoolUserSessions) {
                        if ($session.SessionHostName -eq $sessionHost) {
                            if ($LimitSecondsToForceLogOffUser -ne 0) {
                                #send notification
                                try {
                                           
                                    Send-RdsUserSessionMessage -TenantName $tenantName -HostPoolName $hostPoolName -SessionHostName $session.SessionHostName -SessionId $session.sessionid -MessageTitle $LogOffMessageTitle -MessageBody "$($LogOffMessageBody) You will logged off in $($LimitSecondsToForceLogOffUser) seconds." -NoUserPrompt:$false
                                    
                                     
                                }
                                catch {
                                    Write-Log -Error  "Failed to send message to user with error: $($_.exception.message)"
                                    Exit
                                }
                            }
											
                            $existingSession = $existingSession + 1
                        }
                    }
                            
                    #wait for n seconds to log off user
                    Start-Sleep -Seconds $LimitSecondsToForceLogOffUser


                    if ($LimitSecondsToForceLogOffUser -ne 0) {
                        #force users to log off
                        Write-Log -Message  "Force users to log off..."
                        try {
                            $hostPoolUserSessions = Get-RdsUserSession -TenantName $tenantName -HostPoolName $hostPoolName
                                            
                        }
                        catch {
                            Write-Log -Error "Failed to retrieve list of user sessions in hostPool: $($hostPoolName) with error: $($_.exception.message)"
                            Exit
                        }
                        foreach ($session in $hostPoolUserSessions) {
                            if ($session.SessionHostName -eq $sessionHost) {
                                #log off user
                                try {
    													
                                    Invoke-RdsUserSessionLogoff -TenantName $tenantName -HostPoolName $hostPoolName -SessionHostName $session.SessionHostName -SessionId $session.SessionId -NoUserPrompt:$false
                                    $existingSession = $existingSession - 1
                                    
                                }
                                catch {
                                    Write-ouput "Failed to log off user with error: $($_.exception.message)"
                                    Exit
                                }
                            }
                        }
                    }

                    $VMName = $sessionHost.Split(".")[0]

                    #check the session count before shutting down the VM
                    if ($existingSession -eq 0) {
										
                                
                        #shutdown the Azure VM
                        try {
                            Get-AzureRmVM | Where-Object {$_.Name -eq $VMName} | Stop-AzureRmVM -Force
											
                        }
                        catch { 
                            Write-Log -Error "Failed to stop Azure VM: $VMName with error: $_.exception.message"
                            Exit
                        }

                    }
                    #decrement the number of running session host
                    $numberOfRunningHost = $numberOfRunningHost - 1
    
                }
    
            }
    
        }
        Write-Log -Message $hostpoolname $numberOfRunningHost
    }
}

#Create an storage account to store Auto Scale Script Logs
$StorageAccountName = "autoscalestrgaccount"
$stoagecontainername = "scriptlogcontainer"
$storageaccount = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction SilentlyContinue 
$filepath = "C:\WVDAutoScale-$hostpoolname\ScriptLog-$DateFilename.log"
if(!$storageaccount)
{
    $storageaccount = New-azurermstorageaccount -ResourceGroupName $ResourceGroupName -Name $storageaccountname -SkuName Standard_LRS -Location $Location -Kind BlobStorage -AccessTier Cool 
    $storagecontainer = New-AzureRmStorageContainer -ResourceGroupName $ResourceGroupName -AccountName $storageaccountname -Name $stoagecontainername -PublicAccess Blob
    Set-AzureStorageBlobContent -Container $storagecontainer.Name -File $filepath -Blob "$hostpoolname\ScriptLog-$DateFilename.log" -Context $storageaccount.Context -Force
    
}
else
{
    $storagecontainer = Get-AzureRmStorageContainer -ResourceGroupName $ResourceGroupName -AccountName $storageaccountname -Name $stoagecontainername -ErrorAction SilentlyContinue
    if(!$storagecontainer)
    {
        $storagecontainer = New-AzureRmStorageContainer -ResourceGroupName $ResourceGroupName -AccountName $storageaccountname -Name $stoagecontainername -PublicAccess Blob
        Set-AzureStorageBlobContent -Container $storagecontainer.Name -File $filepath -Blob "$hostpoolname\ScriptLog-$DateFilename.log" -Context $storageaccount.Context -Force
    }
    else
    {
        Set-AzureStorageBlobContent -Container $storagecontainer.Name -File $filepath -Blob "$hostpoolname\ScriptLog-$DateFilename.log" -Context $storageaccount.Context -Force
    }
}