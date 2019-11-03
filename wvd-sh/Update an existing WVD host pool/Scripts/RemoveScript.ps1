param(
    [Parameter(mandatory = $true)]
    [string]$RDBrokerURL,

    [Parameter(mandatory = $true)]
    [string]$TenantName,

    [Parameter(mandatory = $true)]
    [string]$HostPoolName,

    [Parameter(mandatory = $true)]
    [string]$TenantAdminUPN,

    [Parameter(mandatory = $true)]
    [string]$TenantAdminPassword,

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
    [string]$localAdminUsername,
    
    [Parameter(mandatory = $true)]
    [string]$localAdminPassword
)

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
        
        #AzureLogin Credentials
        $Securepass=ConvertTo-SecureString -String $TenantAdminPassword -AsPlainText -Force
        $Credentials=New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList($TenantAdminUPN, $Securepass)

        #Domain Credentials
        $AdminSecurepass = ConvertTo-SecureString -String $localAdminPassword -AsPlainText -Force
        $AdminCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($localAdminUsername, $AdminSecurepass)

        #Setting RDS Context
        $authentication=Set-RdsContext -DeploymentUrl $RDBrokerURL -Credential $Credentials
        
        $obj = $authentication | Out-String
    
        if ($authentication) {
            Write-Log -Message "Imported RDMI PowerShell modules successfully done"
            Write-Log -Message "RDMI Authentication successfully done. Result: `
       $obj"  
        }
        else {
            Write-Log -Error "RDMI Authentication Failed, Error: `
       $obj"
        
        }
             

             $allshs=Get-RdsSessionHost -TenantName $tenantname -HostPoolName $HostPoolName
             $allshslog=$allshs.name | Out-String
             Write-Log -Message "All Session Host servers in $HostPoolName :`
             $allshslog"
             
             $shsNames=0
             $shsNames=@()
             
             $rdsUserSessions=Get-RdsUserSession -TenantName $TenantName -HostPoolName $HostPoolName
             if($rdsUserSessions){
             foreach($rdsUserSession in $rdsUserSessions){
             
             $sessionId=$rdsUserSession.SessionId
             
             $shName=$rdsUserSession.SessionHostName
             
             $username=$rdsUserSession.UserPrincipalName | Out-String
             
             $shsNames+=$shName
             
             #Send-RdsUserSessionMessage -TenantName $TenantName -HostPoolName $HostPoolName -SessionHostName $shName -SessionId $sessionId -MessageTitle $messageTitle -MessageBody $userNotificationMessage -NoConfirm:$false
             
             #Write-log -message "Sent a rdsusersesionmessage to $username and sessionid was $sessionId"
             
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
                        
                        #Get Domaincontroller VMname
                        $DName=Get-ADDomainController -Discover -DomainName $DomainName
                        $DControllerVM=$DName.Name
                        $ZoneName=$DName.Forest
                
                
            #Import-Module AzureRM.Resources
            #Import-Module Azurerm
            $AzSecurepass=ConvertTo-SecureString -String $TenantAdminPassword -AsPlainText -Force
            $AzCredentials=New-Object System.Management.Automation.PSCredential($TenantAdminUPN, $AzSecurepass)
            $loginResult=Login-AzureRmAccount -SubscriptionId $SubscriptionId  -Credential $AzCredentials
            if ($loginResult.Context.Subscription.Id -eq $SubscriptionId)
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
                
                Remove-RdsSessionHost -TenantName $tenantname -HostPoolName $HostPoolName -Name $sh -Force $true
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
                            #Write-Warning -Message "Removing NIC: $NICName"
                            #Get-AzureRmNetworkInterface -ResourceGroupName $ResourceGroup -Name $NICName | Remove-AzureRmNetworkInterface -Force
                            Get-AzureRmNetworkInterface | Where-Object {$_.Name -eq $NICName} | Remove-AzureRmNetworkInterface -Force
                        }
                        Write-Log -Message "Successfully removed $VMName vm NIC"

                        # Support to remove managed disks
                        if($a.StorageProfile.OsDisk.ManagedDisk ) {
                            ($DataDisks + $OSDisk) | ForEach-Object {
                                #Write-Warning -Message "Removing Disk: $_"
                                #Get-AzureRmDisk -ResourceGroupName $ResourceGroup -DiskName $_ | Remove-AzureRmDisk -Force
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
                #Adding new vm instance to existing hostpool                 
                 $CheckRegistery = Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent" -ErrorAction SilentlyContinue

                    Write-Log -Message "Checking whether VM is Registered with RDInfraAgent"

                    if ($CheckRegistery){

                        Write-Log -Message "VM was already registered with RDInfraAgent, script execution was stopped"

                    }
                    else {
    
                        Write-Log -Message "VM was not registered with RDInfraAgent, script is executing now"
                    }

                
                if (!$CheckRegistery){
                
                                $HPName = Get-RdsHostPool -TenantName $TenantName -Name $HostPoolName -ErrorAction SilentlyContinue
                                Write-Log -Message "Checking Hostpool exists inside the Tenant"
                                if ($HPName) {
                                Write-log -Message "Hostpool exists inside tenant: $TenantName" 
                                Write-Log -Message "Checking Hostpool UseResversconnect is true or false"
                                if ($HPName.UseReverseConnect -eq $False) {
                                    Write-Log -Message "Usereverseconnect is false, it will be changed to true"
                                                Set-RdsHostPool -TenantName $TenantName -Name $HostPoolName -UseReverseConnect $true
                                            }
                                            else{
                                        Write-Log -Message "Hostpool Usereverseconnect already enabled as true"
                                        }

                                
                                
                                $SessionHostName = (Get-WmiObject win32_computersystem).DNSHostName + "." + (Get-WmiObject win32_computersystem).Domain
                                
                                $Registered = Export-RdsRegistrationInfo -TenantName $TenantName -HostPoolName $HostPoolName
                                $reglog = $registered | Out-String
                                Write-Log -Message "Exported Rds RegisterationInfo into variable 'Registered': $reglog"
                                
                                 $systemdate = (GET-DATE)
                                 $Tokenexpiredate = $Registered.ExpirationUtc
                                    $difference = $Tokenexpiredate - $systemdate
                                    write-log -Message "Calculating date and time of expiration with system date and time"
                                    if ($difference -lt 0 -or $Registered -eq 'null') {
                                        write-log -Message "Registerationinfo has expired, Creating new registeration info with hours $Hours"
                                        $Registered = New-RdsRegistrationInfo -TenantName $TenantName -HostPoolName $HostPoolName -ExpirationHours $Hours
                                    }
                                    else {

                                        $reglogexpired = $Tokenexpiredate | Out-String -Stream
                                        Write-Log -Message "Registerationinfo is not expired, expiring in $reglogexpired"
                                    }

                                            $DAgentInstall = .\DeployAgent.ps1 -ComputerName $SessionHostName -AgentBootServiceInstaller ".\RDAgentBootLoaderInstall\Microsoft.RDInfra.RDAgentBootLoader.Installer-x64.msi" -AgentInstaller ".\RDInfraAgentInstall\Microsoft.RDInfra.RDAgent.Installer-x64.msi" -SxSStackInstaller ".\RDInfraSxSStackInstall\Microsoft.RDInfra.StackSxS.Installer-x64.msi" -AdminCredentials $AdminCredentials -TenantName $TenantName -PoolName $HostPoolName -RegistrationToken $Registered.Token -StartAgent $true
                                            Write-Log -Message "DeployAgent Script was successfully executed and RDAgentBootloader,RDAgent,StackSxS installed inside VM for existing hostpool: $HostPoolName `
                                            $DAgentInstall"
                                            $addRdsh = Set-RdsSessionHost -TenantName $TenantName -HostPoolName $HostPoolName -Name $SessionHostName -AllowNewSession $true
                                            $rdshName = $addRdsh.name | Out-String -Stream
                                            $poolName = $addRdsh.hostpoolname | Out-String -Stream
                                            Write-Log -Message "Successfully added $rdshName VM to $poolName"
                                }
                           
                            }