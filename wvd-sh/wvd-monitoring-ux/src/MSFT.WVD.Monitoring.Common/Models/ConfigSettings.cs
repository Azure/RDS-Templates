using Microsoft.Extensions.Configuration;
using System;
using System.Collections.Generic;
using System.Text;

namespace MSFT.WVD.Monitoring.Common.Models
{
   public class ConfigSettings
    {
        private IConfiguration config;
        public string RDBrokerUrl { get; set; }
        public string ApplicationID { get; set; }
        public string ResopurceUrl { get; set; }
        public string RedirectUrl { get; set; }
        public string TokenEndPoint { get; set; }
        public string AuthorizeUrl { get; set; }
        public ConfigSettings(IConfiguration configuration)
        {
            config = configuration;
            RDBrokerUrl = config.GetSection("configurations").GetSection("RDBROKER_URL").Value;
            ApplicationID = config.GetSection("configurations").GetSection("APPLICATION_ID").Value;
            ResopurceUrl = config.GetSection("configurations").GetSection("RESOURCE_URL").Value;
            RedirectUrl = config.GetSection("configurations").GetSection("REDIRECT_URL").Value;
           // TokenEndPoint = config.GetSection("configurations").GetSection("_TokenEndPoint").Value;
            AuthorizeUrl = config.GetSection("configurations").GetSection("AAD_AUTH_URL").Value; 
        }
    }
}
