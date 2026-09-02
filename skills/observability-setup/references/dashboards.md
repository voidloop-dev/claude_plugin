# Dashboards

Fewer, sharper. Every panel answers a specific question an operator asks during
an incident. If you can't name the question, delete the panel.

## Service overview (one per service)

Row 1 — RED:
- Request rate by route (stacked)
- Error rate % (with the SLO target line)
- Latency p50 / p95 / p99 (one panel, three series)

Row 2 — SLO:
- Error budget remaining (30d), as a bar
- Burn rate (current), with the 1x / 6x / 14.4x lines

Row 3 — Saturation:
- CPU + memory vs limits
- Connection pool / worker pool utilization
- Queue depth + oldest-message age

Row 4 — Dependencies:
- DB query latency p95, error rate
- Cache hit rate
- Downstream API latency + errors

Overlay: **deploy annotations** (vertical lines) so regressions line up with releases.

## Per critical business flow (checkout, signup, ...)

- Funnel: attempts → successes → success rate
- Latency of the flow end-to-end
- Failure reasons breakdown (by `err.kind` label — bounded set only)

## Per critical dependency (Postgres, Redis, queue)

USE: utilization, saturation, errors. Plus the dependency's own key metrics
(replication lag, evictions, dead-letter count).

## Rules

- Time range and refresh sensible (last 6h / 30s).
- Every graph has units and a threshold line where one exists.
- Link each dashboard to the relevant runbooks.
- No dashboard nobody opened in 90 days — prune it.
