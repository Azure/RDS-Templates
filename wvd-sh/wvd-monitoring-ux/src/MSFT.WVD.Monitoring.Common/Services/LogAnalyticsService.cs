using MSFT.WVD.Monitoring.Common.Models;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;

namespace MSFT.WVD.Monitoring.Common.Services
{
    public class LogAnalyticsService
    {
        CommonService CommonService = new CommonService();
        public async Task<VMPerformance> GetLogData(string refreshToken)
        {
            string hostName = "rdsh-Ptg01-0.rdmicontoso.com";
            string tokenval = CommonService.GetAccessToken(refreshToken);
            JObject obj= JObject.Parse(tokenval);
            var accesstoken = (string)obj["access_token"];
            string query1 = $"Perf | where Computer == '{hostName}' | where ObjectName == 'Processor Information' | where CounterName == '% Processor Time' | where InstanceName == '_Total' | summarize  (TimeGenerated, Value)=arg_min(TimeGenerated,CounterValue) by Computer | project avg = 0, Value, Computer, Status = iff(Value < 80 , true, false)";
            string query2 = $"Perf | where Computer == '{hostName}' | where ObjectName == 'LogicalDisk' | where CounterName == '% Free Space' | where InstanceName == '*' | summarize  (TimeGenerated, Value)=arg_min(TimeGenerated,CounterValue) by Computer | project avg = 0, Value, Computer, Status = iff(Value < 20 , true, false)";
            string query3 = $"Perf | where Computer == '{hostName}' | where ObjectName == 'Memory' | where CounterName == 'Available Mbytes' | where InstanceName == '*' | summarize  (TimeGenerated, Value)=arg_min(TimeGenerated,CounterValue) by Computer | project avg = 0, Value, Computer, Status = iff(Value < 500 , true, false)";
            

            VMPerformance vMPerformance = new VMPerformance();
            vMPerformance.Counters = new Counter {
                ProcessorUtilization= await GetStatus(accesstoken, query1),
                DiskUtilization = await GetStatus(accesstoken, query2),
                MemoryUtilization = await GetStatus(accesstoken, query3),

            };
            return vMPerformance;


        }

        public async Task<bool> GetStatus(string accesstoken,string query)
        {
            bool result = false;
            QueryDetails queryDetails = new QueryDetails();
            queryDetails.query = query;// "Perf | where Computer == 'rdsh-Ptg01-0.rdmicontoso.com'";
            string url = "https://api.loganalytics.io/v1/workspaces/6fb37e86-270f-4c57-becb-85ec0211f3ce/query";

            using (var client = new HttpClient())
            {
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accesstoken);
                HttpRequestMessage request = new HttpRequestMessage(HttpMethod.Post, url);
                var content = new StringContent(JsonConvert.SerializeObject(queryDetails), Encoding.UTF8, "application/json");
                //content.Headers.ContentType = new MediaTypeHeaderValue("application/json");
                request.Content = content;
                HttpResponseMessage response = await client.SendAsync(request);
                var data= response.Content.ReadAsStringAsync().Result;
                var jobj = JObject.Parse(data);
                result = jobj["tables"][0]["rows"] == null || jobj["tables"][0]["rows"].ToString() == "[]" ? true : (bool)jobj["tables"][0]["rows"][0][3];
            }
            return  result;
        }

    }
}
