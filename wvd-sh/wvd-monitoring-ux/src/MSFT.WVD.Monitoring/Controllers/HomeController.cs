using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.AzureAD.UI;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.OpenIdConnect;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using MSFT.WVD.Monitoring.Common.Models;
using MSFT.WVD.Monitoring.Models;
using Newtonsoft.Json.Linq;

namespace MSFT.WVD.Monitoring.Controllers
{
    [Authorize]
    public class HomeController : Controller
    {

        public async Task<IActionResult> Index()
        {
            var role = new RoleAssignment();
            if (HttpContext.Session.Get<RoleAssignment>("selectedRole") == null)
            {
                InitialzeRoleInfomation();
            }
            role = HttpContext.Session.Get<RoleAssignment>("selectedRole");
            //var tenantGroups = HttpContext.Session.Get<IEnumerable<string>>("tenantGroups")
            return View(new HomePageViewModel()
            {
                selectedRole = role
            });
        }

        private async void InitialzeRoleInfomation()
        {
            string upn = User.Claims.First(claim => claim.Type.Contains("upn")).Value;
            string accessToken = await HttpContext.GetTokenAsync("access_token");
            IEnumerable<RoleAssignment> roleAssignments = null;
            HttpContext.Session.SetString("upn", upn);
            HttpContext.Session.SetString("accessToken", accessToken);

            using (var client = new HttpClient())
            {
                client.BaseAddress = new Uri("/api/");
                client.Timeout = TimeSpan.FromMinutes(30);
                //HTTP GET
                var response = await client.GetAsync("RoleAssignment/TenantGroups?accessToken=" + accessToken + "&upn=" + upn);
                if (response.IsSuccessStatusCode)
                {
                    roleAssignments = await response.Content.ReadAsAsync<IEnumerable<RoleAssignment>>();
                    HttpContext.Session.Set<IEnumerable<RoleAssignment>>("WVDRoles", roleAssignments);
                    HttpContext.Session.Set<IEnumerable<string>>("tenantGroups", roleAssignments.Select(x => x.tenantGroupName));
                }
            }
        }

        public IActionResult Login()
        {
            return Challenge(new AuthenticationProperties { RedirectUri = "/" });
        }

        public IActionResult LoginCallback()
        {
            return Challenge(new AuthenticationProperties { RedirectUri = "/" });
        }

        [HttpPost]
        public async Task<IActionResult> Logout()
        {
            HttpContext.Session.Clear();
            await HttpContext.SignOutAsync(OpenIdConnectDefaults.AuthenticationScheme);
            await HttpContext.SignOutAsync(AzureADDefaults.AuthenticationScheme);
            return RedirectToAction("Login", "Home");
        }

        [HttpPost]
        public IActionResult Save([FromBody] HomePageSubmitModel data)
        {
            HttpContext.Session.SetString("selectedTenantGroupName", data.tenantGroupName);
            HttpContext.Session.SetString("selectedTenantName", data.tenantName);
            var roles =  HttpContext.Session.Get<IEnumerable<RoleAssignment>>("WVDRoles");
            HttpContext.Session.Set<RoleAssignment>("selectedRole", roles.SingleOrDefault(x => x.tenantGroupName == data.tenantGroupName));
            return RedirectToAction("Index", "Home");
        }

    }
}