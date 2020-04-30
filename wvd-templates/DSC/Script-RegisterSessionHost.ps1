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
    throw "$HostpoolName Hostpool does not exist in $TenantName Tenant"
}

Write-Log -Message "Hostpool exists inside tenant: $TenantName"

# Getting fqdn (session host name) of rdsh vm
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

# Executing DeployAgent ps1 file in rdsh vm and add to hostpool
Write-Log "AgentInstaller is $DeployAgentLocation\RDAgentBootLoaderInstall, InfraInstaller is $DeployAgentLocation\RDInfraAgentInstall"

$DAgentInstall = .\DeployAgent.ps1 -AgentBootServiceInstallerFolder "$DeployAgentLocation\RDAgentBootLoaderInstall" `
    -AgentInstallerFolder "$DeployAgentLocation\RDInfraAgentInstall" `
    -RegistrationToken $Registered.Token `
    -StartAgent $true

Write-Log -Message "DeployAgent Script was successfully executed and RDAgentBootLoader, RDAgent were installed inside VM for existing hostpool: $HostPoolName`n$DAgentInstall"

# Get Session Host Info
Write-Log -Message "Getting RDSH session host info for '$SessionHostName'"

# Wait for the session host to be available
$StartTime = Get-Date
$SessionHost = $null
$TimeOutInSec = 15 * 60 # 15 min
$WaitTimeInSec = 0
$MaxWaitTimeInSec = 5 * 60 # 5 min
$DesiredStates = GetSessionHostDesiredStates

# note: best case scenario: it takes about a min for the session host to become available but it might take longer for larger deployments because of API calls throttling
Write-Log -Message "Wait for sessions host to be in any of the desired states: $($DesiredStates -join ', ')"
while ((!$SessionHost -or $SessionHost.Status -notin $DesiredStates) -and (get-date).Subtract($StartTime).TotalSeconds -lt $TimeOutInSec) {
    $WaitTimeInSec += 60
    if ($WaitTimeInSec -gt $MaxWaitTimeInSec) {
        $WaitTimeInSec = $MaxWaitTimeInSec
    }
    write-log "$(if (!$SessionHost) { "Session host record doesn't exist yet" } else { "Session host is in '$($SessionHost.Status)' state" }), continue waiting ($WaitTimeInSec sec)"
    Start-Sleep -Seconds $WaitTimeInSec
    
    $SessionHost = Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostPoolName -Name $SessionHostName -ErrorAction SilentlyContinue
}

Write-Log -Message "RDSH object content: `n$($SessionHost | Out-String)"

if (!$SessionHost) {
    throw "RD Agent failed to register VM '$SessionHostName' to HostPool '$HostPoolName'"
}
if ($SessionHost.Status -in $DesiredStates) {
    Write-Log -Message "Session host is now in '$($SessionHost.Status)' state"
}
else {
    Write-Log -Err "Session host is not in any of the desired states: $($DesiredStates -join ', '). Wait timed out (threshold is $TimeOutInSec seconds)"
}

# check if the session host was successfully registered to host pool, note that the error is thrown because the TestScript configuration of DSC may not be run after SetScript (this script)
Write-Log -Message "Check RD Infra registry to see if RD Agent is registered"
$RegistryCheckObj = IsRDAgentRegistryValidForRegistration
if (!$RegistryCheckObj.result) {
    throw "RD Agent failed to register VM '$SessionHostName' to HostPool '$HostPoolName' ($($RegistryCheckObj.msg))"
}

Write-Log -Message "Successfully registered VM '$SessionHostName' to HostPool '$HostPoolName'"