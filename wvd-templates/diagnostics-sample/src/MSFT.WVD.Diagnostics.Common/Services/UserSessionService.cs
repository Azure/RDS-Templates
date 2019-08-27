using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using MSFT.WVD.Diagnostics.Common.Models;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;

namespace MSFT.WVD.Diagnostics.Common.Services
{
    public class UserSessionService
    {
        IConfiguration _config;
        string _brokerUrl;
        ILogger _logger;
        IMemoryCache _cache;

        public UserSessionService(IConfiguration configuration, ILoggerFactory logger, IMemoryCache memoryCache)
        {
            _logger = logger?.CreateLogger<UserSessionService>() ?? throw new ArgumentNullException(nameof(logger));
            _config = configuration ?? throw new ArgumentNullException(nameof(configuration));
            _cache = memoryCache ?? throw new ArgumentException(nameof(memoryCache));
            
            _brokerUrl = _config["configurations:RDBROKER_URL"];
            if (string.IsNullOrEmpty(_brokerUrl))
            {
                _logger.LogError("Missing configurations:RDBROKER_URL");
                //throw new ConfigurationErrorsException("Missing RDSManagement:RDBROKER_URL");
                throw new Exception("Missing configurations:RDBROKER_URL");
            }
        }
        public async Task<List<UserSession>> GetUserSessions(string accessToken, string tenantGroupName, string tenant, string hostPoolName, string hostName)
        {
            var key = new Tuple<string, string, string, string, string, string>(nameof(GetUserSessions), accessToken, tenantGroupName, tenant, hostPoolName, hostName);
            var result = await _cache.GetOrCreateAsync(key, async entry =>
             {
                 var url = string.Empty;
                 url = $"{_brokerUrl}RdsManagement/V1/TenantGroups/{tenantGroupName}/Tenants/{tenant}/HostPools/{hostPoolName}/Sessions";
                 var reply = await SendRequest(url, accessToken).ConfigureAwait(false);

                 // Set cache expiration
                 entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromHours(2);
                 return reply;

             }).ConfigureAwait(false);
            if (result.StatusCode == HttpStatusCode.OK)
            {
                var data = await result.Content.ReadAsStringAsync().ConfigureAwait(false);
                var arr = (JArray)JsonConvert.DeserializeObject(data);
                return ((JArray)arr).Select(item => new UserSession
                {
                    tenantGroupName = (string)item["tenantGroupName"],
                    tenantName = (string)item["tenantName"],
                    hostPoolName = (string)item["hostPoolName"],
                    sessionHostName = (string)item["sessionHostName"],
                    userPrincipalName = (string)item["userPrincipalName"],
                    sessionId = (int)item["sessionId"],
                    applicationType = (string)item["applicationType"],
                    adUserName = (string)item["adUserName"],
                    httpStatus=result.StatusCode
                }).ToList().Where(x => x.sessionHostName.ToString() == hostName).ToList();
            }
            else
            {
                _logger.LogError("No user sessions found.");
                return new List<UserSession>() {
                    new UserSession()
                    {
                        httpStatus=result.StatusCode
                    }
                };
            }

        }
        private async Task<HttpResponseMessage> SendRequest(string url, string accessToken)
        {
            return await Request(HttpMethod.Get, url, accessToken);
        }
        public async Task<string> SendMessage(string accessToken, SendMessageQuery sendMessageQuery)
        {
            _logger.LogInformation($"Enter into service call to send message to {sendMessageQuery.userPrincipalName}");

            var key = sendMessageQuery;
            var result = await _cache.GetOrCreateAsync(key, async entry =>
            {
                var url = "";
                var Content = new StringContent(JsonConvert.SerializeObject(sendMessageQuery), Encoding.UTF8, "application/json");
                url = $"{_brokerUrl}RdsManagement/V1/TenantGroups/{sendMessageQuery.tenantGroupName}/Tenants/{sendMessageQuery.tenantName}/HostPools/{sendMessageQuery.hostPoolName}/SessionHosts/{sendMessageQuery.sessionHostName}/Sessions/{sendMessageQuery.sessionId}/actions/send-message-user?MessageTitle={sendMessageQuery.messageTitle.ToString()}&MessageBody={sendMessageQuery.messageBody.ToString()}";
                var reply = await PostRequest(url, JsonConvert.SerializeObject(sendMessageQuery), accessToken).ConfigureAwait(false);
                // Set cache expiration
                entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromHours(2);
                return reply;
            }).ConfigureAwait(false);
            return result;
        }
        public async Task<string> LogOffUserSession(string accessToken, LogOffUserQuery logOffUserQuery)
        {
            _logger.LogInformation($"Enter into service call to log off user session of {logOffUserQuery.sessionId}");

            var key = logOffUserQuery;
            var result = await _cache.GetOrCreateAsync(key, async entry =>
            {
                var url = string.Empty;
                var Content = new StringContent(JsonConvert.SerializeObject(logOffUserQuery), Encoding.UTF8, "application/json");
                url = $"{_brokerUrl}RdsManagement/V1/TenantGroups/{logOffUserQuery.tenantGroupName}/Tenants/{logOffUserQuery.tenantName}/HostPools/{logOffUserQuery.hostPoolName}/SessionHosts/{logOffUserQuery.sessionHostName}/Sessions/{logOffUserQuery.sessionId}/actions/logoff-user";
                var reply = await PostRequest(url, JsonConvert.SerializeObject(logOffUserQuery), accessToken).ConfigureAwait(false);
                // Set cache expiration
                entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromHours(2);
                return reply;
            }).ConfigureAwait(false);
            return result;
        }


        private async Task<string> PostRequest(string url, string body, string accessToken)
        {
            var activityId = Guid.NewGuid().ToString();
            _logger.LogInformation($"RDS Management api call to post request to url {url}. Activity Id:{activityId}");
            using (var client = new HttpClient())
            {
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
                client.DefaultRequestHeaders.Add("x-ms-correlation-id", activityId);
                HttpRequestMessage request = new HttpRequestMessage(HttpMethod.Post, url);
                StringContent content = new StringContent(body);
                content.Headers.ContentType = new MediaTypeHeaderValue("application/json");
                request.Content = content;
                HttpResponseMessage response = await client.SendAsync(request);
                _logger.LogInformation($"Received response from ActivityId:{activityId} Status:{response.StatusCode}");
                return response.ReasonPhrase;
            }
        }
        private async Task<HttpResponseMessage> Request(HttpMethod httpMethod, string url, string accessToken)
        {
            var activityId = Guid.NewGuid().ToString();
            _logger.LogInformation($"Sending RDS Management request to {url}. ActivityId:{activityId}");
            using (var client = new HttpClient())
            {

                client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
                client.DefaultRequestHeaders.Add("x-ms-correlation-id", activityId);
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
                HttpRequestMessage request = new HttpRequestMessage(httpMethod, url);
                HttpResponseMessage response = await client.SendAsync(request);
                _logger.LogInformation($"Received response from ActivityId:{activityId} Status:{response.StatusCode}");
                return response;
            }
        }
    }
}
