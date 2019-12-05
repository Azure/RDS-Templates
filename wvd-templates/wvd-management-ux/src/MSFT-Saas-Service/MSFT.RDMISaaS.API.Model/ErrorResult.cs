#region "Import Namespaces"
using System;
using System.Collections.Generic;
using System.Text;
#endregion "Import Namespaces"

#region "MSFT.RDMISaaS.API.Model"
namespace MSFT.WVDSaaS.API.Model
{
    #region "ErrorResult"
    public class ErrorResult
    {
        public Error error { get; set; }
    }
    #endregion "ErrorResult"

    #region "ErrorDetails"
    public class ErrorDetails
    {
        public string code { get; set; }
        public string message { get; set; }
        public string target { get; set; }
    }
    #endregion "ErrorDetails"

    #region "Error"
    public class Error
    {
        public string code { get; set; }
        public string message { get; set; }
        public string target { get; set; }
        public List<ErrorDetails> details { get; set; }
    }
    #endregion "Error"

}
#endregion 
