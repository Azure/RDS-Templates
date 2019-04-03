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


    [Route("api/[controller]")]
    public class LoginController : ControllerBase
    {
        LoginBL loginbl = new LoginBL();
        ConfigSettings Configuration;
        public LoginController(IConfiguration config)
        {
            Configuration = new ConfigSettings(config);
        }
        // POST api/<controller>
        [HttpPost]
        public IActionResult Post([FromBody]LoginDetails data)
        {
            LoginDetails loginDetails;
            try
            {
                loginDetails = loginbl.Login(data.code, Configuration);
            }
            catch 
            {
                loginDetails = null;
            }
            return Ok(loginDetails);
        }

        
        [HttpGet]
        public IActionResult Get()
        {
          return Ok($"{Configuration.AuthorizeUrl}?client_id={Configuration.ApplicationID}&response_type=code&redirect_uri={Configuration.RedirectUrl}&response_mode=query&resource={Configuration.ResopurceUrl}&state={Guid.NewGuid().ToString()}");
        }

        //// GET: api/<controller>
        //[HttpGet]
        //public IEnumerable<string> Get()
        //{
        //    return new string[] { "value1", "value2" };
        //}

        //// GET api/<controller>/5
        //[HttpGet("{id}")]
        //public string Get(int id)
        //{
        //    return "value";
        //}

       

        // PUT api/<controller>/5
        [HttpPut("{id}")]
        public void Put(int id, [FromBody]string value)
        {
        }

        // DELETE api/<controller>/5
        [HttpDelete("{id}")]
        public void Delete(int id)
        {
        }
    }
}
