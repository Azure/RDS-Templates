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
#endregion "Import Namespaces"

#region "MSFT.WVDSaaS.API.Controllers"
namespace MSFT.WVDSaaS.API.Controllers
{
    [EnableCors(origins: "*", headers: "*", methods: "*")]
    #region "TenantController"
    public class TenantController : ApiController
    {
        #region "Class level Declaration"
        TenantBL tenantBL = new TenantBL();
        JObject tenantResult = new JObject();
        Common.Common common = new Common.Common();
        Common.Configurations configurations = new Common.Configurations();
        string deploymentUrl = "";
        string invalidToken = Constants.invalidToken.ToString().ToLower();
        string invalidCode = Constants.invalidCode.ToString().ToLower();
        #endregion

        /// <summary>
        /// Description - Gets a specific Rds tenant
        /// </summary>
        /// <param name="tenantName">Name of tenant</param>
        /// <param name="refresh_token">Refresh token to get access token</param>
        /// <returns></returns>
        public HttpResponseMessage GetTenantDetails(string tenantGroupName, string tenantName, string refresh_token)
        {
            //get deployment url
            deploymentUrl = configurations.rdBrokerUrl;
            RdMgmtTenant rdMgmtTenant = new RdMgmtTenant();
            try
            {
                if (!string.IsNullOrEmpty(refresh_token))
                {
                    string accessToken = "";
                    //get token value
                    accessToken = common.GetTokenValue(refresh_token);
                    if (!string.IsNullOrEmpty(accessToken) && accessToken.ToString().ToLower() != invalidToken && accessToken.ToString().ToLower() != invalidCode)
                    {
                        return tenantBL.GetTenantDetails(tenantGroupName, deploymentUrl, accessToken, tenantName);
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
        /// Description - Gets a list of Rds tenants.
        /// </summary>
        /// <param name="refresh_token">effsh token to get access token</param>
        /// //old parameters for pagination -  int pageSize, string sortField, bool isDescending = false, int initialSkip = 0, string lastEntry = ""
        /// <returns></returns>
        public HttpResponseMessage GetTenantList(string tenantGroupName, string refresh_token)
        {
            //get deployment url
            deploymentUrl = configurations.rdBrokerUrl;
            Tenants tenants = new Tenants();
            try
            {
                if (!string.IsNullOrEmpty(refresh_token))
                {
                    string accessToken = "";
                    //get token value
                    accessToken = common.GetTokenValue(refresh_token);
                    if (!string.IsNullOrEmpty(accessToken) && accessToken.ToString().ToLower() != invalidToken && accessToken.ToString().ToLower() != invalidCode)
                    {
                        return tenantBL.GetTenantList(tenantGroupName, deploymentUrl, accessToken);
                    }
                    else
                    {
                        return Request.CreateResponse(HttpStatusCode.OK, new JArray() {
                            new JObject()
                            {
                                {"code", Constants.invalidToken }
                            }
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
            //return tenants;
        }

        /// <summary>
        /// Description : Creates a new Rds Tenant in the Rds context.
        /// </summary>
        /// <param name="rdMgmtTenant">Tenant class</param>
        /// <returns></returns>
        public IHttpActionResult Post([FromBody] JObject rdMgmtTenant)
        {
            //get deployment url
            deploymentUrl = configurations.rdBrokerUrl;
            try
            {
                if (rdMgmtTenant != null)
                {
                    if (!string.IsNullOrEmpty(rdMgmtTenant["refresh_token"].ToString()))
                    {
                        string accessToken = "";
                        //get token value
                        accessToken = common.GetTokenValue(rdMgmtTenant["refresh_token"].ToString());
                        if (!string.IsNullOrEmpty(accessToken) && accessToken.ToString().ToLower() != invalidToken && accessToken.ToString().ToLower() != invalidCode)
                        {
                            tenantResult = tenantBL.CreateTenant(deploymentUrl, accessToken, rdMgmtTenant);
                        }
                        else
                        {
                            tenantResult.Add("isSuccess", false);
                            tenantResult.Add("message", Constants.invalidToken);
                        }
                    }



                }
                else
                {
                    tenantResult.Add("isSuccess", false);
                    tenantResult.Add("message", Constants.invalidDataMessage);
                }

            }
            catch (Exception ex)
            {
                tenantResult.Add("isSuccess", false);
                tenantResult.Add("message", "Tenant '" + rdMgmtTenant["tenantName"] + "' has not been created." + ex.Message.ToString() + " Please try again later.");
            }
            return Ok(tenantResult);
        }

        /// <summary>
        /// Description : Updates properties for an existing Rds tenant
        /// </summary>
        /// <param name="rdMgmtTenant"></param>
        /// <returns></returns>
        public IHttpActionResult Put([FromBody] JObject rdMgmtTenant)
        {
            //get deployment url
            deploymentUrl = configurations.rdBrokerUrl;
            try
            {
                if (rdMgmtTenant != null)
                {
                    if (!string.IsNullOrEmpty(rdMgmtTenant["refresh_token"].ToString()) && !string.IsNullOrEmpty(rdMgmtTenant["tenantName"].ToString()))
                    {
                        string accessToken = "";
                        //get token value
                        accessToken = common.GetTokenValue(rdMgmtTenant["refresh_token"].ToString());
                        if (!string.IsNullOrEmpty(accessToken) && accessToken.ToString().ToLower() != invalidToken && accessToken.ToString().ToLower() != invalidCode)
                        {
                            tenantResult = tenantBL.UpdateTenant(deploymentUrl, accessToken, rdMgmtTenant);
                        }
                        else
                        {
                            tenantResult.Add("isSuccess", false);
                            tenantResult.Add("message", Constants.invalidToken);
                        }
                    }
                    else
                    {
                        tenantResult.Add("isSuccess", false);
                        tenantResult.Add("message", Constants.invalidDataMessage);
                    }
                }
                else
                {
                    tenantResult.Add("isSuccess", false);
                    tenantResult.Add("message", Constants.invalidDataMessage);
                }

            }
            catch (Exception ex)
            {
                tenantResult.Add("isSuccess", false);
                tenantResult.Add("message", "Tenant '" + rdMgmtTenant["tenantName"] + "' has not been updated." + ex.Message.ToString() + "Please try again later.");
            }
            return Ok(tenantResult);
        }

        /// <summary>
        /// Description : Deletes a specific Rds tenant.
        /// </summary>
        /// <param name="tenantName"></param>
        /// <param name="refresh_token">Refrsh token to get access token</param>
        /// <returns></returns>
        public IHttpActionResult Delete([FromUri] string tenantGroupName, string tenantName, string refresh_token)
        {
            //get deployment url
            deploymentUrl = configurations.rdBrokerUrl;
            try
            {
                if (!string.IsNullOrEmpty(refresh_token) && !string.IsNullOrEmpty(tenantName))
                {
                    string accessToken = "";
                    //get token value
                    accessToken = common.GetTokenValue(refresh_token);
                    if (!string.IsNullOrEmpty(accessToken) && accessToken.ToString().ToLower() != invalidToken && accessToken.ToString().ToLower() != invalidCode)
                    {
                        tenantResult = tenantBL.DeleteTenant(tenantGroupName, deploymentUrl, accessToken, tenantName);
                    }
                    else
                    {
                        tenantResult.Add("isSuccess", false);
                        tenantResult.Add("message", Constants.invalidToken);
                    }
                }
                else
                {
                    tenantResult.Add("isSuccess", false);
                    tenantResult.Add("message", Constants.invalidDataMessage);
                }
            }
            catch (Exception ex)
            {
                tenantResult.Add("isSuccess", false);
                tenantResult.Add("message", "Tenant " + tenantName + " has not been deleted." + ex.Message.ToString() + " and try again later.") ;
            }
            return Ok(tenantResult);
        }
        public HttpResponseMessage GetAllTenants(string tenantGroupName, string refresh_token)
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
                        return tenantBL.GetAllTenantList(tenantGroupName, deploymentUrl, accessToken);
                    }
                    else
                    {
                        return Request.CreateResponse(HttpStatusCode.OK, new JArray() {
                            new JObject()
                            {
                                {"code", Constants.invalidToken }
                            }
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
    }

    #endregion

}
#endregion
