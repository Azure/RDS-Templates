using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.OpenIdConnect;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.FileProviders;
using Microsoft.Extensions.Logging;
using MSFT.WVD.Monitoring.Common.Models;
using MSFT.WVD.Monitoring.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.Xml;

namespace MSFT.WVD.Monitoring.Controllers
{
    [Authorize]
    public class HomeController : Controller
    {
        private readonly IFileProvider _fileProvider;
        private readonly ILogger _logger;
        private readonly IHostingEnvironment _hostingEnvironment;
        public HomeController(IMemoryCache cache , IFileProvider fileProvider, ILogger<DiagnoseIssuesController> logger, IHostingEnvironment hostingEnvironment)
        {
            _fileProvider = fileProvider;
            _logger = logger;
            _hostingEnvironment = hostingEnvironment;
        }
        public IActionResult Index()
        {
            var role = new RoleAssignment();
            var messsage = "";
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

                /****following code is for temporary for role assignment***/

                var roleassignment = new RoleAssignment
                {

                    signInName = User.Claims.First(claim => claim.Type.Contains("upn")).Value,
                    displayName = User.Claims.First(claim => claim.Type == "name").Value
                };
                var roles = new List<RoleAssignment>();
                roles.Add(roleassignment);
                _logger.LogInformation($"save selected role in session storage");

                HttpContext.Session.Set<RoleAssignment>("SelectedRole", roleassignment);
                HttpContext.Session.Set("WVDRoles", roles);

                //get queries from xml
                _logger.LogInformation($"Get Log analytic queries from from xml file");
                XmlDocument xDoc = new XmlDocument();
                xDoc.PreserveWhitespace = false;
                var path = _fileProvider.GetFileInfo("/metrics.xml");
                if(path.Exists)
                {
                    try
                    {
                        xDoc.Load(path.PhysicalPath);
                        _logger.LogInformation("save Log analytic queries in session storage ");
                        HttpContext.Session.Set<XmlDocument>("LogAnalyticQuery", xDoc);
                    }
                    catch (System.Xml.XmlException ex)
                    {
                        _logger.LogError($"Failed to load 'metrics.xml' .{ex.Message}");
                        messsage = $"Failed to load 'metrics.xml' .{ex.Message}";
                    }
                  
                }
                else
                {
                    string DirectoryNme = _hostingEnvironment.ContentRootPath;
                    messsage = $"VM performance queries file does not exist or invalid format. Please upload/correct 'metrics.xml' file to '{DirectoryNme}' .";
                    _logger.LogWarning("Log analytic query file is not exist.");
                }
            }
            role = HttpContext.Session.Get<IEnumerable<RoleAssignment>>("WVDRoles").FirstOrDefault();
            //var tenantGroups = HttpContext.Session.Get<IEnumerable<string>>("tenantGroups")
            return View(new HomePageViewModel()
            {
                SelectedRole = role,
                Message = messsage,
                ShowDialog = HttpContext.Session.GetString("SelectedTenantGroupName") == null
            });
        }

        private async Task<HttpResponseMessage> InitialzeRoleInfomation()
        {
            _logger.LogInformation("Call api to get role assignment details");

            string upn = User.Claims.First(claim => claim.Type.Contains("upn")).Value;
            string accessToken = await HttpContext.GetTokenAsync("access_token").ConfigureAwait(false);
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
            _logger.LogInformation("Clear sessions and Logout from application");

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
                _logger.LogInformation("Save tenant group name and tenant name in session storage.");

                var submittedData = data.SubmitData;
                HttpContext.Session.Set<string>("SelectedTenantGroupName", submittedData.TenantGroupName);
                HttpContext.Session.Set<string>("SelectedTenantName", submittedData.TenantName);

               

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
                _logger.LogError($"RouteOfException : { exceptionFeature.Path}. ErrorMessage : {exceptionFeature.Error.Message}");

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
            _logger.LogInformation("Open panel to set tenant group name and tenant name.");
            return View();
        }
    }
}