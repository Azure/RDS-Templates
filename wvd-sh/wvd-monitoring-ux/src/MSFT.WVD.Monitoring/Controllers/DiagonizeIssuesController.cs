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
using Microsoft.Extensions.Logging;
using MSFT.WVD.Monitoring.Common.BAL;
using MSFT.WVD.Monitoring.Common.Models;
using MSFT.WVD.Monitoring.Models;
using Newtonsoft.Json;

namespace MSFT.WVD.Monitoring.Controllers
{
    public class DiagonizeIssuesController : Controller
    {
        private readonly ILogger _logger;
        DiagnosticActivitityBL diagnosticActivityBL = new DiagnosticActivitityBL();

        public DiagonizeIssuesController(ILogger<DiagonizeIssuesController> logger)
        {
            _logger = logger;
        }
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
                    client.DefaultRequestHeaders.Add("Authorization", accessToken);
                    client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));

                    if (data.DiagonizeQuery.ActivityType == ActivityType.Management)
                    {
                        _logger.LogInformation($"Call api to get management activity details for selected tenant group {tenantGroupName} and tenant {tenant}");
                        var response = await client.GetAsync($"DiagnosticActivity/GetManagementActivities/?upn={data.DiagonizeQuery.UPN}&tenantGroupName={tenantGroupName}&tenant={tenant}&startDate={data.DiagonizeQuery.StartDate.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")}&endDate={data.DiagonizeQuery.EndDate.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")}&outcome={data.DiagonizeQuery.ActivityOutcome}");
                        if (response.IsSuccessStatusCode)
                        {
                            var strManagementDetails = await response.Content.ReadAsStringAsync();
                            viewData.ManagementActivity = JsonConvert.DeserializeObject<List<ManagementActivity>>(strManagementDetails);
                            viewData.ActivityType = viewData.ManagementActivity != null && viewData.ManagementActivity.Count > 0 ? ActivityType.Management : ActivityType.None;
                        }
                        else
                        {
                            return RedirectToAction("Error", "Home", new ErrorDetails() { Message = response.Content.ReadAsStringAsync().Result, StatusCode = (int)response.StatusCode });
                        }
                    }
                    else if (data.DiagonizeQuery.ActivityType == ActivityType.Connection)
                    {
                        _logger.LogInformation($"Call api to get connection activity details for selected tenant group {tenantGroupName} and tenant {tenant}");
                        HttpResponseMessage response =  await client.GetAsync($"DiagnosticActivity/GetConnectionActivities/?upn={data.DiagonizeQuery.UPN}&tenantGroupName={tenantGroupName}&tenant={tenant}&startDate={data.DiagonizeQuery.StartDate.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")}&endDate={data.DiagonizeQuery.EndDate.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")}&outcome={data.DiagonizeQuery.ActivityOutcome}");
                        if (response.IsSuccessStatusCode)
                        {
                            var strConnectionDetails = response.Content.ReadAsStringAsync().Result;
                            viewData.ConnectionActivity = JsonConvert.DeserializeObject<List<ConnectionActivity>>(strConnectionDetails);
                            viewData.ActivityType = viewData.ConnectionActivity != null && viewData.ConnectionActivity.Count > 0 ? ActivityType.Connection : ActivityType.None;
                        }
                        else
                        {
                            return RedirectToAction("Error", "Home", new ErrorDetails() { Message = response.Content.ReadAsStringAsync().Result, StatusCode = (int)response.StatusCode });
                        }
                    }
                    else if (data.DiagonizeQuery.ActivityType == ActivityType.Feed)
                    {
                        var response = await client.GetAsync($"DiagnosticActivity/GetFeedActivities/?upn={data.DiagonizeQuery.UPN}&tenantGroupName={tenantGroupName}&tenant={tenant}&startDate={data.DiagonizeQuery.StartDate.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")}&endDate={data.DiagonizeQuery.EndDate.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")}&outcome={data.DiagonizeQuery.ActivityOutcome}");
                        if (response.IsSuccessStatusCode)
                        {
                            var strFeedDetails = response.Content.ReadAsStringAsync().Result;
                            viewData.FeedActivity = JsonConvert.DeserializeObject<List<FeedActivity>>(strFeedDetails);
                            viewData.ActivityType = viewData.FeedActivity != null && viewData.FeedActivity.Count > 0 ? ActivityType.Feed : ActivityType.None;
                        }
                        else
                        {
                            return RedirectToAction("Error", "Home", new ErrorDetails() { Message = response.Content.ReadAsStringAsync().Result, StatusCode = (int)response.StatusCode });
                        }
                    }
                }
            }
            return View("Index", viewData);
           
        }
        public IActionResult UserSessions()
        {
            return PartialView("_UserSessions");
        }
    }
}
