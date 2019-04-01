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
            RDBrokerUrl = config.GetSection("configurations").GetSection("_RdBrokerUrl").Value;
            ApplicationID = config.GetSection("configurations").GetSection("_ApplicationId").Value;
            ResopurceUrl = config.GetSection("configurations").GetSection("_ResourceUrl").Value;
            RedirectUrl = config.GetSection("configurations").GetSection("_RedirectUrl").Value;
            TokenEndPoint = config.GetSection("configurations").GetSection("_TokenEndPoint").Value;
            AuthorizeUrl = config.GetSection("configurations").GetSection("_AuthorizeUrl").Value; 
        }
    }
}
