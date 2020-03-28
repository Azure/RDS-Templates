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

    [Parameter(mandatory = $false)]
    [string]$isServicePrincipal = "False",

    [Parameter(mandatory = $false)]
    [AllowEmptyString()]
    [string]$AadTenantId = "",

    [Parameter(mandatory = $false)]
    [string]$RDPSModSource = 'attached'
)

$ScriptPath = [System.IO.Path]::GetDirectoryName($PSCommandPath)

# Dot sourcing Functions.ps1 file
. (Join-Path $ScriptPath "Functions.ps1")

# Setting ErrorActionPreference to stop script execution when error occurs
$ErrorActionPreference = "Stop"

write-log -message 'Script being executed: Register session host'

# Testing if it is a ServicePrincipal and validade that AadTenant ID in this case is not null or empty
ValidateServicePrincipal -IsServicePrincipal $isServicePrincipal -AADTenantId $AadTenantId

Write-Log -Message "Creating a folder inside rdsh vm for extracting deployagent zip file"
$DeployAgentLocation = "C:\DeployAgent"
ExtractDeploymentAgentZipFile -ScriptPath $ScriptPath -DeployAgentLocation $DeployAgentLocation

Write-Log -Message "Changing current folder to Deployagent folder: $DeployAgentLocation"
Set-Location "$DeployAgentLocation"

ImportRDPSMod -Source $RDPSModSource -ArtifactsPath $ScriptPath

# Authenticating to Windows Virtual Desktop
. AuthenticateRdsAccount -DeploymentUrl $RDBrokerURL -Credential $TenantAdminCredentials -ServicePrincipal:($isServicePrincipal -eq 'True') -TenantId $AadTenantId

SetTenantGroupContextAndValidate -TenantGroupName $definedTenantGroupName -TenantName $TenantName

# Checking if host pool exists.
Write-Log -Message "Checking Hostpool exists inside the Tenant"
$HostPool = Get-RdsHostPool -TenantName "$TenantName" -Name "$HostPoolName" -ErrorAction SilentlyContinue
if (!$HostPool) {
    Write-Log -Error "$HostpoolName Hostpool does not exist in $TenantName Tenant"
    throw "$HostpoolName Hostpool does not exist in $TenantName Tenant"
}

Write-Log -Message "Hostpool exists inside tenant: $TenantName"

# Getting fqdn of rdsh vm
$SessionHostName = GetCurrSessionHostName
Write-Log -Message "Getting fully qualified domain name of RDSH VM: $SessionHostName"

# Obtaining Registration Info
$Registered = New-RdsRegistrationInfo -TenantName $TenantName -HostPoolName $HostPoolName -ExpirationHours $Hours -ErrorAction SilentlyContinue
if (-not $Registered) {
    $Registered = Export-RdsRegistrationInfo -TenantName $TenantName -HostPoolName $HostPoolName
    $obj = $Registered | Out-String
    Write-Log -Message "Exported Rds RegistrationInfo into variable 'Registered': $obj"
}
else {
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

[PsRdsSessionHost]$pssh = [PsRdsSessionHost]::new("$TenantName", "$HostPoolName", $SessionHostName)
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
    Write-Log -Error "Session host $($rdsh.SessionHostName) not in Available state, wait timed out (threshold is $($rdsh.TimeoutInSec) seconds)"
}

# check if the session host was successfully registered to host pool, note that the error is thrown because the TestScript configuration of DSC will not be run after SetScript (this script)
$IsSessionHostRegisterd = (& "$ScriptPath\Script-TestRegisterSessionHost.ps1" -RdBrokerURL $RDBrokerURL -DefinedTenantGroupName $definedTenantGroupName -TenantName $TenantName -HostPoolName $HostPoolName -TenantAdminCredentials $TenantAdminCredentials -isServicePrincipal $isServicePrincipal -aadTenantId $AadTenantId -RDPSModSource $RDPSModSource)
if (!$IsSessionHostRegisterd) {
    throw "RD Agent failed to register $rdshName VM to $poolName"
}

Write-Log -Message "Successfully added $rdshName VM to $poolName"