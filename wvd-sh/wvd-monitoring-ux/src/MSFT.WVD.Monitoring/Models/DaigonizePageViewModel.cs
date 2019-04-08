using MSFT.WVD.Monitoring.Common.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace MSFT.WVD.Monitoring.Models
{
    public class DaigonizePageViewModel
    {
        public string upn { get; set; }
        public DateTime startDate { get; set; }
        public DateTime endDate { get; set; }
        public List<ManagementActivity> managementActivity { get; set; }
        public List<ConnectionActivity> connectionActivity { get; set; }
        public List<FeedActivity> feedActivity { get; set; }
        public ActivityType activityType {get;set;}
        public ActivityOutcome activityOutcome { get; set; }
    }


   
}
