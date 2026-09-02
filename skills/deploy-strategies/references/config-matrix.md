# Environment configuration matrix — {{PROJECT}}

The artifact is identical across environments. Everything that differs is here.

| Variable | dev | staging | prod | Stored in | Secret? |
|---|---|---|---|---|---|
| `APP_ENV` | dev | staging | production | platform env | no |
| `LOG_LEVEL` | debug | info | info | platform env | no |
| `DATABASE_URL` | local | staging RDS | prod RDS | secret manager | **yes** |
| `REDIS_URL` | local | ... | ... | platform env | no |
| `JWT_SIGNING_KEY` | dev-only | unique | unique | secret manager | **yes** |
| `STRIPE_KEY` | test | test | live | secret manager | **yes** |
| `FEATURE_FLAGS_URL` | ... | ... | ... | platform env | no |
| `SENTRY_DSN` | — | set | set | platform env | no |
| replica count | 1 | 2 | {{4}} | IaC tfvars | no |
| instance size | small | small | {{medium}} | IaC tfvars | no |

## Rules

- Secrets never in the repo, never in plain platform env if the platform logs it
  — use the secret manager. See `secrets-and-access`.
- Adding a config key = add a row here + `.env.example` + validation at boot
  (fail fast if a required var is missing/empty).
- No `if (env === 'prod')` branching in app code for anything a config value can
  express.
