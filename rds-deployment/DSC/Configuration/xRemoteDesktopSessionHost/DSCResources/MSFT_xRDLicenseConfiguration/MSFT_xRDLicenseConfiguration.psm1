if ([System.Environment]::OSVersion.Version -lt "6.2.9200.0") { Throw "The minimum OS requirement was not met."}

Import-Module RemoteDesktop


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
        [ValidateNotNullOrEmpty()]
        [string] $ConnectionBroker,
        
        [string[]] $LicenseServers,
        
        [string] $LicenseMode
    )

    $result = $null

    write-verbose "Getting RD License server configuration from broker '$ConnectionBroker'..."    
    
    $config = Get-RDLicenseConfiguration -ConnectionBroker $ConnectionBroker -ea SilentlyContinue

    if ($config)   # Microsoft.RemoteDesktopServices.Management.LicensingSetting
    {
        write-verbose "configuration retrieved successfully:"

        $result = 
        @{
            "ConnectionBroker" = $ConnectionBroker
            "LicenseServers"   = $config.LicenseServer          
            "LicenseMode"      = $config.Mode.ToString()  # Microsoft.RemoteDesktopServices.Management.LicensingMode  .ToString()
        }

        write-verbose ">> RD License mode:     $($result.LicenseMode)"
        write-verbose ">> RD License servers:  $($result.LicenseServers -join '; ')"
    }
    else
    {
        write-verbose "Failed to retrieve RD License configuration from broker '$ConnectionBroker'."
    }

    $result
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
        [ValidateNotNullOrEmpty()]
        [string] $ConnectionBroker,
        
        [string[]] $LicenseServers,
        
        [ValidateSet("PerUser", "PerDevice", "NotConfigured")]
        [string] $LicenseMode
    )
    
    write-verbose "Starting RD License server configuration..."
    write-verbose ">> RD Connection Broker:  $($ConnectionBroker.ToLower())"

    if ($LicenseServers)
    {
        write-verbose ">> RD License servers:    $($LicenseServers -join '; ')"

        "calling Set-RDLicenseConfiguration cmdlet..."
        Set-RDLicenseConfiguration -ConnectionBroker $ConnectionBroker -LicenseServer $LicenseServers -Mode $LicenseMode -Force
    }
    else
    {
        "calling Set-RDLicenseConfiguration cmdlet..."
        Set-RDLicenseConfiguration -ConnectionBroker $ConnectionBroker -Mode $LicenseMode -Force
    }

    write-verbose "Set-RDLicenseConfiguration done."
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
        [ValidateNotNullOrEmpty()]
        [string] $ConnectionBroker,
        
        [string[]] $LicenseServers,
        
        [ValidateSet("PerUser", "PerDevice", "NotConfigured")]
        [string] $LicenseMode
    )

    $config = Get-TargetResource @PSBoundParameters
    
    if ($config)
    {
        write-verbose "verifying RD Licensing mode..."

        $result = ($config.LicenseMode -eq $LicenseMode)
    }
    else
    {
        write-verbose "Failed to retrieve RD License server configuration from broker '$ConnectionBroker'."
        $result = $false
    }

    write-verbose "Test-TargetResource returning:  $result"
    return $result
}


Export-ModuleMember -Function *-TargetResource
