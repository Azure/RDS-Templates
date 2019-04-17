using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using MSFT.WVD.Monitoring.Common.BAL;
using MSFT.WVD.Monitoring.Common.Models;



namespace MSFT.WVD.Monitoring.api
{
    [Route("api/[controller]")]
    public class SessionHostController : Controller
    {
        private readonly ILogger _logger;
        SessionHostBL sessionHostBL = new SessionHostBL();
        ConfigSettings Configuration;
        public SessionHostController(IConfiguration config, ILogger<DiagnosticActivityController> logger)
        {
            Configuration = new ConfigSettings(config);
            _logger = logger;
        }
        // GET: api/<controller>
        [HttpGet("GetUserSessions")]
        public IActionResult GetUserSessions(string tenantGroupName,string tenant,string hostPoolName, string sessionHostName)
        {
            try
            {
                string token = Request.Headers["Authorization"];
                _logger.LogInformation($"Call WVD api to get list of user sessions for selected tenant group {tenantGroupName} and tenant {tenant}");

                HttpResponseMessage httpResponseMessage = sessionHostBL.GetUserSessions(Configuration.RDBrokerUrl, token, tenantGroupName, tenant, hostPoolName, sessionHostName);
                if (httpResponseMessage.IsSuccessStatusCode)
                {
                    IEnumerable<UserSession> connectionActivities = sessionHostBL.GetUserSessions(httpResponseMessage, sessionHostName);
                    return new OkObjectResult(connectionActivities);
                }
                else
                {
                    var message = string.Empty;
                    if (httpResponseMessage.Content != null)
                    {
                        message = !string.IsNullOrEmpty(httpResponseMessage.Content.ReadAsStringAsync().Result) ? httpResponseMessage.Content.ReadAsStringAsync().Result : httpResponseMessage.ReasonPhrase;
                    }
                    _logger.LogError($"Error on listing connected user : {message}");
                    return StatusCode((int)httpResponseMessage.StatusCode, message);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError($"{ex.Message}");
                return StatusCode((int)HttpStatusCode.BadRequest, ex.Message);
            }
        }

       
        // POST api/<controller>
        [HttpPost("SendMessage")]
        public IActionResult SendMessage(SendMessageQuery sendMessageQuery)
        {
            try
            {
                string token = Request.Headers["Authorization"];
                _logger.LogInformation($"Call WVD api to post message to connected user");

                HttpResponseMessage httpResponseMessage = sessionHostBL.SendMessage(Configuration.RDBrokerUrl, token, sendMessageQuery);
                if (httpResponseMessage.IsSuccessStatusCode)
                {
                    return new OkResult();
                }
                else
                {
                    var message = string.Empty;
                    if (httpResponseMessage.Content != null)
                    {
                        message = !string.IsNullOrEmpty(httpResponseMessage.Content.ReadAsStringAsync().Result) ? httpResponseMessage.Content.ReadAsStringAsync().Result : httpResponseMessage.ReasonPhrase;
                    }
                    _logger.LogError($"Error on sending message to connected user{message}");
                    return StatusCode((int)httpResponseMessage.StatusCode, message);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError($"{ex.Message}");
                return StatusCode((int)HttpStatusCode.BadRequest, ex.Message);
            }
        }

        [HttpPost("LogOffUser")]
        public IActionResult LogOffUser(LogOffUserQuery logOffUserQuery)
        {
            try
            {
                string token = Request.Headers["Authorization"];
                _logger.LogInformation($"Call WVD api to logoff connected user");

                HttpResponseMessage httpResponseMessage = sessionHostBL.LogOffUser(Configuration.RDBrokerUrl, token, logOffUserQuery);
                if (httpResponseMessage.IsSuccessStatusCode)
                {
                    return new OkResult();
                }
                else
                {
                    var message = string.Empty;
                    if (httpResponseMessage.Content != null)
                    {
                        message = !string.IsNullOrEmpty(httpResponseMessage.Content.ReadAsStringAsync().Result) ? httpResponseMessage.Content.ReadAsStringAsync().Result : httpResponseMessage.ReasonPhrase;
                    }
                    _logger.LogError($"Error on logoff connected user : {message}");
                    return StatusCode((int)httpResponseMessage.StatusCode, message);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError($"{ex.Message}");
                return StatusCode((int)HttpStatusCode.BadRequest, ex.Message);
            }
           
        }


    }
}
