# Rollback runbook — {{PROJECT}}

_Keep this current. Test it in a game-day every quarter._

## When to roll back

Roll back (don't debug forward) if, after a deploy:
- error rate > {{2%}} for {{5}} min, or
- p95 latency > {{2x}} baseline, or
- a core flow (login, checkout, {{...}}) is broken, or
- data corruption is suspected → roll back **and** freeze writes.

Decision owner: {{on-call engineer}}. No approval needed to roll back.

## How to roll back (code)

| Platform | Command |
|---|---|
| ECS + CodeDeploy | `aws deploy stop-deployment --deployment-id <id> --auto-rollback-enabled` |
| Kubernetes | `kubectl rollout undo deployment/{{app}} -n {{ns}}` |
| Argo Rollouts | `kubectl argo rollouts undo {{app}}` |
| Plain (digest) | redeploy previous image digest: `{{deploy script}} {{prev_digest}}` |
| PaaS (Fly/Render) | `fly deploy --image {{prev}}` / dashboard "rollback" |

Previous good digest is in the deployments log / `CHANGELOG.md` / registry tags.
**Never rebuild to roll back.**

## Database

- If the last release only ran **additive** migrations (expand/contract done
  right): roll back code only. Schema is a superset; old code is fine.
- If a **destructive** migration ran (it shouldn't have): restore from the
  pre-deploy backup / PITR to just before the migration, then redeploy old code.
  Announce data-loss window.

## Verify recovery

- [ ] `/readyz` green on all instances
- [ ] error rate < {{1%}} and p95 back to baseline for {{5}} min
- [ ] the broken flow works (manual smoke)
- [ ] alerts cleared
- [ ] post the incident timeline; open a follow-up issue; schedule a postmortem

## Feature-flag fast path

If the bad change is behind a flag: **turn the flag off first** — it's faster
than a rollback and needs no deploy. Roll back only if the flag-off state is
still broken.
