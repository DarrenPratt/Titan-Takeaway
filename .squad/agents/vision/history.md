# Project Context

- **Owner:** Darren Pratt
- **Project:** Titan-Takeaway training platform for OpenTelemetry, Prometheus, and Grafana.
- **Stack:** ASP.NET microservices, SQL Server, Docker, OpenTelemetry, Prometheus, Grafana, Bootstrap, JavaScript, HTML, CSS.
- **Created:** 2026-03-25T11:52:26Z

## Learnings

- Initial squad cast selected from Marvel Cinematic Universe for this repository.
- Core training scenarios include payment failures, kitchen latency, stuck orders, and retry storms.

### Architecture Foundation (2026-03-25)

- **Owner:** Vision
- **Impact:** Configure OTel Collector pipeline. Decide on Jaeger vs Zipkin for trace backend. Set up Prometheus scrape config and Grafana datasources + dashboards.
- **Key:** All services export OTLP to OTel Collector; Collector aggregates and routes to metrics/traces backends.

### Observability Pipeline Design (2026-03-25)

- **Owner:** Vision
- **Task:** Design comprehensive observability pipeline with OpenTelemetry, Prometheus, Grafana, Loki, Jaeger, and Elasticsearch
- **Key Decisions:**
  - **Jaeger over Zipkin:** Better OTLP support, richer feature set (service graphs, trace comparison), lower memory footprint
  - **Loki as primary log backend:** 10x lower memory (~150MB vs 1.5GB for Elasticsearch), sufficient for 90% of training scenarios, LogQL aligns with PromQL learning
  - **Elasticsearch as optional:** Enable via Docker Compose profile for advanced full-text search exercises only
  - **OTel Collector as aggregation layer:** Decouples services from backends, enables batching, production-realistic pattern
  - **In-memory Jaeger storage:** No persistence needed for 1-2 hour training sessions, simplifies operations
- **Signal Flow Documentation:**
  - Traces: Service → OTel Collector → Jaeger → Grafana (exemplar correlation)
  - Metrics: Service → OTel Collector → Prometheus → Grafana (dashboards, alerts, exemplars)
  - Logs: Service → OTel Collector → Loki/ES → Grafana Explore (trace_id correlation)
- **Resource Budget:**
  - Minimal viable (4GB host): Core + Jaeger + Loki = ~1.9GB
  - Full stack with Elasticsearch (8GB host): + ES + Kibana = ~4.2GB
  - Docker Compose profiles enable progressive complexity
- **Training Scenario Examples:**
  - Payment retry storm: Metrics spike → Exemplar click → Jaeger trace with 5 retries → Logs filtered by trace_id
  - Kitchen latency: Histogram p95 > 5s → Trace shows long kitchen span → Logs reveal queue backlog
  - Signal correlation workflow: Alert → Metric → Trace (exemplar) → Logs (trace_id) → Root cause
- **Learnings:**
  - **Three-pillar correlation is the killer feature:** Trainees must see metrics → traces → logs working together, not in isolation
  - **Resource constraints drive tool choice:** Loki's low footprint makes it ideal for laptop-based training (Elasticsearch requires 8GB+ host)
  - **OTel Collector complexity is justified:** Abstracts backend details, production-realistic, enables easy backend swaps (e.g., Jaeger → Tempo)
  - **Sampling not needed initially:** 100% trace capture is fine for training volumes; add probabilistic sampling (10%) only in "high-load" exercises
  - **In-memory storage simplifies training:** No persistence, no disk I/O, easy state reset between exercises
  - **Docker Compose profiles are essential:** Trainees can start minimal and add complexity as needed without editing YAML
- **Documentation Deliverables:**
  - Updated README.md with complete signal flow diagrams and tool rationale
  - Added practical Docker resource guidance (4GB vs 8GB host configs)
  - Created decision document: `.squad/decisions/inbox/vision-observability-pipeline.md`
- **Open Questions for Team:**
  - Should we demonstrate tail-based sampling in OTel Collector? (Recommendation: yes, in advanced module)
  - Prometheus Alertmanager vs Grafana Alerting? (Recommendation: Grafana for unified UI)
  - Pre-load all dashboards or let trainees build? (Recommendation: 2-3 reference dashboards + customization exercises)
- **Next Actions:**
  - Rocket: Implement Docker Compose profiles (core, traces, logs, full, elasticsearch)
  - Rocket: Create OTel Collector configuration YAML with optimized processors
  - Bruce: Instrument .NET services with OTel SDK (traces, metrics, structured logs)
  - Vision: Build Grafana reference dashboards for RED metrics, order flow, chaos scenarios
  - Clint: Validate resource usage on 4GB and 8GB test machines

### Baseline Observability Configuration (2026-03-25)

- **Owner:** Vision
- **Task:** Wire baseline observability configs for newly scaffolded services
- **Status:** Completed (services pending implementation by Bruce)
- **Deliverables:**
  - `infra/otel-collector/otel-collector-config.yaml` - Complete OTel Collector pipeline with receivers, processors, exporters
  - `infra/prometheus/prometheus.yml` - Scrape configs for all 4 services + infrastructure components
  - `infra/grafana/provisioning/datasources/datasources.yml` - Auto-provisioned datasources with correlation configs
  - `infra/grafana/provisioning/dashboards/dashboard-provider.yml` - Dashboard loading configuration
  - `infra/loki/loki-config.yaml` - Log aggregation with 7-day retention
  - `docker-compose.yml` - Full orchestration with 3 profiles (minimal, lite, full)
  - `infra/README.md` - Comprehensive infrastructure documentation
- **Configuration Highlights:**
  - **OTel Collector**: 3 pipelines (traces → Jaeger, metrics → Prometheus, logs → Loki), batch processing, memory limits, resource enrichment
  - **Prometheus**: 9 scrape targets (4 services + 5 infra components), 15s scrape interval, 7-day retention, remote write enabled
  - **Grafana Datasources**: Full correlation configured (exemplars → traces, traces → logs, traces → metrics)
  - **Loki**: Label-based indexing, 168h retention, 10MB/s ingestion limit, result caching
  - **Docker Compose Profiles**: Minimal (SQL only, 2GB), Lite (full observability, 5GB), Full (+ Elasticsearch, 7GB)
  - **Health Checks**: All services instrumented with readiness probes
  - **Service Placeholders**: Commented-out configs ready for Bruce to enable after .NET implementation
- **Port Allocations:**
  - OTel Collector: 4317 (OTLP gRPC), 4318 (OTLP HTTP), 8888/8889 (metrics), 13133 (health), 55679 (zpages)
  - Prometheus: 9090, Jaeger: 16686, Loki: 3100, Grafana: 3000, Elasticsearch: 9200
  - Services: 5100 (Ordering), 5200 (Payment), 5300 (Kitchen), 5400 (Delivery)
- **Learnings:**
  - **Processor ordering matters**: memory_limiter must be first to prevent OOM, batch last for efficiency
  - **Dual protocol support essential**: gRPC (services) + HTTP (browsers) both needed for full coverage
  - **Label consistency critical**: service.name must match across metrics/traces/logs for correlation
  - **Prometheus remote write vs scrape**: Using both - remote write from OTel Collector, direct scrape from service /metrics endpoints for redundancy
  - **Grafana datasource UIDs**: Hardcoded UIDs (prometheus, jaeger, loki) enable programmatic dashboard creation
  - **Health check start periods**: Elasticsearch needs 60s, others 10-15s; critical for dependency chains
  - **Memory limits tune startup order**: Collector (512MB) between backends (Jaeger/Loki) and services prevents backpressure
- **Correlation Workflow Implemented:**
  1. **Metrics → Traces**: Prometheus panel → exemplar click → Jaeger trace (via trace_id in exemplar)
  2. **Traces → Logs**: Jaeger span → "Logs for this span" button → Loki filtered by trace_id/span_id
  3. **Traces → Metrics**: Jaeger service view → "Related Metrics" → Prometheus queries for that service
  4. **Logs → Traces**: Loki log line → Derived field link (regex extracted trace_id) → Jaeger trace
- **Training Scenarios Now Enabled:**
  - End-to-end request tracing across 4 services
  - PromQL queries for SLI calculation (p95, error rate, throughput)
  - Log correlation by trace_id in Loki
  - Service dependency visualization in Jaeger
  - Collector health monitoring and pipeline debugging
- **Resource Validation Pending:**
  - Clint to test startup on 4GB/8GB/16GB machines
  - Profile switching (minimal → lite → full) to verify memory isolation
  - Health check timing under resource pressure
- **Open Questions:**
  - **Service metrics endpoint**: Should services expose native Prometheus `/metrics` in addition to OTLP export? (Recommendation: Yes, for redundancy and Prometheus-native metrics)
  - **Loki vs Elasticsearch default**: Current config uses Loki (lite profile), ES optional (full profile). Correct for training?
  - **Dashboard provisioning path**: Created folder structure, but no dashboards yet. Vision to build or wait for service instrumentation?
- **Dependencies Blocking Progress:**
  - **Bruce**: .NET services must implement OTel SDK instrumentation before uncommenting service definitions in docker-compose.yml
  - **Rocket**: May need to adjust health check timings after real service startup testing
  - **Peter**: Browser trace propagation requires service CORS headers configured (already in OTel Collector)
- **Next Actions:**
  - **Vision**: Build 2-3 reference Grafana dashboards (RED metrics, service topology, chaos scenarios) after services are instrumented
  - **Bruce**: Implement OTel SDK in .NET services, expose `/metrics` endpoints, emit structured logs with trace_id
  - **Rocket**: Test full stack startup sequence, validate health check timings, test profiles on target hardware
  - **Clint**: Create smoke test suite that validates signal flow (send request → verify trace in Jaeger → verify metrics in Prometheus → verify logs in Loki)

