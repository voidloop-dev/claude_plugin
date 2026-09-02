# Architecture

_Describes the system as it IS on {{DATE}}. Aspirations go under "Planned"._

## Overview

{{2–4 sentences: what the system does and its top-level shape.}}

## Components

| Component | Responsibility | Tech | Location |
|---|---|---|---|
| {{Web app}} | {{UI + SSR}} | {{Next.js}} | `apps/web` |
| {{API}} | {{business logic}} | {{...}} | `apps/api` |
| {{Worker}} | {{async jobs}} | {{...}} | `apps/worker` |

## Data flow

```mermaid
flowchart LR
  User -->|HTTPS| Web
  Web -->|REST| API
  API --> DB[(Postgres)]
  API --> Cache[(Redis)]
  API -->|enqueue| Queue[(Queue)]
  Queue --> Worker
  Worker --> DB
```

## Data stores

| Store | Purpose | Notes |
|---|---|---|
| {{Postgres}} | {{primary data}} | {{migrations in `db/migrations`}} |

## External services

| Service | Used for | Failure mode |
|---|---|---|
| {{Stripe}} | {{billing}} | {{degrade to read-only}} |

## Key constraints & decisions

- {{constraint}} — see ADR-{{NNNN}}

## Planned (not yet built)

- {{future component / change}}
