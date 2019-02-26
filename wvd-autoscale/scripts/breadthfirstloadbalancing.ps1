Param(

    [Parameter(Mandatory = $false)]
    [object]$WebHookData

)

# If runbook was called from Webhook, WebhookData will not be null.
if ($WebHookData) {

    # Collect properties of WebhookData
    $WebhookName = $WebHookData.WebhookName
    $WebhookHeaders = $WebHookData.RequestHeader
    $WebhookBody = $WebHookData.RequestBody

    # Collect individual headers. Input converted from JSON.
    $From = $WebhookHeaders.From
    $Input = (ConvertFrom-Json -InputObject $WebhookBody)
    Write-Verbose "WebhookBody: $Input"
    Write-Output -InputObject ('Runbook started from webhook {0} by {1}.' -f $WebhookName, $From)
}
else {
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
$SessionThresholdPerCPU = $Input.SessionThresholdPerCPU
$MinimumNumberOfRDSH = $Input.MinimumNumberOfRDSH
$LimitSecondsToForceLogOffUser = $Input.LimitSecondsToForceLogOffUser
$LogOffMessageTitle = $Input.LogOffMessageTitle
$LogOffMessageBody = $Input.LogOffMessageBody
$HostpoolName = $Input.HostpoolName


Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope Process -Force -Confirm:$false
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine -Force -Confirm:$false
$PolicyList = Get-ExecutionPolicy -List
$log = $PolicyList | Out-String


if (!(Test-Path -Path "C:\WVDAutoScale-$HostpoolName")) {
  
    Invoke-WebRequest -Uri $fileURI -OutFile "C:\WVDAutoScale-$HostpoolName.zip"
    New-Item -Path "C:\WVDAutoScale-$HostpoolName" -ItemType Directory -Force -ErrorAction SilentlyContinue
    Expand-Archive "C:\WVDAutoScale-$HostpoolName.zip" -DestinationPath "C:\WVDAutoScale-$HostpoolName" -ErrorAction SilentlyContinue
}

$DateTime = Get-Date -Format "MM-dd-yy HH:mm"
$DateFilename = $DateTime.Replace(":", "-")
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
$appcreds = New-Object System.Management.Automation.PSCredential ($AADApplicationId, $secpasswd)

#Login-AzureRmAccount -ServicePrincipal -Credential $appcreds -TenantId $AADTenantId #-Subscription $CurrentAzureSubscriptionName
Connect-AzureRmAccount -ServicePrincipal -Credential $appcreds -TenantId $AADTenantId

#select the current Azure Subscription specified in the config
#Select-AzureRmSubscription -SubscriptionId $SubscriptionID

#Construct Begin time and End time for the Peak period
#$CurrentDateTime = Get-Date
$CurrentDateTime = Get-Date
$CurrentDateTime = $CurrentDateTime.ToUniversalTime()
write-log -Message "Starting WVD Tenant Hosts Scale Optimization: Current Date Time is: $CurrentDateTime" 

$TimeDifferenceInHours = $TimeDifference.Split(":")[0]
$TimeDifferenceInMinutes = $TimeDifference.Split(":")[1]
#Azure is using UTC time, justify it to the local time
$CurrentDateTime = $CurrentDateTime.AddHours($TimeDifferenceInHours).AddMinutes($TimeDifferenceInMinutes)
	
$BeginPeakDateTime = [DateTime]::Parse($CurrentDateTime.ToShortDateString() + ' ' + $BeginPeakTime)
	
$EndPeakDateTime = [DateTime]::Parse($CurrentDateTime.ToShortDateString() + ' ' + $EndPeakTime)
	
    
#check the calculated end time is later than begin time in case of time zone
if ($EndPeakDateTime -lt $BeginPeakDateTime) {
    $EndPeakDateTime = $EndPeakDateTime.AddDays(1)
}	

#authenticate to WVD
try {
    Add-RdsAccount -DeploymentUrl $RDBrokerURL -ServicePrincipal -Credential $appcreds -TenantId $AADTenantId
    
}
catch {
    write-log -Error "WVD authentication Failed: $($_.exception.message)"
    Exit 1
}


#Login to Azure
try {
    Add-AzureRmAccount -ServicePrincipal -Credential $appcreds -TenantId $AADTenantId -SubscriptionId $SubscriptionID
				
}
catch {
    write-output "Failed to retrieve deployment information from Azure with error: $($_.exception.message)" 
    Exit 1
}
			


#Set context to the appropriate tenant group
Write-Log "Running switching to the $TenantGroupName context"
Set-RdsContext -TenantGroupName $TenantGroupName

	
#check if it is during the peak or off-peak time
if ($CurrentDateTime -ge $BeginPeakDateTime -and $CurrentDateTime -le $EndPeakDateTime) {
    write-log -Message "It is in peak hours now"
    write-log -Message "Peak hours: starting session hosts as needed based on current workloads." 
    
    #Get the Session Hosts in the hostPool
    try {
        $RDSessionHost = Get-RdsSessionHost -TenantName $tenantName -HostPoolName $hostPoolName -ErrorAction SilentlyContinue
          
            
    }
    catch {
        write-output "Failed to retrieve RDS session hosts in hostPool $($hostPoolName) : $($_.exception.message)" 
        Exit 1
    }
		
    #Get the User Sessions in the hostPool
    try {    
        $hostPoolUserSessions = Get-RdsUserSession -TenantName $tenantName -HostPoolName $hostPoolName
              
    }
    catch {
        write-output "Failed to retrieve user sessions in hostPool:$($hostPoolName) with error: $($_.exception.message)" 
        Exit 1
    }
		
    #check the number of running session hosts
    $numberOfRunningHost = 0
		
    #total of running cores
    $totalRunningCores = 0
		
    #total capacity of sessions of running VMs
    $AvailableSessionCapacity = 0
	
    write-log -Message "Looping thru available hostpool hosts list ..." 
    foreach ($sessionHost in $RDSessionHost.SessionHostName) {
        write-log -Message "Checking session host: $($sessionHost)"
			
       			 
        $VMName = $sessionHost.Split(".")[0]
        $roleInstance = Get-AzureRmVM -Status | Where-Object {$_.Name.Contains($VMName)} | Select-Object -Unique
                 
        if ($sessionHost.ToLower().Contains($roleInstance.Name.ToLower())) {   
            #check the azure vm is running or not      
            if ($roleInstance.PowerState -eq "VM running") {
                $numberOfRunningHost = $numberOfRunningHost + 1
						
                #we need to calculate available capacity of sessions
						
						
                $roleSize = Get-AzureRmVMSize -Location $roleInstance.Location | Where-Object {$_.Name -eq $roleInstance.HardwareProfile.VmSize}
                       
						
                $AvailableSessionCapacity = $AvailableSessionCapacity + $roleSize.NumberOfCores * $SessionThresholdPerCPU
						
                $totalRunningCores = $totalRunningCores + $roleSize.NumberOfCores
            }
            #Break # break out of the inner foreach loop once a match is found and checked
        }
    }
    
		
    write-log -Message "Current number of running hosts: $numberOfRunningHost"
		
    if ($numberOfRunningHost -lt $MinimumNumberOfRDSH) {
			
        write-log -Message "Current number of running session hosts is less than minimum requirements, start session host ..." 
		
        	
        #start VM to meet the minimum requirement            
        foreach ($sessionHost in $RDSessionHost.SessionHostName) {
				
				         
            #check whether the number of running VMs meets the minimum or not
            if ($numberOfRunningHost -lt $MinimumNumberOfRDSH) {
					
                #foreach ($roleInstance in $Deployment)
                #{
                $VMName = $sessionHost.Split(".")[0]
                $roleInstance = Get-AzureRmVM -Status | Where-Object {$_.Name.Contains($VMName)} | Select-Object -Unique
                        
                if ($sessionHost.ToLower().Contains($roleInstance.Name.ToLower())) {
							
                    #check if the azure VM is running or not
							
                    if ($roleInstance.PowerState -ne "VM running") {
                        $getShsinfo = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostPoolName -Name $sessionHost
                                
                        if ($getShsinfo.AllowNewSession -eq $false) {
                            Set-RdsSessionHost -TenantName $tenantName -HostPoolName $hostPoolName -Name $sessionHost -AllowNewSession $true

                        }


                        #start the azure VM
                        try {
                            Start-AzureRmVM -Name $roleInstance.Name -Id $roleInstance.Id -ErrorAction SilentlyContinue
									
                        }
                        catch {
                            write-output "Failed to start Azure VM: $($roleInstance.Name) with error: $($_.exception.message)" 
                            Exit 1
                        }
								
                        #wait for the VM to start
                        $IsVMStarted = $false
                        while (!$IsVMStarted) {
									
                            $vm = Get-AzureRmVM -Status | Where-Object { $_.Name -eq $roleInstance.Name }
									
                            if ($vm.PowerState -eq "VM running" -and $vm.ProvisioningState -eq "Succeeded") {
                                $IsVMStarted = $true
                            }
                            #wait for 15 seconds
                            #Start-Sleep -Seconds 15
                        }
								
                        # we need to calculate available capacity of sessions
								
                        $vm = Get-AzureRmVM -Status | Where-Object { $_.Name -eq $roleInstance.Name }
								
                        $roleSize = Get-AzureRmVMSize -Location $roleInstance.Location | Where-Object {$_.Name -eq $roleInstance.HardwareProfile.VmSize}
                               
								
                        $AvailableSessionCapacity = $AvailableSessionCapacity + $roleSize.NumberOfCores * $SessionThresholdPerCPU
                        $numberOfRunningHost = $numberOfRunningHost + 1
								
                        $totalRunningCores = $totalRunningCores + $roleSize.NumberOfCores
                        if ($numberOfRunningHost -ge $MinimumNumberOfRDSH) {
                            break
                        }
                    }
                    #Break # break out of the inner foreach loop once a match is found and checked
                }
            }
        }
        write-log -Message "$hostPoolName $totalRunningCores $numberOfRunningHost"
    }
		
    else {
        #check if the available capacity meets the number of sessions or not
        write-log -Message "Current total number of user sessions: $(($hostPoolUserSessions).count)" 
        write-log -Message "Current available session capacity is: $AvailableSessionCapacity" 
        if ($hostPoolUserSessions.Count -ge $AvailableSessionCapacity) {
            write-log -Message "Current available session capacity is less than demanded user sessions, starting session host" 
            #running out of capacity, we need to start more VMs if there are any 
            foreach ($sessionHost in $RDSessionHost.SessionHostName) {
					
                if ($hostPoolUserSessions.count -ge $AvailableSessionCapacity) {
						
                    $VMName = $sessionHost.Split(".")[0]
                    $roleInstance = Get-AzureRmVM -Status | Where-Object {$_.Name.Contains($VMName)} | Select-Object -Unique
							
                    if ($sessionHost.ToLower().Contains($roleInstance.Name.ToLower())) {
                        #check if the Azure VM is running or not
								
                        if ($roleInstance.PowerState -ne "VM running") {
								    

                            $getShsinfo = Get-RdsSessionHost -TenantName $tenantname -HostPoolName $hostPoolName
                                
                            if ($getShsinfo.AllowNewSession -eq $false) {
                                Set-RdsSessionHost -TenantName $tenantName -HostPoolName $hostPoolName -Name $sessionHost -AllowNewSession $true

                            }
                                    
                            #start the Azure VM
                            try {
                                Start-AzureRmVM -Name $roleInstance.Name -Id $roleInstance.Id -ErrorAction SilentlyContinue
										
                            }
                            catch {
                                write-output "Failed to start Azure VM: $($roleInstance.Name) with error: $($_.exception.message)" 
                                Exit 1
                            }
									
                            #wait for the VM to start
                            $IsVMStarted = $false
                            while (!$IsVMStarted) {
                                $vm = Get-AzureRmVM -Status | Where-Object { $_.Name -eq $roleInstance.Name }
										
										
                                if ($vm.PowerState -eq "VM running" -and $vm.ProvisioningState -eq "Succeeded") {
                                    $IsVMStarted = $true
                                }
                                #wait for 15 seconds
                                #Start-Sleep -Seconds 15
                            }
									
									
									
                            # we need to calculate available capacity of sessions
									
                            $vm = Get-AzureRmVM -Status | Where-Object { $_.Name -eq $roleInstance.Name }
																		
                            $roleSize = Get-AzureRmVMSize -Location $roleInstance.Location | Where-Object {$_.Name -eq $roleInstance.HardwareProfile.VmSize}
																		
                            $AvailableSessionCapacity = $AvailableSessionCapacity + $roleSize.NumberOfCores * $SessionThresholdPerCPU
                            $numberOfRunningHost = $numberOfRunningHost + 1
									
                            $totalRunningCores = $totalRunningCores + $roleSize.NumberOfCores
                            write-log -Message "new available session capacity is: $AvailableSessionCapacity" 
                            if ($AvailableSessionCapacity -gt $hostPoolUserSessions.Count) {
                                break
                            }
                        }
                     
                    }
                }
            }
        }
        #write to the usage log
        write-log -Message "$hostPoolName $totalRunningCores $numberOfRunningHost"
    }	
}	
    



#Peak or not peak hour
else {
    write-log -Message "It is Off-peak hours"
    write-log -Message "It is off-peak hours. Starting to scale down RD session hosts..." 
    write-log -Message "Processing hostPool $($hostPoolName)"
    
    #Get the Session Hosts in the hostPool
    try {
            
        $RDSessionHost = Get-RdsSessionHost -TenantName $tenantName -HostPoolName $hostPoolName

            
                       
    }
    catch {
        write-log -Error "Failed to retrieve session hosts in hostPool: $($hostPoolName) with error: $($_.exception.message)" 
        Exit 1
    }
		
		
    #check the number of running session hosts
    $numberOfRunningHost = 0
		
    #total of running cores
    $totalRunningCores = 0
		
    foreach ($sessionHost in $RDSessionHost.SessionHostName) {
			
        #foreach ($roleInstance in $Deployment)
        #{
        $VMName = $sessionHost.Split(".")[0]
        $roleInstance = Get-AzureRmVM -Status | Where-Object {$_.Name.Contains($VMName)} | Select-Object -Unique
				
        if ($sessionHost.ToLower().Contains($roleInstance.Name.ToLower())) {
            
            #check if the Azure VM is running or not
            if ($roleInstance.PowerState -eq "VM running") {
                $numberOfRunningHost = $numberOfRunningHost + 1
						
                # we need to calculate available capacity of sessions  
                $roleSize = Get-AzureRmVMSize -Location $roleInstance.Location | Where-Object {$_.Name -eq $roleInstance.HardwareProfile.VmSize}
                        
                $totalRunningCores = $totalRunningCores + $roleSize.NumberOfCores
            }
            #Break # break out of the inner foreach loop once a match is found and checked
        }
        #}
    }
		
    if ($numberOfRunningHost -gt $MinimumNumberOfRDSH) {
        #shutdown VM to meet the minimum requirement
			
        foreach ($sessionHost in $RDSessionHost.SessionHostName) {
            if ($numberOfRunningHost -gt $MinimumNumberOfRDSH) {
					
                #foreach ($roleInstance in $Deployment)
                #{
                $VMName = $sessionHost.Split(".")[0]
                $roleInstance = Get-AzureRmVM -Status | Where-Object {$_.Name.Contains($VMName)} | Select-Object -Unique
						
                if ($sessionHost.ToLower().Contains($roleInstance.Name.ToLower())) {
                    #check if the Azure VM is running or not
							
                    if ($roleInstance.PowerState -eq "VM running") {
                        #check the role isntance status is ReadyRole or not, before setting the session host
                        $isInstanceReady = $false
                        $numOfRetries = 0
								
                        while (!$isInstanceReady -and $num -le 3) {
                            $numOfRetries = $numOfRetries + 1
                            $instance = Get-AzureRmVM -Status | Where-Object { $_.Name -eq $roleInstance.Name }
                            if ($instance -ne $null -and $instance.ProvisioningState -eq "Succeeded") {
                                $isInstanceReady = $true
                            }
                            #wait for 15 seconds
                            #Start-Sleep -Seconds 15
                        }
								
                        if ($isInstanceReady) {
                            #ensure the running Azure VM is set as drain mode
                            try {
                                                                               
                                #setting hosts
                                        
                                Set-RdsSessionHost -TenantName $tenantName -HostPoolName $hostPoolName -Name $sessionHost -AllowNewSession $false -ErrorAction SilentlyContinue

										
                            } 
                            catch {
                                write-log -Error "Failed to set drain mode on session host: $($sessionHost.SessionHost) with error: $($_.exception.message)" 
                                Exit 1
                            }
								
                            #notify user to log off session
                            #Get the user sessions in the hostPool
                            try {
                                        
                                $hostPoolUserSessions = Get-RdsUserSession -TenantName $tenantName -HostPoolName $hostPoolName
                                       
                            }
                            catch {
                                write-log -Error "Failed to retrieve user sessions in hostPool: $($hostPoolName) with error: $($_.exception.message)" 
                                Exit 1
                            }
									
                            write-log -Message "Counting the current sessions on the host..." 
                            $existingSession = 0
                            foreach ($session in $hostPoolUserSessions) {
                                if ($session.SessionHostName -eq $sessionHost) {
                                    if ($LimitSecondsToForceLogOffUser -ne 0) {
                                        #send notification
                                        try {
                                            
                                            Send-RdsUserSessionMessage -TenantName $tenantName -HostPoolName $hostPoolName -SessionHostName $session.SessionHostName -SessionId $session.sessionid -MessageTitle $LogOffMessageTitle -MessageBody "$($LogOffMessageBody) You will logged off in $($LimitSecondsToForceLogOffUser) seconds." -NoUserPrompt:$false
                                            
                                        }
                                        catch {
                                            write-log -Error "Failed to send message to user with error: $($_.exception.message)" 
                                            Exit 1
                                        }
                                    }
											
                                    $existingSession = $existingSession + 1
                                }
                            }
									
									
                            #wait for n seconds to log off user
                            Start-Sleep -Seconds $LimitSecondsToForceLogOffUser
									
                            if ($LimitSecondsToForceLogOffUser -ne 0) {
                                #force users to log off
                                write-log -Message "Force users to log off..." 
                                try {
                                    $hostPoolUserSessions = Get-RdsUserSession -TenantName $tenantName -HostPoolName $hostPoolName
                                            
                                }
                                catch {
                                    write-log -Error "Failed to retrieve list of user sessions in hostPool: $($hostPoolName) with error: $($_.exception.message)" 
                                    exit 1
                                }
                                foreach ($session in $hostPoolUserSessions) {
                                    if ($session.SessionHostName -eq $sessionHost) {
                                        #log off user
                                        try {
    													
                                            Invoke-RdsUserSessionLogoff -TenantName $tenantName -HostPoolName $hostPoolName -SessionHostName $session.SessionHostName -SessionId $session.SessionId -NoUserPrompt:$false
                                                   
                                            $existingSession = $existingSession - 1
                                            #break
                                        }
                                        catch {
                                            write-log -Error "Failed to log off user with error: $($_.exception.message)" 
                                            exit 1
                                        }
                                    }
                                }
                            }
									
									
									
                            #check the session count before shutting down the VM
                            if ($existingSession -eq 0) {
										
                                #shutdown the Azure VM
                                try {
                                    Stop-AzureRmVM -Name $roleInstance.Name -Id $roleInstance.Id -Force -ErrorAction SilentlyContinue
											
                                }
                                catch {
                                    write-log -Error "Failed to stop Azure VM: $($roleInstance.Name) with error: $($_.exception.message)" 
                                    exit 1
                                }
										
                                #wait for the VM to stop
                                $IsVMStopped = $false
                                while (!$IsVMStopped) {
											
                                    $vm = Get-AzureRmVM -Status | Where-Object { $_.Name -eq $roleInstance.Name }
											
                                    if ($vm.PowerState -eq "VM deallocated") {
                                        $IsVMStopped = $true
                                    }
                                    write-log -Message "$($roleInstance.Name) VM Stopped Successfully ..." 
                                    #wait for 15 seconds
                                    #Start-Sleep -Seconds 15
                                }
										
                                $vm = Get-AzureRmVM -Status | Where-Object { $_.Name -eq $roleInstance.Name }
										
                                $roleSize = Get-AzureRmVMSize -Location $roleInstance.Location | Where-Object {$_.Name -eq $roleInstance.HardwareProfile.VmSize}
										
										
                                #decrement the number of running session host
                                $numberOfRunningHost = $numberOfRunningHost - 1
										
                                $totalRunningCores = $totalRunningCores - $roleSize.NumberOfCores
                            }
                        }
                    }
                }
               
            }
        }
		
    }
    #write to the usage log
    Write-Log -Message "$HostpoolName $totalRunningCores $numberOfRunningHost"
} #Scale hostPool

#endregion

#Create an storage account to store Auto Scale Script Logs
$StorageAccountName = "autoscalestrgaccount"
$stoagecontainername = "scriptlogcontainer"
$storageaccount = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction SilentlyContinue 
$filepath = "C:\WVDAutoScale-$hostpoolname\ScriptLog-$DateFilename.log"
if (!$storageaccount) {
    $storageaccount = New-azurermstorageaccount -ResourceGroupName $ResourceGroupName -Name $storageaccountname -SkuName Standard_LRS -Location $Location -Kind BlobStorage -AccessTier Cool 
    $storagecontainer = New-AzureRmStorageContainer -ResourceGroupName $ResourceGroupName -AccountName $storageaccountname -Name $stoagecontainername -PublicAccess Blob
    Set-AzureStorageBlobContent -Container $storagecontainer.Name -File $filepath -Blob "$hostpoolname\ScriptLog-$DateFilename.log" -Context $storageaccount.Context -Force
    
}
else {
    $storagecontainer = Get-AzureRmStorageContainer -ResourceGroupName $ResourceGroupName -AccountName $storageaccountname -Name $stoagecontainername -ErrorAction SilentlyContinue
    if (!$storagecontainer) {
        $storagecontainer = New-AzureRmStorageContainer -ResourceGroupName $ResourceGroupName -AccountName $storageaccountname -Name $stoagecontainername -PublicAccess Blob
        Set-AzureStorageBlobContent -Container $storagecontainer.Name -File $filepath -Blob "$hostpoolname\ScriptLog-$DateFilename.log" -Context $storageaccount.Context -Force
    }
    else {
        Set-AzureStorageBlobContent -Container $storagecontainer.Name -File $filepath -Blob "$hostpoolname\ScriptLog-$DateFilename.log" -Context $storageaccount.Context -Force
    }
}