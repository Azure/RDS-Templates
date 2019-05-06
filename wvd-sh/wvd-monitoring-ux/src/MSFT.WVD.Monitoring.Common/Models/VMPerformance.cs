using System;
using System.Collections.Generic;
using System.Text;

namespace MSFT.WVD.Monitoring.Common.Models
{
    public class VMPerformance
    {
        public Counter Counters { get; set; }
    }

    public class Counter
    {
        public bool ProcessorUtilization { get; set; }
        public bool DiskUtilization { get; set; }
        public bool MemoryUtilization { get; set; }
    }

    public class QueryDetails
    {
        public string query { get; set; }
    }
}
