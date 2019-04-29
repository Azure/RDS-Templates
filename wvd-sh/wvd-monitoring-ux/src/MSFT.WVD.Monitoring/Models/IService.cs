using MSFT.WVD.Monitoring.Common.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace MSFT.WVD.Monitoring.Models
{
   public interface IService
    {
        List<ConnectionActivity> GetConnectionPaginatedResult(int currentPage, int pageSize = 10);
        int GetCount();
    }
}
