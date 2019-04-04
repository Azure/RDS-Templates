using MSFT.WVD.Monitoring.Common.Models;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Text;

namespace MSFT.WVD.Monitoring.Common.BAL
{
    public class DiagnosticActivitityBL
    {
        public List<DiagnosticActivity> GetActivityDetails(string deploymentUrl, string accessToken, string tenantGroup,string tenant,DateTime startTime, DateTime endTime,int activityType,int outcome)
        {
            List<DiagnosticActivity> diagnosticActivities = new List<DiagnosticActivity>();
            try
            {
                string startDatetime = startTime.ToString("yyyy-MM-ddTHH:mm:ssZ");
                string endDatetime = endTime.ToString("yyyy-MM-ddTHH:mm:ssZ");
                HttpResponseMessage httpResponseMessage= CommonBL.InitializeHttpClient(deploymentUrl, accessToken).GetAsync($"/RdsManagement/V1/DiagnosticActivities/TenantGroups/{tenantGroup}/Tenants/{tenant}?StartTime={startDatetime}&EndTime={endDatetime}&ActivityType={activityType}&Outcome={outcome}&Detailed=true").Result;
                if(httpResponseMessage.IsSuccessStatusCode)
                {
                    string strJson = httpResponseMessage.Content.ReadAsStringAsync().Result;
                    var arr = (JArray)JsonConvert.DeserializeObject(strJson);
                    foreach (var item in arr)
                    {
                        DiagnosticActivity diagnosticActivity = new DiagnosticActivity()
                        {
                            activityId = item["activityId"].ToString(),
                            activityType = item["activityType"].ToString(),//Enum.GetName(typeof(ActivityType), item["activityType"].ToString()),
                            startTime = item["startTime"].ToString() != null ? Convert.ToDateTime(item["startTime"]) : (DateTime?)null,
                            endTime = item["endTime"].ToString() != null ? Convert.ToDateTime(item["endTime"]) : (DateTime?)null,
                            userName = item["userName"].ToString(),
                            roleInstances = item["roleInstances"].ToString(),
                            outcome = Enum.GetName(typeof(ActivityOutcome), (int)item["outcome"]), //Enum.GetName(typeof(ActivityOutcome), item["outcome"].ToString()),
                            status =Convert.ToInt32(item["status"]),
                            lastHeartbeatTime= item["lastHeartbeatTime"].ToString() != null ? Convert.ToDateTime(item["lastHeartbeatTime"]) : (DateTime?)null,
                        };

                        diagnosticActivities.Add(FillDetails(diagnosticActivity, item));
                        if (item["errors"]!=null )
                        {
                            List<Error> errors = new List<Error>();
                            foreach (var err in item["errors"])
                            {
                                Error error = new Error()
                                {
                                    errorSource= Convert.ToInt32(err["errorSource"]),
                                    errorOperation =Convert.ToInt32(err["errorOperation"]),
                                    errorCode =Convert.ToInt32(err["errorCode"]),
                                    errorCodeSymbolic = err["errorCodeSymbolic"].ToString(),
                                    errorMessage = err["errorMessage"].ToString(),
                                    errorInternal =Convert.ToBoolean( err["errorInternal"]),
                                    reportedBy =Convert.ToInt32( err["reportedBy"]),
                                    time =err["time"].ToString() != null ? Convert.ToDateTime(err["time"]) : (DateTime?)null,
                                };
                                errors.Add(error);
                            }
                            diagnosticActivity.errors = errors;
                        }
                       
                        diagnosticActivities.Add(diagnosticActivity);
                    }
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

            return diagnosticActivities;
        }

        public DiagnosticActivity FillDetails( DiagnosticActivity diagnosticActivity,JToken item)
        {
            switch (diagnosticActivity.activityType)
            {
                case "Connection":
                    diagnosticActivity.connectionDetails = new ConnectionDetails()
                    {
                        ClientOS = (string)item["details"]["ClientOS"],
                        ClientVersion = (string)item["details"]["ClientVersion"],
                        ClientType = (string)item["details"]["ClientType"],
                        PredecessorConnectionId = (string)item["details"]["PredecessorConnectionId"],
                        ClientIPAddress = (string)item["details"]["ClientIPAddress"],
                        TenantId = (string)item["details"]["TenantId"],
                        SessionHostPoolId = (string) item["details"]["SessionHostPoolId"],
                        ResourceAlias = (string)item["details"]["ResourceAlias"],
                        ResourceType = (string)item["details"]["ResourceType"],
                        LoadBalanceInfo = (string)item["details"]["LoadBalanceInfo"],
                        SessionHostPoolName = (string)item["details"]["SessionHostPoolName"],
                        SessionHostName = (string)item["details"]["SessionHostName"],
                        Resolution = (string)item["details"]["Resolution"],
                        DisplayCount = (string)item["details"]["DisplayCount"],
                        AgentOSVersion = (string) item["details"]["AgentOSVersion"],
                        AgentOSDescription = (string)item["details"]["AgentOSDescription"],
                        AgentSxsStackVersion = (string)item["details"]["AgentSxsStackVersion"],
                        Tenants = (string)item["details"]["Tenants"],
                    };
                    break;
                case "Management":
                    diagnosticActivity.managementDetails = new ManagementDetails()
                    {
                        Object = (string)item["details"]["Object"],
                        Method = (string) item["details"]["Method"],
                        Route = (string)item["details"]["Route"],
                        ObjectsFetched = Convert.ToInt32(item["details"]["ObjectsFetched"]),
                        ObjectsCreated = Convert.ToInt32(item["details"]["ObjectsCreated"]),
                        ObjectsUpdated = Convert.ToInt32(item["details"]["ObjectsUpdated"]),
                        ObjectsDeleted = Convert.ToInt32(item["details"]["ObjectsDeleted"]),
                        Tenants = (string)item["details"]["Tenants"]
                    };
                    break;
                case "Feed":
                    diagnosticActivity.feedDetails = new FeedDetails()
                    {
                        ClientOS = item["details"]["ClientOS"].ToString(),
                        ClientVersion = item["details"]["ClientVersion"].ToString(),
                        ClientType = item["details"]["ClientType"].ToString(),
                        ClientIPAddress = item["details"]["ClientIPAddress"].ToString(),
                        TenantTotal = Convert.ToInt32(item["details"]["TenantTotal"]),
                        TenantDownload = Convert.ToInt32(item["details"]["TenantDownload"]),
                        TenantFailed = Convert.ToInt32(item["details"]["TenantFailed"]),
                        RDPTotal = Convert.ToInt32(item["details"]["RDPTotal"]),
                        RDPDownload = Convert.ToInt32(item["details"]["RDPDownload"]),
                        RDPCache = Convert.ToInt32(item["details"]["RDPCache"]),
                        RDPFail = Convert.ToInt32(item["details"]["RDPFail"]),
                        IconTotal = Convert.ToInt32(item["details"]["IconTotal"].ToString()),
                        IconDownload = Convert.ToInt32(item["details"]["IconDownload"].ToString()),
                        IconCache = Convert.ToInt32(item["details"]["IconCache"].ToString()),
                        IconFail = Convert.ToInt32(item["details"]["IconFail"].ToString()),
                        Tenants = (string)item["details"]["Tenants"],
                    };
                    break;
                default:
                    break;
            }

            return diagnosticActivity;
        }
    }
}
