using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.AzureAD.UI;
using Microsoft.AspNetCore.Authentication.OpenIdConnect;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using MSFT.WVD.Monitoring.Common.Models;
using MSFT.WVD.Monitoring.Models;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;

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
                var response = await InitialzeRoleInfomation();
                if (response.IsSuccessStatusCode)
                {
                    var strRoleAssignments = response.Content.ReadAsStringAsync().Result;
                    var roleAssignments = JsonConvert.DeserializeObject(strRoleAssignments);
                    HttpContext.Session.Set("WVDRoles", roleAssignments);
                    //HttpContext.Session.Set("tenantGroups", roleAssignments.Select(x => x.tenantGroupName));
                }
            }
            role = HttpContext.Session.Get<IEnumerable<RoleAssignment>>("WVDRoles").FirstOrDefault();
            //var tenantGroups = HttpContext.Session.Get<IEnumerable<string>>("tenantGroups")
            return View(new HomePageViewModel()
            {
                SelectedRole = role,
                ShowDialog = HttpContext.Session.GetString("tenantGroupName") == null

            });
        }

        private async Task<HttpResponseMessage> InitialzeRoleInfomation()
        {
            string upn = User.Claims.First(claim => claim.Type.Contains("upn")).Value;
            string accessToken = await HttpContext.GetTokenAsync("access_token");
            string roleAssignments = string.Empty;
            HttpContext.Session.SetString("upn", upn);
            HttpContext.Session.SetString("accessToken", accessToken);

            using (var client = new HttpClient())
            {
                client.BaseAddress = new Uri("https://localhost:44393/api/");
                client.Timeout = TimeSpan.FromMinutes(30);
                //HTTP GET
                return await client.GetAsync("RoleAssignment/TenantGroups?accessToken=" + accessToken + "&upn=" + upn);
                //if (response.IsSuccessStatusCode)
                //{
                //    roleAssignments = response.Content.ReadAsStringAsync().Result;
                //    this.HttpContext.Session.Set("asd", roleAssignments);
                //    //HttpContext.Session.Set("WVDRoles", roleAssignments);
                //    //HttpContext.Session.Set("tenantGroups", roleAssignments.Select(x => x.tenantGroupName));
                //}
            }
            //HttpContext.Session.Set<JArray>("WVDRoles", roleAssignments);
            
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
        public IActionResult Save(HomePageSubmitModel data)
        {
          HttpContext.Session.SetString("selectedTenantGroupName", data.TenantGroupName);
           HttpContext.Session.SetString("selectedTenantName", data.TenantName);
           var roles = HttpContext.Session.Get<IEnumerable<RoleAssignment>>("WVDRoles");
           HttpContext.Session.Set<RoleAssignment>("selectedRole", roles.SingleOrDefault(x => x.tenantGroupName == data.TenantGroupName));
            return RedirectToAction("Index", "Home");
        }

    }
}