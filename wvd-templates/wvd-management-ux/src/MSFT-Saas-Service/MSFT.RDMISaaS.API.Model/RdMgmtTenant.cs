#region "Import Namespaces"
using System;
using System.Collections.Generic;
using System.Text;
#endregion "Import Namespaces"

#region "MSFT.RDMISaaS.API.Model"
namespace MSFT.WVDSaaS.API.Model
{
    #region "Class - RdMgmtTenant"
    public class RdMgmtTenant
    {
        public string id { get; set; }
        public string tenantGroupName { get; set; }
        public string aadTenantId { get; set; }
        public string tenantName { get; set; }
        public string description { get; set; }
        public string friendlyName { get; set; }
        public string ssoAdfsAuthority { get; set; }
        public string ssoClientId { get; set; }
        public string ssoClientSecret { get; set; }
        public int noOfHostpool { get; set; }
        public int noOfActivehosts { get; set; }
        public int noOfAppgroups { get; set; }
        public int noOfUsers { get; set; }
        public int noOfSessions { get; set; }
        public string code { get; set; }
        public string refresh_token { get; set; }

        public string azureSubscriptionId { get; set; }


    }
    #endregion "Class - RdMgmtTenant"

    #region "Class - TenantResult"
    public class TenantResult
    {
        public bool isSuccess { get; set; }
        public string message { get; set; }
    }
    #endregion  "Class - TenantResult"

    #region "Class - TenantDataDTO"
    public class TenantDataDTO
    {
        public string id { get; set; }
        public string aadTenantId { get; set; }
        public string tenantGroupName { get; set; }
        public string tenantName { get; set; }
        public string description { get; set; }
        public string friendlyName { get; set; }
        public string ssoAdfsAuthority { get; set; }
        public string ssoClientId { get; set; }
        public string ssoClientSecret { get; set; }
        public string azureSubscriptionId { get; set; }
    }
    #endregion  "Class - TenantDataDTO"

    public class Tenants
    {
        public List<RdMgmtTenant> rdMgmtTenants { get; set; }
        public int count { get; set; }
        public string lastEntry { get; set; }
    }
}
#endregion "MSFT.RDMISaaS.API.Model"