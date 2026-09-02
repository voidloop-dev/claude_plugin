# Runbook: {{ALERT NAME}}

_Linked from alert: `{{alert_id}}`. Last reviewed: {{DATE}}._

## What this alert means

{{Plain English: what condition fired, and what the user is experiencing right
now because of it.}}

## Severity & response

- Severity: {{page / ticket}}
- Expected response time: {{15 min for page}}
- Owner team: {{...}}

## First 5 minutes

1. Open: [service overview dashboard]({{url}}), [traces]({{url}}), [logs]({{url}}).
2. Check: is there a deploy in the last 30 min? → consider rollback
   (`deploy-strategies` rollback runbook).
3. Check: is a dependency down? (DB / cache / downstream API panels)
4. Check: is traffic abnormal? (spike, bot, ret/storm)
5. Scope it: one route / one region / one customer / global?

## Common causes & mitigations

| Cause | Signal | Mitigation |
|---|---|---|
| Bad deploy | error rate steps up right after a deploy marker | roll back / disable the feature flag |
| DB saturation | pool at 100%, query p95 up | kill long queries, scale reader, shed load |
| Downstream slow | one dependency's latency panel spiking | enable circuit breaker / fallback, raise timeout budget |
| Traffic surge | request rate 3x, all else healthy-ish | scale out, enable rate limiting |
| Poison message | worker error loop on one payload | move to DLQ, deploy guard |

## If you can't mitigate in {{15}} min

Escalate to {{secondary on-call / team lead}}. Post status to {{status page /
#incidents}}. Start an incident doc.

## After recovery

- [ ] Confirm SLIs back to baseline for {{15}} min
- [ ] Clear/ack alerts
- [ ] Write the timeline; schedule a blameless postmortem within {{3}} days
- [ ] File follow-up actions as issues
