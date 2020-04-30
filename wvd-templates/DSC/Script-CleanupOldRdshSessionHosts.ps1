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

    [Parameter(mandatory = $true)]
    [pscredential]$TenantAdminCredentials,

    [Parameter(mandatory = $true)]
    [pscredential]$AdAdminCredentials,

    [Parameter(mandatory = $false)]
    [string]$isServicePrincipal = "False",

    [Parameter(mandatory = $false)]
    [AllowEmptyString()]
    [string]$AadTenantId = "",

    [Parameter(mandatory = $true)]
    [string]$SubscriptionId,

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
    [string]$rdshPrefix,

    [Parameter(mandatory = $false)]
    [string]$RDPSModSource = 'attached'
)

$ScriptPath = [System.IO.Path]::GetDirectoryName($PSCommandPath)

# Dot sourcing Functions.ps1 file
. (Join-Path $ScriptPath "Functions.ps1")

# Setting ErrorActionPreference to stop script execution when error occurs
$ErrorActionPreference = "Stop"

write-log -message 'Script being executed: Cleanup old session hosts'

# Testing if it is a ServicePrincipal and validade that AadTenant ID in this case is not null or empty
ValidateServicePrincipal -IsServicePrincipal $isServicePrincipal -AADTenantId $AadTenantId

ImportRDPSMod -Source $RDPSModSource -ArtifactsPath $ScriptPath

# Authenticating to Windows Virtual Desktop
. AuthenticateRdsAccount -DeploymentUrl $RDBrokerURL -Credential $TenantAdminCredentials -ServicePrincipal:($isServicePrincipal -eq 'True') -TenantId $AadTenantId

SetTenantGroupContextAndValidate -TenantGroupName $definedTenantGroupName -TenantName $TenantName

# Checking if host pool exists.
Write-Log -Message "Checking Hostpool exists inside the Tenant"
$HostPool = Get-RdsHostPool -TenantName "$TenantName" -Name "$HostPoolName" -ErrorAction SilentlyContinue
if (!$HostPool) {
    throw "$HostpoolName Hostpool does not exist in $TenantName Tenant"
}

Write-Log -Message "Hostpool exists inside tenant: $TenantName"

$RequiredModules = @("AzureRM.Resources", "Azurerm.Profile", "Azurerm.Compute", "Azurerm.Network", "Azurerm.Storage")

Write-Log "checking if nuget package exists"

if (!(Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue -ListAvailable)) {
    Write-Log "installing nuget package inside vm: $env:COMPUTERNAME"
    Install-PackageProvider -Name nuget -Force
}
foreach ($ModuleName in $RequiredModules) {
    do {
        #Check if Module exists
        $InstalledModule = Get-InstalledModule -Name $ModuleName -ErrorAction SilentlyContinue
        if (!$InstalledModule) {
            Write-Log "Installing azureRMModule '$ModuleName' inside vm: $env:COMPUTERNAME"
            Install-Module $ModuleName -AllowClobber -Force
        }
    } until ($InstalledModule)
}

Import-Module AzureRM.Resources
Import-Module Azurerm.Profile
Import-Module Azurerm.Compute
Import-Module Azurerm.Network
Import-Module Azurerm.Storage

#Authenticate AzureRM
$authentication = $null
try {
    if ($isServicePrincipal -eq "True") {
        $authentication = Add-AzureRmAccount -Credential $TenantAdminCredentials -SubscriptionId $SubscriptionId -ServicePrincipal -TenantId $AadTenantId
    }
    else {
        $authentication = Add-AzureRmAccount -Credential $TenantAdminCredentials -SubscriptionId $SubscriptionId
    }
    if (!$authentication) {
        throw $authentication
    }
}
catch {
    throw [System.Exception]::new("Error authenticating AzureRM account, isServicePrincipal = $isServicePrincipal", $PSItem.Exception)
}
Write-Log -Message "AzureRM account authentication successful. Result:`n$($authentication | Out-String)"

if ($authentication.Context.Subscription.Id -ne $SubscriptionId) {
    Write-Log -Err "AzureRM auth subscription ID '$($authentication.Context.Subscription.Id)' doesn't match the subscription ID of the deployment '$SubscriptionId'"
}

# collect new session hosts
$NewSessionHostNames = @{ }
for ($i = 0; $i -lt $rdshNumberOfInstances; ++$i) {
    $NewSessionHostNames.Add("${rdshPrefix}${i}.${DomainName}".ToLower(), $true)
}

Write-Log -Message "List of new Session Host servers in $HostPoolName :`n$($NewSessionHostNames.Keys | Out-String)"

$ListOfSessionHosts = Get-RdsSessionHost -TenantName "$Tenantname" -HostPoolName "$HostPoolName"
$ShslogObj = $ListOfSessionHosts.SessionHostName | Out-String
Write-Log -Message "List of Session Host servers in $HostPoolName :`n$ShslogObj"

#Collect the session hostnames
$SessionHostNames = 0
$SessionHostNames = @()
foreach ($SessionHost in $ListOfSessionHosts) {
    if (!$NewSessionHostNames.ContainsKey($SessionHost.SessionHostName.ToLower())) {
        $SessionHostNames += $SessionHost.SessionHostName
    }
}

$UniqueSessionHostNames = $SessionHostNames | Select-Object -Unique


$ListOfUserSessions = Get-RdsUserSession -TenantName "$TenantName" -HostPoolName "$HostPoolName"
if ($ListOfUserSessions) {
    foreach ($UserSession in $ListOfUserSessions) {
        $SessionHostName = $UserSession.SessionHostName
        if ($NewSessionHostNames.ContainsKey($SessionHostName.ToLower())) {
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

$rdshIsServer = isRdshServer
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
                    Get-AzureStorageContainer -Name vhds -Context $Sa.Context | Get-AzureStorageBlob -Blob $disk | Remove-AzureStorageBlob
                    Write-Log -Message "Removed DataDisk $disk successfully"
                }

                # Remove OSDisk disk
                $disk = $a.StorageProfile.OSDisk.Vhd.Uri | Split-Path -Leaf
                Get-AzureStorageContainer -Name vhds -Context $Sa.Context | Get-AzureStorageBlob -Blob $disk | Remove-AzureStorageBlob

                Write-Log -Message "Removed OSDisk $disk successfully"

                # Remove Boot Diagnostic
                $diagVMName = 0
                $diag = $_.Name.ToLower()
                $diagVMName = $diag -replace '[\-]', ''
                $dCount = $diagVMName.Length
                if ($dCount -cgt 9) {
                    $digsplt = $diagVMName.substring(0, 9)
                    $diagVMName = $digsplt
                }
                $diagContainerName = ('bootdiagnostics-{0}-{1}' -f $diagVMName, $_.VmId)
                Set-AzureRmCurrentStorageAccount -Context $sa.Context
                Remove-AzureStorageContainer -Name $diagContainerName -Force
                Write-Log -Message "Successfully removed boot diagnostic"
            }

            #$avSet=Get-AzureRmVM | Where-Object {$_.Name -eq $VMName} | Remove-AzureRmAvailabilitySet -Force
            # //todo check if this VM belongs to avail set before deleting
            $avset = Get-AzureRmAvailabilitySet -ResourceGroupName $a.ResourceGroupName
            if ($null -eq $avset.VirtualMachinesReferences.Id) {
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
                param($ZoneName, $VMName)
                Get-ADComputer -Identity $VMName | Remove-ADObject -Recursive -Confirm:$false
                Remove-DnsServerResourceRecord -ZoneName $ZoneName -RRType "A" -Name $VMName -Force -Confirm:$false
            } -ArgumentList ($ZoneName, $VMName) -ErrorAction SilentlyContinue
            # //todo check: $result might be $null even if the above cmd succeeds
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
                Write-Log -Message "Waiting for $VMName VM to stop... [current state: $($ProvisioningState.PowerState)]"
            }
        }
    }
}

$AllSessionHosts = Get-RdsSessionHost -TenantName "$TenantName" -HostPoolName "$HostPoolName"
$OldSessionHosts = $AllSessionHosts.SessionHostName | Where-Object { !$NewSessionHostNames.ContainsKey($_.ToLower()) }
if ($OldSessionHosts) {
    throw "Old Session Hosts were not removed from hostpool $HostPoolName"
}