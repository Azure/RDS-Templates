using MSFT.WVD.Monitoring.Common.Models;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Threading.Tasks;

namespace MSFT.WVD.Monitoring.Models
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
    }
}
