#region "Import Namespaces"
using MSFT.WVDSaaS.API.Model;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;

#endregion "Import Namespaces"

#region "MSFT.RDMISaaS.API.BLL"
namespace MSFT.WVDSaaS.API.BLL
{
    #region "HostPoolBL"
    public class HostPoolBL
    {
        JObject poolResult = new JObject();

        /// <summary>
        /// Description - Gets a Rds HostPool associated with the Tenant  specified in the Rds context.
        /// </summary>
        /// <param name="deploymentUrl">RD Broker url</param>
        /// <param name="accessToken">Access Token</param>
        /// <param name="tenantName">Name of Tenant</param>
        /// <param name="hostPoolName">name of Hostpool</param>
        /// <returns></returns>
        public HttpResponseMessage GetHostPoolDetails(string tenantGroupName, string deploymentUrl, string accessToken, string tenantName, string hostPoolName)
        {
            try
            {
                //call rest api to get host pool details -- july code bit
                HttpResponseMessage response = CommonBL.InitializeHttpClient(deploymentUrl, accessToken).GetAsync("/RdsManagement/V1/TenantGroups/" + tenantGroupName + "/Tenants/" + tenantName + "/HostPools/" + hostPoolName).Result;
                return response;
            }
            catch
            {
                return null;
            }
        }

        /// <summary>
        /// Description - Gets a list of Rds HostPools associated with the Tenant specified in the Rds context.
        /// </summary>
        /// <param name="deploymentUrl">RD Broker Url</param>
        /// <param name="accessToken">Access token</param>
        /// <param name="tenantName">Name Of Tenant</param>
        /// <param name="isHostpoolNameOnly">Get only hostpool name </param>
        /// old parameters for pagination - , bool isHostpoolNameOnly, bool isAll, int pageSize, string sortField, bool isDescending, int initialSkip, string lastEntry
        /// <returns></returns>
        public HttpResponseMessage GetHostPoolList(string tenantGroupName, string deploymentUrl, string accessToken, string tenantName)
        {
            try
            {
                HttpResponseMessage response = CommonBL.InitializeHttpClient(deploymentUrl, accessToken).GetAsync("/RdsManagement/V1/TenantGroups/" + tenantGroupName + "/Tenants/" + tenantName + "/HostPools").Result;
                return response;
            }
            catch
            {
                return null;
            }
        }

        
        /// <summary>
        /// Description- Creates a new Rds HostPool within a Tenant specified in the Rds context. 
        /// </summary>
        /// <param name="deploymentUrl">RD Broker Url</param>
        /// <param name="accessToken">Access Token</param>
        /// <param name="rdMgmtHostPool">Hostpool class</param>
        /// <returns></returns>
        public JObject CreateHostPool(string deploymentUrl, string accessToken, JObject rdMgmtHostPool)
        {
            try
            {

                if (Convert.ToBoolean(rdMgmtHostPool["persistent"]) == false)
                {
                    rdMgmtHostPool.Add("loadBalancerType", Convert.ToInt32(Enums.loadBalancer.BreadthFirst));
                }
                else
                {
                    rdMgmtHostPool.Add("loadBalancerType", Convert.ToInt32(Enums.loadBalancer.Persistent));

                }

                //call rest api to create host pool -- july code bit
                var content = new StringContent(JsonConvert.SerializeObject(rdMgmtHostPool), Encoding.UTF8, "application/json");
                HttpResponseMessage response = CommonBL.InitializeHttpClient(deploymentUrl, accessToken).PostAsync("/RdsManagement/V1/TenantGroups/" + rdMgmtHostPool["tenantGroupName"].ToString() + "/Tenants/" + rdMgmtHostPool["tenantName"].ToString() + "/HostPools/" + rdMgmtHostPool["hostPoolName"].ToString(), content).Result;
                string strJson = response.Content.ReadAsStringAsync().Result;
                if (response.IsSuccessStatusCode)
                {
                    if (response.StatusCode == System.Net.HttpStatusCode.Created || response.StatusCode==System.Net.HttpStatusCode.OK)
                    {
                        poolResult.Add("isSuccess", true);
                        poolResult.Add("message","Hostpool '" + rdMgmtHostPool["hostPoolName"].ToString() + "' has been created successfully.");
                    }
                }
                else if ((int)response.StatusCode == 429)
                {
                    poolResult.Add("isSuccess", false);
                    poolResult.Add("message", strJson + " Please try again later.");
                }
                else
                {
                    if (!string.IsNullOrEmpty(strJson))
                    {
                        poolResult.Add("isSuccess", false);
                        poolResult.Add("message", CommonBL.GetErrorMessage(strJson));
                    }
                    else
                    {
                        poolResult.Add("isSuccess", false);
                        poolResult.Add("message", "Hostpool '" + rdMgmtHostPool["hostPoolName"].ToString() + "' has not been created. Please try again later. ");
                    }
                }
            }
            catch (Exception ex)
            {
                poolResult.Add("isSuccess", false);
                poolResult.Add("message", "Hostpool '" + rdMgmtHostPool["hostPoolName"].ToString() + "' has not been created." + ex.Message.ToString() + " Please try again later. ");
            }
            return poolResult;
        }

        /// <summary>
        /// Description : Update hostpool details associated with tenant
        /// </summary>
        /// <param name="deploymenturl">RD Broker Url</param>
        /// <param name="accessToken"> Access Token</param>
        /// <param name="rdMgmtHostPool">Hostpool Class</param>
        /// <returns></returns>
        public JObject UpdateHostPool(string deploymentUrl, string accessToken, JObject rdMgmtHostPool)
        {
            try
            {
                //call rest api to update hostpool -- july code bit
                var content = new StringContent(JsonConvert.SerializeObject(rdMgmtHostPool), Encoding.UTF8, "application/json");
                HttpResponseMessage response = CommonBL.PatchAsync(deploymentUrl, accessToken, "/RdsManagement/V1/TenantGroups/" + rdMgmtHostPool["tenantGroupName"].ToString() + "/Tenants/" + rdMgmtHostPool["tenantName"].ToString() + "/HostPools/" + rdMgmtHostPool["hostPoolName"].ToString(), content).Result;
                string strJson = response.Content.ReadAsStringAsync().Result;
                if (response.IsSuccessStatusCode)
                {
                    poolResult.Add("isSuccess",  true);
                    poolResult.Add("message", "Hostpool '" + rdMgmtHostPool["hostPoolName"] + "' has been updated successfully.");
                }
                else if ((int)response.StatusCode == 429)
                {
                    poolResult.Add("isSuccess", false);
                    poolResult.Add("message",  strJson + " Please try again later.");
                }
                else
                {
                    if (!string.IsNullOrEmpty(strJson))
                    {
                        poolResult.Add("isSuccess",  false);
                        poolResult.Add("message", CommonBL.GetErrorMessage(strJson));
                    }
                    else
                    {
                        poolResult.Add("isSuccess", false);
                        poolResult.Add("message", "Hostpool '" + rdMgmtHostPool["hostPoolName"].ToString() + "' has not been updated. Please try it later again.");
                    }
                }
            }
            catch (Exception ex)
            {
                poolResult.Add("isSuccess", false);
                poolResult.Add("message", "Hostpool '" + rdMgmtHostPool["hostPoolName"].ToString() + "' has not been updated." + ex.Message.ToString() + " Please try it later again.");
            }
            return poolResult;
        }
        /// <summary>
        /// Description-Delete HostPool from associated tenant
        /// </summary>
        /// <param name="deploymentUrl">RD Broker Url</param>
        /// <param name="accessToken">Access token</param>
        /// <param name="tenantName">Name of Tenant</param>
        /// <param name="hostPoolName">Name of Hostpool</param>
        /// <returns></returns>
        public JObject DeleteHostPool(string tenantGroupName, string deploymentUrl, string accessToken, string tenantName, string hostPoolName)
        {
            try
            {
                //call rest api to delete hostpool  -- july code bit
                HttpResponseMessage response = CommonBL.InitializeHttpClient(deploymentUrl, accessToken).DeleteAsync("/RdsManagement/V1/TenantGroups/" + tenantGroupName + "/Tenants/" + tenantName + "/HostPools/" + hostPoolName).Result;
                string strJson = response.Content.ReadAsStringAsync().Result;
                if (response.IsSuccessStatusCode)
                {
                    poolResult.Add("isSuccess", true);
                    poolResult.Add("message", "Hostpool '" + hostPoolName + "' has been deleted successfully.");
                }
                else if ((int)response.StatusCode == 429)
                {
                    poolResult.Add("isSuccess", false);
                    poolResult.Add("message", strJson + " Please try again later.");
                }
                else
                {
                    if (!string.IsNullOrEmpty(strJson))
                    {
                        poolResult.Add("isSuccess", false);
                        poolResult.Add("message", CommonBL.GetErrorMessage(strJson));
                    }
                    else
                    {
                        poolResult.Add("isSuccess", false);
                        poolResult.Add("message", "Hostpool '" + hostPoolName + "' has not been deleted. Please try again later.");
                    }
                }
            }
            catch (Exception ex)
            {
                poolResult.Add("isSuccess", false);
                poolResult.Add("message", "Hostpool '" + hostPoolName + "' has not been deleted." + ex.Message.ToString() + " Please try again later.");
            }
            return poolResult;
        }
    }
    #endregion

}
#endregion
