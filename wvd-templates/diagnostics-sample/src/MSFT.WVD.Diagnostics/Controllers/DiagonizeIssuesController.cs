using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;
using System.Web;
using System.Xml;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using MSFT.WVD.Diagnostics.Common.Models;
using MSFT.WVD.Diagnostics.Common.Services;
using MSFT.WVD.Diagnostics.Models;
using Newtonsoft.Json;

namespace MSFT.WVD.Diagnostics.Controllers
{
    public class DiagnoseIssuesController : Controller
    {
        private readonly ILogger _logger;
        private readonly DiagnozeService _diagnozeService;
        private readonly UserSessionService _userSessionService;
        private readonly LogAnalyticsService _logAnalyticsService;
        private readonly IHostingEnvironment _hostingEnvironment;
        private readonly CommonService _commonService;
        public string tenantGroupName, tenant, accessToken;
        public DiagnoseIssuesController(IHostingEnvironment hostingEnvironment, ILogger<DiagnoseIssuesController> logger, DiagnozeService diagnozeService, UserSessionService userSessionService, LogAnalyticsService logAnalyticsService, CommonService commonService)
        {
            _commonService = commonService;
            _hostingEnvironment = hostingEnvironment;
            _logger = logger;
            _diagnozeService = diagnozeService;
            _userSessionService = userSessionService;
            _logAnalyticsService = logAnalyticsService;
        }
        public IActionResult Index()
        {
            //var role = HttpContext.Session.Get<IEnumerable<RoleAssignment>>("WVDRoles").FirstOrDefault();
            var role = HttpContext.Session.Get<RoleAssignment>("SelectedRole");
            var viewData = new DiagonizePageViewModel() { SelectedRole = role, DiagonizeQuery = new DiagonizeQuery() { StartDate = DateTime.Now.AddDays(-2), EndDate = DateTime.Now } };
            return View(viewData);
        }
        public IActionResult returnToIndex()
        {

            var role = HttpContext.Session.Get<RoleAssignment>("SelectedRole");
            var viewData = new DiagonizePageViewModel() { SelectedRole = role, DiagonizeQuery = new DiagonizeQuery() { StartDate = DateTime.Now.AddDays(-2), EndDate = DateTime.Now } };
            return View(viewData);
        }
        [HttpPost]
        public async Task<IActionResult> Index(DiagonizePageViewModel data)
        {
            var viewData = new DiagonizePageViewModel();
            if (ModelState.IsValid)
            {

                tenantGroupName = HttpContext.Session.Get<string>("SelectedTenantGroupName");
                tenant = HttpContext.Session.Get<string>("SelectedTenantName");
                if (string.IsNullOrEmpty(tenantGroupName) || string.IsNullOrEmpty(tenant))
                {
                    return RedirectToAction("Error", "Home", new ErrorDetails() { StatusCode = (int)HttpStatusCode.Forbidden, Message = "Invalid tenant group name or tenant name." });
                }
                else
                {

                    var refreshtoken = await HttpContext.GetTokenAsync("refresh_token").ConfigureAwait(false);
                    accessToken = _commonService.GetAccessTokenWVD(refreshtoken); //await HttpContext.GetTokenAsync("access_token");
                    string startDate, endDate = "";
                    if (data.DiagonizeQuery.StartDate == null)
                    {
                        startDate = $"{DateTime.Now.ToUniversalTime().AddDays(-7).ToString("yyyy-MM-dd")}T00:00:00Z";
                        endDate = $"{DateTime.Now.ToUniversalTime().ToString("yyyy-MM-dd")}T00:00:00Z";
                    }
                    else
                    {
                        startDate = data.DiagonizeQuery.StartDate.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ");//+"T00:00:00Z";
                        endDate = data.DiagonizeQuery.EndDate.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ");//+"T00: 00:00Z";
                    }



                    string activityoutcome = data.DiagonizeQuery.ActivityOutcome.ToString();
                    if (data.DiagonizeQuery.ActivityType == ActivityType.Management)
                    {
                        _logger.LogInformation($"Service call to get management activity details for selected tenant group {tenantGroupName} and tenant {tenant}");
                        //call from service layer
                        viewData.ManagementActivity = await _diagnozeService.GetManagementActivities(accessToken, data.DiagonizeQuery.UPN, tenantGroupName, tenant, startDate, endDate, activityoutcome).ConfigureAwait(false);
                        if (viewData.ManagementActivity?.Count > 0 && viewData.ManagementActivity[0].ErrorDetails != null)
                        {
                            _logger.LogError($"Error Occured : {viewData.ManagementActivity[0].ErrorDetails.Message}");
                            return RedirectToAction("Error", "Home", new ErrorDetails() { StatusCode = (int)viewData.ManagementActivity[0].ErrorDetails.StatusCode, Message = "Access Denied! You are not authorized to get list of activities.Please contact system administrator" });
                        }
                        viewData.ActivityType = viewData.ManagementActivity?.Count() > 0 ? ActivityType.Management : ActivityType.None;
                    }
                    else if (data.DiagonizeQuery.ActivityType == ActivityType.Connection)
                    {
                        _logger.LogInformation($"Service Call  to get connection activity details for selected tenant group {tenantGroupName} and tenant {tenant}");

                        //call from service layer
                        viewData.ConnectionActivity = await _diagnozeService.GetConnectionActivities(accessToken, data.DiagonizeQuery.UPN, tenantGroupName, tenant, startDate, endDate, activityoutcome).ConfigureAwait(false);
                        if (viewData.ConnectionActivity?.Count > 0 && viewData.ConnectionActivity[0].ErrorDetails != null)
                        {
                            _logger.LogError($"Error Occured : {viewData.ConnectionActivity[0].ErrorDetails.Message}");
                            return RedirectToAction("Error", "Home", new ErrorDetails() { StatusCode = (int)viewData.ConnectionActivity[0].ErrorDetails.StatusCode, Message = "Access Denied! You are not authorized to get list of activities.Please contact system administrator" });
                        }

                        viewData.ActivityType = viewData.ConnectionActivity?.Count() > 0 ? ActivityType.Connection : ActivityType.None;
                    }
                    else if (data.DiagonizeQuery.ActivityType == ActivityType.Feed)
                    {
                        _logger.LogInformation($"Service call to get feed activity details for selected tenant group {tenantGroupName} and tenant {tenant}");

                        viewData.FeedActivity = await _diagnozeService.GetFeedActivities(accessToken, data.DiagonizeQuery.UPN, tenantGroupName, tenant, startDate, endDate, activityoutcome).ConfigureAwait(false);
                        if (viewData.FeedActivity?.Count > 0 && viewData.FeedActivity[0].ErrorDetails != null)
                        {
                            _logger.LogError($"Error Occured : {viewData.FeedActivity[0].ErrorDetails.Message}");
                            return RedirectToAction("Error", "Home", new ErrorDetails() { StatusCode = (int)viewData.FeedActivity[0].ErrorDetails.StatusCode, Message = "Access Denied!You are not authorized to get list of activities.Please contact system administrator" });
                        }
                        viewData.ActivityType = viewData.FeedActivity?.Count() > 0 ? ActivityType.Feed : ActivityType.None;
                    }
                }


            }
            HttpContext.Session.Set<DiagonizeQuery>("SearchQuery", data.DiagonizeQuery);
            HttpContext.Session.Set<List<ConnectionActivity>>("ConnectionActivity", viewData.ConnectionActivity);
            viewData.DiagonizeQuery = data.DiagonizeQuery;
            return View("SearchResults", viewData);
        }

        public async Task<IActionResult> SearchResults()
        {
            var searchQuery = HttpContext.Session.Get<DiagonizeQuery>("SearchQuery");
            RoleAssignment role = HttpContext.Session.Get<RoleAssignment>("SelectedRole");
            if (searchQuery != null)
            {
                return await Index(new DiagonizePageViewModel() { SelectedRole = role, DiagonizeQuery = searchQuery });
            }
            else
            { return RedirectToAction("Index"); }
        }
        public IActionResult GetUserSessions(DiagnoseDetailPageViewModel data)
        {
            return View("UserSessions", data);
        }

        public async Task<List<UserSession>> GetUserSessions(string accessToken, string tenantGroupName, string tenant, string hostPoolName, string hostName)
        {
            var data = await _userSessionService.GetUserSessions(accessToken, tenantGroupName, tenant, hostPoolName, hostName).ConfigureAwait(false);
            return data;
        }


        [HttpPost]
        public async Task<IActionResult> LogOffUserSession(DiagnoseDetailPageViewModel data)
        {
            var viewData = new LogOffUserQuery();
            tenantGroupName = HttpContext.Session.Get<string>("SelectedTenantGroupName");
            tenant = HttpContext.Session.Get<string>("SelectedTenantName");
            var refreshtoken = await HttpContext.GetTokenAsync("refresh_token").ConfigureAwait(false);
            accessToken = _commonService.GetAccessTokenWVD(refreshtoken); //await HttpContext.GetTokenAsync("access_token");

            var messageStatus = new List<MessageStatus>();
            if (data.UserSessions.Where(x => x.IsSelected == true).ToList().Count > 0)
            {
                foreach (var item in data.UserSessions.Where(x => x.IsSelected == true).ToList())
                {
                    var logOffUserQuery = new LogOffUserQuery()
                    {
                        tenantGroupName = tenantGroupName,
                        tenantName = item.tenantName,
                        hostPoolName = item.hostPoolName,
                        sessionHostName = item.sessionHostName,
                        sessionId = item.sessionId,
                        adUserName = item.adUserName
                    };
                    var Content = new StringContent(JsonConvert.SerializeObject(logOffUserQuery), Encoding.UTF8, "application/json");
                    _logger.LogInformation($"Service Call to log off user session ");
                    var response = await _userSessionService.LogOffUserSession(accessToken, logOffUserQuery).ConfigureAwait(false);
                    if (response == HttpStatusCode.OK.ToString() || response == "Success")
                    {
                        messageStatus.Add(new MessageStatus()
                        {
                            Message = $"Log off successfully for {item.adUserName} user session.",
                            Status = "Success"
                        });
                    }
                    else if (response == HttpStatusCode.Forbidden.ToString() || response == HttpStatusCode.Unauthorized.ToString())
                    {
                        messageStatus.Add(new MessageStatus()
                        {
                            Message = $"Failed to log off  {item.adUserName} . You don't have permissions to log off user.",
                            Status = "Error"
                        });
                    }
                    else
                    {
                        messageStatus.Add(new MessageStatus()
                        {
                            Message = $"Failed to logoff {item.adUserName} user session.",
                            Status = "Error"
                        });
                    }

                }
                ViewBag.ErrorMsg = "";
            }
            else
            {
                ViewBag.ErrorMsg = "Please select at least one user";
            }
            await Task.Delay(1500); // delay the process for 1.5 second to get current list of user sessions


            return View("ActivityHostDetails", new DiagnoseDetailPageViewModel()
            {
                Title = string.Empty,
                Message = string.Empty,
                SendMsgStatuses = messageStatus,
                ConnectionActivity = data.ConnectionActivity,
                ShowConnectedUser = true,
                ShowMessageForm = false,
                UserSessions = await GetUserSessions(accessToken, tenantGroupName, tenant, data.ConnectionActivity.SessionHostPoolName, data.ConnectionActivity.SessionHostName).ConfigureAwait(false),
                VMPerformance = await GetVMPerformance(data.ConnectionActivity.SessionHostName).ConfigureAwait(false)
            });
        }


        public async Task<IActionResult> InitiateSendMessage(DiagnoseDetailPageViewModel data)
        {
            try
            {
                bool ShowMessageForm = false;
                tenantGroupName = HttpContext.Session.Get<string>("SelectedTenantGroupName");
                tenant = HttpContext.Session.Get<string>("SelectedTenantName");
                var refreshtoken = await HttpContext.GetTokenAsync("refresh_token").ConfigureAwait(false);
                accessToken = _commonService.GetAccessTokenWVD(refreshtoken); //await HttpContext.GetTokenAsync("access_token");


                if (data.UserSessions.Where(x => x.IsSelected == true).ToList().Count > 0)
                {
                    ShowMessageForm = true;
                    ViewBag.ErrorMsg = "";

                }
                else
                {
                    ViewBag.ErrorMsg = "Please select at least one user";
                    ShowMessageForm = false;
                }

                return View("ActivityHostDetails", new DiagnoseDetailPageViewModel()
                {
                    Title = string.Empty,
                    Message = string.Empty,
                    ConnectionActivity = data.ConnectionActivity,
                    ShowConnectedUser = true,
                    ShowMessageForm = ShowMessageForm,
                    UserSessions = await GetUserSessions(accessToken, tenantGroupName, tenant, data.ConnectionActivity.SessionHostPoolName, data.ConnectionActivity.SessionHostName).ConfigureAwait(false),
                    selectedUsername = data.UserSessions.Where(x => x.IsSelected == true).ToList(),
                    VMPerformance = await GetVMPerformance(data.ConnectionActivity.SessionHostName).ConfigureAwait(false)
                });
            }
            catch (Exception ex)
            {
                _logger.LogError($"Error Occured : {ex.Message.ToString()}");

                return RedirectToAction("Error", "Home", new ErrorDetails() { StatusCode = (int)HttpStatusCode.BadRequest, Message = ex.Message.ToString() });

            }


        }

        [HttpPost]
        public async Task<IActionResult> SendMessage(DiagnoseDetailPageViewModel data)
        {
            try
            {
                if (ModelState.IsValid)
                {
                    var viewData = new SendMessageQuery();
                    var messageStatus = new List<MessageStatus>();
                    tenantGroupName = HttpContext.Session.Get<string>("SelectedTenantGroupName");
                    tenant = HttpContext.Session.Get<string>("SelectedTenantName");
                    var refreshtoken = await HttpContext.GetTokenAsync("refresh_token").ConfigureAwait(false);
                    accessToken = _commonService.GetAccessTokenWVD(refreshtoken); //await HttpContext.GetTokenAsync("access_token");

                    if (string.IsNullOrEmpty(data.Message) && string.IsNullOrEmpty(data.Title))
                    {

                        ViewBag.TitleErrorMsg = "Subject is required";
                        ViewBag.MessageErrorMsg = "Message is required";
                    }
                    else if (string.IsNullOrEmpty(data.Title))
                    {
                        ViewBag.TitleErrorMsg = "Title is required";

                    }
                    else if (string.IsNullOrEmpty(data.Message))
                    {
                        ViewBag.MessageErrorMsg = "Message is required";
                    }

                    else
                    {
                        if (data.UserSessions.Where(x => x.IsSelected == true).ToList().Count > 0)
                        {
                            foreach (var item in data.UserSessions.Where(x => x.IsSelected == true).ToList())
                            {
                                var sendMessageQuery = new SendMessageQuery()
                                {
                                    tenantGroupName = tenantGroupName,
                                    tenantName = item.tenantName,
                                    hostPoolName = item.hostPoolName,
                                    sessionHostName = item.sessionHostName,
                                    sessionId = item.sessionId,
                                    messageTitle = HttpUtility.UrlEncode(data.Title),
                                    messageBody = HttpUtility.UrlEncode(data.Message),
                                    userPrincipalName = item.userPrincipalName,
                                    adUserName = item.adUserName

                                };
                                var Content = new StringContent(JsonConvert.SerializeObject(sendMessageQuery), Encoding.UTF8, "application/json");
                                _logger.LogInformation($"Call service to send message to {item.userPrincipalName}");
                                var response = await _userSessionService.SendMessage(accessToken, sendMessageQuery).ConfigureAwait(false);
                                if (response == HttpStatusCode.OK.ToString())
                                {
                                    messageStatus.Add(new MessageStatus()
                                    {
                                        Message = $"Message sent successfully to {item.adUserName}",
                                        Status = "Success"
                                    });

                                }
                                else if (response == HttpStatusCode.Forbidden.ToString() || response == HttpStatusCode.Unauthorized.ToString())
                                {
                                    messageStatus.Add(new MessageStatus()
                                    {
                                        Message = $"Failed to send message to {item.adUserName} . You don't have permissions to send message.",
                                        Status = "Error"
                                    });
                                }
                                else
                                {
                                    messageStatus.Add(new MessageStatus()
                                    {
                                        Message = $"Failed to send message to {item.adUserName}",
                                        Status = "Error"
                                    });

                                }
                            }
                            ViewBag.ErrorMsg = "";

                        }
                        else
                        {

                            ViewBag.ErrorMsg = "Please select at least one user";
                        }
                    }
                    return View("ActivityHostDetails", new DiagnoseDetailPageViewModel()
                    {
                        selectedUsername = data.UserSessions.Where(x => x.IsSelected == true).ToList(),
                        UserSessions = data.UserSessions.Where(usr => usr.IsSelected = true)
                       .Select(usr => { usr.IsSelected = false; return usr; })
                       .ToList(),
                        Title = data.Title,
                        Message = data.Message,
                        SendMsgStatuses = messageStatus,
                        ConnectionActivity = data.ConnectionActivity,
                        ShowConnectedUser = true,
                        ShowMessageForm = true,
                        VMPerformance = await GetVMPerformance(data.ConnectionActivity.SessionHostName).ConfigureAwait(false)
                    });

                }
                else
                {

                    return View("ActivityHostDetails", new DiagnoseDetailPageViewModel()
                    {
                        selectedUsername = data.UserSessions.Where(x => x.IsSelected == true).ToList(),
                        UserSessions = data.UserSessions.Where(usr => usr.IsSelected = true)
                        .Select(usr => { usr.IsSelected = false; return usr; })
                        .ToList(),
                        ConnectionActivity = data.ConnectionActivity,
                        ShowConnectedUser = true,
                        ShowMessageForm = true,
                        Title = data.Title,
                        Message = data.Message,
                        VMPerformance = await GetVMPerformance(data.ConnectionActivity.SessionHostName).ConfigureAwait(false)
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError($"Error Occured : {ex.Message.ToString()}");
                return RedirectToAction("Error", "Home", new ErrorDetails() { StatusCode = (int)HttpStatusCode.BadRequest, Message = ex.Message.ToString() });
            }

        }

        public async Task<IActionResult> ActivityHostDetails(string id)
        {
            string upn = HttpContext.Session.Get<string>("SelectedUpn");
            tenantGroupName = HttpContext.Session.Get<string>("SelectedTenantGroupName");
            tenant = HttpContext.Session.Get<string>("SelectedTenantName");
            var refreshtoken = await HttpContext.GetTokenAsync("refresh_token").ConfigureAwait(false);
            accessToken = _commonService.GetAccessTokenWVD(refreshtoken); //await HttpContext.GetTokenAsync("access_token");
            var ConnectionActivity = await _diagnozeService.GetActivityHostDetails(accessToken, tenantGroupName, tenant, id).ConfigureAwait(false);
            if (ConnectionActivity?.Count > 0 && ConnectionActivity[0].ErrorDetails != null)
            {
                _logger.LogError($"Error Occured : {ConnectionActivity[0].ErrorDetails.Message}");
                return RedirectToAction("Error", "Home", new ErrorDetails() { StatusCode = ConnectionActivity[0].ErrorDetails.StatusCode, Message = ConnectionActivity[0].ErrorDetails.Message });
            }
            else
            {
                var userSessions = await GetUserSessions(accessToken, tenantGroupName, tenant, ConnectionActivity[0].SessionHostPoolName, ConnectionActivity[0].SessionHostName).ConfigureAwait(false);
                if (userSessions != null && userSessions.Count > 0 && userSessions[0].httpStatus == HttpStatusCode.OK)
                {
                    userSessions.ForEach(x => x.IsSelected = x.adUserName.ToString().Split(@"\")[1] == ConnectionActivity[0].userName.Split('@')[0] ? true : false);
                }
                else if (userSessions != null && userSessions.Count > 0 && (userSessions[0].httpStatus == HttpStatusCode.Forbidden || userSessions[0].httpStatus == HttpStatusCode.Unauthorized))
                {
                    return RedirectToAction("Error", "Home", new ErrorDetails() { StatusCode = (int)userSessions[0].httpStatus, Message = "Access Denied! You are not authorized to view user sessions. Please contact system administrator." });
                }
                

                return View(new DiagnoseDetailPageViewModel()
                {
                    ConnectionActivity = new ConnectionActivity
                    {
                        activityId = ConnectionActivity[0].activityId,
                        activityType = ConnectionActivity[0].activityType,
                        outcome = ConnectionActivity[0].outcome,
                        Tenants = ConnectionActivity[0].Tenants,
                        userName = ConnectionActivity[0].userName,
                        ClientOS = ConnectionActivity[0].ClientOS,
                        ClientIPAddress = ConnectionActivity[0].ClientIPAddress,
                        startTime = Convert.ToDateTime(ConnectionActivity[0].startTime),
                        endTime = Convert.ToDateTime(ConnectionActivity[0].endTime),
                        SessionHostName = ConnectionActivity[0].SessionHostName,
                        SessionHostPoolName = ConnectionActivity[0].SessionHostPoolName
                    },
                    UserSessions = userSessions,
                    ShowConnectedUser = false,
                    ShowMessageForm = true,
                    VMPerformance = await GetVMPerformance(ConnectionActivity[0].SessionHostName).ConfigureAwait(false)
                });
            }
        }

        public async Task<VMPerformance> GetVMPerformance(string hostName)
        {
            var refreshToken = await HttpContext.GetTokenAsync("refresh_token").ConfigureAwait(false);
            var xDoc = HttpContext.Session.Get<XmlDocument>("LogAnalyticQuery");
            if (xDoc != null)
            {
                return await _logAnalyticsService.GetSessionHostPerformance(refreshToken, hostName, xDoc).ConfigureAwait(false);
            }
            else
            {
                string DirectoryNme = _hostingEnvironment.ContentRootPath;
                return new VMPerformance
                {
                    Message = $"VM performance queries file does not exist. Please upload 'metrics.xml' file to '{DirectoryNme}' ."
                };
            }
        }
        public ActionResult ExporttoPDF()
        {
            return View();
        }

        public async Task<IActionResult> IssuesInterval(DiagonizePageViewModel diagonizePageViewModel, string interval = null, string outcome = null, string upn = null)
        {

            if (diagonizePageViewModel.DiagonizeQuery == null)
            {
                diagonizePageViewModel.DiagonizeQuery = new DiagonizeQuery();
                diagonizePageViewModel.DiagonizeQuery.UPN = upn;

            }
            HttpContext.Session.Set<string>("SelectedUpn", diagonizePageViewModel.DiagonizeQuery.UPN);

            try
            {
                if (diagonizePageViewModel.DiagonizeQuery.UPN != null)
                {
                    if (!string.IsNullOrEmpty(interval))
                    {
                        HttpContext.Session.Set<string>("SelectedInterval", interval);

                    }
                    else
                    {
                        diagonizePageViewModel.DiagonizeQuery.StartDate = DateTime.Now.AddDays(-7);
                        diagonizePageViewModel.DiagonizeQuery.EndDate = DateTime.Now;
                        interval = HttpContext.Session.Get<string>("SelectedInterval");
                    }

                    if (!string.IsNullOrEmpty(outcome))
                    {
                        HttpContext.Session.Set<string>("SelectedOutcome", outcome);
                    }
                    else
                    {
                        outcome = HttpContext.Session.Get<string>("SelectedOutcome");
                    }



                    diagonizePageViewModel.DiagonizeQuery.ActivityOutcome = outcome != null ? (ActivityOutcome)Enum.Parse(typeof(ActivityOutcome), outcome) : ActivityOutcome.All;
                    if (interval == startDateEnum.Lastonehour.ToString())
                    {
                        diagonizePageViewModel.DiagonizeQuery.StartDate = DateTime.Now.AddMinutes(-60);
                        diagonizePageViewModel.DiagonizeQuery.EndDate = DateTime.Now;
                    }
                    else if (interval == startDateEnum.sixhoursago.ToString())
                    {

                        diagonizePageViewModel.DiagonizeQuery.StartDate = DateTime.Now.AddHours(-6);
                        diagonizePageViewModel.DiagonizeQuery.EndDate = DateTime.Now;

                    }
                    else if (interval == startDateEnum.onedayago.ToString())
                    {

                        diagonizePageViewModel.DiagonizeQuery.StartDate = DateTime.Now.AddDays(-1);
                        diagonizePageViewModel.DiagonizeQuery.EndDate = DateTime.Now;

                    }
                    else if (interval == startDateEnum.oneweekago.ToString())
                    {

                        diagonizePageViewModel.DiagonizeQuery.StartDate = DateTime.Now.AddDays(-7);
                        diagonizePageViewModel.DiagonizeQuery.EndDate = DateTime.Now;

                    }
                    return await Index(diagonizePageViewModel);

                }
                else
                {
                    return View("Index", diagonizePageViewModel);
                }


            }
            catch (Exception ex)
            {

                return RedirectToAction("Error", "Home", new ErrorDetails() { StatusCode = (int)HttpStatusCode.BadRequest, Message = ex.Message.ToString() });
            }
        }

        public async Task<IActionResult> ClearFilter(DiagonizePageViewModel diagonizePageViewModel, string upn = null)
        {
            if (diagonizePageViewModel.DiagonizeQuery == null)
            {
                diagonizePageViewModel.DiagonizeQuery = new DiagonizeQuery();
                diagonizePageViewModel.DiagonizeQuery.UPN = upn;

            }

            string outcome = ActivityOutcome.All.ToString();
            string interval = startDateEnum.oneweekago.ToString();
            HttpContext.Session.Set<string>("SelectedInterval", interval);
            HttpContext.Session.Set<string>("SelectedOutcome", outcome);
            return await IssuesInterval(diagonizePageViewModel, interval, outcome, upn);

        }
        private string ListToCSV<ConnectionActivity>(List<ConnectionActivity> list)
        {
            StringBuilder sList = new StringBuilder();

            Type type = typeof(ConnectionActivity);
            var props = type.GetProperties();
            sList.Append(string.Join(",", props.Select(p => p.Name)));
            sList.Append(Environment.NewLine);

            foreach (var element in list)
            {
                sList.Append(string.Join(",", props.Select(p => p.GetValue(element, null))));
                sList.Append(Environment.NewLine);
            }

            return sList.ToString();
        }
        [HttpPost]
        public FileContentResult ExtractToCSV()
        {
            List<ConnectionActivity> data = HttpContext.Session.Get<List<ConnectionActivity>>("ConnectionActivity");
            string csv = ListToCSV(data);
            return File(new System.Text.UTF8Encoding().GetBytes(csv), "text/csv", "DiagnosticActivities.csv");
        }
    }
}
