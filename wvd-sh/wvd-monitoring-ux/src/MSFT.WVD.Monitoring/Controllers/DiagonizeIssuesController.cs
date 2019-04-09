using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using MSFT.WVD.Monitoring.Common.Models;
using MSFT.WVD.Monitoring.Models;
using Newtonsoft.Json;

namespace MSFT.WVD.Monitoring.Controllers
{
    public class DiagonizeIssuesController : Controller
    {
        public IActionResult Index()
        {
            //var role = HttpContext.Session.Get<IEnumerable<RoleAssignment>>("WVDRoles").FirstOrDefault();
            var role = HttpContext.Session.Get<RoleAssignment>("SelectedRole");
            return View(new DaigonizePageViewModel()
            {
                SelectedRole = role,
                DiagonizeQuery = new DiagonizeQuery()
                {
                    StartDate = DateTime.Now.AddDays(-2),
                    EndDate = DateTime.Now
                }
            });
        }

        [HttpPost]
        public async Task<IActionResult> SearchActivity(DaigonizePageViewModel data)
        {
            var viewData = new DaigonizePageViewModel();

            if (ModelState.IsValid)
            {
                string accessToken = await HttpContext.GetTokenAsync("access_token");
                string tenantGroupName = HttpContext.Session.Get<string>("SelectedTenantGroupName");
                string tenant = HttpContext.Session.Get<string>("SelectedTenantName");
                using (var client = new HttpClient())
                {

                    client.BaseAddress = new Uri($"{HttpContext.Request.Scheme}://{HttpContext.Request.Host}/api/");
                    client.Timeout = TimeSpan.FromMinutes(30);
                    if (data.DiagonizeQuery.ActivityType == ActivityType.Management)
                    {
                        client.DefaultRequestHeaders.Add("Authorization", accessToken);
                        var response = await client.GetAsync($"DiagnosticActivity/GetManagementActivities/?upn={data.DiagonizeQuery.UPN}&tenantGroupName={tenantGroupName}&tenant={tenant}&startDate={data.DiagonizeQuery.StartDate.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")}&endDate={data.DiagonizeQuery.EndDate.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")}&outcome={data.DiagonizeQuery.ActivityOutcome}");
                        if (response.IsSuccessStatusCode)
                        {
                            var strconnectiondetails = await response.Content.ReadAsStringAsync();
                            viewData.ManagementActivity = JsonConvert.DeserializeObject<List<ManagementActivity>>(strconnectiondetails);
                            viewData.ActivityType = viewData.ManagementActivity != null && viewData.ManagementActivity.Count > 0 ? ActivityType.Management : ActivityType.None;
                        };

                    }
                    else if (data.DiagonizeQuery.ActivityType == ActivityType.Connection)
                    {
                        client.DefaultRequestHeaders.Add("Authorization", accessToken);
                        var response = await client.GetAsync($"DiagnosticActivity/GetConnectionActivities/?upn={data.DiagonizeQuery.UPN}&tenantGroupName={tenantGroupName}&tenant={tenant}&startDate={data.DiagonizeQuery.StartDate.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")}&endDate={data.DiagonizeQuery.EndDate.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")}&outcome={data.DiagonizeQuery.ActivityOutcome}");
                        if (response.IsSuccessStatusCode)
                        {
                            var strconnectiondetails = response.Content.ReadAsStringAsync().Result;
                            viewData.ConnectionActivity = JsonConvert.DeserializeObject<List<ConnectionActivity>>(strconnectiondetails);
                            viewData.ActivityType = viewData.ConnectionActivity != null && viewData.ConnectionActivity.Count > 0 ? ActivityType.Connection : ActivityType.None;
                        }
                    }
                    else if (data.DiagonizeQuery.ActivityType == ActivityType.Feed)
                    {
                        client.DefaultRequestHeaders.Add("Authorization", accessToken);
                        var response = await client.GetAsync($"DiagnosticActivity/GetFeedActivities/?upn={data.DiagonizeQuery.UPN}&tenantGroupName={tenantGroupName}&tenant={tenant}&startDate={data.DiagonizeQuery.StartDate.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")}&endDate={data.DiagonizeQuery.EndDate.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")}&outcome={data.DiagonizeQuery.ActivityOutcome}");
                        if (response.IsSuccessStatusCode)
                        {
                            var strconnectiondetails = response.Content.ReadAsStringAsync().Result;
                            viewData.FeedActivity = JsonConvert.DeserializeObject<List<FeedActivity>>(strconnectiondetails);
                            viewData.ActivityType = viewData.FeedActivity != null && viewData.FeedActivity.Count > 0 ? ActivityType.Feed : ActivityType.None;
                        }
                    }
                }
            }
            return View("Index", viewData);
        }
    }
}
