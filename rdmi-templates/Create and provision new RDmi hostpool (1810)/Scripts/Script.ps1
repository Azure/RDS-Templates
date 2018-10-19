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
    [string]$FileURI,

    [Parameter(mandatory = $true)]
    [string]$TenantAdminUPN,

    [Parameter(mandatory = $true)]
    [string]$TenantAdminPassword,

    [Parameter(mandatory = $true)]
    [string]$localAdminUserName,

    [Parameter(mandatory = $true)]
    [string]$localAdminPassword,

    [Parameter(mandatory = $true)]
    [string]$rdshIs1809OrLater,

    [Parameter(mandatory = $false)]
    [string]$isServicePrincipal = "False",

    [Parameter(Mandatory = $false)]
    [string]$AadTenantId
)



function Write-Log { 
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

# Setting to Tls12 due to Azure web app security requirements
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$DeployAgentLocation = "C:\DeployAgent"
$rdshIs1809OrLaterBool = ($rdshIs1809OrLater -eq "True")

# Downloading the DeployAgent zip file to rdsh vm
Invoke-WebRequest -Uri $fileURI -OutFile "C:\DeployAgent.zip"
Write-Log -Message "Downloaded DeployAgent.zip into this location C:\"

# Creating a folder inside rdsh vm for extracting deployagent zip file
New-Item -Path "$DeployAgentLocation" -ItemType directory -Force -ErrorAction SilentlyContinue
Write-Log -Message "Created a new folder 'DeployAgent' inside VM"
Expand-Archive "C:\DeployAgent.zip" -DestinationPath "$DeployAgentLocation" -ErrorAction SilentlyContinue
Write-Log -Message "Extracted the 'Deployagent.zip' file into '$DeployAgentLocation' folder inside VM"
Set-Location "$DeployAgentLocation"
Write-Log -Message "Setting up the location of Deployagent folder"

# Checking if RDInfragent is registered or not in rdsh vm
$CheckRegistry = Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent" -ErrorAction SilentlyContinue

Write-Log -Message "Checking whether VM was Registered with RDInfraAgent"

if ($CheckRegistry) {
    Write-Log -Message "VM was already registered with RDInfraAgent, script execution was stopped"
}
else {
    Write-Log -Message "VM was not registered with RDInfraAgent, script is executing"
}


if (!$CheckRegistry) {
    
    # Importing WVD PowerShell module
    Import-Module .\PowershellModules\Microsoft.RDInfra.RDPowershell.dll
    Write-Log -Message "Imported RDMI PowerShell modules successfully"
    $Securepass = ConvertTo-SecureString -String $TenantAdminPassword -AsPlainText -Force
    $Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($TenantAdminUPN, $Securepass)
    $AdminSecurepass = ConvertTo-SecureString -String $localAdminPassword -AsPlainText -Force
    $adminCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($localAdminUserName, $AdminSecurepass)

    # Getting fqdn of rdsh vm
    $SessionHostName = (Get-WmiObject win32_computersystem).DNSHostName + "." + (Get-WmiObject win32_computersystem).Domain
    Write-Log  -Message "Getting fully qualified domain name of RDSH VM: $SessionHostName"

    # Authenticating to WVD
    if ($isServicePrincipal -eq "True"){
        $authentication = Add-RdsAccount -DeploymentUrl $RDBrokerURL -Credential $Credentials -ServicePrincipal -TenantId $AadTenantId 
    } else {
        $authentication = Add-RdsAccount -DeploymentUrl $RDBrokerURL -Credential $Credentials
    }
    $obj = $authentication | Out-String

    if ($authentication) {
        Write-Log -Message "RDMI Authentication successfully Done. Result: `
    $obj"  
    }
    else {
        Write-Log -Error "RDMI Authentication Failed, Error: `
    $obj"
    
    }

    # Set context to the appropriate tenant group
    Write-Log "Running switching to the $definedTenantGroupName context"
    Set-RdsContext -TenantGroupName $definedTenantGroupName
    try {
        $tenants = Get-RdsTenant
        if( !$tenants ) {
            Write-Log "No tenants exist or you do not have proper access."
        }
    } catch {
        Write-Log -Message ""
    }

    # Checking if host pool exists. If not, create a new one with the given HostPoolName
    $HPName = Get-RdsHostPool -TenantName $TenantName -Name $HostPoolName -ErrorAction SilentlyContinue
    Write-Log -Message "Checking Hostpool exists inside the Tenant"
    if ($HPName) {
        Write-log -Message "Hostpool exists inside tenant: $TenantName"
    }
    else {
        $HPName = New-RdsHostPool -TenantName $TenantName -Name $HostPoolName -Description $Description -FriendlyName $FriendlyName

        $HName = $HPName.name | Out-String -Stream
        Write-Log -Message "Successfully created new Hostpool: $HName"
    }

    # Setting UseReverseConnect property to true
    Write-Log -Message "Checking Hostpool UseResversconnect is true or false"
    if ($HPName.UseReverseConnect -eq $False) {
        Write-Log -Message "UseReverseConnect is false, it will be changed to true"
        Set-RdsHostPool -TenantName $TenantName -Name $HostPoolName -UseReverseConnect $true
    }
    else {
        Write-Log -Message "Hostpool UseReverseConnect already enabled as true"
    }
    
    # Creating registration token
    $Registered = $null
    try {
        $Registered = Export-RdsRegistrationInfo -TenantName $TenantName -HostPoolName $HostPoolName
        if (!$Registered) {
            $Registered = New-RdsRegistrationInfo -TenantName $TenantName -HostPoolName $HostPoolName -ExpirationHours $Hours
            Write-Log -Message "Created new Rds RegistrationInfo into variable 'Registered': $Registered"
        } else {
            Write-Log -Message "Exported Rds RegistrationInfo into variable 'Registered': $Registered"
        }
    } catch {
        $Registered = New-RdsRegistrationInfo -TenantName $TenantName -HostPoolName $HostPoolName -ExpirationHours $Hours
        Write-Log -Message "Created new Rds RegistrationInfo into variable 'Registered': $Registered"
    }

    # Executing DeployAgent psl file in rdsh vm and add to hostpool
    Write-Log "AgentInstaller is $DeployAgentLocation\RDAgentBootLoaderInstall, InfraInstaller is $DeployAgentLocation\RDInfraAgentInstall, SxS is $DeployAgentLocation\RDInfraSxSStackInstall"
    $DAgentInstall = .\DeployAgent.ps1 -ComputerName $SessionHostName -AgentBootServiceInstallerFolder "$DeployAgentLocation\RDAgentBootLoaderInstall" -AgentInstallerFolder "$DeployAgentLocation\RDInfraAgentInstall" -SxSStackInstallerFolder "$DeployAgentLocation\RDInfraSxSStackInstall" -EnableSxSStackScriptFolder "$DeployAgentLocation\EnableSxSStackScript" -AdminCredentials $adminCredentials -TenantName $TenantName -PoolName $HostPoolName -RegistrationToken $Registered.Token -StartAgent $true -rdshIs1809OrLater $rdshIs1809OrLaterBool
    Write-Log -Message "DeployAgent Script was successfully executed and RDAgentBootLoader,RDAgent,StackSxS installed inside VM for existing hostpool: $HostPoolName `
    $DAgentInstall"

    #add rdsh vm to hostpool
    $addRdsh = Set-RdsSessionHost -TenantName $TenantName -HostPoolName $HostPoolName -Name $SessionHostName -AllowNewSession $true
    $rdshName = $addRdsh.name | Out-String -Stream
    $poolName = $addRdsh.hostpoolname | Out-String -Stream
    Write-Log -Message "Successfully added $rdshName VM to $poolName"
}
