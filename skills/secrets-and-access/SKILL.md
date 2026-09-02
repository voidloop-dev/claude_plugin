---
name: secrets-and-access
description: >-
  Set up secrets management and access control for a project: a secret manager as
  the single source of truth, strict environment separation, keyless CI->cloud
  auth via OIDC (no long-lived cloud keys), least-privilege roles, secret
  rotation, pre-commit + CI secret scanning, and a documented break-glass
  procedure. Use when a project has secrets in .env files in git, shared
  credentials across environments, long-lived cloud access keys in CI, or no
  rotation. Not for the CI pipeline structure (cicd-setup) or infra provisioning
  (iac-setup) — this is the credential layer they both rely on.
---

# secrets-and-access

No secret in git, ever. One secret manager as source of truth. CI authenticates
to clouds without stored keys. Every identity has the least privilege it needs.

## When this applies

- `.env`, `*.pem`, service-account JSON, or `secrets.yaml` tracked in git (even
  in history).
- The same API key / DB password used in dev, staging, and prod.
- CI holds long-lived `AWS_ACCESS_KEY_ID` / GCP SA keys / `DOCKERHUB_TOKEN`.
- Nobody knows when a credential was last rotated; no revocation plan.
- "Manage secrets", "set up Vault / Secrets Manager / SOPS", "stop committing
  .env", "OIDC to AWS", "rotate keys".

## Absolute rules

| Rule | Why |
|---|---|
| Secrets never enter git — not the working tree, not history, not "encrypted just in case". Use a secret manager or an encrypted-secrets tool (SOPS/age, sealed-secrets) where only ciphertext is committed. | Git history is forever and widely cloned; a leaked prod secret is an incident. |
| One secret manager is the source of truth (cloud Secrets Manager / Parameter Store, HashiCorp Vault, Doppler, Infisical). Apps read from it (or from env injected by the platform from it) at deploy/boot. | Scattered secrets can't be rotated, audited, or revoked. |
| Every environment has its own distinct secret values. A dev credential must be useless against staging or prod. | Blast radius: a leaked dev key stays a dev problem. |
| CI authenticates to cloud providers and registries via **OIDC federation** issuing short-lived tokens. No long-lived cloud keys in CI secrets. | Static keys in CI are the most common breach vector; OIDC tokens expire in minutes and are scoped per workflow. |
| Least privilege: each human role, CI role, and service identity gets only the permissions it uses. Separate read (plan/deploy) from write/admin. No wildcards on resources or actions where avoidable. | Contains the damage from any single compromised identity. |
| Every secret has an owner and a rotation interval; rotation is automated or calendared, and tested. Rotating must not require downtime (support 2 valid keys during overlap). | Unrotated long-lived secrets accumulate exposure; manual rotation never happens. |
| Secret scanning runs as a pre-commit hook **and** a CI gate (gitleaks/trufflehog) with history scan. A hit blocks the merge. | Defence in depth against the rule above being broken by accident. |
| A leaked secret is **revoked and rotated**, not just removed from the code. Assume it was captured the moment it was pushed. | Deleting the commit does not un-leak it. |
| Access is audit-logged: who read/changed which secret, who assumed which role, when. Logs go to the central log store, retained. | Required for incident forensics and compliance. |
| A documented **break-glass** path exists for emergency elevated access: time-boxed, multi-approver or heavily alerted, auto-revoked, reviewed after use. | Incidents need a fast, controlled way past normal least-privilege. |

## Procedure

1. **Inventory** every secret the project uses (`references/secret-inventory.md`):
   name, purpose, which env, current store, owner, rotation interval, blast radius.
2. **Pick the manager** for the stack/cloud; document the access model. Record in
   an ADR.
3. **Purge git**: move secrets to the manager; scrub history
   (`git filter-repo` / BFG) if prod secrets were ever committed, then
   **rotate every one of them** regardless. Force-push coordination noted.
4. **Environment separation**: distinct paths/namespaces per env
   (`/myapp/prod/*`, `/myapp/staging/*`); distinct encryption keys where the
   manager supports it; distinct IAM so a staging identity can't read prod paths.
5. **Keyless CI** (`references/oidc-cheatsheet.md`): configure OIDC trust for the
   CI provider → cloud; create per-environment roles; delete any static cloud
   keys from CI secrets. Registries: use OIDC / GITHUB_TOKEN where possible.
6. **App wiring**: app reads secrets from env injected by the platform from the
   manager, or fetches from the manager at boot with its workload identity —
   never bundled. Fail fast if a required secret is missing.
7. **Least-privilege roles** (`references/access-model.md`): define human roles
   (viewer / developer / deployer / admin), CI roles (plan / apply per env),
   service identities. Write the policies tight; review quarterly.
8. **Rotation** (`references/rotation.md`): enable managed rotation where offered
   (RDS, etc.); for the rest, a calendared runbook per secret with the
   dual-key overlap procedure; alert on secrets past their interval.
9. **Scanning**: pre-commit hook (from `repo-bootstrap`) + CI job
   (`supply-chain-security` also covers this) with full-history scan; document
   the allowlist policy.
10. **Break-glass** (`references/break-glass.md`): a separate highly-privileged
    role, assumable only via an approved, alerted, time-boxed request; post-use
    review mandatory.
11. **Document** `docs/SECRETS.md`: the manager, the env layout, how apps get
    secrets, how CI authenticates, rotation schedule, the leak-response and
    break-glass runbooks.

## Verification gate

1. `git log -p --all | gitleaks detect --pipe` (or full-history scan) is clean;
   no secret files tracked (`git ls-files | grep -E '\.env$|\.pem$|sa.*\.json'`).
2. Pre-commit hook and CI secret-scan both block a test commit containing a fake
   AWS key.
3. Dev/staging/prod use different values for every shared secret (spot-check 3).
4. CI has zero long-lived cloud provider keys in its secret store; cloud calls
   use OIDC (check the workflow + a run log showing an assumed-role session).
5. A staging CI/app identity is denied when it tries to read a `prod/*` secret
   (test it).
6. Each secret in the inventory has an owner and a rotation interval; at least
   one rotation has been performed via the documented procedure with no downtime.
7. Secret reads/changes and role assumptions appear in the audit log.
8. Break-glass role exists, is not assumable without approval, and its use fires
   an alert.
9. App fails fast (clear error, non-zero exit) when a required secret is absent.
10. `docs/SECRETS.md` covers manager, env layout, app access, CI auth, rotation,
    leak response, break-glass.

Report pass/fail per item with evidence.

## Worked example

GitHub Actions + AWS, small team, secrets currently in a committed `.env.prod`.

1. Inventory: `DATABASE_URL`, `JWT_KEY`, `STRIPE_KEY`, `RESEND_KEY`,
   `SENTRY_DSN` (not secret) — per env.
2. Manager: AWS Secrets Manager for credentials, SSM Parameter Store for config.
   ADR-0005.
3. `git filter-repo` removed `.env.prod` from all history; **all four secrets
   rotated** (new Stripe key, new DB password via dual-user, new JWT key with
   overlap, new Resend key). Team re-cloned.
4. Paths `myapp/prod/*`, `myapp/staging/*`; KMS key per env; IAM policies scoped
   to the path prefix.
5. OIDC provider added; roles `deploy-staging` / `deploy-prod` (assume-role
   conditioned on repo + environment); removed `AWS_ACCESS_KEY_ID`/`SECRET` from
   Actions secrets. ECR login via OIDC.
6. ECS task role reads `myapp/prod/*` at task start; app validates all required
   env at boot and exits 1 if any missing.
7. Roles: humans get `developer` (read staging, no prod secrets) except two
   `deployer`s; break-glass `prod-admin`.
8. RDS managed rotation (30d); Stripe/Resend/JWT calendared 90d with overlap
   runbook; CloudWatch alarm on `LastRotated > interval`.
9. gitleaks pre-commit + CI (history) — verified it blocks a planted key.
10. Break-glass: `prod-admin` assumable only through an issue-ops approval that
    grants a 1-hour session and pages the lead.
11. `docs/SECRETS.md` written. Gate 10/10.
