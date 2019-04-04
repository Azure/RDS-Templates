using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace MSFT.WVD.Monitoring.Models
{
    public class Diagonize
    {
        public string userupn { get; set; }
        public activityType activityType { get; set; }
        public outcome outcome { get; set; }
    }
    public enum activityType
    {
        Management,
        Feed
    }
    public enum outcome
    {
        Failure,
        Success
    }
}
