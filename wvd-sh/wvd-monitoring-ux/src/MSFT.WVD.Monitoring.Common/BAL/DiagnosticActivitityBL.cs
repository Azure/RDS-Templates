using MSFT.WVD.Monitoring.Common.Models;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace MSFT.WVD.Monitoring.Common.BAL
{
    public class DiagnosticActivitityBL
    {
        public HttpResponseMessage GetConnectionActivities(string deploymentUrl, string accessToken, string upn, string tenantGroupName, string tenant, string startDatetime, string endDatetime, string outcome = null)
        {
            try
            {
                int activityType = (int)ActivityType.Connection;
                outcome = outcome == ActivityOutcome.All.ToString() ? null : outcome;
                if (outcome != null)
                {
                    int outcomeVal = (int)Enum.Parse(typeof(ActivityOutcome), outcome);
                    return CommonBL.InitializeHttpClient(deploymentUrl, accessToken).GetAsync($"/RdsManagement/V1/DiagnosticActivities/TenantGroups/{tenantGroupName}/Tenants/{tenant}?UserName={upn}&StartTime={startDatetime}&EndTime={endDatetime}&ActivityType={activityType}&Outcome={outcomeVal}&Detailed=true").Result;
                }
                else
                {
                    return CommonBL.InitializeHttpClient(deploymentUrl, accessToken).GetAsync($"/RdsManagement/V1/DiagnosticActivities/TenantGroups/{tenantGroupName}/Tenants/{tenant}?UserName={upn}&StartTime={startDatetime}&EndTime={endDatetime}&ActivityType={activityType}&Detailed=true").Result;
                }
            }
            catch (Exception ex)
            {
                return new HttpResponseMessage() { StatusCode = HttpStatusCode.BadRequest, Content = new StringContent(ex.Message) };
            }
        }

        public IEnumerable<ConnectionActivity> GetConnectionActivities(HttpResponseMessage httpResponseMessage)
        {
            string strJson = httpResponseMessage.Content.ReadAsStringAsync().Result;
            var arr = (JArray)JsonConvert.DeserializeObject(strJson);
            return ((JArray)arr).Select(item => new ConnectionActivity
            {
                activityId = (string)item["activityId"],
                activityType = (string)item["activityType"],
                startTime = item["startTime"].ToString() != null ? Convert.ToDateTime(item["startTime"]) : (DateTime?)null,
                endTime = (string)item["endTime"] == null || (string)item["endTime"] == "" ? (DateTime?)null : Convert.ToDateTime(item["endTime"]),
                userName = item["userName"].ToString(),
                outcome = (string)item["outcome"] == null || (string)item["outcome"] == "" ? "" : Enum.GetName(typeof(ActivityOutcome), (int)item["outcome"]),
                isInternalError = item["errors"].ToArray().Count() > 0 ? (string)item["errors"][0]["errorInternal"].ToString() : null,
                errorMessage = item["errors"].ToArray().Count() > 0 ? (string)item["errors"][0]["errorMessage"].ToString() : null,
                ClientOS = (string)item["details"]["ClientOS"],
                ClientIPAddress = item["details"]["ClientIPAddress"].ToString(),
                Tenants = (string)item["details"]["Tenants"],
                SessionHostName = (string)item["details"]["SessionHostName"],
                SessionHostPoolName = (string)item["details"]["SessionHostPoolName"]
            }).ToList();
        }

        public HttpResponseMessage GetManagementActivities(string deploymentUrl, string accessToken, string upn, string tenantGroupName, string tenant, string startDatetime, string endDatetime, string outcome = null)
        {
            try
            {
                int activityType = (int)ActivityType.Management;
                outcome = outcome == ActivityOutcome.All.ToString() ? null : outcome;
                if (outcome != null)
                {
                    int outcomeVal = (int)Enum.Parse(typeof(ActivityOutcome), outcome);
                   return CommonBL.InitializeHttpClient(deploymentUrl, accessToken).GetAsync($"/RdsManagement/V1/DiagnosticActivities/TenantGroups/{tenantGroupName}/Tenants/{tenant}?UserName={upn}&StartTime={startDatetime}&EndTime={endDatetime}&ActivityType={activityType}&Outcome={outcomeVal}&Detailed=true").Result;
                }
                else
                {
                    return CommonBL.InitializeHttpClient(deploymentUrl, accessToken).GetAsync($"/RdsManagement/V1/DiagnosticActivities/TenantGroups/{tenantGroupName}/Tenants/{tenant}?UserName={upn}&StartTime={startDatetime}&EndTime={endDatetime}&ActivityType={activityType}&Detailed=true").Result;
                }
            }
            catch (Exception ex)
            {
                return new HttpResponseMessage() { StatusCode = HttpStatusCode.BadRequest, Content = new StringContent(ex.Message) };
            }
        }

        public IEnumerable<ManagementActivity> GetManagementActivities(HttpResponseMessage httpResponseMessage)
        {
            string strJson = httpResponseMessage.Content.ReadAsStringAsync().Result;
            var arr = (JArray)JsonConvert.DeserializeObject(strJson);

            return ((JArray)arr).Select(item => new ManagementActivity
            {
                activityId = (string)item["activityId"],
                activityType = (string)item["activityType"],
                startTime = item["startTime"].ToString() != null ? Convert.ToDateTime(item["startTime"]) : (DateTime?)null,
                endTime = (string)item["endTime"] == null || (string)item["endTime"] == "" ? (DateTime?)null : Convert.ToDateTime(item["endTime"]),
                userName = (string)item["userName"],
                outcome = (string)item["outcome"] == null || (string)item["outcome"] == "" ? "" : Enum.GetName(typeof(ActivityOutcome), (int)item["outcome"]),
                isInternalError = item["errors"].ToArray().Count() > 0 ? (string)item["errors"][0]["errorInternal"].ToString() : null,
                errorMessage = item["errors"].ToArray().Count() > 0 ? (string)item["errors"][0]["errorMessage"].ToString() : null,
                ObjectsCreated = (string)item["ObjectsCreated"] == null || (string)item["ObjectsCreated"] == "" ? 0 : (int)item["ObjectsCreated"],
                ObjectsDeleted = (string)item["ObjectsDeleted"] == null || (string)item["ObjectsDeleted"] == "" ? 0 : (int)item["ObjectsDeleted"],
                ObjectsFetched = (string)item["ObjectsFetched"] == null || (string)item["ObjectsFetched"] == "" ? 0 : (int)item["ObjectsFetched"],
                ObjectsUpdated = (string)item["ObjectsUpdated"] == null || (string)item["ObjectsUpdated"] == "" ? 0 : (int)item["ObjectsUpdated"]
            }).ToList();
        }

        public HttpResponseMessage GetFeedActivities(string deploymentUrl, string accessToken, string upn, string tenantGroupName, string tenant, string startDatetime, string endDatetime, string outcome = null)
        {
            try
            {
                int activityType = (int)ActivityType.Feed;
                outcome = outcome == ActivityOutcome.All.ToString() ? null : outcome;
                if (outcome != null)
                {
                    int outcomeVal = (int)Enum.Parse(typeof(ActivityOutcome), outcome);
                    return CommonBL.InitializeHttpClient(deploymentUrl, accessToken).GetAsync($"/RdsManagement/V1/DiagnosticActivities/TenantGroups/{tenantGroupName}/Tenants/{tenant}?UserName={upn}&StartTime={startDatetime}&EndTime={endDatetime}&ActivityType={activityType}&Outcome={outcomeVal}&Detailed=true").Result;
                }
                else
                {
                    return CommonBL.InitializeHttpClient(deploymentUrl, accessToken).GetAsync($"/RdsManagement/V1/DiagnosticActivities/TenantGroups/{tenantGroupName}/Tenants/{tenant}?UserName={upn}&StartTime={startDatetime}&EndTime={endDatetime}&ActivityType={activityType}&Detailed=true").Result;
                }
            }
            catch (Exception ex)
            {
                return new HttpResponseMessage() { StatusCode = HttpStatusCode.BadRequest, Content = new StringContent(ex.Message) };
            }
        }

        public IEnumerable<FeedActivity> GetFeedActivities(HttpResponseMessage httpResponseMessage)
        {
            string strJson = httpResponseMessage.Content.ReadAsStringAsync().Result;
            var arr = (JArray)JsonConvert.DeserializeObject(strJson);
            return ((JArray)arr).Select(item => new FeedActivity
            {
                activityId = (string)item["activityId"],
                activityType = (string)item["activityType"],
                startTime = item["startTime"].ToString() != null ? Convert.ToDateTime(item["startTime"]) : (DateTime?)null,
                endTime = (string)item["endTime"] == null || (string)item["endTime"] == "" ? (DateTime?)null : Convert.ToDateTime(item["endTime"]),
                userName = (string)item["userName"],
                outcome = (string)item["outcome"] == null || (string)item["outcome"] == "" ? "" : Enum.GetName(typeof(ActivityOutcome), (int)item["outcome"]),
                isInternalError = item["errors"].ToArray().Count() > 0 ? (string)item["errors"][0]["errorInternal"].ToString() : null,
                errorMessage = item["errors"].ToArray().Count() > 0 ? (string)item["errors"][0]["errorMessage"].ToString() : null,
                ClientOS = (string)item["details"]["ClientOS"],
                ClientIPAddress = item["details"]["ClientIPAddress"].ToString()
            }).ToList();
        }

        public HttpResponseMessage GetActivityDetails(string deploymentUrl, string accessToken,string tenantGroupName,string tenant, string activityId)
        {
            try
            {
               
                
                    return CommonBL.InitializeHttpClient(deploymentUrl, accessToken).GetAsync($"/RdsManagement/V1/DiagnosticActivities/TenantGroups/{tenantGroupName}/Tenants/{tenant}?ActivityId={activityId}&Detailed=true").Result;
            }
            catch (Exception ex)
            {
                return new HttpResponseMessage() { StatusCode = HttpStatusCode.BadRequest, Content = new StringContent(ex.Message) };
            }
        }
        public IEnumerable<ConnectionActivity> GetActivityDetails(HttpResponseMessage httpResponseMessage)
        {
            string strJson = httpResponseMessage.Content.ReadAsStringAsync().Result;
            var arr = (JArray)JsonConvert.DeserializeObject(strJson);
            return ((JArray)arr).Select(item => new ConnectionActivity
            {
                activityId = (string)item["activityId"],
                activityType = (string)item["activityType"],
                startTime = item["startTime"].ToString() != null ? Convert.ToDateTime(item["startTime"]) : (DateTime?)null,
                endTime = (string)item["endTime"] == null || (string)item["endTime"] == "" ? (DateTime?)null : Convert.ToDateTime(item["endTime"]),
                userName = item["userName"].ToString(),
                outcome = (string)item["outcome"] == null || (string)item["outcome"] == "" ? "" : Enum.GetName(typeof(ActivityOutcome), (int)item["outcome"]),
                isInternalError = item["errors"].ToArray().Count() > 0 ? (string)item["errors"][0]["errorInternal"].ToString() : null,
                errorMessage = item["errors"].ToArray().Count() > 0 ? (string)item["errors"][0]["errorMessage"].ToString() : null,
                ClientOS = (string)item["details"]["ClientOS"],
                ClientIPAddress = item["details"]["ClientIPAddress"].ToString(),
                Tenants = (string)item["details"]["Tenants"],
                SessionHostName = (string)item["details"]["SessionHostName"],
                SessionHostPoolName = (string)item["details"]["SessionHostPoolName"]
            }).ToList();
        }
    }
}
