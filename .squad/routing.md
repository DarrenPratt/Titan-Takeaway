# Work Routing

How to decide who handles what.

## Routing Table

| Work Type | Route To | Examples |
|-----------|----------|----------|
| Architecture, scope, technical trade-offs | Tony | Service boundaries, API contracts, rollout plans |
| ASP.NET frontend + Bootstrap/JS/HTML/CSS | Peter | UI pages, order dashboards, responsive layout |
| Backend APIs + SQL Server data layer | Bruce | Ordering, kitchen, payment, delivery services |
| Containerization and local runtime | Rocket | Dockerfiles, docker-compose, service networking |
| OpenTelemetry instrumentation | Vision | Trace context propagation, spans, baggage |
| Prometheus + Grafana observability | Vision | Metrics exposure, scrape config, dashboards, alerts |
| Loki + Elasticsearch logging/search | Natasha | Log ingestion design, retention, query patterns |
| Jaeger tracing backend and analysis | Stephen | Trace storage/query flows, dependency graphs, sampling |
| GitHub platform workflows and automation | Nick | GitHub Actions, labels, issue/PR automation, workflow debugging |
| Test strategy and quality gates | Clint | Integration tests, failure simulations, regression checks |
| Session logging and memory | Scribe | Decision merge, orchestration log, cross-agent updates |
| Backlog/work monitor | Ralph | Queue checks, issue triage loop, unblock tracking |

## Issue Routing

| Label | Action | Who |
|-------|--------|-----|
| `squad` | Triage: analyze issue, assign `squad:{member}` label | Tony |
| `squad:tony` | Pick up issue and complete the work | Tony |
| `squad:peter` | Pick up issue and complete the work | Peter |
| `squad:bruce` | Pick up issue and complete the work | Bruce |
| `squad:rocket` | Pick up issue and complete the work | Rocket |
| `squad:vision` | Pick up issue and complete the work | Vision |
| `squad:natasha` | Pick up issue and complete the work | Natasha |
| `squad:stephen` | Pick up issue and complete the work | Stephen |
| `squad:nick` | Pick up issue and complete the work | Nick |
| `squad:clint` | Pick up issue and complete the work | Clint |

## Rules

1. Eager by default: parallelize independent work.
2. Scribe runs after substantial work batches.
3. Quick factual questions can be answered directly by coordinator.
4. Reviewer rejection lockout is enforced for rejected artifacts.
5. Ralph monitors queue health when activated.
