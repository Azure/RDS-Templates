using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using MSFT.WVD.Diagnostics.Common.Models;
using MSFT.WVD.Diagnostics.Common.Services;

namespace MSFT.WVD.Diagnostics.api
{
    [Route("api/[controller]")]
    [ApiController]

    public class SessionHostController : ControllerBase
    {
        private readonly ILogger _logger;
        UserSessionService _userSessionService;
        public SessionHostController( ILogger<DiagnosticActivityController> logger, UserSessionService userSessionService)
        {
            _userSessionService = userSessionService;
             _logger = logger;
        }
        // GET: api/<controller>
        [HttpGet("GetUserSessions")]
        public async Task<List<UserSession>> GetUserSessions(string tenantGroupName,string tenant,string hostPoolName, string sessionHostName)
        {
            _logger.LogInformation($"Make api call to get user session of host {sessionHostName} within hostpool {hostPoolName},  tenant {tenant} and tenant group {tenantGroupName} ");
            string token = Request.Headers["Authorization"];
            return await _userSessionService.GetUserSessions(token, tenantGroupName, tenant, hostPoolName, sessionHostName).ConfigureAwait(false);
        }
       
        // POST api/<controller>
        [HttpPost("SendMessage")]
        public async Task<string> SendMessage(SendMessageQuery sendMessageQuery)
        {
            _logger.LogInformation($"Make api call  get send message to user {sendMessageQuery.userPrincipalName}");
            string token = Request.Headers["Authorization"];
            return await _userSessionService.SendMessage(token, sendMessageQuery).ConfigureAwait(false);
        }

        [HttpPost("LogOffUser")]
        public async Task<string> LogOffUser(LogOffUserQuery logOffUserQuery)
        {
            _logger.LogInformation($"Make api call to log off user session of session id {logOffUserQuery.sessionId}");
            string token = Request.Headers["Authorization"];
            return await _userSessionService.LogOffUserSession(token, logOffUserQuery).ConfigureAwait(false);
        }
    }
}
