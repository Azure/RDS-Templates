using Microsoft.Extensions.Configuration;
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json.Linq;

namespace MSFT.WVD.Diagnostics.Common.Services
{
    public class CommonService
    {
        IConfiguration _config;
        ILogger _logger;

        public CommonService(IConfiguration configuration, ILoggerFactory logger)
        {
            _logger = logger?.CreateLogger<DiagnozeService>() ?? throw new ArgumentNullException(nameof(logger));
            _config = configuration ?? throw new ArgumentNullException(nameof(configuration));
        }

        public string GetAccessTokenLogAnalytic(string refreshToken)
        {
            _logger.LogInformation("Get Access token using refresh token for log analytics api. ");
            HttpResponseMessage response;
            Dictionary<string, string> requestdata = new Dictionary<string, string>();
            var url = _config["configurations:AAD_Token_URL"];
            requestdata.Add("grant_type", "refresh_token");
            requestdata.Add("resource", _config["configurations:LogAnalytic_URL"]);
            requestdata.Add("refresh_token", refreshToken);
            requestdata.Add("client_id", _config["AzureAd:ClientId"]);
            requestdata.Add("client_secret", _config["AzureAd:ClientSecret"]);
            using (HttpClient client = new HttpClient())
            {
                client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
                response = client.PostAsync(url, new FormUrlEncodedContent(requestdata)).Result;
                var tokenval = response.Content.ReadAsStringAsync().Result;
                JObject obj = JObject.Parse(tokenval);
                var accesstoken = (string)obj["access_token"];
                return accesstoken;
            }
        }

        public string GetAccessTokenWVD(string refreshToken)
        {
            _logger.LogInformation("Get Access token using refresh token for WVD API. ");
            HttpResponseMessage response;
            Dictionary<string, string> requestdata = new Dictionary<string, string>();
            var url = _config["configurations:AAD_Token_URL"];
            requestdata.Add("grant_type", "refresh_token");
            requestdata.Add("auth_url", _config["configurations:AAD_AUTH_URL"]);
            requestdata.Add("resource", _config["configurations:RESOURCE_URL"]);
            requestdata.Add("client_id", _config["AzureAd:ClientId"]);
            requestdata.Add("client_secret", _config["AzureAd:ClientSecret"]);
            requestdata.Add("refresh_token", refreshToken);
            using (HttpClient client = new HttpClient())
            {
                client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
                response = client.PostAsync(url, new FormUrlEncodedContent(requestdata)).Result;
                var tokenval = response.Content.ReadAsStringAsync().Result;
                JObject obj = JObject.Parse(tokenval);
                var accesstoken = (string)obj["access_token"];
                return accesstoken;
            }
        }

    }
}
