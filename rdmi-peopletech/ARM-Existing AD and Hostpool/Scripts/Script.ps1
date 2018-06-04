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


try {
    #Downloading the DeployAgent zip file to rdsh vm
    Invoke-WebRequest -Uri $fileURI -OutFile "C:\DeployAgent.zip"
    Write-Log -Message "Downloaded DeployAgent.zip into this location C:\"

    #Creating a folder inside rdsh vm for extracting deployagent zip file
    New-Item -Path "C:\DeployAgent" -ItemType directory -Force -ErrorAction SilentlyContinue
    Write-Log -Message "Created a new folder which is 'DeployAgent' inside VM"
    Expand-Archive "C:\DeployAgent.zip" -DestinationPath "C:\DeployAgent" -ErrorAction SilentlyContinue
    Write-Log -Message "Extracted the 'Deployagent.zip' file into 'C:\Deployagent' folder inside VM"
    Set-Location "C:\DeployAgent"
    Write-Log -Message "Setting up the location of Deployagent folder"

    #Checking if RDInfragent is registered or not in rdsh vm
    $CheckRegistery = Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent" -ErrorAction SilentlyContinue

    Write-Log -Message "Checking whether VM was Registered with RDInfraAgent or not"

    if ($CheckRegistery) {
        Write-Log -Message "VM was already registered with RDInfraAgent, script execution was stopped"

    }
    else {

        Write-Log -Message "VM was not registered with RDInfraAgent, script is executing"
    }


    if (!$CheckRegistery) {
        #Importing RDMI PowerShell module
    
        Import-Module .\PowershellModules\Microsoft.RDInfra.RDPowershell.dll
        Write-Log -Message "Imported RDMI PowerShell modules successfully"
        $Securepass = ConvertTo-SecureString -String $DelegateAdminpassword -AsPlainText -Force
        $Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($DelegateAdminUsername, $Securepass)
        $DAdminSecurepass = ConvertTo-SecureString -String $DomainAdminPassword -AsPlainText -Force
        $domaincredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($DomainAdminUsername, $DAdminSecurepass)

        #Getting fqdn of rdsh vm
        $SessionHostName = (Get-WmiObject win32_computersystem).DNSHostName + "." + (Get-WmiObject win32_computersystem).Domain
        Write-Log  -Message "Getting fully qualified domain name of RDSH VM: $SessionHostName"
    
        #Setting RDS Context
        $authentication = Set-RdsContext -DeploymentUrl $RDBrokerURL -Credential $Credentials
        $obj = $authentication | Out-String
    
        if ($authentication) {
            Write-Log -Message "RDMI Authentication successfully Done. Result: `
       $obj"  
        }
        else {
            Write-Log -Error "RDMI Authentication Failed, Error: `
       $obj"
        
        }
    
        $HPName = Get-RdsHostPool -TenantName $TenantName -Name $HostPoolName -ErrorAction SilentlyContinue
        Write-Log -Message "Checking Hostpool is existing or not inside the Tenant"

        if ($HPName) {
            Write-log -Message "Hostpool is existed inside the tenant"

            Write-Log -Message "Checking Hostpool UseResversconnect is true or false"
            # Cheking UseReverseConnect is true or false
            if ($HPName.UseReverseConnect -eq $False) {
                Write-Log -Message "Usereverseconnect is false, it will be changed to true"
                Set-RdsHostPool -TenantName $TenantName -Name $HostPoolName -UseReverseConnect $true
            }

            #Exporting existed rdsregisterationinfo of hostpool
            $Registered = Export-RdsRegistrationInfo -TenantName $TenantName -HostPoolName $HostPoolName
            $reglog = $registered | Out-String -Stream
            Write-Log -Message "Exported Rds RegisterationInfo into variable 'Registered' $reglog"
            $systemdate = (GET-DATE)
            $Tokenexpiredate = $Registered.ExpirationUtc
            $difference = $Tokenexpiredate - $systemdate
            write-log -Message "Calculating date and time whether expired or not? with system date and time"
            if ($difference -lt 0 -or $Registered -eq 'null') {
                write-log -Message "Registerationinfo was expired, now again creating new registeration info with hours $Hours"
                $Registered = New-RdsRegistrationInfo -TenantName $TenantName -HostPoolName $HostPoolName -ExpirationHours $Hours
            }
            else {
                $reglogexpired = $Tokenexpiredate | Out-String -Stream
                Write-Log -Message "Registerationinfo is not expired, expired in $reglogexpired"
            }
            #Executing DeployAgent psl file in rdsh vm and add to hostpool
            $DAgentInstall = .\DeployAgent.ps1 -ComputerName $SessionHostName -AgentInstaller ".\RDInfraAgentInstall\Microsoft.RDInfra.RDAgent.Installer-x64.msi" -SxSStackInstaller ".\RDInfraSxSStackInstall\Microsoft.RDInfra.StackSxS.Installer-x64.msi" -AdminCredentials $domaincredentials -TenantName $TenantName -PoolName $HostPoolName -RegistrationToken $Registered.Token -StartAgent $true
            Write-Log -Message "DeployAgent Script was successfully executed and installed RDAgent, sidebyside inside VM for existing hostpool: $HostPoolName `
        $DAgentInstall"
        }

        else {
            # creating new hostpool
            $Hostpool = New-RdsHostPool -TenantName $TenantName -Name $HostPoolName -Description $Description -FriendlyName $FriendlyName
            $HName = $hostpool.name | Out-String -Stream
            Write-Log -Message "Successfully created new Hostpool: $HName"
        
            # setting up usereverseconnect as true
            Write-Log -Message "setting up the UserReverseconnect value as true for Hostpool: $HName"
            Set-RdsHostPool -TenantName $TenantName -Name $HostPoolName -UseReverseConnect $true
        
        
            #Registering hostpool with 365 days
            Write-log -Message "Creating new registeration info for hostpool:$HName with expired hours $Hours"
            $ToRegister = New-RdsRegistrationInfo -TenantName $TenantName -HostPoolName $HostPoolName -ExpirationHours $Hours
            $newRegInfo=$ToRegister.ExpirationUtc | Out-String -Stream
            Write-Log -Message "Successfully registered $HName, expiration date: $newRegInfo"
        
            #Executing DeployAgent psl file in rdsh vm and add to hostpool
            .\DeployAgent.ps1 -ComputerName $SessionHostName -AgentInstaller ".\RDInfraAgentInstall\Microsoft.RDInfra.RDAgent.Installer-x64.msi" -SxSStackInstaller ".\RDInfraSxSStackInstall\Microsoft.RDInfra.StackSxS.Installer-x64.msi" -AdminCredentials $domaincredentials -TenantName $TenantName -PoolName $HostPoolName -RegistrationToken $ToRegister.Token -StartAgent $true
        
            Write-Log -Message "DeployAgent Script was successfully executed and installed RDAgent, sidebyside inside VM for new $HName `
        $DAgentInstall"
        }
        #add rdsh vm to hostpool
        $addRdsh = Set-RdsSessionHost -TenantName $TenantName -HostPoolName $HostPoolName -Name $SessionHostName -AllowNewSession $true -MaxSessionLimit $MaxSessionLimit
        $rdshName = $addRdsh.name | Out-String
        $poolName = $addRdsh.hostpoolname | Out-String
        Write-Log -Message "Successfully added $rdshName VM to $poolName"
    }

}
catch {
    Write-log -Error $_.Exception.Message

}

