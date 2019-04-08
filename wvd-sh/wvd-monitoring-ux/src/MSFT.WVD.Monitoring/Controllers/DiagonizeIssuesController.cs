using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
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
        public IActionResult Index()
        {
            var role = HttpContext.Session.Get<IEnumerable<RoleAssignment>>("WVDRoles").FirstOrDefault();
            return View(new DaigonizePageViewModel()
            {
                SelectedRole = role,
                DiagonizeQuery = new DiagonizeQuery()
                {
                    startDate = DateTime.Now.AddDays(-2),
                    endDate = DateTime.Now
                }
            });

        }
        [HttpPost]
        public async Task<IActionResult> SearchActivity(DaigonizePageViewModel data)
        {
            Nullable<int> outcome = (int)data.DiagonizeQuery.activityOutcome;
            string accessToken = await HttpContext.GetTokenAsync("access_token");
            string tenantGroupName = HttpContext.Session.Get<string>("SelectedTenantGroupName");
            string tenant = HttpContext.Session.Get<string>("SelectedTenantName");
            var viewData = new DaigonizePageViewModel();
            using (var client = new HttpClient())
            {

                client.BaseAddress = new Uri($"{HttpContext.Request.Scheme}://{HttpContext.Request.Host}/api/");
                //client.Timeout = TimeSpan.FromMinutes(30);
                if (data.DiagonizeQuery.activityType == ActivityType.Management)
                {
                    client.DefaultRequestHeaders.Add("Authorization", accessToken);
                    var response = await client.GetAsync("DiagnosticActivity/GetManagementActivities/?&upn=" + data.DiagonizeQuery.upn + "&tenantGroupName=" + tenantGroupName + "&tenant=" + tenant + "&startDate=" + data.DiagonizeQuery.startDate.ToString("yyyy-MM-ddTHH:mm:ssZ") + "&endDate=" + data.DiagonizeQuery.endDate.ToString("yyyy-MM-ddTHH:mm:ssZ") + "&outcome = " + outcome);
                    
                    if (response.IsSuccessStatusCode)
                    {
                        var strconnectiondetails = await response.Content.ReadAsStringAsync();
                        viewData.managementActivity = JsonConvert.DeserializeObject<List<ManagementActivity>>(strconnectiondetails);
                        viewData.DiagonizeQuery.activityType = viewData.managementActivity.Count > 0 ? ActivityType.Management :ActivityType.None  ;

                    };
                    
                }
                else if (data.DiagonizeQuery.activityType == ActivityType.Connection)
                {
                    client.DefaultRequestHeaders.Add("Authorization", accessToken);
                    var response = await client.GetAsync("DiagnosticActivity/GetConnectionActivities/?&upn=" + data.DiagonizeQuery.upn + "&tenantGroupName=" + tenantGroupName + "&tenant=" + tenant + "&startDate=" + data.DiagonizeQuery.startDate.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ") + "&endDate=" + data.DiagonizeQuery.endDate.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ") + "&outcome = " + outcome);
                    if (response.IsSuccessStatusCode)
                    {
                        var strconnectiondetails = response.Content.ReadAsStringAsync().Result;
                        viewData.connectionActivity = JsonConvert.DeserializeObject<List<ConnectionActivity>>(strconnectiondetails);
                        viewData.activityType = viewData.connectionActivity.Count >0? ActivityType.Connection: ActivityType.None  ;

                    }
                }
                else if (data.DiagonizeQuery.activityType == ActivityType.Feed)
                {
                    client.DefaultRequestHeaders.Add("Authorization", accessToken);
                    var response = await client.GetAsync("DiagnosticActivity/GetFeedActivities/?&upn=" + data.DiagonizeQuery.upn + "&tenantGroupName=" + tenantGroupName + "&tenant=" + tenant + "&startDate=" + data.DiagonizeQuery.startDate.ToString("yyyy-MM-ddTHH:mm:ssZ") + "&endDate=" + data.DiagonizeQuery.endDate.ToString("yyyy-MM-ddTHH:mm:ssZ") + "&outcome = " + outcome);
                    if (response.IsSuccessStatusCode)
                    {
                        var strconnectiondetails = response.Content.ReadAsStringAsync().Result;
                        feedActivities = JsonConvert.DeserializeObject<List<FeedActivity>>(strconnectiondetails);
                        viewData.feedActivity = JsonConvert.DeserializeObject<List<FeedActivity>>(strconnectiondetails);
                        viewData.DiagonizeQuery.activityType = viewData.feedActivity.Count > 0 ? ActivityType.Management : ActivityType.None;

                    }
                }
            }
            //return View(viewData);
            return View("Index", viewData);
        }

    }
}
