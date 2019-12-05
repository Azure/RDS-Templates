#region "Import Namespaces"
using System;
using System.Collections.Generic;
using System.Text;
#endregion "Import Namespaces"

#region "MSFT.RDMISaaS.API.Model"
namespace MSFT.WVDSaaS.API.Model
{
    #region "Class - RdMgmtRemoteApp"
    public class RdMgmtRemoteApp
    {
        public string tenantGroupName { get; set; }
        public string tenantName { get; set; }
        public string hostPoolName { get; set; }
        public string appGroupName { get; set; }
        public string remoteAppName { get; set; }
        public string filePath { get; set; }
        public string appAlias { get; set; }
        public string commandLineSetting { get; set; }
        public string description { get; set; }
        public string friendlyName { get; set; }
        public int iconIndex { get; set; }
        public string iconPath { get; set; }
        public string requiredCommandLine { get; set; }
        public bool showInWebFeed { get; set; }
        public string code { get; set; }
        public string refresh_token { get; set; }
    }
    #endregion  "Class - RdMgmtRemoteApp"

    #region "Class - RemoteAppResult"
    public class RemoteAppResult
    {
        public bool isSuccess { get; set; }
        public string message { get; set; }
    }
    #endregion  "Class - RdMgmtRemoteApp"

    #region "Class - RemoteAppDTO"
    public class RemoteAppDTO
    {
        public string tenantGroupName { get; set; }
        public string appGroupName { get; set; }
        public string tenantName { get; set; }
        public string hostPoolName { get; set; }
      //  public string AppName { get; set; }
      public string remoteAppName { get; set; }
        public string filePath { get; set; }
        public string commandLineSetting { get; set; }
        public string description { get; set; }
        public string friendlyName { get; set; }
        public int iconIndex { get; set; }
        public string iconPath { get; set; }
        public string requiredCommandLine { get; set; }
        public bool showInWebFeed { get; set; }
        public string appAlias { get; set; }

    }
    #endregion  "Class - RemoteAppDTO"

}
#endregion "MSFT.RDMISaaS.API.Model"  