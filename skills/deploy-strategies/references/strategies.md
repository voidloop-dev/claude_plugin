# Rollout strategies — how to choose

| | Rolling | Blue-green | Canary |
|---|---|---|---|
| How | Replace instances batch by batch | Stand up full new env, switch traffic at once | Route small % to new, ramp with metric gates |
| Rollback speed | Slow (roll forward/back batches) | Instant (flip back) | Instant (drop canary) |
| Extra cost | ~0 | ~2x during deploy | ~10% during deploy |
| Needs backward-compat | Yes (mixed versions serve) | No (clean cut) | Yes (mixed versions serve) |
| Best for | Small apps, k8s defaults | Stateless web/API, DB compat done | High traffic, want data-driven confidence |
| Watch out | Long deploys, partial-failure states | DB/session compat across the cut; warm caches | Needs good metrics + enough traffic for signal |

## Metric gates (canary / blue-green verification)

Abort + rollback automatically if, over the bake window (e.g. 5–10 min):

- readiness probe failure rate > 0
- HTTP 5xx rate > baseline + 1% (or absolute > 2%)
- p95 latency > baseline * 1.2
- error-log rate spike (> 3x baseline)
- key business metric drops (checkout success, etc.)

Tools: k8s → Argo Rollouts / Flagger. AWS → CodeDeploy + CloudWatch alarms.
Nomad → canary deployments. Platform PaaS (Fly/Render/Railway) → built-in
health-gated rolling; add your own smoke test + alarm for auto-rollback.

## Non-negotiables regardless of strategy

- Deploy the same artifact you tested.
- Readiness gates traffic; liveness gates restart.
- Graceful shutdown on SIGTERM.
- Previous version stays launchable with no rebuild.
- Migrations backward compatible.
