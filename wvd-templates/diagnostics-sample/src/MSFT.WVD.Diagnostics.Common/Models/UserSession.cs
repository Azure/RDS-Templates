using System;
using System.Collections.Generic;
using System.Net;
using System.Text;

namespace MSFT.WVD.Diagnostics.Common.Models
{
    public class UserSession
    {
        public string tenantGroupName { get; set; }
        public string tenantName { get; set; }
        public string hostPoolName { get; set; }
        public string sessionHostName { get; set; }
        public string userPrincipalName { get; set; }
        public int sessionId { get; set; }
        public string applicationType { get; set; }
        public string adUserName { get; set; }
        public bool IsSelected { get; set; }
        public ErrorDetails ErrorDetails { get; set; }
        public HttpStatusCode httpStatus { get; set; }
    }

    public class SendMessageQuery
    {
        public string tenantGroupName { get; set; }
        public string tenantName { get; set; }
        public string hostPoolName { get; set; }
        public string sessionHostName { get; set; }
        public int sessionId { get; set; }
        public string messageTitle { get; set; }
        public string messageBody { get; set; }
        public string userPrincipalName { get; set; }
        public string adUserName { get; set; }
    }

    public class LogOffUserQuery
    {
        public string tenantGroupName { get; set; }
        public string tenantName { get; set; }
        public string hostPoolName { get; set; }
        public string sessionHostName { get; set; }
        public int sessionId { get; set; }
        public string adUserName { get; set; }
    }
}
