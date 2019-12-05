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
using System.Threading.Tasks;
#endregion "Import Namespaces"

#region "MSFT.WVDSaaS.API.BLL"
namespace MSFT.WVDSaaS.API.BLL
{
    #region "AuthorizationBL"
    public class AuthorizationBL
    {

        public  Task<HttpResponseMessage> GetRoleAssignments(string deploymentUrl, string accessToken, string upn)
        {
            try
            {
                HttpResponseMessage response = CommonBL.InitializeHttpClient(deploymentUrl, accessToken).GetAsync("/RdsManagement/V1/Rds.Authorization/roleAssignments?upn=" + upn).Result;//.Result; //.ConfigureAwait(true).GetAwaiter().GetResult();
                return Task.FromResult(response);
            }
            catch (Exception ex)
            {
                HttpResponseMessage response=  new HttpResponseMessage(System.Net.HttpStatusCode.RequestTimeout) { Content = new StringContent(ex.InnerException.Message.ToString(), System.Text.Encoding.UTF8, "application/json") };
                return  Task.FromResult(response);
            }
        }

        public List<RdMgmtRoleAssignment> GetRoleAssignmentsByUser(string deploymentUrl, string accessToken, string loginUserName)
        {
            List<RdMgmtRoleAssignment> rdMgmtRoleAssignments = new List<RdMgmtRoleAssignment>();
            try
            {
                HttpResponseMessage response = CommonBL.InitializeHttpClient(deploymentUrl, accessToken).GetAsync("RdsManagement/V1/Rds.Authorization/roleAssignments").Result;


                string strJson = response.Content.ReadAsStringAsync().Result;
                if (response.IsSuccessStatusCode)
                {
                    //Deserialize the string to JSON object
                    var jObj = (JArray)JsonConvert.DeserializeObject(strJson);
                    if (jObj.Count > 0 && jObj.Select(x => (string)x["signInName"] == loginUserName).Count() > 0)
                    {
                        rdMgmtRoleAssignments = jObj.Select(item => new RdMgmtRoleAssignment
                        {
                            roleAssignmentId = (string)item["roleAssignmentId"],
                            scope = (string)item["scope"],
                            displayName = (string)item["displayName"],
                            signInName = (string)item["signInName"],
                            roleDefinitionName = (string)item["roleDefinitionName"],
                            roleDefinitionId = (string)item["roleDefinitionId"],
                            objectId = (string)item["objectId"],
                            objectType = (string)item["objectType"]
                        }).ToList();
                    }

                }
            }
            catch (Exception ex)
            {
                return null;
            }
            return rdMgmtRoleAssignments;
        }
    }
    #endregion

}
#endregion 
