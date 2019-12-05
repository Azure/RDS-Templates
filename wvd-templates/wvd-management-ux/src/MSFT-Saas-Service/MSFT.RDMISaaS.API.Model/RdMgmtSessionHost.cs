#region "Import Namespaces"
using System;
using System.Collections.Generic;
using System.Text;
#endregion "Import Namespaces"

#region "MSFT.RDMISaaS.API.Model"
namespace MSFT.WVDSaaS.API.Model
{
    #region "Class - RdMgmtSessionHost"
    public class RdMgmtSessionHost
    {
        public string tenantGroupName { get; set; }

        public string sessionHostName { get; set; }
        public string tenantName { get; set; }
        public string hostPoolName { get; set; }
        public bool allowNewSession { get; set; }
        public int sessions { get; set; }
        public DateTime lastHeartBeat { get; set; }
        public string agentVersion { get; set; }
        public string code { get; set; }
        public string refresh_token { get; set; }
    }
    #endregion  "Class - RdMgmtSessionHost"

    #region "Class - SessionHostResult"
    public class SessionHostResult
    {
        public bool isSuccess { get; set; }
        public string message { get; set; }
    }
    #endregion  "Class - SessionHostResult"

    #region "Class - SessionHostDTO"
    public class SessionHostDTO
    {
        public string tenantGroupName { get; set; }

        public string sessionHostName { get; set; }
        public string tenantName { get; set; }
        public string hostPoolName { get; set; }
        public bool allowNewSession { get; set; }
        public int sessions { get; set; }
        public string lastHeartBeat { get; set; }
        public string agentVersion { get; set; }
    }
    #endregion  "Class - SessionHostDTO"

}
#endregion "MSFT.RDMISaaS.API.Model"  