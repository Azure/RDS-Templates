param(
	[Parameter(mandatory = $true)]
	[string]$RDBrokerURL,

	[Parameter(mandatory = $true)]
	[string]$InitializeDBSecret,

	[Parameter(mandatory = $false)]
	[string]$TenantName,

    [Parameter(mandatory = $true)]
	[string]$HostPoolName,

	[Parameter(mandatory = $false)]
	[string]$Description,

   
	[Parameter(mandatory = $false)]
	[string]$FriendlyName,


	[Parameter(mandatory = $true)]
	[int]$MaxSessionLimit,

	[Parameter(mandatory = $true)]
	[string]$Hours,

	[Parameter(mandatory = $true)]
	[string]$FileURI,

	[Parameter(mandatory = $true)]
	[string]$DelegateAdminUsername,

	[Parameter(mandatory = $true)]
	[string]$DelegateAdminpassword,


	[Parameter(mandatory = $true)]
	[string]$DomainAdminUsername,

	[Parameter(mandatory = $true)]
	[string]$DomainAdminPassword
)


#Downloading the DeployAgent zip file to rdsh vm
Invoke-WebRequest -Uri $fileURI -OutFile "C:\DeployAgent.zip"
Start-Sleep -Seconds 60

#Creating a folder inside rdsh vm for extracting deployagent zip file
New-Item -Path "C:\DeployAgent" -ItemType directory -Force -ErrorAction SilentlyContinue
Expand-Archive "C:\DeployAgent.zip" -DestinationPath "C:\DeployAgent" -ErrorAction SilentlyContinue
Set-Location "C:\DeployAgent"

#Checking if RDInfragent is registered or not in rdsh vm
$CheckRegistery = Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent" -ErrorAction SilentlyContinue

#Getting fqdn of rdsh vm

if (!$CheckRegistery) {
	Start-Sleep 240
    #Importing RDMI PowerShell module
    Import-Module .\PowershellModules\Microsoft.RDInfra.RDPowershell.dll
	$Securepass = ConvertTo-SecureString -String $DelegateAdminpassword -AsPlainText -Force
	$Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($DelegateAdminUsername,$Securepass)
	$DAdminSecurepass = ConvertTo-SecureString -String $DomainAdminPassword -AsPlainText -Force
	$domaincredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($DomainAdminUsername,$DAdminSecurepass)
    $SessionHostName = (Get-WmiObject win32_computersystem).DNSHostName + "." + (Get-WmiObject win32_computersystem).Domain
	#Setting RDS Context
	Set-RdsContext -DeploymentUrl $RDBrokerURL -Credential $Credentials
	Write-Host "executed success"
	$HPName = Get-RdsHostPool -TenantName $TenantName -Name $HostPoolName -ErrorAction SilentlyContinue
	if ($HPName) {
        #Exporting existed rdsregisterationinfo of hostpool
		$Registered = Export-RdsRegistrationInfo -TenantName $TenantName -HostPoolName $HostPoolName
		
        #Executing DeployAgent psl file in rdsh vm and add to hostpool
        .\DeployAgent.ps1 -ComputerName $SessionHostName -AgentInstaller ".\RDInfraAgentInstall\Microsoft.RDInfra.RDAgent.Installer-x64.msi" -SxSStackInstaller ".\RDInfraSxSStackInstall\Microsoft.RDInfra.StackSxS.Installer-x64.msi" -InitializeDBSecret $InitializeDBSecret -AdminCredentials $domaincredentials -TenantName $TenantName -PoolName $HostPoolName -RegistrationToken $Registered.Token -StartAgent $true
		
	}

	else
	
    {
		# creating new hostpool
        $Hostpool = New-RdsHostPool -TenantName $TenantName -Name $HostPoolName -Description $Description -FriendlyName $FriendlyName
		
        #Registering hostpool with 365 days
        $ToRegister = New-RdsRegistrationInfo -TenantName $TenantName -HostPoolName $HostPoolName -ExpirationHours $Hours
		
        #Executing DeployAgent psl file in rdsh vm and add to hostpool
        .\DeployAgent.ps1 -ComputerName $SessionHostName -AgentInstaller ".\RDInfraAgentInstall\Microsoft.RDInfra.RDAgent.Installer-x64.msi" -SxSStackInstaller ".\RDInfraSxSStackInstall\Microsoft.RDInfra.StackSxS.Installer-x64.msi" -InitializeDBSecret $InitializeDBSecret -AdminCredentials $domaincredentials -TenantName $TenantName -PoolName $HostPoolName -RegistrationToken $ToRegister.Token -StartAgent $true
		
	}
        #add rdsh vm to hostpool
        Set-RdsSessionHost -TenantName $TenantName -HostPoolName $HostPoolName -Name $SessionHostName -AllowNewSession $true -MaxSessionLimit $MaxSessionLimit
}
#Remove-Item -Path "C:\DeployAgent.zip" -Recurse -force
#Remove-Item -Path "C:\DeployAgent" -Recurse -Force

