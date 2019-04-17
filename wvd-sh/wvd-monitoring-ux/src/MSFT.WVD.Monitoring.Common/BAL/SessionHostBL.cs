using MSFT.WVD.Monitoring.Common.Models;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Net;
namespace MSFT.WVD.Monitoring.Common.BAL
{
    public class SessionHostBL
    {
        public HttpResponseMessage GetUserSessions(string deploymentUrl, string accessToken, string tenantGroupName, string tenant, string hostPoolName, string sessionHostName)
        {
            try
            {
                return CommonBL.InitializeHttpClient(deploymentUrl, accessToken).GetAsync($"/RdsManagement/V1/TenantGroups/{tenantGroupName}/Tenants/{tenant}/HostPools/{sessionHostName}/Sessions").Result;
            }
            catch (Exception ex)
            {
                return new HttpResponseMessage() { StatusCode = HttpStatusCode.BadRequest, Content = new StringContent(ex.Message) };
            }
        }

        public IEnumerable<UserSession> GetUserSessions(HttpResponseMessage httpResponseMessage,string sessionHostName)
        {
            string strJson = httpResponseMessage.Content.ReadAsStringAsync().Result;
            var arr = (JArray)JsonConvert.DeserializeObject(strJson);
            return  ((JArray)arr).Select(item => new UserSession
            {
                tenantGroupName = (string)item["tenantGroupName"],
                tenantName = (string)item["tenantName"],
                hostPoolName = (string)item["hostPoolName"],
                sessionHostName = (string)item["sessionHostName"],
                userPrincipalName = (string)item["userPrincipalName"],
                sessionId = (int)item["sessionId"],
                applicationType = (string)item["applicationType"]
            }).ToList().Where(x => x.sessionHostName.ToString() == sessionHostName).ToList();
        }

        public HttpResponseMessage SendMessage(string deploymentUrl, string accessToken,SendMessageQuery sendMessageQuery)
        {
            try
            {
                var json = JsonConvert.SerializeObject(sendMessageQuery);
                var content = new StringContent(json, UnicodeEncoding.UTF8, "application/json");
                return CommonBL.InitializeHttpClient(deploymentUrl, accessToken).PostAsync($"/RdsManagement/V1/TenantGroups/{sendMessageQuery.tenantGroupName}/Tenants/{sendMessageQuery.tenantName}/HostPools/{sendMessageQuery.hostPoolName}/SessionHosts/{sendMessageQuery.sessionHostName}/Sessions/{sendMessageQuery.sessionId}/actions/send-message-user?MessageTitle={sendMessageQuery.messageTitle}&MessageBody={sendMessageQuery.messageBody}", content).Result;
            }
            catch (Exception ex)
            {
                return new HttpResponseMessage() {
                    StatusCode= HttpStatusCode.BadRequest,
                    Content= new StringContent(ex.Message, UnicodeEncoding.UTF8, "application/json")
                };
            }
        }

        public HttpResponseMessage LogOffUser(string deploymentUrl, string accessToken,LogOffUserQuery logOffUserQuery)
        {
            try
            {
                var json = JsonConvert.SerializeObject(logOffUserQuery);
                var content = new StringContent(json, UnicodeEncoding.UTF8, "application/json");
                return CommonBL.InitializeHttpClient(deploymentUrl, accessToken).PostAsync($"/RdsManagement/V1/TenantGroups/{logOffUserQuery.tenantGroupName}/Tenants/{logOffUserQuery.tenantName}/HostPools/{logOffUserQuery.hostPoolName}/SessionHosts/{logOffUserQuery.sessionHostName}/Sessions/{logOffUserQuery.sessionId}/actions/logoff-user", content).Result;
            }
            catch (Exception ex)
            {
                return new HttpResponseMessage()
                {
                    StatusCode = HttpStatusCode.BadRequest,
                    Content = new StringContent(ex.Message, UnicodeEncoding.UTF8, "application/json")
                };
            }
        }
    }
}
