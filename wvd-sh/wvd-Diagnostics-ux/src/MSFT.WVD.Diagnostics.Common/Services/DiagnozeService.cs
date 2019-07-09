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
using System.Threading.Tasks;

namespace MSFT.WVD.Diagnostics.Common.Services
{
    public class DiagnozeService
    {
        IConfiguration _config;
        ILogger _logger;
        IMemoryCache _cache;
        string _brokerUrl;


        public DiagnozeService(IConfiguration configuration, ILoggerFactory logger, IMemoryCache memoryCache)
        {
            _logger = logger?.CreateLogger<DiagnozeService>() ?? throw new ArgumentNullException(nameof(logger));
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


        public async Task<List<ConnectionActivity>> GetConnectionActivities(string accessToken, string upn, string tenantGroupName, string tenant, string startDatetime, string endDatetime, string outcome)
        {
            _logger.LogInformation($"Service call to get connection activities of user {upn} of Tenant {tenant} within tenant group {tenantGroupName} ");

            // Here we will add user to the key
            var key = new Tuple<string, string, string, string, string, string, string>(nameof(GetConnectionActivities), upn, tenantGroupName, tenant, startDatetime, endDatetime, outcome);

            // Try to get from cache first
            var result = await _cache.GetOrCreateAsync(key, async entry =>
            {
                int activityType = (int)ActivityType.Connection;
                outcome = outcome == ActivityOutcome.All.ToString() ? null : outcome;
                var url = "";
                if (outcome == null)
                {
                    url = $"{_brokerUrl}RdsManagement/V1/DiagnosticActivities/TenantGroups/{tenantGroupName}/Tenants/{tenant}?UserName={upn}&StartTime={startDatetime}&EndTime={endDatetime}&ActivityType={activityType}&Detailed=true";//&PageSize=1000&SortField=StartTime&IsDescending=True";
                }
                else
                {
                    int outcomeVal = (int)Enum.Parse(typeof(ActivityOutcome), outcome);
                    url = $"{_brokerUrl}RdsManagement/V1/DiagnosticActivities/TenantGroups/{tenantGroupName}/Tenants/{tenant}?UserName={upn}&StartTime={startDatetime}&EndTime={endDatetime}&ActivityType={activityType}&Outcome={outcomeVal}&Detailed=true";// &PageSize=1000&SortField=StartTime&IsDescending=True";
                }

                var reply = await SendRequest(url, accessToken).ConfigureAwait(false);

                // Set cache expiration
                entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromHours(2);

                return reply;

            }).ConfigureAwait(false);

            if (result.StatusCode == HttpStatusCode.OK)
            {
                var data = await result.Content.ReadAsStringAsync().ConfigureAwait(false);
                var arr = (JArray)JsonConvert.DeserializeObject(data);
                return ((JArray)arr).Select(item => new ConnectionActivity
                {
                    activityId = (string)item["activityId"],
                    activityType = (string)item["activityType"],
                    startTime = item["startTime"].ToString() != null ? Convert.ToDateTime(item["startTime"]) : (DateTime?)null,
                    endTime = (string)item["endTime"] == null || (string)item["endTime"] == "" ? (DateTime?)null : Convert.ToDateTime(item["endTime"]),
                    userName = item["userName"].ToString(),
                    outcome = (string)item["outcome"] == null || (string)item["outcome"] == "" ? "" : Enum.GetName(typeof(ActivityOutcome), (int)item["outcome"]),
                    //  isInternalError = item["errors"].ToArray().Count() > 0 ? (string)item["errors"][0]["errorInternal"] : null,
                    //  errorMessage = item["errors"].ToArray().Count() > 0 ? (string)item["errors"][0]["errorMessage"] : null,
                    //errors= errors.OfType<JObject>().ToList(),
                    errors = item["errors"].OfType<JObject>().ToList(),
                    ClientOS = (string)item["details"]["ClientOS"],
                    ClientIPAddress = item["details"]["ClientIPAddress"].ToString(),
                    Tenants = (string)item["details"]["Tenants"],
                    SessionHostName = (string)item["details"]["SessionHostName"],
                    SessionHostPoolName = (string)item["details"]["SessionHostPoolName"]
                }).ToList().OrderByDescending(x=> x.startTime).ToList();
                
             
               
            }
            else
            {
                _logger.LogError($"Service call to get connection activities of user {upn} of Tenant {tenant} within tenant group {tenantGroupName} is failed. Error : {result} ");
                return new List<ConnectionActivity>() {
                        new ConnectionActivity()
                        {
                            ErrorDetails= new ErrorDetails
                            {
                                StatusCode=(int)result.StatusCode,
                                Message = result.ReasonPhrase.ToString()
                            }
                        }
                    };
            }

        }

        public async Task<List<ManagementActivity>> GetManagementActivities(string accessToken, string upn, string tenantGroupName, string tenant, string startDatetime, string endDatetime, string outcome)
        {
            _logger.LogInformation($"Service call to get management activities of user {upn} of Tenant {tenant} within tenant group {tenantGroupName} ");

            // Here we will add user to the key
            var key = new Tuple<string, string, string, string, string, string, string>(nameof(GetManagementActivities), upn, tenantGroupName, tenant, startDatetime, endDatetime, outcome);

            // Try to get from cache first
            var result = await _cache.GetOrCreateAsync(key, async entry =>
            {
                int activityType = (int)ActivityType.Management;
                outcome = outcome == ActivityOutcome.All.ToString() ? null : outcome;
                var url = "";
                if (outcome == null)
                {
                    url = $"{_brokerUrl}RdsManagement/V1/DiagnosticActivities/TenantGroups/{tenantGroupName}/Tenants/{tenant}?UserName={upn}&StartTime={startDatetime}&EndTime={endDatetime}&ActivityType={activityType}&Detailed=true";
                }
                else
                {
                    int outcomeVal = (int)Enum.Parse(typeof(ActivityOutcome), outcome);
                    url = $"{_brokerUrl}RdsManagement/V1/DiagnosticActivities/TenantGroups/{tenantGroupName}/Tenants/{tenant}?UserName={upn}&StartTime={startDatetime}&EndTime={endDatetime}&ActivityType={activityType}&Outcome={outcomeVal}&Detailed=true";
                }

                var reply = await SendRequest(url, accessToken).ConfigureAwait(false);

                // Set cache expiration
                entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromHours(2);

                return reply;

            }).ConfigureAwait(false);

            if (result.StatusCode == HttpStatusCode.OK)
            {
                var data = await result.Content.ReadAsStringAsync().ConfigureAwait(false);
                var arr = (JArray)JsonConvert.DeserializeObject(data);
                return ((JArray)arr).Select(item => new ManagementActivity
                {
                    activityId = (string)item["activityId"],
                    activityType = (string)item["activityType"],
                    startTime = item["startTime"].ToString() != null ? Convert.ToDateTime(item["startTime"]) : (DateTime?)null,
                    endTime = (string)item["endTime"] == null || (string)item["endTime"] == "" ? (DateTime?)null : Convert.ToDateTime(item["endTime"]),
                    userName = (string)item["userName"],
                    outcome = (string)item["outcome"] == null || (string)item["outcome"] == "" ? "" : Enum.GetName(typeof(ActivityOutcome), (int)item["outcome"]),
                    isInternalError = item["errors"].ToArray().Count() > 0 ? (string)item["errors"][0]["errorInternal"] : null,
                    errorMessage = item["errors"].ToArray().Count() > 0 ? (string)item["errors"][0]["errorMessage"] : null,
                    ObjectsCreated = (string)item["ObjectsCreated"] == null || (string)item["ObjectsCreated"] == "" ? 0 : (int)item["ObjectsCreated"],
                    ObjectsDeleted = (string)item["ObjectsDeleted"] == null || (string)item["ObjectsDeleted"] == "" ? 0 : (int)item["ObjectsDeleted"],
                    ObjectsFetched = (string)item["ObjectsFetched"] == null || (string)item["ObjectsFetched"] == "" ? 0 : (int)item["ObjectsFetched"],
                    ObjectsUpdated = (string)item["ObjectsUpdated"] == null || (string)item["ObjectsUpdated"] == "" ? 0 : (int)item["ObjectsUpdated"],
                    Tenants = (string)item["details"]["Tenants"]
                }).ToList();

            }
            else
            {
                _logger.LogError($"Service call to get management activities of user {upn} of Tenant {tenant} within tenant group {tenantGroupName} is failed. Error : {result} ");

                return new List<ManagementActivity>() {
                        new ManagementActivity()
                        {
                            ErrorDetails= new ErrorDetails
                            {
                                  StatusCode=(int)result.StatusCode,
                                Message = result.ReasonPhrase.ToString()
                            }
                        }
                    };
            }
        }

        public async Task<List<FeedActivity>> GetFeedActivities(string accessToken, string upn, string tenantGroupName, string tenant, string startDatetime, string endDatetime, string outcome)
        {
            _logger.LogInformation($"Service call to get feed activities of user {upn} of Tenant {tenant} within tenant group {tenantGroupName} ");

            // Here we will add user to the key
            var key = new Tuple<string, string, string, string, string, string, string>(nameof(GetFeedActivities), upn, tenantGroupName, tenant, startDatetime, endDatetime, outcome);

            // Try to get from cache first
            var result = await _cache.GetOrCreateAsync(key, async entry =>
            {
                int activityType = (int)ActivityType.Feed;
       
                outcome = outcome == ActivityOutcome.All.ToString() ? null : outcome;
                var url = "";
                if (outcome == null)
                {
                    url = $"{_brokerUrl}RdsManagement/V1/DiagnosticActivities/TenantGroups/{tenantGroupName}/Tenants/{tenant}?UserName={upn}&StartTime={startDatetime}&EndTime={endDatetime}&ActivityType={activityType}&Detailed=true";
                }
                else
                {
                    int outcomeVal = (int)Enum.Parse(typeof(ActivityOutcome), outcome);
                    url = $"{_brokerUrl}RdsManagement/V1/DiagnosticActivities/TenantGroups/{tenantGroupName}/Tenants/{tenant}?UserName={upn}&StartTime={startDatetime}&EndTime={endDatetime}&ActivityType={activityType}&Outcome={outcomeVal}&Detailed=true";
                }

                var reply = await SendRequest(url, accessToken).ConfigureAwait(false);

                // Set cache expiration
                entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromHours(2);

                return reply;

            }).ConfigureAwait(false);

            if (result.StatusCode == HttpStatusCode.OK)
            {
                var data = await result.Content.ReadAsStringAsync().ConfigureAwait(false);
                var arr = (JArray)JsonConvert.DeserializeObject(data);
                return ((JArray)arr).Select(item => new FeedActivity
                {
                    activityId = (string)item["activityId"],
                    activityType = (string)item["activityType"],
                    startTime = item["startTime"].ToString() != null ? Convert.ToDateTime(item["startTime"]) : (DateTime?)null,
                    endTime = (string)item["endTime"] == null || (string)item["endTime"] == "" ? (DateTime?)null : Convert.ToDateTime(item["endTime"]),
                    userName = (string)item["userName"],
                    outcome = (string)item["outcome"] == null || (string)item["outcome"] == "" ? "" : Enum.GetName(typeof(ActivityOutcome), (int)item["outcome"]),
                    isInternalError = item["errors"].ToArray().Count() > 0 ? (string)item["errors"][0]["errorInternal"] : null,
                    errorMessage = item["errors"].ToArray().Count() > 0 ? (string)item["errors"][0]["errorMessage"] : null,
                    ClientOS = (string)item["details"]["ClientOS"],
                    ClientIPAddress = item["details"]["ClientIPAddress"].ToString()
                }).ToList();
            }
            else
            {
                _logger.LogError($"Service call to get feed activities of user {upn} of Tenant {tenant} within tenant group {tenantGroupName} is  failed. Error : {result} ");

                return new List<FeedActivity>() {
                        new FeedActivity()
                        {
                            ErrorDetails= new ErrorDetails
                            {
                                StatusCode=(int)result.StatusCode,
                                Message = result.ReasonPhrase.ToString()
                            }
                        }
                    };
            }
        }

        public async Task<List<ConnectionActivity>> GetActivityHostDetails(string accessToken, string tenantGroupName, string tenant, string activityId)
        {
            _logger.LogInformation($"Service call to get activity details based on activityId {activityId}");
            // Here we will add user to the key
            var key = new Tuple<string, string, string, string>(nameof(GetActivityHostDetails), tenantGroupName, tenant, activityId);

            // Try to get from cache first
            var result = await _cache.GetOrCreateAsync(key, async entry =>
            {
                var url = "";
                url = $"{_brokerUrl}RdsManagement/V1/DiagnosticActivities/TenantGroups/{tenantGroupName}/Tenants/{tenant}?ActivityId={activityId}&Detailed=true";
                var reply = await SendRequest(url, accessToken).ConfigureAwait(false);

                // Set cache expiration
                entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromHours(2);

                return reply;

            }).ConfigureAwait(false);

            if (result.StatusCode == HttpStatusCode.OK)
            {
                var data = await result.Content.ReadAsStringAsync().ConfigureAwait(false);
                var arr = (JArray)JsonConvert.DeserializeObject(data);
                return ((JArray)arr).Select(item => new ConnectionActivity
                {
                    activityId = (string)item["activityId"],
                    activityType = (string)item["activityType"],
                    startTime = item["startTime"].ToString() != null ? Convert.ToDateTime(item["startTime"]) : (DateTime?)null,
                    endTime = (string)item["endTime"] == null || (string)item["endTime"] == "" ? (DateTime?)null : Convert.ToDateTime(item["endTime"]),
                    userName = item["userName"].ToString(),
                    outcome = (string)item["outcome"] == null || (string)item["outcome"] == "" ? "" : Enum.GetName(typeof(ActivityOutcome), (int)item["outcome"]),
                    //isInternalError = item["errors"].ToArray().Count() > 0 ? (string)item["errors"][0]["errorInternal"] : null,
                   // errorMessage = item["errors"].ToArray().Count() > 0 ? (string)item["errors"][0]["errorMessage"] : null,
                   errors= item["errors"].OfType<JObject>().ToList(),
                    ClientOS = (string)item["details"]["ClientOS"],
                    ClientIPAddress = item["details"]["ClientIPAddress"].ToString(),
                    Tenants = (string)item["details"]["Tenants"],
                    SessionHostName = (string)item["details"]["SessionHostName"],
                    SessionHostPoolName = (string)item["details"]["SessionHostPoolName"]
                }).ToList();
            }
            else
            {
                _logger.LogError($"Service call to get activity details based on activityId {activityId} is failed. Error : {result} ");

                return new List<ConnectionActivity>() {
                        new ConnectionActivity()
                        {
                            ErrorDetails= new ErrorDetails
                            {
                                  StatusCode=(int)result.StatusCode,
                                Message = result.ReasonPhrase.ToString()
                            }
                        }
                    };
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
