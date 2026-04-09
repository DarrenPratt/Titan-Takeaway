# Project Context

- **Owner:** Darren Pratt
- **Project:** Titan-Takeaway training platform for OpenTelemetry, Prometheus, Grafana, Loki, Elasticsearch, and Jaeger.
- **Stack:** ASP.NET microservices, SQL Server, Docker, OpenTelemetry, Prometheus, Grafana, Loki, Elasticsearch, Jaeger.
- **Created:** 2026-03-25T14:13:14Z

## Learnings

- Joined team during observability stack expansion for Loki, Elasticsearch, and Jaeger.
- Priority is practical local-first guidance that supports repeatable training scenarios.
- Added a local-dev Jaeger baseline with explicit env-backed settings and an OTel Collector traces pipeline that exports to Jaeger OTLP gRPC.
- Compose integration now wires `otel-collector` to `jaeger` using consistent service names and shared config mounts under `infra/`.
