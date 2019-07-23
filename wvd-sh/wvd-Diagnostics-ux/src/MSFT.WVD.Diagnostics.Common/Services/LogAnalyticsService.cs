using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using MSFT.WVD.Diagnostics.Common.Models;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;
using System.Xml;


namespace MSFT.WVD.Diagnostics.Common.Services
{
    public class LogAnalyticsService
    {
        CommonService _commonService;
        IConfiguration Configuration { get; }
        ILogger _logger;
        public LogAnalyticsService(IConfiguration configuration, ILoggerFactory logger, CommonService commonService)
        {
            _commonService = commonService;
            Configuration = configuration;
            _logger = logger?.CreateLogger<LogAnalyticsService>() ?? throw new ArgumentNullException(nameof(logger));
        }

        public JArray PrepareBatchQueryRequest(string hostName, out List<Counter> counters, XmlDocument xDoc)
        {
            counters = new List<Counter>();
            string WorkspaceID = Configuration.GetSection("AzureAd").GetSection("LogAnalyticsWorkspaceId").Value;
            JArray jArrayQry = new JArray();
            foreach (XmlNode node in xDoc.DocumentElement.ChildNodes)
            {
                int id = 0;
                foreach (XmlNode childNode in node)
                {
                    id++;
                    string query = "", timespan = "";
                    foreach (XmlNode childnode in childNode)
                    {
                        if (childnode.Name == "Query")
                        {
                            query = childnode.InnerText.Replace(System.Environment.NewLine, "").Trim();
                        }

                        if (!string.IsNullOrEmpty(query) && childnode.Name == "timespan")
                        {
                            timespan = childnode.InnerText.Replace(System.Environment.NewLine, "").Trim();
                        }
                    }

                    if (!string.IsNullOrEmpty(query) && !string.IsNullOrEmpty(timespan))
                    {
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
                    }
                    counters.Add(new Counter()
                    {
                        id = id,
                        ObjectName = childNode.Name.Replace('_', ' ')

                    });
                }
            }

            return jArrayQry;
        }
        public async Task<VMPerformance> ExecuteLogAnalyticsQuery(string refreshToken, string hostName, XmlDocument xmlDocument)
        {
            var loganalyticUrl = Configuration.GetSection("configurations").GetSection("LogAnalytic_URL").Value;
            var accesstoken = _commonService.GetAccessTokenLogAnalytic(refreshToken);
            //VMPerformance vMPerformance = new VMPerformance();
            List<Counter> counters = new List<Counter>();
            var body = new JObject();
            JArray jArray = PrepareBatchQueryRequest(hostName, out counters, xmlDocument);
            if (jArray == null || jArray.Count == 0)
            {
                return new VMPerformance()
                {
                    Message = "Invalid Queries or Queries are not availble in metrics file. Please ckeck 'metrics.xml' file. "
                };
            }
            else
            {
                body.Add("requests", jArray);
                // var body = new JObject();
                //  body = PrepareBatchQueryRequest(hostName, out counters, xmlDocument);
                var url = $"{loganalyticUrl}/v1/$batch";
                using (var client = new HttpClient())
                {
                    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accesstoken);
                    HttpRequestMessage request = new HttpRequestMessage(HttpMethod.Post, url);
                    var content = new StringContent(JsonConvert.SerializeObject(body), Encoding.UTF8, "application/json");
                    request.Content = content;
                    HttpResponseMessage response = await client.SendAsync(request);
                    if (response.StatusCode == System.Net.HttpStatusCode.OK)
                    {
                        var data = response.Content.ReadAsStringAsync().Result;
                        foreach (var item in JObject.Parse(data)["responses"])
                        {
                            if (item["status"].ToString() == "200")
                            {
                                if (item["body"]["tables"] != null && item["body"]["tables"][0]["rows"] != null && item["body"]["tables"][0]["rows"].ToString() != "[]" && item["body"]["tables"][0]["rows"].Count() > 0)
                                {
                                    decimal avg = item["body"]["tables"][0]["rows"][0][0] != null ? (decimal)item["body"]["tables"][0]["rows"][0][0] : 0;
                                    decimal value = item["body"]["tables"][0]["rows"][0][1] != null ? (decimal)item["body"]["tables"][0]["rows"][0][1] : 0;
                                    var status = item["body"]["tables"][0]["rows"][0][3].ToString();
                                    counters.Where(x => x.id == (int)item["id"])
                                    .Select(x => { x.avg = avg; x.Value = value; x.Status = status; return x; })
                                    .ToList();
                                }
                            }
                        }
                    }
                    else
                    {
                        return new VMPerformance()
                        {
                            Message = response.StatusCode+" : "+ response.Content.ReadAsStringAsync().Result
                    };
                    }
                    
                   
                }
                return new VMPerformance()
                {
                    CurrentStateCounters = counters,
                    isHealthy = counters.Where(x => x.Status == "2").ToList().Count > 1 ? false : true
                };
            }

        }
        public async Task<VMPerformance> GetSessionHostPerformance(string refreshToken, string hostName, XmlDocument xmlDocument)
        {
            _logger.LogInformation($" Enter into GetSessionHostPerformance() to get log data for {hostName} ");
            return await ExecuteLogAnalyticsQuery(refreshToken, hostName, xmlDocument);
            //return new VMPerformance()
            //{
            //    CurrentStateCounters = await ExecuteLogAnalyticsQuery(refreshToken, hostName, xmlDocument)
            //};
        }


    }
}
