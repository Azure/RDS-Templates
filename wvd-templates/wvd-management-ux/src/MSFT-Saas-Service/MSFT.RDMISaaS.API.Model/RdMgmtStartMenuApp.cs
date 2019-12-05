#region "Import Namespaces"
using System;
using System.Collections.Generic;
using System.Text;
#endregion "Import Namespaces"

#region "MSFT.RDMISaaS.API.Model"
namespace MSFT.WVDSaaS.API.Model
{
    #region "Class - RdMgmtStartMenuApp"
    public class RdMgmtStartMenuApp
    {
        public string tenantName { get; set; }
        public string hostPoolName { get; set; }
        public string appGroupName { get; set; }
        public string appAlias { get; set; }
        public string friendlyName { get; set; }
        public string filePath { get; set; }
        public string commandLineArguments { get; set; }
        public string iconPath { get; set; }
        public int iconIndex { get; set; }
        public string code { get; set; }
    }
    #endregion  "Class - RdMgmtStartMenuApp"
}
#endregion "MSFT.RDMISaaS.API.Model"