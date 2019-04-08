using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Mvc;
using MSFT.WVD.Monitoring.Common.Models;
using MSFT.WVD.Monitoring.Models;
using Newtonsoft.Json;

namespace MSFT.WVD.Monitoring.Controllers
{
    public class DiagonizeIssuesController : Controller
    {
        List<ManagementActivity> managementActivities;
        List<ConnectionActivity> connectionActivities;
        List<FeedActivity> feedActivities;
        public async Task<IActionResult> Index()
        {

            return View();

        }
        [HttpPost]
        public async Task<IActionResult> SearchActivity( DaigonisepageModel data)
        {

            ActivityType activitype = data.activityType;
            int activiTypeValue = (int)activitype;

            
            ActivityOutcome activityOutcome = data.activityOutcome;
            int activityOutcomeValue = (int)activityOutcome;

            string upn = User.Claims.First(claim => claim.Type.Contains("upn")).Value;
            string accessToken = await HttpContext.GetTokenAsync("access_token");
            string tenantGroupname = HttpContext.Session.Get<string>("selectedTenantGroupName");
            string tenantname = HttpContext.Session.Get<string>("selectedTenantName");           
            using (var client = new HttpClient())
            {
                client.BaseAddress = new Uri("https://localhost:44393/api/");
                client.Timeout = TimeSpan.FromMinutes(30);
                //HTTP GET
                if (data.activityType == ActivityType.Management)
                {
                    var response = await client.GetAsync("DiagnosticActivity/GetManagementActivities//?accessToken=" + accessToken + "&upn=" + data.upn + "&tenantGroupName=" + tenantGroupname + "&tenant=" + tenantname + "&startDate=" + data.startdate + "&endDate=" + data.enddate + "&activityType=" + activiTypeValue + "&outcome = " + activityOutcomeValue);
                    if (response.IsSuccessStatusCode)
                    {
                        var strmanagementdetails = response.Content.ReadAsStringAsync().Result;
                        managementActivities = JsonConvert.DeserializeObject<List<ManagementActivity>>(strmanagementdetails);
                        return View(new DaigonisepageModel()
                        {
                            managementActivity = managementActivities
                        });
                    }
                }
                else if (data.activityType == ActivityType.Connection)
                {
                    var response = await client.GetAsync($"DiagnosticActivity/GetConnectionActivities/?accessToken=" + accessToken + "&upn=" + data.upn + "&tenantGroupName="+tenantGroupname + "&tenant=" + tenantname + "&startDate=" + data.startdate + "&endDate=" + data.enddate + "&activityType=" + activiTypeValue + "&outcome = "+ activityOutcomeValue);
                    if (response.IsSuccessStatusCode)
                    {
                        var strconnectiondetails = response.Content.ReadAsStringAsync().Result;
                        //var roleAssignments = JsonConvert.DeserializeObject(strRoleAssignments);
                        connectionActivities = JsonConvert.DeserializeObject<List<ConnectionActivity>>(strconnectiondetails);
                        return View(new DaigonisepageModel()
                        {
                            connectionActivity = connectionActivities
                        });
                    }
                }
                else if (data.activityType == ActivityType.Feed)
                {
                    var response = await client.GetAsync($"DiagnosticActivity/GetFeedActivities/?accessToken=" + accessToken + "&upn=" + data.upn + "&tenantGroupName=" + tenantGroupname + "&tenant=" + tenantname + "&startDate=" + data.startdate + "&endDate=" + data.enddate + "&activityType=" + activiTypeValue + "&outcome = " + activityOutcomeValue);
                    if (response.IsSuccessStatusCode)
                    {
                        var strfeeddetails = response.Content.ReadAsStringAsync().Result;
                        //var roleAssignments = JsonConvert.DeserializeObject(strRoleAssignments);
                        feedActivities = JsonConvert.DeserializeObject<List<FeedActivity>>(strfeeddetails);
                        return View(new DaigonisepageModel()
                        {
                            feedActivity = feedActivities
                        });
                    }
                }
            }
            return View("Index", "Home");
        }

    }
}
