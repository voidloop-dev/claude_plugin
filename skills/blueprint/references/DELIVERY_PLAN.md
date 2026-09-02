# Delivery Plan — {{PROJECT}}

_Pairs with docs/SYSTEM_DESIGN.md. Phases are ordered by dependency then risk._
_1 module-day = one developer, one focused day._

## Phase dependency

```mermaid
flowchart LR
  P0[P0 Walking skeleton] --> P1[P1 {{Groups}}]
  P1 --> P2[P2 {{Q&A threads}}]
  P2 --> P3[P3 {{Voting}}]
  P2 --> P4[P4 {{Notifications}}]
  P4 --> P5[P5 {{Digest + GDPR}}]
```

## Traceability — every functional requirement lands in a phase

| Req | Capability | Phase |
|---|---|---|
| F1 | {{post a question}} | P2 |
| F2 | {{...}} | {{Px}} |

_100% of REQUIREMENTS §"Functional scope" rows must appear here._

---

## Phase 0 — Walking skeleton

- **Goal:** thinnest end-to-end slice through every container, deployed, CI green.
- **Scope (modules):**
  - `p0-repo-setup` — repo-bootstrap + cicd-setup + ui-scaffold applied
  - `p0-auth-skeleton` — sign up / sign in / sign out, session cookie
  - `p0-shell` — app layout, one authed empty page
  - `p0-deploy` — staging + production environments, migrations run in pipeline
- **Out of scope:** any real feature, real content.
- **Demoable outcome:** visit the deployed URL, create an account, land on an
  empty dashboard; push to `main` auto-deploys to staging.
- **Exit criteria (measurable):**
  - [ ] CI runs lint+typecheck+test+build+secret-scan on every PR and blocks merge
  - [ ] `main` auto-deploys to staging; tag deploys to production
  - [ ] a new user can sign up, sign in, sign out on the deployed site
  - [ ] one DB migration has run through the pipeline
  - [ ] /metrics and structured logs are live
- **Estimate:** {{5}} module-days · **Risks:** {{deploy/secrets wiring}}

---

## Phase {{N}} — {{name}}

- **Goal:** {{one sentence}}
- **Scope (modules):** `p{{N}}-{{slug}}`, `p{{N}}-{{slug}}` (link to specs)
- **Out of scope:** {{...}}
- **Depends on:** {{Phase N-1 module X's contract}}
- **Demoable outcome:** {{what you can show a stakeholder}}
- **Exit criteria:**
  - [ ] {{observable, testable statement}}
- **Estimate:** {{sum of module estimates}} module-days
- **Risks:** {{...}}

---

## Rollout notes

- Each phase merges behind a feature flag if it touches shared surfaces.
- `PROGRESS.md` milestones == these phases; update on every phase completion.
- Do not start a phase until the prior phase's exit criteria are all checked.
