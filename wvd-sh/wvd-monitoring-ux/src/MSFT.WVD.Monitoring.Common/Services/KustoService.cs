using Kusto.Data;
using Kusto.Data.Common;
using Kusto.Data.Net.Client;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;


namespace MSFT.WVD.Monitoring.Common.Models
{
    public class KustoService
    {
        const string ConnectionString = @"Data Source=https://datfun.kusto.windows.net:443;Initial Catalog=DatFun;AAD Federated Security=True";

        public static void Connect()
        {
         
          
        }
    }
}
