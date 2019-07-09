using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Text;

namespace MSFT.WVD.Diagnostics.Common.Models
{
    public class LoginDetails
    {
        public string code { get; set; }
        public string access_token { get; set; }
        public string refresh_token { get; set; }
        public string upn { get; set; }
        public string name { get; set; }
        public LoginError error { get; set; }
        public JArray roleAssignments { get; set; }
        public string[] tenantGroups { get; set; }
    }

    public class LoginError
    {
        public int StatusCode { get; set; }
        public string Message { get; set; }
    }

   
}
