
configuration CreateHostPoolAndRegisterSessionHost
{
    param
    (
        [Parameter(mandatory = $true)]
        [string]$RDBrokerURL,
    
        [Parameter(mandatory = $true)]
        [string]$DefinedTenantGroupName,
    
        [Parameter(mandatory = $true)]
        [string]$TenantName,
    
        [Parameter(mandatory = $true)]
        [string]$HostPoolName,
    
        [Parameter(mandatory = $true)]
        [string]$Description,
    
        [Parameter(mandatory = $true)]
        [string]$FriendlyName,
    
        [Parameter(mandatory = $true)]
        [string]$Hours,
    
        [Parameter(mandatory = $true)]
        [PSCredential]$TenantAdminCredentials,
	
        [Parameter(mandatory = $false)]
        [string]$isServicePrincipal = "False",
    
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]$AadTenantId = "",
    
        [Parameter(Mandatory = $false)]
        [string]$EnablePersistentDesktop = "False",

        [Parameter(Mandatory = $true)]
        [string]$DefaultDesktopUsers,

        [Parameter(mandatory = $false)]
        [string]$RDPSModSource = 'attached'
    )

    $ErrorActionPreference = 'Stop'

    $ScriptPath = [system.io.path]::GetDirectoryName($PSCommandPath)
    . (Join-Path $ScriptPath "Functions.ps1")

    $rdshIsServer = isRdshServer

    Node localhost
    {
        LocalConfigurationManager {
            RebootNodeIfNeeded = $true
            ConfigurationMode  = "ApplyOnly"
        }

        if ($rdshIsServer) {
            "$(get-date) - rdshIsServer = true: $rdshIsServer" | out-file c:\windows\temp\rdshIsServerResult.txt -Append
            WindowsFeature RDS-RD-Server {
                Ensure = "Present"
                Name   = "RDS-RD-Server"
            }
        }

        Script CreateHostPool {
            GetScript  = {
                return @{'Result' = '' }
            }
            SetScript  = {
                . (Join-Path $using:ScriptPath "Functions.ps1")
                
                try {
                    return (& "$using:ScriptPath\Script-CreateHostPool.ps1" -RdBrokerURL $using:RDBrokerURL -DefinedTenantGroupName $using:DefinedTenantGroupName -TenantName $using:TenantName -HostPoolName $using:HostPoolName -Description $using:Description -FriendlyName $using:FriendlyName -TenantAdminCredentials $using:TenantAdminCredentials -isServicePrincipal $using:isServicePrincipal -aadTenantId $using:AadTenantId -EnablePersistentDesktop $using:EnablePersistentDesktop -RDPSModSource $using:RDPSModSource)
                }
                catch {
                    $ErrMsg = $PSItem | Format-List -Force | Out-String
                    Write-Log -Err $ErrMsg
                    throw [System.Exception]::new("Some error occurred in DSC CreateHostPool SetScript: $ErrMsg", $PSItem.Exception)
                }
            }
            TestScript = {
                . (Join-Path $using:ScriptPath "Functions.ps1")

                try {
                    return (& "$using:ScriptPath\Script-TestHostPoolExists.ps1" -RdBrokerURL $using:RDBrokerURL -DefinedTenantGroupName $using:DefinedTenantGroupName -TenantName $using:TenantName -HostPoolName $using:HostPoolName -TenantAdminCredentials $using:TenantAdminCredentials -isServicePrincipal $using:isServicePrincipal -aadTenantId $using:AadTenantId -RDPSModSource $using:RDPSModSource)
                }
                catch {
                    $ErrMsg = $PSItem | Format-List -Force | Out-String
                    Write-Log -Err $ErrMsg
                    throw [System.Exception]::new("Some error occurred in DSC CreateHostPool TestScript: $ErrMsg", $PSItem.Exception)
                }
            }
        }

        Script RegisterSessionHostAndAddDefaultUsers {
            GetScript  = {
                return @{'Result' = '' }
            }
            SetScript  = {
                . (Join-Path $using:ScriptPath "Functions.ps1")

                try {
                    & "$using:ScriptPath\Script-RegisterSessionHost.ps1" -RdBrokerURL $using:RDBrokerURL -DefinedTenantGroupName $using:DefinedTenantGroupName -TenantName $using:TenantName -HostPoolName $using:HostPoolName -Hours $using:Hours -TenantAdminCredentials $using:TenantAdminCredentials -isServicePrincipal $using:isServicePrincipal -aadTenantId $using:AadTenantId -RDPSModSource $using:RDPSModSource
                    return (& "$using:ScriptPath\Script-AddDefaultUsers.ps1" -RdBrokerURL $using:RDBrokerURL -DefinedTenantGroupName $using:DefinedTenantGroupName -TenantName $using:TenantName -HostPoolName $using:HostPoolName -TenantAdminCredentials $using:TenantAdminCredentials -isServicePrincipal $using:isServicePrincipal -aadTenantId $using:AadTenantId -DefaultDesktopUsers $using:DefaultDesktopUsers -RDPSModSource $using:RDPSModSource)
                }
                catch {
                    $ErrMsg = $PSItem | Format-List -Force | Out-String
                    Write-Log -Err $ErrMsg
                    throw [System.Exception]::new("Some error occurred in DSC RegisterSessionHostAndAddDefaultUsers SetScript: $ErrMsg", $PSItem.Exception)
                }
            }
            TestScript = {
                . (Join-Path $using:ScriptPath "Functions.ps1")

                try {
                    return (& "$using:ScriptPath\Script-TestRegisterSessionHost.ps1" -RdBrokerURL $using:RDBrokerURL -DefinedTenantGroupName $using:DefinedTenantGroupName -TenantName $using:TenantName -HostPoolName $using:HostPoolName -TenantAdminCredentials $using:TenantAdminCredentials -isServicePrincipal $using:isServicePrincipal -aadTenantId $using:AadTenantId -RDPSModSource $using:RDPSModSource)
                }
                catch {
                    $ErrMsg = $PSItem | Format-List -Force | Out-String
                    Write-Log -Err $ErrMsg
                    throw [System.Exception]::new("Some error occurred in DSC RegisterSessionHostAndAddDefaultUsers TestScript: $ErrMsg", $PSItem.Exception)
                }
            }
        }
    }
}

configuration RegisterSessionHost
{
    param
    (
        [Parameter(mandatory = $true)]
        [string]$RDBrokerURL,
    
        [Parameter(mandatory = $true)]
        [string]$DefinedTenantGroupName,
    
        [Parameter(mandatory = $true)]
        [string]$TenantName,
    
        [Parameter(mandatory = $true)]
        [string]$HostPoolName,
    
        [Parameter(mandatory = $true)]
        [string]$Hours,
    
        [Parameter(mandatory = $true)]
        [PSCredential]$TenantAdminCredentials,
		
        [Parameter(mandatory = $false)]
        [string]$isServicePrincipal = "False",
    
        [Parameter(mandatory = $false)]
        [AllowEmptyString()]
        [string]$AadTenantId = "",

        [Parameter(mandatory = $false)]
        [string]$RDPSModSource = 'attached'
    )

    $ErrorActionPreference = 'Stop'

    $ScriptPath = [system.io.path]::GetDirectoryName($PSCommandPath)
    . (Join-Path $ScriptPath "Functions.ps1")

    $rdshIsServer = isRdshServer

    Node localhost
    {
        LocalConfigurationManager {
            RebootNodeIfNeeded = $true
            ConfigurationMode  = "ApplyOnly"
        }

        if ($rdshIsServer) {
            "$(get-date) - rdshIsServer = true: $rdshIsServer" | out-file c:\windows\temp\rdshIsServerResult.txt -Append
            WindowsFeature RDS-RD-Server {
                Ensure = "Present"
                Name   = "RDS-RD-Server"
            }
        }

        Script RegisterSessionHost {
            GetScript  = {
                return @{'Result' = '' }
            }
            SetScript  = {
                . (Join-Path $using:ScriptPath "Functions.ps1")

                try {
                    return (& "$using:ScriptPath\Script-RegisterSessionHost.ps1" -RdBrokerURL $using:RDBrokerURL -DefinedTenantGroupName $using:DefinedTenantGroupName -TenantName $using:TenantName -HostPoolName $using:HostPoolName -Hours $using:Hours -TenantAdminCredentials $using:TenantAdminCredentials -isServicePrincipal $using:isServicePrincipal -aadTenantId $using:AadTenantId -RDPSModSource $using:RDPSModSource)
                }
                catch {
                    $ErrMsg = $PSItem | Format-List -Force | Out-String
                    Write-Log -Err $ErrMsg
                    throw [System.Exception]::new("Some error occurred in DSC RegisterSessionHost SetScript: $ErrMsg", $PSItem.Exception)
                }
            }
            TestScript = {
                . (Join-Path $using:ScriptPath "Functions.ps1")

                try {
                    return (& "$using:ScriptPath\Script-TestRegisterSessionHost.ps1" -RdBrokerURL $using:RDBrokerURL -DefinedTenantGroupName $using:DefinedTenantGroupName -TenantName $using:TenantName -HostPoolName $using:HostPoolName -TenantAdminCredentials $using:TenantAdminCredentials -isServicePrincipal $using:isServicePrincipal -aadTenantId $using:AadTenantId -RDPSModSource $using:RDPSModSource)
                }
                catch {
                    $ErrMsg = $PSItem | Format-List -Force | Out-String
                    Write-Log -Err $ErrMsg
                    throw [System.Exception]::new("Some error occurred in DSC RegisterSessionHost TestScript: $ErrMsg", $PSItem.Exception)
                }
            }
        }
    }
}

configuration RegisterSessionHostAndCleanup
{
    param
    (
        [Parameter(mandatory = $true)]
        [string]$RDBrokerURL,
    
        [Parameter(mandatory = $true)]
        [string]$DefinedTenantGroupName,
    
        [Parameter(mandatory = $true)]
        [string]$TenantName,
    
        [Parameter(mandatory = $true)]
        [string]$HostPoolName,
    
        [Parameter(mandatory = $true)]
        [string]$Hours,
    
        [Parameter(mandatory = $true)]
        [PSCredential]$TenantAdminCredentials,
		
        [Parameter(mandatory = $false)]
        [PSCredential]$AdAdminCredentials,
		
        [Parameter(mandatory = $false)]
        [string]$isServicePrincipal = "False",
    
        [Parameter(mandatory = $false)]
        [AllowEmptyString()]
        [string]$AadTenantId = "",
        
        [Parameter(mandatory = $false)]
        [string]$SubscriptionId,

        [Parameter(mandatory = $false)]
        [int]$userLogoffDelayInMinutes,

        [Parameter(mandatory = $false)]
        [string]$userNotificationMessege,

        [Parameter(mandatory = $false)]
        [string]$messageTitle,

        [Parameter(mandatory = $false)]
        [string]$deleteordeallocateVMs,

        [Parameter(mandatory = $false)]
        [string]$DomainName,

        [Parameter(mandatory = $false)]
        [int]$rdshNumberOfInstances,

        [Parameter(mandatory = $false)]
        [string]$rdshPrefix,

        [Parameter(mandatory = $false)]
        [string]$RDPSModSource = 'attached'
    )

    $ErrorActionPreference = 'Stop'

    $ScriptPath = [system.io.path]::GetDirectoryName($PSCommandPath)
    . (Join-Path $ScriptPath "Functions.ps1")

    $rdshIsServer = isRdshServer

    Node localhost
    {
        LocalConfigurationManager {
            RebootNodeIfNeeded = $true
            ConfigurationMode  = "ApplyOnly"
        }

        if ($rdshIsServer) {
            "$(get-date) - rdshIsServer = true: $rdshIsServer" | out-file c:\windows\temp\rdshIsServerResult.txt -Append
            WindowsFeature RDS-RD-Server {
                Ensure = "Present"
                Name   = "RDS-RD-Server"
            }
        }

        Script RegisterSessionHost {
            GetScript  = {
                return @{'Result' = '' }
            }
            SetScript  = {
                . (Join-Path $using:ScriptPath "Functions.ps1")

                try {
                    return (& "$using:ScriptPath\Script-RegisterSessionHost.ps1" -RdBrokerURL $using:RDBrokerURL -DefinedTenantGroupName $using:DefinedTenantGroupName -TenantName $using:TenantName -HostPoolName $using:HostPoolName -Hours $using:Hours -TenantAdminCredentials $using:TenantAdminCredentials -isServicePrincipal $using:isServicePrincipal -aadTenantId $using:AadTenantId -RDPSModSource $using:RDPSModSource)
                }
                catch {
                    $ErrMsg = $PSItem | Format-List -Force | Out-String
                    Write-Log -Err $ErrMsg
                    throw [System.Exception]::new("Some error occurred in DSC: RegisterSessionHost: SetScript: $ErrMsg", $PSItem.Exception)
                }
            }
            TestScript = {
                . (Join-Path $using:ScriptPath "Functions.ps1")

                try {
                    return (& "$using:ScriptPath\Script-TestRegisterSessionHost.ps1" -RdBrokerURL $using:RDBrokerURL -DefinedTenantGroupName $using:DefinedTenantGroupName -TenantName $using:TenantName -HostPoolName $using:HostPoolName -TenantAdminCredentials $using:TenantAdminCredentials -isServicePrincipal $using:isServicePrincipal -aadTenantId $using:AadTenantId -RDPSModSource $using:RDPSModSource)
                }
                catch {
                    $ErrMsg = $PSItem | Format-List -Force | Out-String
                    Write-Log -Err $ErrMsg
                    throw [System.Exception]::new("Some error occurred in DSC RegisterSessionHost TestScript: $ErrMsg", $PSItem.Exception)
                }
            }
        }

        Script CleanupOldRdshSessionHosts {
            GetScript  = {
                return @{'Result' = '' }
            }
            SetScript  = {
                . (Join-Path $using:ScriptPath "Functions.ps1")

                try {
                    return (& "$using:ScriptPath\Script-CleanupOldRdshSessionHosts.ps1" -RdBrokerURL $using:RDBrokerURL -DefinedTenantGroupName $using:DefinedTenantGroupName -TenantName $using:TenantName -HostPoolName $using:HostPoolName -TenantAdminCredentials $using:TenantAdminCredentials -AdAdminCredentials $using:AdAdminCredentials -isServicePrincipal $using:isServicePrincipal -aadTenantId $using:AadTenantId -SubscriptionId $using:SubscriptionId -userLogoffDelayInMinutes $using:userLogoffDelayInMinutes -userNotificationMessege $using:userNotificationMessege -messageTitle $using:messageTitle -deleteordeallocateVMs $using:deleteordeallocateVMs -DomainName $using:DomainName -rdshNumberOfInstances $using:rdshNumberOfInstances -rdshPrefix $using:rdshPrefix -RDPSModSource $using:RDPSModSource)
                }
                catch {
                    $ErrMsg = $PSItem | Format-List -Force | Out-String
                    Write-Log -Err $ErrMsg
                    throw [System.Exception]::new("Some error occurred in DSC CleanupOldRdshSessionHosts SetScript: $ErrMsg", $PSItem.Exception)
                }
            }
            TestScript = {
                . (Join-Path $using:ScriptPath "Functions.ps1")

                try {
                    return (& "$using:ScriptPath\Script-TestCleanupOldRdshSessionHosts.ps1" -RdBrokerURL $using:RDBrokerURL -DefinedTenantGroupName $using:DefinedTenantGroupName -TenantName $using:TenantName -HostPoolName $using:HostPoolName -TenantAdminCredentials $using:TenantAdminCredentials -isServicePrincipal $using:isServicePrincipal -aadTenantId $using:AadTenantId -DomainName $using:DomainName -rdshNumberOfInstances $using:rdshNumberOfInstances -rdshPrefix $using:rdshPrefix -RDPSModSource $using:RDPSModSource)
                }
                catch {
                    $ErrMsg = $PSItem | Format-List -Force | Out-String
                    Write-Log -Err $ErrMsg
                    throw [System.Exception]::new("Some error occurred in DSC CleanupOldRdshSessionHosts TestScript: $ErrMsg", $PSItem.Exception)
                }
            }
        }
    }
}

# Note: Do not use this in new code, it is here for backwards compatibility and may be removed soon.
configuration FirstSessionHost
{
    param
    (
        [Parameter(mandatory = $true)]
        [string]$RDBrokerURL,
    
        [Parameter(mandatory = $true)]
        [string]$DefinedTenantGroupName,
    
        [Parameter(mandatory = $true)]
        [string]$TenantName,
    
        [Parameter(mandatory = $true)]
        [string]$HostPoolName,
    
        [Parameter(mandatory = $true)]
        [string]$Description,
    
        [Parameter(mandatory = $true)]
        [string]$FriendlyName,
    
        [Parameter(mandatory = $true)]
        [string]$Hours,
    
        [Parameter(mandatory = $true)]
        [PSCredential]$TenantAdminCredentials,
	
        [Parameter(mandatory = $false)]
        [string]$isServicePrincipal = "False",
    
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]$AadTenantId = "",
    
        [Parameter(Mandatory = $false)]
        [string]$EnablePersistentDesktop = "False",

        [Parameter(Mandatory = $true)]
        [string]$DefaultDesktopUsers,

        [Parameter(mandatory = $false)]
        [string]$RDPSModSource = 'attached'
    )

    . CreateHostPoolAndRegisterSessionHost @PSBoundParameters
}

# Note: Do not use this in new code, it is here for backwards compatibility and may be removed soon.
configuration AdditionalSessionHosts
{
    param
    (
        [Parameter(mandatory = $true)]
        [string]$RDBrokerURL,
    
        [Parameter(mandatory = $true)]
        [string]$DefinedTenantGroupName,
    
        [Parameter(mandatory = $true)]
        [string]$TenantName,
    
        [Parameter(mandatory = $true)]
        [string]$HostPoolName,

        [Parameter(mandatory = $true)]
        [string]$Hours,
      
        [Parameter(mandatory = $true)]
        [PSCredential]$TenantAdminCredentials,
    
        [Parameter(mandatory = $false)]
        [string]$IsServicePrincipal = "False",
    
        [Parameter(Mandatory = $false)]
        [string]$AadTenantId = ""
    )

    . RegisterSessionHost @PSBoundParameters
}