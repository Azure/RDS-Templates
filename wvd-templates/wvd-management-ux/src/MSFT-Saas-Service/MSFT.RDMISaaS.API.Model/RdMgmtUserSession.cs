#region "Import Namespaces"
using System;
using System.Collections.Generic;
using System.Text;
#endregion "Import Namespaces"

#region "MSFT.RDMISaaS.API.Model"
namespace MSFT.WVDSaaS.API.Model
{
    #region "Class - RdMgmtUserSession"
    public class RdMgmtUserSession
    {
        public string tenantGroupName { get; set; }
        public string tenantName { get; set; }
        public string hostPoolName { get; set; }
        public string sessionHostName { get; set; }
        public string userPrincipalName { get; set; }
        public int sessionId { get; set; }
        public string applicationType { get; set; }
        public string code { get; set; }
        public string refresh_token { get; set; }
    }

    #endregion  "Class - RdMgmtUserSession"

    #region "Class - UserSessionResult"
    public class UserSessionResult
    {
        public bool isSuccess { get; set; }
        public string message { get; set; }
    }
    #endregion  "Class - UserSessionResult"

}
#endregion "MSFT.RDMISaaS.API.Model"  