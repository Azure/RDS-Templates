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
        [string]$Hours,
    
        [Parameter(mandatory = $true)]
        [PSCredential]$TenantAdminCredentials,
		
        [Parameter(mandatory = $true)]
        [PSCredential]$AdAdminCredentials,
		
        [Parameter(mandatory = $false)]
        [string]$isServicePrincipal = "False",
    
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]$AadTenantId = "",
        
        [Parameter(mandatory = $true)]
        [string]$SubscriptionId,

        [Parameter(mandatory = $false)]
        [int]$userLogoffDelayInMinutes,

        [Parameter(mandatory = $false)]
        [string]$userNotificationMessege,

        [Parameter(mandatory = $false)]
        [string]$messageTitle,

        [Parameter(mandatory = $true)]
        [string]$deleteordeallocateVMs,

        [Parameter(mandatory = $true)]
        [string]$DomainName
    )

    $rdshIsServer = $true
    $ScriptPath = [system.io.path]::GetDirectoryName($PSCommandPath)

    $OSVersionInfo = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
    
    if ($OSVersionInfo -ne $null) {
        if ($OSVersionInfo.InstallationType -ne $null) {
            $rdshIsServer = @{$true = $true; $false = $false}[$OSVersionInfo.InstallationType -eq "Server"]
        }
    }

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
        Script ExecuteRdAgentInstallServer {
            GetScript  = {
                return @{'Result' = ''}
            }
            SetScript  = {
                & "$using:ScriptPath\Script-FirstRdshServer.ps1" -RdBrokerURL $using:RDBrokerURL -DefinedTenantGroupName $using:DefinedTenantGroupName -TenantName $using:TenantName -TenantAdminCredentials $using:TenantAdminCredentials -AdAdminCredentials $using:AdAdminCredentials -DomainName $using:DomainName -HostPoolName $using:HostPoolName -Hours $using:Hours -isServicePrincipal $using:isServicePrincipal -aadTenantId $using:AadTenantId -SubscriptionId $using:SubscriptionId -userLogoffDelayInMinutes $using:userLogoffDelayInMinutes -userNotificationMessege $using:userNotificationMessege -messageTitle $using:messageTitle -deleteordeallocateVMs $using:deleteordeallocateVMs
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
    
    if ($OSVersionInfo -ne $null) {
        if ($OSVersionInfo.InstallationType -ne $null) {
            $rdshIsServer = @{$true = $true; $false = $false}[$OSVersionInfo.InstallationType -eq "Server"]
        }
    }

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
        Script ExecuteRdAgentInstallServer {
            GetScript  = {
                return @{'Result' = ''}
            }
            SetScript  = {
                & "$using:ScriptPath\Script-AdditionalRdshServers.ps1" -RdBrokerURL $using:RDBrokerURL -DefinedTenantGroupName $using:DefinedTenantGroupName -TenantName $using:TenantName -TenantAdminCredentials $using:TenantAdminCredentials -HostPoolName $using:HostPoolName -Hours $using:Hours -isServicePrincipal $using:isServicePrincipal -aadTenantId $using:AadTenantId
            }
            TestScript = {
                return (Test-path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent")
            }
        }
    }
}