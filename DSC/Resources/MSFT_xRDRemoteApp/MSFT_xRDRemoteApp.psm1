if ([System.Environment]::OSVersion.Version -lt "6.2.9200.0") { Throw "The minimum OS requirement was not met."}
Import-Module RemoteDesktop
$localhost = [System.Net.Dns]::GetHostByName((hostname)).HostName

#######################################################################
# The Get-TargetResource cmdlet.
#######################################################################
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory)]
        [string] $CollectionName = "Tenant",
        [parameter(Mandatory)]
        [string] $DisplayName = "Calculator",
        [parameter(Mandatory)]
        [string] $FilePath = "C:\Windows\System32\calc.exe",
        [parameter(Mandatory)]
        [string] $Alias = "calc",
        [string] $FileVirtualPath,
        [string] $FolderName,
        [string] $CommandLineSetting,
        [string] $RequiredCommandLine,
        [uint32] $IconIndex,
        [string] $IconPath,
        [string] $UserGroups,
        [boolean] $ShowInWebAccess
    )
        Write-Verbose "Getting published RemoteApp program $DisplayName, if one exists."
        $CollectionName = Get-RDSessionCollection | % {Get-RDSessionHost $_.CollectionName} | ? {$_.SessionHost -ieq $localhost} | % {$_.CollectionName}
        $remoteApp = Get-RDRemoteApp -CollectionName $CollectionName -DisplayName $DisplayName -Alias $Alias

        @{
        "CollectionName" = $remoteApp.CollectionName;
        "DisplayName" = $remoteApp.DisplayName;
        "FilePath" = $remoteApp.FilePath;
        "Alias" = $remoteApp.Alias;
        "FileVirtualPath" = $remoteApp.FileVirtualPath;
        "FolderName" = $remoteApp.FolderName;
        "CommandLineSetting" = $remoteApp.CommandLineSetting;
        "RequiredCommandLine" = $remoteApp.RequiredCommandLine;
        "IconIndex" = $remoteApp.IconIndex;
        "IconPath" = $remoteApp.IconPath;
        "UserGroups" = $remoteApp.UserGroups;
        "ShowInWebAccess" = $remoteApp.ShowInWebAccess;
        }
}


######################################################################## 
# The Set-TargetResource cmdlet.
########################################################################
function Set-TargetResource

{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory)]
        [string] $CollectionName,
        [parameter(Mandatory)]
        [string] $DisplayName,
        [parameter(Mandatory)]
        [string] $FilePath,
        [parameter(Mandatory)]
        [string] $Alias,
        [string] $FileVirtualPath,
        [string] $FolderName,
        [string] $CommandLineSetting,
        [string] $RequiredCommandLine,
        [uint32] $IconIndex,
        [string] $IconPath,
        [string] $UserGroups,
        [boolean] $ShowInWebAccess
    )
    Write-Verbose "Making updates to RemoteApp."
    $CollectionName = Get-RDSessionCollection | % {Get-RDSessionHost $_.CollectionName} | ? {$_.SessionHost -ieq $localhost} | % {$_.CollectionName}
    $PSBoundParameters.collectionName = $CollectionName
    if (!$(Get-RDRemoteApp -Alias $Alias)) {
        New-RDRemoteApp @PSBoundParameters
        }
    else {
        Set-RDRemoteApp @PSBoundParameters
    }
}


#######################################################################
# The Test-TargetResource cmdlet.
#######################################################################
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory)]
        [string] $CollectionName,
        [parameter(Mandatory)]
        [string] $DisplayName,
        [parameter(Mandatory)]
        [string] $FilePath,
        [parameter(Mandatory)]
        [string] $Alias,
        [string] $FileVirtualPath,
        [string] $FolderName,
        [string] $CommandLineSetting,
        [string] $RequiredCommandLine,
        [uint32] $IconIndex,
        [string] $IconPath,
        [string] $UserGroups,
        [boolean] $ShowInWebAccess
    )
    Write-Verbose "Testing if RemoteApp is published."
    $collectionName = Get-RDSessionCollection | % {Get-RDSessionHost $_.CollectionName} | ? {$_.SessionHost -ieq $localhost} | % {$_.CollectionName}
    $PSBoundParameters.Remove("Verbose") | out-null
    $PSBoundParameters.Remove("Debug") | out-null
    $PSBoundParameters.Remove("ConnectionBroker") | out-null
    $Check = $true
    
    $Get = Get-TargetResource -CollectionName $CollectionName -DisplayName $DisplayName -FilePath $FilePath -Alias $Alias
    $PSBoundParameters.keys | % {if ($PSBoundParameters[$_] -ne $Get[$_]) {$Check = $false} }
    $Check
}

Export-ModuleMember -Function *-TargetResource

