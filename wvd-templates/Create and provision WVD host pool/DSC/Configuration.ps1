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