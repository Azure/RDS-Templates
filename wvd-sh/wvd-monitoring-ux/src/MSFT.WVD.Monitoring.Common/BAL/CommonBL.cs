using MSFT.WVD.Monitoring.Common.Models;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Web;

namespace MSFT.WVD.Monitoring.Common
{
    public class CommonBL
    {
        public HttpResponseMessage GetAccessToken(string code, ConfigSettings config)
        {
            HttpResponseMessage response;
            try
            {
                Dictionary<string, string> requestdata = new Dictionary<string, string>();
                var url = config.TokenEndPoint;
                requestdata.Add("redirect_uri", config.RedirectUrl);
                requestdata.Add("grant_type", "authorization_code");
                requestdata.Add("resource", config.ResopurceUrl);
                requestdata.Add("client_id", config.ApplicationID);
                requestdata.Add("code", code);
                using (HttpClient client = new HttpClient())
                {
                    client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
                    response = client.PostAsync(url, new FormUrlEncodedContent(requestdata)).Result;
                    return response;
                }
            }
            catch (Exception ex)
            {
                return new HttpResponseMessage() { StatusCode=HttpStatusCode.InternalServerError,Content= new StringContent( ex.Message.ToString()) }; 
            }
           
        }

        public static HttpClient InitializeHttpClient(string deploymentUrl, string accessToken)
        {
            HttpClient client = new HttpClient();
            client.BaseAddress = new Uri(deploymentUrl);
            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
            client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
            client.Timeout = TimeSpan.FromMinutes(30);
            return client;
        }

        public HttpResponseMessage GetAccessTokenByRefreshToken(string refreshToken,ConfigSettings config)
        {
            HttpResponseMessage response;
            try
            {
                Dictionary<string, string> requestdata = new Dictionary<string, string>();
                var url = config.TokenEndPoint;
                requestdata.Add("redirect_uri", config.RedirectUrl);
                requestdata.Add("grant_type", "refresh_token");
                requestdata.Add("resource", config.ResopurceUrl);
                requestdata.Add("client_id", config.ApplicationID);
                requestdata.Add("refresh_token", refreshToken);
                using (HttpClient client = new HttpClient())
                {
                    client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
                    response = client.PostAsync(url, new FormUrlEncodedContent(requestdata)).Result;
                    return response;
                }
            }
            catch (Exception ex)
            {
                return new HttpResponseMessage() { StatusCode = HttpStatusCode.InternalServerError, Content = new StringContent(ex.Message.ToString()) }; //Constants.invalidCode.ToString();
            }
        }

        public string GetRefreshTokenValue(string code,ConfigSettings config)
        {
            string refresh_token = "";
            HttpResponseMessage httpResponseMessage  = GetAccessToken(code, config);
            if(httpResponseMessage.IsSuccessStatusCode)
            {
               string token = httpResponseMessage.Content.ReadAsStringAsync().Result;
                if (!string.IsNullOrEmpty(token))
                {
                    if (token.ToString().ToLower() == Constants.invalidCode.ToString().ToLower()) 
                    {
                        refresh_token = Constants.invalidCode;
                    }
                    else
                    {
                        JObject tokenDetails = Newtonsoft.Json.JsonConvert.DeserializeObject<JObject>(token);
                        if (tokenDetails != null)
                        {
                            refresh_token = tokenDetails["refresh_token"].ToString();
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
            }
            else
            {
                refresh_token = Constants.invalidToken;
            }
            return refresh_token;
        }

        public string GetTokenValue(string refreshToken,ConfigSettings config)
        {
            string access_token = "";
           HttpResponseMessage httpResponseMessage = GetAccessTokenByRefreshToken(refreshToken, config);
            if(httpResponseMessage.IsSuccessStatusCode)
            {
                string token = httpResponseMessage.Content.ReadAsStringAsync().Result;
                JObject tokenDetails = new JObject();
                if (!string.IsNullOrEmpty(token))
                {
                    if (token.ToString().ToLower() == Constants.invalidCode.ToString())
                    {
                        tokenDetails.Add("access_token", Constants.invalidCode);
                    }
                    else
                    {
                        tokenDetails = Newtonsoft.Json.JsonConvert.DeserializeObject<JObject>(token);
                        if (tokenDetails != null)
                        {
                            access_token = tokenDetails["access_token"].ToString();
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
            }
            else
            {

            }
          
            return access_token;
        }
    }
}
