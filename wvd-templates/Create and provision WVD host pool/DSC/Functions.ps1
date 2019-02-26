<#

.SYNOPSIS
Functions/Common variables file to be used by both Script-FirstRdsh.ps1 and Script-AdditionalRdshServers.ps1

#>

# Variables

# Setting to Tls12 due to Azure web app security requirements
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

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
        $DateTime = Get-Date -Format "MM-dd-yy HH:mm:ss" 
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

function AddDefaultUsers
{
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
    $DefaultUsers = $DefaultUsers.Replace("`"","").Replace("'","").Replace(" ","")

    if (-not ([string]::IsNullOrEmpty($DefaultUsers)))
    {
        $UserList = $DefaultUsers.split(",",[System.StringSplitOptions]::RemoveEmptyEntries)

        foreach ($user in $UserList)
        {
            try 
            {
                Add-RdsAppGroupUser -TenantName $TenantName -HostPoolName $HostPoolName -AppGroupName $ApplicationGroupName -UserPrincipalName $user
                Write-Log "Successfully assigned user $user to App Group: $ApplicationGroupName. Other details -> TenantName: $TenantName, HostPoolName: $HostPoolName."  
            }
            catch
            {
                Write-Log "An error ocurred assigining user $user to App Group $ApplicationGroupName. Other details -> TenantName: $TenantName, HostPoolName: $HostPoolName."
                Write-Log "Error details: $_"
            }
        }
    }
}

function ValidateServicePrincipal
{
    param
    ( 
        [Parameter(Mandatory = $true)] 
        [string]$isServicePrincipal,

        [Parameter(Mandatory = $true)] 
        [string]$AadTenantId
    ) 

    if ($isServicePrincipal -eq "True")
    {
        if ([string]::IsNullOrEmpty($AadTenantId))
        {
            throw "When IsServicePrincipal = True, AadTenant ID is mandatory. Please provide a valid AadTenant ID."
        }
    }
}

function Is1809OrLater
{
    $OSVersionInfo = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
    if ($OSVersionInfo -ne $null)
    {
        if ($OSVersionInfo.ReleaseId -ne $null)
        {
            Write-Log -Message "Build: $($OSVersionInfo.ReleaseId)"
            $rdshIs1809OrLaterBool=@{$true = $true; $false = $false}[$OSVersionInfo.ReleaseId -ge 1809]
        }
    }
    return $rdshIs1809OrLaterBool
}

function ExtractDeploymentAgentZipFile
{
    param
    ( 
        [Parameter(Mandatory = $true)] 
        [string]$ScriptPath,
        [Parameter(Mandatory = $true)] 
        [string]$DeployAgentLocation
    ) 

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
    
}

function AuthenticateOnWvd
{
    param
    ( 
        [Parameter(Mandatory = $true)] 
        [string]$isServicePrincipal,
        [Parameter(Mandatory = $true)] 
        [PSCredential]$TenantAdminCredentials,
        [Parameter(Mandatory = $true)] 
        [string]$AadTenantId,
        [Parameter(Mandatory = $true)] 
        [string]$RDBrokerURL,
        [Parameter(Mandatory = $true)] 
        [string]$DefinedTenantGroupName,
        [Parameter(Mandatory = $true)] 
        [string]$TenantName
    ) 

    Write-Log  -Message "AuthenticateOnWvd arguments:"
    Write-Log  -Message "   isServicePrincipal......: $isServicePrincipal"
    Write-Log  -Message "   AadTenantId.............: $AadTenantId"
    Write-Log  -Message "   RDBrokerURL.............: $RDBrokerURL"
    Write-Log  -Message "   DefinedTenantGroupName..: $DefinedTenantGroupName"
    Write-Log  -Message "   TenantName..............: $TenantName"
    Write-Log  -Message "   TenantAdminUsername.....: $($TenantAdminCredentials.username)"

    # Authenticating to WVD
    if ($isServicePrincipal -eq "True")
    {
        Write-Log  -Message "Authenticating using service principal $($TenantAdminCredentials.username) and Tenant id: $AadTenantId "
        $authentication = Add-RdsAccount -DeploymentUrl $RDBrokerURL -Credential $TenantAdminCredentials -ServicePrincipal -TenantId $AadTenantId 
    }
    else
    {
        Write-Log  -Message "Authenticating using user $($TenantAdminCredentials.username) "
        $authentication = Add-RdsAccount -DeploymentUrl $RDBrokerURL -Credential $TenantAdminCredentials
    }

    Write-Log  -Message "Authentication object: $($authentication | Out-String)"
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
    Write-Log "Running switching to the $DefinedTenantGroupName context"
    Set-RdsContext -TenantGroupName $DefinedTenantGroupName
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

}