configuration DomainJoin 
{ 
   param 
    ( 
        [Int]$RetryCount=200,
        [Int]$RetryIntervalSec=30
    ) 
    
    Import-DscResource -ModuleName xNetworking

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

        WindowsFeature ADPowershell
        {
            Name = "RSAT-AD-PowerShell"
            Ensure = "Present"
        } 

        Registry RdmsEnableUILog
        {
            Ensure = "Present"
            Key = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDMS"
            ValueName = "EnableUILog"
            ValueType = "Dword"
            ValueData = "1"
        }

        Registry EnableDeploymentUILog
        {
            Ensure = "Present"
            Key = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDMS"
            ValueName = "EnableDeploymentUILog"
            ValueType = "Dword"
            ValueData = "1"
        }

        Registry EnableTraceLog
        {
            Ensure = "Present"
            Key = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDMS"
            ValueName = "EnableTraceLog"
            ValueType = "Dword"
            ValueData = "1"
        }

        Registry EnableTraceToFile
        {
            Ensure = "Present"
            Key = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDMS"
            ValueName = "EnableTraceToFile"
            ValueType = "Dword"
            ValueData = "1"
        }
   }
}


configuration SessionHost
{
    Import-DscResource -ModuleName xNetworking
    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
            ConfigurationMode = "ApplyOnly"
        }

        xFirewall FirewallRuleForGWRDSH
        {
            Direction = "Inbound"
            Name = "Firewall-GW-RDSH-TCP-In"
            DisplayName = "Firewall-GW-RDSH-TCP-In"
            Description = "Inbound rule for CB to allow TCP traffic for configuring GW and RDSH machines during deployment."
            DisplayGroup = "Connection Broker"
            State = "Enabled"
            Access = "Allow"
            Protocol = "TCP"
            LocalPort = "5985"
            Ensure = "Present"
        }

        WindowsFeature RDS-RD-Server
        {
            Ensure = "Present"
            Name = "RDS-RD-Server"
        }
    }
}