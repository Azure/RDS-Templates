#Microsoft.RDInfra.RDPowerShell and Get-Package both require powershell 5.0 or higher.
#Requires -Version 5.0

<#
.SYNOPSIS
Common functions to be used by DSC scripts
#>

# Setting to Tls12 due to Azure web app security requirements
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

<# [CalledByARMTemplate] #>
function Write-Log {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        # note: can't use variable named '$Error': https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/AvoidAssignmentToAutomaticVariable.md
        [switch]$Err
    )
     
    try {
        $DateTime = Get-Date -Format "MM-dd-yy HH:mm:ss"
        $Invocation = "$($MyInvocation.MyCommand.Source):$($MyInvocation.ScriptLineNumber)"

        if ($Err) {
            $Message = "[ERROR] $Message"
        }
        
        Add-Content -Value "$DateTime - $Invocation - $Message" -Path "$([environment]::GetEnvironmentVariable('TEMP', 'Machine'))\ScriptLog.log"
    }
    catch {
        throw [System.Exception]::new("Some error occurred while writing to log file with message: $Message", $PSItem.Exception)
    }
}

function AddDefaultUsers {
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$TenantName,

        [Parameter(Mandatory = $true)]
        [string]$HostPoolName,

        [Parameter(Mandatory = $true)]
        [string]$ApplicationGroupName,

        [Parameter(Mandatory = $false)]
        [string]$DefaultUsers
    )
    $ErrorActionPreference = "Stop"

    Write-Log "Adding Default users. Argument values: App Group: $ApplicationGroupName, TenantName: $TenantName, HostPoolName: $HostPoolName, DefaultUsers: $DefaultUsers"

    # Sanitizing DefaultUsers string
    $DefaultUsers = $DefaultUsers.Replace("`"", "").Replace("'", "").Replace(" ", "")

    if (-not ([string]::IsNullOrEmpty($DefaultUsers))) {
        $UserList = $DefaultUsers.split(",", [System.StringSplitOptions]::RemoveEmptyEntries)

        foreach ($user in $UserList) {
            try {
                Add-RdsAppGroupUser -TenantName "$TenantName" -HostPoolName "$HostPoolName" -AppGroupName $ApplicationGroupName -UserPrincipalName $user
                Write-Log "Successfully assigned user $user to App Group: $ApplicationGroupName. Other details -> TenantName: $TenantName, HostPoolName: $HostPoolName."
            }
            catch {
                Write-Log -Err "An error ocurred assigining user $user to App Group $ApplicationGroupName. Other details -> TenantName: $TenantName, HostPoolName: $HostPoolName."
                Write-Log -Err ($PSItem | Format-List -Force | Out-String)
            }
        }
    }
}

function ValidateServicePrincipal {
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$isServicePrincipal,

        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]$AadTenantId = ""
    )

    if ($isServicePrincipal -eq "True") {
        if ([string]::IsNullOrEmpty($AadTenantId)) {
            throw "When IsServicePrincipal = True, AadTenant ID is mandatory. Please provide a valid AadTenant ID."
        }
    }
}

function Is1809OrLater {
    $OSVersionInfo = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
    if ($null -ne $OSVersionInfo) {
        if ($null -ne $OSVersionInfo.ReleaseId) {
            Write-Log -Message "Build: $($OSVersionInfo.ReleaseId)"
            $rdshIs1809OrLaterBool = @{$true = $true; $false = $false }[$OSVersionInfo.ReleaseId -ge 1809]
        }
    }
    return $rdshIs1809OrLaterBool
}

function ExtractDeploymentAgentZipFile {
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [Parameter(Mandatory = $true)]
        [string]$DeployAgentLocation
    )

    if (Test-Path $DeployAgentLocation) {
        Remove-Item -Path $DeployAgentLocation -Force -Confirm:$false -Recurse
    }
    
    New-Item -Path "$DeployAgentLocation" -ItemType directory -Force
    
    # Locating and extracting DeployAgent.zip
    $DeployAgentFromRepo = (LocateFile -Name 'DeployAgent.zip' -SearchPath $ScriptPath -Recurse)
    
    Write-Log -Message "Extracting 'Deployagent.zip' file into '$DeployAgentLocation' folder inside VM"
    Expand-Archive $DeployAgentFromRepo -DestinationPath "$DeployAgentLocation"
}

<# [CalledByARMTemplate] #>
function isRdshServer {
    $rdshIsServer = $true

    $OSVersionInfo = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
    
    if ($null -ne $OSVersionInfo) {
        if ($null -ne $OSVersionInfo.InstallationType) {
            $rdshIsServer = @{$true = $true; $false = $false }[$OSVersionInfo.InstallationType -eq "Server"]
        }
    }

    return $rdshIsServer
}


<#
.Description
Call this function using dot source notation like ". AuthenticateRdsAccount" because the Add-RdsAccount function this calls creates variables using the AllScope option that other WVD poweshell module functions like Set-RdsContext require. Note that this creates a variable named "$authentication" that will overwrite any existing variable with that name in the scope this is dot sourced to.

Calling code should set $ErrorActionPreference = "Stop" before calling this function to ensure that detailed error information is thrown if there is an error.
#>
function AuthenticateRdsAccount {
    param(
        [Parameter(mandatory = $true)]
        [string]$DeploymentUrl,
    
        [Parameter(mandatory = $true)]
        [pscredential]$Credential,
    
        [switch]$ServicePrincipal,
    
        [Parameter(mandatory = $false)]
        [AllowEmptyString()]
        [string]$TenantId = ""
    )

    if ($ServicePrincipal) {
        Write-Log -Message "Authenticating using service principal $($Credential.username) and Tenant id: $TenantId"
    }
    else {
        $PSBoundParameters.Remove('ServicePrincipal')
        $PSBoundParameters.Remove('TenantId')
        Write-Log -Message "Authenticating using user $($Credential.username)"
    }
    
    $authentication = $null
    try {
        $authentication = Add-RdsAccount @PSBoundParameters
        if (!$authentication) {
            throw $authentication
        }
    }
    catch {
        throw [System.Exception]::new("Error authenticating Windows Virtual Desktop account, ServicePrincipal = $ServicePrincipal", $PSItem.Exception)
    }
    
    Write-Log -Message "Windows Virtual Desktop account authentication successful. Result:`n$($authentication | Out-String)"
}

function SetTenantGroupContextAndValidate {
    param(
        [Parameter(mandatory = $true)]
        [string]$TenantGroupName,

        [Parameter(mandatory = $true)]
        [string]$TenantName
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = "Stop"

    # Set context to the appropriate tenant group
    $currentTenantGroupName = (Get-RdsContext).TenantGroupName
    if ($TenantGroupName -ne $currentTenantGroupName) {
        Write-Log -Message "Running switching to the $TenantGroupName context"

        try {
            #As of Microsoft.RDInfra.RDPowerShell version 1.0.1534.2001 this throws a System.NullReferenceException when the TenantGroupName doesn't exist.
            Set-RdsContext -TenantGroupName $TenantGroupName
        }
        catch {
            throw [System.Exception]::new("Error setting RdsContext using tenant group ""$TenantGroupName"", this may be caused by the tenant group not existing or the user not having access to the tenant group", $PSItem.Exception)
        }
    }
    
    $tenants = $null
    try {
        $tenants = (Get-RdsTenant -Name $TenantName)
    }
    catch {
        throw [System.Exception]::new("Error getting the tenant with name ""$TenantName"", this may be caused by the tenant not existing or the account doesn't have access to the tenant", $PSItem.Exception)
    }
    
    if (!$tenants) {
        throw "No tenant with name ""$TenantName"" exists or the account doesn't have access to it."
    }
}

function LocateFile {
    param (
        [Parameter(mandatory = $true)]
        [string]$Name,
        [string]$SearchPath = '.',
        [switch]$Recurse
    )
    
    Write-Log -Message "Locating '$Name' within: '$SearchPath'"
    $Path = (Get-ChildItem "$SearchPath\" -Filter $Name -Recurse:$Recurse).FullName
    if ((-not $Path) -or (-not (Test-Path $Path))) {
        throw "'$Name' file not found at '$SearchPath'"
    }
    if (@($Path).Length -ne 1) {
        throw "Multiple '$Name' files found at '$SearchPath': [`n$Path`n]"
    }

    return $Path
}

function ImportRDPSMod {
    param(
        [string]$Source = 'attached',
        [string]$ArtifactsPath
    )

    $ErrorActionPreference = "Stop"

    $ModName = 'Microsoft.RDInfra.RDPowershell'
    $Mod = (get-module $ModName)

    if ($Mod) {
        Write-Log -Message 'RD PowerShell module already imported (Not going to re-import)'
        return
    }
        
    $Path = 'C:\_tmp_RDPSMod\'
    if (test-path $Path) {
        Write-Log -Message "Remove tmp dir '$Path'"
        Remove-Item -Path $Path -Force -Recurse
    }
    
    if ($Source -eq 'attached') {
        if ((-not $ArtifactsPath) -or (-not (test-path $ArtifactsPath))) {
            throw "invalid param: ArtifactsPath = '$ArtifactsPath'"
        }

        # Locating and extracting PowerShellModules.zip
        $ZipPath = (LocateFile -Name 'PowerShellModules.zip' -SearchPath $ArtifactsPath -Recurse)

        Write-Log -Message "Extracting RD PowerShell module file '$ZipPath' into '$Path'"
        Expand-Archive $ZipPath -DestinationPath $Path -Force
        Write-Log -Message "Successfully extracted RD PowerShell module file '$ZipPath' into '$Path'"
    }
    else {
        $Version = ($Source.Trim().ToLower() -split 'gallery@')[1]
        if ($null -eq $Version -or $Version.Trim() -eq '') {
            throw "invalid param: Source = $Source"
        }

        Write-Log -Message "Downloading RD PowerShell module (version: v$Version) from PowerShell Gallery into '$Path'"
        if ($Version -eq 'latest') {
            Save-Module -Name $ModName -Path $Path -Force
        }
        else {
            Save-Module -Name $ModName -Path $Path -Force -RequiredVersion (new-object System.Version($Version))
        }
        Write-Log -Message "Successfully downloaded RD PowerShell module (version: v$Version) from PowerShell Gallery into '$Path'"
    }

    $DLLPath = (LocateFile -Name "$ModName.dll" -SearchPath $Path -Recurse)

    Write-Log -Message "Importing RD PowerShell module DLL '$DLLPath"
    Import-Module $DLLPath -Force
    Write-Log -Message "Successfully imported RD PowerShell module DLL '$DLLPath"
}

function GetCurrSessionHostName {
    $Wmi = (Get-WmiObject win32_computersystem)
    return "$($Wmi.DNSHostName).$($Wmi.Domain)"
}

function GetSessionHostDesiredStates {
    return ('Available', 'NeedsAssistance')
}

function IsRDAgentRegistryValidForRegistration {
    $ErrorActionPreference = "Stop"

    $RDInfraReg = Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent' -ErrorAction SilentlyContinue
    if (!$RDInfraReg) {
        return @{
            result = $false;
            msg    = 'RD Infra registry missing';
        }
    }
    Write-Log -Message 'RD Infra registry exists'

    Write-Log -Message 'Check RD Infra registry values to see if RD Agent is registered'
    if ($RDInfraReg.RegistrationToken -ne '') {
        return @{
            result = $false;
            msg    = 'RegistrationToken in RD Infra registry is not empty'
        }
    }
    if ($RDInfraReg.IsRegistered -ne 1) {
        return @{
            result = $false;
            msg    = "Value of 'IsRegistered' in RD Infra registry is $($RDInfraReg.IsRegistered), but should be 1"
        }
    }
    
    return @{
        result = $true
    }
}

<# [CalledByARMTemplate] indirectly because this is called by InstallRDAgents #>
function RunMsiWithRetry {
    param(
        [Parameter(mandatory = $true)]
        [string]$programDisplayName,

        [Parameter(mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]]$argumentList, #Must have at least 1 value

        [Parameter(mandatory = $true)]
        [string]$msiOutputLogPath,

        [Parameter(mandatory = $false)]
        [switch]$isUninstall,

        [Parameter(mandatory = $false)]
        [switch]$msiLogVerboseOutput
    )
    Set-StrictMode -Version Latest
    $ErrorActionPreference = "Stop"

    if ($msiLogVerboseOutput) {
        $argumentList += "/l*vx $msiOutputLogPath" 
    }
    else {
        $argumentList += "/l* $msiOutputLogPath"
    }

    $retryTimeToSleepInSec = 30
    $retryCount = 0
    $sts = $null
    do {
        $modeAndDisplayName = ($(if ($isUninstall) { "Uninstalling" } else { "Installing" }) + " $programDisplayName")

        if ($retryCount -gt 0) {
            Write-Log -Message "Retrying $modeAndDisplayName in $retryTimeToSleepInSec seconds because it failed with Exit code=$sts This will be retry number $retryCount"
            Start-Sleep -Seconds $retryTimeToSleepInSec
        }

        Write-Log -Message ( "$modeAndDisplayName" + $(if ($msiLogVerboseOutput) { " with verbose msi logging" } else { "" }))


        $processResult = Start-Process -FilePath "msiexec.exe" -ArgumentList $argumentList -Wait -Passthru
        $sts = $processResult.ExitCode

        $retryCount++
    } 
    while ($sts -eq 1618 -and $retryCount -lt 20) # Error code 1618 is ERROR_INSTALL_ALREADY_RUNNING see https://docs.microsoft.com/en-us/windows/win32/msi/-msiexecute-mutex .

    if ($sts -eq 1618) {
        Write-Log -Err "Stopping retries for $modeAndDisplayName. The last attempt failed with Exit code=$sts which is ERROR_INSTALL_ALREADY_RUNNING"
        throw "Stopping because $modeAndDisplayName finished with Exit code=$sts"
    }
    else {
        Write-Log -Message "$modeAndDisplayName finished with Exit code=$sts"
    }

    return $sts
} 

<#
.DESCRIPTION
Uninstalls any existing RDAgent BootLoader and RD Infra Agent installations and then installs the RDAgent BootLoader and RD Infra Agent using the specified registration token.

.PARAMETER AgentInstallerFolder
Required path to MSI installer file

.PARAMETER AgentBootServiceInstallerFolder
Required path to MSI installer file

[CalledByARMTemplate]
#>
function InstallRDAgents {
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$AgentInstallerFolder,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$AgentBootServiceInstallerFolder,
    
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RegistrationToken,
    
        [Parameter(mandatory = $false)]
        [switch]$EnableVerboseMsiLogging
    )

    $ErrorActionPreference = "Stop"

    Write-Log -Message "Boot loader folder is $AgentBootServiceInstallerFolder"
    $AgentBootServiceInstaller = LocateFile -SearchPath $AgentBootServiceInstallerFolder -Name "*.msi"

    Write-Log -Message "Agent folder is $AgentInstallerFolder"
    $AgentInstaller = LocateFile -SearchPath $AgentInstallerFolder -Name "*.msi"

    if (!$RegistrationToken) {
        throw "No registration token specified"
    }

    RunMsiWithRetry -programDisplayName "RDAgentBootLoader" -isUninstall -argumentList @("/x {A38EE409-424D-4A0D-B5B6-5D66F20F62A5}", "/quiet", "/qn", "/norestart", "/passive") -msiOutputLogPath "C:\Users\AgentBootLoaderUnInstall.txt" -msiLogVerboseOutput:$EnableVerboseMsiLogging

    while ($true) {
        try {
            $oldAgent = Get-Package -ProviderName msi -Name "Remote Desktop Services Infrastructure Agent"
        }
        catch {
            #Ignore the error if it was due to no packages being found.
            if ($PSItem.FullyQualifiedErrorId -eq "NoMatchFound,Microsoft.PowerShell.PackageManagement.Cmdlets.GetPackage") {
                break
            }

            throw;
        }

        $oldVersion = $oldAgent.Version
        $productCodeParameter = $oldAgent.FastPackageReference

        RunMsiWithRetry -programDisplayName "RD Infra Agent $oldVersion" -isUninstall -argumentList @("/x $productCodeParameter", "/quiet", "/qn", "/norestart", "/passive") -msiOutputLogPath "C:\Users\AgentUninstall.txt" -msiLogVerboseOutput:$EnableVerboseMsiLogging
    }


    Write-Log -Message "Installing RD Infra Agent on VM $AgentInstaller"
    RunMsiWithRetry -programDisplayName "RD Infra Agent" -argumentList @("/i $AgentInstaller", "/quiet", "/qn", "/norestart", "/passive", "REGISTRATIONTOKEN=$RegistrationToken") -msiOutputLogPath "C:\Users\AgentInstall.txt" -msiLogVerboseOutput:$EnableVerboseMsiLogging

    Write-Log -Message "Installing RDAgent BootLoader on VM $AgentBootServiceInstaller"
    RunMsiWithRetry -programDisplayName "RDAgent BootLoader" -argumentList @("/i $AgentBootServiceInstaller", "/quiet", "/qn", "/norestart", "/passive") -msiOutputLogPath "C:\Users\AgentBootLoaderInstall.txt" -msiLogVerboseOutput:$EnableVerboseMsiLogging

    $bootloaderServiceName = "RDAgentBootLoader"
    $startBootloaderRetryCount = 0
    while ( -not (Get-Service $bootloaderServiceName -ErrorAction SilentlyContinue)) {
        $retry = ($startBootloaderRetryCount -lt 6)
        $msgToWrite = "Service $bootloaderServiceName was not found. "
        if ($retry) { 
            $msgToWrite += "Retrying again in 30 seconds, this will be retry $startBootloaderRetryCount" 
            Write-Log -Message $msgToWrite
        } 
        else {
            $msgToWrite += "Retry limit exceeded" 
            Write-Log -Err $msgToWrite
            throw $msgToWrite
        }
            
        $startBootloaderRetryCount++
        Start-Sleep -Seconds 30
    }

    Write-Log -Message "Starting service $bootloaderServiceName"
    Start-Service $bootloaderServiceName
}