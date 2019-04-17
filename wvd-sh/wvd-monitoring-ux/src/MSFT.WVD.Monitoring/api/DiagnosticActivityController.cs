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
    public class DiagnosticActivityController : Controller
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
        public IEnumerable<ConnectionActivity> GetConnectionActivities(string upn, string tenantGroupName, string tenant, string startDate, string endDate, string outcome = null)
        {
            try
            {
                string token = Request.Headers["Authorization"];
                _logger.LogInformation($"Call WVD api to get connection activity details for selected tenant group {tenantGroupName} and tenant {tenant}");

                return diagnosticActivitityBL.GetConnectionActivities(Configuration.RDBrokerUrl, token, upn, tenantGroupName, tenant, startDate, endDate, outcome);
            }
            catch (Exception ex)
            {

                return new List<ConnectionActivity>
                   {
                       new ConnectionActivity
                       {
                           ErrorDetails= new ErrorDetails
                           {
                               StatusCode=(int)HttpStatusCode.InternalServerError,
                               Message= ex.Message.ToString()
                           }
                       }
                   };
            }
        }


        [HttpGet("GetManagementActivities")]
        public IEnumerable<ManagementActivity> GetManagementActivities(string upn, string tenantGroupName, string tenant, string startDate, string endDate, string outcome = null)
        {
            try
            {
                string token = Request.Headers["Authorization"];
                _logger.LogInformation($"Call WVD api to get management activity details for selected tenant group {tenantGroupName} and tenant {tenant}");

                return diagnosticActivitityBL.GetManagementActivities(Configuration.RDBrokerUrl, token, upn, tenantGroupName, tenant, startDate, endDate, outcome);
            }
            catch (Exception ex)
            {
                return new List<ManagementActivity>
                   {
                       new ManagementActivity
                       {
                           ErrorDetails= new ErrorDetails
                           {
                               StatusCode=(int)HttpStatusCode.InternalServerError,
                               Message= ex.Message.ToString()
                           }
                       }
                   };
            }
        }

        [HttpGet("GetFeedActivities")]
        public IEnumerable<FeedActivity> GetFeedActivities(string upn, string tenantGroupName, string tenant, string startDate, string endDate, string outcome = null)
        {
            try
            {
                string token = Request.Headers["Authorization"];
                _logger.LogInformation($"Call WVD api to get feed activity details for selected tenant group {tenantGroupName} and tenant {tenant}");

                return diagnosticActivitityBL.GetFeedActivities(Configuration.RDBrokerUrl, token, upn, tenantGroupName, tenant, startDate, endDate, outcome);
            }
            catch (Exception ex)
            {
                return new List<FeedActivity>
                   {
                       new FeedActivity
                       {
                           ErrorDetails= new ErrorDetails
                           {
                               StatusCode=(int)HttpStatusCode.InternalServerError,
                               Message= ex.Message.ToString()
                           }
                       }
                   };
            }

        }
    }
}
