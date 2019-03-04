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
    
        [Parameter(mandatory = $true)]
        [PSCredential]$ADAdminCredentials,
    
        [Parameter(mandatory = $false)]
        [string]$isServicePrincipal = "False",
    
        [Parameter(Mandatory = $false)]
        [string]$AadTenantId,
    
        [Parameter(Mandatory = $true)]
        [string]$EnablePersistentDesktop="False",

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

            Script ExecuteRdAgentInstallServer
            {
                DependsOn = "[WindowsFeature]RDS-RD-Server"
                GetScript = {
                    return @{'Result' = ''}
                }
                SetScript = {
                    & "$using:ScriptPath\Script-FirstRdshServer.ps1" -RdBrokerURL $using:RDBrokerURL -DefinedTenantGroupName $using:DefinedTenantGroupName -TenantName $using:TenantName -TenantAdminCredentials $using:TenantAdminCredentials -ADAdminCredentials $using:ADAdminCredentials -HostPoolName $using:HostPoolName -FriendlyName $using:FriendlyName -Description $using:Description -Hours $using:Hours -isServicePrincipal $using:isServicePrincipal -aadTenantId $using:AadTenantId -EnablePersistentDesktop $using:EnablePersistentDesktop -DefaultDesktopUsers $using:DefaultDesktopUsers
                }
                TestScript = {
                    return (Test-path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent")
                }
            }
        }
        else
        {
            "$(get-date) - rdshIsServer = false: $rdshIsServer" | out-file c:\windows\temp\rdshIsServerResult.txt -Append
            Script ExecuteRdAgentInstallClient
            {
                GetScript = {
                    return @{'Result' = ''}
                }
                SetScript = {
                    & "$using:ScriptPath\Script-FirstRdshServer.ps1" -RdBrokerURL $using:RDBrokerURL -DefinedTenantGroupName $using:DefinedTenantGroupName -TenantName $using:TenantName -TenantAdminCredentials $using:TenantAdminCredentials -ADAdminCredentials $using:ADAdminCredentials -HostPoolName $using:HostPoolName -FriendlyName $using:FriendlyName -Description $using:Description -Hours $using:Hours -isServicePrincipal $using:isServicePrincipal -aadTenantId $using:AadTenantId -EnablePersistentDesktop $using:EnablePersistentDesktop -DefaultDesktopUsers $using:DefaultDesktopUsers
                }
                TestScript = {
                    return (Test-path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent")
                }
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
        [PSCredential]$TenantAdminCredentials,
    
        [Parameter(mandatory = $true)]
        [PSCredential]$ADAdminCredentials,
    
        [Parameter(mandatory = $false)]
        [string]$IsServicePrincipal = "False",
    
        [Parameter(Mandatory = $false)]
        [string]$AadTenantId
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

            Script ExecuteRdAgentInstallServer
            {
                DependsOn = "[WindowsFeature]RDS-RD-Server"
                GetScript = {
                    return @{'Result' = ''}
                }
                SetScript = {
                    & "$using:ScriptPath\Script-AdditionalRdshServers.ps1" -RdBrokerURL $using:RDBrokerURL -DefinedTenantGroupName $using:DefinedTenantGroupName -TenantName $using:TenantName -TenantAdminCredentials $using:TenantAdminCredentials -ADAdminCredentials $using:ADAdminCredentials -HostPoolName $using:HostPoolName  -isServicePrincipal $using:isServicePrincipal -aadTenantId $using:AadTenantId
                }
                TestScript = {
                    return (Test-path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent")
                }
            }
        }
        else
        {
            "$(get-date) - rdshIsServer = false: $rdshIsServer" | out-file c:\windows\temp\rdshIsServerResult.txt -Append
            Script ExecuteRdAgentInstallClient
            {
                GetScript = {
                    return @{'Result' = ''}
                }
                SetScript = {
                    & "$using:ScriptPath\Script-AdditionalRdshServers.ps1" -RdBrokerURL $using:RDBrokerURL -DefinedTenantGroupName $using:DefinedTenantGroupName -TenantName $using:TenantName -TenantAdminCredentials $using:TenantAdminCredentials -ADAdminCredentials $using:ADAdminCredentials -HostPoolName $using:HostPoolName -isServicePrincipal $using:isServicePrincipal -aadTenantId $using:AadTenantId
                }
                TestScript = {
                    return (Test-path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent")
                }
            }
        }
    }
}