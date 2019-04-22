using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace MSFT.WVD.Monitoring.Models
{
    public class MessageStatus
    {
        public List<SendMsgStatus> SendMsgStatuses { get; set; }
    }

    public class SendMsgStatus
    {
        public string UserName { get; set;}
        public string Status { get; set; }
      

    }
}
