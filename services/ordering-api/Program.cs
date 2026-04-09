var builder = WebApplication.CreateBuilder(args);

const string serviceName = "ordering-api";
var sqlConnectionString =
    Environment.GetEnvironmentVariable("SQLSERVER_CONNECTION_STRING")
    ?? builder.Configuration.GetConnectionString("DefaultConnection")
    ?? builder.Configuration["SqlServer:ConnectionString"];

var app = builder.Build();

app.MapGet("/", () => Results.Ok(new { service = serviceName, status = "running" }));
app.MapGet("/health", () => Results.Ok(new
{
    service = serviceName,
    status = "healthy",
    sqlServerConfigured = !string.IsNullOrWhiteSpace(sqlConnectionString),
    timestamp = DateTimeOffset.UtcNow
}));

app.Run();
