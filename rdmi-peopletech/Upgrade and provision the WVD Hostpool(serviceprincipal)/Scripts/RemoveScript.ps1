<#

    .SYNOPSIS
    Removing hosts from Existing Hostpool and add first instance to hostpool.

    .DESCRIPTION
    This script remove old sessionhost servers from existing Hostpool and add first instance to existing hostpool.
    The supported Operating Systems Windows Server 2016/windows 10 multisession.

    .ROLE
    Readers

#>
param(
    [Parameter(mandatory = $true)]
    [string]$RDBrokerURL,
	
	[Parameter(mandatory = $true)]
    [string]$TenantGroupName,

    [Parameter(mandatory = $true)]
    [string]$TenantName,

    [Parameter(mandatory = $true)]
    [string]$HostPoolName,

    [Parameter(mandatory = $true)]
    [string]$ApplicationId,

    [Parameter(mandatory = $true)]
    [string]$ApplicationSecret,

    [Parameter(mandatory = $true)]
    [string]$SubscriptionId,
    
    [Parameter(mandatory = $false)]
    [string]$FileURI,
    
    [Parameter(mandatory = $false)]
    [double]$Hours,

    [Parameter(mandatory = $false)]
    [int]$userLogoffDelayInMinutes,

    [Parameter(mandatory = $false)]
    [string]$userNotificationMessege,

    [Parameter(mandatory = $false)]
    [string]$messageTitle,

    [Parameter(mandatory = $true)]
    [string]$deleteordeallocateVMs,

    [Parameter(mandatory = $true)]
    [string]$DomainName,
	
	[Parameter(mandatory = $true)]
    [string]$rdshIs1809OrLater,
	
	[Parameter(mandatory = $false)]
    [string]$aadTenantId,

	[Parameter(mandatory = $false)]
    [string]$ActivationKey,	

    [Parameter(mandatory = $true)]
    [string]$localAdminUsername,
    
    [Parameter(mandatory = $true)]
    [string]$localAdminPassword
)

	Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope Process -Force -Confirm:$false
	Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine -Force -Confirm:$false
	$PolicyList=Get-ExecutionPolicy -List
	$log = $PolicyList | Out-String
	
    Function Write-Log { 
                    [CmdletBinding()] 
                    param ( 
                        [Parameter(Mandatory = $false)] 
                        [string]$Message,
                        [Parameter(Mandatory = $false)] 
                        [string]$Error 
                    ) 
     
                    try { 
                        $DateTime = Get-Date -Format ‘MM-dd-yy HH:mm:ss’ 
                        $Invocation = "$($MyInvocation.MyCommand.Source):$($MyInvocation.ScriptLineNumber)" 
                        if ($Message) {
                            Add-Content -Value "$DateTime - $Invocation - $Message" -Path "$([environment]::GetEnvironmentVariable('TEMP', 'Machine'))\ScriptLog.log" 
                        }
                        else {
                            Add-Content -Value "$DateTime - $Invocation - $Error" -Path "$([environment]::GetEnvironmentVariable('TEMP', 'Machine'))\ScriptLog.log" 
                        }
                    } 
                    catch { 
                        Write-Error $_.Exception.Message 
                    } 
                }
		function ActivateWin10
		{
		  param
		  (
			[Parameter(mandatory = $false)]
			[string]$ActivationKey
		  )


		  cscript c:\windows\system32\slmgr.vbs /ipk $ActivationKey
		  dism /online /Enable-Feature /FeatureName:AppServerClient /NoRestart /Quiet
		}
    Write-Log -Message "Policy List: $log"
	$rdshIs1809OrLaterBool = ($rdshIs1809OrLater -eq "True")
	Invoke-WebRequest -Uri $fileURI -OutFile "C:\DeployAgent.zip"
    Write-Log -Message "Downloaded DeployAgent.zip into this location C:\"

    #Creating a folder inside rdsh vm for extracting deployagent zip file
    New-Item -Path "C:\DeployAgent" -ItemType directory -Force -ErrorAction SilentlyContinue
    Write-Log -Message "Created a new folder 'DeployAgent' inside VM"
    Expand-Archive "C:\DeployAgent.zip" -DestinationPath "C:\DeployAgent" -ErrorAction SilentlyContinue
    Write-Log -Message "Extracted the 'Deployagent.zip' file into 'C:\Deployagent' folder inside VM"
    Set-Location "C:\DeployAgent"
    Write-Log -Message "Setting up the location of Deployagent folder"


                do{
                        Write-Output "checking nuget package exists or not"
                        if (!(Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue -ListAvailable)) 
                        {
                        Write-Output "installing nuget package inside vm: $env:COMPUTERNAME"
                            Install-PackageProvider -Name nuget -Force
                        }
                        
                        $LoadModule=Get-Module -ListAvailable "Azure*"
                        
                        if(!$LoadModule){
                        Write-Output "installing azureModule inside vm: $env:COMPUTERNAME"
                        Install-Module AzureRm -AllowClobber -Force
                        }
                        } until($LoadModule)


               
        Import-Module ".\PowershellModules\Microsoft.RDInfra.RDPowershell.dll"
        
        #Converting AzureLogin,WVD Credentials
        $Securepass=ConvertTo-SecureString -String $ApplicationSecret -AsPlainText -Force
        $Credentials=New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList($ApplicationId, $Securepass)

        #Domain Credentials
        $AdminSecurepass = ConvertTo-SecureString -String $localAdminPassword -AsPlainText -Force
        $AdminCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($localAdminUsername, $AdminSecurepass)

           # Authenticating to WVD
			
			$authentication = Add-RdsAccount -DeploymentUrl $RDBrokerURL -Credential $Credentials -ServicePrincipal -TenantId $AadTenantId
      
      $obj = $authentication | Out-String

      if ($authentication)
      {
        Write-Log -Message "WVD Authentication successfully Done. Result:`n$obj"
      }
      else
      {
        Write-Log -Error "WVD Authentication Failed, Error:`n$obj"
      }


      # Set context to the appropriate tenant group
      Write-Log "Running switching to the $TenantGroupName context"
      Set-RdsContext -TenantGroupName $TenantGroupName
      try
      {
        $tenants = Get-RdsTenant -Name $TenantName
        if (!$tenants)
        {
          Write-Log "No tenants exist or you do not have proper access."
        }
      }
      catch
      {
        Write-Log -Message $_
      }

             $allshs=Get-RdsSessionHost -TenantName $tenantname -HostPoolName $HostPoolName
             $allshslog=$allshs.SessionHostName | Out-String
             Write-Log -Message "All Session Host servers in $HostPoolName :`n$allshslog"
             
             $shsNames=0
             $shsNames=@()
             
             $rdsUserSessions=Get-RdsUserSession -TenantName $TenantName -HostPoolName $HostPoolName
             if($rdsUserSessions){
             foreach($rdsUserSession in $rdsUserSessions){
             
             $sessionId=$rdsUserSession.SessionId
             
             $shName=$rdsUserSession.SessionHostName
             
             $username=$rdsUserSession.UserPrincipalName | Out-String
             
             $shsNames+=$shName
             
             Send-RdsUserSessionMessage -TenantName $TenantName -HostPoolName $HostPoolName -SessionHostName $shName -SessionId $sessionId -MessageTitle $messageTitle -MessageBody $userNotificationMessage -NoConfirm:$false
             
             Write-log -message "Sent a rdsusersesionmessage to $username and sessionid was $sessionId"
             
             }
             }
              else
             {
             $shName=$allshs.SessionHostName
             Write-Log -Message "Sessions not present in $shName session host vm"
             $shsNames+=$shName
                }
    
            $allShsNames=$shsNames | select -Unique
            Write-Log -Message "Collected old sessionhosts of Hostpool $HostPoolName : `
            $allShsNames"
                        	
                        Add-WindowsFeature RSAT-AD-PowerShell
                        #Get Domaincontroller VMname
                        $DName=Get-ADDomainController -Discover -DomainName $DomainName
                        $DControllerVM=$DName.Name
                        $ZoneName=$DName.Forest
                
                
            Import-Module AzureRM.Resources
            Import-Module Azurerm
			Import-Module Azurerm.Profile
			Import-Module Azurerm.Compute
            $AzSecurepass=ConvertTo-SecureString -String $ApplicationSecret -AsPlainText -Force
            $AzCredentials=New-Object System.Management.Automation.PSCredential($ApplicationId, $AzSecurepass)
            #$loginResult=Login-AzureRmAccount -SubscriptionId $SubscriptionId  -Credential $AzCredentials
			
			#Authenticate AzureRM
			$authentication = Add-AzureRmAccount -Credential $AzCredentials -ServicePrincipal -TenantId $AadTenantId
			  
			  $obj = $authentication | Out-String

					  if ($authentication)
					  {
						Write-Log -Message "AzureRM Login successfully Done. Result:`n$obj"
					  }
					  else
					  {
						Write-Log -Error "AzureRM Login Failed, Error:`n$obj"
					  }
			if ($authentication.Context.Subscription.Id -eq $SubscriptionId)
            {
                 $success=$true
                 Write-Log -Message "Successfully logged into AzureRM"
            }
            else 
            {
                 Write-Log -Error "Subscription Id $SubscriptionId not in context"
            }
            
            $convertSeconds=$userLogoffDelayInMinutes * 60
            Start-Sleep -Seconds $convertSeconds
            
            
            foreach($sh in $allShsNames){
               
                # setting rdsh vm in drain mode
                $shsDrain=Set-RdsSessionHost -TenantName $tenantname -HostPoolName $HostPoolName -Name $sh -AllowNewSession $false
                $shsDrainlog=$shsDrain | Out-String
                Write-Log -Message "Sesssion host server in drain mode : `
                $shsDrainlog"
                
                Remove-RdsSessionHost -TenantName $tenantname -HostPoolName $HostPoolName -Name $sh -Force
                Write-Log -Message "Successfully $sh removed from hostpool"
                
                $VMName=$sh.Split(".")[0]
                
                if($deleteordeallocateVMs -eq "Delete"){
                
                # Remove the VM's and then remove the datadisks, osdisk, NICs
                Get-AzureRmVM | Where-Object {$_.name -eq $VMName}  | foreach {
                    $a=$_
                    $DataDisks = @($_.StorageProfile.DataDisks.Name)
                    $OSDisk = @($_.StorageProfile.OSDisk.Name)
                    Write-Log -Message "Removing $VMName VM and associated resources from Azure"
                   
                        #Write-Warning -Message "Removing VM: $($_.Name)"
                        $_ | Remove-AzureRmVM -Force -Confirm:$false
                        Write-Log -Message "Successfully removed VM from Azure"

                        $_.NetworkProfile.NetworkInterfaces | ForEach-Object {
                            $NICName = Split-Path -Path $_.ID -leaf
                            Get-AzureRmNetworkInterface | Where-Object {$_.Name -eq $NICName} | Remove-AzureRmNetworkInterface -Force
                        }
                        Write-Log -Message "Successfully removed $VMName vm NIC"

                        # Support to remove managed disks
                        if($a.StorageProfile.OsDisk.ManagedDisk ) {
                                                       
                            if($OSDisk){
                            foreach($ODisk in $OSDisk){
                            Get-AzureRmDisk -ResourceGroupName $_.ResourceGroupName -DiskName $ODisk | Remove-AzureRmDisk -Force
                            }
                            }
                                                        
                            if($DataDisks){
                            foreach($DDisk in $DataDisks){
                            Get-AzureRmDisk -ResourceGroupName $_.ResourceGroupName -DiskName $DDisk | Remove-AzureRmDisk -Force
                            }
                            }
                        }
                        # Support to remove unmanaged disks (from Storage Account Blob)
                        else {
                            # This assumes that OSDISK and DATADisks are on the same blob storage account
                            # Modify the function if that is not the case.
                            $saname = ($a.StorageProfile.OsDisk.Vhd.Uri -split '\.' | Select -First 1) -split '//' |  Select -Last 1
                            $sa = Get-AzureRmStorageAccount | Where-Object {$_.StorageAccountName -eq $saname}
        
                            # Remove DATA disks
                            $a.StorageProfile.DataDisks | foreach {
                                $disk = $_.Vhd.Uri | Split-Path -Leaf
                                Get-AzureStorageContainer -Name vhds -Context $Sa.Context |
                                Get-AzureStorageBlob -Blob  $disk |
                                Remove-AzureStorageBlob
                                Write-Log -Message "Removed DataDisk $disk successfully"  
                            }
                            
        
                            # Remove OSDisk disk
                            $disk = $a.StorageProfile.OsDisk.Vhd.Uri | Split-Path -Leaf
                            Get-AzureStorageContainer -Name vhds -Context $Sa.Context |
                            Get-AzureStorageBlob -Blob  $disk |
                            Remove-AzureStorageBlob

                            Write-Log -Message "Removed OSDisk $disk successfully"
                
                            # Remove Boot Diagnostic
                            $diagVMName=0
                            $diag=$_.Name.ToLower()
                            $diagVMName=$diag -replace '[\-]', ''
                            $dCount=$diagVMName.Length
                                        if($dCount -cgt 9){
                                            $digsplt=$diagVMName.substring(0,9)
                                            $diagVMName=$digsplt
                                            }
                            $diagContainerName = ('bootdiagnostics-{0}-{1}' -f $diagVMName, $_.VmId)
                            Set-AzureRmCurrentStorageAccount -Context $sa.Context
                            Remove-AzureStorageContainer -Name $diagContainerName -Force
                            Write-Log -Message "Successfully removed boot diagnostic"

                        }

                        #$avSet=Get-AzureRmVM | Where-Object {$_.Name -eq $VMName} | Remove-AzureRmAvailabilitySet -Force
                        $avset=Get-AzureRmAvailabilitySet -ResourceGroupName $a.ResourceGroupName
                        if($avset.VirtualMachinesReferences.id -eq $null){
                        $removeavset=Get-AzureRmAvailabilitySet -ResourceGroupName $a.ResourceGroupName -ErrorAction SilentlyContinue | Remove-AzureRmAvailabilitySet -Force
                        Write-Log -Message "Successfully removed availabilityset"
                        }
                        $checkResources=Get-AzureRmResource -ResourceGroupName $a.ResourceGroupName
                        if(!$checkResources){
                        $removeRg=Remove-AzureRmResourceGroup -Name $a.ResourceGroupName -Force
                        Write-Log -Message "Successfully removed ResourceGroup"
                        }
                        
                }
                
                #Removing VM from domain controller and DNS Record
                $result=Invoke-Command -ComputerName $DControllerVM -Credential $AdminCredentials -ScriptBlock{
                Param($ZoneName,$VMName)
                Get-ADComputer -Identity $VMName | Remove-ADObject -Recursive -confirm:$false
                Remove-DnsServerResourceRecord -ZoneName $ZoneName -RRType "A" -Name $VMName -Force -Confirm:$false
                } -ArgumentList($ZoneName,$VMName) -ErrorAction SilentlyContinue
                if($result){
                Write-Log -Message "Successfully removed $VMName from domaincontroller"
                Write-Log -Message "successfully removed dns record of $VMName"
                }
                }
                else{
                $vmProvisioning=Get-AzureRmVM | Where-Object {$_.Name -eq $VMName} | Stop-AzureRmVM -Force
                            
                            if($vmProvisioning.Status -eq "Succeeded"){
                            write-log -Message "VM has been stopped: $VMName"
                            }
                            else
                            {
                            write-log -Error "$VMName VM cannot be stopped"
                            }
                }
                }

                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
			
                #DSC Portion Log
                class RdsSessionHost
                {
                  [string]$TenantName
                  [string]$HostPoolName
                  [string]$SessionHostName
                  [int]$TimeoutInMin = 500

                  RdsSessionHost () {}

                  RdsSessionHost ($TenantName,$HostPoolName,$SessionHostName) {
                    $this.TenantName = $TenantName
                    $this.HostPoolName = $HostPoolName
                    $this.SessionHostName = $SessionHostName
                  }

                  RdsSessionHost ($TenantName,$HostPoolName,$SessionHostName,$TimeoutInMin) {

                    if ($TimeoutInMin -gt 800)
                    {
                      Write-Output "TimeoutInMin is too high, maximum value is 800"

                    }

                    $this.TenantName = $TenantName
                    $this.HostPoolName = $HostPoolName
                    $this.SessionHostName = $SessionHostName
                    $this.TimeoutInMin = $TimeoutInMin
                  }

                  hidden [object] _SessionHost ([string]$operation)
                  {
                    if ($operation -ne "get" -and $operation -ne "set")
                    {
                      Write-Output "RdsSessionHost: Invalid operation: $operation. Valid Operations are get or set"
                    }


                    $specificToSet = @{ $true = "-AllowNewSession `$true"; $false = "" }[$operation -eq "set"]
                    $commandToExecute = "$operation-RdsSessionHost -TenantName `$this.TenantName -HostPoolName `$this.HostPoolName -Name `$this.SessionHostName -ErrorAction SilentlyContinue $specificToSet"


                    $sessionHost = (Invoke-Expression $commandToExecute)



                    $StartTime = Get-Date
                    while ($sessionHost -eq $null)
                    {
                      Start-Sleep -Seconds (60..120 | Get-Random)
                      Write-Output "RdsSessionHost: Retrying Add SessionHost..."
                      $sessionHost = (Invoke-Expression $commandToExecute)



                      if ((Get-Date).Subtract($StartTime).Minutes -gt $this.TimeoutInMin)
                      {
                        if ($sessionHost -eq $null)
                        {
                          Write-Output "RdsSessionHost: An error ocurred while adding session host:`nSessionHost:$this.SessionHostname`nHostPoolName:$this.HostPoolNmae`nTenantName:$this.TenantName`nError Message: $($error[0] | Out-String)"
                          return $null
                        }
                      }
                    }

                    return $sessionHost
                  }
  
                  [object] SetSessionHost () {


                    if ([string]::IsNullOrEmpty($this.TenantName) -or [string]::IsNullOrEmpty($this.HostPoolName) -or [string]::IsNullOrEmpty($this.HostPoolName))
                    {
                      return $null
                    }
                    else
                    {

                      return ($this._SessionHost("set"))
                    }
                  }

                  [object] GetSessionHost () {



                    if ([string]::IsNullOrEmpty($this.TenantName) -or [string]::IsNullOrEmpty($this.HostPoolName) -or [string]::IsNullOrEmpty($this.HostPoolName))
                    {
                      return $null
                    }
                    else
                    {
                      return ($this._SessionHost("get"))
                    }
                  }
                }

				
                #Adding new vm instance to existing hostpool                 
                 $CheckRegistery = Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent" -ErrorAction SilentlyContinue

                    Write-Log -Message "Checking whether VM is Registered with RDInfraAgent"

                    if ($CheckRegistery){

                        Write-Log -Message "VM was already registered with RDInfraAgent, script execution was stopped"

                    }
                    else {
    
                        Write-Log -Message "VM was not registered with RDInfraAgent, script is executing now"
                    }
					
					#Getting fqdn of rdsh vm
					$SessionHostName = (Get-WmiObject win32_computersystem).DNSHostName + "." + (Get-WmiObject win32_computersystem).Domain
					Write-Log -Message "Getting fully qualified domain name of RDSH VM: $SessionHostName"

                
                if (!$CheckRegistery){
                
                                $HPName = Get-RdsHostPool -TenantName $TenantName -Name $HostPoolName -ErrorAction SilentlyContinue
									Write-Log -Message "Hostpool exists inside tenant: $TenantName"


									Write-Log -Message "Checking Hostpool UseResversconnect is true or false"
									# Cheking UseReverseConnect is true or false
									if ($HPName.UseReverseConnect -eq $False) {

									  Write-Log -Message "Usereverseconnect is false, it will be changed to true"
									  Set-RdsHostPool -TenantName $TenantName -Name $HostPoolName -UseReverseConnect $true
									}
									else {
									  Write-Log -Message "Hostpool Usereverseconnect already enabled as true"
									}
									
									#Exporting existed rdsregisterationinfo of hostpool
									$Registered = Export-RdsRegistrationInfo -TenantName $TenantName -HostPoolName $HostPoolName -ErrorAction SilentlyContinue
									$registrationToken = $Registered.Token
									$reglog = $registered | Out-String
									Write-Log -Message "Exported Rds RegisterationInfo into variable 'Registered': $reglog"
									$systemdate = (Get-Date)
									#$Tokenexpiredate = $Registered.ExpirationUtc #June Codebit
									$Tokenexpiredate = $Registered.expirationtime #July Codebit
									$difference = $Tokenexpiredate - $systemdate
									Write-Log -Message "Calculating date and time of expiration with system date and time"
									if ($difference -lt 0 -or $Registered -eq 'null') {
									  Write-Log -Message "Registerationinfo expired, creating new registeration info with hours $Hours"
									  $Registered = New-RdsRegistrationInfo -TenantName $TenantName -HostPoolName $HostPoolName -ExpirationHours $Hours
									  $registrationToken = $Registered.Token
									}
									else {
									  $reglogexpired = $Tokenexpiredate | Out-String -Stream
									  Write-Log -Message "Registerationinfo not expired and expiring on $reglogexpired"
									}
									#Executing DeployAgent psl file in rdsh vm and add to hostpool
									$DAgentInstall = .\DeployAgent.ps1 -ComputerName $SessionHostName -AgentBootServiceInstaller ".\RDAgentBootLoaderInstall\" -AgentInstaller ".\RDInfraAgentInstall\" -SxSStackInstaller ".\RDInfraSxSStackInstall\" -AdminCredentials $adminCredentials -RegistrationToken $registrationToken -StartAgent $true -rdshIs1809OrLater $rdshIs1809OrLaterBool -EnableSxSStackScriptFile ".\enablesxsstackrc.ps1"
									Write-Log -Message "DeployAgent Script was successfully executed and RDAgentBootLoader,RDAgent,StackSxS installed inside VM for existing hostpool: $HostPoolName `n$DAgentInstall"
									#add host vm to hostpool
									[Microsoft.RDInfra.RDManagementData.RdMgmtSessionHost]$addRdsh = ([RdsSessionHost]::new($TenantName,$HostPoolName,$SessionHostName)).GetSessionHost()
									Write-Log -Message "host object content: `n$($addRdsh | Out-String)"
									$rdshName = $addRdsh.Name | Out-String -Stream
									$poolName = $addRdsh.HostPoolName | Out-String -Stream
									Write-Log -Message "Successfully added $rdshName VM to $poolName"
                           
                            }
							if ($rdshIs1809OrLaterBool) {
							  Write-Log -Message "Activating Windows 10 Multi Session VM"
							  ActivateWin10 -ActivationKey $ActivationKey

							  Write-Log -Message "Rebooting VM"
							  Shutdown -r -t 90
							}