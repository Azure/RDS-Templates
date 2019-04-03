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
        public DiagnosticActivity GetActivityDetails(string deploymentUrl, string accessToken, string tenantGroup,string tenant,string startTime, string endTime,int activityType,int outcome)
        {
            try
            {
                HttpResponseMessage httpResponseMessage= CommonBL.InitializeHttpClient(deploymentUrl, accessToken).GetAsync($"/RdsManagement/V1/DiagnosticActivities/TenantGroups/{tenantGroup}/Tenants/{tenant}?StartTime={startTime}&EndTime={endTime}&ActivityType={activityType}&Outcome={outcome}&Detailed=true").Result;
                if(httpResponseMessage.IsSuccessStatusCode)
                {

                    return new DiagnosticActivity()
                    {
                       
                    };
                   
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
