# Project Context

- **Owner:** Darren Pratt
- **Project:** Titan-Takeaway training platform for OpenTelemetry, Prometheus, and Grafana.
- **Stack:** ASP.NET microservices, SQL Server, Docker, OpenTelemetry, Prometheus, Grafana, Bootstrap, JavaScript, HTML, CSS.
- **Created:** 2026-03-25T11:52:26Z

## Learnings

- Initial squad cast selected from Marvel Cinematic Universe for this repository.
- Core training scenarios include payment failures, kitchen latency, stuck orders, and retry storms.

### Architecture Foundation (2026-03-25)

- **Owner:** Clint
- **Impact:** Design tests around four-service architecture with schema-per-service isolation. Evaluate Testcontainers vs docker-compose for integration tests.
- **Key:** Services must NOT query across schema boundaries; tests should cover failure injection, chaos scenarios, and trace propagation.

### Build Validation Tooling (2026-03-25)

- **Owner:** Clint
- **Impact:** Added a minimal PowerShell-friendly validation script set for startup/build readiness:
  - `scripts/validate-required-files.ps1` (required file presence checks)
  - `scripts/validate-compose-config.ps1` (runs `docker compose config`)
  - `scripts/list-service-build-commands.ps1` (prints per-service `dotnet build` commands)
- **Key:** In early-stage repos where compose files may not yet exist, validation must fail fast with clear output so setup gaps are visible before runtime debugging.
