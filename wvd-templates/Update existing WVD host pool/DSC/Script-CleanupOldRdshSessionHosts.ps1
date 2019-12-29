<#

.SYNOPSIS
Removing old hosts from Existing Hostpool.

.DESCRIPTION
This script will Remove/Stop old sessionhost servers from existing Hostpool.
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

	# [Parameter(mandatory = $true)]
	# [string]$Hours,

	[Parameter(mandatory = $true)]
	[pscredential]$TenantAdminCredentials,

	[Parameter(mandatory = $true)]
	[pscredential]$AdAdminCredentials,

	[Parameter(mandatory = $false)]
	[string]$isServicePrincipal = "False",

	[Parameter(mandatory = $false)]
	[AllowEmptyString()]
	[string]$AadTenantId = "",

	# [Parameter(mandatory = $true)]
	# [string]$SubscriptionId,

	[Parameter(mandatory = $true)]
	[int]$userLogoffDelayInMinutes,

	[Parameter(mandatory = $true)]
	[string]$userNotificationMessege,

	[Parameter(mandatory = $true)]
	[string]$messageTitle,

	[Parameter(mandatory = $true)]
	[string]$deleteordeallocateVMs,

	[Parameter(mandatory = $true)]
	[string]$DomainName,

	[Parameter(mandatory = $true)]
	[int]$rdshNumberOfInstances,

	[Parameter(mandatory = $true)]
	[string]$rdshPrefix

)

$ScriptPath = [System.IO.Path]::GetDirectoryName($PSCommandPath)

# Dot sourcing Functions.ps1 file
.(Join-Path $ScriptPath "Functions.ps1")

# Setting ErrorActionPreference to stop script execution when error occurs
$ErrorActionPreference = "Stop"

# Testing if it is a ServicePrincipal and validade that AadTenant ID in this case is not null or empty
ValidateServicePrincipal -IsServicePrincipal $isServicePrincipal -AADTenantId $AadTenantId

# extract RD Powershell module from deploy agent .zip
Write-Log -Message "Creating a folder inside rdsh vm for extracting RD Powershell module"
$DeployAgentLocation = "C:\DeployAgent"
ExtractDeploymentAgentZipFile -ScriptPath $ScriptPath -DeployAgentLocation $DeployAgentLocation

Write-Log -Message "Changing current folder to Deployagent folder: $DeployAgentLocation"
Set-Location "$DeployAgentLocation"

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
if (!$HostPool)
{
	Write-Log -Error "$HostpoolName Hostpool does not exist in $TenantName Tenant"
	throw "$HostpoolName Hostpool does not exist in $TnenatName Tenant"
}

Write-Log -Message "Hostpool exists inside tenant: $TenantName"

$rdshIsServer = $true

$OSVersionInfo = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"

if ($null -ne $OSVersionInfo) {
	if ($null -ne $OSVersionInfo.InstallationType) {
		$rdshIsServer = @{ $true = $true; $false = $false }[$OSVersionInfo.InstallationType -eq "Server"]
	}
}

# collect new session hosts
$NewSessionHostNames = @{}
for ($i = 0; $i -lt $rdshNumberOfInstances; ++$i) {
	$NewSessionHostNames.Add("${rdshPrefix}${i}.${DomainName}", $true)
}

Write-Log -Message "List of new Session Host servers in $HostPoolName :`n$($NewSessionHostNames.Keys | Out-String)"

$ListOfSessionHosts = Get-RdsSessionHost -TenantName "$Tenantname" -HostPoolName "$HostPoolName"
$ShslogObj = $ListOfSessionHosts.SessionHostName | Out-String
Write-Log -Message "List of Session Host servers in $HostPoolName :`n$ShslogObj"

#Collect the session hostnames
$SessionHostNames = 0
$SessionHostNames = @()
foreach ($SessionHost in $ListOfSessionHosts) {
	if (!$NewSessionHostNames.ContainsKey($SessionHost.SessionHostName))
	{
		$SessionHostNames += $SessionHost.SessionHostName
	}
}

$UniqueSessionHostNames = $SessionHostNames | Select-Object -Unique


$ListOfUserSessions = Get-RdsUserSession -TenantName "$TenantName" -HostPoolName "$HostPoolName"
if ($ListOfUserSessions) {
	foreach ($UserSession in $ListOfUserSessions) {
		$SessionHostName = $UserSession.SessionHostName
		if ($NewSessionHostNames.ContainsKey($SessionHostName))
		{
			continue
		}
		$SessionId = $UserSession.SessionId
		$UserPrincipalName = $UserSession.UserPrincipalName | Out-String

		# Before removing session hosts from hostpool, sending User session message to User
		Send-RdsUserSessionMessage -TenantName "$TenantName" -HostPoolName "$HostPoolName" -SessionHostName "$SessionHostName" -SessionId $SessionId -MessageTitle $messageTitle -MessageBody $userNotificationMessege -NoUserPrompt
		Write-Log -Message "Sent a user session message to $UserPrincipalName and sessionid was $SessionId"
	}
}
$allShsNames = $UniqueSessionHostNames | Out-String
Write-Log -Message "Collected old sessionhosts and remove from $HostPoolName hostpool : `n$allShsNames"

if ($rdshIsServer) {
	Add-WindowsFeature RSAT-AD-PowerShell
	#Get Domaincontroller
	$DName = Get-ADDomainController -Discover -DomainName $DomainName
	$DControllerVM = $DName.Name
	$ZoneName = $DName.Forest
}

$ConvertSeconds = $userLogoffDelayInMinutes * 60
Start-Sleep -Seconds $ConvertSeconds

foreach ($SessionHostName in $UniqueSessionHostNames) {

	# Keeping session host in drain mode
	$shsDrain = Set-RdsSessionHost -TenantName "$Tenantname" -HostPoolName "$HostPoolName" -Name "$SessionHostName" -AllowNewSession $false
	$shsDrainlog = $shsDrain | Out-String
	Write-Log -Message "Sesssion host server in drain mode : `n$shsDrainlog"

	Remove-RdsSessionHost -TenantName "$TenantName" -HostPoolName "$HostPoolName" -Name "$SessionHostName" -Force
	Write-Log -Message "Successfully $SessionHostName removed from hostpool"

	$VMName = $SessionHostName.Split(".")[0]

	if ($deleteordeallocateVMs -eq "Delete") {

		# Remove the VM's and then remove the datadisks, osdisk, NICs
		Get-AzureRmVM | Where-Object { $_.Name -eq $VMName } | ForEach-Object {
			$a = $_
			$DataDisks = @($_.StorageProfile.DataDisks.Name)
			$OSDisk = @($_.StorageProfile.OSDisk.Name)
			Write-Log -Message "Removing $VMName VM and associated resources from Azure"

			#Write-Warning -Message "Removing VM: $($_.Name)"
			$_ | Remove-AzureRmVM -Force -Confirm:$false
			Write-Log -Message "Successfully removed VM from Azure"

			$_.NetworkProfile.NetworkInterfaces | ForEach-Object {
				$NICName = Split-Path -Path $_.Id -Leaf
				Get-AzureRmNetworkInterface | Where-Object { $_.Name -eq $NICName } | Remove-AzureRmNetworkInterface -Force
			}
			Write-Log -Message "Successfully removed $VMName vm NIC"

			# Support to remove managed disks
			if ($a.StorageProfile.OSDisk.ManagedDisk) {

				if ($OSDisk) {
					foreach ($ODisk in $OSDisk) {
						Get-AzureRmDisk -ResourceGroupName $_.ResourceGroupName -DiskName $ODisk | Remove-AzureRmDisk -Force
					}
				}

				if ($DataDisks) {
					foreach ($DDisk in $DataDisks) {
						Get-AzureRmDisk -ResourceGroupName $_.ResourceGroupName -DiskName $DDisk | Remove-AzureRmDisk -Force
					}
				}
			}
			# Support to remove unmanaged disks (from Storage Account Blob)
			else {
				# This assumes that OSDISK and DATADisks are on the same blob storage account
				# Modify the function if that is not the case.
				$saname = ($a.StorageProfile.OSDisk.Vhd.Uri -split '\.' | Select-Object -First 1) -split '//' | Select-Object -Last 1
				$sa = Get-AzureRmStorageAccount | Where-Object { $_.StorageAccountName -eq $saname }

				# Remove DATA disks
				$a.StorageProfile.DataDisks | ForEach-Object {
					$disk = $_.Vhd.Uri | Split-Path -Leaf
					Get-AzureStorageContainer -Name vhds -Context $Sa.Context |
					Get-AzureStorageBlob -Blob $disk |
					Remove-AzureStorageBlob
					Write-Log -Message "Removed DataDisk $disk successfully"
				}

				# Remove OSDisk disk
				$disk = $a.StorageProfile.OSDisk.Vhd.Uri | Split-Path -Leaf
				Get-AzureStorageContainer -Name vhds -Context $Sa.Context |
				Get-AzureStorageBlob -Blob $disk |
				Remove-AzureStorageBlob

				Write-Log -Message "Removed OSDisk $disk successfully"

				# Remove Boot Diagnostic
				$diagVMName = 0
				$diag = $_.Name.ToLower()
				$diagVMName = $diag -replace '[\-]',''
				$dCount = $diagVMName.Length
				if ($dCount -cgt 9) {
					$digsplt = $diagVMName.substring(0,9)
					$diagVMName = $digsplt
				}
				$diagContainerName = ('bootdiagnostics-{0}-{1}' -f $diagVMName,$_.VmId)
				Set-AzureRmCurrentStorageAccount -Context $sa.Context
				Remove-AzureStorageContainer -Name $diagContainerName -Force
				Write-Log -Message "Successfully removed boot diagnostic"
			}

			#$avSet=Get-AzureRmVM | Where-Object {$_.Name -eq $VMName} | Remove-AzureRmAvailabilitySet -Force
			$avset = Get-AzureRmAvailabilitySet -ResourceGroupName $a.ResourceGroupName
			if ($avset.VirtualMachinesReferences.Id -eq $null) {
				Get-AzureRmAvailabilitySet -ResourceGroupName $a.ResourceGroupName -ErrorAction SilentlyContinue | Remove-AzureRmAvailabilitySet -Force
				Write-Log -Message "Successfully removed availabilityset"
			}
			$checkResources = Get-AzureRmResource -ResourceGroupName $a.ResourceGroupName
			if (!$checkResources) {
				Remove-AzureRmResourceGroup -Name $a.ResourceGroupName -Force
				Write-Log -Message "Successfully removed ResourceGroup"
			}
		}

		#Removing VM from domain controller and DNS Record
		if ($rdshIsServer) {
			$result = Invoke-Command -ComputerName $DControllerVM -Credential $AdAdminCredentials -ScriptBlock {
				param($ZoneName,$VMName)
				Get-ADComputer -Identity $VMName | Remove-ADObject -Recursive -Confirm:$false
				Remove-DnsServerResourceRecord -ZoneName $ZoneName -RRType "A" -Name $VMName -Force -Confirm:$false
			} -ArgumentList ($ZoneName,$VMName) -ErrorAction SilentlyContinue
			if ($result) {
				Write-Log -Message "Successfully removed $VMName from domaincontroller"
				Write-Log -Message "successfully removed dns record of $VMName"
			}
		}
	}
	else {
		#Deallocate the VM
		Get-AzureRmVM | Where-Object { $_.Name -eq $VMName } | Stop-AzureRmVM -Force
		$StateOftheVM = $false
		while (!$StateOftheVM) {
			$ProvisioningState = Get-AzureRmVM -Status | Where-Object { $_.Name -eq $VMName }
			if ($ProvisioningState.PowerState -eq "VM deallocated") {
				$StateOftheVM = $true
				Write-Log -Message "VM has been stopped: $VMName"
			}
			else {
				Write-Log -Message "Waiting for to stop $VMName VM..."
			}
		}
	}
}

$AllSessionHosts = Get-RdsSessionHost -TenantName "$TenantName" -HostPoolName "$HostPoolName"
$OldSessionHosts = $AllSessionHosts.SessionHostName | Where-Object { !$NewSessionHostNames.ContainsKey($_) }
if ($OldSessionHosts) {
	Write-Log -Error "Old Session Hosts were not removed from hostpool $HostPoolName"
	throw "Old Session Hosts were not removed from hostpool $HostPoolName"
}