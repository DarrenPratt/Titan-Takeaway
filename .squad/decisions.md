# Squad Decisions

## Active Decisions

### Architecture Foundation (2026-03-25)

**Author:** Tony  
**Status:** Proposed

Four-service microservice architecture:
- **Services:** Ordering API, Payment, Kitchen, Delivery
- **Data:** Single SQL Server, schema-per-service isolation
- **Communication:** Synchronous HTTP only
- **Observability:** OTel Collector → Prometheus/Jaeger → Grafana
- **Chaos Engineering:** Env vars + Admin API for failure injection
- **Frontend:** Bootstrap + vanilla JS from Ordering API wwwroot/
- **Repo Structure:** `src/` (services), `infra/` (Docker/configs), `docs/exercises/` (training)

**Rationale:** Balances distributed complexity (trace propagation, failure scenarios) with simplicity (single dev machine). Schema-per-service ensures data isolation without 4 DB containers. HTTP sync keeps stack lean for training focus on observability.

**Open Questions:**
- Jaeger vs Zipkin for trace backend (Vision to decide)
- Testcontainers vs docker-compose for integration tests (Clint to evaluate)

**Team Impact:** Bruce (services), Rocket (Docker), Vision (OTel/Jaeger), Peter (frontend), Clint (tests)

### Observability Stack Expansion (2026-03-25)

**Authors:** Tony (Lead Architect), Vision (Observability Engineer), Rocket (DevOps)  
**Status:** Proposed

#### Decision

Expand observability stack from baseline (OTel Collector → Prometheus/Grafana) to comprehensive three-pillar system:

**Three-Component Expansion:**
1. **Jaeger** — Promoted from optional to required for distributed trace visualization
2. **Loki** — Log aggregation with LogQL (primary, always enabled)
3. **Elasticsearch** — Optional, for advanced full-text log search and training exercises

**Resource Allocation:**
- Minimal configuration (core + Jaeger + Loki): **1.9GB RAM** required
- Full configuration (+ Elasticsearch): **4.2GB RAM** required
- Individual footprints: Jaeger ~256MB, Loki ~150MB, Elasticsearch ~1.5GB

**Architecture Flow:**
```
Services (OTel SDK) 
  ↓ OTLP (gRPC 4317 / HTTP 4318)
OTel Collector (receivers → processors → exporters)
  ├─→ Jaeger (traces via gRPC)
  ├─→ Prometheus (metrics via remote write)
  └─→ Loki (logs via HTTP)
       └─→ Elasticsearch (optional, logs via HTTP)
Grafana queries all backends for unified view
```

#### Rationale

**Why Jaeger Required:** Training platform demands dedicated trace UI for understanding distributed request flows, service dependency graphs, and span details. Essential for trace-based learning scenarios.

**Why Loki Primary:** Combines Prometheus-like experience (LogQL syntax, native Grafana integration) with label-based indexing efficiency. Sufficient for 90% of training scenarios with minimal resource cost (~150MB).

**Why Elasticsearch Optional:** Enables full-text search for complex debugging exercises (finding error messages, stack traces). Opt-in via Docker Compose profiles for resource-constrained machines.

#### Implementation

**Docker Compose Profiles (Progressive Complexity):**
- `minimal` — Core services only (5 containers)
- `observability-lite` — Metrics + Grafana (8 containers)
- `full` (default) — Complete stack with Elasticsearch (11 containers)
- `traces-only` — Tracing deep-dive (8 containers)
- `logs-only` — Log aggregation workshops (7 containers)

**Infrastructure Startup (4-Level Dependency):**
```
Level 1: sqlserver, elasticsearch, loki
Level 2: otel-collector, jaeger (depends_on elasticsearch)
Level 3: 4 services (depend_on sqlserver, otel-collector)
Level 4: prometheus, grafana
```

**Training Scenarios Enabled:**
1. Payment Retry Storm — Observe retries across metrics/traces/logs
2. Kitchen Latency Under Load — Track p95 latency spikes
3. Trace-to-Logs Correlation — Use trace_id to find context
4. Service Dependency Analysis — Visualize request flow in Jaeger
5. Error Pattern Search — Full-text search in Elasticsearch
6. Chaos Impact Visualization — Dashboard showing failure injection effects

#### Team Impact

| Role | Responsibility |
|------|-----------------|
| **Tony** | Approve architecture, ensure alignment |
| **Vision** | OTel Collector config, Grafana dashboards, scenarios |
| **Rocket** | Docker Compose profiles, health checks, testing |
| **Bruce** | Service instrumentation (.NET OTel SDK) |
| **Peter** | Browser trace context propagation |
| **Clint** | Validate on 4GB/8GB/16GB machines, chaos test |

#### Resource Planning

**Memory Breakdown (Local Development):**
| Component | Minimum | Recommended |
|-----------|---------|-------------|
| Elasticsearch | 1GB | 2GB |
| Loki | 512MB | 1GB |
| Jaeger | 256MB | 512MB |
| OTel Collector | 256MB | 512MB |
| Prometheus | 512MB | 1GB |
| Grafana | 256MB | 512MB |
| SQL Server | 2GB | 4GB |
| 4 Services | 1GB | 2GB |
| **Total** | **~6GB** | **~12GB** |

**Disk Requirements (7-Day Retention):**
- Elasticsearch (traces): 5-10GB
- Loki (logs): 2-5GB
- Prometheus (metrics): 2-3GB
- SQL Server (data): 500MB

#### Staged Startup (For 8GB Machines)

1. **Stage 1 (Core):** sqlserver, 4 services, ordering-api
2. **Stage 2 (Metrics):** otel-collector, prometheus, grafana
3. **Stage 3 (Traces):** elasticsearch, jaeger
4. **Stage 4 (Logs):** loki

#### Migration Path (Future)

- Replace Jaeger with Grafana Tempo (OTel Collector exporter change)
- Replace Loki with Elasticsearch (exporter change)
- Add OpenSearch (Elasticsearch alternative, lower licensing)
- All changes transparent to service code (Collector decoupling principle)

#### Success Criteria

Trainees can:
1. ✅ Trace request end-to-end across all services
2. ✅ Identify failure root cause (metrics → traces → logs)
3. ✅ Calculate SLIs using PromQL
4. ✅ Query logs by trace_id
5. ✅ Understand signal types (traces vs metrics vs logs)
6. ✅ Run stack on 4GB RAM laptop

#### Open Questions

1. **Sampling:** Start at 100%, add tail-based sampling in "high-load" module
2. **Alerting:** Use Grafana Alerting (simpler than Prometheus Alertmanager)
3. **Dashboards:** Provide 2-3 reference dashboards, encourage customization
4. **Log Level:** INFO for services, DEBUG only for chaos exercises

#### Approval Required

- Tony (Architect)
- Darren Pratt (Owner)

---

### Runtime Infrastructure Scaffold (2026-03-26)

**Author:** Rocket (Docker & Platform Engineer)  
**Status:** Implemented

Established root-level `docker-compose.yml` as local runtime baseline with three progressive profiles supporting resource-constrained machines. Added starter configs for OTel Collector, Prometheus, Grafana, Loki, and Elasticsearch with bind mounts to existing repository paths.

**Profiles:**
- **minimal:** SQL Server + OTel Collector + Prometheus + Grafana (4 containers)
- **lite:** minimal + Jaeger + Loki (6 containers)
- **full:** lite + Elasticsearch + Kibana (default, 11 containers)

**Key Achievements:**
- Progressive enablement for training on constrained laptops (core → metrics → traces → logs)
- One compose entry point with explicit profiles
- Pre-provisioned Grafana datasources and baseline collector pipelines reduce manual setup
- Validated compose with `docker compose config --quiet`

---

### Application Services Docker Integration (2026-03-26)

**Author:** Rocket (Docker & Platform Engineer)  
**Status:** Implemented

Integrated all 5 application services into docker-compose.yml with proper profiles, dependencies, and OpenTelemetry configuration.

**Services Added:**
1. **ordering-api** (port 5000) - Main API gateway
2. **payment-service** (port 5001) - Payment processing
3. **kitchen-service** (port 5002) - Kitchen order management
4. **delivery-service** (port 5003) - Delivery tracking
5. **web-app** (port 8080) - ASP.NET Razor Pages frontend

**Configuration:**
- **OpenTelemetry:** OTEL_EXPORTER_OTLP_ENDPOINT → http://otel-collector:4317 (gRPC); unique service names per service
- **SQL Server:** Shared database with schema-per-service isolation; all services depend on sqlserver health check
- **Profiles:** app (services only), full (complete stack); minimal/lite remain infra-only
- **Networking:** Default bridge; services prefixed with `titan-` for clarity
- **Dependencies:** All services depend on sqlserver + otel-collector; web-app depends on ordering-api

**Resource Impact:**
- Additional memory: ~2GB for 5 containers (~400MB each estimated)
- Full stack total: ~14GB recommended (12GB infra + 2GB apps)
- Profile containers: `--profile app`: 7 containers; `--profile full`: 13 containers

**Next Actions:**
1. Add health check endpoints in application code (Bruce)
2. Test full stack startup with `docker compose --profile full up`
3. Validate service-to-service HTTP communication
4. Confirm OpenTelemetry trace propagation across services
5. Document profile usage in README.md

---

### Backend Services Scaffold (2026-03-25)

**Author:** Bruce (Backend Engineer)  
**Status:** Proposed

Create four independent ASP.NET minimal API services as initial backend baseline:
- `services/ordering-api`
- `services/payment-service`
- `services/kitchen-service`
- `services/delivery-service`

Each service includes minimal `Program.cs` bootstrap with `/` and `/health` endpoints, `appsettings.json` with SQL Server connection string, environment override via `SQLSERVER_CONNECTION_STRING`, and per-service Dockerfile exposing port 5000-5003.

Shared solution file `Titan-Takeaway.Services.slnx` maintained at repo root for coordinated build/test workflows.

---

### Frontend Service Scaffold (2026-03-25)

**Author:** Peter (Frontend Engineer)  
**Status:** Proposed

Create minimal, buildable frontend shell as dedicated ASP.NET Razor Pages app at `frontend/web-app/` using Bootstrap.

**Delivered:**
1. Razor Pages scaffold (`dotnet new webapp`)
2. Landing page with service health placeholders and quick links to Grafana, Jaeger, Prometheus, Loki
3. Clean static asset structure (css/js organization)
4. Multi-stage .NET 10 Dockerfile

Keeps training frontend intentionally simple and easy to run while preserving clear separation of shared vs page-specific assets.

---

### Jaeger Local Development Baseline (2026-03-25)

**Author:** Stephen (Observability Infrastructure)  
**Status:** Proposed

Adopt local-dev Jaeger baseline keeping configuration explicit and coherent across infrastructure files:
- `infra/docker/docker-compose.yml` defines `jaeger` and `otel-collector` services
- `infra/jaeger/jaeger.env` carries Jaeger runtime defaults (OTLP enabled, in-memory storage, capped traces)
- `infra/otel-collector/otel-collector-config.yaml` exports traces to `jaeger:4317` over OTLP gRPC

**Defaults (local-dev friendly):**
- Jaeger uses `jaegertracing/all-in-one` with `SPAN_STORAGE_TYPE=memory`
- `MEMORY_MAX_TRACES=10000` limits in-memory footprint for laptops
- Collector includes `memory_limiter` + `batch` processors and health extension
- Only essential ports exposed: Jaeger UI (16686) and collector OTLP/health (4317, 4318, 13133)

Keeps trace path simple and deterministic (services → collector → Jaeger) while avoiding premature persistence complexity.

---

### Logging & Search Integration Alignment (2026-03-25)

**Author:** Natasha (Logging & Search Engineer)  
**Status:** Implemented

Aligned Loki/collector ingestion paths in compose with actual files:
- `infra/otel-collector/otel-collector-config.yaml`
- `infra/loki/loki-config.yaml`

Added optional search profile wiring in root compose:
- `elasticsearch` and `kibana` now include `profiles: ["search", "full"]`
- Kibana now mounts `infra/kibana/kibana.yml`

Added placeholder search config (`infra/kibana/kibana.yml`) with valid baseline settings. Updated documentation to remove stale profile names and extension mismatches.

---

### Build Validation Tooling (2026-03-25)

**Author:** Clint (QA & Build Automation)  
**Status:** Proposed

Introduce lightweight PowerShell script set to verify required files, parse docker compose config, and list service build commands. Provides repeatable preflight gate for local reliability and reduces setup-related failures before container startup/build attempts.

---

### Staffing Consideration: Expert Hiring (2026-03-25T14:13:14Z)

**By:** Darren Pratt (Owner, via Copilot directive)  
**Note:** May need to hire experts for new stacks (Elasticsearch, Loki, Jaeger) — captured for team memory

---

## Governance

- All meaningful changes require team consensus
- Document architectural decisions here
- Keep history focused on work, decisions focused on direction.
