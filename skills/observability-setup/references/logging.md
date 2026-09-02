# Structured logging standard

## Schema (every line)

| Field | Type | Notes |
|---|---|---|
| `ts` | RFC3339 string | UTC |
| `level` | enum | error \| warn \| info \| debug |
| `msg` | string | static text — **no interpolated data** |
| `service` | string | resource attr |
| `env` | string | dev/staging/production |
| `version` | string | build SHA / semver |
| `trace_id`, `span_id` | string | from the active OTel context |
| `req_id` | string | if no trace context |
| ...typed fields | — | `user_id`, `route`, `status`, `duration_ms`, `err.kind` |

Good: `log.info("http_request", { route, status, duration_ms })`
Bad:  `log.info(\`GET \${route} -> \${status} in \${ms}ms\`)`

## Levels

| Level | Use for | Pages? |
|---|---|---|
| error | a request/job failed; needs attention | via alert if rate high |
| warn | degraded but handled (retry, fallback, near-limit) | no |
| info | lifecycle + one line per request/job | no |
| debug | development detail; off in prod by default | no |

## Redaction (deny-list at the logger)

Always redact: `authorization`, `cookie`, `set-cookie`, `password`, `token`,
`secret`, `api_key`, `access_token`, `refresh_token`, `card`, `cvv`, `ssn`,
full email (hash or mask), request/response bodies of auth endpoints.

pino: `redact: { paths: ['req.headers.authorization','req.headers.cookie','*.password','*.token'], censor: '[REDACTED]' }`

## Rules

- stdout/stderr only; the platform ships logs. No file logging, no direct-to-
  Elasticsearch from the app.
- One event per line. No multi-line stack traces as separate lines — put the
  stack in an `err.stack` field.
- Sample high-volume info logs if cost matters; never sample errors.
- Log at the boundary (one request-completed line) not at every function.
