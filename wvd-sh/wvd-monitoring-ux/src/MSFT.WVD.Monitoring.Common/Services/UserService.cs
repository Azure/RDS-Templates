using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using MSFT.WVD.Monitoring.Common.Models;
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Text;

namespace MSFT.WVD.Monitoring.Common.Services
{
    public class UserService
    {
        IMemoryCache _cache;

        public UserService(IMemoryCache memoryCache)
        {
            _cache = memoryCache ?? throw new ArgumentException(nameof(memoryCache));
        }

        //public UserInfo GetUserDetails()
        //{

         
        //    // get user data from cache memory
        //    var tenantGroup = _cache.Get<string>("SelectedTenantGroupName");
        //    var SelectedTenantName = _cache.Get<string>("SelectedTenantName");
        //    var token = _cache.Get<string>("AccessToken");
        //    return new UserInfo()
        //    {
        //        tenantGroupName = tenantGroup,
        //        tenant = SelectedTenantName,
        //        accessToken = token
        //    };
        //}

    }
}
