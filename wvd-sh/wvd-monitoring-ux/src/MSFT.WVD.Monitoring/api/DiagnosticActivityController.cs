using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using MSFT.WVD.Monitoring.Common.BAL;
using MSFT.WVD.Monitoring.Common.Models;

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
        public IEnumerable<ConnectionActivity> GetConnectionActivities(string accessToken, string upn, string tenantGroupName, string tenant, DateTime startDate, DateTime endDate,  Nullable<int> outcome)
        {
            return diagnosticActivitityBL.GetConnectionActivities(Configuration.RDBrokerUrl, accessToken, upn, tenantGroupName, tenant, startDate, endDate, outcome);
        }


        [HttpGet("GetManagementActivities")]
        public IEnumerable<ManagementActivity> GetManagementActivities(string accessToken, string upn, string tenantGroupName, string tenant, DateTime startDate, DateTime endDate,  Nullable<int> outcome)
        {
            return diagnosticActivitityBL.GetManagementActivities(Configuration.RDBrokerUrl, accessToken, upn, tenantGroupName, tenant, startDate, endDate,  outcome);
        }

        [HttpGet("GetFeedActivities")]
        public IEnumerable<FeedActivity> GetFeedActivities(string accessToken, string upn, string tenantGroupName, string tenant, DateTime startDate, DateTime endDate,  Nullable<int> outcome)
        {
            return diagnosticActivitityBL.GetFeedActivities(Configuration.RDBrokerUrl, accessToken, upn, tenantGroupName, tenant, startDate, endDate,  outcome);
        }
    }
}
