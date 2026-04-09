# Project Context

- **Owner:** Darren Pratt
- **Project:** Titan-Takeaway training platform for OpenTelemetry, Prometheus, and Grafana.
- **Stack:** ASP.NET microservices, SQL Server, Docker, OpenTelemetry, Prometheus, Grafana, Bootstrap, JavaScript, HTML, CSS.
- **Created:** 2026-03-25T11:52:26Z

## Learnings

- Initial squad cast selected from Marvel Cinematic Universe for this repository.
- Core training scenarios include payment failures, kitchen latency, stuck orders, and retry storms.

### Architecture Foundation (2026-03-25)

- **Owner:** Rocket
- **Impact:** Docker Compose setup for four services + SQL Server + OTel Collector + Prometheus + Jaeger + Grafana. All services export OTLP to OTel Collector.
- **Key:** Single SQL Server with schema-per-service; OTel Collector routes to Prometheus (metrics) and Jaeger (traces); Grafana for dashboards.

### Observability Infrastructure Documentation (2026-03-25)

- **Owner:** Rocket
- **Task:** Document infrastructure impact of expanded observability stack (Elasticsearch, Loki, Jaeger promoted to core)
- **Changes Made:**
  - Updated README.md with resource requirements (min 8GB, recommended 16GB, comfortable 32GB)
  - Added detailed memory allocation breakdown for 12-container stack (~12GB total recommended)
  - Documented startup order with 5 dependency levels (Elasticsearch cold start: 30-60s)
  - Added Docker Compose profiles for resource-constrained environments (minimal, lite, traces-only, logs-only, full)
  - Added staged startup guide for 8GB machines
  - Updated Quick Start with prerequisites and resource cautions
  - Created decision document: `.squad/decisions/inbox/rocket-infra-observability-additions.md`
- **Key Insights:**
  - Full stack requires ~12GB RAM (not including OS overhead)
  - Elasticsearch is the heaviest component (2GB Java heap) and slowest to start (30-60s)
  - Docker Compose profiles enable progressive training: Day 1 (lite) → Day 2 (metrics) → Day 3 (full stack)
  - 8GB machines need staged startup or profiles to avoid memory pressure
- **Next Steps (Pending Team Approval):**
  - Implement compose profiles in `infra/docker/docker-compose.yml`
  - Add Elasticsearch healthchecks and heap limits
  - Update training module docs to reference profiles
  - Test full startup on 8GB/16GB/32GB reference machines

### Runtime Infrastructure Scaffold (2026-03-26)

- **Owner:** Rocket
- **Task:** Scaffold local runtime infrastructure with progressive compose profiles and baseline observability configs.
- **Changes Made:**
  - Added root `docker-compose.yml` with `minimal`, `lite`, and `full` profiles.
  - Included SQL Server, OTel Collector, Prometheus, Grafana, Jaeger, Loki, with optional Elasticsearch/Kibana in `full`.
  - Added/updated baseline infra configs at:
    - `infra/otel-collector/config.yaml`
    - `infra/prometheus/prometheus.yml`
    - `infra/grafana/provisioning/datasources/datasources.yml`
    - `infra/loki/loki-config.yml`
    - `infra/elasticsearch/elasticsearch.yml`
  - Ensured all compose bind mounts target existing repository paths.
  - Validated compose syntax with `docker compose -f docker-compose.yml config --quiet`.
- **Key Insights:**
  - Keeping `minimal` profile metrics-first (SQL + OTel + Prometheus + Grafana) supports day-one observability without heavier trace/log stores.
  - `lite` profile adds Jaeger + Loki for full three-pillar learning while staying lighter than Elasticsearch-backed setups.
  - Elasticsearch/Kibana should stay profile-gated due to memory footprint and slower startup.
- **Follow-ups:**
  - Wire service containers into the same compose as service projects stabilize.
  - Add healthchecks for Jaeger/Loki/Kibana once startup SLOs are defined.

### Application Services Integration (2026-03-26)

- **Owner:** Rocket
- **Task:** Integrated all 5 application services (ordering-api, payment-service, kitchen-service, delivery-service, web-app) into docker-compose.yml.
- **Changes Made:**
  - Added 5 application service definitions to docker-compose.yml:
    - **ordering-api** (port 5000) - Main API gateway
    - **payment-service** (port 5001) - Payment processing microservice
    - **kitchen-service** (port 5002) - Kitchen order management
    - **delivery-service** (port 5003) - Delivery tracking
    - **web-app** (port 8080) - ASP.NET Razor Pages frontend
  - Configured OpenTelemetry environment variables:
    - OTEL_EXPORTER_OTLP_ENDPOINT pointing to otel-collector:4317 (gRPC)
    - OTEL_SERVICE_NAME for each service
  - Added SQL Server connection strings with TrustServerCertificate=True for all backend services
  - Configured dependencies: All services depend on sqlserver (health) + otel-collector
  - Web-app depends on ordering-api (backend communication)
  - Added `restart: unless-stopped` policy for resilience
  - Integrated services into profile system:
    - **app profile**: Just application services (for standalone app testing)
    - **full profile**: Complete stack (infra + apps)
    - **minimal/lite profiles**: Remain infra-only for progressive learning
- **Key Insights:**
  - All services are ASP.NET 10.0 with identical Dockerfile patterns (multi-stage build)
  - Web-app is ASP.NET Razor Pages (not React/Vue), treated as a .NET service
  - Port mapping: 5000-5003 for backend services, 8080 for frontend
  - All services use same SQL Server database with schema-per-service isolation
  - Services share default bridge network for inter-service communication
  - Build contexts point to service-specific directories (./services/*, ./frontend/web-app)
- **Profile Usage:**
  - `docker compose --profile minimal up` - Infra only: sqlserver, otel-collector, prometheus, grafana (4 containers)
  - `docker compose --profile lite up` - Infra with traces/logs: + jaeger, loki (6 containers)
  - `docker compose --profile app up` - Apps + dependencies: sqlserver, otel-collector, 5 apps (7 containers)
  - `docker compose --profile full up` - Complete stack: all infra + apps (13 containers)
- **Next Steps:**
  - Add health checks for application services (once endpoints are defined)
  - Consider adding service-to-service URLs as environment variables
  - Test full stack startup and verify service connectivity
  - Add resource limits (CPU/memory) for production-like testing

### Container Runtime Fixes (2026-03-25)

- **Owner:** Rocket
- **Task:** Fixed two critical container runtime issues: Loki config schema compatibility and frontend service URLs.
- **Changes Made:**
  - **Loki Configuration (infra/loki/loki-config.yaml):**
    - Updated schema from `boltdb-shipper` (v11) to `tsdb` (v13) to match Loki 3.1.1
    - Removed deprecated fields: `storage_config.boltdb_shipper.shared_store`, `limits_config.enforce_metric_name`, `table_manager`, `chunk_store_config.max_look_back_period`
    - Removed deprecated `table_manager` and `chunk_store_config` sections entirely
    - Updated compactor: removed `shared_store`, changed working directory, added `delete_request_store: filesystem` for retention support
    - Result: Loki now starts successfully without schema validation errors
  - **Frontend Service URLs (frontend/web-app/Pages/Index.cshtml, _Layout.cshtml):**
    - Fixed incorrect port mappings in service health cards and navigation links
    - Updated ordering-api: 5100 → 5000
    - Updated payment-service: 5200 → 5001
    - Updated kitchen-service: 5300 → 5002
    - Updated delivery-service: 5400 → 5003
    - Result: Frontend now displays correct localhost URLs matching docker-compose port mappings
- **Key Insights:**
  - Loki 3.x uses TSDB (Time Series Database) index, not BoltDB-shipper from 2.x
  - Schema v13 is the current recommended schema for Loki 3.1.1
  - Retention requires `delete_request_store` config in compactor section
  - Frontend is a static landing page with hardcoded links (not dynamic service discovery)
  - Port mappings in docker-compose are `host:container` format: 5000:8080 means localhost:5000 → container:8080
  - Web-app rebuilds require `--no-cache` flag to ensure static file changes are picked up
- **Testing Verification:**
  - Loki container: Started successfully, logs show "Loki started" with 410ms startup time
  - Ordering API: Health check returns `{"status":"healthy","sqlServerConfigured":true}`
  - Web-app: All service URLs now display correct ports (5000-5003) when accessed at localhost:8080
  - All three containers running stably with no restart loops
- **Loki Version Notes:**
  - Running: grafana/loki:3.1.1
  - Schema progression: v11 (legacy) → v12 (transitional) → v13 (current TSDB)
  - Major breaking change from 2.x to 3.x: BoltDB-shipper deprecated in favor of TSDB
  - For training purposes, using filesystem storage (single-binary mode) instead of S3/GCS

