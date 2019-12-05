#region "Import Namespaces"
using MSFT.WVDSaaS.API.Model;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using MSFT.WVDSaaS.API.BLL;
using System.Web.Http.Cors;
using Newtonsoft.Json.Linq;
using System.Threading.Tasks;
#endregion "Import Namespaces"

#region "MSFT.WVDSaaS.API.Controllers"
namespace MSFT.WVDSaaS.API.Controllers
{
    [EnableCors(origins: "*", headers: "*", methods: "*")]

    #region "SessionHostController"
    public class SessionHostController : ApiController
    {
        #region "Class level Declaration"
        SessionHostBL sessionHostBL = new SessionHostBL();
        JObject hostResult = new JObject();
        Common.Common common = new Common.Common();
        Common.Configurations configurations = new Common.Configurations();
        string deploymentUrl = "";
        string invalidToken = Constants.invalidToken.ToString().ToLower();
        string invalidCode = Constants.invalidCode.ToString().ToLower();

        #endregion

        #region "Functions/Methods"
        /// <summary>
        /// Description: Gets all Rds SessionHosts associated with the Tenant and Host Pool specified in the Rds context.
        /// </summary>
        /// <param name="tenantName">Name of Tenant</param>
        /// <param name="hostPoolName">Name of Hostpool</param>
        /// <param name="refresh_token">Refresh token to get access token</param>
        /// //old parameters -- , int pageSize, string sortField, bool isDescending = false, int initialSkip = 0, string lastEntry = null
        /// <returns></returns>
        public async Task<HttpResponseMessage> GetSessionhostList(string tenantGroupName, string tenantName, string hostPoolName, string refresh_token, string subscriptionId=null)
        {
            //get deployment url
            deploymentUrl = configurations.rdBrokerUrl;
           string  azureDeployUrl = configurations.managementResourceUrl;
            try
            {
                if (!string.IsNullOrEmpty(refresh_token))
                {
                    string wvdAccessToken = "", AzureAccessToken="";
                    //get token value
                    wvdAccessToken = common.GetTokenValue(refresh_token);
                    AzureAccessToken = common.GetManagementTokenValue(refresh_token);
                    if (!string.IsNullOrEmpty(wvdAccessToken) && wvdAccessToken.ToString().ToLower() != invalidToken && wvdAccessToken.ToString().ToLower() != invalidCode)
                    {
                        return await sessionHostBL.GetSessionhostList(deploymentUrl, wvdAccessToken, tenantGroupName, tenantName, hostPoolName, azureDeployUrl, AzureAccessToken, subscriptionId);
                    }
                    else
                    {
                        return Request.CreateResponse(HttpStatusCode.OK, new JArray() { new JObject() { { "code", Constants.invalidToken } } });
                    }
                }
                else
                { return null; }
            }
            catch
            {
                return null;
            }
        }

        /// <summary>
        /// Description : Gets a Rds HostPool associated with the Tenant specified in the Rds context.
        /// </summary>
        /// <param name="tenantName">Name of Tenant</param>
        /// <param name="hostPoolName">Name of hostpool</param>
        /// <param name="sessionHostName">Name of Session Host</param>
        /// <param name="refresh_token">Refresh token to get access token</param>
        /// <returns></returns>
        public HttpResponseMessage GetSessionHostDetails(string tenantGroupName, string tenantName, string hostPoolName, string sessionHostName, string refresh_token)
        {
            //get deployment url
            deploymentUrl = configurations.rdBrokerUrl;
            try
            {
                if (!string.IsNullOrEmpty(refresh_token))
                {
                    string accessToken = "";
                    //get token value
                    accessToken = common.GetTokenValue(refresh_token);
                    if (!string.IsNullOrEmpty(accessToken) && accessToken.ToString().ToLower() != invalidToken && accessToken.ToString().ToLower() != invalidCode)
                    {
                        return sessionHostBL.GetSessionHostDetails(deploymentUrl, accessToken, tenantGroupName, tenantName, hostPoolName, sessionHostName);
                    }
                    else
                    {
                        return Request.CreateResponse(HttpStatusCode.OK, new JObject() { { "code", Constants.invalidToken } });
                    }
                }
                else
                {
                    return null;
                }
            }
            catch
            {
                return null;
            }
        }

        /// <summary>
        /// Description : Updates a Rds SessionHost associated with the Tenant and HostPool specified in the Rds context.
        /// </summary>
        /// <param name="rdMgmtSessionHost"> Session  Host class</param>
        /// <returns></returns>
        public IHttpActionResult Put(JObject rdMgmtSessionHost)
        {
            //get deployment url
            deploymentUrl = configurations.rdBrokerUrl;
            try
            {
                if (rdMgmtSessionHost != null)
                {
                    if (!string.IsNullOrEmpty(rdMgmtSessionHost["refresh_token"].ToString()))
                    {
                        string accessToken = "";
                        //get token value
                        accessToken = common.GetTokenValue(rdMgmtSessionHost["refresh_token"].ToString());
                        if (!string.IsNullOrEmpty(accessToken) && accessToken.ToString().ToLower() != invalidToken && accessToken.ToString().ToLower() != invalidCode)
                        {
                            hostResult = sessionHostBL.UpdateSessionHost(deploymentUrl, accessToken, rdMgmtSessionHost);
                        }
                        else
                        {
                            hostResult.Add("isSuccess", false);
                            hostResult.Add("message", Constants.invalidToken);
                        }
                    }
                }
                else
                {
                    hostResult.Add("isSuccess", false);
                    hostResult.Add("message", Constants.invalidDataMessage);
                }
            }
            catch (Exception ex)
            {
                hostResult.Add("isSuccess", false);
                hostResult.Add("message", "Host '" + rdMgmtSessionHost["sessionHostName"].ToString() + "' has not been updated." + ex.Message.ToString() + " Please try again later.");
            }
            return Ok(hostResult);
        }

        [HttpPost]
        public IHttpActionResult ChangeDrainMode(JObject rdMgmtSessionHost)
        {
            //get deployment url
            deploymentUrl = configurations.rdBrokerUrl;
            try
            {
                if (rdMgmtSessionHost != null)
                {
                    if (!string.IsNullOrEmpty(rdMgmtSessionHost["refresh_token"].ToString()))
                    {
                        string accessToken = "";
                        //get token value
                        accessToken = common.GetTokenValue(rdMgmtSessionHost["refresh_token"].ToString());
                        if (!string.IsNullOrEmpty(accessToken) && accessToken.ToString().ToLower() != invalidToken && accessToken.ToString().ToLower() != invalidCode)
                        {
                            hostResult = sessionHostBL.ChangeDrainMode(deploymentUrl, accessToken, rdMgmtSessionHost);
                        }
                        else
                        {
                            hostResult.Add("isSuccess", false);
                            hostResult.Add("message", Constants.invalidToken);
                        }
                    }
                }
                else
                {
                    hostResult.Add("isSuccess", false);
                    hostResult.Add("message", Constants.invalidDataMessage);
                }
            }
            catch (Exception ex)
            {
                hostResult.Add("isSuccess", false);
                hostResult.Add("message", "Host '" + rdMgmtSessionHost["sessionHostName"].ToString() + "' has not been updated." + ex.Message.ToString() + " Please try again later.");
            }
            return Ok(hostResult);
        }

        /// <summary>
        /// Description : Removes a Rds SessionHost associated with the Tenant and HostPool specified in the Rds context.
        /// </summary>
        /// <param name="tenantName">Name of Tenant</param>
        /// <param name="hostPoolName">Name of hostpool</param>
        /// <param name="sessionHostName">Name of Session Host</param>
        /// <param name="refresh_token">refresh token to get access token</param>
        /// <returns></returns>
        public IHttpActionResult DeleteSessionHost([FromUri] string tenantGroup, string tenantName, string hostPoolName, string sessionHostName, string refresh_token)
        {
            //get deployment url
            deploymentUrl = configurations.rdBrokerUrl;
            SessionHostResult sessionHostResult = new SessionHostResult();
            try
            {
                if (!string.IsNullOrEmpty(refresh_token))
                {
                    string accessToken = "";
                    //get token value
                    accessToken = common.GetTokenValue(refresh_token);
                    if (!string.IsNullOrEmpty(accessToken) && accessToken.ToString().ToLower() != invalidToken && accessToken.ToString().ToLower() != invalidCode)
                    {
                        sessionHostResult = sessionHostBL.DeletesessionHost(deploymentUrl, accessToken, tenantGroup, tenantName, hostPoolName, sessionHostName);
                    }
                    else
                    {
                        sessionHostResult.message = Constants.invalidToken;
                        sessionHostResult.isSuccess = false;
                    }
                }
            }
            catch (Exception ex)
            {
                sessionHostResult.message = "Session Host '" + sessionHostName + "' has not neen deleted." + ex.Message.ToString() + " Please try it later again.";
                sessionHostResult.isSuccess = false;
            }
            return Ok(sessionHostResult);
        }

        public IHttpActionResult RestartHost(string subscriptionId, string resourceGroupName, string sessionHostName, string refresh_token)
        {
            deploymentUrl = configurations.managementResourceUrl;// subscriptions/f657519e-2b49-48fe-85ec-3acff0ac67a6/resourceGroups/svTestRG/providers/Microsoft.Compute/virtualMachines/RDSH-7777-0/restart?api-version=2018-06-01
            try
            {
                string accessToken = common.GetManagementTokenValue(refresh_token);
                hostResult =  sessionHostBL.RestartHost(deploymentUrl, accessToken, subscriptionId, resourceGroupName, sessionHostName);
            }
            catch (Exception ex)
            {
                hostResult.Add("isSuccess", false);
                hostResult.Add("message", "Failed to restart host. "+ ex.Message);
            }
            return Ok(hostResult);

        }

        #endregion

    }
    #endregion

}
#endregion
