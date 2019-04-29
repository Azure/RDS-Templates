using System;
using System.Collections.Generic;
using System.Text;

namespace MSFT.WVD.Monitoring.Common.Models
{
    public interface IUserService
    {
        RoleAssignment SelectedRole { get; set; }
        //RoleAssignment SaveUser();
    }
}
