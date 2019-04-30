using MSFT.WVD.Monitoring.Common.Models;
using System;

namespace MSFT.WVD.Monitoring.Models
{
    public class ErrorViewModel
    {
        public string RequestId { get; set; }
        public bool ShowRequestId => !string.IsNullOrEmpty(RequestId);
        public ErrorDetails ErrorDetails { get; set; }
    }
}