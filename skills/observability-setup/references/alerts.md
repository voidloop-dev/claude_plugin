# Alerting

## Principles

- Page a human only for **user-impacting, actionable, urgent** problems.
- Everything else → ticket or Slack, reviewed in business hours.
- Every paging alert: a `for:` duration, a severity, a runbook link, an owner.
- Alert on symptoms (the user's experience), not causes (a machine's vitals).

## The starter set

| Alert | Condition | for | Severity | Runbook |
|---|---|---|---|---|
| SLO fast burn | budget burn 14.4x, 1h & 5m windows | 5m | page | slo-burn |
| SLO slow burn | budget burn 6x, 6h & 30m windows | 30m | page | slo-burn |
| Error rate | 5xx / total > 2% | 5m | page | high-error-rate |
| Latency SLO breach | p95 > {{threshold}} | 10m | ticket | high-latency |
| Saturation | request queue / pool > 90% | 10m | page | saturation |
| Queue unbounded | depth rising & > {{N}} & oldest age > {{T}} | 15m | page | queue-backlog |
| Job failure | scheduled job failed or missed its window | 0m | page | job-failure |
| Synthetic probe | external check of a core flow fails | 3m | page | probe-down |
| Dependency down | DB/cache/critical API unreachable | 2m | page | dependency-down |
| Cert / token expiry | < 14 days | 0m | ticket | cert-renewal |
| Disk / budget | disk > 85% or cloud spend forecast > cap | — | ticket | — |

## Anti-patterns (do not create)

- "CPU > 80%" — not user impact; autoscaling or a batch job is fine.
- "Pod restarted" — restarts are normal; alert on crash-loop rate instead.
- "Memory > X" — alert on OOMKills or saturation, not a gauge.
- Alerts with no runbook and no clear action.
- Duplicate alerts for the same symptom from 3 systems.

## Notification routing

`page` → on-call rotation (PagerDuty/Opsgenie/Grafana OnCall), ack required.
`ticket` → issue tracker, triaged next business day.
`slack` → team channel, FYI only.
