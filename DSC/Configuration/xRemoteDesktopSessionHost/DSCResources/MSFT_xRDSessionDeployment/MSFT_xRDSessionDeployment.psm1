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
        
        [string] $WebAccessServer,
        
        [string[]] $SessionHosts
    )

    $result = $null

    write-verbose "Getting list of RD Server roles from '$ConnectionBroker'..."    

    $servers = Get-RDServer -ConnectionBroker $ConnectionBroker -ea SilentlyContinue


    if ($servers)
    {
        write-verbose "Found deployment consisting of $($servers.Count) servers:"
      # write-verbose ( $servers | out-string )

        $result = 
        @{
            "ConnectionBroker" = ($servers | where Roles -contains "RDS-CONNECTION-BROKER").Server
            "WebAccessServer"  = ($servers | where Roles -contains "RDS-WEB-ACCESS").Server
            
            "SessionHosts"   = $servers | where Roles -contains "RDS-RD-SERVER" | % Server
        }


        write-verbose ">> RD Connection Broker:     $($result.ConnectionBroker.ToLower())"
        
        if ($result.WebAccessServer)
        {
            write-verbose ">> RD Web Access server:     $($result.WebAccessServer.ToLower())"
        }
        
        write-verbose ">> RD Session Host servers:  $($result.SessionHosts.ToLower() -join '; ')"


        $licenseServers = $servers | where Roles -contains "RDS-LICENSING" | % Server
        
        if ($licenseServers)
        {
            write-verbose ">> RD License servers  :     $($licenseServers.ToLower() -join '; ')"
        }
    }
    else
    {
        write-verbose "Remote Desktop deployment does not exist on server '$ConnectionBroker' (or Remote Desktop Management Service is not running)."
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

        [string] $WebAccessServer,

        [string[]] $SessionHosts
    )


    if (-not $SessionHosts)  { $SessionHosts =  @( $ConnectionBroker ) }

    
    write-verbose "Initiating new RD Session-based deployment on '$ConnectionBroker'..."

    write-verbose ">> RD Connection Broker:     $($ConnectionBroker.ToLower())"

    if ($WebAccessServer)
    {
        write-verbose ">> RD Web Access server:     $($WebAccessServer.ToLower())"
    }
    else
    {
        $PSBoundParameters.Remove("WebAccessServer")
    }

    write-verbose ">> RD Session Host servers:  $($SessionHosts.ToLower() -join '; ')"


    write-verbose "calling New-RdSessionDeployment cmdlet..."
    #{
        $PSBoundParameters.Remove("SessionHosts");  

        New-RDSessionDeployment @PSBoundParameters -SessionHost $SessionHosts
    #}
    write-verbose "New-RdSessionDeployment done."

 
  # write-verbose "RD Session deployment done, setting reboot flag..."
  # $global:DSCMachineStatus = 1
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

        [string] $WebAccessServer,

        [string[]] $SessionHosts
    )


    write-verbose "Checking whether Remote Desktop deployment exists on server '$ConnectionBroker'..."

    $rddeployment = Get-TargetResource @PSBoundParameters
    
    if ($rddeployment)
    {
        write-verbose "verifying RD Connection broker name..."
        $result =  ($rddeployment.ConnectionBroker -ieq $ConnectionBroker)
    }
    else
    {
        write-verbose "RD deployment not found."
        $result = $false
    }

    write-verbose "Test-TargetResource returning:  $result"
    return $result
}


Export-ModuleMember -Function *-TargetResource
