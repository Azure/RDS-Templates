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
        [string] $CollectionName,
        [uint32] $ActiveSessionLimitMin,
        [boolean] $AuthenticateUsingNLA,
        [boolean] $AutomaticReconnectionEnabled,
        [string] $BrokenConnectionAction,
        [string] $ClientDeviceRedirectionOptions,
        [boolean] $ClientPrinterAsDefault,
        [boolean] $ClientPrinterRedirected,
        [string] $CollectionDescription,
        [string] $ConnectionBroker,
        [string] $CustomRdpProperty,
        [uint32] $DisconnectedSessionLimitMin,
        [string] $EncryptionLevel,
        [uint32] $IdleSessionLimitMin,
        [uint32] $MaxRedirectedMonitors,
        [boolean] $RDEasyPrintDriverEnabled,
        [string] $SecurityLayer,
        [boolean] $TemporaryFoldersDeletedOnExit,
        [string] $UserGroup
    )
        Write-Verbose "Getting currently configured RDSH Collection properties"
        $collectionName = Get-RDSessionCollection | % {Get-RDSessionHost $_.CollectionName} | ? {$_.SessionHost -ieq $localhost} | % {$_.CollectionName}

        $collectionGeneral = Get-RDSessionCollectionConfiguration -CollectionName $CollectionName
        $collectionClient = Get-RDSessionCollectionConfiguration -CollectionName $CollectionName -Client
        $collectionConnection = Get-RDSessionCollectionConfiguration -CollectionName $CollectionName -Connection
        $collectionSecurity = Get-RDSessionCollectionConfiguration -CollectionName $CollectionName -Security
        $collectionUserGroup = Get-RDSessionCollectionConfiguration -CollectionName $CollectionName -UserGroup

        @{
            "CollectionName" = $collectionGeneral.CollectionName;
            "ActiveSessionLimitMin" = $collectionConnection.ActiveSessionLimitMin;
            "AuthenticateUsingNLA" = $collectionSecurity.AuthenticateUsingNLA;
            "AutomaticReconnectionEnabled" = $collectionConnection.AutomaticReconnectionEnabled;
            "BrokenConnectionAction" = $collectionConnection.BrokenConnectionAction;
            "ClientDeviceRedirectionOptions" = $collectionClient.ClientDeviceRedirectionOptions;
            "ClientPrinterAsDefault" = $collectionClient.ClientPrinterAsDefault;
            "ClientPrinterRedirected" = $collectionClient.ClientPrinterRedirected;
            "CollectionDescription" = $collectionGeneral.CollectionDescription;
            "CustomRdpProperty" = $collectionGeneral.CustomRdpProperty;
            "DisconnectedSessionLimitMin" = $collectionGeneral.DisconnectedSessionLimitMin;
            "EncryptionLevel" = $collectionSecurity.EncryptionLevel;
            "IdleSessionLimitMin" = $collectionConnection.IdleSessionLimitMin;
            "MaxRedirectedMonitors" = $collectionClient.MaxRedirectedMonitors;
            "RDEasyPrintDriverEnabled" = $collectionClient.RDEasyPrintDriverEnabled;
            "SecurityLayer" = $collectionSecurity.SecurityLayer;
            "TemporaryFoldersDeletedOnExit" = $collectionConnection.TemporaryFoldersDeletedOnExit;
            "UserGroup" = $collectionUserGroup.UserGroup;
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
        [uint32] $ActiveSessionLimitMin,
        [boolean] $AuthenticateUsingNLA,
        [boolean] $AutomaticReconnectionEnabled,
        [string] $BrokenConnectionAction,
        [string] $ClientDeviceRedirectionOptions,
        [boolean] $ClientPrinterAsDefault,
        [boolean] $ClientPrinterRedirected,
        [string] $CollectionDescription,
        [string] $ConnectionBroker,
        [string] $CustomRdpProperty,
        [uint32] $DisconnectedSessionLimitMin,
        [string] $EncryptionLevel,
        [uint32] $IdleSessionLimitMin,
        [uint32] $MaxRedirectedMonitors,
        [boolean] $RDEasyPrintDriverEnabled,
        [string] $SecurityLayer,
        [boolean] $TemporaryFoldersDeletedOnExit,
        [string] $UserGroup
    )
    Write-Verbose "Setting RDSH collection properties"
    $discoveredCollectionName = Get-RDSessionCollection | % {Get-RDSessionHost $_.CollectionName} | ? {$_.SessionHost -ieq $localhost} | % {$_.CollectionName}
    if ($collectionName -ne $discoveredCollectionName) {$PSBoundParameters.collectionName = $discoveredCollectionName}
    Set-RDSessionCollectionConfiguration @PSBoundParameters
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
        [uint32] $ActiveSessionLimitMin,
        [boolean] $AuthenticateUsingNLA,
        [boolean] $AutomaticReconnectionEnabled,
        [string] $BrokenConnectionAction,
        [string] $ClientDeviceRedirectionOptions,
        [boolean] $ClientPrinterAsDefault,
        [boolean] $ClientPrinterRedirected,
        [string] $CollectionDescription,
        [string] $ConnectionBroker,
        [string] $CustomRdpProperty,
        [uint32] $DisconnectedSessionLimitMin,
        [string] $EncryptionLevel,
        [uint32] $IdleSessionLimitMin,
        [uint32] $MaxRedirectedMonitors,
        [boolean] $RDEasyPrintDriverEnabled,
        [string] $SecurityLayer,
        [boolean] $TemporaryFoldersDeletedOnExit,
        [string] $UserGroup
    )
    
    Write-Verbose "Testing RDSH collection properties"
    $collectionName = Get-RDSessionCollection | % {Get-RDSessionHost $_.CollectionName} | ? {$_.SessionHost -ieq $localhost} | % {$_.CollectionName}
    $PSBoundParameters.Remove("Verbose") | out-null
    $PSBoundParameters.Remove("Debug") | out-null
    $PSBoundParameters.Remove("ConnectionBroker") | out-null
    $Check = $true

    $Get = Get-TargetResource -CollectionName $CollectionName
    $PSBoundParameters.keys | % {if ($PSBoundParameters[$_] -ne $Get[$_]) {$Check = $false} }
    $Check
}

Export-ModuleMember -Function *-TargetResource

