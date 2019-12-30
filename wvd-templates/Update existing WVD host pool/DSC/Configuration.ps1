configuration SessionHost
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
        [string]$rdshPrefix,

        # [Parameter(mandatory = $false)]
        [switch]$Last
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
                & "$using:ScriptPath\Script-RdshServer.ps1" -RdBrokerURL $using:RDBrokerURL -DefinedTenantGroupName $using:DefinedTenantGroupName -TenantName $using:TenantName -HostPoolName $using:HostPoolName -Hours $using:Hours -TenantAdminCredentials $using:TenantAdminCredentials -isServicePrincipal $using:isServicePrincipal -aadTenantId $using:AadTenantId
            }
            TestScript = {
                return (Test-path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent")
            }
        }

        Script CleanupOldRdshSessionHosts {
            GetScript  = {
                return @{'Result' = ''}
            }
            SetScript  = {
                & "$using:ScriptPath\Script-CleanupOldRdshSessionHosts.ps1" -RdBrokerURL $using:RDBrokerURL -DefinedTenantGroupName $using:DefinedTenantGroupName -TenantName $using:TenantName -HostPoolName $using:HostPoolName -TenantAdminCredentials $using:TenantAdminCredentials -AdAdminCredentials $using:AdAdminCredentials -isServicePrincipal $using:isServicePrincipal -aadTenantId $using:AadTenantId -SubscriptionId $using:SubscriptionId -userLogoffDelayInMinutes $using:userLogoffDelayInMinutes -userNotificationMessege $using:userNotificationMessege -messageTitle $using:messageTitle -deleteordeallocateVMs $using:deleteordeallocateVMs -DomainName $using:DomainName -rdshNumberOfInstances $using:rdshNumberOfInstances -rdshPrefix $using:rdshPrefix
            }
            TestScript = {
                return (!$using:Last)
            }
        }
    }
}