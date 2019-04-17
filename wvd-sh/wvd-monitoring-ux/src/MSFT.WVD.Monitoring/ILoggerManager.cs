using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace MSFT.WVD.Monitoring
{
    public interface ILoggerManager
    {
        void LogInfo(string message);
        void LogWarn(string message);
        void LogDebug(string message);
        void LogError(string message);
    }
}
