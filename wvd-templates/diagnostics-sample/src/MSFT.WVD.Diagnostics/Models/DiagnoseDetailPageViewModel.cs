using MSFT.WVD.Diagnostics.Common.Models;
using System.Collections.Generic;

namespace MSFT.WVD.Diagnostics.Models
{
    public class DiagnoseDetailPageViewModel
    {
        public ConnectionActivity ConnectionActivity { get; set; }
        public List<UserSession> UserSessions { get; set; }
        public SendMessageQuery SendMessageQuery { get; set; }
        public LogOffUserQuery LogOffUserQuery { get; set; }
        public string Title { get; set; }
        public string Message { get; set; }
        public List<MessageStatus> SendMsgStatuses { get; set; }
        public bool ShowConnectedUser { get; set; }
        public bool ShowMessageForm { get; set; }
        public VMPerformance VMPerformance { get; set; }
        public List<UserSession> selectedUsername { get; set; }
    }
}
