using MSFT.WVD.Monitoring.Common.Models;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;

namespace MSFT.WVD.Monitoring.Common.BAL
{
    public class DiagnosticActivitityBL
    {

        public IEnumerable<ConnectionActivity> GetConnectionActivities(string deploymentUrl, string accessToken, string upn, string tenantGroupName, string tenant, string startDatetime, string endDatetime, Nullable<int> outcome)
        {
            List<ConnectionActivity> diagnosticActivities;
            try
            {
                HttpResponseMessage httpResponseMessage;
                int activityType = (int)ActivityType.Connection;
                if (outcome != null)
                {
                    httpResponseMessage = CommonBL.InitializeHttpClient(deploymentUrl, accessToken).GetAsync($"/RdsManagement/V1/DiagnosticActivities/TenantGroups/{tenantGroupName}/Tenants/{tenant}?UserName={upn}&StartTime={startDatetime}&EndTime={endDatetime}&ActivityType={activityType}&Outcome={outcome}&Detailed=true").Result;
                }
                else
                {
                    httpResponseMessage = CommonBL.InitializeHttpClient(deploymentUrl, accessToken).GetAsync($"/RdsManagement/V1/DiagnosticActivities/TenantGroups/{tenantGroupName}/Tenants/{tenant}?UserName={upn}&StartTime={startDatetime}&EndTime={endDatetime}&ActivityType={activityType}&Detailed=true").Result;
                }

                if (httpResponseMessage.IsSuccessStatusCode)
                {
                    string strJson = httpResponseMessage.Content.ReadAsStringAsync().Result;
                    var arr = (JArray)JsonConvert.DeserializeObject(strJson);
                    diagnosticActivities = ((JArray)arr).Select(item => new ConnectionActivity
                    {
                        activityId = (string)item["activityId"],
                        activityType = (string)item["activityType"],
                        startTime = item["startTime"].ToString() != null ? Convert.ToDateTime(item["startTime"]) : (DateTime?)null,
                        endTime = item["endTime"].ToString() != null ? Convert.ToDateTime(item["endTime"]) : (DateTime?)null,
                        userName = item["userName"].ToString(),
                        outcome = Enum.GetName(typeof(ActivityOutcome), (int)item["outcome"]),
                        isInternalError = item["errors"].ToArray().Count() > 0 ? (string)item["errors"][0]["errorInternal"].ToString() : null,
                        errorMessage = item["errors"].ToArray().Count() > 0 ? (string)item["errors"][0]["errorMessage"].ToString() : null,
                        ClientOS = (string)item["details"]["ClientOS"],
                        ClientIPAddress = item["details"]["ClientIPAddress"].ToString(),
                        Tenants = (string)item["details"]["Tenants"],
                        SessionHostName = (string)item["details"]["SessionHostName"],
                    }).ToList();
                    return diagnosticActivities;
                }
                else
                {
                    return null;
                }
            }
            catch (Exception ex)
            {
                return null;
            }
        }

        public IEnumerable<ManagementActivity> GetManagementActivities(string deploymentUrl, string accessToken, string upn, string tenantGroupName, string tenant, string startDatetime, string endDatetime, Nullable<int> outcome)
        {
            List<ManagementActivity> diagnosticActivities;
            try
            {
                HttpResponseMessage httpResponseMessage;
                int activityType = (int)ActivityType.Management;
                if (outcome != null)
                {
                    httpResponseMessage = CommonBL.InitializeHttpClient(deploymentUrl, accessToken).GetAsync($"/RdsManagement/V1/DiagnosticActivities/TenantGroups/{tenantGroupName}/Tenants/{tenant}?UserName={upn}&StartTime={startDatetime}&EndTime={endDatetime}&ActivityType={activityType}&Outcome={outcome}&Detailed=true").Result;
                }
                else
                {
                    httpResponseMessage = CommonBL.InitializeHttpClient(deploymentUrl, accessToken).GetAsync($"/RdsManagement/V1/DiagnosticActivities/TenantGroups/{tenantGroupName}/Tenants/{tenant}?UserName={upn}&StartTime={startDatetime}&EndTime={endDatetime}&ActivityType={activityType}&Detailed=true").Result;
                }

                if (httpResponseMessage.IsSuccessStatusCode)
                {
                    string strJson = httpResponseMessage.Content.ReadAsStringAsync().Result;
                    var arr = (JArray)JsonConvert.DeserializeObject(strJson);
                    diagnosticActivities = ((JArray)arr).Select(item => new ManagementActivity
                    {
                        activityId = (string)item["activityId"],
                        activityType = (string)item["activityType"],
                        startTime = (string)item["startTime"] != null ? Convert.ToDateTime(item["startTime"]) : (DateTime?)null,
                        endTime = (string)item["endTime"] != null ? Convert.ToDateTime(item["endTime"]) : (DateTime?)null,
                        userName = (string)item["userName"],
                        outcome = Enum.GetName(typeof(ActivityOutcome), (int)item["outcome"]),
                        isInternalError = item["errors"].ToArray().Count() > 0 ? (string)item["errors"][0]["errorInternal"].ToString() : null,
                        errorMessage = item["errors"].ToArray().Count() > 0 ? (string)item["errors"][0]["errorMessage"].ToString() : null,
                        ObjectsCreated = (int)item["ObjectsCreated"],
                        ObjectsDeleted = (int)item["ObjectsDeleted"],
                        ObjectsFetched = (int)item["ObjectsFetched"],
                        ObjectsUpdated = (int)item["ObjectsUpdated"]
                    }).ToList();
                    return diagnosticActivities;
                }
                else
                {
                    return null;
                }
            }
            catch (Exception ex)
            {
                return null;
            }
        }

        public IEnumerable<FeedActivity> GetFeedActivities(string deploymentUrl, string accessToken, string upn, string tenantGroupName, string tenant, string startDatetime, string endDatetime, Nullable<int> outcome)
        {
            List<FeedActivity> diagnosticActivities;
            try
            {
                int activityType = (int)ActivityType.Feed;
                HttpResponseMessage httpResponseMessage;
                if (outcome != null)
                {
                    httpResponseMessage = CommonBL.InitializeHttpClient(deploymentUrl, accessToken).GetAsync($"/RdsManagement/V1/DiagnosticActivities/TenantGroups/{tenantGroupName}/Tenants/{tenant}?UserName={upn}&StartTime={startDatetime}&EndTime={endDatetime}&ActivityType={activityType}&Outcome={outcome}&Detailed=true").Result;
                }
                else
                {
                    httpResponseMessage = CommonBL.InitializeHttpClient(deploymentUrl, accessToken).GetAsync($"/RdsManagement/V1/DiagnosticActivities/TenantGroups/{tenantGroupName}/Tenants/{tenant}?UserName={upn}&StartTime={startDatetime}&EndTime={endDatetime}&ActivityType={activityType}&Detailed=true").Result;
                }
                if (httpResponseMessage.IsSuccessStatusCode)
                {
                    string strJson = httpResponseMessage.Content.ReadAsStringAsync().Result;
                    var arr = (JArray)JsonConvert.DeserializeObject(strJson);
                    diagnosticActivities = ((JArray)arr).Select(item => new FeedActivity
                    {
                        activityId = (string)item["activityId"],
                        activityType = (string)item["activityType"],
                        startTime = (string)item["startTime"] != null ? Convert.ToDateTime(item["startTime"]) : (DateTime?)null,
                        endTime = (string)item["endTime"] != null ? Convert.ToDateTime(item["endTime"]) : (DateTime?)null,
                        userName = (string)item["userName"],
                        outcome = Enum.GetName(typeof(ActivityOutcome), (int)item["outcome"]),
                        isInternalError = item["errors"].ToArray().Count() > 0 ? (string)item["errors"][0]["errorInternal"].ToString() : null,
                        errorMessage = item["errors"].ToArray().Count() > 0 ? (string)item["errors"][0]["errorMessage"].ToString() : null,
                        ClientOS = (string)item["details"]["ClientOS"],
                        ClientIPAddress = item["details"]["ClientIPAddress"].ToString()
                    }).ToList();
                    return diagnosticActivities;
                }
                else
                {
                    return null;
                }
            }
            catch (Exception ex)
            {
                return null;
            }
        }
    }
}
