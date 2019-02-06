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
    [string]$localAdminPassword
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
    Write-Log -Message "Created a new folder 'DeployAgent' inside VM"
    Expand-Archive "C:\DeployAgent.zip" -DestinationPath "C:\DeployAgent" -ErrorAction SilentlyContinue
    Write-Log -Message "Extracted the 'Deployagent.zip' file into 'C:\Deployagent' folder inside VM"
    Set-Location "C:\DeployAgent"
    Write-Log -Message "Setting up the location of Deployagent folder"

    #Importing RDMI PowerShell module
    
    Import-Module .\PowershellModules\Microsoft.RDInfra.RDPowershell.dll
        
    $Securepass = ConvertTo-SecureString -String $TenantAdminPassword -AsPlainText -Force
    $Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($TenantAdminUPN, $Securepass)
    $AdminSecurepass = ConvertTo-SecureString -String $localAdminPassword -AsPlainText -Force
    $Admincredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($localAdminUserName, $AdminSecurepass)

    #Getting fqdn of rdsh vm
    $SessionHostName = (Get-WmiObject win32_computersystem).DNSHostName + "." + (Get-WmiObject win32_computersystem).Domain
    Write-Log  -Message "Getting fully qualified domain name of RDSH VM: $SessionHostName"
    
    #Setting RDS Context
    $authentication = Add-RdsAccount -DeploymentUrl $RDBrokerURL -Credential $Credentials
    $obj = $authentication | Out-String
    
    if ($authentication) {
        Write-Log -Message "Imported RDMI PowerShell modules successfully"
        Write-Log -Message "RDMI Authentication successfully Done. Result: `
       $obj"  
    }
    else {
        Write-Log -Error "RDMI Authentication Failed, Error: `
       $obj"
        
    }
    
    $HPName = Get-RdsHostPool -TenantName $TenantName -Name $HostPoolName -ErrorAction SilentlyContinue
    Write-Log -Message "Checking Hostpool exists inside the Tenant"

    if ($HPName) {
        $HPName = Get-RdsHostPool -TenantName $TenantName -Name $HostPoolName -ErrorAction SilentlyContinue
        Write-log -Message "Hostpool exists inside tenant: $TenantName"

        Write-Log -Message "Checking Hostpool UseResversconnect is true or false"
        # Cheking UseReverseConnect is true or false
        if ($HPName.UseReverseConnect -eq $False) {
            Write-Log -Message "Usereverseconnect is false, it will be changed to true"
            Set-RdsHostPool -TenantName $TenantName -Name $HostPoolName -UseReverseConnect $true
        }
        else {
            Write-Log -Message "Hostpool Usereverseconnect already enabled as true"
        }

        #Exporting existed rdsregisterationinfo of hostpool
        $Registered = Export-RdsRegistrationInfo -TenantName $TenantName -HostPoolName $HostPoolName
        $reglog = $registered | Out-String
        Write-Log -Message "Exported Rds RegisterationInfo into variable 'Registered': $reglog"
        $systemdate = (GET-DATE)
        $Tokenexpiredate = $Registered.ExpirationUtc
        $difference = $Tokenexpiredate - $systemdate
        write-log -Message "Calculating date and time expiration with system date and time"
        if ($difference -lt 0 -or $Registered -eq 'null') {
            write-log -Message "Registerationinfo expired, creating new registeration info with hours $Hours"
            $Registered = New-RdsRegistrationInfo -TenantName $TenantName -HostPoolName $HostPoolName -ExpirationHours $Hours
        }
        else {
            $reglogexpired = $Tokenexpiredate | Out-String -Stream
            Write-Log -Message "Registerationinfo not expired and expiring on $reglogexpired"
        }
        #Executing DeployAgent psl file in rdsh vm and add to hostpool
        $DAgentInstall = .\DeployAgent.ps1 -ComputerName $SessionHostName -AgentBootServiceInstaller ".\RDAgentBootLoaderInstall\Microsoft.RDInfra.RDAgentBootLoader.Installer-x64.msi" -AgentInstaller ".\RDInfraAgentInstall\Microsoft.RDInfra.RDAgent.Installer-x64.msi" -SxSStackInstaller ".\RDInfraSxSStackInstall\Microsoft.RDInfra.StackSxS.Installer-x64.msi" -AdminCredentials $Admincredentials -TenantName $TenantName -PoolName $HostPoolName -RegistrationToken $Registered.Token -StartAgent $true
        Write-Log -Message "DeployAgent Script was successfully executed and RDAgentBootLoader,RDAgent,StackSxS installed inside VM for existing hostpool: $HostPoolName `
        $DAgentInstall"
        
        #add rdsh vm to hostpool
        $addRdsh = Set-RdsSessionHost -TenantName $TenantName -HostPoolName $HostPoolName -Name $SessionHostName -AllowNewSession $true
        $rdshName = $addRdsh.name | Out-String -Stream
        $poolName = $addRdsh.hostpoolname | Out-String -Stream
        Write-Log -Message "Successfully added $rdshName VM to $poolName"
    }
    else {
        
        Write-Log -Message "$HostPoolName doesn't exist inside Tenant: $TenantName"
    }

}
catch {
    Write-log -Error $_.Exception.Message

}

