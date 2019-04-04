using MSFT.WVD.Monitoring.Common.Models;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;

namespace MSFT.WVD.Monitoring.Common.BAL
{
    public class TenantBL
    {
        public IEnumerable<Tenant> GetTenants(string deploymentUrl, string accessToken, string tenantGroup)
        {
            List<Tenant> tenants;
            HttpResponseMessage httpResponseMessage;
            try
            {
                httpResponseMessage = CommonBL.InitializeHttpClient(deploymentUrl, accessToken).GetAsync($"/RdsManagement/V1/TenantGroups/{tenantGroup}/Tenants/").Result;
                if (httpResponseMessage.IsSuccessStatusCode)
                {
                    string strJson = httpResponseMessage.Content.ReadAsStringAsync().Result;
                    var arr = (JArray)JsonConvert.DeserializeObject(strJson);
                    tenants = ((JArray)arr).Select(item => new Tenant
                    {
                        tenantGroupName = (string)item["tenantGroupName"],
                        aadTenantId = (string)item["aadTenantId"],
                        tenantName = (string)item["tenantName"],
                        description = (string)item["description"],
                        friendlyName = (string)item["friendlyName"],
                        ssoAdfsAuthority = (string)item["ssoAdfsAuthority"],
                        ssoClientId = (string)item["ssoClientId"],
                        ssoClientSecret = (string)item["ssoClientSecret"],
                        azureSubscriptionId = (string)item["azureSubscriptionId"],
                        logAnalyticsWorkspaceId = (string)item["logAnalyticsWorkspaceId"],
                        logAnalyticsPrimaryKey = (string)item["logAnalyticsPrimaryKey"],
                    }).ToList();
                    return tenants;
                }
                else
                {
                    return null;
                }
            }
            catch (Exception ex)
            {

                return null;
            }

           

        }
    }
}
