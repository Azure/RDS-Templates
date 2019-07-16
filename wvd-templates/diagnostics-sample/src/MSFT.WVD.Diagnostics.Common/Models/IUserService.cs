using System;
using System.Collections.Generic;
using System.Text;

namespace MSFT.WVD.Diagnostics.Common.Models
{
    public interface IUserService
    {
        RoleAssignment SelectedRole { get; set; }
    }
}
