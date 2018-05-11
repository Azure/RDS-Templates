<#
Copyright 2018 Peopletech Group

Version 1.0 April 2018

.SYNOPSIS
This is a sample script for automatically scaling Tenant Environment RDMI Host Servers in Micrsoft Azure

.Description
This script will automatically start/stop Tenant RDMI host VMs based on the number of user sessions and peak/off-peak time period specified in the configuration file.
During the peak hours, the script will start necessary session hosts in the Hostpool to meet the demands of users.
During the off-peak hours, the script will shutdown the session hosts and only keep the minimum number of session hosts.


#>


<#
.SYNOPSIS
Function for writing the log
#>
Function Write-Log
{
    Param(
        [int]$level
    ,   [string]$Message
    ,   [ValidateSet("Info", "Warning", "Error")][string]$severity = 'Info'
    ,   [string]$logname = $rdmiTenantlog
    ,   [string]$color = "white"
    )
    $time = get-date
    Add-Content $logname -value ("{0} - [{1}] {2}" -f $time, $severity, $Message)
    if ($interactive) {
        switch ($severity)
        {
            'Error' {$color = 'Red'}
            'Warning' {$color = 'Yellow'}
        }
        if ($level -le $VerboseLogging)
        {
            if ($color -match "Red|Yellow")
            {
                Write-Host ("{0} - [{1}] {2}" -f $time, $severity, $Message) -ForegroundColor $color -BackgroundColor Black
                if ($severity -eq 'Error') { 
                    
                    throw $Message 
                }
            }
            else 
            {
                Write-Host ("{0} - [{1}] {2}" -f $time, $severity, $Message) -ForegroundColor $color
            }
        }
    }
    else
    {
        switch ($severity)
        {
            'Info' {Write-Verbose -Message $Message}
            'Warning' {Write-Warning -Message $Message}
            'Error' {
                throw $Message
            }
        }
    }
} 

<# 
.SYNOPSIS
Function for writing the usage log
#>
Function Write-UsageLog
{
    Param(
        [string]$hostpoolName,
        [int]$corecount,
        [int]$vmcount,
        [string]$logfilename=$RdmiTenantUsagelog
    )
    $time=get-date
    Add-Content $logfilename -value ("{0}, {1}, {2}, {3}" -f $time, $hostpoolName, $corecount, $vmcount)
}

<#
.SYNOPSIS
Function for creating variable from XML
#>
Function Set-ScriptVariable ($Name,$Value) 
{
    Invoke-Expression ("`$Script:" + $Name + " = `"" + $Value + "`"")
}


#$CurrentPath=Split-Path $script:MyInvocation.MyCommand.Path
$CurrentPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(‘.\’)


$XMLPath = "$CurrentPath\Config.xml"

#Log path
$rdmiTenantlog="$CurrentPath\RdmiTenantScale"

#usage log path
$RdmiTenantUsagelog="$CurrentPath\RdmiTenantUsage.log"


###### Verify XML file ######
If (Test-Path $XMLPath) 
{
    write-verbose "Found $XMLPath"
    write-verbose "Validating file..."
    try 
    {
        $Variable = [XML] (Get-Content $XMLPath)
    } 
    catch 
    {
        $Validate = $false
        Write-Error "$XMLPath is invalid. Check XML syntax - Unable to proceed"
        Write-Log 3 "$XMLPath is invalid. Check XML syntax - Unable to proceed" "Error"
        exit 1
    }
} 
Else 
{
    $Validate = $false
    write-error "Missing $XMLPath - Unable to proceed"
    Write-Log 3 "Missing $XMLPath - Unable to proceed" "Error"
    exit 1
}

##### Load XML Configuration values as variables #########
Write-Verbose "loading values from Config.xml"
$Variable=[XML] (Get-Content "$XMLPath")
$Variable.RDMIScale.Azure | ForEach-Object {$_.Variable} | Where-Object {$_.Name -ne $null} | ForEach-Object {Set-ScriptVariable -Name $_.Name -Value $_.Value}
$Variable.RDMIScale.RdmiTScaleSettings | ForEach-Object {$_.Variable} | Where-Object {$_.Name -ne $null} | ForEach-Object {Set-ScriptVariable -Name $_.Name -Value $_.Value}
$Variable.RDMIScale.Ptrinfo | ForEach-Object {$_.Variable} | Where-Object {$_.Name -ne $null} | ForEach-Object {Set-ScriptVariable -Name $_.Name -Value $_.Value}


cd "$CurrentPath\PowershellModules"
Import-Module .\Microsoft.RdInfra.RdPowershell.dll

            #Create pspassword for AAD user of partner
            #<#---->#>$password = ConvertTo-SecureString -String $PartAPassword -asPlainText -Force
            #<#---->#>$credential = New-Object System.Management.Automation.PSCredential($PartAUsername,$password)

#The the following three lines is to use password/secret based authentication for service principal, to use certificate based authentication, please comment those lines, and uncomment the above line
$secpasswd = ConvertTo-SecureString $AADServicePrincipalSecret -AsPlainText -Force
$appcreds = New-Object System.Management.Automation.PSCredential ($AADApplicationId, $secpasswd)

Add-AzureRmAccount -ServicePrincipal -Credential $appcreds -TenantId $AADTenantId

#select the current Azure Subscription specified in the config
Select-AzureRmSubscription -SubscriptionName $CurrentAzureSubscriptionName
            
	#Construct Begin time and End time for the Peak period
	$CurrentDateTime = Get-Date
	Write-Log 3 "Starting RDMI Tenant Hosts Scale Optimization: Current Date Time is: $CurrentDateTime" "Info"
	
	$BeginPeakDateTime = [DateTime]::Parse($CurrentDateTime.ToShortDateString() + ' ' + $BeginPeakTime)
	
	$EndPeakDateTime = [DateTime]::Parse($CurrentDateTime.ToShortDateString() + ' ' + $EndPeakTime)
	
    
#check the calculated end time is later than begin time in case of time zone
if($EndPeakDateTime -lt $BeginPeakDateTime)
{
    $EndPeakDateTime=$EndPeakDateTime.AddDays(1)
}	

#get the available HostPoolnames in the RDMITenant
try
{
    #<#---->#>Set-RdsContext -DeploymentUrl $Rdbroker -Credential $credential
    $hostPoolNames=Get-RdsHostPool -TenantName "MSFT-Tenant" -ErrorAction Stop 
}
catch
{
    Write-Log 1 "Failed to retrieve RDMITenant Hostpools: $($_.exception.message)" "Error"
    Exit 1
}



	
	#check if it is during the peak or off-peak time
	if ($CurrentDateTime -ge $BeginPeakDateTime -and $CurrentDateTime -le $EndPeakDateTime)
	{
        Write-Host "It is in peak hours now"
        Write-Log 3 "Peak hours: starting session hosts as needed based on current workloads." "Info"
        Write-Log 1 "Looping thru available hostpool list ..." "Info"
		#Get the Session Hosts in the hostPool
		
        foreach($hostPoolName in $hostPoolNames){
        try
		{
			$RDSessionHost=Get-RdsSessionHost -TenantName "MSFT-Tenant" -HostPoolName "tempHostpool" -ErrorAction SilentlyContinue
            
            #$RDSessionHost="shs-01.rdmi.com","shs-02.rdmi.com"

       # <#---->#>$RDSessionHost = Get-SessionHost -ConnectionBroker $ConnectionBrokerFQDN -CollectionAlias $collection.CollectionAlias
                
		
}
		catch
		{
			Write-Log 1 "Failed to retrieve RDS session hosts in hostPool $($hostPoolName.Name) : $($_.exception.message)" "Error"
			Exit 1
		}
		
		#Get the User Sessions in the hostPool
		try
		{     
              $hostPoolUserSessions = 1
              #$hostPoolUserSessions = Get-Random -Count 1 -InputObject (1..10)
              #$CollectionUserSessions=Get-RdsUserSession -TenantName $tenantName -HostPoolName $hostPoolName 
              #$CollectionUserSessions = Get-RDUserSession -ConnectionBroker $ConnectionBrokerFQDN -CollectionName $hostPoolName.Name -ErrorAction Stop
               
		}
		catch
		{
			Write-Log 1 "Failed to retrieve user sessions in hostPool:$($hostPoolName.Name) with error: $($_.exception.message)" "Error"
			Exit 1
		}
		
		#check the number of running session hosts
		$numberOfRunningHost = 0
		
		#total of running cores
		$totalRunningCores = 0
		
		#total capacity of sessions of running VMs
		$AvailableSessionCapacity = 0
		
		foreach ($sessionHost in $RDSessionHost.Name)
		{
			Write-Log 1 "Checking session host: $($sessionHost)" "Info"
			
			#Get Azure Virtual Machines
			try
			{
                
	            $TenantLogin=Add-AzureRmAccount -ServicePrincipal -Credential $appcreds -TenantId $AADTenantId
				$Deployment = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Status -ErrorAction Stop
			}
			catch
			{
				Write-Log 1 "Failed to retrieve deployment information from Azure with error: $($_.exception.message)" "Error"
				Exit 1
			}
			
			
			foreach ($roleInstance in $Deployment)
			{
				
				if ($sessionHost.ToLower().Contains($roleInstance.Name.ToLower()))
				{
					
					#check the azure vm is running or not      
					if ($roleInstance.PowerState -eq "VM running")
					{
						$numberOfRunningHost = $numberOfRunningHost + 1
						
						#we need to calculate available capacity of sessions
						
						$roleSize = Get-AzureRmVMSize -VMName $roleInstance.Name -ResourceGroupName $ResourceGroupName | Where-Object{ $_.Name -eq $roleInstance.HardwareProfile.VmSize }
						
						$AvailableSessionCapacity = $AvailableSessionCapacity + $roleSize.NumberOfCores.ToString() * $SessionThresholdPerCPU
						
						$totalRunningCores = $totalRunningCores + $roleSize.NumberOfCores.ToString()
					}
					Break # break out of the inner foreach loop once a match is found and checked
				}
			}
		}
		
		write-host "Current number of running hosts: " $numberOfRunningHost
		Write-Log 1 "Current number of running hosts: $numberOfRunningHost" "Info"
		
		if ($numberOfRunningHost -lt $MinimumNumberOfRDSH)
		{
			
			Write-Log 1 "Current number of running session hosts is less than minimum requirements, start session host ..." "Info"
			
			#start VM to meet the minimum requirement            
			foreach ($sessionHost in $RDSessionHost.Name)
			{
				
				#refresh the azure VM list
				try
				{
					
					$Deployment = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Status
				}
				catch
				{
					Write-Log 1 "Failed to retrieve Azure deployment information with error: $($_.exception.message)" "Error"
					Exit 1
				}
				#check whether the number of running VMs meets the minimum or not
				if ($numberOfRunningHost -lt $MinimumNumberOfRDSH)
				{
					
					foreach ($roleInstance in $Deployment)
					{
						if ($sessionHost.ToLower().Contains($roleInstance.Name.ToLower()))
						{
							
							#check if the azure VM is running or not
							
							if ($roleInstance.PowerState -ne "VM running")
							{
								#start the azure VM
								try
								{
									
									Start-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $roleInstance.Name -ErrorAction Stop
								}
								catch
								{
									Write-Log 1 "Failed to start Azure VM: $($roleInstance.Name) with error: $($_.exception.message)" "Error"
									Exit 1
								}
								
								#wait for the VM to start
								$IsVMStarted = $false
								while (!$IsVMStarted)
								{
									
									$vm = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Status | Where-Object{ $_.Name -eq $roleInstance.Name }
									
									if ($vm.PowerState -eq "VM running" -and $vm.ProvisioningState -eq "Succeeded")
									{
										$IsVMStarted = $true
									}
									#wait for 15 seconds
									Start-Sleep -Seconds 15
								}
								
								# we need to calculate available capacity of sessions
								
								$vm = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Status | Where-Object{ $_.Name -eq $roleInstance.Name }
								
								$roleSize = Get-AzureRmVMSize -ResourceGroupName $ResourceGroupName -VMName $roleInstance.Name | Where-Object{ $_.Name -eq $roleInstance.HardwareProfile.VmSize }
								
								$AvailableSessionCapacity = $AvailableSessionCapacity + $roleSize.NumberOfCores.ToString() * $SessionThresholdPerCPU
								$numberOfRunningHost = $numberOfRunningHost + 1
								
								$totalRunningCores = $totalRunningCores + $roleSize.NumberOfCores.ToString()
								if ($numberOfRunningHost -ge $MinimumNumberOfRDSH)
								{
									break
								}
							}
							Break # break out of the inner foreach loop once a match is found and checked
						}
					}
				}
			}
		}
		else
		{
			#check if the available capacity meets the number of sessions or not
			Write-Log 1 "Current total number of user sessions: $($hostPoolUserSessions)" "Info"
			Write-Log 1 "Current available session capacity is: $AvailableSessionCapacity" "Info"
			if ($hostPoolUserSessions -ge $AvailableSessionCapacity)
			{
				Write-Log 1 "Current available session capacity is less than demanded user sessions, starting session host" "Info"
				#running out of capacity, we need to start more VMs if there are any 
				#refresh the Azure VM list
				try
				{
					
					$Deployment = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Status -ErrorAction Stop
				}
				catch
				{
					Write-Log 1 "Failed to retrieve Azure deployment information with error: $($_.exception.message)" "Error"
					Exit 1
				}
				foreach ($sessionHost in $RDSessionHost.Name)
				{
					
					if ($hostPoolUserSessions -ge $AvailableSessionCapacity)
					{
						
						foreach ($roleInstance in $Deployment)
						{
							if ($sessionHost.ToLower().Contains($roleInstance.Name.ToLower()))
							{
								#check if the Azure VM is running or not
								
								if ($roleInstance.PowerState -ne "VM running")
								{
									#start the Azure VM
									try
									{
										
										Start-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $roleInstance.Name -ErrorAction Stop
									}
									catch
									{
										Write-Log 1 "Failed to start Azure VM: $($roleInstance.Name) with error: $($_.exception.message)" "Error"
										Exit 1
									}
									
									#wait for the VM to start
									$IsVMStarted = $false
									while (!$IsVMStarted)
									{
										
										$vm = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Status | Where-Object{ $_.Name -eq $roleInstance.Name }
										
										if ($vm.PowerState -eq "VM running" -and $vm.ProvisioningState -eq "Succeeded")
										{
											$IsVMStarted = $true
										}
										#wait for 15 seconds
										Start-Sleep -Seconds 15
									}
									
									
									
									# we need to calculate available capacity of sessions
									
									$vm = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Status | Where-Object{ $_.Name -eq $roleInstance.Name }
									
									$roleSize = Get-AzureRmVMSize -ResourceGroupName $ResourceGroupName -VMName $roleInstance.Name | Where-Object{ $_.Name -eq $roleInstance.HardwareProfile.VmSize }
									
									$AvailableSessionCapacity = $AvailableSessionCapacity + $roleSize.NumberOfCores.ToString() * $SessionThresholdPerCPU
									$numberOfRunningHost = $numberOfRunningHost + 1
									
									$totalRunningCores = $totalRunningCores + $roleSize.NumberOfCores.ToString()
									Write-Log 1 "new available session capacity is: $AvailableSessionCapacity" "Info"
									if ($AvailableSessionCapacity -gt $hostPoolUserSessions.Count)
									{
										break
									}
								}
								Break # break out of the inner foreach loop once a match is found and checked
							}
						}
					}
				}
			
		}
		}
		#write to the usage log
		Write-UsageLog $hostPoolName.Name $totalRunningCores $numberOfRunningHost 
}	
} #Peak or not peak hour
	else
	{
		write-host "It is Off-peak hours"
		write-log 3 "It is off-peak hours. Starting to scale down RD session hosts..." "Info"
		Write-Host ("Processing hostPool {0}" -f $hostPoolName.Name)
		foreach($hostPoolName in $hostPoolNames){
		Write-Log 3 "Processing hostPool $($hostPoolName.Name)"
		#Get the Session Hosts in the hostPool
		try
		{
            
            $RDSessionHost=Get-RdsSessionHost -TenantName $tenantName -HostPoolName $hostPoolName.Name -ErrorAction SilentlyContinue
            #$RDSessionHost=Get-RdsSessionHost -TenantName $tenantName -HostPoolName $hostPoolName
            #$RDSessionHost="shs-01.rdmi.com","shs-02.rdmi.com"
            

			#<#---->#>$RDSessionHost = Get-SessionHost -ConnectionBroker $ConnectionBrokerFQDN -CollectionAlias $collection.CollectionAlias
                       
		}
		catch
		{
			Write-Log 1 "Failed to retrieve session hosts in hostPool: $($hostPoolName.Name) with error: $($_.exception.message)" "Error"
			Exit 1
		}
		
		
		#check the number of running session hosts
		$numberOfRunningHost = 0
		
		#total of running cores
		$totalRunningCores = 0
		
		foreach ($sessionHost in $RDSessionHost.Name)
		{
			
			#refresh the Azure VM list
			try
			{
				$TenantLogin=Add-AzureRmAccount -ServicePrincipal -Credential $appcreds -TenantId $AADTenantId
				$Deployment = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Status -ErrorAction Stop
				
			}
			catch
			{
				Write-Log 1 "Failed to retrieve Azure deployment information for cloud service: $ResourceGroupName with error: $($_.exception.message)" "Error"
				Exit 1
			}
			
			foreach ($roleInstance in $Deployment)
			{
				
				if ($sessionHost.ToLower().Contains($roleInstance.Name.ToLower()))
				{
					#check if the Azure VM is running or not
					
					if ($roleInstance.PowerState -eq "VM running")
					{
						$numberOfRunningHost = $numberOfRunningHost + 1
						# we need to calculate available capacity of sessions  
						$roleSize = Get-AzureRmVMSize -ResourceGroupName $ResourceGroupName -VMName $roleInstance.Name | Where-Object{ $_.Name -eq $roleInstance.HardwareProfile.VmSize }
						$totalRunningCores = $totalRunningCores + $roleSize.NumberOfCores.ToString()
					}
					Break # break out of the inner foreach loop once a match is found and checked
				}
			}
		}
		
		if ($numberOfRunningHost -gt $MinimumNumberOfRDSH)
		{
			#shutdown VM to meet the minimum requirement
			
			#refresh the Azure VM list
			try
			{
				
				$Deployment = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Status -ErrorAction Stop
			}
			catch
			{
				Write-Log 1 "Failed to retrieve Azure deployment information for cloud service: $ResourceGroupName with error: $($_.exception.message)" "Error"
				Exit 1
			}
			foreach ($sessionHost in $RDSessionHost.Name)
			{
				if ($numberOfRunningHost -gt $MinimumNumberOfRDSH)
				{
					
					foreach ($roleInstance in $Deployment)
					{
						
						if ($sessionHost.ToLower().Contains($roleInstance.Name.ToLower()))
						{
							#check if the Azure VM is running or not
							
							if ($roleInstance.PowerState -eq "VM running")
							{
								#check the role isntance status is ReadyRole or not, before setting the session host
								$isInstanceReady = $false
								$numOfRetries = 0
								
								while (!$isInstanceReady -and $num -le 3)
								{
									$numOfRetries = $numOfRetries + 1
									$instance = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Status | Where-Object{ $_.Name -eq $roleInstance.Name }
									if ($instance -ne $null -and $instance.ProvisioningState -eq "Succeeded")
									{
										$isInstanceReady = $true
									}
									#wait for 15 seconds
									Start-Sleep -Seconds 5
								}
								
								if ($isInstanceReady)
								{
									#ensure the running Azure VM is set as drain mode
									try
									{
                                        #setting hosts


										#<#---->#>Set-RDSessionHost -SessionHost $sessionHost.SessionHost -NewConnectionAllowed NotUntilReboot -ConnectionBroker $ConnectionBrokerFQDN -ErrorAction Stop
									}
									catch
									{
										Write-Log 1 "Failed to set drain mode on session host: $($sessionHost.SessionHost) with error: $($_.exception.message)" "Error"
										Exit 1
									}
									
									
									#notify user to log off session
									#Get the user sessions in the hostPool
									try
									{
                                        $hostPoolUserSessions = 1
                                        #$hostPoolUserSessions = Get-Random -Count 1 -InputObject (1..10)
                                        #Write-host $hostPoolUserSessions + first
										#<#---->#>$CollectionUserSessions = Get-RDUserSession -ConnectionBroker $ConnectionBrokerFQDN -CollectionName $hostPoolName.Name -ErrorAction Stop
									}
									catch
									{
										Write-Log 1 "Failed to retrieve user sessions in hostPool: $($hostPoolName.Name) with error: $($_.exception.message)" "Error"
										Exit 1
									}
									
									#Write-Log 1 "Counting the current sessions on the host..." "Info"
									$existingSession = 0
									foreach ($session in $hostPoolUserSessions)
									{
										if ($session.HostServer -eq $sessionHost)
										{
											if ($LimitSecondsToForceLogOffUser -ne 0)
											{
												#send notification
												try
												{
													break
													#<#---->#>Send-RDUserMessage -HostServer $session.HostServer -UnifiedSessionID $session.UnifiedSessionId -MessageTitle $LogOffMessageTitle -MessageBody "$($LogOffMessageBody) You will logged off in $($LimitSecondsToForceLogOffUser) seconds." -ErrorAction Stop
												}
												catch
												{
													Write-Log 1 "Failed to send message to user with error: $($_.exception.message)" "Error"
													Exit 1
												}
											}
											
											$existingSession = $existingSession + 1
										}
									}
									
									
									#wait for n seconds to log off user
									Start-Sleep -Seconds $LimitSecondsToForceLogOffUser
									
									if ($LimitSecondsToForceLogOffUser -ne 0)
									{
										#force users to log off
										Write-Log 1 "Force users to log off..." "Info"
										try
										{
											$hostPoolUserSessions = 1
                                            #$hostPoolUserSessions = Get-Random -Count 1 -InputObject (1..10)
                                            Write-Host $hostPoolUserSessions
                                        #<#---->#>$CollectionUserSessions = Get-RDUserSession -ConnectionBroker $ConnectionBrokerFQDN -CollectionName $hostPoolName.Name -ErrorAction Stop
										}
										catch
										{
											Write-Log 1 "Failed to retrieve list of user sessions in hostPool: $($hostPoolName.Name) with error: $($_.exception.message)" "Error"
											exit 1
										}
										foreach ($session in $hostPoolUserSessions)
										{
											if ($session.HostServer -eq $sessionHost)
											{
												#log off user
												try
												{
													#<#---->#>Invoke-RDUserLogoff -HostServer $session.HostServer -UnifiedSessionID $session.UnifiedSessionId -Force -ErrorAction Stop
													$existingSession = $existingSession - 1
                                                    break
												}
												catch
												{
													Write-Log 1 "Failed to log off user with error: $($_.exception.message)" "Error"
													exit 1
												}
											}
										}
									}
									
									
									
									#check the session count before shutting down the VM
									if ($existingSession -eq 0)
									{
										
										#shutdown the Azure VM
										try
										{
											
											Stop-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $roleInstance.Name -Force -ErrorAction Stop
										}
										catch
										{
											Write-Log 1 "Failed to stop Azure VM: $($roleInstance.Name) with error: $($_.exception.message)" "Error"
											exit 1
										}
										
										#wait for the VM to stop
										$IsVMStopped = $false
										while (!$IsVMStopped)
										{
											
											$vm = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Status | Where-Object{ $_.Name -eq $roleInstance.Name }
											
											if ($vm.PowerState -eq "VM deallocated")
											{
												$IsVMStopped = $true
											}
											write-log 3 "Waiting for Azure VM to stop $($roleInstance.Name) ..." "Info"
											#wait for 15 seconds
											Start-Sleep -Seconds 15
										}
										
										$vm = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Status | Where-Object{ $_.Name -eq $roleInstance.Name }
										
										$roleSize = Get-AzureRmVMSize -ResourceGroupName $ResourceGroupName -VMName $roleInstance.Name | Where-Object{ $_.Name -eq $roleInstance.HardwareProfile.VmSize }
										
										#decrement the number of running session host
										$numberOfRunningHost = $numberOfRunningHost - 1
										
										$totalRunningCores = $totalRunningCores - $roleSize.NumberOfCores.ToString().ToString()
									}
								}
							}
							Break # break out of the inner foreach loop once a match is found and checked
						}
					}
				}
			}
			
			#write to the usage log
			#Write-UsageLog $.name $totalRunningCores $numberOfRunningHost
		}
	}} #Scale hostPools
	
cd..
#endregion

