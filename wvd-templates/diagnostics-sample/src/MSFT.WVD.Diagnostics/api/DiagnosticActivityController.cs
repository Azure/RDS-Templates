using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using MSFT.WVD.Diagnostics.Common.Models;
using MSFT.WVD.Diagnostics.Common.Services;


namespace MSFT.WVD.Diagnostics.api
{
    [Route("api/[controller]")]
    [ApiController]
    public class DiagnosticActivityController : ControllerBase
    {
        private readonly ILogger _logger;
        DiagnozeService _diagnozeService;

        public DiagnosticActivityController(IConfiguration config, ILogger<DiagnosticActivityController> logger, DiagnozeService diagnozeService)
        {
            _logger = logger;
            _diagnozeService = diagnozeService;
        }

        [HttpGet("GetConnectionActivities")]
        public async Task<List<ConnectionActivity>> GetConnectionActivities(string upn, string tenantGroupName, string tenant, string startDate, string endDate, string outcome = null)
        {
            _logger.LogInformation($"Make api call to get connection activities of user {upn} within tenant {tenant} within tenant group {tenantGroupName}");
            string token = Request.Headers["Authorization"];
            return await _diagnozeService.GetConnectionActivities(token, upn, tenantGroupName, tenant, startDate, endDate, outcome).ConfigureAwait(false);
        }


        [HttpGet("GetManagementActivities")]
        public async Task<List<ManagementActivity>> GetManagementActivities(string upn, string tenantGroupName, string tenant, string startDate, string endDate, string outcome = null)
        {
            _logger.LogInformation($"Make api call to get management activities of user {upn} within tenant {tenant} within tenant group {tenantGroupName}");
            string token = Request.Headers["Authorization"];
            return await _diagnozeService.GetManagementActivities(token, upn, tenantGroupName, tenant, startDate, endDate, outcome).ConfigureAwait(false);
        }

        [HttpGet("GetFeedActivities")]
        public async Task<List<FeedActivity>> GetFeedActivities(string upn, string tenantGroupName, string tenant, string startDate, string endDate, string outcome = null)
        {
            _logger.LogInformation($"Make api call to get feed activities of user {upn} within tenant {tenant} within tenant group {tenantGroupName}");
            string token = Request.Headers["Authorization"];
            return await _diagnozeService.GetFeedActivities(token, upn, tenantGroupName, tenant, startDate, endDate, outcome).ConfigureAwait(false);
        }

        [HttpGet("GetActivityDetails")]
        public async Task<List<ConnectionActivity>> GetActivityDetails(string tenantGroupName,string tenant,string activityId)
        {
            _logger.LogInformation($"Make api call to get connection  activity details of activityId{activityId}");
            string token = Request.Headers["Authorization"];
            return await _diagnozeService.GetActivityHostDetails(token,tenantGroupName,tenant,activityId).ConfigureAwait(false);
        }

       
    }
}
