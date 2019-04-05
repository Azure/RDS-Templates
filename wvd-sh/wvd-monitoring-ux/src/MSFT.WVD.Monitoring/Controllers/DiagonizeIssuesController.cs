using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Mvc;
using MSFT.WVD.Monitoring.Common.Models;
namespace MSFT.WVD.Monitoring.Controllers
{
    public class DiagonizeIssuesController : Controller
    {
        public async Task<IActionResult> Index()
        {

            return View();

        }


        [HttpPost]
        public async Task<ActionResult> SearchActivity()
        {
            if (User.Identity.IsAuthenticated)
            {
                string accessToken = await HttpContext.GetTokenAsync("access_token");
                IEnumerable<DiagnosticActivity> diagnosticactivities = null;
                using (var client = new HttpClient())
                {
                    client.BaseAddress = new Uri("https://localhost:44393/api/");
                    //HTTP GET
                    //  var responseTask = client.GetAsync("DiagnosticActivity/GetActivityDetails/?accessToken=" + accessToken + "&tenantGroup=" + tenantGroup + "&tenant=" + tenant + "&startDate=" + startTime + " &endDate=" + enddate + "&activityType=" + activitytime + "&outcome=" null);
                    var responseTask = client.GetAsync("DiagnosticActivity/GetActivityDetails/?accessToken=" + accessToken + "&tenantGroup = Default Tenant Group & tenant = Peopletech - Tenant & startDate = 2019 - 03 - 27 & endDate = 2019 - 03 - 29 & activityType = 2 & outcome = null");
                    responseTask.Wait();

                    var result = responseTask.Result;
                    if (result.IsSuccessStatusCode)
                    {
                        //var readTask = result.Content.ReadAsAsync<JArray>();
                        var readTask = result.Content.ReadAsAsync<IList<RoleAssignment>>();
                        readTask.Wait();

                        diagnosticactivities = (IEnumerable<DiagnosticActivity>)readTask.Result;
                    }
                    else //web api sent error response 
                    {
                        //log response status here..

                        //tenantGroups = Enumerable.Empty<TenantGroup>();

                        ModelState.AddModelError(string.Empty, "Server error. Please contact administrator.");
                    }
                }
                return View(diagnosticactivities);
            }
            else
            {
                return null;
            }
        }
    }
}