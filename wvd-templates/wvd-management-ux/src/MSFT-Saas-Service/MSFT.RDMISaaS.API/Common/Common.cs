#region "Import Namespaces"
using MSFT.WVDSaaS.API.Model;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Web;
using System.Web.Configuration;
using System.IdentityModel.Tokens.Jwt;
using MSFT.WVDSaaS.API.BLL;
using System.Threading.Tasks;

#endregion "Import Namespaces"

#region "MSFT.RDMISaaS.API.Common"
namespace MSFT.WVDSaaS.API.Common

{

    #region "Common"
    public class Common
    {
        #region "Class level declaration"

        Configurations configurations = new Configurations();
        AuthorizationBL authorizationBL = new AuthorizationBL();
        #endregion



        #region "Functions/Methods"
        /// <summary>
        /// Description - Get access token from code
        /// </summary>
        /// <param name="code"></param>
        /// <returns></returns>
        public string GetAccessToken(string code)
        {
            try
            {
                HttpResponseMessage response;
                Dictionary<string, string> requestdata = new Dictionary<string, string>();
                var url = configurations.aadTokenUrl;
                requestdata.Add("redirect_uri", configurations.redirectUrl);
                requestdata.Add("grant_type", "authorization_code");
                requestdata.Add("resource", configurations.resourceUrl);
                requestdata.Add("code", code);
                requestdata.Add("client_id", configurations.applicationId);
                requestdata.Add("client_secret", configurations.clientSecret);
                using (HttpClient client = new HttpClient())
                {
                    client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
                    response = client.PostAsync(url, new FormUrlEncodedContent(requestdata)).Result;
                    var tokenval = response.Content.ReadAsStringAsync().Result;
                    return tokenval;
                }
            }
            catch (Exception ex)
            {
                return Constants.invalidCode.ToString();
            }
        }

        /// <summary>
        /// Description - Get access token using refresh token
        /// </summary>
        /// <param name="refreshToken"></param>
        /// <returns></returns>
        public string GetAccessTokenByRefreshToken(string refreshToken)
        {
            try
            {
                HttpResponseMessage response;
                Dictionary<string, string> requestdata = new Dictionary<string, string>();
                var url = configurations.aadTokenUrl;
                requestdata.Add("redirect_uri", configurations.redirectUrl);
                requestdata.Add("grant_type", "refresh_token");
                requestdata.Add("resource", configurations.resourceUrl);
                requestdata.Add("refresh_token", refreshToken);
                requestdata.Add("client_id", configurations.applicationId);
                requestdata.Add("client_secret", configurations.clientSecret);
                using (HttpClient client = new HttpClient())
                {
                    client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
                    response = client.PostAsync(url, new FormUrlEncodedContent(requestdata)).Result;
                    var tokenval = response.Content.ReadAsStringAsync().Result;
                    return tokenval;
                }
            }
            catch
            {
                return Constants.invalidCode.ToString();
            }
        }


        public string GetAccessTokenByRefreshTokenManagement(string refreshToken)
        {
            try
            {
                HttpResponseMessage response;
                Dictionary<string, string> requestdata = new Dictionary<string, string>();
                var url = configurations.aadTokenUrl;
                requestdata.Add("grant_type", "refresh_token");
                requestdata.Add("resource", configurations.managementResourceUrl);
                requestdata.Add("refresh_token", refreshToken);
                requestdata.Add("client_id", configurations.applicationId);
                requestdata.Add("client_secret", configurations.clientSecret);
                using (HttpClient client = new HttpClient())
                {
                    client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
                    response = client.PostAsync(url, new FormUrlEncodedContent(requestdata)).Result;
                    var tokenval = response.Content.ReadAsStringAsync().Result;
                    return tokenval;
                }
            }
            catch (Exception ex)
            {
                return Constants.invalidCode.ToString();
            }
        }
        /// <summary>
        /// Description : Get login details from code
        /// </summary>
        /// <param name="userName"></param>
        /// <returns></returns>
        public async Task<Login> Login(string Code)
        {
            Login loginDetails = new Login();
            try
            {
                string token = GetAccessToken(Code);
                if(token!=Constants.invalidCode && token != Constants.invalidToken)
                {
                    loginDetails = JsonConvert.DeserializeObject<Login>(token);
                    var handler = new JwtSecurityTokenHandler();
                    var tokenS = handler.ReadToken(loginDetails.Access_Token) as JwtSecurityToken;
                    loginDetails.UserName = tokenS.Claims.First(claim => claim.Type.Equals("name")).Value.ToString();
                    loginDetails.Email = tokenS.Claims.First(claim => claim.Type.Equals("unique_name")).Value;
                    loginDetails.Code = "";

                    // to get role assignment
                    if (loginDetails != null && loginDetails.Access_Token != null)
                    {
                        string deploymentUrl = configurations.rdBrokerUrl;
                        List<string> list = new List<string>();
                        HttpResponseMessage httpResponse = await authorizationBL.GetRoleAssignments(deploymentUrl, loginDetails.Access_Token, loginDetails.Email.ToString());
                        string strJson = httpResponse.Content.ReadAsStringAsync().Result;

                        if (httpResponse.IsSuccessStatusCode)
                        {
                            loginDetails.RoleAssignment = (JArray)JsonConvert.DeserializeObject(strJson);
                            for (int i = 0; i < loginDetails.RoleAssignment.Count; i++)
                            {
                               // loginDetails.RoleAssignment = new JObject() { { "roleDefinitionName", rdMgmtRoleAssignments[i]["roleDefinitionName"].ToString() }, { "scope", rdMgmtRoleAssignments[i]["scope"].ToString() } };
                                if (loginDetails.RoleAssignment[i]["signInName"] != null && loginDetails.RoleAssignment[i]["signInName"].ToString().ToLower() == loginDetails.Email.ToString().ToLower())
                                {
                                    if (loginDetails.RoleAssignment[i]["scope"].ToString().Split('/').Length > 1)
                                    {
                                        list.Add(loginDetails.RoleAssignment[i]["scope"].ToString().Split('/')[1].ToString());
                                    }
                                    else
                                    {
                                        list.Add(Constants.tenantGroupName);
                                    }
                                }
                            }
                            loginDetails.TenantGroups = list.ToArray();
                        }
                        else if ((int)httpResponse.StatusCode == 429)
                        {
                            loginDetails.Error = new JObject() { { "StatusCode", httpResponse.StatusCode.ToString() }, { "Message", strJson } };
                        }
                        else
                        {
                            loginDetails.Error = new JObject() { { "StatusCode", httpResponse.StatusCode.ToString() }, { "Message", strJson } };
                        }
                    }
                    else
                    {
                        return null;
                    }
                }
                else
                {
                    loginDetails.Error = new JObject() { { "StatusCode", (int)HttpStatusCode.BadRequest }, { "Message", Constants.invalidCode } };
                }
                return loginDetails;
            }
            catch (Exception ex)
            {
                loginDetails.Error = new JObject() { { "StatusCode", (int)HttpStatusCode.BadRequest }, { "Message", Constants.invalidCode } };
                return loginDetails;
            }
        }

        /// <summary>
        ///  Description : Get login details from code
        /// </summary>
        /// <param name="code"></param>
        /// <returns></returns>
        public string GetRefreshTokenValue(string code)
        {
            string refresh_token = "";
            string token = GetAccessToken(code);
            if (!string.IsNullOrEmpty(token))
            {
                if (token.ToString().ToLower() == Constants.invalidCode.ToString().ToLower())
                {
                    refresh_token = Constants.invalidCode;
                }
                else
                {
                    TokenDetails tokenDetails = Newtonsoft.Json.JsonConvert.DeserializeObject<TokenDetails>(token);
                    if (tokenDetails != null)
                    {
                        refresh_token = tokenDetails.refresh_token;
                    }
                    else
                    {
                        refresh_token = Constants.invalidToken;
                    }
                }
            }
            else
            {
                refresh_token = Constants.invalidToken;
            }
            return refresh_token;
        }

        /// <summary>
        /// Description - Get Access token value
        /// </summary>
        /// <param name="refreshToken"></param>
        /// <returns></returns>
        public string GetTokenValue(string refreshToken)
        {
            string access_token = "";
            string token = GetAccessTokenByRefreshToken(refreshToken);
            TokenDetails tokenDetails = new TokenDetails();
            if (!string.IsNullOrEmpty(token))
            {
                if (token.ToString().ToLower() == Constants.invalidCode.ToString().ToLower())
                {
                    tokenDetails.access_token = Constants.invalidCode;
                }
                else
                {
                    tokenDetails = Newtonsoft.Json.JsonConvert.DeserializeObject<TokenDetails>(token);
                    if (tokenDetails != null)
                    {
                        access_token = tokenDetails.access_token;
                    }
                    else
                    {
                        access_token = Constants.invalidToken;
                    }
                }
            }
            else
            {
                access_token = Constants.invalidToken;
            }
            return access_token;
        }


        public string GetManagementTokenValue(string refreshToken)
        {
            string access_token = "";
            string token = GetAccessTokenByRefreshTokenManagement(refreshToken);
            TokenDetails tokenDetails = new TokenDetails();
            if (!string.IsNullOrEmpty(token))
            {
                if (token.ToString().ToLower() == Constants.invalidCode.ToString().ToLower())
                {
                    tokenDetails.access_token = Constants.invalidCode;
                }
                else
                {
                    tokenDetails = Newtonsoft.Json.JsonConvert.DeserializeObject<TokenDetails>(token);
                    if (tokenDetails != null)
                    {
                        access_token = tokenDetails.access_token;
                    }
                    else
                    {
                        access_token = Constants.invalidToken;
                    }
                }
            }
            else
            {
                access_token = Constants.invalidToken;
            }
            return access_token;
        }
        #endregion

    }
    #endregion "Common"
}
#endregion "MSFT.RDMISaaS.API.Common"
