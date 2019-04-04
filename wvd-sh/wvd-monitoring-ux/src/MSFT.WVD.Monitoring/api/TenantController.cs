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
    public class TenantController : Controller
    {
        TenantBL tenantBL = new TenantBL();
        ConfigSettings Configuration;
        public TenantController(IConfiguration config)
        {
            Configuration = new ConfigSettings(config);
        }
        // GET: api/<controller>
        [HttpGet]
        public IEnumerable<Tenant> Get(string accessToken,string tenantGroup )
        {
            return tenantBL.GetTenants(Configuration.RDBrokerUrl, accessToken, tenantGroup);
        }

       
        

       

        
    }
}
