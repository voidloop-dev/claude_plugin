# Access model

## Human roles

| Role | Secrets | Infra | Prod | Who |
|---|---|---|---|---|
| viewer | none | read-only | read-only | stakeholders |
| developer | read **dev** only | read-only | no access | all engineers |
| deployer | read staging + prod (deploy-time only) | plan all, apply staging | deploy via pipeline only | 2–3 people |
| admin | manage all | apply all | full | 1–2 people |
| break-glass | prod admin, **time-boxed** | full | full | assumable on approval only |

- Prefer group membership (IdP) → role mapping over per-person grants.
- Prod console access is read-only for humans; changes go through pipelines.
- MFA required for deployer and above. SSO everywhere.

## Machine identities

| Identity | Can do | Cannot do |
|---|---|---|
| `ci-plan-<env>` | read state, read-only cloud, read that env's secrets | write anything |
| `ci-apply-<env>` | write the resources this stack manages in `<env>` | touch other envs, IAM admin, delete state bucket |
| `app-<env>` (workload identity) | read `myapp/<env>/*` secrets, the queues/buckets it uses | read other envs, write IAM |
| `backup` | write to the backup bucket, read DB snapshots | delete backups (separate retention lock) |

## Policy hygiene

- No `"Action": "*"` or `"Resource": "*"` unless genuinely unavoidable (document why).
- Deny-by-default; grant per resource ARN / path prefix.
- Separate the identity that can **delete** state/backups from the one that
  writes them.
- Review all policies + role memberships quarterly; remove unused grants
  (access analyzer / `iam-least-privilege` tooling).
