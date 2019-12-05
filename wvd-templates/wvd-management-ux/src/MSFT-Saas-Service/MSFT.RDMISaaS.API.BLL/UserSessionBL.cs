#region "Import Namespaces"
using MSFT.WVDSaaS.API.Model;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Web;
#endregion "Import Namespaces"

#region "MSFT.RDMISaaS.API.BLL"
namespace MSFT.WVDSaaS.API.BLL
{
    #region "UserSessionBL"
    public class UserSessionBL
    {
        // string tenantGroup = Constants.tenantGroupName;
        JObject userSessionResult = new JObject();
        #region "Functions/Methods"
        /// <summary>
        /// Description - get list of user session
        /// </summary>
        /// <param name="deploymentUrl"></param>
        /// <param name="accessToken"></param>
        /// <param name="tenantName"></param>
        /// <param name="hostPoolName"></param>
        /// old parameters-- , bool isAll, int pageSize, string sortField, bool isDescending, int initialSkip, string lastEntry
        /// <returns></returns>
        public HttpResponseMessage GetListOfUserSessioons(string deploymentUrl, string accessToken, string tenantGroup, string tenantName, string hostPoolName, string hostName=null)
        {
            try
            {
                HttpResponseMessage response;
                response = CommonBL.InitializeHttpClient(deploymentUrl, accessToken).GetAsync("/RdsManagement/V1/TenantGroups/" + tenantGroup + "/Tenants/" + tenantName + "/HostPools/" + hostPoolName + "/Sessions").Result;

                if (hostName != null)
                {
                    var data = response.Content.ReadAsStringAsync().Result;
                    var arr = (JArray)JsonConvert.DeserializeObject(data);
                    var result = ((JArray)arr).Select(item => new JObject()
                    {
                        new JProperty( "tenantGroupName" , item["tenantGroupName"]),
                        new JProperty( "tenantName" , item["tenantName"]),
                        new JProperty("hostPoolName" , item["hostPoolName"]),
                        new JProperty("sessionHostName" , item["sessionHostName"]),
                        new JProperty( "userPrincipalName" , item["userPrincipalName"]),
                        new JProperty("sessionId" , item["sessionId"]),
                        new JProperty( "applicationType" , item["applicationType"]),
                        new JProperty( "adUserName" ,item["adUserName"]),
                        new JProperty( "createTime" ,item["createTime"]),
                        new JProperty("sessionState",item["sessionState"])
                    }).ToList().Where(x => x["sessionHostName"].ToString() == hostName).ToList();

                    return new HttpResponseMessage()
                    {
                        Content = new StringContent(JsonConvert.SerializeObject(result)),
                        StatusCode = System.Net.HttpStatusCode.OK
                    };
                }

                return response;
                //api call included pagination
                //response = CommonBL.InitializeHttpClient(deploymentUrl, accessToken).GetAsync("/RdsManagement/V1/TenantGroups/" + tenantGroup + "/Tenants/" + tenantName + "/HostPools/" + hostPoolName + "/Sessions?PageSize=" + pageSize + "&LastEntry=" + lastEntry + "&SortField=" + sortField + "&IsDescending=" + isDescending + "&InitialSkip=" + initialSkip).Result;
            }
            catch
            {
                return null;
            }
        }




        public JObject LogOffUserSesion(string deploymentUrl, string accessToken, JObject userSession)
        {
            try
            {
                //call rest service to log off user sessions 
                var content = new StringContent(JsonConvert.SerializeObject(userSession), Encoding.UTF8, "application/json");
                HttpResponseMessage response = CommonBL.InitializeHttpClient(deploymentUrl, accessToken).PostAsync("/RdsManagement/V1/TenantGroups/" + userSession["tenantGroupName"] + "/Tenants/" + userSession["tenantName"] + "/HostPools/" + userSession["hostPoolName"] + "/SessionHosts/" + userSession["sessionHostName"] + "/Sessions/" + userSession["sessionId"] + "/actions/logoff-user", content).Result;
                string strJson = response.Content.ReadAsStringAsync().Result;
                if (response.IsSuccessStatusCode)
                {
                    userSessionResult.Add("isSuccess", true);
                    userSessionResult.Add("message", "Log off successfully for '" + userSession["adUserName"].ToString()+"'");
                }
                else if ((int)response.StatusCode == 429)
                {
                    userSessionResult.Add("isSuccess", false);
                    userSessionResult.Add("message", strJson + " Please try again later.");
                }
                else
                {
                    if (!string.IsNullOrEmpty(strJson))
                    {
                        userSessionResult.Add("isSuccess", false);
                        userSessionResult.Add("message", CommonBL.GetErrorMessage(strJson));
                    }
                    else
                    {
                        userSessionResult.Add("isSuccess", false);
                        userSessionResult.Add("message", "Failed to log off  '" + userSession["adUserName"].ToString() + "'. Please try it again later.");
                    }
                }
            }
            catch (Exception ex)
            {
                userSessionResult.Add("isSuccess", false);
                userSessionResult.Add("message", "Failed to log off  '" + userSession["adUserName"].ToString() + "'." + ex.Message.ToString() + " Please try it again later.");
            }
            return userSessionResult;
        }

        public JObject SendMessage(string deploymentUrl, string accessToken, JObject userSession)
        {
            try
            {
                //call rest service to log off user sessions 
                var content = new StringContent(JsonConvert.SerializeObject(userSession), Encoding.UTF8, "application/json");
                HttpResponseMessage response = CommonBL.InitializeHttpClient(deploymentUrl, accessToken).PostAsync("/RdsManagement/V1/TenantGroups/" + userSession["tenantGroupName"] + "/Tenants/" + userSession["tenantName"] + "/HostPools/" + userSession["hostPoolName"] + "/SessionHosts/" + userSession["sessionHostName"] + "/Sessions/" + userSession["sessionId"] + "/actions/send-message-user?MessageTitle=" + HttpUtility.UrlEncode(userSession["messageTitle"].ToString()) + "&MessageBody=" + HttpUtility.UrlEncode(userSession["messageBody"].ToString()), content).Result;
                string strJson = response.Content.ReadAsStringAsync().Result;
                if (response.IsSuccessStatusCode)
                {
                    userSessionResult.Add("isSuccess", true);
                    userSessionResult.Add("message", "Message sent successfully to '" + userSession["adUserName"].ToString()+"'");
                }
                else if ((int)response.StatusCode == 429)
                {
                    userSessionResult.Add("isSuccess", false);
                    userSessionResult.Add("message", strJson + " Please try again later.");
                }
                else
                {
                    if (!string.IsNullOrEmpty(strJson))
                    {
                        userSessionResult.Add("isSuccess", false);
                        userSessionResult.Add("message", CommonBL.GetErrorMessage(strJson));
                    }
                    else
                    {
                        userSessionResult.Add("isSuccess", false);
                        userSessionResult.Add("message", "Failed to send message to '" + userSession["adUserName"].ToString() + "'. Please try it again later.");
                    }
                }
            }
            catch (Exception ex)
            {
                userSessionResult.Add("isSuccess", false);
                userSessionResult.Add("message", "Failed to send message to '" + userSession["adUserName"].ToString() + "'." + ex.Message.ToString() + " Please try it again later.");
            }
            return userSessionResult;
        }

        #endregion

    }
    #endregion "MSFT.RDMISaaS.API.BLL"

}
#endregion
