---
name: observability-setup
description: >-
  Instrument a service so operators can answer "is it healthy, and if not why"
  without SSH: structured logs, RED/USE metrics, distributed traces via
  OpenTelemetry, correlation IDs across the three, SLOs with error budgets,
  actionable alerts (symptom-based, not cause-based), and dashboards + runbooks.
  Use when a service has print-debugging only, no metrics, alerts that page on
  CPU, or no way to trace a slow request. Not for CI (cicd-setup) or infra
  provisioning of the monitoring stack itself (iac-setup).
---

# observability-setup

Give the service the three pillars wired together, SLOs that define "healthy",
and alerts that page a human only when users are actually affected.

## When this applies

- Debugging production means reading raw `console.log` / `print`.
- No metrics, or metrics no one looks at; alerts on CPU/memory/disk instead of
  user impact.
- Can't answer "where did this 8-second request spend its time".
- "Add monitoring", "set up Grafana/Prometheus/OTel", "SLOs", "on-call alerts".

## Absolute rules

| Rule | Why |
|---|---|
| One instrumentation layer: **OpenTelemetry** for traces + metrics (and logs where supported). Export to whatever backend; don't couple code to a vendor. | Re-instrumenting to switch vendors is months of work. |
| Logs are structured (JSON), one event per line, with a stable schema: timestamp, level, message, `trace_id`, `span_id`, `service`, plus typed fields. No string interpolation of data into the message. | Unparseable logs can't be queried, correlated, or alerted on. |
| Every log line, metric exemplar, and trace for one request shares a **correlation/trace ID**, propagated across service and queue boundaries (W3C `traceparent`). | Without it you cannot follow one request through the system. |
| Never log secrets, credentials, tokens, full PII, card numbers, or auth headers. Redact at the logger. | Logs get shipped to third parties and retained for months. |
| Metrics follow **RED** (Rate, Errors, Duration) for request-driven services and **USE** (Utilization, Saturation, Errors) for resources. Latency is a histogram, never an average. | Averages hide the tail; the tail is the user pain. |
| Alerts page on **symptoms** (SLO burn, error rate, latency, queue growing unboundedly), not causes (high CPU, a pod restarted). Every paging alert links a runbook and is actionable. | Cause-based alerts cause pager fatigue and miss novel failures. |
| Define SLIs/SLOs before dashboards. The error budget drives release decisions. | Dashboards without a target are just decoration. |
| Cardinality discipline: never put user IDs, request IDs, emails, or unbounded values in metric labels. | High-cardinality labels blow up the TSDB and the bill. |
| Instrumentation must be low-overhead and fail-open: if the collector is down, the app keeps serving. | Observability must never be a availability risk. |

## Procedure

1. **Define SLIs/SLOs** (`references/slo.md`): for each user-facing operation pick
   an SLI (availability = good responses / total; latency = % under threshold),
   set an SLO target (e.g. 99.5% / 30d), compute the error budget, decide the
   burn-rate alert thresholds.
2. **Structured logging** (`references/logging.md`): adopt a JSON logger (pino /
   structlog / zap / slog), fix the field schema, add a redaction list, inject
   `trace_id`/`span_id`, log to stdout only. Levels: error/warn/info/debug with a
   clear meaning each.
3. **OpenTelemetry SDK** (`references/otel-setup.md`): auto-instrument HTTP
   server/client, DB, cache, queue; add manual spans around meaningful business
   operations; set `service.name`, `service.version`, `deployment.environment`
   resource attrs; configure the OTLP exporter to a collector.
4. **Collector** — deploy the OTel Collector as the single egress point (batch,
   retry, redact, route). App → collector → backend(s).
5. **Metrics** — emit RED for every endpoint (via OTel), USE for runtime/infra;
   expose or push per the backend. Use histogram buckets tuned to the SLO
   threshold.
6. **Dashboards** (`references/dashboards.md`): one "service overview" (RED +
   saturation + SLO burn + deploy markers), one per critical dependency, one
   per critical business flow. Keep it small; every panel answers a question.
7. **Alerts** (`references/alerts.md`): SLO fast-burn + slow-burn, error-rate
   spike, latency SLO breach, queue depth unbounded, job failure, cert expiry,
   synthetic probe down. Each: threshold, `for:` duration, severity, runbook
   link. Route: page vs ticket vs Slack.
8. **Runbooks** (`references/runbook-template.md`): one per paging alert —
   what it means, dashboards to open, first checks, common causes, mitigations,
   escalation.
9. **Trace-log correlation** — verify a log line's `trace_id` opens the trace and
   vice versa in the chosen UI.
10. **Continuous** — add deploy annotations to dashboards, review SLOs monthly,
    prune noisy alerts, delete unused dashboards.

## Verification gate

1. All logs are valid JSON with the fixed schema; a sample request's logs all
   carry the same `trace_id`.
2. Redaction works: a test request with a fake token/PII produces logs with those
   values masked.
3. A request across ≥2 components produces one connected trace with correct
   parent/child spans and DB/cache spans.
4. RED metrics exist for every HTTP route; latency is a histogram with p50/p95/p99
   queryable.
5. No metric label contains an unbounded/high-cardinality value (inspect label
   sets).
6. Each SLO has: SLI query, target, error budget, and a burn-rate alert.
7. Every paging alert has a `for:` duration, a severity, and a runbook link that
   resolves.
8. No alert pages on raw CPU/memory/disk/pod-restart alone.
9. Killing the collector does not break the app (requests still served).
10. The service-overview dashboard shows RED + SLO burn + deploy markers and
    loads in < 5s.

Report pass/fail per item.

## Worked example

Node API + Postgres + a worker, backend = Grafana Cloud (Loki/Mimir/Tempo).

- SLOs: `GET /api/*` availability 99.5%/30d; latency SLO = 95% < 300ms.
  Error budget = 3.6h/30d. Fast-burn alert at 14.4x for 5m; slow-burn 3x for 1h.
- Logging: `pino` with `redact: ['req.headers.authorization','*.password','*.token']`,
  base fields `service`, `env`, `version`; mixin injects `trace_id`.
- OTel: `@opentelemetry/sdk-node` auto-instruments http+pg; manual span
  `digest.build`; resource `service.name=api`, `deployment.environment` from env;
  OTLP → local collector.
- Collector: deployment with `batch`, `memory_limiter`, `attributes` (drop
  `http.request.header.*`), exporters to Tempo/Mimir/Loki.
- Dashboards: "API overview" (req rate, error %, p50/95/99, DB pool, SLO burn,
  deploy markers), "Postgres", "Digest job".
- Alerts: SLO burn (page), 5xx > 2% 5m (page), p95 > 300ms 10m (ticket), worker
  job failed (page), queue depth > 1000 15m (page), TLS < 14d (ticket).
- Runbooks in `docs/runbooks/` linked from each alert.
- Gate 10/10 after masking a leaked `authorization` header in step 2.
