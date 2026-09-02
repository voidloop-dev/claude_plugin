# SLIs, SLOs, error budgets

## Definitions

- **SLI** — a ratio of good events to total events. `good / valid`.
- **SLO** — the target for that ratio over a window. e.g. 99.5% over 30 rolling days.
- **Error budget** — `(1 - SLO) * window`. 99.5%/30d = 0.5% = **3h 39m** of
  "bad" allowed per 30 days.

## Pick SLIs (start with 2–3, user-facing only)

| SLI type | Good events | Valid events |
|---|---|---|
| Availability | responses with status < 500 (and not timeouts) | all requests to the endpoint (exclude client 4xx like 401/404 if they're "working as intended") |
| Latency | requests served faster than threshold T | all successful requests |
| Freshness | records processed within T of arrival | all records |
| Correctness | jobs completing without error | all jobs |

Threshold T comes from user expectation, not current performance.

## Example SLO doc entry

```
SLO: Checkout availability
  SLI:   sum(rate(http_requests_total{route="/checkout",code!~"5.."}[5m]))
       / sum(rate(http_requests_total{route="/checkout"}[5m]))
  Target: 99.9% over 28 days
  Budget: 40m 19s / 28 days
  Owner:  payments team
```

## Burn-rate alerts (multiwindow, multi-burn-rate)

Alert on how fast the budget is being consumed, not on a raw threshold.

| Severity | Burn rate | Long window | Short window | Budget consumed before firing |
|---|---|---|---|---|
| Page (fast) | 14.4x | 1h | 5m | 2% |
| Page (slow) | 6x | 6h | 30m | 5% |
| Ticket | 3x | 24h | 2h | 10% |

Both windows must exceed the threshold to fire (kills flapping).

## Using the budget

- Budget left → ship features.
- Budget exhausted → freeze feature releases, only reliability work, until it recovers.
- Review SLO targets quarterly; a never-burning budget means the SLO is too loose.
