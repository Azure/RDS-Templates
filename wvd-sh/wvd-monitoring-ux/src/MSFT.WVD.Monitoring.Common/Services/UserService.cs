using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using MSFT.WVD.Monitoring.Common.Models;
using System;
using System.Collections.Generic;
using System.Text;

namespace MSFT.WVD.Monitoring.Common.Services
{
    public class UserService
    {
        IConfiguration _config;
        ILogger _logger;
        IMemoryCache _cache;

        public UserService(IConfiguration configuration, ILoggerFactory logger, IMemoryCache memoryCache)
        {
            _logger = logger?.CreateLogger<UserService>() ?? throw new ArgumentNullException(nameof(logger));
            _config = configuration ?? throw new ArgumentNullException(nameof(configuration));
            _cache = memoryCache ?? throw new ArgumentException(nameof(memoryCache));
        }

        public UserInfo GetUserData()
        {
            // get user data from cache memory
            var tenantGroup = _cache.Get<string>("SelectedTenantGroupName");
            var SelectedTenantName = _cache.Get<string>("SelectedTenantName");

            return new UserInfo()
            {
                tenantGroupName = tenantGroup,
                tenant = SelectedTenantName
            };
        }

    }
}
