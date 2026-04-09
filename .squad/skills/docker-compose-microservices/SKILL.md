---
name: "docker-compose-microservices"
description: "Pattern for integrating microservices into docker-compose with OpenTelemetry, profiles, and proper dependencies"
domain: "docker, observability, microservices"
confidence: "high"
source: "earned - Titan-Takeaway microservices integration"
---

## Context

When adding microservices to docker-compose with observability stack (OpenTelemetry, Prometheus, Grafana), use profile-based organization and proper dependency management to enable progressive complexity.

Applies when:
- Multiple application services need containerization
- Services require OpenTelemetry instrumentation
- Different deployment scenarios (dev, training, full stack)
- Services share common infrastructure (database, message broker, observability)

## Patterns

### Profile Organization
```yaml
services:
  # Infrastructure (minimal profile)
  sqlserver:
    profiles: ["minimal", "lite", "full"]
  
  otel-collector:
    profiles: ["minimal", "lite", "full"]
  
  # Observability (lite profile adds traces/logs)
  jaeger:
    profiles: ["lite", "full"]
  
  loki:
    profiles: ["lite", "full"]
  
  # Applications (app + full profiles)
  ordering-api:
    profiles: ["app", "full"]
  
  payment-service:
    profiles: ["app", "full"]
```

**Profile Strategy:**
- `minimal`: Core infrastructure only (DB + metrics)
- `lite`: Infrastructure + traces/logs
- `app`: Application services + minimal dependencies
- `full`: Complete stack (default for training/development)

### Service Definition Template
```yaml
service-name:
  build:
    context: ./services/service-name
    dockerfile: Dockerfile
  container_name: titan-service-name
  environment:
    ASPNETCORE_ENVIRONMENT: Development
    OTEL_EXPORTER_OTLP_ENDPOINT: http://otel-collector:4317
    OTEL_SERVICE_NAME: service-name
    ConnectionStrings__DefaultConnection: "Server=sqlserver;Database=AppDB;User Id=sa;Password=Pass;TrustServerCertificate=True"
  ports:
    - "5000:8080"
  depends_on:
    sqlserver:
      condition: service_healthy
    otel-collector:
      condition: service_started
  restart: unless-stopped
  profiles: ["app", "full"]
```

### Key Environment Variables

**OpenTelemetry (Standard):**
- `OTEL_EXPORTER_OTLP_ENDPOINT`: Collector address (gRPC: 4317, HTTP: 4318)
- `OTEL_SERVICE_NAME`: Unique service identifier for traces/metrics
- `OTEL_RESOURCE_ATTRIBUTES`: Additional resource attributes (optional)

**ASP.NET (.NET Services):**
- `ASPNETCORE_ENVIRONMENT`: Development/Staging/Production
- `ASPNETCORE_URLS`: Override default port (already in Dockerfile)
- `ConnectionStrings__DefaultConnection`: SQL Server connection

**Service URLs (Inter-Service Communication):**
- Use container names as DNS: `http://ordering-api:8080`
- Pass as environment variables: `OrderingApiUrl: "http://ordering-api:8080"`

### Dependency Patterns

**Startup Order:**
1. **Infrastructure Layer:** sqlserver, elasticsearch, loki
2. **Observability Layer:** otel-collector, jaeger
3. **Application Layer:** backend services
4. **Frontend Layer:** web-app (depends on backend)

**Health Check Dependencies:**
```yaml
depends_on:
  sqlserver:
    condition: service_healthy  # Wait for health check
  otel-collector:
    condition: service_started  # Just wait for startup
  ordering-api:
    condition: service_started  # Service-to-service
```

### Port Mapping Strategy

**Sequential Ports for Backend Services:**
- ordering-api: 5000 (main API gateway)
- payment-service: 5001
- kitchen-service: 5002
- delivery-service: 5003

**Standard Ports for Infrastructure:**
- Web frontend: 8080
- Grafana: 3000
- Prometheus: 9090
- Jaeger UI: 16686
- SQL Server: 1433

### Networking

**Default Bridge Network:**
- All services on same network (implicit)
- Container names as DNS (titan-ordering-api → ordering-api:8080)
- No explicit network definition needed for simple setups

**Custom Networks (Advanced):**
```yaml
networks:
  app-tier:
    driver: bridge
  db-tier:
    driver: bridge
```

## Examples

### Adding a New Service

1. **Create Dockerfile** in `./services/new-service/`
2. **Add to docker-compose.yml:**
```yaml
new-service:
  build:
    context: ./services/new-service
    dockerfile: Dockerfile
  container_name: titan-new-service
  environment:
    OTEL_EXPORTER_OTLP_ENDPOINT: http://otel-collector:4317
    OTEL_SERVICE_NAME: new-service
    ConnectionStrings__DefaultConnection: "Server=sqlserver;..."
  ports:
    - "5004:8080"
  depends_on:
    sqlserver:
      condition: service_healthy
    otel-collector:
      condition: service_started
  restart: unless-stopped
  profiles: ["app", "full"]
```

3. **Validate:**
```bash
docker compose config --quiet
docker compose --profile app up -d new-service
```

### Service-to-Service Communication

**Ordering API calling Payment Service:**
```yaml
ordering-api:
  environment:
    PaymentServiceUrl: "http://payment-service:8080"
```

**In Code (.NET):**
```csharp
var paymentUrl = Configuration["PaymentServiceUrl"];
var response = await httpClient.GetAsync($"{paymentUrl}/api/payments");
```

## Anti-Patterns

❌ **Don't use localhost for inter-service URLs**
```yaml
PaymentServiceUrl: "http://localhost:5001"  # WRONG
```
✅ **Use container names:**
```yaml
PaymentServiceUrl: "http://payment-service:8080"  # CORRECT
```

❌ **Don't mix profiles randomly**
```yaml
sqlserver:
  profiles: ["minimal", "full"]  # WRONG - skips lite

ordering-api:
  profiles: ["lite"]  # WRONG - apps in lite?
```

❌ **Don't forget restart policies for apps**
```yaml
ordering-api:
  # Missing restart: unless-stopped
```

❌ **Don't use service_started for databases**
```yaml
depends_on:
  sqlserver:
    condition: service_started  # WRONG - DB may not be ready
```
✅ **Use health checks:**
```yaml
depends_on:
  sqlserver:
    condition: service_healthy  # CORRECT
```

❌ **Don't hardcode passwords in production**
```yaml
MSSQL_SA_PASSWORD: "Your_strong_Password123"  # OK for dev, use secrets in prod
```

❌ **Don't forget TrustServerCertificate for SQL Server**
```
Server=sqlserver;...;TrustServerCertificate=True
```

## Validation

```bash
# Validate compose syntax
docker compose config --quiet

# List available profiles
docker compose config --profiles

# Test specific profile
docker compose --profile app up -d

# Verify service connectivity
docker compose exec ordering-api curl http://payment-service:8080/health

# Check OpenTelemetry endpoint
docker compose exec ordering-api curl http://otel-collector:4317
```

## Resource Considerations

**Memory Estimates (per service):**
- .NET API: 300-500MB
- .NET with OTel: +50MB overhead
- Frontend: 200-400MB

**Full Stack (15 containers):**
- Infrastructure: ~12GB
- Applications: ~2GB
- **Total:** ~14GB recommended

**Profile-Based Resource Planning:**
- `minimal`: ~2GB (DB + metrics)
- `lite`: ~4GB (+ traces/logs)
- `app`: ~3GB (apps + minimal deps)
- `full`: ~14GB (complete stack)
