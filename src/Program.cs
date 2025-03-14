namespace HelloWorldApp
{
    using Microsoft.AspNetCore.Builder;
    using Microsoft.Extensions.DependencyInjection;
    using Microsoft.Extensions.Hosting;
    using Microsoft.AspNetCore.StaticFiles;
    using Microsoft.Extensions.FileProviders;
    using Microsoft.AspNetCore.ResponseCompression;
    using System.IO;

    public class Program 
    {
        public static async Task Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            // Add the response compression services
            builder.Services.AddResponseCompression(options =>
            {
                options.Providers.Add<GzipCompressionProvider>();
            });

            // Add MVC services to the container
            builder.Services.AddControllersWithViews();

            var app = builder.Build();
            var env = app.Services.GetRequiredService<IHostEnvironment>();

            // Use response compression middleware
            app.UseResponseCompression(); 

            // Enable static files and configure caching
            app.UseStaticFiles(new StaticFileOptions
            {
                FileProvider = new PhysicalFileProvider(Path.Combine(env.ContentRootPath, "Content")),
                RequestPath = "/Content",
                OnPrepareResponse = context =>
                {
                    // Enable caching for static files
                    context.Context.Response.Headers["Cache-Control"] = "public, max-age=3600";
                }
            });

            // Use routing
            app.UseRouting();

            // Configure the HTTP request pipeline
            app.MapControllerRoute(
                name: "default",
                pattern: "{controller=Home}/{action=Index}/{id?}");

            app.Run();
        }

        public static string Version => System.Reflection.Assembly.GetExecutingAssembly()?.GetName()?.Version?.ToString();
    }
}
