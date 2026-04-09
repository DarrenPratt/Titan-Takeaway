# Project Context

- **Owner:** Darren Pratt
- **Project:** Titan-Takeaway training platform for OpenTelemetry, Prometheus, and Grafana.
- **Stack:** ASP.NET microservices, SQL Server, Docker, OpenTelemetry, Prometheus, Grafana, Bootstrap, JavaScript, HTML, CSS.
- **Created:** 2026-03-25T11:52:26Z

## Learnings

- Initial squad cast selected from Marvel Cinematic Universe for this repository.
- Core training scenarios include payment failures, kitchen latency, stuck orders, and retry storms.

### Architecture Foundation (2026-03-25)

- **Owner:** Bruce
- **Impact:** Implements four services (Ordering, Payment, Kitchen, Delivery) with schema-per-service isolation. Services must NOT query across schema boundaries. HTTP sync communication for inter-service calls.
- **Key:** Services implement EF Core migrations, chaos simulation via env vars, and Admin API endpoints for failure injection.

### Service Scaffold Delivery (2026-03-25)

- **Owner:** Bruce
- **Impact:** Scaffolded runnable ASP.NET services under `services/ordering-api`, `services/payment-service`, `services/kitchen-service`, and `services/delivery-service` using minimal API bootstrap + `/health`.
- **Key:** Added SQL Server-ready defaults in `appsettings.json` per service, with runtime env override support via `SQLSERVER_CONNECTION_STRING` and configuration fallbacks.
- **Ops:** Added Dockerfiles for each service and a shared `Titan-Takeaway.Services.slnx` for grouped build operations.
