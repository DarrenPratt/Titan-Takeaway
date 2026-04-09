# Project Context

- **Owner:** Darren Pratt
- **Project:** Titan-Takeaway training platform for OpenTelemetry, Prometheus, Grafana, Loki, Elasticsearch, and Jaeger.
- **Stack:** ASP.NET microservices, SQL Server, Docker, OpenTelemetry, Prometheus, Grafana, Loki, Elasticsearch, Jaeger.
- **Created:** 2026-03-25T14:13:14Z

## Learnings

- Joined team during observability stack expansion for Loki, Elasticsearch, and Jaeger.
- Priority is practical local-first guidance that supports repeatable training scenarios.
- Compose/collector path mismatches are easy to miss: lock OTel and Loki mount paths to the real `.yaml` filenames used under `infra/`.
- Optional search tooling should be profile-gated (`search`) with checked-in placeholder configs to avoid broken volume references.
