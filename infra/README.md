# Infrastructure Configuration

This directory contains all observability stack configurations for the Titan-Takeaway training platform.

## Directory Structure

```
infra/
├── otel-collector/
│   └── otel-collector-config.yaml    # OpenTelemetry Collector pipeline config
├── prometheus/
│   └── prometheus.yml                # Metrics scraping and storage config
├── grafana/
│   └── provisioning/
│       ├── datasources/
│       │   └── datasources.yml       # Auto-configured datasources
│       └── dashboards/
│           └── dashboard-provider.yml # Dashboard loading config
├── loki/
│   └── loki-config.yaml              # Log aggregation config
├── elasticsearch/
│   └── elasticsearch.yml             # Optional Elasticsearch baseline config
├── kibana/
│   └── kibana.yml                    # Optional Kibana baseline config
└── jaeger/
    └── (using default all-in-one config)
```

## Configuration Overview

### OpenTelemetry Collector (`otel-collector/otel-collector-config.yaml`)

**Purpose**: Receives OTLP signals from all services and routes to appropriate backends.

**Receivers**:
- OTLP gRPC (port 4317) - primary protocol
- OTLP HTTP (port 4318) - fallback/browser support

**Processors**:
- `batch`: Batches telemetry for efficient transmission (10s timeout, 1024 batch size)
- `memory_limiter`: Protects collector from OOM (512MB limit, 128MB spike)
- `resource`: Enriches signals with environment metadata

**Exporters**:
- `prometheusremotewrite`: Sends metrics to Prometheus via remote write API
- `prometheus`: Exposes collector self-monitoring metrics (port 8889)
- `otlp/jaeger`: Forwards traces to Jaeger (gRPC)
- `loki`: Sends logs to Loki with label-based indexing
- `elasticsearch/logs`: Optional log export to Elasticsearch (when profile enabled)
- `logging`: Console debug output (sampling: 1/200 after first 5)

**Pipelines**:
- **Traces**: OTLP → Memory Limiter → Resource → Batch → Jaeger
- **Metrics**: OTLP → Memory Limiter → Resource → Batch → Prometheus
- **Logs**: OTLP → Memory Limiter → Resource → Batch → Loki

**Telemetry Endpoints**:
- Health check: `http://localhost:13133`
- Internal metrics: `http://localhost:8888/metrics`
- ZPages (diagnostics): `http://localhost:55679`

---

### Prometheus (`prometheus/prometheus.yml`)

**Purpose**: Scrapes and stores time-series metrics from services and infrastructure.

**Scrape Targets**:
1. **otel-collector** (port 8889) - Collector metrics exported via Prometheus exporter
2. **otel-collector-internal** (port 8888) - Collector internal telemetry
3. **prometheus** (port 9090) - Self-monitoring
4. **ordering-api** (port 5100) - Service metrics endpoint `/metrics`
5. **payment-service** (port 5200) - Service metrics endpoint `/metrics`
6. **kitchen-service** (port 5300) - Service metrics endpoint `/metrics`
7. **delivery-tracker** (port 5400) - Service metrics endpoint `/metrics`
8. **jaeger** (port 14269) - Jaeger internal metrics
9. **loki** (port 3100) - Loki metrics endpoint

**Configuration**:
- Scrape interval: 15s (global), 10s (services)
- Scrape timeout: 10s
- Remote write: Enabled for OTel Collector integration
- Retention: 7 days (configured in Docker Compose)
- External labels: `cluster=titan-takeaway-local`, `environment=dev`

**Label Strategy**:
- `job`: Identifies scrape target
- `service`: Service name (ordering-api, payment-service, etc.)
- `tier`: Service tier (api, backend)
- `component`: Infrastructure component (collector, prometheus, jaeger, loki)
- `instance`: Host/container name (extracted via relabel_config)

---

### Grafana Datasources (`grafana/provisioning/datasources/datasources.yml`)

**Purpose**: Auto-configures datasources for unified signal correlation.

**Datasources**:

1. **Prometheus** (Default)
   - URL: `http://prometheus:9090`
   - Type: `prometheus`
   - Features: Exemplar traces (→ Jaeger), PromQL queries, alerting
   - UID: `prometheus`

2. **Jaeger**
   - URL: `http://jaeger:16686`
   - Type: `jaeger`
   - Features:
     - Traces to Logs: Correlates trace_id with Loki logs
     - Traces to Metrics: Links spans to Prometheus metrics
     - Node Graph: Service dependency visualization
     - Service Map: Real-time service topology
   - UID: `jaeger`

3. **Loki**
   - URL: `http://loki:3100`
   - Type: `loki`
   - Features:
     - Derived Fields: Auto-extracts trace_id and links to Jaeger
     - LogQL queries (similar to PromQL)
     - 1000 log lines max per query
   - UID: `loki`

4. **Elasticsearch** (Optional - commented out)
   - URL: `http://elasticsearch:9200`
   - Type: `elasticsearch`
   - Index: `titan-takeaway-logs*`
   - Features: Full-text search, advanced aggregations
   - UID: `elasticsearch`

**Correlation Workflows**:
- **Metrics → Traces**: Prometheus panel → Exemplar click → Jaeger trace
- **Traces → Logs**: Jaeger trace → "Logs for this span" → Loki filtered by trace_id
- **Traces → Metrics**: Jaeger span → Related metrics query in Prometheus
- **Logs → Traces**: Loki log → Derived field link → Jaeger trace

---

### Loki (`loki/loki-config.yaml`)

**Purpose**: Log aggregation with label-based indexing (cost-efficient alternative to Elasticsearch).

**Storage**:
- Type: `boltdb-shipper` (local filesystem)
- Chunks: `/loki/chunks`
- Indexes: `/loki/boltdb-shipper-active`
- Retention: 168h (7 days)
- Compaction: Every 10 minutes

**Limits** (Training-friendly):
- Ingestion rate: 10 MB/s
- Burst size: 20 MB
- Max streams: 10,000
- Max query series: 500
- Max entries per query: 5,000

**Query Config**:
- Max query length: 721h (30 days)
- Result caching: Enabled (100MB embedded cache)
- Parallelization: Enabled for shardable queries
- Slow query logging: >5 seconds

**Label Strategy**:
- Resource labels: `service.name`, `service.namespace`
- Attribute labels: `level`, `trace_id`, `span_id`
- Indexed by labels, NOT log content (low memory footprint)

---

## Docker Compose Profiles

The `docker-compose.yml` supports progressive complexity:

### `minimal` Profile (Fastest startup)
**Services**: SQL Server only  
**Use Case**: Local development without observability  
**Memory**: ~2GB  
**Command**: `docker-compose --profile minimal up -d`

### `lite` Profile (Recommended for training)
**Services**: SQL Server + OTel Collector + Prometheus + Jaeger + Loki + Grafana  
**Use Case**: Full observability without Elasticsearch  
**Memory**: ~5GB  
**Command**: `docker-compose --profile lite up -d`

### `full` Profile (Default)
**Services**: All services including Elasticsearch  
**Use Case**: Complete stack with full-text search  
**Memory**: ~7GB  
**Command**: `docker-compose up -d` or `docker-compose --profile full up -d`

### `search` Profile
**Services**: Adds Elasticsearch + Kibana to any profile  
**Use Case**: Enable full-text log search on demand  
**Command**: `docker-compose --profile lite --profile search up -d`

---

## Port Reference

| Service | Port(s) | Description |
|---------|---------|-------------|
| SQL Server | 1433 | Database connection |
| OTel Collector | 4317, 4318 | OTLP gRPC/HTTP receivers |
| OTel Collector | 8888, 8889 | Internal metrics, Prometheus exporter |
| OTel Collector | 13133 | Health check endpoint |
| OTel Collector | 55679 | ZPages diagnostics |
| Prometheus | 9090 | Metrics query UI and API |
| Jaeger | 16686 | Trace UI |
| Jaeger | 4317, 4318 | OTLP receivers (direct) |
| Jaeger | 14269 | Admin/metrics endpoint |
| Loki | 3100 | Log ingestion and query API |
| Elasticsearch | 9200 | REST API |
| Grafana | 3000 | Dashboards and Explore UI |
| Ordering API | 5100 | Service endpoint |
| Payment Service | 5200 | Service endpoint |
| Kitchen Service | 5300 | Service endpoint |
| Delivery Tracker | 5400 | Service endpoint |

---

## Access URLs

Once running, access the stack via:

- **Grafana**: http://localhost:3000 (admin/titan2026)
- **Prometheus**: http://localhost:9090
- **Jaeger**: http://localhost:16686
- **OTel Collector Health**: http://localhost:13133
- **OTel Collector ZPages**: http://localhost:55679

---

## Health Checks

All services include health checks with:
- **Interval**: 10-15s
- **Timeout**: 5-10s
- **Retries**: 5-10
- **Start Period**: 10-60s (Elasticsearch: 60s, others: 10-15s)

Check container health:
```bash
docker-compose ps
docker inspect --format='{{json .State.Health}}' titan-otel-collector
```

---

## Resource Limits

Default memory limits (training-optimized):

| Service | Memory Limit |
|---------|--------------|
| SQL Server | 2 GB |
| OTel Collector | 512 MB |
| Prometheus | 1 GB |
| Jaeger | 512 MB |
| Loki | 512 MB |
| Elasticsearch | 2 GB |
| Grafana | 512 MB |
| **Total (lite)** | **~5 GB** |
| **Total (full)** | **~7 GB** |

Adjust in `docker-compose.yml` via `mem_limit` if needed.

---

## Troubleshooting

### OTel Collector not receiving data
```bash
# Check collector logs
docker logs titan-otel-collector

# Verify health
curl http://localhost:13133

# Check ZPages for pipeline stats
curl http://localhost:55679/debug/pipelinez
```

### Prometheus not scraping services
```bash
# Check targets status
# Visit: http://localhost:9090/targets

# Verify service metrics endpoint
curl http://localhost:5100/metrics
```

### Grafana datasources not loading
```bash
# Check provisioning logs
docker logs titan-grafana | grep -i provision

# Verify datasource config
docker exec titan-grafana cat /etc/grafana/provisioning/datasources/datasources.yml
```

### Loki not receiving logs
```bash
# Check Loki logs
docker logs titan-loki

# Test Loki API
curl http://localhost:3100/ready

# Check ingestion stats
curl http://localhost:3100/metrics | grep loki_distributor
```

---

## Next Steps

1. **Bruce** (Backend Engineer): Instrument .NET services with OpenTelemetry SDK
2. **Rocket** (DevOps): Test startup on 4GB/8GB/16GB machines
3. **Vision** (Observability): Build reference Grafana dashboards
4. **Peter** (Frontend): Add browser trace context propagation
5. **Clint** (QA): Validate chaos scenarios with observability

---

## Training Scenarios Enabled

With this baseline configuration, trainees can now:

1. ✅ **Trace requests end-to-end** - Follow a single order through all services in Jaeger
2. ✅ **Calculate SLIs with PromQL** - p95 latency, error rates, throughput
3. ✅ **Correlate metrics to traces** - Click exemplars in Grafana to jump to Jaeger
4. ✅ **Query logs by trace_id** - Find all logs for a failed request in Loki
5. ✅ **Visualize service dependencies** - See service map in Jaeger
6. ✅ **Monitor collector health** - Check pipeline stats and backpressure
7. ✅ **Compare trace patterns** - Identify slow vs fast requests

---

## Configuration Philosophy

**Production-Realistic**: Patterns mirror real-world deployments (OTel Collector aggregation, remote write, multi-backend)

**Training-Optimized**: Low memory footprint, fast startup, progressive complexity via profiles

**Correlation-First**: Every datasource configured for cross-signal linking (metrics ↔ traces ↔ logs)

**Observable Observability**: All infrastructure components monitored (collector, Prometheus, Jaeger, Loki)

**Future-Proof**: Easy backend swaps (Jaeger → Tempo, Loki → Elasticsearch, add new exporters)
