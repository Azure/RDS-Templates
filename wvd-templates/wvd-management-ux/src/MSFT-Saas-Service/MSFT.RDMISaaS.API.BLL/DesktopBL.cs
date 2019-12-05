#region "Import Namespaces"
using MSFT.WVDSaaS.API.Model;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Text;
#endregion "Import Namespaces" 

#region "MSFT.RDMISaaS.API.BLL"
namespace MSFT.WVDSaaS.API.BLL
{
    #region "class-DesktopBL"
    public class DesktopBL
    {

        /// <summary>
        /// Description-Gets the published desktop for host pool's application group
        /// </summary>
        /// <param name="deploymentUrl">RD Broker url</param>
        /// <param name="accessToken">Access Token</param>
        /// <param name="tenantName">Name of Tenant</param>
        /// <param name="hostPoolName">Name of Hostpool</param>
        /// <param name="appGroupName">Name of App Group</param>
        /// <returns></returns>
        public RdMgmtPublishedDesktop GetPublishedDesktop(string deploymentUrl, string accessToken, string tenantGroup, string tenantName, string hostPoolName, string appGroupName)
        {
            RdMgmtPublishedDesktop rdMgmtPublishedDesktop = new RdMgmtPublishedDesktop();
            try
            {
                //call rest api to get all published desktop apps in app groups -- july code bit
                HttpResponseMessage response = CommonBL.InitializeHttpClient(deploymentUrl, accessToken).GetAsync("/RdsManagement/V1/TenantGroups/"+tenantGroup+"/Tenants/" + tenantName + "/HostPools/" + hostPoolName + "/AppGroups/" + appGroupName + "/Desktop").Result;
                string strJson = response.Content.ReadAsStringAsync().Result;
                if (response.IsSuccessStatusCode)
                {
                    //Deserialize the string to JSON object
                    rdMgmtPublishedDesktop = JsonConvert.DeserializeObject<RdMgmtPublishedDesktop>(strJson);
                }
            }
            catch 
            {
                return null;
            }
            return rdMgmtPublishedDesktop;
        }
    }
    #endregion  "Class - DesktopBL"
}
#endregion "MSFT.RDMISaaS.API.BLL" 