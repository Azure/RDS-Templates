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
        private readonly HttpClient apiClient;
        public DiagonizeIssuesController(ILogger<DiagonizeIssuesController> logger)
        {
            _logger = logger;
            apiClient = new HttpClient();
            apiClient.Timeout = TimeSpan.FromMinutes(30);
            apiClient.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
        }
        public IActionResult Index()
        {
            //var role = HttpContext.Session.Get<IEnumerable<RoleAssignment>>("WVDRoles").FirstOrDefault();
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
                string tenantGroupName = HttpContext.Session.Get<string>("SelectedTenantGroupName");
                string tenant = HttpContext.Session.Get<string>("SelectedTenantName");
                string accessToken = await HttpContext.GetTokenAsync("access_token");
                apiClient.BaseAddress = new Uri($"{HttpContext.Request.Scheme}://{HttpContext.Request.Host}/api/");
                apiClient.DefaultRequestHeaders.Add("Authorization", accessToken);
                if (data.DiagonizeQuery.ActivityType == ActivityType.Management)
                {
                    _logger.LogInformation($"Call api to get management activity details for selected tenant group {tenantGroupName} and tenant {tenant}");
                    var response = await apiClient.GetAsync($"DiagnosticActivity/GetManagementActivities/?upn={data.DiagonizeQuery.UPN}&tenantGroupName={tenantGroupName}&tenant={tenant}&startDate={data.DiagonizeQuery.StartDate.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")}&endDate={data.DiagonizeQuery.EndDate.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")}&outcome={data.DiagonizeQuery.ActivityOutcome}");
                    if (response.IsSuccessStatusCode)
                    {
                        var strManagementDetails = await response.Content.ReadAsStringAsync();
                        viewData.ManagementActivity = JsonConvert.DeserializeObject<List<ManagementActivity>>(strManagementDetails);
                        viewData.ActivityType = viewData.ManagementActivity?.Count() > 0 ? ActivityType.Management : ActivityType.None;
                    }
                    else
                    {
                        return RedirectToAction("Error", "Home", new ErrorDetails() { Message = response.Content.ReadAsStringAsync().Result, StatusCode = (int)response.StatusCode });
                    }
                }
                else if (data.DiagonizeQuery.ActivityType == ActivityType.Connection)
                {
                    _logger.LogInformation($"Call api to get connection activity details for selected tenant group {tenantGroupName} and tenant {tenant}");
                    HttpResponseMessage response = await apiClient.GetAsync($"DiagnosticActivity/GetConnectionActivities/?upn={data.DiagonizeQuery.UPN}&tenantGroupName={tenantGroupName}&tenant={tenant}&startDate={data.DiagonizeQuery.StartDate.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")}&endDate={data.DiagonizeQuery.EndDate.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")}&outcome={data.DiagonizeQuery.ActivityOutcome}");
                    if (response.IsSuccessStatusCode)
                    {
                        var strConnectionDetails = response.Content.ReadAsStringAsync().Result;
                        viewData.ConnectionActivity = JsonConvert.DeserializeObject<List<ConnectionActivity>>(strConnectionDetails);
                        viewData.ActivityType = viewData.ConnectionActivity?.Count() > 0 ? ActivityType.Connection : ActivityType.None;
                    }
                    else
                    {
                        return RedirectToAction("Error", "Home", new ErrorDetails() { Message = response.Content.ReadAsStringAsync().Result, StatusCode = (int)response.StatusCode });
                    }
                }
                else if (data.DiagonizeQuery.ActivityType == ActivityType.Feed)
                {
                    var response = await apiClient.GetAsync($"DiagnosticActivity/GetFeedActivities/?upn={data.DiagonizeQuery.UPN}&tenantGroupName={tenantGroupName}&tenant={tenant}&startDate={data.DiagonizeQuery.StartDate.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")}&endDate={data.DiagonizeQuery.EndDate.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")}&outcome={data.DiagonizeQuery.ActivityOutcome}");
                    if (response.IsSuccessStatusCode)
                    {
                        var strFeedDetails = response.Content.ReadAsStringAsync().Result;
                        viewData.FeedActivity = JsonConvert.DeserializeObject<List<FeedActivity>>(strFeedDetails);
                        viewData.ActivityType = viewData.FeedActivity?.Count() > 0 ? ActivityType.Feed : ActivityType.None;
                    }
                    else
                    {
                        return RedirectToAction("Error", "Home", new ErrorDetails() { Message = response.Content.ReadAsStringAsync().Result, StatusCode = (int)response.StatusCode });
                    }
                }
            }
            HttpContext.Session.Set<DiagonizeQuery>("SearchQuery", data.DiagonizeQuery);
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

        public List<UserSession> GetUserSessions(string accessToken, string tenantGroupName, string tenant, string hostPoolName, string hostName)
        {
            List<UserSession> userSessions = new List<UserSession>();
            using (var client = new HttpClient())
            {
                client.BaseAddress = new Uri($"{HttpContext.Request.Scheme}://{HttpContext.Request.Host}/api/");
                client.Timeout = TimeSpan.FromMinutes(30);
                client.DefaultRequestHeaders.Add("Authorization", accessToken);
                client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));

                HttpResponseMessage httpResponseMessage = client.GetAsync($"SessionHost/GetUserSessions?tenantGroupName={tenantGroupName}&tenant={tenant}&hostPoolName={hostPoolName}&sessionHostName={hostName}").Result;
                if (httpResponseMessage.IsSuccessStatusCode)
                {
                    var data = httpResponseMessage.Content.ReadAsStringAsync().Result;
                    userSessions = JsonConvert.DeserializeObject<List<UserSession>>(data);
                }
            }
            return userSessions;
        }


        [HttpPost]
        public async Task<IActionResult> LogOffUserSession(DiagnoseDetailPageViewModel data)
        {
            var viewData = new LogOffUserQuery();
            string accessToken = await HttpContext.GetTokenAsync("access_token");
            string tenantGroupName = HttpContext.Session.Get<string>("SelectedTenantGroupName");
            string tenant = HttpContext.Session.Get<string>("SelectedTenantName");
            List<MessageStatus> messageStatus = new List<MessageStatus>();
            using (var client = new HttpClient())
            {

                client.BaseAddress = new Uri($"{HttpContext.Request.Scheme}://{HttpContext.Request.Host}/api/");
                client.Timeout = TimeSpan.FromMinutes(30);
                client.DefaultRequestHeaders.Add("Authorization", accessToken);
                client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
                if (data.UserSessions.Where(x => x.IsSelected == true).ToList().Count > 0)
                {
                    foreach (var item in data.UserSessions.Where(x => x.IsSelected == true).ToList())
                    {
                        LogOffUserQuery logOffUserQuery = new LogOffUserQuery()
                        {
                            tenantGroupName = item.tenantGroupName,
                            tenantName = item.tenantName,
                            hostPoolName = item.hostPoolName,
                            sessionHostName = item.sessionHostName,
                            sessionId = item.sessionId
                        };
                        var Content = new StringContent(JsonConvert.SerializeObject(logOffUserQuery), Encoding.UTF8, "application/json");
                        _logger.LogInformation($"Call api to get management activity details for selected tenant group {tenantGroupName} and tenant {tenant}");
                        var response = await client.PostAsync($"SessionHost/LogOffUser", Content);

                        if (response.IsSuccessStatusCode)
                        {
                            messageStatus.Add(new MessageStatus()
                            {
                                Message = $"Log off sucessfully for {item.userPrincipalName} user session.",
                                Status = "Success"
                            });
                        }
                        else
                        {
                            messageStatus.Add(new MessageStatus()
                            {
                                Message = $"Failed to logoff {item.userPrincipalName} user session.",
                                Status = "Error"
                            });
                        }
                    }
                }
                else
                {
                    messageStatus.Add(new MessageStatus()
                    {
                        Message = $"Please select users.",
                        Status = "Error"
                    });
                }
            }
            return View("ActivityHostDetails", new DiagnoseDetailPageViewModel()
            {
                Title = "",
                Message = "",
                SendMsgStatuses = messageStatus,
                ConnectionActivity = data.ConnectionActivity,
                ShowConnectedUser = true,
                ShowMessageForm = false,
                UserSessions = GetUserSessions(accessToken, tenantGroupName, tenant, data.ConnectionActivity.SessionHostPoolName, data.ConnectionActivity.SessionHostName)
            });
        }

        [HttpPost]
        public async Task<IActionResult> SendMessage(DiagnoseDetailPageViewModel data)
        {
            if (ModelState.IsValid)
            {
                var viewData = new SendMessageQuery();
                List<MessageStatus> messageStatus = new List<MessageStatus>();
                string accessToken = await HttpContext.GetTokenAsync("access_token");
                string tenantGroupName = HttpContext.Session.Get<string>("SelectedTenantGroupName");
                string tenant = HttpContext.Session.Get<string>("SelectedTenantName");
                using (var client = new HttpClient())
                {
                    client.BaseAddress = new Uri($"{HttpContext.Request.Scheme}://{HttpContext.Request.Host}/api/");
                    client.Timeout = TimeSpan.FromMinutes(30);
                    client.DefaultRequestHeaders.Add("Authorization", accessToken);
                    client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
                    if (data.UserSessions.Where(x => x.IsSelected == true).ToList().Count > 0)
                    {
                        foreach (var item in data.UserSessions.Where(x => x.IsSelected == true).ToList())
                        {
                            SendMessageQuery sendMessageQuery = new SendMessageQuery()
                            {
                                tenantGroupName = item.tenantGroupName,
                                tenantName = item.tenantName,
                                hostPoolName = item.hostPoolName,
                                sessionHostName = item.sessionHostName,
                                sessionId = item.sessionId,
                                messageTitle = data.Title,
                                messageBody = data.Message,
                                userPrincipalName = item.userPrincipalName
                            };
                            var Content = new StringContent(JsonConvert.SerializeObject(sendMessageQuery), Encoding.UTF8, "application/json");
                            _logger.LogInformation($"Call api to get management activity details for selected tenant group {tenantGroupName} and tenant {tenant}");
                            var response = await client.PostAsync($"SessionHost/SendMessage", Content);
                            if (response.IsSuccessStatusCode)
                            {
                                messageStatus.Add(new MessageStatus()
                                {
                                    Message = $"Message sent sucessfully to {item.userPrincipalName}",
                                    Status = "Success"
                                });
                            }
                            else
                            {
                                messageStatus.Add(new MessageStatus()
                                {
                                    Message = $"Failed to send message to {item.userPrincipalName}",
                                    Status = "Error"
                                });

                            }
                        }
                    }
                    else
                    {
                        messageStatus.Add(new MessageStatus()
                        {
                            Message = $"Please select users",
                            Status = "Error"
                        });
                    }


                    return View("ActivityHostDetails", new DiagnoseDetailPageViewModel()
                    {
                        UserSessions = data.UserSessions.Where(usr => usr.IsSelected = true)
               .Select(usr => { usr.IsSelected = false; return usr; })
               .ToList(),

                        Title = "",
                        Message = "",

                        SendMsgStatuses = messageStatus,
                        ConnectionActivity = data.ConnectionActivity,
                        ShowConnectedUser = true,
                        ShowMessageForm = true
                    });
                }
            }
            else
            {
                return View("ActivityHostDetails", new DiagnoseDetailPageViewModel()
                {
                    UserSessions = data.UserSessions.Where(usr => usr.IsSelected = true)
              .Select(usr => { usr.IsSelected = false; return usr; })
              .ToList(),
                    ConnectionActivity = data.ConnectionActivity,
                    ShowConnectedUser = true,
                    ShowMessageForm = true
                });
            }

        }

        public async Task<IActionResult> ActivityHostDetails(string id)
        {
            string accessToken = await HttpContext.GetTokenAsync("access_token");
            string tenantGroupName = HttpContext.Session.Get<string>("SelectedTenantGroupName");
            string tenant = HttpContext.Session.Get<string>("SelectedTenantName");


            apiClient.BaseAddress = new Uri($"{HttpContext.Request.Scheme}://{HttpContext.Request.Host}/api/");
            apiClient.DefaultRequestHeaders.Add("Authorization", accessToken);
            HttpResponseMessage response = await apiClient.GetAsync($"DiagnosticActivity/GetActivityDetails/?tenantGroupName={tenantGroupName}&tenant={tenant}&activityId={id}");
            if (response.IsSuccessStatusCode)
            {
                var strConnectionDetails = response.Content.ReadAsStringAsync().Result;
                var ConnectionActivity = JsonConvert.DeserializeObject<List<ConnectionActivity>>(strConnectionDetails);
                List<UserSession> userSessions = GetUserSessions(accessToken, tenantGroupName, tenant, ConnectionActivity[0].SessionHostPoolName, ConnectionActivity[0].SessionHostName);
                ViewBag.ShowConnectedUser = true;

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
                    ShowMessageForm = true
                });
            }
            else
            {
                return RedirectToAction("Error", "Home", new ErrorDetails() { Message = response.Content.ReadAsStringAsync().Result, StatusCode = (int)response.StatusCode });
            }
        }
    }
}