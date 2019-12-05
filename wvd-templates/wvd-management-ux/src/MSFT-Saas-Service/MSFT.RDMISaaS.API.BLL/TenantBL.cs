#region "Import Namespaces"
using MSFT.WVDSaaS.API.Model;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Net.Http.Headers;
#endregion "Import Namespaces"

#region "MSFT.RDMISaaS.API.BLL"
namespace MSFT.WVDSaaS.API.BLL
{
    public class TenantBL
    {
        JObject tenantResult = new JObject();

        /// <summary>
        /// Description-Gets a specific Rds tenant.
        /// </summary>
        /// <param name="deploymentUrl">RD Broker url</param>
        /// <param name="accessToken">Access Token</param>
        /// <param name="tenantName">Anme of Tenant</param>
        /// <returns></returns>
        public HttpResponseMessage GetTenantDetails(string tenantGroupName, string deploymentUrl, string accessToken, string tenantName)
        {
            try
            {
                //call rest api to get tenant details -- july code bit
                HttpResponseMessage response = CommonBL.InitializeHttpClient(deploymentUrl, accessToken).GetAsync("/RdsManagement/V1/TenantGroups/" + tenantGroupName + "/Tenants/" + tenantName).Result;
                return response;
            }
            catch
            {
                return null;
            }
        }

        /// <summary>
        /// Description-Gets a list of Rds tenants.
        /// </summary>
        /// <param name="deploymentUrl">RD Broker Url</param>
        /// <param name="accessToken"> Access token</param>
        /// //old parameters for pagination - int pageSize, string sortField, bool isDescending, int initialSkip, string lastEntry
        /// <returns></returns>
        public HttpResponseMessage GetTenantList(string tenantGroupName, string deploymenturl, string accessToken)
        {
            try
            {
                //call rest api to get all tenants 
                HttpResponseMessage response = CommonBL.InitializeHttpClient(deploymenturl, accessToken).GetAsync("/RdsManagement/V1/TenantGroups/" + tenantGroupName + "/Tenants").Result;
                return response;
                
            }
            catch (Exception ex)
            {
                return null;
            }
        }

        

        /// <summary>
        /// Description :  create a RDs tenant
        /// </summary>
        /// <param name="deploymenturl">RD Broker Url</param>
        /// <param name="accessToken">Aaccess Token</param>
        /// <param name="rdMgmtTenant">Tenant Class</param>
        /// <returns></returns>
        public JObject CreateTenant(string deploymenturl, string accessToken, JObject tenantDataDTO)
        {
            try
            {
                //call rest api to create tenant-- july code bit
                var content = new StringContent(JsonConvert.SerializeObject(tenantDataDTO), Encoding.UTF8, "application/json");
                HttpResponseMessage response = CommonBL.InitializeHttpClient(deploymenturl, accessToken).PostAsync("/RdsManagement/V1/TenantGroups/" + tenantDataDTO["tenantGroupName"].ToString() + "/Tenants/" + tenantDataDTO["tenantName"].ToString(), content).Result;
                string strJson = response.Content.ReadAsStringAsync().Result;
                if (response.IsSuccessStatusCode)
                {
                    if (response.StatusCode == System.Net.HttpStatusCode.Created || response.StatusCode == System.Net.HttpStatusCode.OK)
                    {
                        tenantResult.Add("isSuccess", true);
                        tenantResult.Add("message", "Tenant '" + tenantDataDTO["tenantName"] + "' has been created successfully.");
                    }
                }
                else if ((int)response.StatusCode == 429)
                {
                    tenantResult.Add("isSuccess", false);
                    tenantResult.Add("message", strJson + " Please try again later.");
                }
                else
                {
                    if (!string.IsNullOrEmpty(strJson))
                    {
                        tenantResult.Add("message", CommonBL.GetErrorMessage(strJson));
                        tenantResult.Add("isSuccess", false);
                    }
                    else
                    {
                        tenantResult.Add("isSuccess", false);
                        tenantResult.Add("message", "Tenant '" + tenantDataDTO["tenantName"] + "' has not been created. Please try it again later.");
                    }
                }
            }
            catch (Exception ex)
            {
                tenantResult.Add("isSuccess", false);
                tenantResult.Add("message", "Tenant '" + tenantDataDTO["tenantName"] + "' has not been created." + ex.Message.ToString() + " and please try again later.");
            }
            return tenantResult;
        }

        /// <summary>
        /// Description : Update tenant information
        /// </summary>
        /// <param name="deploymenturl">RD Broker Url</param>
        /// <param name="accessToken">Access Token</param>
        /// <param name="rdMgmtTenant">Tenant Class</param>
        /// <returns></returns>
        public JObject UpdateTenant(string deploymenturl, string accessToken, JObject rdMgmtTenant)
        {
            try
            {
                //call rest api to update tenant -- july code bit
                var content = new StringContent(JsonConvert.SerializeObject(rdMgmtTenant), Encoding.UTF8, "application/json");
                HttpResponseMessage response = CommonBL.PatchAsync(deploymenturl, accessToken, "/RdsManagement/V1/TenantGroups/" + rdMgmtTenant["tenantGroupName"].ToString() + "/Tenants/" + rdMgmtTenant["tenantName"].ToString(), content).Result;
                string strJson = response.Content.ReadAsStringAsync().Result;
                if (response.IsSuccessStatusCode)
                {
                    tenantResult.Add("isSuccess", true);
                    tenantResult.Add("message", "Tenant '" + rdMgmtTenant["tenantName"] + "' has been updated successfully.");
                }
                else if ((int)response.StatusCode == 429)
                {
                    tenantResult.Add("isSuccess", false);
                    tenantResult.Add("message",strJson + " Please try again later.");
                }
                else
                {
                    if (!string.IsNullOrEmpty(strJson))
                    {
                        tenantResult.Add("isSuccess", false);
                        tenantResult.Add("message", CommonBL.GetErrorMessage(strJson));
                    }
                    else
                    {
                        tenantResult.Add("isSuccess", false);
                        tenantResult.Add("message", "Tenant '" + rdMgmtTenant["tenantName"] + "' has not been updated. Please try again later.");
                    }
                }
            }
            catch (Exception ex)
            {
                tenantResult.Add("isSuccess", false);
                tenantResult.Add("message", "Tenant " + rdMgmtTenant["tenantName"] + " has not been updated." + ex.Message.ToString() + " Please try again later.");
            }
            return tenantResult;
        }

        /// <summary>
        /// Description: Delete Tenant
        /// </summary>
        /// <param name="deploymenturl">RD Broker Url</param>
        /// <param name="accessToken">access Token</param>
        /// <param name="tenantName">tenantName</param>
        /// <returns></returns>
        public JObject DeleteTenant(string tenantGroupName, string deploymenturl, string accessToken, string tenantName)
        {
            try
            {
                //call rest api to delete tenant -- july code bit
                HttpResponseMessage response = CommonBL.InitializeHttpClient(deploymenturl, accessToken).DeleteAsync("/RdsManagement/V1/TenantGroups/" + tenantGroupName + "/Tenants/" + tenantName).Result;
                string strJson = response.Content.ReadAsStringAsync().Result;
                if (response.IsSuccessStatusCode)
                {
                    tenantResult.Add("isSuccess", true);
                    tenantResult.Add("message", "Tenant '" + tenantName + "' has been deleted successfully.");
                }
                else if ((int)response.StatusCode == 429)
                {
                    tenantResult.Add("isSuccess", false);
                    tenantResult.Add("message", strJson + " Please try again later.");
                }
                else
                {
                    if (!string.IsNullOrEmpty(strJson))
                    {
                        tenantResult.Add("isSuccess", false);
                        tenantResult.Add("message", CommonBL.GetErrorMessage(strJson));
                    }
                    else
                    {
                        tenantResult.Add("isSuccess", false);
                        tenantResult.Add("message", "Tenant '" + tenantName + "' has not been deleted. Please try again later.");
                    }
                }
            }
            catch (Exception ex)
            {
                tenantResult.Add("isSuccess", false);
                tenantResult.Add("message", "Tenant '" + tenantName + "' has not been deleted." + ex.Message.ToString() + " and try again later.");
            }
            return tenantResult;
        }

        public HttpResponseMessage GetAllTenantList(string tenantGroupName, string deploymenturl, string accessToken)
        {
            try
            {
                //call rest api to get all tenants -- july code bit
                HttpResponseMessage response = CommonBL.InitializeHttpClient(deploymenturl, accessToken).GetAsync("/RdsManagement/V1/TenantGroups/" + tenantGroupName + "/Tenants").Result;
                return response;
            }
            catch
            {
                return null;
            }
        }

        
    }
}
#endregion "MSFT.RDMISaaS.API.BLL"

