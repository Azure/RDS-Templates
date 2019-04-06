using MSFT.WVD.Monitoring.Common.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace MSFT.WVD.Monitoring.Models
{
    public class DaigonisepageModel
    {
        public string upn { get; set; }
        public DateTime startdate { get; set; }
        public DateTime enddate { get; set; }
        public string activitytype { get; set; }
        public string outcome { get; set; }
        public List<ManagementActivity> managementActivity { get; set; }
        public List<ConnectionActivity> connectionActivity { get; set; }
        public List<FeedActivity> feedActivity { get; set; }
        public ActivityType activityType {get;set;}
        public ActivityOutcome activityOutcome { get; set; }
    }

}
