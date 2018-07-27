<#

.SYNOPSIS
Creating Hostpool and add sessionhost servers to existing Hostpool.

.DESCRIPTION
This script add sessionhost servers to existing Hostpool
The supported Operating Systems Windows Server 2016.

.ROLE
Readers

#>


param(
    [Parameter(mandatory = $true)]
    [string]$FileURI,

    [Parameter(mandatory = $true)]
    [string]$registrationToken,

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

    #Checking if RDInfragent is registered or not in rdsh vm
    $CheckRegistery = Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent" -ErrorAction SilentlyContinue

    Write-Log -Message "Checking whether VM was Registered with RDInfraAgent"

    if ($CheckRegistery) {
        Write-Log -Message "VM was already registered with RDInfraAgent, script execution was stopped"

    }
    else {
    
        Write-Log -Message "VM was not registered with RDInfraAgent, script is executing"
    }


    if (!$CheckRegistery) {
       
        #Converting Local Admin Credentials
        $AdminSecurepass = ConvertTo-SecureString -String $localAdminPassword -AsPlainText -Force
        $adminCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($localAdminUserName, $AdminSecurepass)

        #Getting fqdn of rdsh vm
        $SessionHostName = (Get-WmiObject win32_computersystem).DNSHostName + "." + (Get-WmiObject win32_computersystem).Domain
        Write-Log  -Message "Getting fully qualified domain name of RDSH VM: $SessionHostName"
           
        #Executing DeployAgent psl file in rdsh vm and add to hostpool
        $DAgentInstall = .\DeployAgent.ps1 -ComputerName $SessionHostName -AgentBootServiceInstaller ".\RDAgentBootLoaderInstall\Microsoft.RDInfra.RDAgentBootLoader.Installer-x64.msi" -AgentInstaller ".\RDInfraAgentInstall\Microsoft.RDInfra.RDAgent.Installer-x64.msi" -SxSStackInstaller ".\RDInfraSxSStackInstall\Microsoft.RDInfra.StackSxS.Installer-x64.msi" -AdminCredentials $adminCredentials -RegistrationToken $registrationToken -StartAgent $true
        Write-Log -Message "DeployAgent Script was successfully executed and RDAgentBootLoader,RDAgent,StackSxS installed inside VM for existing hostpool: $HostPoolName `
        $DAgentInstall"
    }
}
catch {
    Write-log -Error $_.Exception.Message

}
