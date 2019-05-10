using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.AzureAD.UI;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.OpenIdConnect;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.FileProviders;
using MSFT.WVD.Monitoring.Common.Models;
using MSFT.WVD.Monitoring.Models;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using System.Xml;

namespace MSFT.WVD.Monitoring.Controllers
{
    [Authorize]
    public class HomeController : Controller
    {
        private readonly IMemoryCache _cache;
        private readonly IFileProvider _fileProvider;
        public HomeController(IMemoryCache cache , IFileProvider fileProvider)
        {
            _cache = cache;
            _fileProvider = fileProvider;
        }
        public IActionResult Index()
        {
            var role = new RoleAssignment();
            if (HttpContext.Session.Get<RoleAssignment>("SelectedRole") == null)
            {
                //var response = await InitialzeRoleInfomation();
                //if (response.IsSuccessStatusCode)
                //{
                //    var strRoleAssignments = response.Content.ReadAsStringAsync().Result;
                //    var roleAssignments = JsonConvert.DeserializeObject(strRoleAssignments);
                //    HttpContext.Session.Set("WVDRoles", roleAssignments);
                //    //HttpContext.Session.Set("tenantGroups", roleAssignments.Select(x => x.tenantGroupName));
                //}


                //get queries from xml
                XmlDocument xDoc = new XmlDocument();
                xDoc.PreserveWhitespace = false;
                var path = _fileProvider.GetFileInfo("metrics.xml");
                xDoc.Load(path.PhysicalPath);
                HttpContext.Session.Set<XmlDocument>("LogAnalyticQuery", xDoc);
                /****following code is for temporary***/



                var roleassignment = new RoleAssignment
                {

                    signInName = User.Claims.First(claim => claim.Type.Contains("upn")).Value,
                    displayName = User.Claims.First(claim => claim.Type == "name").Value
                };
                var roles = new List<RoleAssignment>();
                roles.Add(roleassignment);
                HttpContext.Session.Set<RoleAssignment>("SelectedRole", roleassignment);
                HttpContext.Session.Set("WVDRoles", roles);
            }
            role = HttpContext.Session.Get<IEnumerable<RoleAssignment>>("WVDRoles").FirstOrDefault();
            //var tenantGroups = HttpContext.Session.Get<IEnumerable<string>>("tenantGroups")
            return View(new HomePageViewModel()
            {
                SelectedRole = role,
                ShowDialog = HttpContext.Session.GetString("SelectedTenantGroupName") == null
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
                client.BaseAddress = new Uri($"{HttpContext.Request.Scheme}://{HttpContext.Request.Host}/api/");
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
        public async Task Logout()
        {
            HttpContext.Session.Clear();
            await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
            await HttpContext.SignOutAsync(OpenIdConnectDefaults.AuthenticationScheme);
        }

        [HttpPost]
        [Authorize]
        public async Task<IActionResult> Save(HomePageViewModel data)
        {
            if (ModelState.IsValid)
            {
                var submittedData = data.SubmitData;
                HttpContext.Session.Set<string>("SelectedTenantGroupName", submittedData.TenantGroupName);
                HttpContext.Session.Set<string>("SelectedTenantName", submittedData.TenantName);

                string accessToken = await HttpContext.GetTokenAsync("access_token");
                _cache.Set("SelectedTenantGroupName", submittedData.TenantGroupName);
                _cache.Set("SelectedTenantName", submittedData.TenantName);
                _cache.Set("AccessToken", accessToken);

                /***following line will have to use ***/
                //HttpContext.Session.Set<RoleAssignment>("selectedRole", roles?.SingleOrDefault(x => x.tenantGroupName == submittedData.TenantGroupName));
                //var roles = HttpContext.Session.Get<IEnumerable<RoleAssignment>>("WVDRoles");

                //temporary code
                var roleAssignment = new RoleAssignment
                {
                    tenantGroupName = submittedData.TenantGroupName,
                    signInName = User.Claims.First(claim => claim.Type.Contains("upn")).Value,
                    displayName = User.Claims.First(claim => claim.Type == "name").Value
                };
                var roles = new List<RoleAssignment> { new RoleAssignment {
                tenantGroupName= submittedData.TenantGroupName,
                signInName=User.Claims.First(claim => claim.Type.Contains("upn")).Value,
                displayName=User.Claims.First(claim => claim.Type=="name").Value
                } };
                HttpContext.Session.Set("WVDRoles", roles);
                HttpContext.Session.Set<RoleAssignment>("SelectedRole", roleAssignment);
                return RedirectToAction("Index", "Home");
            }
            else
            {
                return View("Index", new HomePageViewModel() { ShowDialog = true });
            }
        }

        public IActionResult Error(int id, ErrorDetails errorDetails)
        {
            if (errorDetails.Message != null && errorDetails.StatusCode != null)
            {
                return View(new ErrorViewModel()
                { ErrorDetails = errorDetails }
                );
            }
            else
            {
                var exceptionFeature = HttpContext.Features.Get<IExceptionHandlerPathFeature>();
                return View(new ErrorViewModel()
                {
                    ErrorDetails = new ErrorDetails
                    {
                        Message = $"RouteOfException : { exceptionFeature.Path}. ErrorMessage : {exceptionFeature.Error.Message}"
                    }
                }
             );
            }
        }
        public IActionResult AppSettings()
        {
            return View();
        }
    }
}