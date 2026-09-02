---
name: deploy-strategies
description: >-
  Design and implement the release process: environment promotion (dev -> staging
  -> prod), a progressive rollout strategy (rolling / blue-green / canary) with
  automated health gates and fast rollback, backward-compatible database
  migrations (expand/contract), feature flags for decoupling deploy from release,
  and a release-versioning + changelog scheme. Use when a project deploys by
  hand, has downtime on deploy, has no rollback, or couples risky schema changes
  to code deploys. Not for building the CI pipeline itself (cicd-setup) or infra
  provisioning (iac-setup).
---

# deploy-strategies

Make shipping boring: every release is promoted through identical environments,
rolled out progressively behind health checks, reversible in one step, and
decoupled from schema changes and feature launches.

## When this applies

- Deploys cause downtime, or are manual/ad-hoc.
- No rollback plan beyond "redeploy the old branch and hope".
- Schema migrations run in lockstep with code and block rollback.
- "Set up staging", "blue-green", "canary", "zero-downtime deploy", "feature
  flags", "how do we roll back".

## Absolute rules

| Rule | Why |
|---|---|
| Promote the **same build artifact** (image digest / bundle hash) through every environment. Never rebuild per environment. | "Works in staging" only means something if prod runs the identical bits. |
| Environments are configuration-only different. Config comes from the environment, never from the artifact. | 12-factor; prevents "it was compiled for staging" bugs. |
| Every rollout is gated by an automated health signal (readiness + error rate + latency) and auto-aborts on regression. | Humans watching a graph miss the 3am rollout. |
| Rollback is a single action and is always available — keep N-1 running (blue-green) or redeploy the previous digest. Rollback must not require a rebuild. | MTTR dominates incident impact. |
| Database migrations are backward compatible (expand/contract): the previous app version must run against the new schema. Never destructive in the same deploy that needs the column. | Lets you roll back code without rolling back data; enables zero-downtime. |
| Deploying code ≠ releasing a feature. Ship dark behind a flag; turn on separately; the flag is also a kill switch. | Decouples risk; a bad feature is toggled off, not rolled back. |
| Health checks distinguish **liveness** (restart me) from **readiness** (don't send traffic yet). Drain connections on `SIGTERM` before exit. | Prevents dropped requests during rollout and restarts. |
| Each release has an immutable version (semver or date+SHA), a git tag, and a changelog entry generated from Conventional Commits. | Traceability from a running instance back to the exact code. |
| Prod deploys require the pipeline's checks green + a recorded approval; the approval and the deploy are audit-logged. | Change management, and a paper trail for incidents. |

## Procedure

1. **Environments** — define `dev`, `staging`, `prod` (add `preview` per-PR if
   useful). Identical topology; a config matrix (`references/config-matrix.md`)
   lists every variable per env and where it's stored (secret manager vs plain).
2. **Artifact promotion** — CI builds once, tags by digest, pushes to a registry.
   Promotion = deploying an existing digest to the next env. Record the
   digest→env→time in a deployments log.
3. **Pick a rollout strategy** (`references/strategies.md`):
   - *Rolling* — simplest, needs backward-compatible everything, slow rollback.
   - *Blue-green* — instant switch + instant rollback, 2x resources briefly.
   - *Canary* — 1%→10%→50%→100% with metric gates; best for high traffic.
   Choose from traffic, budget, and platform. Record in an ADR.
4. **Health gates** — implement `/healthz` (liveness) and `/readyz` (readiness,
   checks deps). Configure the platform probes + graceful shutdown
   (`references/graceful-shutdown.md`). Define abort thresholds (error rate,
   p95, probe failures).
5. **Migrations** — adopt expand/contract (`references/migrations-expand-contract.md`):
   migrations run as a separate pipeline step before the app rollout; only
   additive changes ship with the release that introduces them; drops come a
   release later after the old code is gone.
6. **Feature flags** — pick a system (OpenFeature + a provider, or a simple
   config-backed flag). Rules: default off, typed, owner + expiry per flag, kill
   switch semantics, remove stale flags. See `references/feature-flags.md`.
7. **Versioning & changelog** — Conventional Commits → `release-please` or
   `semantic-release` cuts the version, tag, GitHub Release, and `CHANGELOG.md`.
8. **Rollback runbook** — `references/rollback-runbook.md`: exact commands, who
   can run them, how to verify recovery, when to also revert a migration.
9. **Wire to CI/CD** — the deploy workflow (from `cicd-setup`) gains: promote job
   per env, `environment:` protection + approval for prod, migration step,
   progressive rollout, automatic abort+rollback on gate failure, deployment
   record + changelog.
10. **Verify** with a game-day: deploy a deliberately broken build to staging and
    confirm it auto-aborts and rolls back.

## Verification gate

1. The prod artifact digest equals the staging digest for the same release
   (check the deployments log).
2. No environment-specific values are baked into the artifact (grep the image/
   bundle for env URLs/keys).
3. `/healthz` and `/readyz` exist and behave differently (readyz fails when a
   dependency is down; healthz stays up).
4. `SIGTERM` triggers connection draining; a rollout mid-request drops zero
   requests (load test during deploy).
5. Rollback to the previous release completes with no rebuild and is a single
   command/click; measured MTTR recorded.
6. The last schema migration is backward compatible: the previous app version
   boots and passes smoke tests against the new schema.
7. At least one feature ships behind a flag that is off by default and can be
   toggled without a deploy.
8. Prod deploy requires green checks + approval; the deployment is recorded with
   who/what/when.
9. Releases produce a semver tag + `CHANGELOG.md` entry automatically.
10. Game-day: a broken canary auto-aborts on the metric gate and traffic returns
    to the stable version without human action.

Report pass/fail per item with evidence.

## Worked example

Containerised API on ECS, moderate traffic, small team.

- Envs: `staging`, `prod`; config in SSM Parameter Store + Secrets Manager,
  matrix documented.
- CI builds `api@sha256:abc`, pushes to ECR. Promotion = update the prod ECS
  service to that digest.
- Strategy: **blue-green** via CodeDeploy — new task set gets 0% traffic, smoke
  test, shift 100%, keep old task set 15 min for instant rollback. ADR-0004.
- Probes: ALB target group health = `/readyz`; ECS `stopTimeout=30s`; app traps
  `SIGTERM`, stops accepting, finishes in-flight, exits.
- Migrations: a `migrate` task runs pre-deploy; PR adding a column is additive;
  the follow-up PR (next release) drops the old column.
- Flags: OpenFeature + a JSON config in S3; new "digest email" ships off,
  enabled per-cohort later.
- `release-please` manages version/tag/CHANGELOG from Conventional Commits.
- Rollback runbook: `aws deploy stop-deployment --auto-rollback` or re-point to
  previous digest; verify `/readyz` + error rate < 1% for 5 min.
- Game-day: pushed a build that 500s on `/readyz` → CodeDeploy never shifted
  traffic, alarm fired, auto-rollback → 0 user impact. Gate 10/10.
