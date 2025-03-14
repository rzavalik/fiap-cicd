namespace HelloWorldApp.Controllers
{
    using Microsoft.AspNetCore.Mvc;

    public class HomeController : Controller
    {
        public IActionResult Index()
        {
            ViewData["Version"] = Program.Version;
            return View();
        }
    }
}
