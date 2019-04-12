using System;
using System.Collections.Generic;
using System.Text;

namespace MSFT.WVD.Monitoring.Common.Models
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
    }

    public class LogOffUserQuery
    {
        public string tenantGroupName { get; set; }
        public string tenantName { get; set; }
        public string hostPoolName { get; set; }
        public string sessionHostName { get; set; }
        public int sessionId { get; set; }
    }
}
