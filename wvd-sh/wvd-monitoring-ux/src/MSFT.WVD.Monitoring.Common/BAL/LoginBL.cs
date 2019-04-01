using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Net;
using System.Text;
using System.Threading.Tasks;

using MSFT.WVD.Monitoring.Common.Models;
using System.Net.Http;
using Microsoft.IdentityModel.Tokens;

namespace MSFT.WVD.Monitoring.Common.BAL
{
    public class LoginBL
    {
        CommonBL CommonBL = new CommonBL();
        RoleAssignmentBL roleAssignmentBL = new RoleAssignmentBL();
        public LoginDetails Login(string Code, ConfigSettings config)
        {
            LoginDetails loginDetails = new LoginDetails();
            try
            {
                HttpResponseMessage httpResponseMessage = CommonBL.GetAccessToken(Code, config);
                if (httpResponseMessage.IsSuccessStatusCode)
                {
                    string token = httpResponseMessage.Content.ReadAsStringAsync().Result;
                    if (token.ToLower() != Constants.invalidCode && token.ToLower() != Constants.invalidToken)
                    {
                        loginDetails = JsonConvert.DeserializeObject<LoginDetails>(token);
                        SecurityTokenHandler handler = new JwtSecurityTokenHandler();
                        var tokenS = handler.ReadToken(loginDetails.access_token);
                        loginDetails.name = ((System.IdentityModel.Tokens.Jwt.JwtSecurityToken)tokenS).Claims.First(claim => claim.Type.Equals("name")).Value;
                        loginDetails.upn = ((System.IdentityModel.Tokens.Jwt.JwtSecurityToken)tokenS).Claims.First(claim => claim.Type.Equals("upn")).Value;
                        //get roleassigment
                        HttpResponseMessage httpResponse = roleAssignmentBL.GetRoleAssignments(config.RDBrokerUrl, loginDetails.access_token, loginDetails.upn);
                        if (httpResponse.IsSuccessStatusCode)
                        {
                            loginDetails.roleAssignments = (JArray)JsonConvert.DeserializeObject(httpResponse.Content.ReadAsStringAsync().Result);
                            if (loginDetails.roleAssignments != null && loginDetails.roleAssignments.Count > 0)
                            {
                                loginDetails.tenantGroups = new string[loginDetails.roleAssignments.Count];
                                for (int i = 0; i < loginDetails.roleAssignments.Count; i++)
                                {
                                    loginDetails.tenantGroups[i] = loginDetails.roleAssignments[i]["scope"].ToString().Split('/').Length > 1 ? loginDetails.roleAssignments[i]["scope"].ToString().Split('/')[1].ToString() : Constants.tenantGroupName;
                                }
                            }
                        }
                    }
                    else
                    {
                        loginDetails.error = new LoginError() { StatusCode = (int)HttpStatusCode.BadRequest, Message = Constants.invalidToken };
                    }
                    return loginDetails;
                }
                else
                {
                    return null;
                }
            }
            catch (Exception ex)
            {
                loginDetails.error = new LoginError() { StatusCode = (int)HttpStatusCode.InternalServerError, Message = ex.Message.ToString() };
                return loginDetails;
            }
        }
    }
}
