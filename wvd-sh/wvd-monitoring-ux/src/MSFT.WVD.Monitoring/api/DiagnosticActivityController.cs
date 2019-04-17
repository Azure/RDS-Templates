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
using MSFT.WVD.Monitoring.Models;

// For more information on enabling Web API for empty projects, visit https://go.microsoft.com/fwlink/?LinkID=397860

namespace MSFT.WVD.Monitoring.api
{
    [Route("api/[controller]")]
    [ApiController]
    public class DiagnosticActivityController : ControllerBase
    {
        private readonly ILogger _logger;
        DiagnosticActivitityBL diagnosticActivitityBL = new DiagnosticActivitityBL();
        ConfigSettings Configuration;
        public DiagnosticActivityController(IConfiguration config, ILogger<DiagnosticActivityController> logger)
        {
            Configuration = new ConfigSettings(config);
            _logger = logger;
        }

        [HttpGet("GetConnectionActivities")]
        public IActionResult GetConnectionActivities(string upn, string tenantGroupName, string tenant, string startDate, string endDate, string outcome = null)
        {
            try
            {
                string token = Request.Headers["Authorization"];
                _logger.LogInformation($"Call WVD api to get connection activity details for selected tenant group {tenantGroupName} and tenant {tenant}");

                HttpResponseMessage response = diagnosticActivitityBL.GetConnectionActivities(Configuration.RDBrokerUrl, token, upn, tenantGroupName, tenant, startDate, endDate, outcome);
                if (response.IsSuccessStatusCode)
                {
                    IEnumerable<ConnectionActivity> connectionActivities = diagnosticActivitityBL.GetConnectionActivities(response);
                    return new OkObjectResult(connectionActivities);
                }
                else
                {
                    var message = string.Empty;
                    if (response.Content != null)
                    {
                        message = !string.IsNullOrEmpty(response.Content.ReadAsStringAsync().Result) ? response.Content.ReadAsStringAsync().Result : response.ReasonPhrase;
                    }
                    return StatusCode((int)response.StatusCode, message);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError($"{ex.Message}");
                return StatusCode((int)HttpStatusCode.BadRequest, ex.Message);
            }
        }


        [HttpGet("GetManagementActivities")]
        public IActionResult GetManagementActivities(string upn, string tenantGroupName, string tenant, string startDate, string endDate, string outcome = null)
        {
            try
            {
                string token = Request.Headers["Authorization"];
                _logger.LogInformation($"Call WVD api to get management activity details for selected tenant group {tenantGroupName} and tenant {tenant}");

                HttpResponseMessage response = diagnosticActivitityBL.GetManagementActivities(Configuration.RDBrokerUrl, token, upn, tenantGroupName, tenant, startDate, endDate, outcome);
                if (response.IsSuccessStatusCode)
                {
                    IEnumerable<ManagementActivity> managementActivities = diagnosticActivitityBL.GetManagementActivities(response);
                    return new OkObjectResult(managementActivities);
                }
                else
                {
                    var message = string.Empty;
                    if (response.Content != null)
                    {
                        message = !string.IsNullOrEmpty(response.Content.ReadAsStringAsync().Result) ? response.Content.ReadAsStringAsync().Result : response.ReasonPhrase;
                    }
                    return StatusCode((int)response.StatusCode, message);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError($"{ex.Message}");
                return StatusCode((int)HttpStatusCode.BadRequest, ex.Message);
            }
        }

        [HttpGet("GetFeedActivities")]
        public IActionResult GetFeedActivities(string upn, string tenantGroupName, string tenant, string startDate, string endDate, string outcome = null)
        {
            try
            {
                string token = Request.Headers["Authorization"];
                _logger.LogInformation($"Call WVD api to get feed activity details for selected tenant group {tenantGroupName} and tenant {tenant}");

                HttpResponseMessage response = diagnosticActivitityBL.GetFeedActivities(Configuration.RDBrokerUrl, token, upn, tenantGroupName, tenant, startDate, endDate, outcome);
                if (response.IsSuccessStatusCode)
                {
                    IEnumerable<FeedActivity> feedActivities = diagnosticActivitityBL.GetFeedActivities(response);
                    return new OkObjectResult(feedActivities);
                }
                else
                {
                    var message = string.Empty;
                    if (response.Content != null)
                    {
                        message = !string.IsNullOrEmpty(response.Content.ReadAsStringAsync().Result) ? response.Content.ReadAsStringAsync().Result : response.ReasonPhrase;
                    }
                    return StatusCode((int)response.StatusCode, message);
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
