# Project Context

- **Owner:** Darren Pratt
- **Project:** Titan-Takeaway training platform for OpenTelemetry, Prometheus, and Grafana.
- **Stack:** ASP.NET microservices, SQL Server, Docker, OpenTelemetry, Prometheus, Grafana, Bootstrap, JavaScript, HTML, CSS.
- **Created:** 2026-03-25T11:52:26Z

## Learnings

- Initial squad cast selected from Marvel Cinematic Universe for this repository.
- Core training scenarios include payment failures, kitchen latency, stuck orders, and retry storms.

### Architecture Foundation (2026-03-25)

- **Owner:** Peter
- **Impact:** Build frontend in Ordering API `wwwroot/`. Bootstrap + vanilla JavaScript. Entry point for all user interactions.
- **Key:** Frontend served from Ordering API to avoid separate container; focus on observability, not frontend build systems.

### Frontend Shell Scaffold (2026-03-25)

- **Owner:** Peter
- **Impact:** Added standalone ASP.NET Razor Pages shell at `frontend/web-app/` with Bootstrap layout and observability quick links.
- **Key:** Landing page intentionally uses health placeholders (`Unknown`) and page-scoped static asset folders (`wwwroot/css/pages`, `wwwroot/js/pages`) to keep scope minimal but ready for incremental health polling.
- **Buildability:** Added `frontend/web-app/Dockerfile` (multi-stage .NET 10 build/runtime, port 8080) and verified with `dotnet build frontend/web-app/web-app.csproj`.
