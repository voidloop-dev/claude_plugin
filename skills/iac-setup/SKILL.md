---
name: iac-setup
description: >-
  Stand up Infrastructure as Code to a professional standard with Terraform (or
  OpenTofu): a module-based repo layout, remote encrypted state with locking,
  per-environment isolation, a plan-on-PR / apply-on-merge pipeline with least-
  privilege cloud auth via OIDC, tagging and cost controls, and drift detection.
  Use when a project provisions cloud infrastructure and has none codified, or
  has hand-clicked ("ClickOps") infra, local state, or one shared environment.
  Not for app deploy rollout strategy (deploy-strategies) or k8s workloads.
---

# iac-setup

Make infrastructure reproducible, reviewable, and environment-isolated. Nobody
clicks in a cloud console; every change is a PR with a visible plan.

## When this applies

- Cloud resources exist but aren't in code, or `terraform.tfstate` is on someone's
  laptop / committed to git.
- One environment doubles as staging and prod; no isolation.
- "Set up Terraform", "IaC", "infrastructure pipeline", "manage our AWS/GCP/Azure
  in code".

## Absolute rules

| Rule | Why |
|---|---|
| Remote state backend (S3+DynamoDB / GCS / azurerm / TF Cloud), encrypted at rest, with locking. Never local state, never state in git. | State holds secrets and is the source of truth; concurrent applies corrupt it. |
| One state file per environment per component. Environments are separate directories or workspaces with separate backends — never a single state with a `count` toggle. | Blast radius: a bad prod apply must be impossible to trigger from a dev change. |
| CI authenticates to the cloud via short-lived OIDC federation, not stored long-lived keys. | A leaked static cloud key is game over; OIDC tokens expire in minutes. |
| `plan` runs on every PR and its output is posted to the PR. `apply` runs only on merge to the default branch (or a manual gated job), never from a PR. | Humans must see the diff before infra changes; PRs are untrusted. |
| Pin Terraform version (`required_version`) and every provider (`~>` with lockfile `.terraform.lock.hcl` committed). | Provider upgrades silently change plans. |
| Every resource carries standard tags/labels: `env`, `owner`, `project`, `managed-by=terraform`, `cost-center`. | Attribution, cost tracking, and safe cleanup. |
| No secrets in `.tf` or `.tfvars` in git. Inject via CI secret store / cloud secret manager / `TF_VAR_` env. Mark outputs `sensitive`. | `.tfvars` in git = credentials in history. |
| Reusable code lives in `modules/`; environments only compose modules and pass variables. | DRY, and prod/staging stay structurally identical. |
| Destructive plan changes (replace/destroy of stateful resources) require an explicit extra approval and a reason. | Prevents an accidental DB replace. |
| State backend resources (the bucket/table) are created once, out-of-band or in a bootstrap module with its own local→migrated state, and locked down. | Chicken-and-egg; and the backend must outlive everything. |

## Procedure

1. **Choose** Terraform vs OpenTofu (license), and the backend for the target
   cloud. Record in an ADR.
2. **Bootstrap state**: create the state bucket/table (versioned, encrypted,
   public-access-blocked, lifecycle-protected) via `references/bootstrap/`.
   Migrate its own state into itself.
3. **Repo layout** from `references/layout.md`:
   ```
   infra/
     modules/<name>/{main,variables,outputs,versions}.tf
     envs/{dev,staging,prod}/{main.tf,backend.tf,terraform.tfvars}
     global/            # org-wide: IAM/OIDC, DNS zones, state backend
   ```
4. **Write modules** — networking, data stores, compute, etc. Each: typed
   variables with descriptions + validation, explicit outputs, `versions.tf`
   with pinned providers, a `README.md`.
5. **Compose environments** — each env dir has its own `backend.tf` (distinct
   key/prefix), calls modules, sets env-specific sizes/counts. `prod` differs
   from `staging` only by variables.
6. **OIDC + roles** (`references/oidc/`): an identity-provider trust for GitHub
   Actions, one role per environment scoped to least privilege, `plan` role
   read-only, `apply` role write.
7. **Pipeline** (`references/workflow.yml`): matrix per env — `fmt -check`,
   `validate`, `tflint`, `checkov`/`tfsec`, `plan` (PR comment, saved plan
   artifact), `apply` on merge using the saved plan, manual approval env for prod.
8. **Tagging**: a `default_tags` provider block (AWS) / common labels module.
9. **Drift detection** (`references/drift.yml`): scheduled `plan`; non-empty plan
   opens an issue / alerts.
10. **Docs**: `infra/README.md` — how to plan locally (read-only), how changes
    ship, the environment map; ADRs for backend and cloud-layout decisions.

## Verification gate

1. `terraform init` uses a remote backend; no `*.tfstate` tracked by git (`git ls-files`).
2. `.terraform.lock.hcl` committed; `required_version` and all providers pinned.
3. Each environment has an isolated backend key and its own state (prove: `dev`
   plan cannot see `prod` resources).
4. CI cloud auth is OIDC — no long-lived cloud keys in repo/Actions secrets.
5. `plan` posts to PRs; `apply` job has no `pull_request` trigger; prod `apply`
   requires manual approval.
6. `fmt -check`, `validate`, `tflint`, and a security scanner all run in CI and block.
7. `terraform plan` on a clean `main` is empty (no drift) for every env.
8. Every managed resource shows the standard tags (spot-check in cloud console).
9. Scheduled drift job exists and alerts on non-empty plan.
10. `infra/README.md` + ADRs present.

Report pass/fail per item.

## Worked example

Single AWS account, GitHub Actions, dev+staging+prod.

- Backend: S3 (versioned, SSE-KMS, block-public) + DynamoDB lock table, created
  by `infra/global/state-backend` then state-migrated.
- OIDC: `token.actions.githubusercontent.com` provider; roles
  `tf-plan-{env}` (ReadOnlyAccess + state RW) and `tf-apply-{env}` (scoped
  write), trust policy conditioned on repo + branch/environment.
- `modules/`: `network` (VPC, subnets, NAT), `rds` (Postgres, multi-AZ only in
  prod via var), `ecs-service`. `envs/prod/terraform.tfvars` sets
  `db_instance_class = "db.t4g.medium"`, `multi_az = true`, `desired_count = 3`.
- `provider "aws" { default_tags { tags = { project = "myapp", managed-by =
  "terraform", env = var.env } } }`.
- Workflow: PR → fmt/validate/tflint/checkov/plan(comment) per env; merge →
  apply dev+staging auto, prod via `environment: production` approval using the
  uploaded plan file.
- Drift: nightly `plan`; non-empty → opens a GitHub issue.
- Gate 10/10; ADR-0003 "OpenTofu + S3 backend".
