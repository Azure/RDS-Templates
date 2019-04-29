using Microsoft.AspNetCore.Hosting;
using MSFT.WVD.Monitoring.Common.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace MSFT.WVD.Monitoring.Models
{
    public class ActivityService : IService
    {
        public List<ConnectionActivity> GetConnectionPaginatedResult(int currentPage, int pageSize = 10)
        {
            List<ConnectionActivity> data = new List<ConnectionActivity>();
            return  data.OrderBy(d => d.activityId).Skip((currentPage - 1) * pageSize).Take(pageSize).ToList();
        }

        public int GetCount()
        {
            List<ConnectionActivity> data = new List<ConnectionActivity>();
            return data.Count;
        }
    }
}
