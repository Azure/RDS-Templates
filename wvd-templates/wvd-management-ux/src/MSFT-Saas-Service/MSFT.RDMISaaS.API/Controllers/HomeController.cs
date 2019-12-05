#region "Imports/Namespaces"
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
#endregion "Imports/Namespaces" 
#region "MSFT.WVDSaaS.API.Controllers"
namespace MSFT.WVDSaaS.API.Controllers
{
    #region "Class - HomeController"
    public class HomeController : Controller
    {
        public ActionResult Index()
        {
            ViewBag.Title = "Home Page";

            return View();
        }
    }
    #endregion  "Class - HomeController"
}
#endregion "MSFT.RDMISaaS.API.Controllers" 