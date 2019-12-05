#region "Import Namespaces"
using System;
using System.Collections.Generic;
using System.Text;
#endregion "Import Namespaces"

#region "MSFT.RDMISaaS.API.Model"
namespace MSFT.WVDSaaS.API.Model
{
    #region "Class - RdMgmtRegistrationInfo"
    public class RdMgmtRegistrationInfo
    {
        public string token { get; set; }
        public DateTime expirationUtc { get; set; }
        // public string tenantGroupName { get; set; }
        public string tenantName { get; set; }
        public string tenantGroupName { get; set; }
        public string hostPoolName { get; set; }
        public string code { get; set; }
        public string refresh_token { get; set; }
        public DateTime expirationTime { get; set; }
    }
    #endregion  "Class - RdMgmtRegistrationInfo"

    #region "Class - RegistrationInfoResult"
    public class RegistrationInfoResult
    {
        public bool isSuccess { get; set; }
        public string message { get; set; }
    }
    #endregion  "Class - RegistrationInfoResult"


    #region "Class - RegistrationInfoDTO"
    public class RegistrationInfoDTO
    {
       // public string token { get; set; }
        public DateTime expirationTime { get; set; }
        // public string tenantGroupName { get; set; }
        public string tenantName { get; set; }
        public string hostPoolName { get; set; }
        public string tenantGroupName { get; set; }
    }
    #endregion  "Class - RegistrationInfoDTO"
}
#endregion "MSFT.RDMISaaS.API.Model"  