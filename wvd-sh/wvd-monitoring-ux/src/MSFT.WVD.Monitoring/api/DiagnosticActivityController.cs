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

        // GET: api/<controller>
        [HttpGet("GetActivityDetails")]
        public List<DiagnosticActivity> GetActivityDetails(string accessToken,string tenantGroup,string tenant,DateTime startDate,DateTime endDate,int activityType,int outcome)
        {
            return diagnosticActivitityBL.GetActivityDetails(Configuration.RDBrokerUrl, accessToken, tenantGroup, tenant, startDate, endDate, activityType, outcome);
        }

       
    }
}
