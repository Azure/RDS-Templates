using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json.Linq;
using System.Web;
using MSFT.WVD.Monitoring.Common.BAL;
using Microsoft.Extensions.Configuration;
using MSFT.WVD.Monitoring.Common.Models;

// For more information on enabling Web API for empty projects, visit https://go.microsoft.com/fwlink/?LinkID=397860

namespace MSFT.WVD.Monitoring.api
{
    [Route("api/RoleAssignment")]
    public class RoleAssignmentController : ControllerBase
    {
        RoleAssignmentBL roleAssignmentBL = new RoleAssignmentBL();
        ConfigSettings Configuration;
        public RoleAssignmentController(IConfiguration config)
        {
            Configuration = new ConfigSettings(config);
        }
        // GET: api/<controller>
        [HttpGet("TenantGroups")]
        public IEnumerable<RoleAssignment> TenantGroups(string accessToken,string upn)
        {
           return roleAssignmentBL.GetTenantGroups(Configuration.RDBrokerUrl, accessToken, upn);
        }
    }
}
