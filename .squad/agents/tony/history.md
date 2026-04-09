# Project Context

- **Owner:** Darren Pratt
- **Project:** Titan-Takeaway training platform for OpenTelemetry, Prometheus, and Grafana.
- **Stack:** ASP.NET microservices, SQL Server, Docker, OpenTelemetry, Prometheus, Grafana, Bootstrap, JavaScript, HTML, CSS.
- **Created:** 2026-03-25T11:52:26Z

## Learnings

- Initial squad cast selected from Marvel Cinematic Universe for this repository.
- Core training scenarios include payment failures, kitchen latency, stuck orders, and retry storms.

### Architecture Foundation (2026-03-25)

- **Service Boundaries:** Four services (Ordering API, Payment, Kitchen, Delivery) — balances learning complexity with local dev resources.
- **Data Pattern:** Single SQL Server, schema-per-service (`[ordering]`, `[payment]`, `[kitchen]`, `[delivery]`). Services must NOT query across schema boundaries.
- **Communication:** Synchronous HTTP only — no message broker. Keeps stack simple for training.
- **Observability Stack:** OTel Collector aggregates all telemetry → routes to Prometheus (metrics) and Jaeger (traces) → Grafana for dashboards.
- **Chaos Engineering:** Env vars (`SIMULATE_*`) + Admin API (`/admin/chaos/*`) for failure injection.
- **Repo Structure:** `src/` for services, `infra/` for Docker/OTel/Prometheus/Grafana configs, `docs/exercises/` for training content.
- **Key Files:** `README.md` (architecture overview), `.squad/decisions/inbox/tony-architecture-foundation.md` (decision note).
- **Frontend:** Bootstrap + vanilla JS served from Ordering API `wwwroot/` — avoids separate frontend container.

### Observability Stack Expansion (2026-03-25)

- **Jaeger:** Promoted from optional to required. Essential for trace visualization and training on distributed tracing.
- **Loki:** Added for log aggregation with LogQL. Integrates natively with Grafana; label-based indexing for structured logs.
- **Elasticsearch:** Added for full-text log search. Enables training scenarios searching for error messages and stack traces.
- **Data Flow:** OTel Collector → Jaeger (traces), Prometheus (metrics), Loki (logs), Elasticsearch (logs).
- **Training Impact:** Added Module 3 (Logging & Search) to learning path; trainees now cover all three pillars of observability.
- **Resource Budget:** ~900MB additional RAM for local Docker (Jaeger: 256MB, Loki: 128MB, Elasticsearch: 512MB).
- **Key Learning:** Full observability requires all three pillars (metrics, traces, logs). Trade-off between Loki (label-indexed, lightweight) and Elasticsearch (full-text, heavier) is complementary, not competitive.

### Implementation Blueprint (2026-03-25)

- **Build Plan Created:** `.squad/decisions/inbox/tony-build-plan.md` — sequenced 10-phase implementation roadmap with parallel paths.
- **Repo Structure:** `src/` (4 services + TitanTakeaway.sln), `infra/docker/`, `infra/otel/`, `infra/prometheus/`, `infra/grafana/`, `infra/jaeger/`, `infra/loki/`, `infra/elasticsearch/`.
- **Docker Profiles:** Four progressive learning tiers: `minimal` (core, 1.9GB), `observability-lite` (metrics, 2.5GB), `traces-only` (3.0GB), `full` (all pillars, 4.2GB). Enables learning on 4GB–16GB machines.
- **Service Ports:** OrderingApi 5100, Payment 5200, Kitchen 5300, Delivery 5400. OTel 4317/4318, Prometheus 9090, Grafana 3000, Jaeger 16686, Loki 3100, Elasticsearch 9200.
- **Naming Conventions:** C# projects PascalCase (`OrderingApi`), Docker containers lowercase-hyphen (`ordering-api`), schemas lowercase-bracket (`[ordering]`), env vars SCREAMING_SNAKE_CASE.
- **Critical Path:** Phase 1 (solution) → Phase 3 (boilerplate) → Phase 4 (OTel) → Phases 5–7 (parallel) → Phase 8 (compose) → Phase 9 (tests) → Phase 10 (docs).
- **Key Decision:** All four services always-on; observability components gated by Docker Compose profiles. Enables "turn knobs, not rebuild" approach to learning outcomes.
- **Success Metrics:** 4GB machines run minimal profile; traces/metrics/logs correlated in full profile; <60s startup, <5min rebuild.
