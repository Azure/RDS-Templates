#region "Import Namespaces"
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using MSFT.WVDSaaS.API.Model;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Web;
using System.Net;
#endregion "Import Namespaces" 

#region "MSFT.WVDSaaS.API.BLL"
namespace MSFT.WVDSaaS.API.BLL
{
    #region "class-AppGroupBL"
    public class AppGroupBL
    {
        JObject groupResult = new JObject();
        UserSessionBL userSessionBL = new UserSessionBL();

        // string tenantGroup = Constants.tenantGroupName;


        /// <summary>
        /// Description : Gets a user details from an AppGroup within  Tenant and HostPool associated with the specified Rds context.
        /// </summary>
        /// <param name="deploymentUrl"> RD Broker Url </param>
        /// <param name="accessToken">Access Token</param>
        /// <param name="userPrincipalName"> Login ID of AAD User</param>
        /// <param name="tenantName">Name of Tenant</param>
        /// <param name="hostPoolName"> Name of Hostpool</param>
        /// <param name="appGroupName">Name of App group</param>
        /// <returns></returns>
        public HttpResponseMessage GetUserDetails(string tenantGroupName, string deploymentUrl, string accessToken, string tenantName, string hostPoolName, string appGroupName, string userPrincipalName)
        {
            //RdMgmtUser rdMgmtUser = new RdMgmtUser();
            try
            {
                //call rest api to get app group user details -- july code bit
                HttpResponseMessage response = CommonBL.InitializeHttpClient(deploymentUrl, accessToken).GetAsync("/RdsManagement/V1/TenantGroups/" + tenantGroupName + "/Tenants/" + tenantName + "/HostPools/" + hostPoolName + "/AppGroups/" + appGroupName + "/AssignedUsers/" + userPrincipalName).Result;
                return response;
            }
            catch
            {
                return null;
            }
        }

        /// <summary>
        /// Description-Gets a list of users from an AppGroup 
        /// </summary>
        /// <param name="deploymentUrl">RD Broker Url</param>
        /// <param name="accessToken"> Access Token</param>
        /// <param name="userPrincipalName"> Login ID of AAD User</param>
        /// <param name="tenantName">Name of Tenant</param>
        /// <param name="hostPoolName">Name of Hostpool</param>
        /// <param name="appGroupName">Name of App Group</param>
        /// //old parametewrs for pagination - bool isUserNameOnly,bool isAll, int pageSize, string sortField, bool isDescending, int initialSkip, string lastEntry
        /// <returns></returns>
        public HttpResponseMessage GetAppGroupUsersList(string tenantGroupName, string deploymentUrl, string accessToken, string tenantName, string hostPoolName, string appGroupName)
        {
            HttpResponseMessage response;
            try
            {
                response = CommonBL.InitializeHttpClient(deploymentUrl, accessToken).GetAsync("/RdsManagement/V1/TenantGroups/" + tenantGroupName + "/Tenants/" + tenantName + "/HostPools/" + hostPoolName + "/AppGroups/" + appGroupName + "/AssignedUsers").Result;
                return response;
            }
            catch
            {
                return null;
            }
        }

        public HttpResponseMessage GetUsersList(string tenantGroupName, string deploymentUrl, string accessToken, string tenantName, string hostPoolName, string appGroupName)
        {
            HttpResponseMessage userResponse = GetAppGroupUsersList(tenantGroupName, deploymentUrl, accessToken, tenantName, hostPoolName, appGroupName);
            if (userResponse.StatusCode == HttpStatusCode.OK)
            {

                var arrUsers = (JArray)JsonConvert.DeserializeObject(userResponse.Content.ReadAsStringAsync().Result);
                var usersResult = ((JArray)arrUsers);
                if (usersResult != null && usersResult.ToList().Count > 0)
                {
                    HttpResponseMessage userSessionResponse = userSessionBL.GetListOfUserSessioons(deploymentUrl, accessToken, tenantGroupName, tenantName, hostPoolName);
                    if (userSessionResponse.StatusCode == HttpStatusCode.OK)
                    {
                        var arrSessionUsers = (JArray)JsonConvert.DeserializeObject(userSessionResponse.Content.ReadAsStringAsync().Result);
                        var sessionUsersResult = ((JArray)arrSessionUsers).ToList();
                        if (sessionUsersResult != null && sessionUsersResult.Count > 0)
                        {
                            usersResult.ToList().ForEach(item =>
                            {
                                var element = sessionUsersResult.ToList().FirstOrDefault(d => d["userPrincipalName"].ToString().ToLower() == item["userPrincipalName"].ToString().ToLower());
                                item["sessionHostName"] = element != null ? element["sessionHostName"] : "NA";
                                item["tenantName"] = element != null ? element["tenantName"] : item["tenantName"];
                                item["tenantGroupName"] = element != null ? element["tenantGroupName"] : item["tenantGroupName"];
                                item["hostPoolName"] = element != null ? element["hostPoolName"] : item["hostPoolName"];
                                item["createTime"] = element != null ? element["createTime"]:"NA";
                                item["sessionState"] = element != null ? element["sessionState"]:"NA";
                                item["userPrincipalName"] = element != null ? element["userPrincipalName"] : item["userPrincipalName"];
                            });

                            return new HttpResponseMessage()
                            {
                                Content = new StringContent(JsonConvert.SerializeObject(usersResult)),
                                StatusCode = System.Net.HttpStatusCode.OK
                            };
                        }
                        else
                        {
                            return PrepareUserList(usersResult);
                        }
                    }
                    else
                    {
                        return PrepareUserList(usersResult);
                    }
                }
                else
                {
                    return userResponse;
                }
            }
            else
            {
                return userResponse;
            }

        }

        public HttpResponseMessage PrepareUserList(JArray usersResult)
        {
            usersResult.ToList().ForEach(item =>
            {
                item["sessionHostName"] = "NA";
                item["tenantName"] = item["tenantName"];
                item["tenantGroupName"] =  item["tenantGroupName"];
                item["hostPoolName"] = item["hostPoolName"];
                item["createTime"] = "NA";
                item["sessionState"] =  "NA";
                item["userPrincipalName"] = item["userPrincipalName"];
            });
            return new HttpResponseMessage()
            {
                Content = new StringContent(JsonConvert.SerializeObject(usersResult)),
                StatusCode = System.Net.HttpStatusCode.OK
            };
        }

        /// <summary>
        /// Description-Gets an AppGroupDetails within a Tenant and Hostpool
        /// </summary>
        /// <param name="deploymentUrl">Rd Broker Url</param>
        /// <param name="accessToken"> Access Token</param>
        /// <param name="tenantName">Name of Tenant</param>
        /// <param name="hostPoolName">Name of Hostpool</param>
        /// <param name="appGroupName">Name of App group</param>
        /// <returns></returns>
        public HttpResponseMessage GetAppGroupDetails(string tenantGroupName, string deploymentUrl, string accessToken, string tenantName, string hostPoolName, string appGroupName)
        {
            RdMgmtAppGroup rdMgmtAppGroup = new RdMgmtAppGroup();
            try
            {
                //call rest api to get  app groups details -- july code bit
                HttpResponseMessage response = CommonBL.InitializeHttpClient(deploymentUrl, accessToken).GetAsync("/RdsManagement/V1/TenantGroups/" + tenantGroupName + "/Tenants/" + tenantName + "/HostPools/" + hostPoolName + "/AppGroups/" + appGroupName).Result;
                return response;

            }
            catch
            {
                return null;
            }
        }

        /// <summary>
        /// Description - Gets a list of AppGroups within a Tenant and Hostpool 
        /// </summary>
        /// <param name="deploymentUrl">RD Broker Url</param>
        /// <param name="accessToken">Access token</param>
        /// <param name="tenantName">Name of Tenant</param>
        /// <param name="hostPoolName">Name of Hostpool</param>
        /// <param name="isAppGroupNameOnly">used to get Only App Group Name</param>
        /// // old parameters -- , bool isAppGroupNameOnly,bool isAll, int pageSize, string sortField, bool isDescending, int initialSkip, string lastEntry
        /// <returns></returns>
        public HttpResponseMessage GetAppGroupsList(string tenantGroupName, string deploymentUrl, string accessToken, string tenantName, string hostPoolName)
        {
            try
            {
                HttpResponseMessage response = CommonBL.InitializeHttpClient(deploymentUrl, accessToken).GetAsync("/RdsManagement/V1/TenantGroups/" + tenantGroupName + "/Tenants/" + tenantName + "/HostPools/" + hostPoolName + "/AppGroups").Result;
                return response;
            }
            catch
            {
                return null;
            }
        }

        /// <summary>
        /// Description-Gets a list of StartMenuApps within a Teanat and Hostpool. 
        /// </summary>
        /// <param name="deploymentUrl">RD Broker Url</param>
        /// <param name="accessToken"> Access Token</param>
        /// <param name="tenantName"> Name of Tenant</param>
        /// <param name="hostPoolName">Name of Hostpool</param>
        /// <param name="appGroupName">Name of App group</param>
        /// old parameters --  int pageSize, string sortField, bool isDescending, int initialSkip, string lastEntry
        /// <returns></returns>
        public HttpResponseMessage GetStartMenuAppsList(string tenantGroupName, string deploymentUrl, string accessToken, string tenantName, string hostPoolName, string appGroupName)
        {
            List<RdMgmtStartMenuApp> rdMgmtStartMenuApps = new List<RdMgmtStartMenuApp>();
            try
            {
                //call rest api to get all startmenu apps in app group -- july code bit
                HttpResponseMessage response = CommonBL.InitializeHttpClient(deploymentUrl, accessToken).GetAsync("/RdsManagement/V1/TenantGroups/" + tenantGroupName + "/Tenants/" + tenantName + "/HostPools/" + hostPoolName + "/AppGroups/" + appGroupName + "/StartMenuApps").Result;

                //folllowing api call is included pagination
                //HttpResponseMessage response = CommonBL.InitializeHttpClient(deploymentUrl, accessToken).GetAsync("/RdsManagement/V1/TenantGroups/" + tenantGroupName + "/Tenants/" + tenantName + "/HostPools/" + hostPoolName + "/AppGroups/" + appGroupName + "/StartMenuApps?PageSize=" + pageSize + "&LastEntry=" + lastEntry + "&SortField=" + sortField + "&IsDescending=" + isDescending + "&InitialSkip=" + initialSkip).Result;
                return response;

            }
            catch
            {
                return null;
            }
        }

        /// <summary>
        /// Description : Creates an AppGroup within Tenant, and HostPool associated with the specified Rds context.
        /// </summary>
        /// <param name="deploymentUrl">RD Broker Url</param>
        /// <param name="accessToken"> Access Token</param>
        /// <param name="rdMgmtAppGroup"> App Group Class </param>
        /// <returns></returns>
        public JObject CreateAppGroup(string deploymentUrl, string accessToken, JObject rdMgmtAppGroup)
        {
            try
            {
                //call rest service to create app group -- july code bit
                var content = new StringContent(JsonConvert.SerializeObject(rdMgmtAppGroup), Encoding.UTF8, "application/json");
                HttpResponseMessage response = CommonBL.InitializeHttpClient(deploymentUrl, accessToken).PostAsync("/RdsManagement/V1/TenantGroups/" + rdMgmtAppGroup["tenantGroupName"].ToString() + "/Tenants/" + rdMgmtAppGroup["tenantName"].ToString() + "/HostPools/" + rdMgmtAppGroup["hostPoolName"].ToString() + "/AppGroups/" + rdMgmtAppGroup["appGroupName"].ToString(), content).Result;
                string strJson = response.Content.ReadAsStringAsync().Result;
                if (response.IsSuccessStatusCode)
                {
                    groupResult.Add("isSuccess", true);
                    groupResult.Add("message", "App group '" + rdMgmtAppGroup["appGroupName"].ToString() + "' has been created successfully.");
                }
                else if ((int)response.StatusCode == 429)
                {
                    groupResult.Add("isSuccess", false);
                    groupResult.Add("message", strJson + " Please try again later.");
                }
                else
                {

                    if (!string.IsNullOrEmpty(strJson))
                    {
                        groupResult.Add("isSuccess", false);
                        groupResult.Add("message", CommonBL.GetErrorMessage(strJson));
                    }
                    else
                    {
                        groupResult.Add("isSuccess", false);
                        groupResult.Add("message", "AppGroup '" + rdMgmtAppGroup["appGroupName"].ToString() + "' has not been created. Please try it later again.");
                    }
                }
            }
            catch (Exception ex)
            {
                groupResult.Add("isSuccess", false);
                groupResult.Add("message", "AppGroup '" + rdMgmtAppGroup["appGroupName"].ToString() + "' has not been created." + ex.Message.ToString() + " Please try it later again.");
            }
            return groupResult;
        }

        /// <summary>
        /// Description : Updates an AppGroup within a Tenant, and HostPool associated with the specified Rds context.
        /// </summary>
        /// <param name="deploymentUrl">RD Broker Url</param>
        /// <param name="accessToken">Access Token</param>
        /// <param name="rdMgmtAppGroup">App Group Class </param>
        /// <returns></returns>
        public JObject UpdateAppGroup(string deploymentUrl, string accessToken, JObject rdMgmtAppGroup)
        {
            try
            {

                //call rest service to update app group details 
                var content = new StringContent(JsonConvert.SerializeObject(rdMgmtAppGroup), Encoding.UTF8, "application/json");
                HttpResponseMessage response = CommonBL.PatchAsync(deploymentUrl, accessToken, "/RdsManagement/V1/TenantGroups/" + rdMgmtAppGroup["tenantGroupName"].ToString() + "/Tenants/" + rdMgmtAppGroup["tenantName"].ToString() + "/HostPools/" + rdMgmtAppGroup["hostPoolName"].ToString() + "/AppGroups/" + rdMgmtAppGroup["appGroupName"].ToString(), content).Result;
                string strJson = response.Content.ReadAsStringAsync().Result;
                if (response.IsSuccessStatusCode)
                {
                    //Deserialize the string to JSON object
                    groupResult.Add("isSuccess", true);
                    groupResult.Add("message", "App group '" + rdMgmtAppGroup["appGroupName"].ToString() + "' has been updated successfully.");
                }
                else if ((int)response.StatusCode == 429)
                {
                    groupResult.Add("isSuccess", false);
                    groupResult.Add("message", strJson + " Please try again later.");
                }
                else
                {
                    if (!string.IsNullOrEmpty(strJson))
                    {
                        groupResult.Add("isSuccess", false);
                        groupResult.Add("message", CommonBL.GetErrorMessage(strJson));
                    }
                    else
                    {
                        groupResult.Add("isSuccess", false);
                        groupResult.Add("message", "AppGroup '" + rdMgmtAppGroup["appGroupName"].ToString() + "' has not been updated. Please try it later again.");
                    }
                }
            }
            catch (Exception ex)
            {
                groupResult.Add("isSuccess", false);
                groupResult.Add("message", "AppGroup '" + rdMgmtAppGroup["appGroupName"].ToString() + "' has not been updated." + ex.Message.ToString() + " Please try it later again.");
            }
            return groupResult;
        }

        /// <summary>
        /// Description : Removes an user from an AppGroup within a Tenant, HostPool and AppGroup associated with the specified Rds context
        /// </summary>
        /// <param name="deploymentURL">Rd Broker Url</param>
        /// <param name="accessToken"> Access token</param>
        /// <param name="tenantName">Name of Tenant</param>
        /// <param name="hostPoolName">Name of Hostpool </param>
        /// <param name="appGroupName">Name of App Group</param>
        /// <param name="appGroupUser">Login ID of AAD User</param>
        /// <returns></returns>
        public JObject DeleteAppGroupUser(string tenantGroupName, string deploymentUrl, string accessToken, string tenantName, string hostPoolName, string appGroupName, string appGroupUser)
        {
            try
            {
                //call rest service to remove user from App group
                HttpResponseMessage response = CommonBL.InitializeHttpClient(deploymentUrl, accessToken).DeleteAsync("/RdsManagement/V1/TenantGroups/" + tenantGroupName + "/Tenants/" + tenantName + "/HostPools/" + hostPoolName + "/AppGroups/" + appGroupName + "/AssignedUsers/" + appGroupUser).Result;
                string strJson = response.Content.ReadAsStringAsync().Result;
                if (response.IsSuccessStatusCode)
                {
                    groupResult.Add("isSuccess", true);
                    groupResult.Add("message", "User '" + appGroupUser + "' has been removed from app group " + appGroupName + " successfully.");
                }
                else if ((int)response.StatusCode == 429)
                {
                    groupResult.Add("isSuccess", false);
                    groupResult.Add("message", strJson + " Please try again later.");
                }
                else
                {
                    if (!string.IsNullOrEmpty(strJson))
                    {
                        groupResult.Add("isSuccess", false);
                        groupResult.Add("message", CommonBL.GetErrorMessage(strJson));
                    }
                    else
                    {
                        groupResult.Add("isSuccess", false);
                        groupResult.Add("message", "User '" + appGroupUser + "' has not been removed. Please try it later again.");
                    }
                }
            }
            catch (Exception ex)
            {
                groupResult.Add("isSuccess", false);
                groupResult.Add("message", "User '" + appGroupUser + "' has not been removed." + ex.Message.ToString() + " and try again later.");
            }
            return groupResult;
        }

        /// <summary>
        /// Description : Adds a user to an AppGroup within Tenant and HostPool associated with the specified Rds context.
        /// </summary>
        /// <param name="deploymentUrl">RD Broker Url</param>
        /// <param name="accessToken"> Access Token</param>
        /// <param name="rdMgmtUser"> App Group user claass</param>
        /// <returns></returns>
        public JObject CreateAppGroupUser(string deploymentUrl, string accessToken, JObject rdMgmtUser)
        {
            try
            {
                //call rest service to add user to app group - july code bit
                var content = new StringContent(JsonConvert.SerializeObject(rdMgmtUser), Encoding.UTF8, "application/json");
                HttpResponseMessage response = CommonBL.InitializeHttpClient(deploymentUrl, accessToken).PostAsync("/RdsManagement/V1/TenantGroups/" + rdMgmtUser["tenantGroupName"].ToString() + "/Tenants/" + rdMgmtUser["tenantName"].ToString() + "/HostPools/" + rdMgmtUser["hostPoolName"].ToString() + "/AppGroups/" + rdMgmtUser["appGroupName"].ToString() + "/AssignedUsers/" + rdMgmtUser["userPrincipalName"].ToString(), content).Result;
                string strJson = response.Content.ReadAsStringAsync().Result;
                if (response.IsSuccessStatusCode)
                {
                    groupResult.Add("isSuccess", true);
                    groupResult.Add("message", "User '" + rdMgmtUser["userPrincipalName"].ToString() + "' has been added to app group " + rdMgmtUser["appGroupName"].ToString() + " successfully.");
                }
                else if ((int)response.StatusCode == 429)
                {
                    groupResult.Add("isSuccess", false);
                    groupResult.Add("message", strJson + " Please try again later.");
                }
                else
                {
                    if (!string.IsNullOrEmpty(strJson))
                    {
                        groupResult.Add("isSuccess", false);
                        groupResult.Add("message", CommonBL.GetErrorMessage(strJson));
                    }
                    else
                    {
                        groupResult.Add("isSuccess", false);
                        groupResult.Add("message", "User '" + rdMgmtUser["userPrincipalName"].ToString() + "' has not been added to app group. Please try it later again. ");
                    }
                }
            }
            catch (Exception ex)
            {
                groupResult.Add("isSuccess", false);
                groupResult.Add("message", "User '" + rdMgmtUser["userPrincipalName"].ToString() + "' has not been added to app group " + ex.Message.ToString() + " Please try again later.");
            }
            return groupResult;
        }

        /// <summary>
        /// Description Description : Removes an user from an AppGroup within a Tenant, HostPool and AppGroup associated with the specified Rds context
        /// </summary>
        /// <param name="deploymentURL">RD Broker Url</param>
        /// <param name="accessToken">Access Token</param>
        /// <param name="tenantName">Name of tenant</param>
        /// <param name="hostpoolName">Name of Hostpool</param>
        /// <param name="appGroupName">Name of AppGroup</param>
        /// <returns></returns>
        public JObject DeleteAppGroup(string tenantGroupName, string deploymentURL, string accessToken, string tenantName, string hostpoolName, string appGroupName)
        {
            try
            {
                //call rest service to delete app group - july code bit
                HttpResponseMessage response = CommonBL.InitializeHttpClient(deploymentURL, accessToken).DeleteAsync("/RdsManagement/V1/TenantGroups/" + tenantGroupName + "/Tenants/" + tenantName + "/HostPools/" + hostpoolName + "/AppGroups/" + appGroupName).Result;
                string strJson = response.Content.ReadAsStringAsync().Result;
                if (response.IsSuccessStatusCode)
                {
                    groupResult.Add("isSuccess", true);
                    groupResult.Add("message", "App group '" + appGroupName + "' has been deleted successfully.");
                }
                else if ((int)response.StatusCode == 429)
                {
                    groupResult.Add("isSuccess", false);
                    groupResult.Add("message", strJson + " Please try again later.");
                }
                else
                {
                    if (!string.IsNullOrEmpty(strJson))
                    {
                        groupResult.Add("isSuccess", false);
                        groupResult.Add("message", CommonBL.GetErrorMessage(strJson));
                    }
                    else
                    {
                        groupResult.Add("isSuccess", false);
                        groupResult.Add("message", "AppGroup '" + appGroupName + "' has not been deleted . Please try it again later.");
                    }
                }
            }
            catch (Exception ex)
            {
                groupResult.Add("isSuccess", false);
                groupResult.Add("message", "AppGroup '" + appGroupName + "' has not been deleted." + ex.Message.ToString() + "Please try it again later.");
            }
            return groupResult;
        }
    }
    #endregion  "Class - AppGroupBL"
}
#endregion "MSFT.RDMISaaS.API.BLL" 