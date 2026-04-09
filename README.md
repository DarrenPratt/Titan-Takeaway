# Titan-Takeaway

A hands-on training application for learning **OpenTelemetry**, **Prometheus**, **Grafana**, **Elasticsearch**, **Loki**, and **Jaeger** through a realistic microservice food ordering system.

## Overview

Titan-Takeaway simulates a food delivery platform where trainees can observe, diagnose, and fix real-world distributed system problems using modern observability tools. The system runs entirely on Docker Compose for local development.

---

## Architecture

### High-Level Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              BROWSER CLIENT                                  │
│                    (Bootstrap + JavaScript SPA Pages)                        │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                             ORDERING API                                     │
│                   ASP.NET Core Web API (Port 5100)                          │
│         Accepts orders, coordinates workflow, serves frontend               │
└─────────────────────────────────────────────────────────────────────────────┘
            │                         │                         │
            ▼                         ▼                         ▼
┌───────────────────┐   ┌───────────────────┐   ┌───────────────────────────┐
│   PAYMENT SERVICE │   │   KITCHEN SERVICE │   │     DELIVERY TRACKER      │
│  ASP.NET (5200)   │   │  ASP.NET (5300)   │   │     ASP.NET (5400)        │
│  Payment gateway  │   │  Prep simulation  │   │   Driver assignment &     │
│  integration stub │   │  & queue mgmt     │   │   location updates        │
└───────────────────┘   └───────────────────┘   └───────────────────────────┘
            │                         │                         │
            └─────────────────────────┼─────────────────────────┘
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                             SQL SERVER                                       │
│                    (Single instance, schema-per-service)                    │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                         OBSERVABILITY STACK                                  │
├─────────────────────┬─────────────────────┬─────────────────────────────────┤
│   OTEL COLLECTOR    │    PROMETHEUS       │           GRAFANA               │
│   (Port 4317/4318)  │    (Port 9090)      │         (Port 3000)             │
│   Receives traces,  │    Scrapes metrics  │    Dashboards & alerts          │
│   metrics, & logs   │    from services    │    for visualization            │
│   from all services │    & collector      │                                 │
├─────────────────────┼─────────────────────┼─────────────────────────────────┤
│   JAEGER            │    LOKI             │        ELASTICSEARCH            │
│   (Port 16686)      │    (Port 3100)      │         (Port 9200)             │
│   Distributed trace │    Log aggregation  │    Full-text search for         │
│   storage & UI      │    & querying       │    logs & structured data       │
└─────────────────────┴─────────────────────┴─────────────────────────────────┘
```

### Service Boundaries

| Service | Responsibility | Owns | Exposes |
|---------|---------------|------|---------|
| **Ordering API** | Order lifecycle orchestration, customer-facing API, frontend hosting | `ordering` schema: Orders, OrderItems, OrderStatusHistory | REST API + static frontend |
| **Payment Service** | Payment processing, refunds, payment status | `payment` schema: Payments, PaymentAttempts | Internal REST API |
| **Kitchen Service** | Order preparation queue, cook time simulation | `kitchen` schema: PrepTickets, PrepSteps | Internal REST API |
| **Delivery Tracker** | Driver assignment, GPS simulation, ETA calculation | `delivery` schema: Deliveries, DriverLocations | Internal REST API + SSE for live updates |

### Communication Patterns

- **Synchronous HTTP**: All inter-service calls use REST over HTTP with OpenTelemetry trace context propagation
- **Polling for status**: Kitchen and Delivery services poll or are polled for status updates
- **No message broker**: Keeps complexity low for training purposes; all workflows are request-driven

---

## Observability Architecture

### OpenTelemetry Integration

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Ordering   │     │   Payment   │     │   Kitchen   │     │  Delivery   │
│    API      │     │   Service   │     │   Service   │     │   Tracker   │
├─────────────┤     ├─────────────┤     ├─────────────┤     ├─────────────┤
│ OTel SDK    │     │ OTel SDK    │     │ OTel SDK    │     │ OTel SDK    │
│ - Traces    │     │ - Traces    │     │ - Traces    │     │ - Traces    │
│ - Metrics   │     │ - Metrics   │     │ - Metrics   │     │ - Metrics   │
│ - Logs      │     │ - Logs      │     │ - Logs      │     │ - Logs      │
└──────┬──────┘     └──────┬──────┘     └──────┬──────┘     └──────┬──────┘
       │                   │                   │                   │
       └───────────────────┴───────────────────┴───────────────────┘
                                      │
                                      ▼
                        ┌─────────────────────────┐
                        │    OTEL COLLECTOR       │
                        │  ┌───────────────────┐  │
                        │  │    Receivers      │  │
                        │  │  OTLP (gRPC/HTTP) │  │
                        │  └─────────┬─────────┘  │
                        │            │            │
                        │  ┌─────────▼─────────┐  │
                        │  │    Processors     │  │
                        │  │  Batch, Memory    │  │
                        │  └─────────┬─────────┘  │
                        │            │            │
                        │  ┌─────────▼─────────┐  │
                        │  │    Exporters      │  │
                        │  │ Prometheus, Jaeger│  │
                        │  │ Loki, Elasticsearch│ │
                        │  └───────────────────┘  │
                        └─────────────────────────┘
                                      │
            ┌──────────────┬──────────┴──────────┬──────────────┐
            ▼              ▼                     ▼              ▼
┌───────────────────┐ ┌───────────────┐ ┌───────────────┐ ┌────────────────┐
│    PROMETHEUS     │ │    JAEGER     │ │     LOKI      │ │ ELASTICSEARCH  │
│  Metrics storage  │ │ Trace storage │ │ Log aggregator│ │ Search backend │
│  & PromQL queries │ │ & trace UI    │ │ & LogQL       │ │ & full-text    │
└─────────┬─────────┘ └───────────────┘ └───────┬───────┘ └────────────────┘
          │                                     │
          └──────────────────┬──────────────────┘
                             ▼
                   ┌───────────────────┐
                   │      GRAFANA      │
                   │  - Dashboards     │
                   │  - Alerting       │
                   │  - Log exploration│
                   └───────────────────┘
```

### Complete Signal Flow: Traces, Metrics, and Logs

#### 1. **TRACES** → OpenTelemetry → Jaeger
**Purpose:** Track distributed transactions across service boundaries

**Signal Flow:**
1. Each service creates spans for operations (HTTP requests, DB queries, business logic)
2. Parent span context propagated via HTTP headers (W3C TraceContext: `traceparent`, `tracestate`)
3. Spans exported via OTLP to OTel Collector (gRPC port 4317)
4. Collector batches and forwards to Jaeger backend
5. Jaeger stores traces and provides query UI

**What you see:**
- End-to-end request flow visualization
- Service dependency map
- Latency breakdown by operation
- Error spans with stack traces
- Retry patterns and cascading failures

**Training scenarios:**
- Trace payment failures through the entire order flow
- Identify which service introduces latency
- Correlate traces with metrics using exemplars

**Access:** http://localhost:16686

#### 2. **METRICS** → OpenTelemetry → Prometheus
**Purpose:** Time-series numeric data for performance and health monitoring

**Signal Flow:**
1. Services emit counters, histograms, and gauges via OTel SDK
2. Metrics exported via OTLP to OTel Collector
3. Collector converts to Prometheus format and writes via `prometheusremotewrite`
4. Prometheus stores and indexes time-series data
5. Grafana queries Prometheus for dashboards and alerts

**What you see:**
- Request rates (requests per second by service/endpoint)
- Error rates (4xx/5xx responses over time)
- Latency distributions (p50, p95, p99 percentiles)
- Queue depths, connection pool usage, cache hit rates
- Custom business metrics (orders_completed, revenue_total)

**Key metrics:**
- `http_server_request_duration_seconds` (histogram) → calculate latency percentiles
- `orders_total` (counter) → rate() for orders/sec
- `active_orders` (gauge) → current in-flight orders
- `payment_failures_total` (counter) → error rates
- `kitchen_queue_depth` (gauge) → backpressure indicator

**Training scenarios:**
- Calculate 95th percentile latency using PromQL: `histogram_quantile(0.95, rate(http_server_request_duration_seconds_bucket[5m]))`
- Alert on error rate spike: `rate(http_server_errors_total[1m]) > 0.1`
- Identify service degradation from gauge trends

**Access:** http://localhost:9090

#### 3. **LOGS** → OpenTelemetry → Loki / Elasticsearch
**Purpose:** Structured event logs with trace correlation

**Signal Flow:**
1. Services emit structured JSON logs with trace/span IDs
2. Logs captured by OTel SDK and enriched with resource attributes
3. Exported via OTLP to OTel Collector
4. Collector routes to Loki (primary) or Elasticsearch (optional)
5. Grafana queries logs with LogQL or Elasticsearch DSL

**What you see:**
- Application logs filtered by service, level, or trace_id
- Error messages with full context
- Audit trail of order state transitions
- Query logs with exact SQL statements
- Correlated logs from a single distributed trace

**Log structure:**
```json
{
  "timestamp": "2026-03-25T14:30:00Z",
  "level": "ERROR",
  "message": "Payment gateway timeout",
  "trace_id": "4bf92f3577b34da6a3ce929d0e0e4736",
  "span_id": "00f067aa0ba902b7",
  "service.name": "payment-service",
  "order_id": "ord-12345",
  "payment_amount": 42.50
}
```

**Why Loki (Primary):**
- Low memory footprint (~200MB vs 2GB for Elasticsearch)
- Indexes labels only, not log content (cost-effective)
- LogQL similar to PromQL (easy learning curve)
- Native Grafana integration with Explore UI
- Sufficient for training scenarios

**Why Elasticsearch (Optional):**
- Full-text search across all log content
- Advanced aggregations and analytics
- Better for unknown-unknown debugging
- Kibana provides powerful log analysis UI
- Higher resource requirements (~2GB RAM + disk)

**Training scenarios:**
- Find all logs for a failed trace: `{service="ordering-api"} |= "trace_id:abc123"`
- Count errors by service: `sum by (service) (rate({level="ERROR"}[5m]))`
- Jump from Grafana dashboard → trace → logs for the same request

**Access:**
- Loki: via Grafana Explore (http://localhost:3000/explore)
- Elasticsearch: Kibana at http://localhost:5601 (if enabled)

### Signal Correlation: The Three Pillars Working Together

**Scenario: Debugging a slow order**

1. **Start with Metrics (Grafana dashboard)**
   - Alert fires: "Order completion time p95 > 30 seconds"
   - Dashboard shows spike in `http_server_request_duration_seconds` for `ordering-api`

2. **Drill into Traces (Exemplar link)**
   - Click exemplar dot on Grafana chart → opens Jaeger trace
   - Trace shows 28 seconds spent in `payment-service` span
   - Payment span has 5 retry attempts visible

3. **Investigate Logs (Trace ID)**
   - Copy `trace_id` from Jaeger
   - Query Loki: `{service="payment-service"} |= "trace_id:xyz"` 
   - Logs reveal: "Connection pool exhausted, retrying..."

4. **Root cause:** Payment service connection pool too small under load
5. **Fix:** Increase connection pool size or add circuit breaker

### Key Observability Concepts Covered

| Concept | Where Demonstrated |
|---------|-------------------|
| **Distributed Tracing** | End-to-end traces from browser → Ordering → Payment/Kitchen → Delivery |
| **Span Context Propagation** | HTTP headers carry trace context between services |
| **Custom Spans** | Business operations (e.g., "validate-payment", "cook-order") create explicit spans |
| **Metrics (Counters)** | orders_placed_total, payments_processed_total |
| **Metrics (Histograms)** | request_duration_seconds, kitchen_prep_time_seconds |
| **Metrics (Gauges)** | orders_in_progress, kitchen_queue_depth |
| **Structured Logging** | JSON logs with trace_id and span_id correlation |
| **Exemplars** | Link metrics to traces for drill-down |
| **Log Aggregation (Loki)** | Centralized logs from all services, queryable via LogQL |
| **Log Search (Elasticsearch)** | Full-text search across log content for debugging |
| **Trace Storage (Jaeger)** | Persistent trace storage with dependency graphs |
| **Service Mesh Observability** | Envoy sidecar metrics (if using service mesh - future) |
| **Trace Sampling** | Probabilistic sampling in OTel Collector for high-volume scenarios |
| **Log-to-Trace Correlation** | Click trace_id in logs → jump to Jaeger trace view |
| **Metric-to-Trace Correlation** | Click exemplar on Prometheus metric → view source trace |

### Local Docker Resource Considerations

Running a full observability stack requires careful resource management. Below are practical guidelines for development machines.

#### Minimal Viable Configuration (4GB RAM Available)

**Core Stack (Required):**
- `ordering-api`, `payment-service`, `kitchen-service`, `delivery-tracker`: ~600MB combined
- `sqlserver`: ~512MB
- `otel-collector`: ~100MB
- `prometheus`: ~200MB (with 1-hour retention)
- `grafana`: ~150MB
- **Total: ~1.5GB**

**Observability Options:**
- **Option A: Traces Only** — Add `jaeger`: ~200MB → **Total: 1.7GB**
- **Option B: Logs Only (Loki)** — Add `loki`: ~150MB → **Total: 1.65GB**
- **Option C: Both** — Add `jaeger` + `loki`: ~350MB → **Total: 1.85GB**

**NOT Recommended for <4GB:**
- Elasticsearch + Kibana (~2.5GB) — too heavy for minimal setups

#### Recommended Configuration (8GB+ RAM Available)

**Full Stack with Loki:**
- Core stack: 1.5GB
- `jaeger`: ~200MB
- `loki`: ~150MB
- **Total: ~1.85GB** ✅ Good balance of features and performance

**Full Stack with Elasticsearch (Optional):**
- Core stack: 1.5GB
- `jaeger`: ~200MB
- `loki`: ~150MB
- `elasticsearch`: ~1.5GB
- `kibana`: ~800MB
- **Total: ~4.15GB** ⚠️ Only if you need full-text search

#### Resource Optimization Strategies

**1. Prometheus Retention**
```yaml
# docker-compose.yml
prometheus:
  command:
    - '--storage.tsdb.retention.time=1h'  # Reduce from default 15d
    - '--storage.tsdb.retention.size=512MB'
```
**Impact:** Saves 80% disk I/O and memory for training scenarios (1-2 hour sessions)

**2. OTel Collector Batch Size**
```yaml
# otel-collector-config.yaml
processors:
  batch:
    timeout: 500ms        # Increase from 200ms
    send_batch_size: 2048 # Increase from 8192
  memory_limiter:
    limit_mib: 256        # Reduce from 512 if needed
```
**Impact:** Reduces CPU usage by 30% with minimal latency increase

**3. Jaeger In-Memory Storage**
```yaml
# docker-compose.yml
jaeger:
  environment:
    - SPAN_STORAGE_TYPE=memory
    - MEMORY_MAX_TRACES=5000  # ~100MB of traces
```
**Impact:** Fast, no disk I/O, but traces lost on restart (fine for training)

**4. Loki Retention**
```yaml
# loki-config.yaml
limits_config:
  retention_period: 24h  # Default is unlimited
compactor:
  retention_enabled: true
```
**Impact:** Prevents disk bloat during multi-day training

**5. Conditional Service Startup**

Use Docker Compose profiles to run only what you need:

```yaml
# docker-compose.yml
services:
  jaeger:
    profiles: ["traces", "full"]
  
  loki:
    profiles: ["logs", "full"]
  
  elasticsearch:
    profiles: ["search", "full"]
  
  kibana:
    profiles: ["search", "full"]
```

**Usage:**
```bash
# Minimal: Core + metrics only
docker compose up

# Lite stack (core observability without Elasticsearch/Kibana)
docker compose --profile lite up

# Full stack (includes optional search components)
docker compose --profile full up

# Add optional search tooling to any run
docker compose --profile lite --profile search up
```

#### Minimal Viable Defaults (Recommended Starting Point)

**Start with:** Core services + OTel Collector + Prometheus + Grafana + Jaeger + Loki

**Skip initially:** Elasticsearch + Kibana (add later if needed for advanced log search)

**Rationale:**
- Jaeger: Essential for distributed tracing exercises
- Loki: Low overhead, sufficient for most log correlation scenarios
- Prometheus + Grafana: Core metrics and dashboards
- Elasticsearch: Adds complexity and resources; enable only for specific full-text search exercises

#### Resource Monitoring Commands

**Check Docker resource usage:**
```powershell
# Overall stats
docker stats --no-stream

# Specific container memory
docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}\t{{.CPUPerc}}"

# Disk usage by container
docker system df -v
```

**Warning signs:**
- Container restarts: Check `docker ps -a` for restart counts
- Slow query responses: Prometheus/Loki may be memory-starved
- OOM kills: Check `docker inspect <container>` for OOMKilled status

#### Performance Tuning Tips

**If experiencing slowness:**

1. **Reduce scrape intervals** (Prometheus): 30s → 60s
2. **Disable metrics you don't need** (OTel SDK): Filter out high-cardinality metrics
3. **Use Jaeger sampling**: 100% → 10% for high-volume tests
4. **Increase Docker Desktop memory**: Settings → Resources → Memory (8GB minimum recommended)

**Example Jaeger sampling:**
```yaml
# otel-collector-config.yaml
processors:
  probabilistic_sampler:
    sampling_percentage: 10  # Sample 10% of traces
```

---

## Failure Simulation Scenarios

Training scenarios that can be triggered via environment variables or admin endpoints:

| Scenario | Injection Point | How to Trigger | What to Observe |
|----------|----------------|----------------|-----------------|
| **Payment 503 Failures** | Payment Service | `SIMULATE_PAYMENT_FAILURE=true` or `POST /admin/chaos/payment-503` | Retry storms in traces, error rate spike in metrics, cascading delays |
| **Kitchen Latency Under Load** | Kitchen Service | `SIMULATE_KITCHEN_LATENCY_MS=5000` or `POST /admin/chaos/slow-kitchen` | Long spans, queue buildup, timeout errors |
| **Stuck Preparing Orders** | Kitchen Service | `SIMULATE_STUCK_ORDERS=true` or `POST /admin/chaos/stuck-orders` | Orders never transition past "Preparing", alerts fire |
| **Retry Storms** | Ordering API | Automatic when downstream fails | Exponential backoff visible in traces, metrics show retry counts |
| **Database Slowdown** | SQL Server | `SIMULATE_DB_LATENCY_MS=2000` | All services slow down, connection pool exhaustion |

### Chaos Admin API

Each service exposes `/admin/chaos/*` endpoints (disabled in production builds):
- `POST /admin/chaos/enable/{scenario}` — Enable a failure scenario
- `POST /admin/chaos/disable/{scenario}` — Disable a failure scenario
- `GET /admin/chaos/status` — Current chaos configuration

---

## Data Storage

### SQL Server Schema Ownership

Each service owns its schema and migrations. No cross-schema queries allowed.

```
┌──────────────────────────────────────────────────────────────┐
│                     titan_takeaway (Database)                │
├──────────────────┬──────────────────┬───────────────────────┤
│  [ordering]      │  [payment]       │  [kitchen]            │
│  ─────────────   │  ──────────      │  ─────────            │
│  Orders          │  Payments        │  PrepTickets          │
│  OrderItems      │  PaymentAttempts │  PrepSteps            │
│  OrderHistory    │                  │                       │
├──────────────────┴──────────────────┴───────────────────────┤
│  [delivery]                                                  │
│  ───────────                                                 │
│  Deliveries                                                  │
│  DriverLocations                                             │
└──────────────────────────────────────────────────────────────┘
```

### Migration Strategy

- **Tool**: Entity Framework Core Migrations (per-service)
- **Location**: Each service has `Migrations/` folder in its project
- **Execution**: Migrations run on service startup (`Database.Migrate()`)
- **Idempotent**: Safe to run multiple times; tracks applied migrations in `__EFMigrationsHistory`

### Connection Strings

Each service connects to the same SQL Server instance but uses a different schema:
```
Server=sqlserver;Database=titan_takeaway;User=sa;Password=...;TrustServerCertificate=true
```

---

## Local Development Architecture

### Docker Compose Services

```yaml
services:
  # Application Services
  ordering-api:      # Port 5100 - Main entry point
  payment-service:   # Port 5200 - Internal
  kitchen-service:   # Port 5300 - Internal
  delivery-tracker:  # Port 5400 - Internal
  
  # Data
  sqlserver:         # Port 1433 - SQL Server 2022
  
  # Observability - Core
  otel-collector:    # Ports 4317 (gRPC), 4318 (HTTP) - Telemetry aggregation
  prometheus:        # Port 9090 - Metrics storage & queries
  grafana:           # Port 3000 - Dashboards, alerts, log exploration
  
  # Observability - Tracing
  jaeger:            # Port 16686 - Distributed trace storage & UI
  
  # Observability - Logging
  loki:              # Port 3100 - Log aggregation & LogQL queries
  elasticsearch:     # Port 9200 - Full-text log search backend
```

**Total Containers:** 12 (4 services + 1 database + 7 observability)

### Service Dependencies

```
ordering-api ──────► sqlserver
             ──────► payment-service ──────► sqlserver
             ──────► kitchen-service ──────► sqlserver
             ──────► delivery-tracker ─────► sqlserver

All services ──────► otel-collector ──────► prometheus (metrics)
                                    ──────► jaeger (traces)
                                    ──────► loki (logs)
                                    ──────► elasticsearch (log search)

prometheus ────────► grafana
loki ──────────────► grafana
```

### Startup Order

Docker Compose `depends_on` with healthchecks:

**Level 1 - Foundation Layer:**
1. `sqlserver` — Healthcheck: SQL connection test (~10-15s)
2. `elasticsearch` — Healthcheck: Cluster health check (~30-60s for cold start)
3. `loki` — No dependencies, starts immediately

**Level 2 - Collectors:**
4. `otel-collector` — Starts immediately, buffers telemetry if backends not ready
5. `prometheus` — Starts immediately, begins scraping when targets become available
6. `jaeger` — Depends on elasticsearch (requires healthy backend for trace storage)

**Level 3 - Backend Services:**
7. `payment-service`, `kitchen-service`, `delivery-tracker` — Depend on sqlserver + otel-collector

**Level 4 - Frontend:**
8. `ordering-api` — Depends on all backend services (payment, kitchen, delivery)

**Level 5 - Visualization:**
9. `grafana` — Depends on prometheus + loki (configures datasources on startup)

**Expected total startup time:** 60-90 seconds for full stack (Elasticsearch dominates)

### Resource Requirements

Running the full observability stack requires adequate system resources:

| System Tier | RAM | CPU | Disk | Use Case |
|-------------|-----|-----|------|----------|
| **Minimum** | 8GB | 4 cores | 20GB | Staged startup or use profiles (see below) |
| **Recommended** | 16GB | 8 cores | 40GB | Full stack, comfortable training experience |
| **Comfortable** | 32GB | 8+ cores | 60GB | Multi-day training, extended retention |

#### Memory Allocation Breakdown (Recommended Configuration)

| Component | Min | Recommended | Notes |
|-----------|-----|-------------|-------|
| Elasticsearch | 1GB | 2GB | Java heap; increase for longer retention periods |
| Loki | 512MB | 1GB | Scales with log volume and query concurrency |
| Jaeger (UI/Query) | 256MB | 512MB | Lightweight trace frontend |
| OTel Collector | 256MB | 512MB | Stateless telemetry processor |
| Prometheus | 512MB | 1GB | Scales with metric cardinality |
| Grafana | 256MB | 512MB | Dashboard rendering engine |
| SQL Server | 2GB | 4GB | Database engine minimum |
| 4× Services | 1GB | 2GB | 250-500MB each (ASP.NET Core) |
| **Total** | **~6GB** | **~12GB** | **Plus 2-4GB OS overhead** |

#### Disk Space Requirements (7-Day Retention)

- **Elasticsearch (traces):** ~5-10GB for typical training load
- **Loki (logs):** ~2-5GB for typical training load  
- **Prometheus (metrics):** ~2-3GB for typical training load
- **SQL Server (data):** ~500MB for sample orders
- **Total:** ~10-20GB active data + 10GB buffer recommended

⚠️ **Caution for 8GB Machines:** The full stack may cause memory pressure. Use Docker Compose profiles (below) or staged startup to manage resource consumption.

### Docker Compose Profiles (Optional)

For resource-constrained training environments, use profiles to run partial stacks:

```bash
# Minimal: Services + database only (5 containers, ~3GB RAM)
docker-compose --profile minimal up

# Lite: Add metrics/dashboards, skip heavy storage (8 containers, ~6GB RAM)
docker-compose --profile lite up

# Full: Complete observability stack (12 containers, ~12GB RAM)
docker-compose up  # or --profile full

# Search add-on: Enable Elasticsearch + Kibana when needed
docker-compose --profile lite --profile search up
```

**Recommended Training Progression:**
- **Day 1 (Foundations):** Start with `minimal` or `lite` profile
- **Day 2 (Metrics & Dashboards):** Run `lite` (includes Prometheus/Grafana)
- **Day 3 (Chaos Engineering):** Upgrade to `full` stack for comprehensive troubleshooting

### Staged Startup for Limited Resources

If running on an 8GB machine without compose profiles configured:

**Stage 1: Core Services**
```bash
docker-compose up sqlserver ordering-api payment-service kitchen-service delivery-tracker
```
Verify application functionality, then proceed.

**Stage 2: Add Metrics & Dashboards**
```bash
docker-compose up otel-collector prometheus grafana
```
Explore metrics and build dashboards.

**Stage 3: Add Tracing (Heavy Components)**
```bash
docker-compose up elasticsearch jaeger
# Note: Elasticsearch takes 30-60s to initialize
```
Wait for cluster formation, then explore distributed traces.

**Stage 4: Add Log Aggregation**
```bash
docker-compose up loki
```
Configure Grafana → Loki datasource, explore structured logs.

---

## Repository Structure

```
titan-takeaway/
├── src/
│   ├── Ordering.Api/              # Main API, frontend host, order orchestration
│   │   ├── Controllers/
│   │   ├── Services/
│   │   ├── Models/
│   │   ├── Migrations/
│   │   ├── wwwroot/               # Static frontend (Bootstrap + JS)
│   │   └── Ordering.Api.csproj
│   │
│   ├── Payment.Service/           # Payment processing microservice
│   │   ├── Controllers/
│   │   ├── Services/
│   │   ├── Models/
│   │   ├── Migrations/
│   │   └── Payment.Service.csproj
│   │
│   ├── Kitchen.Service/           # Kitchen preparation microservice
│   │   ├── Controllers/
│   │   ├── Services/
│   │   ├── Models/
│   │   ├── Migrations/
│   │   └── Kitchen.Service.csproj
│   │
│   ├── Delivery.Tracker/          # Delivery tracking microservice
│   │   ├── Controllers/
│   │   ├── Services/
│   │   ├── Models/
│   │   ├── Migrations/
│   │   └── Delivery.Tracker.csproj
│   │
│   └── Shared/                    # Shared libraries
│       ├── Observability/         # Common OTel setup, trace context helpers
│       ├── Chaos/                 # Chaos engineering middleware
│       └── Shared.csproj
│
├── infra/
│   ├── docker/
│   │   └── docker-compose.yml
│   │
│   ├── otel-collector/
│   │   └── otel-collector-config.yaml
│   │
│   ├── prometheus/
│   │   └── prometheus.yml
│   │
│   ├── jaeger/
│   │   └── jaeger.env                 # Jaeger local-dev runtime settings
│   │
│   ├── loki/
│   │   └── loki-config.yaml           # Loki log aggregation config
│   │
│   ├── elasticsearch/
│   │   └── elasticsearch.yml          # Elasticsearch log search config
│   │
│   └── grafana/
│       ├── provisioning/
│       │   ├── dashboards/
│       │   │   ├── order-flow.json
│       │   │   ├── service-health.json
│       │   │   ├── logs-explorer.json
│       │   │   └── chaos-scenarios.json
│       │   └── datasources/
│       │       ├── prometheus.yaml
│       │       ├── jaeger.yaml
│       │       ├── loki.yaml
│       │       └── elasticsearch.yaml
│       └── grafana.ini
│
├── docs/
│   ├── exercises/                 # Step-by-step training exercises
│   │   ├── 01-traces-basics.md
│   │   ├── 02-metrics-basics.md
│   │   ├── 03-dashboards.md
│   │   ├── 04-alerting.md
│   │   └── 05-chaos-debugging.md
│   │
│   ├── architecture/              # Architecture decision records
│   │   └── README.md
│   │
│   └── runbooks/                  # Operational runbooks for scenarios
│       ├── payment-failures.md
│       ├── kitchen-latency.md
│       └── stuck-orders.md
│
├── tests/
│   ├── Ordering.Api.Tests/
│   ├── Payment.Service.Tests/
│   ├── Kitchen.Service.Tests/
│   ├── Delivery.Tracker.Tests/
│   └── Integration.Tests/         # End-to-end with Docker
│
├── .squad/                        # Squad agent configuration
├── TitanTakeaway.sln              # Solution file
├── .gitignore
├── .editorconfig
└── README.md
```

### Folder Rationale

| Folder | Purpose |
|--------|---------|
| `src/` | All application code. Each service is independently deployable. `Shared/` contains cross-cutting concerns. |
| `infra/` | Infrastructure-as-code. Docker configs, observability tool configs. Keeps infra separate from app code. |
| `docs/exercises/` | Training exercises that trainees follow step-by-step. Numbered for progression. |
| `docs/runbooks/` | Reference material for debugging specific failure scenarios. |
| `tests/` | Mirrors `src/` structure. Integration tests use Testcontainers or Docker Compose. |

---

## Learning Path

Recommended progression for trainees:

### Module 1: Foundations (Day 1)
1. **Setup** — Clone repo, run `docker-compose up`, verify services are healthy
2. **Explore the System** — Place orders via UI, watch order flow in Jaeger
3. **Understand Tracing** — Read `01-traces-basics.md`, add a custom span to Kitchen Service

### Module 2: Metrics & Dashboards (Day 2)
4. **Metrics Deep Dive** — Read `02-metrics-basics.md`, explore Prometheus query UI
5. **Build a Dashboard** — Read `03-dashboards.md`, create a custom panel in Grafana
6. **Set Up Alerts** — Read `04-alerting.md`, configure an alert for error rate > 5%

### Module 3: Logging & Search (Day 3)
7. **Log Aggregation** — Explore logs in Grafana using Loki as the datasource
8. **LogQL Queries** — Write queries to filter logs by service, level, and trace_id
9. **Full-text Search** — Use Elasticsearch for complex log content searches
10. **Correlate Signals** — Jump from metrics → traces → logs using trace_id correlation

### Module 4: Chaos Engineering (Day 4)
11. **Break Things** — Read `05-chaos-debugging.md`, enable payment failures
12. **Diagnose with Observability** — Use traces + metrics + logs to find root cause
13. **Follow Runbooks** — Practice using `docs/runbooks/` to resolve scenarios
14. **Capstone** — Debug an unknown failure scenario using only observability tools

### Skills Acquired

By completion, trainees will be able to:
- Instrument .NET services with OpenTelemetry
- Configure OTel Collector pipelines (traces, metrics, logs)
- Write PromQL queries for common scenarios
- Write LogQL queries for log exploration in Loki
- Use Elasticsearch for full-text log search
- Correlate traces, metrics, and logs using trace_id
- Build Grafana dashboards from scratch
- Set up meaningful alerts
- Diagnose distributed system failures using the full observability stack
- Understand observability best practices

---

## Quick Start

### Prerequisites

- **Docker Desktop** (or Docker Engine + Docker Compose)
- **System Requirements:** 16GB RAM recommended (8GB minimum with profiles)
- **Disk Space:** 40GB free recommended

### Build Verification (PowerShell-friendly)

Run these checks from the repository root before starting containers:

```powershell
pwsh -File .\scripts\validate-required-files.ps1
pwsh -File .\scripts\validate-compose-config.ps1
pwsh -File .\scripts\list-service-build-commands.ps1
dotnet build .\Titan-Takeaway.Services.slnx -nologo
```

If you use Windows PowerShell 5.1, replace `pwsh` with `powershell`.

### Launch Full Stack

```bash
# Clone and start
git clone https://github.com/your-org/titan-takeaway.git
cd titan-takeaway
docker-compose -f infra/docker/docker-compose.yml up --build

# Wait 60-90 seconds for Elasticsearch to initialize
# Watch for "Cluster health status changed from [RED] to [GREEN]"
```

### Access Points

| Service | URL | Credentials |
|---------|-----|-------------|
| **Ordering UI** | http://localhost:5100 | N/A |
| **Grafana** | http://localhost:3000 | admin / admin |
| **Prometheus** | http://localhost:9090 | N/A |
| **Jaeger Traces** | http://localhost:16686 | N/A |
| **Elasticsearch** | http://localhost:9200 | N/A (security disabled for training) |
| **Loki** | http://localhost:3100 | Access via Grafana datasource |

### Resource-Constrained Environments

If you have 8GB RAM, use a profile or staged startup:

```bash
# Option 1: Use lite profile (no Elasticsearch/Kibana)
docker-compose --profile lite up

# Option 2: Start minimal stack first, add components later
docker-compose up sqlserver ordering-api payment-service kitchen-service delivery-tracker
# Then add observability when ready:
docker-compose up otel-collector prometheus grafana
```

See **Docker Compose Profiles** section for all available profiles.

---

## Contributing

See `.squad/` for team structure and routing. Architecture decisions are documented in `.squad/decisions.md`.
