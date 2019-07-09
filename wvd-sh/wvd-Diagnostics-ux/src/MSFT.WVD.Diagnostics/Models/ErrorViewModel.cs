using MSFT.WVD.Diagnostics.Common.Models;

namespace MSFT.WVD.Diagnostics.Models
{
    public class ErrorViewModel
    {
        public string RequestId { get; set; }
        public bool ShowRequestId => !string.IsNullOrEmpty(RequestId);
        public ErrorDetails ErrorDetails { get; set; }
    }
}