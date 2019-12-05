#region "Import Namespaces"
using System;
using System.Collections.Generic;
using System.Text;
#endregion "Import Namespaces"

#region "MSFT.RDMISaaS.API.Model"
namespace MSFT.WVDSaaS.API.Model
{
    #region "Class - RdMgmtAppGroup"
    public class RdMgmtAppGroup
    {
        public string tenantGroupName { get; set; }
        public string tenantName { get; set; }
        public string hostPoolName { get; set; }
        public string appGroupName { get; set; }
        public string description { get; set; }
        public string friendlyName { get; set; }
        public string resourceType { get; set; }
        public int noOfApps { get; set; }
        public int noOfusers { get; set; }
        public string code { get; set; }
        public string refresh_token { get; set; }

    }
    #endregion  "Class - RdMgmtAppGroup"

    #region  "Class - AppGroupResult"
    public class AppGroupResult
    {
        public bool isSuccess { get; set; }
        public string message { get; set; }
    }
    #endregion  "Class - AppGroupResult"


    #region "Class - AppGroupDTO"
    public class AppGroupDTO
    {
        public string tenantGroupName { get; set; }

        public string tenantName { get; set; }
        public string hostPoolName { get; set; }
        public string appGroupName { get; set; }
        public string description { get; set; }
        public string friendlyName { get; set; }
        public int resourceType { get; set; }

    }
    #endregion  "Class - AppGroupDTO"
}
#endregion "MSFT.RDMISaaS.API.Model" 