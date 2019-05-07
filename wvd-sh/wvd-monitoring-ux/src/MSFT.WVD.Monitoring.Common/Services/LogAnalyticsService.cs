using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using MSFT.WVD.Monitoring.Common.Models;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;

namespace MSFT.WVD.Monitoring.Common.Services
{
    public class LogAnalyticsService
    {
        CommonService _commonService = new CommonService();
        IConfiguration Configuration { get; }
        ILogger _logger;
        public LogAnalyticsService(IConfiguration configuration, ILoggerFactory logger)
        {
            Configuration = configuration;
            _logger = logger?.CreateLogger<LogAnalyticsService>() ?? throw new ArgumentNullException(nameof(logger));
        }

        public JObject PrepareBatchQueryRequest(string hostName)
        {
            string WorkspaceID = Configuration.GetSection("AzureAd").GetSection("WorkspaceID").Value;
            VMPerfCurrentStateQueries vMPerfQueries = new VMPerfCurrentStateQueries();
            JArray jArray = new JArray();
            int id = 0;
            foreach (FieldInfo item in vMPerfQueries.GetType().GetFields())
            {
                id++;
                jArray.Add(new JObject() {
                     new JProperty("id",id),
                new JProperty("body",new JObject(){
                    new JProperty("query", item.GetValue(vMPerfQueries).ToString().Replace("[hostName]",hostName)),
                    new JProperty("timespan","PT1H")
                }),
                new JProperty("method","POST"),
                new JProperty("path","/query"),
                new JProperty("workspace",WorkspaceID),
                });
            }
            var queryPayLoad = new JObject();
            queryPayLoad.Add("requests", jArray);
            return queryPayLoad;
        }
        public async Task<List<Counter>> ExecuteLogAnalyticsQuery(string refreshToken, string hostName, bool isCurrent, string startTime=null, string endTime=null)
        {

            List<Counter> counters  = new List<Counter>();

            string loganalyticUrl = Configuration.GetSection("configurations").GetSection("LogAnalytic_URL").Value;
            string tokenval = _commonService.GetAccessToken(refreshToken, loganalyticUrl);
            JObject obj = JObject.Parse(tokenval);
            var accesstoken = (string)obj["access_token"];
            VMPerformance vMPerformance = new VMPerformance();
            var body= new JObject();
            if (isCurrent)
            {
                 body = PrepareBatchQueryRequest(hostName);
            }
            else
            {
                body = PrepareBatchQueryRequestForTimeFrame(hostName, startTime,endTime);

            }

            string url = "https://api.loganalytics.io/v1/$batch";
            using (var client = new HttpClient())
            {
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accesstoken);
                HttpRequestMessage request = new HttpRequestMessage(HttpMethod.Post, url);
                var content = new StringContent(JsonConvert.SerializeObject(body), Encoding.UTF8, "application/json");
                request.Content = content;
                HttpResponseMessage response = await client.SendAsync(request);
                var data = response.Content.ReadAsStringAsync().Result;
                foreach (var item in JObject.Parse(data)["responses"])
                {
                    if (item["status"].ToString() == "200")
                    {
                        if (item["body"]["tables"] != null && item["body"]["tables"][0]["rows"] != null && item["body"]["tables"][0]["rows"].ToString()!="[]" && item["body"]["tables"][0]["rows"][0] != null)
                        {
                            var counter = new Counter()
                            {
                                ObjectName = item["body"]["tables"][0]["rows"][0][0].ToString(),
                                CounterName = item["body"]["tables"][0]["rows"][0][1].ToString(),
                                avg = (long)item["body"]["tables"][0]["rows"][0][2],
                                Value = (long)item["body"]["tables"][0]["rows"][0][3],
                                Computer = (string)item["body"]["tables"][0]["rows"][0][4],
                                Status = (bool)item["body"]["tables"][0]["rows"][0][5],
                            };
                            if(isCurrent)
                            {
                               counters.Add(counter);

                            }
                            else
                            {
                                counters.Add(counter);
                            }
                        }
                    }
                }
            }
            return counters;
        }
        public async Task<VMPerformance> GetSessionHostPerformance(string refreshToken, string hostName,  string startTime=null, string endTime=null)
        {
            _logger.LogInformation($" Enter into GetSessionHostPerformance() to get log data for {hostName} ");

            return new VMPerformance()
            {
                CurrentStateCounters = await ExecuteLogAnalyticsQuery(refreshToken, hostName, true),
                TimeFrameCounters = await ExecuteLogAnalyticsQuery(refreshToken, hostName, false, startTime, endTime)
            };
        }

        public JObject PrepareBatchQueryRequestForTimeFrame(string hostName, string startTime, string endTime)
        {
            string WorkspaceID = Configuration.GetSection("AzureAd").GetSection("WorkspaceID").Value;

            VMPerfTimeFrameQueries vMPerfQueries = new VMPerfTimeFrameQueries();
            JArray jArray = new JArray();
            int id = 0;
            foreach (FieldInfo item in vMPerfQueries.GetType().GetFields())
            {
                id++;
                jArray.Add(new JObject() {
                     new JProperty("id",id),
                new JProperty("body",new JObject(){
                    new JProperty("query", item.GetValue(vMPerfQueries).ToString().Replace("[hostName]",hostName).Replace("[StartTime]",startTime).Replace("[EndTime]",endTime)),
                    new JProperty("timespan","PT1H")
                }),
                new JProperty("method","POST"),
                new JProperty("path","/query"),
                new JProperty("workspace",WorkspaceID),
                });
            }
            var queryPayLoad = new JObject();
            queryPayLoad.Add("requests", jArray);
            return queryPayLoad;
        }
    }
}
