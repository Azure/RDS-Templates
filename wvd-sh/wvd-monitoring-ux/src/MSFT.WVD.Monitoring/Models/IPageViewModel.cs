using MSFT.WVD.Monitoring.Common.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace MSFT.WVD.Monitoring.Models
{
    public interface IPageViewModel
    {
         RoleAssignment SelectedRole { get; set; }
    }
}
