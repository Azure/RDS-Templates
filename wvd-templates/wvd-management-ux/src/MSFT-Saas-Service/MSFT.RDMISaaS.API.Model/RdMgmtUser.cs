#region "Import Namespaces"
using System;
using System.Collections.Generic;
using System.Text;
#endregion "Import Namespaces"

#region "MSFT.RDMISaaS.API.Model"
namespace MSFT.WVDSaaS.API.Model
{
    #region "Class - RdMgmtUser"
    public class RdMgmtUser
    {
        public string userPrincipalName { get; set; }
        public string tenantName { get; set; }
        public string tenantGroupName { get; set; }
        public string hostPoolName { get; set; }
        public string appGroupName { get; set; }
        public string appGroupUser { get; set; }
        public string code { get; set; }
        public string refresh_token { get; set; }

    }
    #endregion  "Class - RdMgmtUser"

    #region "Class - UserResult"
    public class UserResult
    {
        public bool isSuccess { get; set; }
        public string message { get; set; }
    }
    #endregion  "Class - UserResult"

    #region "Class - AppGroupUserDTO"
    public class AppGroupUserDTO
    {
        public string tenantName { get; set; }
        public string hostPoolName { get; set; }
        public string appGroupName { get; set; }
        public string appGroupUser { get; set; }
        public string userPrincipalName { get; set; }
        public string tenantGroupName { get; set; }
    }
    #endregion  "Class - AppGroupUserDTO"
}
#endregion "MSFT.RDMISaaS.API.Model"