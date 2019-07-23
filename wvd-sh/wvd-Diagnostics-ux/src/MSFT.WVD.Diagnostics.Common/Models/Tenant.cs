using System;
using System.Collections.Generic;
using System.Text;

namespace MSFT.WVD.Diagnostics.Common.Models
{
    public class Tenant
    {
        public string tenantGroupName { get; set; }
        public string aadTenantId { get; set; }
        public string tenantName { get; set; }
        public string description { get; set; }
        public string friendlyName { get; set; }
        public string ssoAdfsAuthority { get; set; }
        public string ssoClientId { get; set; }
        public string ssoClientSecret { get; set; }
        public string azureSubscriptionId { get; set; }
        public string logAnalyticsWorkspaceId { get; set; }
        public string logAnalyticsPrimaryKey { get; set; }
    }
}
