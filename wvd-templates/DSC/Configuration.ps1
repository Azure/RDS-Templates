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
    
        [Parameter(mandatory = $false)]
        [string]$Description,
    
        [Parameter(mandatory = $false)]
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
        [string]$DefaultDesktopUsers
    )

    $rdshIsServer = $true
    $ScriptPath = [system.io.path]::GetDirectoryName($PSCommandPath)

    $OSVersionInfo = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
    
    if ($OSVersionInfo -ne $null)
    {
        if ($OSVersionInfo.InstallationType -ne $null)
        {
            $rdshIsServer=@{$true = $true; $false = $false}[$OSVersionInfo.InstallationType -eq "Server"]
        }
    }

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
            ConfigurationMode = "ApplyOnly"
        }

        if ($rdshIsServer)
        {
            "$(get-date) - rdshIsServer = true: $rdshIsServer" | out-file c:\windows\temp\rdshIsServerResult.txt -Append
            WindowsFeature RDS-RD-Server
            {
                Ensure = "Present"
                Name = "RDS-RD-Server"
            }
        }

        Script ExecuteRdAgentInstall
        {
            GetScript = {
                return @{'Result' = ''}
            }
            SetScript = {
                & "$using:ScriptPath\Script-FirstRdshServer.ps1" -RdBrokerURL $using:RDBrokerURL -DefinedTenantGroupName $using:DefinedTenantGroupName -TenantName $using:TenantName -TenantAdminCredentials $using:TenantAdminCredentials -HostPoolName $using:HostPoolName -FriendlyName $using:FriendlyName -Description $using:Description -Hours $using:Hours -isServicePrincipal $using:isServicePrincipal -aadTenantId $using:AadTenantId -EnablePersistentDesktop $using:EnablePersistentDesktop -DefaultDesktopUsers $using:DefaultDesktopUsers
            }
            TestScript = {
                return (Test-path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent")
            }
        }
    }
}

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


    $rdshIsServer = $true
    $ScriptPath = [system.io.path]::GetDirectoryName($PSCommandPath)

    $OSVersionInfo = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
    
    if ($OSVersionInfo -ne $null)
    {
        if ($OSVersionInfo.InstallationType -ne $null)
        {
            $rdshIsServer=@{$true = $true; $false = $false}[$OSVersionInfo.InstallationType -eq "Server"]
        }
    }

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
            ConfigurationMode = "ApplyOnly"
        }

        if ($rdshIsServer)
        {
            "$(get-date) - rdshIsServer = true: $rdshIsServer" | out-file c:\windows\temp\rdshIsServerResult.txt -Append
            WindowsFeature RDS-RD-Server
            {
                Ensure = "Present"
                Name = "RDS-RD-Server"
            }
        }
        Script ExecuteRdAgentInstallClient
        {
            GetScript = {
                return @{'Result' = ''}
            }
            SetScript = {
                & "$using:ScriptPath\Script-AdditionalRdshServers.ps1" -RdBrokerURL $using:RDBrokerURL -DefinedTenantGroupName $using:DefinedTenantGroupName -TenantName $using:TenantName -TenantAdminCredentials $using:TenantAdminCredentials -HostPoolName $using:HostPoolName -Hours $using:Hours -isServicePrincipal $using:isServicePrincipal -aadTenantId $using:AadTenantId
            }
            TestScript = {
                return (Test-path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent")
            }
        }
    }
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
    
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]$AadTenantId = ""
    )

    $ScriptPath = [system.io.path]::GetDirectoryName($PSCommandPath)
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
                & "$using:ScriptPath\Script-RegisterSessionHost.ps1" -RdBrokerURL $using:RDBrokerURL -DefinedTenantGroupName $using:DefinedTenantGroupName -TenantName $using:TenantName -HostPoolName $using:HostPoolName -Hours $using:Hours -TenantAdminCredentials $using:TenantAdminCredentials -isServicePrincipal $using:isServicePrincipal -aadTenantId $using:AadTenantId
            }
            TestScript = {
                return (Test-path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent")
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
    
        [Parameter(Mandatory = $false)]
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
        [string]$rdshPrefix
    )

    $ScriptPath = [system.io.path]::GetDirectoryName($PSCommandPath)
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
                & "$using:ScriptPath\Script-RegisterSessionHost.ps1" -RdBrokerURL $using:RDBrokerURL -DefinedTenantGroupName $using:DefinedTenantGroupName -TenantName $using:TenantName -HostPoolName $using:HostPoolName -Hours $using:Hours -TenantAdminCredentials $using:TenantAdminCredentials -isServicePrincipal $using:isServicePrincipal -aadTenantId $using:AadTenantId
            }
            TestScript = {
                return (Test-path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent")
            }
        }

        Script CleanupOldRdshSessionHosts {
            GetScript  = {
                return @{'Result' = '' }
            }
            SetScript  = {
                & "$using:ScriptPath\Script-CleanupOldRdshSessionHosts.ps1" -RdBrokerURL $using:RDBrokerURL -DefinedTenantGroupName $using:DefinedTenantGroupName -TenantName $using:TenantName -HostPoolName $using:HostPoolName -TenantAdminCredentials $using:TenantAdminCredentials -AdAdminCredentials $using:AdAdminCredentials -isServicePrincipal $using:isServicePrincipal -aadTenantId $using:AadTenantId -SubscriptionId $using:SubscriptionId -userLogoffDelayInMinutes $using:userLogoffDelayInMinutes -userNotificationMessege $using:userNotificationMessege -messageTitle $using:messageTitle -deleteordeallocateVMs $using:deleteordeallocateVMs -DomainName $using:DomainName -rdshNumberOfInstances $using:rdshNumberOfInstances -rdshPrefix $using:rdshPrefix
            }
            TestScript = {
                return (& "$using:ScriptPath\Script-TestCleanupOldRdshSessionHosts.ps1" -RdBrokerURL $using:RDBrokerURL -DefinedTenantGroupName $using:DefinedTenantGroupName -TenantName $using:TenantName -HostPoolName $using:HostPoolName -TenantAdminCredentials $using:TenantAdminCredentials -isServicePrincipal $using:isServicePrincipal -aadTenantId $using:AadTenantId -DomainName $using:DomainName -rdshNumberOfInstances $using:rdshNumberOfInstances -rdshPrefix $using:rdshPrefix)
            }
        }
    }
}