<#

.SYNOPSIS
Creating Hostpool and add sessionhost servers to existing/new Hostpool.

.DESCRIPTION
This script add sessionhost servers to existing/new Hostpool
The supported Operating Systems Windows Server 2016.

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

    [Parameter(mandatory = $false)]
    [string]$Description,

    [Parameter(mandatory = $false)]
    [string]$FriendlyName,

    [Parameter(mandatory = $true)]
    [string]$Hours,

    [Parameter(mandatory = $true)]
    [PSCredential]$TenantAdminCredentials,

    [Parameter(mandatory = $true)]
    [PSCredential]$ADAdminCredentials,

    [Parameter(mandatory = $false)]
    [string]$isServicePrincipal = "False",

    [Parameter(Mandatory = $false)]
    [string]$AadTenantId,

    [Parameter(Mandatory = $true)]
    [string]$EnablePersistentDesktop="False"
)

function Write-Log
{ 
    [CmdletBinding()] 
    param
    ( 
        [Parameter(Mandatory = $false)] 
        [string]$Message,
        [Parameter(Mandatory = $false)] 
        [string]$Error 
    ) 
     
    try
    { 
        $DateTime = Get-Date -Format ‘MM-dd-yy HH:mm:ss’ 
        $Invocation = "$($MyInvocation.MyCommand.Source):$($MyInvocation.ScriptLineNumber)" 
        if ($Message)
        {
            Add-Content -Value "$DateTime - $Invocation - $Message" -Path "$([environment]::GetEnvironmentVariable('TEMP', 'Machine'))\ScriptLog.log" 
        }
        else
        {
            Add-Content -Value "$DateTime - $Invocation - $Error" -Path "$([environment]::GetEnvironmentVariable('TEMP', 'Machine'))\ScriptLog.log" 
        }
    } 
    catch
    { 
        Write-Error $_.Exception.Message 
    } 
}

class PsRdsSessionHost
{
    [string]$TenantName = [string]::Empty
    [string]$HostPoolName = [string]::Empty
    [string]$SessionHostName = [string]::Empty
    [int]$TimeoutInMin=900 

    PsRdsSessionHost() {}

    PsRdsSessionHost([string]$TenantName, [string]$HostPoolName, [string]$SessionHostName) {
        $this.TenantName = $TenantName
        $this.HostPoolName = $HostPoolName
        $this.SessionHostName = $SessionHostName
    }

    PsRdsSessionHost([string]$TenantName, [string]$HostPoolName, [string]$SessionHostName, [int]$TimeoutInMin) {
        
        if ($TimeoutInMin -gt 1800)
        {
            throw "TimeoutInMin is too high, maximum value is 1800"
        }

        $this.TenantName = $TenantName
        $this.HostPoolName = $HostPoolName
        $this.SessionHostName = $SessionHostName
        $this.TimeoutInMin = $TimeoutInMin
    }

    hidden [object] _trySessionHost([string]$operation)
    {
        if ($operation -ne "get" -and $operation -ne "set")
        {
            throw "PsRdsSessionHost: Invalid operation: $operation. Valid Operations are get or set"
        }

        $specificToSet=@{$true = "-AllowNewSession `$true"; $false = ""}[$operation -eq "set"]
        $commandToExecute="$operation-RdsSessionHost -TenantName `$this.TenantName -HostPoolName `$this.HostPoolName -Name `$this.SessionHostName -ErrorAction SilentlyContinue $specificToSet"

        $sessionHost = (Invoke-Expression $commandToExecute )

        $StartTime = Get-Date
        while ($sessionHost -eq $null)
        {
            Start-Sleep (60..120 | Get-Random)
            Write-Output "PsRdsSessionHost: Retrying Add SessionHost..."
            $sessionHost = (Invoke-Expression $commandToExecute)
    
            if ((get-date).Subtract($StartTime).Minutes -gt $this.TimeoutInMin)
            {
                if ($sessionHost -eq $null)
                {
                    Write-Output "PsRdsSessionHost: An error ocurred while adding session host:`nSessionHost:$this.SessionHostname`nHostPoolName:$this.HostPoolNmae`nTenantName:$this.TenantName`nError Message: $($error[0] | Out-String)"
                    return $null
                }
            }
        }

        return $sessionHost
    }

    [object] SetSessionHost() {

        if ([string]::IsNullOrEmpty($this.TenantName) -or [string]::IsNullOrEmpty($this.HostPoolName) -or [string]::IsNullOrEmpty($this.HostPoolName))
        {
            return $null
        }
        else
        {
            
            return ($this._trySessionHost("set"))
        }
    }
    
    [object] GetSessionHost() {

        if ([string]::IsNullOrEmpty($this.TenantName) -or [string]::IsNullOrEmpty($this.HostPoolName) -or [string]::IsNullOrEmpty($this.HostPoolName))
        {
            return $null
        }
        else
        {
            return ($this._trySessionHost("get"))
        }
    }
}

$ScriptPath = [system.io.path]::GetDirectoryName($PSCommandPath)

# Setting ErrorActionPreference to stop script execution when error occurs
$ErrorActionPreference = "Stop"

# Testing if it is a ServicePrincipal and validade that AadTenant ID in this case is not null or empty
if ($isServicePrincipal)
{
    if ([string]::IsNullOrEmpty($AadTenantId))
    {
        throw "When IsServicePrincipal = True, AadTenant ID is mandatory. Please provide a valid AadTenant ID."
    }
}

# Setting to Tls12 due to Azure web app security requirements
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$BlnEnablePersistentDesktop = [System.Convert]::ToBoolean($EnablePersistentDesktop)

$DeployAgentLocation = "C:\DeployAgent"

Write-Log -Message "Identifying if this VM is Build >= 1809"
$rdshIs1809OrLaterBool = $false
$rdshIsServer = $true
$OSVersionInfo = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
if ($OSVersionInfo -ne $null)
{
    if ($OSVersionInfo.ReleaseId -ne $null)
    {
        Write-Log -Message "Build: $($OSVersionInfo.ReleaseId)"
        $rdshIs1809OrLaterBool=@{$true = $true; $false = $false}[$OSVersionInfo.ReleaseId -ge 1809]
    }

    if ($OSVersionInfo.InstallationType -ne $null)
    {
        Write-Log -Message "OS Installation type: $($OSVersionInfo.InstallationType)"
        $rdshIsServer=@{$true = $true; $false = $false}[$OSVersionInfo.InstallationType -eq "Server"]
    }
}

Write-Log -Message "Creating a folder inside rdsh vm for extracting deployagent zip file"
if (Test-Path $DeployAgentLocation)
{
    Remove-Item -Path $DeployAgentLocation -Force -Confirm:$false -Recurse
}

New-Item -Path "$DeployAgentLocation" -ItemType directory -Force 

# Locating and extracting DeployAgent.zip
Write-Log -Message "Locating DeployAgent.zip within Custom Script Extension folder structure: $ScriptPath"
$DeployAgentFromRepo = (Get-ChildItem $ScriptPath\ -Filter DeployAgent.zip -Recurse | Select-Object).FullName
if ((-not $DeployAgentFromRepo) -or (-not (Test-Path $DeployAgentFromRepo)))
{
    throw "DeployAgent.zip file not found at $ScriptPath"
}

Write-Log -Message "Extracting 'Deployagent.zip' file into '$DeployAgentLocation' folder inside VM"
Expand-Archive $DeployAgentFromRepo -DestinationPath "$DeployAgentLocation" 

Write-Log -Message "Changing current folder to Deployagent folder: $DeployAgentLocation"
Set-Location "$DeployAgentLocation"

# Checking if RDInfragent is registered or not in rdsh vm
$CheckRegistry = Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent" -ErrorAction SilentlyContinue

Write-Log -Message "Checking whether VM was Registered with RDInfraAgent"

if ($CheckRegistry)
{
    Write-Log -Message "VM was already registered with RDInfraAgent, script execution was stopped"
}
else
{
    Write-Log -Message "VM not registered with RDInfraAgent, script execution will continue"

    # Importing WVD PowerShell module
    Import-Module .\PowershellModules\Microsoft.RDInfra.RDPowershell.dll

    Write-Log -Message "Imported RDMI PowerShell modules successfully"

    # Getting fqdn of rdsh vm
    $SessionHostName = (Get-WmiObject win32_computersystem).DNSHostName + "." + (Get-WmiObject win32_computersystem).Domain

    Write-Log  -Message "Getting fully qualified domain name of RDSH VM: $SessionHostName"

    # Authenticating to WVD
    if ($isServicePrincipal -eq "True")
    {
        $authentication = Add-RdsAccount -DeploymentUrl $RDBrokerURL -Credential $TenantAdminCredentials -ServicePrincipal -TenantId $AadTenantId 
    }
    else
    {
        $authentication = Add-RdsAccount -DeploymentUrl $RDBrokerURL -Credential $TenantAdminCredentials
    }
    $obj = $authentication | Out-String

    if ($authentication)
    {
        Write-Log -Message "RDMI Authentication successfully Done. Result:`n$obj"  
    }
    else
    {
        Write-Log -Error "RDMI Authentication Failed, Error:`n$obj"
        throw "RDMI Authentication Failed, Error:`n$obj"
    }

    # Set context to the appropriate tenant group
    Write-Log "Running switching to the $definedTenantGroupName context"
    Set-RdsContext -TenantGroupName $definedTenantGroupName
    try
    {
        $tenants = Get-RdsTenant -Name $TenantName
        if(!$tenants)
        {
            Write-Log "No tenants exist or you do not have proper access."
        }
    }
    catch
    {
        Write-Log -Message $_
        throw $_
    }

    # Checking if host pool exists. If not, create a new one with the given HostPoolName
    Write-Log -Message "Checking Hostpool exists inside the Tenant"
    $HostPool = Get-RdsHostPool -TenantName $TenantName -Name $HostPoolName -ErrorAction SilentlyContinue
    if ($HostPool)
    {
        Write-log -Message "Hostpool exists inside tenant: $TenantName"
    }
    else
    {
        $EnablePersistentDesktopOption=@{$true = "-Persistent"; $false = ""}[$BlnEnablePersistentDesktop -eq $true]
        $HostPool = Invoke-Expression( "New-RdsHostPool -TenantName `$TenantName -Name `$HostPoolName -Description `$Description -FriendlyName `$FriendlyName $EnablePersistentDesktopOption")
        $HName = $HostPool.name | Out-String -Stream
        Write-Log -Message "Successfully created new Hostpool: $HName"
    }

    # Setting UseReverseConnect property to true
    Write-Log -Message "Checking Hostpool UseResversconnect is true or false"
    if ($HostPool.UseReverseConnect -eq $False)
    {
        Write-Log -Message "UseReverseConnect is false, it will be changed to true"
        Set-RdsHostPool -TenantName $TenantName -Name $HostPoolName -UseReverseConnect $true
    }
    else
    {
        Write-Log -Message "Hostpool UseReverseConnect already enabled as true"
    }
    
    # Creating registration token
    $Registered = Export-RdsRegistrationInfo -TenantName $TenantName -HostPoolName $HostPoolName -ErrorAction SilentlyContinue
    if (!$Registered)
    {
        $Registered = New-RdsRegistrationInfo -TenantName $TenantName -HostPoolName $HostPoolName -ExpirationHours $Hours
        $obj =  $Registered | Out-String
        Write-Log -Message "Created new Rds RegistrationInfo into variable 'Registered': $obj"
    }
    else
    {
        $obj =  $Registered | Out-String
        Write-Log -Message "Exported Rds RegistrationInfo into variable 'Registered': $obj"
    }

    # Executing DeployAgent psl file in rdsh vm and add to hostpool
    Write-Log "AgentInstaller is $DeployAgentLocation\RDAgentBootLoaderInstall, InfraInstaller is $DeployAgentLocation\RDInfraAgentInstall, SxS is $DeployAgentLocation\RDInfraSxSStackInstall"
    $DAgentInstall = .\DeployAgent.ps1 -ComputerName $SessionHostName `
                                       -AgentBootServiceInstallerFolder "$DeployAgentLocation\RDAgentBootLoaderInstall" `
                                       -AgentInstallerFolder "$DeployAgentLocation\RDInfraAgentInstall" `
                                       -SxSStackInstallerFolder "$DeployAgentLocation\RDInfraSxSStackInstall" `
                                       -EnableSxSStackScriptFolder "$DeployAgentLocation\EnableSxSStackScript" `
                                       -AdminCredentials $ADAdminCredentials `
                                       -TenantName $TenantName `
                                       -PoolName $HostPoolName `
                                       -RegistrationToken $Registered.Token `
                                       -StartAgent $true `
                                       -rdshIs1809OrLater $rdshIs1809OrLaterBool
    
    Write-Log -Message "DeployAgent Script was successfully executed and RDAgentBootLoader,RDAgent,StackSxS installed inside VM for existing hostpool: $HostPoolName`n$DAgentInstall"

    # Get Session Host Info
    Write-Log -Message "Getting rdsh host $SessionHostName information"

    [Microsoft.RDInfra.RDManagementData.RdMgmtSessionHost]$rdsh = ([PsRdsSessionHost]::new($TenantName,$HostPoolName,$SessionHostName)).GetSessionHost()
    Write-Log -Message "RDSH object content: `n$($rdsh | Out-String)"

    $rdshName = $rdsh.SessionHostName | Out-String -Stream
    $poolName = $rdsh.hostpoolname | Out-String -Stream

    Write-Log -Message "Successfully added $rdshName VM to $poolName"
}
