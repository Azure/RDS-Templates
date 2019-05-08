using System;
using System.Collections.Generic;
using System.Text;

namespace MSFT.WVD.Monitoring.Common.Models
{
    public class VMPerformance
    {
        public List<Counter> CurrentStateCounters { get; set; }
        //public List<Counter> TimeFrameCounters { get; set; }
    
    }

    public class Counter
    {
        public string ObjectName { get; set; }
        public string CounterName { get; set; }
        public long avg { get; set; }
        public long Value { get; set; }
        public string Computer { get; set; }
        public bool Status { get; set; }
    }


}
