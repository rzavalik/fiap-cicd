var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllersWithViews();

var app = builder.Build();

app.MapGet("/", static () =>
{
    var version = System.Reflection.Assembly.GetExecutingAssembly()?.GetName()?.Version?.ToString();
    return Results.Content($"<h1>Hello World</h1><h2>build version: {version}</h2>", "text/html");
});

app.Run();