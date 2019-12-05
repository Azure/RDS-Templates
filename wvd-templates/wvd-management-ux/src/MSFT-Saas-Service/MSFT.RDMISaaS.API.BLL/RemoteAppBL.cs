#region "Import Namespaces"
using MSFT.WVDSaaS.API.Model;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Text;
#endregion "Import Namespaces"

#region "MSFT.RDMISaaS.API.BLL"
namespace MSFT.WVDSaaS.API.BLL
{
    #region "RemoteAppBL"
    public class RemoteAppBL
    {
        JObject appResult = new JObject();

        #region "Functions/Methods"
        /// <summary>
        /// Description - Gets a RemoteApp within a  Tenant, HostPool and AppGroup associated with the specified Rds context.
        /// </summary>
        /// <param name="deploymentUrl">RD Broker Url</param>
        /// <param name="accessToken">Access token</param>
        /// <param name="tenantName">Name of Tenant</param>
        /// <param name="hostPoolName">Name of Hostpool</param>
        /// <param name="appGroupName">Name of App Group</param>
        /// <param name="remoteAppName">Name of Remote App</param>
        /// <returns></returns>
        public HttpResponseMessage GetRemoteAppDetails(string tenantGroupName, string deploymentUrl, string accessToken, string tenantName, string hostPoolName, string appGroupName, string remoteAppName)
        {
            try
            {
                //call rest api to get all app groups -- july code bit
                HttpResponseMessage response = CommonBL.InitializeHttpClient(deploymentUrl, accessToken).GetAsync("/RdsManagement/V1/TenantGroups/" + tenantGroupName + "/Tenants/" + tenantName + "/HostPools/" + hostPoolName + "/AppGroups/" + appGroupName + "/RemoteApps/" + remoteAppName).Result;
                return response;
                
            }
            catch
            {
                return null;
            }
        }

        /// <summary>
        /// Description - Create a RemoteApp within a  Tenant, HostPool and AppGroup associated with the specified Rds context.
        /// </summary>
        /// <param name="deploymentUrl">RD Broker Url</param>
        /// <param name="accessToken">Access Token</param>
        /// <param name="rdMgmtRemoteApp">Remote App class</param>
        /// <returns></returns>
        public JObject CreateRemoteApp(string deploymentUrl, string accessToken, JObject rdMgmtRemoteApp)
        {
            try
            {
               
                //call rest api to publish remote appgroup app 
                var content = new StringContent(JsonConvert.SerializeObject(rdMgmtRemoteApp), Encoding.UTF8, "application/json");
                HttpResponseMessage response = CommonBL.InitializeHttpClient(deploymentUrl, accessToken).PostAsync("/RdsManagement/V1/TenantGroups/" + rdMgmtRemoteApp["tenantGroupName"].ToString() + "/Tenants/" + rdMgmtRemoteApp["tenantName"].ToString() + "/HostPools/" + rdMgmtRemoteApp["hostPoolName"].ToString() + "/AppGroups/" + rdMgmtRemoteApp["appGroupName"].ToString() + "/RemoteApps/" + rdMgmtRemoteApp["remoteAppName"].ToString(), content).Result;
                string strJson = response.Content.ReadAsStringAsync().Result;
                if (response.IsSuccessStatusCode)
                {
                    if (response.StatusCode == HttpStatusCode.OK || response.StatusCode == HttpStatusCode.Created)
                    {
                        appResult.Add("isSuccess" , true);
                        appResult.Add("message" , "Remote app '" + rdMgmtRemoteApp["remoteAppName"].ToString() + "' has been published successfully.");
                    }
                }
                else if ((int)response.StatusCode == 429)
                {
                    appResult.Add("isSuccess", false);
                    appResult.Add("message" , strJson + " Please try again later.");
                }
                else
                {
                    if (!string.IsNullOrEmpty(strJson))
                    {
                        appResult.Add("isSuccess", false);
                        appResult.Add("message", CommonBL.GetErrorMessage(strJson));
                    }
                    else
                    {
                        appResult.Add("isSuccess", false);
                        appResult.Add("message", "Remote app '" + rdMgmtRemoteApp["remoteAppName"].ToString() + "' has not been published. Please try it later again.");
                    }
                }
            }
            catch (Exception ex)
            {
                appResult.Add("isSuccess", false);
                appResult.Add("message", "Remote app '" + rdMgmtRemoteApp["remoteAppName"].ToString() + "' has not been published." + ex.Message.ToString() + " Please try it later again.");
            }
            return appResult;
        }

        public JObject EditRemoteApp(string deploymentUrl, string accessToken, JObject rdMgmtRemoteApp)
        {
            try
            {

                //call rest api to publish remote appgroup app 
                var content = new StringContent(JsonConvert.SerializeObject(rdMgmtRemoteApp), Encoding.UTF8, "application/json");
                HttpResponseMessage response = CommonBL.PatchAsync(deploymentUrl, accessToken,"/RdsManagement/V1/TenantGroups/" + rdMgmtRemoteApp["tenantGroupName"].ToString() + "/Tenants/" + rdMgmtRemoteApp["tenantName"].ToString() + "/HostPools/" + rdMgmtRemoteApp["hostPoolName"].ToString() + "/AppGroups/" + rdMgmtRemoteApp["appGroupName"].ToString() + "/RemoteApps/" + rdMgmtRemoteApp["remoteAppName"].ToString(), content).Result;
                string strJson = response.Content.ReadAsStringAsync().Result;
                if (response.IsSuccessStatusCode)
                {
                    if (response.StatusCode == HttpStatusCode.OK)
                    {
                        appResult.Add("isSuccess", true);
                        appResult.Add("message", "Remote app '" + rdMgmtRemoteApp["remoteAppName"].ToString() + "' has been updated successfully.");
                    }
                }
                else if ((int)response.StatusCode == 429)
                {
                    appResult.Add("isSuccess", false);
                    appResult.Add("message", strJson + " Please try again later.");
                }
                else
                {
                    if (!string.IsNullOrEmpty(strJson))
                    {
                        appResult.Add("isSuccess", false);
                        appResult.Add("message", CommonBL.GetErrorMessage(strJson));
                    }
                    else
                    {
                        appResult.Add("isSuccess", false);
                        appResult.Add("message", "Remote app '" + rdMgmtRemoteApp["remoteAppName"].ToString() + "' has not been updated. Please try it later again.");
                    }
                }
            }
            catch (Exception ex)
            {
                appResult.Add("isSuccess", false);
                appResult.Add("message", "Remote app '" + rdMgmtRemoteApp["remoteAppName"].ToString() + "' has not been updated." + ex.Message.ToString() + " Please try it later again.");
            }
            return appResult;
        }


        /// <summary>
        /// Description - Gets a list of RemoteApps within a TenantGroup, Tenant, HostPool and AppGroup associated with the specified Rds context.
        /// </summary>
        /// <param name="deploymentUrl">RD Broker url</param>
        /// <param name="accessToken">Access Token</param>
        /// <param name="tenantName">Name of Tenant</param>
        /// <param name="hostPoolName">Name of Hostpool</param>
        /// <param name="appGroupName">Name of App Group</param>
        /// <param name="remoteAppName">Name of Remote App</param>
        /// <param name="isRemoteAppNameOnly">To get Remote app Name only</param>
        /// //old parameters --  bool isRemoteAppNameOnly,bool isAll, int pageSize, string sortField, bool isDescending, int initialSkip, string lastEntry
        /// <returns></returns>
        public HttpResponseMessage GetRemoteAppList(string tenantGroupName, string deploymentUrl, string accessToken, string tenantName, string hostPoolName, string appGroupName)
        {
            try
            {
                HttpResponseMessage response = CommonBL.InitializeHttpClient(deploymentUrl, accessToken).GetAsync("/RdsManagement/V1/TenantGroups/" + tenantGroupName + "/Tenants/" + tenantName + "/HostPools/" + hostPoolName + "/AppGroups/" + appGroupName + "/RemoteApps").Result;
                return response;

                //api call included pagination 
                // response = CommonBL.InitializeHttpClient(deploymentUrl, accessToken).GetAsync("/RdsManagement/V1/TenantGroups/" + tenantGroupName + "/Tenants/" + tenantName + "/HostPools/" + hostPoolName + "/AppGroups/" + appGroupName + "/RemoteApps?PageSize=" + pageSize + "&LastEntry=" + lastEntry + "&SortField=" + sortField + "&IsDescending=" + isDescending + "&InitialSkip=" + initialSkip).Result;
            }
            catch
            {
                return null;
            }
        }
        /// <summary>
        /// Description : Remove remote app from associated app group
        /// </summary>
        /// <param name="deploymentUrl"></param>
        /// <param name="accessToken"></param>
        /// <param name="tenantName"></param>
        /// <param name="hostPoolName"></param>
        /// <param name="appGroupName"></param>
        /// <param name="remoteAppName"></param>
        /// <returns></returns>
        public JObject DeleteRemoteApp(string tenantGroupName, string deploymentUrl, string accessToken, string tenantName, string hostPoolName, string appGroupName, string remoteAppName)
        {
            try
            {

                //call rest api to remove remote app -- july code bit
                HttpResponseMessage response = CommonBL.InitializeHttpClient(deploymentUrl, accessToken).DeleteAsync("/RdsManagement/V1/TenantGroups/" + tenantGroupName + "/Tenants/" + tenantName + "/HostPools/" + hostPoolName + "/AppGroups/" + appGroupName + "/RemoteApps/" + remoteAppName).Result;
                string strJson = response.Content.ReadAsStringAsync().Result;
                if (response.IsSuccessStatusCode)
                {
                    appResult.Add("isSuccess" , true);
                    appResult.Add("message" , "Remote app '" + remoteAppName + "' has been removed from app group '" + appGroupName + "' successfully.");
                }
                else if ((int)response.StatusCode == 429)
                {
                    appResult.Add("isSuccess" , false);
                    appResult.Add("message" , strJson + " Please try again later.");
                }
                else
                {
                    if (!string.IsNullOrEmpty(strJson))
                    {
                        appResult.Add("isSuccess" , false);
                        appResult.Add("message" , CommonBL.GetErrorMessage(strJson));
                    }
                    else
                    {
                        appResult.Add("isSuccess" , false);
                        appResult.Add("message" , "Remote app '" + remoteAppName + "' has not been removed from app group '" + appGroupName + "'. Please try again later.");
                    }
                }
            }
            catch (Exception ex)
            {
                appResult.Add("isSuccess" , false);
                appResult.Add("message" , "Remote app '" + remoteAppName + "' has not been removed from app group '" + appGroupName + "'." + ex.Message.ToString() + " Please try again later.");
            }
            return appResult;
        }
        #endregion

    }
    #endregion

}
#endregion

