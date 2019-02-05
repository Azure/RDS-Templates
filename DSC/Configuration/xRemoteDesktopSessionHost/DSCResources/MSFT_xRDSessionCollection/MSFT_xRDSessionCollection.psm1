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
        [string] $ConnectionBroker,
 
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $CollectionName,

        [string] $CollectionDescription,
 
        [string[]] $SessionHosts
    )

    $result = $null

    if ($ConnectionBroker)
    {
        write-verbose "Getting information about RD Session collection '$CollectionName' at RD Connection Broker '$ConnectionBroker'..."
     
        $collection = Get-RDSessionCollection -CollectionName $CollectionName -ConnectionBroker $ConnectionBroker -ea SilentlyContinue
    }
    else
    {
        write-verbose "Getting information about RD Session collection '$CollectionName'..."
     
        $collection = Get-RDSessionCollection -CollectionName $CollectionName -ea SilentlyContinue

        $ConnectionBroker = $localhost
    }

    if ($collection)
    {
        write-verbose "found the collection, now getting list of RD Session Host servers..."

        $SessionHosts = Get-RDSessionHost -CollectionName $CollectionName | % SessionHost
        write-verbose "found $($SessionHosts.Count) host servers assigned to the collection."

        $result = 
        @{
            "ConnectionBroker" = $ConnectionBroker

            "CollectionName"   = $collection.CollectionName
            "CollectionDescription" = $collection.CollectionDescription

            "SessionHosts" = $SessionHosts
        }

        write-verbose ">> Collection name:  $($result.CollectionName)"
        write-verbose ">> Collection description:  $($result.CollectionDescription)"
        write-verbose ">> RD Connection Broker:  $($result.ConnectionBroker.ToLower())"
        write-verbose ">> RD Session Host servers:  $($result.SessionHosts.ToLower() -join '; ')"
    }
    else
    {
        write-verbose "RD Session collection '$CollectionName' not found."
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
        [string] $ConnectionBroker,
        
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $CollectionName,

        [string] $CollectionDescription,
        
        [string[]] $SessionHosts
    )

    if ($ConnectionBroker)
    { 
        write-verbose "Creating a new RD Session collection '$CollectionName' at the RD Connection Broker '$ConnectionBroker'..."
    }
    else
    {
        $PSBoundParameters.Remove("ConnectionBroker")
        write-verbose "Creating a new RD Session collection '$CollectionName'..."
    }

    if ($CollectionDescription)  
    {
        write-verbose "Description: '$CollectionDescription'"
    }
    else
    { 
        $PSBoundParameters.Remove("CollectionDescription") 
    }
    
    if ($SessionHosts) 
    {
        write-verbose ">> RD Session Host servers:  $($SessionHosts.ToLower() -join '; ')"
    }
    else 
    { 
        $SessionHosts = @( $localhost ) 
    }

    
    $PSBoundParameters.Remove("SessionHosts")
    write-verbose "calling New-RdSessionCollection cmdlet..."
    New-RDSessionCollection @PSBoundParameters -SessionHost $SessionHosts

    #    Add-RDSessionHost @PSBoundParameters  # that's if the Session host is not in the collection
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
        [string] $ConnectionBroker,

        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $CollectionName,

        [string] $CollectionDescription,

        [string[]] $SessionHosts
    )

    write-verbose "Checking for existence of RD Session collection named '$CollectionName'..."
    
    $collection = Get-TargetResource @PSBoundParameters
    
    if ($collection)
    {
        write-verbose "verifying RD Session collection name and parameters..."
        $result =  ($collection.CollectionName -ieq $CollectionName)
    }
    else
    {
        write-verbose "RD Session collection named '$CollectionName' not found."
        $result = $false
    }

    write-verbose "Test-TargetResource returning:  $result"
    return $result
}


Export-ModuleMember -Function *-TargetResource