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
    public class RoleAssignmentService
    {
        IConfiguration _config;
        string _brokerUrl;
        ILogger _logger;
        IMemoryCache _cache;
        
        public RoleAssignmentService(IConfiguration configuration, ILoggerFactory logger, IMemoryCache memoryCache)
        {
            _logger = logger?.CreateLogger<RoleAssignmentService>() ?? throw new ArgumentNullException(nameof(logger));
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

        public async Task<List<RoleAssignment>> GetRoleAssignments(string accessToken, string upn)
        {
            var key = new Tuple<string,string,string>(nameof(GetRoleAssignments), accessToken,upn);
            var result = await _cache.GetOrCreateAsync(key, async entry =>
            {
                var url = string.Empty;
                url = $"{_brokerUrl}RdsManagement/V1/Rds.Authorization/roleAssignments?upn={upn}";
                var reply = await SendRequest(url, accessToken).ConfigureAwait(false);

                // Set cache expiration
                entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromHours(2);
                return reply;

            }).ConfigureAwait(false);
            if (result.StatusCode == HttpStatusCode.OK)
            {
                var data = await result.Content.ReadAsStringAsync().ConfigureAwait(false);
                var arr = (JArray)JsonConvert.DeserializeObject(data);
                return ((JArray)arr).Select(item => new RoleAssignment
                {
                    tenantGroupName = item["scope"].ToString().Split("/").Length>1? item["scope"].ToString().Split("/")[1]: item["scope"].ToString().Split("/")[0]==""?"Default Tenant Group": item["scope"].ToString().Split("/")[0],
                    roleAssignmentId = (string)item["roleAssignmentId"],
                    scope = (string)item["scope"],
                    displayName = (string)item["displayName"]==null?item["signInName"].ToString().Split("@")[0]: item["displayName"].ToString(),
                    signInName = (string)item["signInName"],
                    roleDefinitionName = (string)item["roleDefinitionName"],
                    roleDefinitionId = (string)item["roleDefinitionId"],
                    objectId = (string)item["objectId"],
                    objectType = (string)item["objectType"]
                }).ToList();
            }
            else
            {
                _logger.LogError("No role assignments found.");
                return null;
            }

        }

        private async Task<HttpResponseMessage> SendRequest(string url, string accessToken)
        {
            return await Request(HttpMethod.Get, url, accessToken);
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
