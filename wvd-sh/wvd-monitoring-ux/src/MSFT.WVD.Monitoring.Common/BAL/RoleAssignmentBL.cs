using MSFT.WVD.Monitoring.Common.Models;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace MSFT.WVD.Monitoring.Common.BAL
{
    public class RoleAssignmentBL
    {
        public HttpResponseMessage GetRoleAssignments(string deploymentUrl, string accessToken, string upn)
        {
            try
            {
                return CommonBL.InitializeHttpClient(deploymentUrl, accessToken).GetAsync("/RdsManagement/V1/Rds.Authorization/roleAssignments?upn=" + upn).Result;//.Result; //.ConfigureAwait(true).GetAwaiter().GetResult();
            }
            catch (Exception ex)
            {
                return new HttpResponseMessage(System.Net.HttpStatusCode.RequestTimeout) { Content = new StringContent(ex.InnerException.Message.ToString(), System.Text.Encoding.UTF8, "application/json") };
            }
        }

        public string[] GetTenantGroups(string rdBrokerUrl,string accessToken,string upn)
        {
            //get roleassigment
            //  HttpResponseMessage httpResponse = GetRoleAssignments(rdBrokerUrl, accessToken, upn);
            // if (httpResponse.IsSuccessStatusCode)
            // {

            //Array arr = (JArray)JsonConvert.DeserializeObject(strJson);

            // List<RoleAssignment> roles = Newtonsoft.Json.JsonConvert.DeserializeObject<List<RoleAssignment>>(arr.ToString());
            //List<RoleAssignment> roleAssignments= new List<RoleAssignment>
            //if (loginDetails.roleAssignments != null && loginDetails.roleAssignments.Count > 0)
            //{
            //    loginDetails.tenantGroups = new string[loginDetails.roleAssignments.Count];
            //    for (int i = 0; i < loginDetails.roleAssignments.Count; i++)
            //    {
            //        loginDetails.tenantGroups[i] = loginDetails.roleAssignments[i]["scope"].ToString().Split('/').Length > 1 ? loginDetails.roleAssignments[i]["scope"].ToString().Split('/')[1].ToString() : Constants.tenantGroupName;
            //    }
            //}
            // }
            string[] groups = { "Default Tenant Group", "Ptg" };
            return groups;

            
        }
    }
}
