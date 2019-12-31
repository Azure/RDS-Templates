<#

.SYNOPSIS
add an instance to hostpool.

.DESCRIPTION
This script will add an instance to existing hostpool.
The supported Operating Systems Windows Server 2016/windows 10 multisession.

.ROLE
Readers

#>
param(
	[Parameter(mandatory = $true)]
	[string]$RDBrokerURL,

	[Parameter(mandatory = $true)]
	[string]$definedTenantGroupName,

	[Parameter(mandatory = $true)]
	[string]$TenantName,

	[Parameter(mandatory = $true)]
	[string]$HostPoolName,

	[Parameter(mandatory = $true)]
	[string]$Hours,

	[Parameter(mandatory = $true)]
	[pscredential]$TenantAdminCredentials,

	# [Parameter(mandatory = $true)]
	# [pscredential]$AdAdminCredentials,

	[Parameter(mandatory = $false)]
	[string]$isServicePrincipal = "False",

	[Parameter(mandatory = $false)]
	[AllowEmptyString()]
	[string]$AadTenantId = ""

	# [Parameter(mandatory = $true)]
	# [string]$SubscriptionId,


	# [Parameter(mandatory = $true)]
	# [int]$userLogoffDelayInMinutes,

	# [Parameter(mandatory = $true)]
	# [string]$userNotificationMessege,

	# [Parameter(mandatory = $true)]
	# [string]$messageTitle,

	# [Parameter(mandatory = $true)]
	# [string]$deleteordeallocateVMs,

	# [Parameter(mandatory = $false)]
	# [string]$DomainName

)

$ScriptPath = [System.IO.Path]::GetDirectoryName($PSCommandPath)

# Dot sourcing Functions.ps1 file
.(Join-Path $ScriptPath "Functions.ps1")

# Setting ErrorActionPreference to stop script execution when error occurs
$ErrorActionPreference = "Stop"

# Testing if it is a ServicePrincipal and validade that AadTenant ID in this case is not null or empty
ValidateServicePrincipal -IsServicePrincipal $isServicePrincipal -AADTenantId $AadTenantId

Write-Log -Message "Creating a folder inside rdsh vm for extracting deployagent zip file"
$DeployAgentLocation = "C:\DeployAgent"
ExtractDeploymentAgentZipFile -ScriptPath $ScriptPath -DeployAgentLocation $DeployAgentLocation

Write-Log -Message "Changing current folder to Deployagent folder: $DeployAgentLocation"
Set-Location "$DeployAgentLocation"


# Checking if RDInfragent is registered or not in rdsh vm
$CheckRegistry = Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent" -ErrorAction SilentlyContinue

Write-Log -Message "Checking whether VM was Registered with RDInfraAgent"


if ($CheckRegistry)
{
    Write-Log -Message "VM was already registered with RDInfraAgent, script execution was stopped"
    return
}
else
{
	Write-Log -Message "VM not registered with RDInfraAgent, script execution will continue"

	# Importing Windows Virtual Desktop PowerShell module
	Import-Module .\PowershellModules\Microsoft.RDInfra.RDPowershell.dll

	Write-Log -Message "Imported Windows Virtual Desktop PowerShell modules successfully"


	# Authenticating to Windows Virtual Desktop
	try
	{
		if ($isServicePrincipal -eq "True")
		{
			Write-Log -Message "Authenticating using service principal $TenantAdminCredentials.username and Tenant id: $AadTenantId "
			$authentication = Add-RdsAccount -DeploymentUrl $RDBrokerURL -Credential $TenantAdminCredentials -ServicePrincipal -TenantId $AadTenantId
		}
		else
		{
			Write-Log -Message "Authenticating using user $($TenantAdminCredentials.username) "
			$authentication = Add-RdsAccount -DeploymentUrl $RDBrokerURL -Credential $TenantAdminCredentials
		}
	}
	catch
	{
		Write-Log -Error "Windows Virtual Desktop Authentication Failed, Error:`n$_"
		throw "Windows Virtual Desktop Authentication Failed, Error:`n$_"
	}

	$obj = $authentication | Out-String

	if ($authentication)
	{
		Write-Log -Message "Windows Virtual Desktop Authentication successfully Done. Result:`n$obj"
	}
	else
	{
		Write-Log -Error "Windows Virtual Desktop Authentication Failed, Error:`n$obj"
		throw "Windows Virtual Desktop Authentication Failed, Error:`n$obj"
	}

	# Set context to the appropriate tenant group
	$currentTenantGroupName = (Get-RdsContext).TenantGroupName
	if ($definedTenantGroupName -ne $currentTenantGroupName) {
		Write-Log -Message "Running switching to the $definedTenantGroupName context"
		Set-RdsContext -TenantGroupName $definedTenantGroupName
	}
	try
	{
		$tenants = Get-RdsTenant -Name "$TenantName"
		if (!$tenants)
		{
			Write-Log "No tenants exist or you do not have proper access."
		}
	}
	catch
	{
		Write-Log -Message $_
		throw $_
	}

	# Checking if host pool exists.
	Write-Log -Message "Checking Hostpool exists inside the Tenant"
	$HostPool = Get-RdsHostPool -TenantName "$TenantName" -Name "$HostPoolName" -ErrorAction SilentlyContinue
	if ($HostPool)
	{
		Write-Log -Message "Hostpool exists inside tenant: $TenantName"

        # Getting fqdn of rdsh vm
        $SessionHostName = (Get-WmiObject win32_computersystem).DNSHostName + "." + (Get-WmiObject win32_computersystem).Domain
        Write-Log -Message "Getting fully qualified domain name of RDSH VM: $SessionHostName"

        # Obtaining Registration Info
        $Registered = New-RdsRegistrationInfo -TenantName $TenantName -HostPoolName $HostPoolName -ExpirationHours $Hours -ErrorAction SilentlyContinue
        if (-not $Registered)
        {
            $Registered = Export-RdsRegistrationInfo -TenantName $TenantName -HostPoolName $HostPoolName
            $obj = $Registered | Out-String
            Write-Log -Message "Exported Rds RegistrationInfo into variable 'Registered': $obj"
        }
        else
        {
            $obj = $Registered | Out-String
            Write-Log -Message "Created new Rds RegistrationInfo into variable 'Registered': $obj"
        }

        # Executing DeployAgent psl file in rdsh vm and add to hostpool
        Write-Log "AgentInstaller is $DeployAgentLocation\RDAgentBootLoaderInstall, InfraInstaller is $DeployAgentLocation\RDInfraAgentInstall"

        $DAgentInstall = .\DeployAgent.ps1 -AgentBootServiceInstallerFolder "$DeployAgentLocation\RDAgentBootLoaderInstall" `
            -AgentInstallerFolder "$DeployAgentLocation\RDInfraAgentInstall" `
            -RegistrationToken $Registered.Token `
            -StartAgent $true

        Write-Log -Message "DeployAgent Script was successfully executed and RDAgentBootLoader,RDAgent installed inside VM for existing hostpool: $HostPoolName`n$DAgentInstall"

        # Get Session Host Info
        Write-Log -Message "Getting rdsh host $SessionHostName information"

        [PsRdsSessionHost]$pssh = [PsRdsSessionHost]::new("$TenantName","$HostPoolName",$SessionHostName)
        [Microsoft.RDInfra.RDManagementData.RdMgmtSessionHost]$rdsh = $pssh.GetSessionHost()
        Write-Log -Message "RDSH object content: `n$($rdsh | Out-String)"

        $rdshName = $rdsh.SessionHostName | Out-String -Stream
        $poolName = $rdsh.hostpoolname | Out-String -Stream
        
        Write-Log -Message "Waiting for session host return when in available status"
        $AvailableSh = $pssh.GetSessionHostWhenAvailable()
        if ($null -ne $AvailableSh) {
            Write-Log -Message "Session host $($rdsh.SessionHostName) is now in Available state"
        }
        else {
            Write-Log -Message "Session host $($rdsh.SessionHostName) not in Available state, wait timed out (threshold is $($rdsh.TimeoutInSec) seconds)"
        }

        Write-Log -Message "Successfully added $rdshName VM to $poolName"
	}
	else
	{
		Write-Log -Error "$HostpoolName Hostpool does not exist in $TenantName Tenant"
		throw "$HostpoolName Hostpool does not exist in $TnenatName Tenant"
	}
}
