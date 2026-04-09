# Observability Stack Quick Start

## Prerequisites

- Docker Desktop with at least 6GB RAM allocated
- Docker Compose v2.0+
- 10GB free disk space

## Startup

### Option 1: Lite Profile (Recommended)
Full observability without Elasticsearch - best for training.

```bash
docker-compose --profile lite up -d
```

**Included Services:**
- SQL Server
- OpenTelemetry Collector
- Prometheus
- Jaeger
- Loki
- Grafana

**Memory Usage:** ~5GB

### Option 2: Full Profile
Complete stack including Elasticsearch for full-text log search.

```bash
docker-compose --profile full up -d
```

**Additional Services:**
- Elasticsearch

**Memory Usage:** ~7GB

### Option 3: Minimal Profile
Database only, no observability stack.

```bash
docker-compose --profile minimal up -d
```

**Memory Usage:** ~2GB

## Health Check

Wait for all services to be healthy (~60 seconds for lite, ~120 seconds for full):

```bash
docker-compose ps
```

All services should show `healthy` status.

## Access Points

| Service | URL | Credentials |
|---------|-----|-------------|
| Grafana | http://localhost:3000 | admin / titan2026 |
| Prometheus | http://localhost:9090 | - |
| Jaeger UI | http://localhost:16686 | - |
| OTel Collector Health | http://localhost:13133 | - |
| OTel Collector ZPages | http://localhost:55679 | - |

## Verify Setup

### 1. Check Grafana Datasources
1. Open http://localhost:3000 (admin/titan2026)
2. Navigate to **Connections** → **Data sources**
3. Verify all datasources show green checkmark:
   - ✅ Prometheus
   - ✅ Jaeger
   - ✅ Loki

### 2. Check Prometheus Targets
1. Open http://localhost:9090/targets
2. Verify these targets are **UP**:
   - otel-collector (8889)
   - otel-collector-internal (8888)
   - prometheus (9090)
   - jaeger (14269)
   - loki (3100)
3. Service targets will show **DOWN** until services are implemented (expected)

### 3. Check OTel Collector Health
```bash
curl http://localhost:13133
```
Should return: `{"status":"Server available"}`

### 4. View OTel Collector Metrics
```bash
curl http://localhost:8889/metrics
```
Should return Prometheus-format metrics.

## Troubleshooting

### Containers not starting
```bash
# Check logs
docker-compose logs -f otel-collector
docker-compose logs -f prometheus

# Check resource usage
docker stats
```

### Elasticsearch slow to start
Elasticsearch can take 30-60 seconds to become healthy. Be patient.

### Port conflicts
If you see "port already allocated" errors:
```bash
# Check what's using the port
netstat -ano | findstr :3000   # Windows
lsof -i :3000                  # Mac/Linux

# Stop conflicting service or change port in docker-compose.yml
```

### Out of memory
If containers are being killed (OOM):
1. Stop stack: `docker-compose down`
2. Increase Docker Desktop memory allocation (Settings → Resources)
3. Use lighter profile: `docker-compose --profile lite up -d`

## Shutdown

### Stop services (keep data)
```bash
docker-compose down
```

### Stop and remove all data
```bash
docker-compose down -v
```

## Next Steps

Once services are implemented by Bruce:
1. Uncomment service definitions in `docker-compose.yml`
2. Start full stack: `docker-compose --profile lite up -d`
3. Send test request to ordering-api: `curl http://localhost:5100/health`
4. View trace in Jaeger: http://localhost:16686
5. View metrics in Grafana: http://localhost:3000

## Support

- Configuration details: See `infra/README.md`
- Decision rationale: See `.squad/decisions/inbox/vision-observability-baseline.md`
- Troubleshooting: See `infra/README.md` Troubleshooting section
