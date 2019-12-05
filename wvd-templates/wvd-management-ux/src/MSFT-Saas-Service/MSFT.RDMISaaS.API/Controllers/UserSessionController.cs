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
using MSFT.WVDSaaS.API.Common;
using Newtonsoft.Json.Linq;
using Newtonsoft.Json;
#endregion "Import Namespaces"

#region "MSFT.WVDSaaS.API.Controllers"
namespace MSFT.WVDSaaS.API.Controllers
{
    [EnableCors(origins: "*", headers: "*", methods: "*")]

    #region "UserSessionController"
    public class UserSessionController : ApiController
    {
        #region "Class level declaration"
        UserSessionBL userSessionBL = new UserSessionBL();
        JObject usrSessionResult = new JObject();
        Common.Common common = new Common.Common();
        Common.Configurations configurations = new Common.Configurations();
        string deploymentUrl = "";
        string invalidToken = Constants.invalidToken.ToString().ToLower();
        string invalidCode = Constants.invalidCode.ToString().ToLower();
        #endregion

        #region "Functions/Methods"
        /// <summary>
        /// Description - get list of User sessions
        /// </summary>
        /// <param name="tenantName">name of tenant</param>
        /// <param name="hostPoolName">Name of Hostpool</param>
        /// <param name="refresh_token">Refresh Token to get access token</param>
        /// old parameters for pagination --   int pageSize, string sortField, bool isDescending = false, int initialSkip = 0, string lastEntry = null
        /// <returns></returns>
        public HttpResponseMessage GetListOfUserSessions(string tenantGroupName, string tenantName, string hostPoolName, string refresh_token,string hostName=null)
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
                       return userSessionBL.GetListOfUserSessioons(deploymentUrl, accessToken, tenantGroupName, tenantName, hostPoolName, hostName);
                      
                    }
                    else
                    {
                        return Request.CreateResponse(HttpStatusCode.OK, new JArray() { new JObject() { { "code", Constants.invalidToken } } });
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

        public IHttpActionResult LogOffUserSesion(JObject userSession)
        {
            //get deployment url
            deploymentUrl = configurations.rdBrokerUrl;
            try
            {
                if (userSession != null)
                {
                    if (!string.IsNullOrEmpty(userSession["refresh_token"].ToString()))
                    {
                        string accessToken = "";
                        //get token value
                        accessToken = common.GetTokenValue(userSession["refresh_token"].ToString());
                        if (!string.IsNullOrEmpty(accessToken) && accessToken.ToString().ToLower() != invalidToken && accessToken.ToString().ToLower() != invalidCode)
                        {
                            usrSessionResult = userSessionBL.LogOffUserSesion(deploymentUrl, accessToken, userSession);
                        }
                        else
                        {
                            usrSessionResult.Add("isSuccess", false);
                            usrSessionResult.Add("message", Constants.invalidToken);
                        }
                    }
                }
                else
                {
                    usrSessionResult.Add("isSuccess", false);
                    usrSessionResult.Add("message", Constants.invalidDataMessage);
                }
            }
            catch (Exception ex)
            {
                usrSessionResult.Add("isSuccess", false);
                usrSessionResult.Add("message", "Failed to log off  '" + userSession["adUserName"].ToString() + "'." + ex.Message.ToString() + " Please try it again later.");
            }
            return Ok(usrSessionResult);
        }

        public IHttpActionResult SendMessage(JObject userSession)
        {
            //get deployment url
            deploymentUrl = configurations.rdBrokerUrl;
            try
            {
                if (userSession != null)
                {
                    if (!string.IsNullOrEmpty(userSession["refresh_token"].ToString()))
                    {
                        string accessToken = "";
                        //get token value
                        accessToken = common.GetTokenValue(userSession["refresh_token"].ToString());
                        if (!string.IsNullOrEmpty(accessToken) && accessToken.ToString().ToLower() != invalidToken && accessToken.ToString().ToLower() != invalidCode)
                        {
                            usrSessionResult = userSessionBL.SendMessage(deploymentUrl, accessToken, userSession);
                        }
                        else
                        {
                            usrSessionResult.Add("isSuccess", false);
                            usrSessionResult.Add("message", Constants.invalidToken);
                        }
                    }
                }
                else
                {
                    usrSessionResult.Add("isSuccess", false);
                    usrSessionResult.Add("message", Constants.invalidDataMessage);
                }
            }
            catch (Exception ex)
            {
                usrSessionResult.Add("isSuccess", false);
                usrSessionResult.Add("message", "Failed to send message to '" + userSession["adUserName"].ToString() + "'." + ex.Message.ToString() + " Please try it again later.");
            }
            return Ok(usrSessionResult);
        }
        #endregion
    }
    #endregion
}
#endregion
