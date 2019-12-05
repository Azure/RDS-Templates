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
#endregion "Import Namespaces"

#region "MSFT.WVDSaaS.API.Controllers"
namespace MSFT.WVDSaaS.API.Controllers
{
    [EnableCors(origins: "*", headers: "*", methods: "*")]

    #region "HostPoolController"
    public class HostPoolController : ApiController
    {
        #region "Class level declaration"
        HostPoolBL hostPoolBL = new HostPoolBL();
        JObject poolResult = new JObject();
        Common.Common common = new Common.Common();
        Common.Configurations configurations = new Common.Configurations();
        string deploymentUrl = "";
        string invalidToken = Constants.invalidToken.ToString().ToLower();
        string invalidCode = Constants.invalidCode.ToString().ToLower();
        #endregion

        #region "Functions/Methods"

        /// <summary>
        /// Description - Gets a Rds HostPool associated with the Tenant  specified in the Rds context.
        /// </summary>
        /// <param name="tenantName">Name of Tenant</param>
        /// <param name="hostPoolName">Name of Hostpool</param>
        /// <param name="refresh_token">Refresh token to get access token</param>
        /// <returns></returns>
        public HttpResponseMessage GetHostPoolDetails(string tenantGroupName, string tenantName, string hostPoolName, string refresh_token)
        {

            //get deployment url
            deploymentUrl = configurations.rdBrokerUrl;
            RdMgmtHostPool rdMgmtHostPool = new RdMgmtHostPool();
            try
            {
                if (!string.IsNullOrEmpty(refresh_token))
                {
                    string accessToken = "";
                    //get token value
                    accessToken = common.GetTokenValue(refresh_token);
                    if (!string.IsNullOrEmpty(accessToken) && accessToken.ToString().ToLower() != invalidToken && accessToken.ToString().ToLower() != invalidCode)
                    {
                        return hostPoolBL.GetHostPoolDetails(tenantGroupName, deploymentUrl, accessToken, tenantName, hostPoolName);
                    }
                    else
                    {
                        return Request.CreateResponse(HttpStatusCode.OK, new JObject()
                        {
                            {"code",  Constants.invalidToken}
                        });
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
        /// Description: Creates a new Rds HostPool within a Tenant specified in the Rds context. 
        /// </summary>
        /// <param name="rdMgmthostpool"> Hostpool Class </param>
        /// <returns></returns>
        public IHttpActionResult Post([FromBody] JObject rdMgmthostpool)
        {
            //get deployment url
            deploymentUrl = configurations.rdBrokerUrl;
            try
            {
                if (rdMgmthostpool != null)
                {
                    if (!string.IsNullOrEmpty(rdMgmthostpool["refresh_token"].ToString()))
                    {
                        string accessToken = "";
                        //get token value
                        accessToken = common.GetTokenValue(rdMgmthostpool["refresh_token"].ToString());
                        if (!string.IsNullOrEmpty(accessToken) && accessToken.ToString().ToLower() != invalidToken && accessToken.ToString().ToLower() != invalidCode)
                        {
                            poolResult = hostPoolBL.CreateHostPool(deploymentUrl, accessToken, rdMgmthostpool);
                        }
                        else
                        {
                            poolResult.Add("isSuccess", false);
                            poolResult.Add("message", Constants.invalidToken);
                        }
                    }
                }
                else
                {
                    poolResult.Add("isSuccess", false);
                    poolResult.Add("message", Constants.invalidDataMessage);
                }
            }
            catch (Exception ex)
            {
                poolResult.Add("isSuccess", false);
                poolResult.Add("message", "Hostpool '" + rdMgmthostpool["hostPoolName"] + "' has not been created." + ex.Message.ToString() + "Please try again later.");
            }
            return Ok(poolResult);
        }

        /// <summary>
        /// Description: Removes a Rds HostPool associated with the Tenant specified in the Rds context.
        /// </summary>
        /// <param name="tenantName">Name of Tenant</param>
        /// <param name="hostPoolName">Name of hostpool</param>
        /// <param name="refresh_token">Refresh token to get access token</param>
        /// <returns></returns>
        public IHttpActionResult Delete([FromUri] string tenantGroupName, string tenantName, string hostPoolName, string refresh_token)
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
                        poolResult = hostPoolBL.DeleteHostPool(tenantGroupName, deploymentUrl, accessToken, tenantName, hostPoolName);
                    }
                    else
                    {
                        poolResult.Add("isSuccess", false);
                        poolResult.Add("message", Constants.invalidToken);
                    }
                }
                else
                {
                    poolResult.Add("isSuccess", false);
                    poolResult.Add("message", Constants.invalidDataMessage);
                }
            }
            catch (Exception ex)
            {
                poolResult.Add("isSuccess", false);
                poolResult.Add("message", "Hostpool '" + hostPoolName + "' has not been deleted." + ex.Message.ToString() + " Please try again later.");
            }
            return Ok(poolResult);
        }

        /// <summary>
        /// Description : Gets a list of Rds HostPools associated with the Tenant specified in the Rds context.
        /// </summary>
        /// <param name="tenantName">Name of Tenant</param>
        /// <param name="refresh_token">Refresh token to get access token</param>
        /// // old parameters for pagination -  int pageSize, string sortField, bool isDescending = false, int initialSkip = 0, string lastEntry = null
        /// <returns></returns>
        public HttpResponseMessage GetHostPoolList(string tenantGroupName, string tenantName, string refresh_token)
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
                        return hostPoolBL.GetHostPoolList(tenantGroupName, deploymentUrl, accessToken, tenantName);
                    }
                    else
                    {
                        return Request.CreateResponse(HttpStatusCode.OK, new JArray()
                        {
                           new JObject() {"code",  Constants.invalidToken}
                        });
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
        /// Description : Updates a Rds HostPools associated with the Tenant specified in the Rds context.
        /// </summary>
        /// <param name="rdMgmthostpool">Hostpool class </param>
        /// <returns></returns>
        public IHttpActionResult Put([FromBody] JObject rdMgmthostpool)
        {
            //get deployment url
            deploymentUrl = configurations.rdBrokerUrl;
            try
            {
                if (rdMgmthostpool != null)
                {
                    if (!string.IsNullOrEmpty(rdMgmthostpool["refresh_token"].ToString()))
                    {
                        string token = "";
                        //get token value
                        token = common.GetTokenValue(rdMgmthostpool["refresh_token"].ToString());
                        if (!string.IsNullOrEmpty(token) && token.ToString().ToLower() != invalidToken && token.ToString().ToLower() != invalidCode)
                        {
                            poolResult = hostPoolBL.UpdateHostPool(deploymentUrl, token, rdMgmthostpool);
                        }
                        else
                        {
                            poolResult.Add("isSuccess", false);
                            poolResult.Add("message", Constants.invalidToken);
                        }
                    }
                    else
                    {
                        poolResult.Add("isSuccess", false);
                        poolResult.Add("message", Constants.invalidDataMessage);
                    }
                }
                else
                {
                    poolResult.Add("isSuccess", false);
                    poolResult.Add("message", Constants.invalidDataMessage);
                }

            }
            catch (Exception ex)
            {
                poolResult.Add("isSuccess", false);
                poolResult.Add("message", "Hostpool '" + rdMgmthostpool["hostPoolName"].ToString() + "' has not been updated." + ex.Message.ToString() + " Please try again later.");
            }
            return Ok(poolResult);
        }
        #endregion

    }
    #endregion

}
#endregion
