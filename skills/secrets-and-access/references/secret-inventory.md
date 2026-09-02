# Secret inventory — {{PROJECT}}

_Review quarterly. Every row must have an owner and a rotation interval._

| Secret | Purpose | Envs | Store | Owner | Rotation | Blast radius if leaked | Last rotated |
|---|---|---|---|---|---|---|---|
| `DATABASE_URL` | app → Postgres | dev/stg/prod | Secrets Manager `myapp/<env>/db` | @backend | 30d (managed) | full data read/write | {{DATE}} |
| `JWT_SIGNING_KEY` | sign/verify sessions | stg/prod | Secrets Manager | @backend | 90d w/ overlap | forge any session | {{DATE}} |
| `STRIPE_SECRET_KEY` | payments | stg(test)/prod(live) | Secrets Manager | @payments | 90d | charge/refund, read customers | {{DATE}} |
| `RESEND_API_KEY` | transactional email | stg/prod | Secrets Manager | @backend | 90d | send mail as us | {{DATE}} |
| `OTEL_EXPORTER_OTLP_HEADERS` | telemetry auth | stg/prod | platform env | @sre | 180d | write junk telemetry | {{DATE}} |
| `GITHUB_APP_PRIVATE_KEY` | CI bot | n/a | Actions/OIDC | @sre | 180d | act as the app | {{DATE}} |

## Not secrets (safe in config / repo)

`SENTRY_DSN` (public DSN), `APP_ENV`, `LOG_LEVEL`, public URLs, feature-flag
client IDs.

## On any leak

1. Revoke the credential at the provider **now**.
2. Rotate (issue new, deploy, confirm).
3. Scrub from git history if committed.
4. Check audit/access logs for use during the exposure window.
5. Incident note + postmortem if prod.
