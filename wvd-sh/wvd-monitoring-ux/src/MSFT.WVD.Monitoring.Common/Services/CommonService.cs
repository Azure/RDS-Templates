using Microsoft.Extensions.Configuration;
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using Microsoft.Extensions.Logging;

namespace MSFT.WVD.Monitoring.Common.Services
{
    public class CommonService
    {
     
        private const string tokenUrl = "https://login.microsoftonline.com//common/oauth2/token";
     
        public string GetAccessToken(string refreshToken,string logAnalyticUrl)
        {

            HttpResponseMessage response;
            Dictionary<string, string> requestdata = new Dictionary<string, string>();
            var url = tokenUrl;
            requestdata.Add("grant_type", "refresh_token");
            requestdata.Add("resource", logAnalyticUrl);
            requestdata.Add("refresh_token", refreshToken);
            using (HttpClient client = new HttpClient())
            {
                client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
                response = client.PostAsync(url, new FormUrlEncodedContent(requestdata)).Result;
                return response.Content.ReadAsStringAsync().Result;
            }
        }
    }
}
