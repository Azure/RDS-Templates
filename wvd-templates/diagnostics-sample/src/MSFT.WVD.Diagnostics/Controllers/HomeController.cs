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
using MSFT.WVD.Diagnostics.Common.Models;
using MSFT.WVD.Diagnostics.Common.Services;
using MSFT.WVD.Diagnostics.Models;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.Xml;

namespace MSFT.WVD.Diagnostics.Controllers
{
    [Authorize]
    public class HomeController : Controller
    {
        private readonly IFileProvider _fileProvider;
        private readonly ILogger _logger;
        private readonly IHostingEnvironment _hostingEnvironment;
        private readonly RoleAssignmentService _roleAssignmentService;

        public HomeController(IMemoryCache cache, IFileProvider fileProvider, ILogger<DiagnoseIssuesController> logger, IHostingEnvironment hostingEnvironment, RoleAssignmentService roleAssignmentService)
        {
            _fileProvider = fileProvider;
            _logger = logger;
            _hostingEnvironment = hostingEnvironment;
            _roleAssignmentService = roleAssignmentService;
        }
        public async Task<IActionResult> Index()
        {
            var role = new RoleAssignment();
            var messsage = "";
            if (HttpContext.Session.Get<RoleAssignment>("SelectedRole") == null)
            {
                var roleAssignments = await InitialzeRoleInfomation();
                HttpContext.Session.Set("WVDRoles", roleAssignments);
                HttpContext.Session.Set<RoleAssignment>("SelectedRole", roleAssignments[0]);
                //get queries from xml
                _logger.LogInformation($"Get Log analytic queries from from xml file");
                XmlDocument xDoc = new XmlDocument();
                xDoc.PreserveWhitespace = false;
                var path = _fileProvider.GetFileInfo("/metrics.xml");
                if (path.Exists)
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

           

            return View(new HomePageViewModel()
            {
                SelectedRole = role,
                Message = messsage,
                TenantGroups= GetTenantGroups(),
                ShowDialog = HttpContext.Session.GetString("SelectedTenantGroupName") == null
            });
        }

        private async Task<List<RoleAssignment>> InitialzeRoleInfomation()
        {
            _logger.LogInformation("Call api to get role assignment details");

            string upn = User.Claims.First(claim => claim.Type.Contains("upn")).Value;
            string accessToken = await HttpContext.GetTokenAsync("access_token").ConfigureAwait(false);
            string roleAssignments = string.Empty;
            HttpContext.Session.SetString("upn", upn);
            HttpContext.Session.SetString("accessToken", accessToken);
            var roles = await _roleAssignmentService.GetRoleAssignments(accessToken, upn);
            return roles;
        }

        public IActionResult Login()
        {
            return Challenge(new AuthenticationProperties { RedirectUri = "/" });
        }

        public IActionResult LoginCallback()
        {
            return Challenge(new AuthenticationProperties { RedirectUri = "/" });
        }


        //[HttpPost]
        public async Task Logout()
        {
            _logger.LogInformation("Clear sessions and Logout from application");
            HttpContext.Session.Clear();
            await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
            await HttpContext.SignOutAsync(OpenIdConnectDefaults.AuthenticationScheme);
        }

        [HttpPost]
        [Authorize]
        public IActionResult Save(HomePageViewModel data)
        {
            if (ModelState.IsValid)
            {
                _logger.LogInformation("Save tenant group name and tenant name in session storage.");
                var submittedData = data.SubmitData;
                HttpContext.Session.Set<string>("SelectedTenantGroupName", submittedData.TenantGroupName);
                HttpContext.Session.Set<string>("SelectedTenantName", submittedData.TenantName);

                List<RoleAssignment> roles = HttpContext.Session.Get<List<RoleAssignment>>("WVDRoles");
                var selectedRole = roles.ToList().Where(x => x.tenantGroupName == submittedData.TenantGroupName).FirstOrDefault();
                if (selectedRole == null)
                {
                    return View("Index", new HomePageViewModel() { ShowDialog = true, Message = "Invalid tenant group name." });

                }
                else
                {
                    HttpContext.Session.Set<RoleAssignment>("SelectedRole", selectedRole);
                    return RedirectToAction("Index", "DiagnoseIssues");
                }
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
            return View(new HomePageViewModel()
            {
                TenantGroups = GetTenantGroups(),
            });
        }

        public List<string> GetTenantGroups()
        {
            var roles = HttpContext.Session.Get<IEnumerable<RoleAssignment>>("WVDRoles");
            var tenantGroups = new List<string>();
            foreach (var item in roles)
            {
                if (item.scope.ToString().Split('/').Length > 1)
                {
                    tenantGroups.Add(item.scope.ToString().Split('/')[1].ToString());
                }
                else
                {
                    tenantGroups.Add(Constants.tenantGroupName);
                }
            }
            if (tenantGroups == null || tenantGroups.Count == 0)
            {
                tenantGroups.Add(Constants.tenantGroupName);
            }
            return tenantGroups.Distinct().ToList();
        }
    }
}