using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using MSFT.WVD.Monitoring.Common.BAL;
using MSFT.WVD.Monitoring.Common.Models;

// For more information on enabling Web API for empty projects, visit https://go.microsoft.com/fwlink/?LinkID=397860

namespace MSFT.WVD.Monitoring.api
{
    [Route("api/[controller]")]
    public class SessionHostController : Controller
    {
        SessionHostBL sessionHostBL = new SessionHostBL();
        ConfigSettings Configuration;
        public SessionHostController(IConfiguration config)
        {
            Configuration = new ConfigSettings(config);
        }
        // GET: api/<controller>
        [HttpGet("GetUserSessions")]
        public IEnumerable<UserSession> GetUserSessions(string tenantGroupName,string tenant,string hostPoolName, string sessionHostName)
        {
            string token = Request.Headers["Authorization"];
            return sessionHostBL.GetUserSessions(Configuration.RDBrokerUrl, token, tenantGroupName, tenant, hostPoolName, sessionHostName);
        }

       
        // POST api/<controller>
        [HttpPost("SendMessage")]
        public HttpResponseMessage SendMessage(SendMessageQuery sendMessageQuery)
        {
            string token = Request.Headers["Authorization"];
            return sessionHostBL.SendMessage(Configuration.RDBrokerUrl, token, sendMessageQuery);
        }

        [HttpPost("LogOffUser")]
        public HttpResponseMessage LogOffUser(LogOffUserQuery logOffUserQuery)
        {
            string token = Request.Headers["Authorization"];
            return sessionHostBL.LogOffUser(Configuration.RDBrokerUrl, token, logOffUserQuery);
        }


    }
}
