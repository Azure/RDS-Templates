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
        
        [string] $GatewayServer,

        [ValidateNotNullOrEmpty()]
        [string] $ExternalFqdn,

        [ValidateSet("DoNotUse","Custom","Automatic")]
        [string] $GatewayMode,

        [ValidateSet("Password","Smartcard","AllowUserToSelectDuringConnection")]
        [string] $LogonMethod,

        [bool] $UseCachedCredentials,
        [bool] $BypassLocal
    )


    $result = $null

    write-verbose "Getting RD Gateway configuration from broker '$ConnectionBroker'..."    
    
    $config = Get-RDDeploymentGatewayConfiguration -ConnectionBroker $ConnectionBroker -ea SilentlyContinue

    if ($config)
    {
        write-verbose "configuration retrieved successfully:"

        write-verbose ">> RD Gateway mode:       $($config.GatewayMode)"

        $result = 
        @{
            "ConnectionBroker" = $ConnectionBroker
            "GatewayMode"      = $config.Gatewaymode.ToString()   # Microsoft.RemoteDesktopServices.Management.GatewayUsage  .ToString()
        }

        if ($config.GatewayMode -eq 'Custom')
        {
          # assert-expression ($config -is [Microsoft.RemoteDesktopServices.Management.CustomGatewaySettings])

            $result.GatewayExternalFqdn  = $config.GatewayExternalFqdn
            $result.LogonMethod          = $config.LogonMethod
            $result.UseCachedCredentials = $config.UseCachedCredentials
            $result.BypassLocal          = $config.BypassLocal

            write-verbose ">> GatewayExternalFqdn:   $($result.GatewayExternalFqdn)"
            write-verbose ">> LogonMethod:           $($result.LogonMethod)"
            write-verbose ">> UseCachedCredentials:  $($result.UseCachedCredentials)"
            write-verbose ">> BypassLocal:           $($result.BypassLocal)"
        }
    }
    else
    {
        write-verbose "Failed to retrieve RD Gateway configuration from broker '$ConnectionBroker'."
    }

    $result
}


######################################################################## 
# The Set-TargetResource cmdlet.
########################################################################
function ValidateCustomModeParameters
{
    param
    (  
        [ValidateSet("DoNotUse","Custom","Automatic")]
        [string] $mode,

        [string] $ExternalFqdn,
        [string] $LogonMethod,

        $UseCachedCredentials,
        $BypassLocal
    )

    write-verbose "validating parameters..."

    $customModeParams = @{ "ExternalFqdn" = $ExternalFqdn; "LogonMethod" = $LogonMethod; "UseCachedCredentials" = $UseCachedCredentials; "BypassLocal" = $BypassLocal }

    if ($mode -eq 'Custom')
    {
        # ensure all 4 parameters were passed in, otherwise Set-RdDeploymentGatewayConfiguration will fail

        $nulls = $customModeParams.getenumerator() | where { $_.value -eq $null  }

        if ($nulls.count -gt 0)
        {
            $nulls | % { write-verbose ">> '$($_.Key)' parameter is empty" }

            write-warning "[PARAMETER VALIDATION FAILURE] i'm gonna throw, right now..."

            throw ("Requested gateway mode is 'Custom', you must pass in the following parameters: $($nulls.Key -join ', ').")
        }
    }
    else
    {
        # give warning about incorrect usage of the resource (do not fail)

        $parametersWithValues = $customModeParams.getenumerator() | where { $_.value }

        if ($parametersWithValues.count -gt 0)
        {
            $parametersWithValues | % { write-verbose ">> '$($_.Key)' was specified, the value is: '$($_.Value)'" }

            write-warning ("[WARNING]: Requested gateway mode is '$mode', the following parametera can only be used with Gateway mode 'Custom': " + 
                            "$($parametersWithValues.Key -join ', '). These parameters will be ignored in the call to Set-RdDeploymentGatewayConfiguration to avoid error!")
        }
    }
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (    
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $ConnectionBroker,
        
        [string] $GatewayServer,

        [ValidateSet("DoNotUse","Custom","Automatic")]
        [string] $GatewayMode,

        [string] $ExternalFqdn,

        [ValidateSet("Password","Smartcard","AllowUserToSelectDuringConnection")]
        [string] $LogonMethod,

        $UseCachedCredentials,
        $BypassLocal
    )

    write-verbose "Starting RD Gateway configuration for the RD deployment at broker '$ConnectionBroker'..."

    # validate parameters
    ValidateCustomModeParameters $GatewayMode $ExternalFqdn $LogonMethod $UseCachedCredentials $BypassLocal


    if ($GatewayServer)
    {
        write-verbose ">> RD Gateway server (parameter):  $($GatewayServer.ToLower())"

        write-verbose "checking if the server is part of the deployment, getting list of servers..."

        $servers = Get-RDServer -ConnectionBroker $ConnectionBroker | where Roles -eq RDS-Gateway

        if ($servers)
        {
            write-verbose "there is $($servers.Count) RD Gateway server(s) in the deployment:"
            write-verbose ">> RD Gateway servers list:  $($servers.Server.ToLower() -join '; ')"

            if ($GatewayServer -in $servers.Server)
            {
                write-verbose "RD Gateways server '$GatewayServer' is already part of the deployment."
                $bAddGatewayServer = $false
            }
            else
            {
                write-verbose "RD Gateways server '$GatewayServer' is not yet in the deployment."
                $bAddGatewayServer = $true
            }
         }
         else
         {
            write-verbose "no RD Gateway servers in the deployment..."

            $bAddGatewayServer = $true
         }

         if ($bAddGatewayServer)
         {
            write-verbose "Adding RD Gateway server '$GatewayServer' to the deployment..."

            Add-RDServer -server $GatewayServer -role RDS-Gateway -gatewayexternalfqdn $ExternalFqdn -connectionbroker $connectionBroker

            write-verbose "Add-RDServer done."
         }
    }


    write-verbose "calling Set-RdDeploymentGatewayConfiguration cmdlet..."

    write-verbose ">> requested GatewayMode:  $GatewayMode"

    if ($GatewayMode -eq 'Custom')
    {
        write-verbose ">> GatewayExternalFqdn:   '$ExternalFqdn'"
        write-verbose ">> LogonMethod:           '$LogonMethod'"
        write-verbose ">> UseCachedCredentials:  $UseCachedCredentials"
        write-verbose ">> BypassLocal:           $BypassLocal"

        Set-RdDeploymentGatewayConfiguration -ConnectionBroker $ConnectionBroker -gatewaymode $GatewayMode -gatewayexternalfqdn $ExternalFqdn `
            -logonmethod $LogonMethod -usecachedcredentials $UseCachedCredentials -bypasslocal $BypassLocal -force
    }
    else   # 'DoNotUse' or 'Automatic'
    {
        Set-RdDeploymentGatewayConfiguration -ConnectionBroker $ConnectionBroker -gatewaymode $GatewayMode -force
    }

    write-verbose "Set-RdDeploymentGatewayConfiguration done."
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
        
        [string] $GatewayServer,

        [ValidateNotNullOrEmpty()]
        [string] $ExternalFqdn,

        [ValidateSet("DoNotUse","Custom","Automatic")]
        [string] $GatewayMode,

        [ValidateSet("Password","Smartcard","AllowUserToSelectDuringConnection")]
        [string] $LogonMethod,

        [bool] $UseCachedCredentials,
        [bool] $BypassLocal
    )


    $config = Get-TargetResource @PSBoundParameters
    
    if ($config)
    {
        write-verbose "verifying RD Gateway usage name..."
        $result =  ($config.GatewayMode -ieq $GatewayMode)
    }
    else
    {
        write-verbose "Failed to retrieve RD Gateway configuration."
        $result = $false
    }

    write-verbose "Test-TargetResource returning:  $result"
    return $result
}


Export-ModuleMember -Function *-TargetResource
