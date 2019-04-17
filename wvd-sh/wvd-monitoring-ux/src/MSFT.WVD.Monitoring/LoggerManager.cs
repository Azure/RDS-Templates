using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace MSFT.WVD.Monitoring
{
    public class LoggerManager : ILoggerManager
    {
        private static ILogger logger;//= LogManager.GetCurrentClassLogger();

        public LoggerManager()
        {
        }
        public void LogDebug(string message)
        {
            logger.LogDebug(message);
        }

        public void LogError(string message)
        {
            logger.LogError(message);

        }

        public void LogInfo(string message)
        {
            logger.LogInformation(message);

        }

        public void LogWarn(string message)
        {
            logger.LogWarning(message);
        }
    }
}
