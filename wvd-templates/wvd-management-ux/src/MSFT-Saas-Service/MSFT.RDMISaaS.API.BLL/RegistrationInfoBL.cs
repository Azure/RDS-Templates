#region "Import Namespaces"
using MSFT.WVDSaaS.API.Model;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
#endregion "Import Namespaces"

#region "MSFT.RDMISaaS.API.BLL"
namespace MSFT.WVDSaaS.API.BLL
{
    #region "RegistrationInfoBL"
    public class RegistrationInfoBL
    {
        JObject infoResult = new JObject();

        /// <summary>
        /// Description - Exports a Rds RegistrationInfo associated with the TenantGroup, Tenant and HostPool specified in the Rds context.
        /// </summary>
        /// <param name="deploymentUrl"></param>
        /// <param name="accessToken"></param>
        /// <param name="tenantName"></param>
        /// <param name="hostPoolName"></param>
        /// <returns></returns>
        public HttpResponseMessage GetRegistrationInfo(string tenantGroupName,string deploymentUrl, string accessToken, string tenantName, string hostPoolName)
        {
            try
            {
                //call rest api to get RegistrationInfo -- july code bit
                HttpResponseMessage response = CommonBL.InitializeHttpClient(deploymentUrl, accessToken).GetAsync("/RdsManagement/V1/TenantGroups/" + tenantGroupName + "/Tenants/" + tenantName + "/HostPools/" + hostPoolName + "/RegistrationInfos/actions/export").Result;
                return response;
            }
            catch 
            {
                return null;
            }
        }

        /// <summary>
        /// Description : Generate registration key to create host
        /// </summary>
        /// <param name="deploymentUrl"></param>
        /// <param name="accessToken"></param>
        /// <param name="rdMgmtRegistrationInfo"></param>
        /// <returns></returns>
        public JObject CreateRegistrationInfo(string deploymentUrl, string accessToken, JObject rdMgmtRegistrationInfo)
        {
            try
            {
                //call rest api to generate registration key -- july code bit
                var content = new StringContent(JsonConvert.SerializeObject(rdMgmtRegistrationInfo), Encoding.UTF8, "application/json");
                HttpResponseMessage response = CommonBL.InitializeHttpClient(deploymentUrl, accessToken).PostAsync("/RdsManagement/V1/TenantGroups/" + rdMgmtRegistrationInfo["tenantGroupName"].ToString() + "/Tenants/" + rdMgmtRegistrationInfo["tenantName"].ToString() + "/HostPools/" + rdMgmtRegistrationInfo["hostPoolName"].ToString() + "/RegistrationInfos/", content).Result;

                string strJson = response.Content.ReadAsStringAsync().Result;
                if (response.IsSuccessStatusCode)
                {
                    if (response.StatusCode == System.Net.HttpStatusCode.Created || response.StatusCode == System.Net.HttpStatusCode.OK)
                    {
                        infoResult.Add("isSuccess", true);
                        infoResult.Add("message", "Registration Key has been generated for hostpool '" + rdMgmtRegistrationInfo["hostPoolName"].ToString() + "' successfully.");
                    }
                }
                else
                {
                    if (!string.IsNullOrEmpty(strJson))
                    {
                        infoResult.Add("isSuccess", false);
                        infoResult.Add("message", CommonBL.GetErrorMessage(strJson));
                    }
                    else
                    {
                        infoResult.Add("isSuccess", false);
                        infoResult.Add("message", "Registration Key has not been generated. Please try again later.");
                    }
                }
            }
            catch (Exception ex)
            {
                infoResult.Add("isSuccess", false);
                infoResult.Add("message", "Registration Key has not been generated." +ex.Message.ToString()+" Please try it later again.");
            }
            return infoResult;
        }

        /// <summary>
        /// Description : Removes a Rds Registration key associated with the Tenant and HostPool specified in the Rds context
        /// </summary>
        /// <param name="deploymentUrl">RD broker Url</param>
        /// <param name="accessToken">Access Token</param>
        /// <param name="tenantName">Name of Tenant</param>
        /// <param name="hostPoolName">Name of hostpool</param>
        /// <returns></returns>
        public JObject DeleteRegistrationInfo(string tenantGroupName,string deploymentUrl, string accessToken, string tenantName, string hostPoolName)
        {
            try
            {

                //call rest api to delete registration key  -- july code bit
                HttpResponseMessage response = CommonBL.InitializeHttpClient(deploymentUrl, accessToken).DeleteAsync("/RdsManagement/V1/TenantGroups/" + tenantGroupName + "/Tenants/" + tenantName + "/HostPools/" + hostPoolName + "/RegistrationInfos/").Result;
                string strJson = response.Content.ReadAsStringAsync().Result;
                if (response.IsSuccessStatusCode)
                {
                    infoResult.Add("isSuccess", true);
                    infoResult.Add("message", "Registration Key has been deleted successully.");
                }
                else
                {
                    if (!string.IsNullOrEmpty(strJson))
                    {
                        infoResult.Add("isSuccess", false);
                        infoResult.Add("message", CommonBL.GetErrorMessage(strJson));
                    }
                    else
                    {
                        infoResult.Add("isSuccess", false);
                        infoResult.Add("message", "Registration Key has not been deleted. Please try it later again.");
                    }
                }
            }
            catch (Exception ex)
            {
                infoResult.Add("isSuccess", false);
                infoResult.Add("message", "Registration Key has been deleted." +ex.Message.ToString()+" Please try again later.");
            }
            return infoResult;
        }
    }
    #endregion

}
#endregion

