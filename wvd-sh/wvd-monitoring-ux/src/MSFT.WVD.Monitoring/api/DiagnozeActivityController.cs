using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using MSFT.WVD.Monitoring.Common.Models;
using MSFT.WVD.Monitoring.Common.Services;


// For more information on enabling Web API for empty projects, visit https://go.microsoft.com/fwlink/?LinkID=397860

namespace MSFT.WVD.Monitoring.api
{

    // [Authorize]
    // [Produces("application/json")]
    // [Route("api/DiagnozeActivity")]
    [Route("api/[controller]")]
    public class DiagnozeActivityController : Controller
    {

        ILogger _logger;
        private readonly IConfiguration _configuration;
        DiagnozeService _diagnozeService;

     

        public DiagnozeActivityController(
            DiagnozeService diagnozeService,
            IConfiguration configuration,
            ILoggerFactory logger)
        {
            _diagnozeService = diagnozeService ?? throw new ArgumentNullException(nameof(diagnozeService));
            _logger = logger?.CreateLogger<DiagnozeActivityController>() ?? throw new ArgumentNullException(nameof(logger));
            _configuration = configuration;
        }
        [HttpGet("GetConnectionActivities")]
        public async Task<List<ConnectionActivity>> GetConnectionActivities(string upn, string tenantGroupName, string tenant, string startDatetime, string endDatetime, string outcome = null)
        {
            string token = Request.Headers["Authorization"];
            return await _diagnozeService.GetConnectionActivities(token,upn,tenantGroupName,tenant,startDatetime,endDatetime,outcome).ConfigureAwait(false);
        }

      


    }
}
