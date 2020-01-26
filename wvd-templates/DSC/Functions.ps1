<#

.SYNOPSIS
Functions/Common variables file to be used by both Script-FirstRdsh.ps1 and Script-AdditionalRdshServers.ps1

#>

# Variables

# Setting to Tls12 due to Azure web app security requirements
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

class PsRdsSessionHost {
    [string]$TenantName = [string]::Empty
    [string]$HostPoolName = [string]::Empty
    [string]$SessionHostName = [string]::Empty
    [int]$TimeoutInSec = 900
    [bool]$CheckForAvailableState = $false

    PsRdsSessionHost() { }

    PsRdsSessionHost([string]$TenantName, [string]$HostPoolName, [string]$SessionHostName) {
        $this.TenantName = $TenantName
        $this.HostPoolName = $HostPoolName
        $this.SessionHostName = $SessionHostName
    }

    PsRdsSessionHost([string]$TenantName, [string]$HostPoolName, [string]$SessionHostName, [int]$TimeoutInSec) {
        
        if ($TimeoutInSec -gt 1800) {
            throw "TimeoutInSec is too high, maximum value is 1800"
        }

        $this.TenantName = $TenantName
        $this.HostPoolName = $HostPoolName
        $this.SessionHostName = $SessionHostName
        $this.TimeoutInSec = $TimeoutInSec
    }

    hidden [object] _trySessionHost([string]$operation) {
        if ($operation -ne "get" -and $operation -ne "set") {
            throw "PsRdsSessionHost: Invalid operation: $operation. Valid Operations are get or set"
        }

        $specificToSet = @{$true = "-AllowNewSession `$true"; $false = "" }[$operation -eq "set"]
        $commandToExecute = "$operation-RdsSessionHost -TenantName `"`$(`$this.TenantName)`" -HostPoolName `"`$(`$this.HostPoolName)`" -Name `$this.SessionHostName -ErrorAction SilentlyContinue $specificToSet"

        $sessionHost = (Invoke-Expression $commandToExecute )

        $StartTime = Get-Date
        while ($sessionHost -eq $null) {
            Start-Sleep -Seconds 30
            $sessionHost = (Invoke-Expression $commandToExecute)
    
            if ((get-date).Subtract($StartTime).TotalSeconds -gt $this.TimeoutInSec) {
                if ($sessionHost -eq $null) {
                    return $null
                }
            }
        }

        if (($operation -eq "get") -and $this.CheckForAvailableState) {
            $StartTime = Get-Date

            while ($sessionHost.Status -ine "Available") {
                Start-Sleep -Seconds 60
                $sessionHost = (Invoke-Expression $commandToExecute)
        
                if ((get-date).Subtract($StartTime).TotalSeconds -gt $this.TimeoutInSec) {
                    if ($sessionHost.Status -ine "Available") {
                        $this.CheckForAvailableState = $false
                        return $null
                    }
                }
            }
        }

        $this.CheckForAvailableState = $false
        return $sessionHost
    }

    [object] SetSessionHost() {

        if ([string]::IsNullOrEmpty($this.TenantName) -or [string]::IsNullOrEmpty($this.HostPoolName) -or [string]::IsNullOrEmpty($this.HostPoolName)) {
            return $null
        }
        else {
            
            return ($this._trySessionHost("set"))
        }
    }
    
    [object] GetSessionHost() {

        if ([string]::IsNullOrEmpty($this.TenantName) -or [string]::IsNullOrEmpty($this.HostPoolName) -or [string]::IsNullOrEmpty($this.HostPoolName)) {
            return $null
        }
        else {
            return ($this._trySessionHost("get"))
        }
    }

    [object] GetSessionHostWhenAvailable() {

        if ([string]::IsNullOrEmpty($this.TenantName) -or [string]::IsNullOrEmpty($this.HostPoolName) -or [string]::IsNullOrEmpty($this.HostPoolName)) {
            return $null
        }
        else {
            $this.CheckForAvailableState = $true
            return ($this._trySessionHost("get"))
        }
    }
}

function Write-Log {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $false)]
        [string]$Message,
        [Parameter(Mandatory = $false)]
        [string]$Error
    )
     
    try {
        $DateTime = Get-Date -Format "MM-dd-yy HH:mm:ss"
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

    # Checking for null parameters
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
                Write-Log "An error ocurred assigining user $user to App Group $ApplicationGroupName. Other details -> TenantName: $TenantName, HostPoolName: $HostPoolName."
                Write-Log "Error details: $_"
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
    if ($OSVersionInfo -ne $null) {
        if ($OSVersionInfo.ReleaseId -ne $null) {
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
    $DeployAgentFromRepo = (LocateFile -Name 'DeployAgent.zip' -SearchPath $ScriptPath)
    
    Write-Log -Message "Extracting 'Deployagent.zip' file into '$DeployAgentLocation' folder inside VM"
    Expand-Archive $DeployAgentFromRepo -DestinationPath "$DeployAgentLocation"
}

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
        Write-Log -Message "Authenticating using service principal $($Credential.username) and Tenant id: $TenantId "
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
        $errMsg = "Windows Virtual Desktop Authentication Failed, Error:`n$($_ | Out-String)"
        Write-Log -Error "$errMsg"
        throw "$errMsg"
    }
    Write-Log -Message "Windows Virtual Desktop Authentication successfully Done. Result:`n$($authentication | Out-String)"
}

function SetTenantContextAndValidate {
    param(
        [Parameter(mandatory = $true)]
        [string]$definedTenantGroupName,

        [Parameter(mandatory = $true)]
        [string]$TenantName
    )
    #//todo refactor
    #//todo try catch ?
    # Set context to the appropriate tenant group
    $currentTenantGroupName = (Get-RdsContext).TenantGroupName
    if ($definedTenantGroupName -ne $currentTenantGroupName) {
        Write-Log -Message "Running switching to the $definedTenantGroupName context"
        Set-RdsContext -TenantGroupName $definedTenantGroupName
    }
    try {
        $tenants = Get-RdsTenant -Name "$TenantName"
        if (!$tenants) {
            Write-Log "No tenants exist or you do not have proper access."
            #//todo throw ?
        }
    }
    catch {
        #//todo refactor msg ?
        Write-Log -Message $_
        throw $_
    }
}

function LocateFile {
    param (
        [Parameter(mandatory = $true)]
        [string]$Name,

        [string]$SearchPath = '.'
    )
    
    Write-Log -Message "Locating '$Name' within: '$SearchPath'"
    $Path = (Get-ChildItem "$SearchPath\" -Filter $Name -Recurse).FullName
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
        $ZipPath = (LocateFile -Name 'PowerShellModules.zip' -SearchPath $ArtifactsPath)

        Write-Log -Message "Extracting RD PowerShell module file '$ZipPath' into '$Path'"
        Expand-Archive $ZipPath -DestinationPath $Path -Force
        Write-Log -Message "Successfully extracted RD PowerShell module file '$ZipPath' into '$Path'"
    }
    else {
        $Version = ($Source.Trim().ToLower() -split 'gallery@')[1]
        if ($Version -eq $null -or $Version.Trim() -eq '') {
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

    $DLLPath = (LocateFile -Name "$ModName.dll" -SearchPath $Path)

    Write-Log -Message "Importing RD PowerShell module DLL '$DLLPath"
    Import-Module $DLLPath -Force
    Write-Log -Message "Successfully imported RD PowerShell module DLL '$DLLPath"
}