using System;
using System.Collections.Generic;

namespace MSFT.WVD.Diagnostics.Common.Models
{
    public class VMPerformance
    {
        public List<Counter> CurrentStateCounters { get; set; }
        public bool isHealthy { get; set; }
        public string Message { get; set; }
    }

    public class Counter
    {
        public int id { get; set; }
        public string ObjectName { get; set; }
        public string CounterName { get; set; }
        public decimal avg { get; set; }
        public decimal Value { get; set; }
        public string Computer { get; set; }
        public string Status { get; set; }
    }
}
