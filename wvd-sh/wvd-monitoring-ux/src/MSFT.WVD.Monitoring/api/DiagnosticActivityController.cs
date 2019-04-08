using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using MSFT.WVD.Monitoring.Common.BAL;
using MSFT.WVD.Monitoring.Common.Models;
using MSFT.WVD.Monitoring.Models;

// For more information on enabling Web API for empty projects, visit https://go.microsoft.com/fwlink/?LinkID=397860

namespace MSFT.WVD.Monitoring.api
{
    [Route("api/[controller]")]
    public class DiagnosticActivityController : Controller
    {
        DiagnosticActivitityBL diagnosticActivitityBL = new DiagnosticActivitityBL();
        ConfigSettings Configuration;
        public DiagnosticActivityController(IConfiguration config)
        {
            Configuration = new ConfigSettings(config);
        }

        [HttpGet("GetConnectionActivities")]
        public IEnumerable<ConnectionActivity> GetConnectionActivities( string upn, string tenantGroupName, string tenant, string startDate, string endDate, Nullable<int> outcome)
        {
            string token = Request.Headers["Authorization"];
            return diagnosticActivitityBL.GetConnectionActivities(Configuration.RDBrokerUrl, token, upn, tenantGroupName, tenant, startDate, endDate, outcome);
        }


        [HttpGet("GetManagementActivities")]
        public IEnumerable<ManagementActivity> GetManagementActivities( string upn, string tenantGroupName, string tenant, string startDate, string endDate,  Nullable<int> outcome)
        {
            string token = Request.Headers["Authorization"];
            return diagnosticActivitityBL.GetManagementActivities(Configuration.RDBrokerUrl, token, upn, tenantGroupName, tenant, startDate, endDate,  outcome);
        }

        [HttpGet("GetFeedActivities")]
        public IEnumerable<FeedActivity> GetFeedActivities( string upn, string tenantGroupName, string tenant, string startDate, string endDate,  Nullable<int> outcome)
        {
            string token = Request.Headers["Authorization"];
            return diagnosticActivitityBL.GetFeedActivities(Configuration.RDBrokerUrl, token, upn, tenantGroupName, tenant, startDate, endDate,  outcome);
        }
    }
}
