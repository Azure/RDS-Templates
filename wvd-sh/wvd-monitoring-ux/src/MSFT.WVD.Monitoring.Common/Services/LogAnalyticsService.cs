using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using MSFT.WVD.Monitoring.Common.Models;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Reflection;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Xml;


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

        public JObject PrepareBatchQueryRequest(string hostName, out List<Counter> counters, XmlDocument xDoc)
        {
            counters = new List<Counter>();
            string WorkspaceID = Configuration.GetSection("AzureAd").GetSection("WorkspaceID").Value;
            JArray jArrayQry = new JArray();
            foreach (XmlNode node in xDoc.DocumentElement.ChildNodes)
            {
                int id = 0;
                // first node is the url ... have to go to nexted loc node 
                foreach (XmlNode locNode in node)
                {
                    id++;
                    string query = "", timespan = "";
                    foreach (XmlNode childnode in locNode)
                    {
                        if (childnode.Name == "Query")
                        {
                            query = childnode.InnerText.Replace(System.Environment.NewLine, "").Trim();

                        }

                        if (childnode.Name == "timespan")
                        {
                            timespan = childnode.InnerText.Replace(System.Environment.NewLine, "").Trim();
                        }
                    }

                    jArrayQry.Add(new JObject() {
                        new JProperty("id",id),
                        new JProperty("body",new JObject(){
                        new JProperty("query",String.Format(query,"'"+hostName+"'").Trim()),
                        new JProperty("timespan",timespan)
                    }),
                    new JProperty("method","POST"),
                    new JProperty("path","/query"),
                    new JProperty("workspace",WorkspaceID),
                });

                    counters.Add(new Counter()
                    {
                        id = id,
                        ObjectName = locNode.Name

                    });
                }
            }

            var queryPayLoad = new JObject();
            queryPayLoad.Add("requests", jArrayQry);
            return queryPayLoad;
        }
        public async Task<List<Counter>> ExecuteLogAnalyticsQuery(string refreshToken, string hostName, XmlDocument xmlDocument)
        {
            string loganalyticUrl = Configuration.GetSection("configurations").GetSection("LogAnalytic_URL").Value;
            string tokenval = _commonService.GetAccessToken(refreshToken, loganalyticUrl);
            JObject obj = JObject.Parse(tokenval);
            var accesstoken = (string)obj["access_token"];
            VMPerformance vMPerformance = new VMPerformance();
            var body = new JObject();
            List<Counter> counters = new List<Counter>();
            body = PrepareBatchQueryRequest(hostName, out counters, xmlDocument);

            string url = $"{loganalyticUrl}/v1/$batch";
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
                        if (item["body"]["tables"] != null && item["body"]["tables"][0]["rows"] != null && item["body"]["tables"][0]["rows"].ToString() != "[]" && item["body"]["tables"][0]["rows"].Count() > 0)
                        {
                            decimal avg = item["body"]["tables"][0]["rows"][0][0] != null ? (decimal)item["body"]["tables"][0]["rows"][0][0]:0;
                            decimal value = item["body"]["tables"][0]["rows"][0][1]!=null ? (decimal)item["body"]["tables"][0]["rows"][0][1]:0;
                            var status = item["body"]["tables"][0]["rows"][0][3].ToString();
                            counters.Where(x => x.id == (int)item["id"])
                            .Select(x => { x.avg = avg; x.Value = value; x.Status =status; return x; })
                            .ToList();
                        }
                    }
                }
            }
            return counters;
        }
        public async Task<VMPerformance> GetSessionHostPerformance(string refreshToken, string hostName, XmlDocument xmlDocument)
        {
            _logger.LogInformation($" Enter into GetSessionHostPerformance() to get log data for {hostName} ");

            return new VMPerformance()
            {
                CurrentStateCounters = await ExecuteLogAnalyticsQuery(refreshToken, hostName, xmlDocument)
            };
        }


    }
}
