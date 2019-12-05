#region "Import Namespaces"
using System;
using System.Collections.Generic;
using System.Text;
#endregion "Import Namespaces"

#region "MSFT.RDMISaaS.API.Model"
namespace MSFT.WVDSaaS.API.Model
{
    #region "Class - RdMgmtPublishedDesktop"
    public class RdMgmtPublishedDesktop
    {
        public string tenantName { get; set; }
        public string hostPoolName { get; set; }
        public string appGroupName { get; set; }
        public string remoteDesktopName { get; set; }
        public string friendlyName { get; set; }
        public string description { get; set; }
        public string showInWebFeed { get; set; }
    }
    #endregion  "Class - RdMgmtPublishedDesktop"
}
#endregion "MSFT.RDMISaaS.API.Model"  
