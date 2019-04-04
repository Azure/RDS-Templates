using MSFT.WVD.Monitoring.Common.Models;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Linq;
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

        public IEnumerable<RoleAssignment> GetTenantGroups(string rdBrokerUrl, string accessToken, string upn)
        {
            string strJson = @"[
            {
                'roleAssignmentId': '260f1d99-81ec-4ff7-9546-08d64a573e59',
                'scope': '/Default Tenant Group/Peopletech-Tenant',
                'displayName': 'WVD Demo',
                'signInName': 'wvd.demo@peopletechcsp.onmicrosoft.com',
                'groupObjectId': '1073c417-26eb-4c67-9b95-f6cbcfce5ed7',
                'aadTenantId': '00000000-0000-0000-0000-000000000000',
                'appId': 'fa4345a4-a730-4230-84a8-7d9651b86739',
                'roleDefinitionName': 'RDS Owner',
                'roleDefinitionId': '3b14baea-8d82-4610-f5da-08d623dd1cc4',
                'objectId': '02f02d06-a346-4210-a30e-08d64a54f4aa',
                'objectType': 'User'
            },
            {
                'roleAssignmentId': '2ed4a8fc-5a84-4158-f32c-08d6721cf222',
                'scope': '/Ptg',
                'displayName': 'WVD Demo',
                'signInName': 'wvd.demo@peopletechcsp.onmicrosoft.com',
                'groupObjectId': '1073c417-26eb-4c67-9b95-f6cbcfce5ed7',
                'aadTenantId': '00000000-0000-0000-0000-000000000000',
                'appId': 'fa4345a4-a730-4230-84a8-7d9651b86739',
                'roleDefinitionName': 'RDS Owner',
                'roleDefinitionId': '3b14baea-8d82-4610-f5da-08d623dd1cc4',
                'objectId': '02f02d06-a346-4210-a30e-08d64a54f4aa',
                'objectType': 'User'
            },
            {
                'roleAssignmentId': '2ed4a8fc-5a84-4158-f32c-08d6721cf222',
                'scope': '/Ptg',
                'displayName': 'WVD Demo',
                'signInName': 'wvd.demo@peopletechcsp.onmicrosoft.com',
                'groupObjectId': '1073c417-26eb-4c67-9b95-f6cbcfce5ed7',
                'aadTenantId': '00000000-0000-0000-0000-000000000000',
                'appId': 'fa4345a4-a730-4230-84a8-7d9651b86739',
                'roleDefinitionName': 'RDS Owner',
                'roleDefinitionId': '3b14baea-8d82-4610-f5da-08d623dd1cc4',
                'objectId': '02f02d06-a346-4210-a30e-08d64a54f4aa',
                'objectType': 'User'
            }
            ]
            ";
            //List<RoleAssignment> roles= new List<RoleAssignment>();
            var arr = (JArray)JsonConvert.DeserializeObject(strJson);

            List<RoleAssignment> roles = ((JArray)arr).Select(item => new RoleAssignment
            {
                roleAssignmentId = (string)item["roleAssignmentId"],
                scope = (string)item["scope"],
                displayName = (string)item["displayName"],
                signInName = (string)item["signInName"],
                roleDefinitionName = (string)item["roleDefinitionName"],
                roleDefinitionId = (string)item["roleDefinitionId"],
                objectId = (string)item["objectId"],
                objectType = (string)item["objectType"],
                tenantGroupName = item["scope"].ToString().Split('/').Length > 1 ? item["scope"].ToString().Split('/')[1].ToString() : Constants.tenantGroupName
            }).GroupBy(i => i.tenantGroupName).Select(g => g.First()).ToList();

           
            //roles = roles.GroupBy(i => i.tenantGroupName).Select(g => g.First()).ToList();
            return roles;
        }
    }
}
