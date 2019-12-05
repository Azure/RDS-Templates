#region "Import Namespaces"
using System;
using System.Collections.Generic;
using System.Text;
#endregion "Import Namespaces"

#region "MSFT.RDMISaaS.API.Model"
namespace MSFT.WVDSaaS.API.Model
{
    #region "Class - RdMgmtHostPool"
    public class RdMgmtHostPool
    {
        // public string tenantGroupName { get; set; }
        // public string tenantName { get; set; }
        // public string hostPoolName { get; set; }
        // public string friendlyName { get; set; }
        // public string description { get; set; }
        //// public string persistent { get; set; }
        // public string diskPath { get; set; }
        // public Nullable<bool> enableUserProfileDisk { get; set; }
        // public string excludeFolderPath { get; set; }
        // public string excludeFilePath { get; set; }
        // public string includeFilePath { get; set; }
        // public string includeFolderPath { get; set; }
        // public string customRdpProperty { get; set; }
        // public int  maxSessionLimit { get; set; }
        // public string useReverseConnect { get; set; }
        // public bool persistent { get; set; }
        // public string autoAssignUser { get; set; }
        // public string grantAdministrativePrivilege { get; set; }
        // public int loadBalancerType { get; set; }
        // public string loadBalancerTypeName { get; set; }
        // public int noOfActivehosts { get; set; }
        // public int noOfAppgroups { get; set; }
        // public int noOfUsers { get; set; }
        // public int noOfSessions { get; set; }
        public string tenantName { get; set; }
        //public string name { get; set; }
        public string hostPoolName { get; set; }
        public string friendlyName { get; set; }
        public string description { get; set; }
        public string autoAssignUser { get; set; }
        public string grantAdministrativePrivilege { get; set; }
        public bool persistent { get; set; }
        public string diskPath { get; set; }
        public bool enableUserProfileDisk { get; set; }
        public string[] excludeFolderPath { get; set; }
        public string[] excludeFilePath { get; set; }
        public string[] includeFilePath { get; set; }
        public string[] includeFolderPath { get; set; }
        public string maxUserProfileDiskSizeGb { get; set; }
        public string activeSessionLimitMin { get; set; }
        public string authenticateUsingNla { get; set; }
        public string automaticReconnectionEnabled { get; set; }
        public string clientPrinterAsDefault { get; set; }
        public string clientPrinterRedirected { get; set; }
        public string customRdpProperty { get; set; }
        public string disconnectedSessionLimitMin { get; set; }
        public string idleSessionLimitMin { get; set; }
        public string maxRedirectedMonitors { get; set; }
        public string maxSessionLimit { get; set; }
        public string rdEasyPrintDriverEnabled { get; set; }
        public string temporaryFoldersDeletedOnExit { get; set; }
        public string useReverseConnect { get; set; }
        public string encryptionLevel { get; set; }
        public string brokerConnectionAction { get; set; }
        public string clientDeviceRedirectOptions { get; set; }
        public string securityLayer { get; set; }
        public string ResponseMsg { get; set; }
        public int cntOfHosts { get; set; }
        public int loadBalancerType { get; set; }
        public string loadBalancerTypeName { get; set; }
        public int noOfActivehosts { get; set; }
        public int noOfAppgroups { get; set; }
        public int noOfUsers { get; set; }
        public int noOfSessions { get; set; }

        public string tenantGroupName { get; set; }
        public string code { get; set; }
        public string refresh_token { get; set; }
    }
    #endregion  "Class - RdMgmtHostPool"


    #region "Class - HostPoolResult"
    public class HostPoolResult
    {
        public bool isSuccess { get; set; }
        public string message { get; set; }
    }
    #endregion  "Class - HostPoolResult"


    #region "Class - HostPoolDataDTO"
    public class HostPoolDataDTO
    {
        public int loadBalancerType;

        public string tenantGroupName { get; set; }
        public string aadHostPoolId { get; set; }
        public string hostpoolName { get; set; }
        public string tenantName { get; set; }
        public string friendlyName { get; set; }
        public string description { get; set; }
        public bool persistent { get; set; }
        public string autoAssignUser { get; set; }
        public string grantAdministrativePrivilege { get; set; }
        public int maxSessionLimit { get; set; }
        public string enableUserProfileDisk { get; set; }
        public string diskPath { get; set; }

        public string maxUserProfileDiskSizeGb { get; set; }
        public string excludeFolderPath { get; set; }
        public string excludeFilePath { get; set; }
        public string includeFilePath { get; set; }
        public string includeFolderPath { get; set; }
        public string customRdpProperty { get; set; }
        public string useReverseConnect { get; set; }



    }
    #endregion  "Class - RdMgmtHostPool"
}
#endregion "MSFT.RDMISaaS.API.Model"  
