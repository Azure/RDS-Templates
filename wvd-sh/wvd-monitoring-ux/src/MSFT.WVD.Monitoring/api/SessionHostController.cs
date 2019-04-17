using System;
using System.Collections.Generic;
using System.Linq;
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
        public IEnumerable<UserSession> GetUserSessions(string tenantGroupName,string tenant,string hostPoolName, string sessionHostName)
        {
            string token = Request.Headers["Authorization"];
            _logger.LogInformation($"Call WVD api to get list of user sessions for selected tenant group {tenantGroupName} and tenant {tenant}");

            return sessionHostBL.GetUserSessions(Configuration.RDBrokerUrl, token, tenantGroupName, tenant, hostPoolName, sessionHostName);
        }

       
        // POST api/<controller>
        [HttpPost("SendMessage")]
        public HttpResponseMessage SendMessage(SendMessageQuery sendMessageQuery)
        {
            string token = Request.Headers["Authorization"];
            _logger.LogInformation($"Call WVD api to post message to connected user");

            return sessionHostBL.SendMessage(Configuration.RDBrokerUrl, token, sendMessageQuery);
        }

        [HttpPost("LogOffUser")]
        public HttpResponseMessage LogOffUser(LogOffUserQuery logOffUserQuery)
        {
            string token = Request.Headers["Authorization"];
            _logger.LogInformation($"Call WVD api to logoff connected user");

            return sessionHostBL.LogOffUser(Configuration.RDBrokerUrl, token, logOffUserQuery);
        }


    }
}
