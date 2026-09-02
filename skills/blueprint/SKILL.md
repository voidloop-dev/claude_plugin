---
name: blueprint
description: >-
  Produce the full up-front engineering plan for any project — web app, mobile
  app, desktop app, API, CLI, library, data pipeline — to the standard a software
  company expects before build starts: a detailed system design document
  (context, containers, components, data model, APIs, non-functional
  requirements, security, observability, deployment, trade-offs), a phased
  delivery plan that breaks the whole project into ordered phases, and a
  fine-grained module spec for every module in every phase (what it does, its
  contract, how to build it, its tests, its acceptance criteria). Use when the
  user wants architecture, a system design, a build plan, a phase breakdown, a
  spec, or "how should I structure / build this project". Run before dev-workflow
  (which builds one feature); blueprint plans the whole thing.
---

# blueprint

Turn a project idea into the document set an engineering team would take into a
build: a **System Design Document**, a **Delivery Plan** of ordered phases, and a
**Module Spec** for every module. Depth is the point — someone should be able to
build the project from these files without re-deriving the design.

## When this applies

- "Design the architecture / system for <project>."
- "Break this project into phases / a build plan / a roadmap."
- "Write the spec / system design / technical design doc."
- "How should I structure and build this <app/API/pipeline>?"
- At the start of any project bigger than a single feature.

Relationship to the other skills:
- `blueprint` plans the **whole project** → outputs live in `docs/`.
- `project-docs` keeps `ARCHITECTURE.md` / `PROGRESS.md` / `MODULES.md` current
  *after* build starts (blueprint seeds them).
- `dev-workflow` executes **one phase's one module** at a time.
- `repo-bootstrap` / `cicd-setup` / `ui-scaffold` set up the repo the plan targets.

## Absolute rules

| Rule | Why |
|---|---|
| Do not start the design until you have written requirements the user has confirmed — functional scope, the top non-functional targets (scale, latency, availability, budget, compliance), and explicit non-goals. | Every architectural choice is a response to a requirement. Design without them is guessing. |
| Every architectural decision names the requirement or constraint that forced it, and the alternative rejected. A decision with lasting consequences becomes an ADR. | A design nobody can trace back to a "why" cannot be safely changed later. |
| Phases are ordered by risk and dependency, not by feature priority. The first phase must produce a deployable walking skeleton (thinnest end-to-end slice through every layer). | Integrates the risky seams first, while changing them is cheap; gives a real thing to test from day one. |
| Every phase has a demoable outcome and measurable exit criteria. No phase is "infrastructure only" with nothing to show. | Undemoable phases hide slippage and rarely end. |
| Every module spec is buildable in isolation: it states its inputs, outputs, public contract, data owned, dependencies, and acceptance criteria. Two people reading it build the same thing. | Vague specs are re-litigated during the build, which is the expensive place to do it. |
| Size modules so one is roughly 1–5 days of work. Split anything larger; a "module" that is really a subsystem gets its own set of specs. | Keeps estimates honest and PRs reviewable. |
| The data model is defined before the APIs; the APIs before the UI. Name every entity, its fields, types, and relationships. | Downstream layers are shaped by the ones beneath; doing it top-down forces rework. |
| Non-functional requirements (performance, availability, security, privacy, accessibility, observability, cost) each get an explicit section with a target and how the design meets it — never "we'll handle it later". | These are architecture-shaping. Retrofitting them means a redesign. |
| State assumptions and open questions explicitly in their own section. Do not silently pick for the user on anything that materially changes scope or cost. | The user owns product and budget decisions. |
| Keep every diagram as text (Mermaid). Use the C4 levels: Context → Container → Component. | Diagrams in git diff and never rot into lies. |

## Procedure

### 1. Requirements (exit: user confirms)

Write `docs/REQUIREMENTS.md` from the template:
- **Problem & users** — who, what pain, what success looks like.
- **Functional scope** — capability list, each as a short user-goal statement.
- **Non-goals** — what this project explicitly will not do (v1).
- **Non-functional targets** — concrete numbers: expected users / RPS / data
  volume, p95 latency, availability target, security & compliance (PII? GDPR?
  auth model?), platforms/browsers/devices, offline?, budget ceiling, team size
  & skills, deadline.
- **Constraints** — existing systems, mandated tech, integrations, licensing.
- **Assumptions & open questions.**

Ask only the questions whose answers change the design. Batch them. Wait.

### 2. System Design Document (exit: internally consistent, NFRs each addressed)

Write `docs/SYSTEM_DESIGN.md` from the template. Sections, in order:

1. **Overview** — 3–5 sentences and the headline choices.
2. **Context (C4 L1)** — the system as one box, its users and external systems;
   Mermaid.
3. **Architecture drivers** — the 3–7 requirements/constraints that most shape
   the design, each with its implication.
4. **Solution approach & alternatives** — the chosen architecture style
   (monolith / modular monolith / services / serverless / client-only …) and
   1–2 rejected options with why. Style choice must cite drivers.
5. **Containers (C4 L2)** — each deployable/runnable unit: responsibility, tech,
   how it scales, how it talks to the others (protocol, sync/async); Mermaid.
6. **Components (C4 L3)** — inside each container, the major internal parts and
   their responsibilities; Mermaid per container.
7. **Data model** — every entity: fields + types, keys, relationships (Mermaid
   ER diagram), ownership, retention, migration approach. Note read/write
   patterns and indexing for the hot paths.
8. **API design** — style (REST/GraphQL/RPC/events), auth, versioning, error
   model, pagination, idempotency. List the key endpoints/operations with
   request/response shape. Include external webhooks/events.
9. **Key flows** — 2–4 critical end-to-end scenarios as sequence diagrams
   (Mermaid), including the failure paths.
10. **Cross-cutting / NFR sections** — one subsection each, with a target and the
    mechanism:
    - Security & privacy — authN/authZ model, secrets, data protection,
      threat list + mitigations, dependency & supply-chain posture.
    - Performance & scalability — bottlenecks, caching, async, load strategy.
    - Reliability & availability — failure modes, redundancy, backups, DR,
      degradation behavior.
    - Observability — logs, metrics, traces, the specific dashboards & alerts.
    - Accessibility & i18n (if there's a UI).
    - Cost — estimated monthly infra cost at the stated scale, main cost drivers.
11. **Deployment & environments** — environments, infra (IaC?), CI/CD gates,
    release strategy (blue-green / canary / rolling), rollback.
12. **Tech stack** — table: layer → choice → why (tie to drivers) → maturity/risk.
13. **Risks & mitigations** — ranked table.
14. **Decision log** — links to `docs/adr/`; write ADRs for the load-bearing calls.
15. **Glossary.**

Before leaving this step: walk every NFR target from REQUIREMENTS and confirm a
section addresses it. Walk every architectural choice and confirm it names a driver.

### 3. Delivery Plan (exit: phases ordered by risk, each demoable)

Write `docs/DELIVERY_PLAN.md` from the template:
- **Phase 0 — Walking skeleton**: thinnest slice touching every container/layer,
  deployed to a real environment, with CI green. No real features.
- **Phase 1..N**: each with — goal (one sentence), scope (module list),
  out-of-scope, dependencies on prior phases, demoable outcome, measurable exit
  criteria, rough estimate (module-days summed), risks.
- Order by: dependency first, then risk (unknowns early), then value.
- A **phase dependency diagram** (Mermaid).
- A **traceability table**: each functional requirement → the phase that delivers it.

### 4. Module Specs (exit: every module in every phase has one)

For each module listed in any phase, create
`docs/modules/<phase>-<module-slug>.md` from the template:
- **Purpose** — one paragraph: what it does and why it exists.
- **Responsibilities / Not responsibilities** — bullet lists.
- **Public contract** — the exact interface other modules use: function
  signatures / endpoints / events / CLI, with types. This is the promise.
- **Internal design** — key classes/functions/files, algorithm notes, state.
- **Data owned** — tables/collections/files this module is the source of truth for.
- **Dependencies** — other modules (by contract), libraries, services.
- **Build steps** — an ordered, concrete checklist to implement it
  (scaffold → data layer → logic → interface → wire-in), each step small.
- **Test plan** — unit cases (list the important ones incl. edge/failure),
  integration points, and how to verify manually.
- **Acceptance criteria** — observable pass/fail statements. "Done" = all true.
- **Estimate** — days, and the biggest unknown.

### 5. Seed the living docs

- Copy the SYSTEM_DESIGN component list into `docs/ARCHITECTURE.md` (project-docs).
- Populate `docs/MODULES.md` rows from the module specs.
- Set `docs/PROGRESS.md` milestones = the phases.
- Hand off: build starts with Phase 0, one module at a time, via `dev-workflow`.

## Verification gate

1. `docs/REQUIREMENTS.md` exists, was confirmed by the user, and states concrete
   NFR numbers (not "fast", "scalable").
2. `docs/SYSTEM_DESIGN.md` has all 15 sections; no `{{PLACEHOLDER}}` remains.
3. Every NFR target in REQUIREMENTS is addressed by a named section in
   SYSTEM_DESIGN.
4. Every tech-stack row and architecture-style choice cites a driver.
5. All Mermaid blocks parse (context, ≥1 container, components, ER, ≥2 sequence,
   phase-dependency).
6. `docs/DELIVERY_PLAN.md`: Phase 0 is a deployable walking skeleton; every phase
   has demoable outcome + measurable exit criteria + estimate.
7. Traceability table covers 100% of functional scope items.
8. Every module named in any phase has a spec file under `docs/modules/`.
9. Every module spec has a public contract with types, build steps, a test plan,
   and observable acceptance criteria; estimate ≤ 5 days or the module is split.
10. `ARCHITECTURE.md`, `MODULES.md`, `PROGRESS.md` seeded from the above.
11. ADRs written for the load-bearing decisions; each has a status.

Report pass/fail per item. Any fail → fix before calling the blueprint done.

## Worked example (compressed)

Project: "Peer study-group app — students post questions, others answer, upvotes,
weekly digest email." Solo dev, ~2k users first term, budget < $30/mo, needs
mobile web + PWA, PII = names + emails.

1. **REQUIREMENTS.md** — scope: auth, groups, Q&A threads, voting, notifications,
   weekly digest. Non-goals: real-time chat, video, native apps. NFR: ≤300 RPS
   peak, p95 < 400ms, 99.5% uptime, GDPR delete-my-data, WCAG AA, $30/mo.
2. **SYSTEM_DESIGN.md** — drivers: tiny budget + solo dev + modest scale →
   *modular monolith* (Next.js app + Postgres + a cron worker), rejected
   microservices (ops overhead) and BaaS-only (lock-in, digest job awkward).
   Containers: Web/API (Next.js on a small VPS), Postgres (managed, $7 tier),
   Worker (same host, node-cron) for the digest. Data model: User, Group,
   Membership, Question, Answer, Vote, Notification — ER diagram. API: REST,
   cookie-session auth, cursor pagination, RFC-7807 errors. Flows: post-answer +
   notify (sequence, incl. email-send failure → retry queue); weekly-digest job.
   NFR sections: rate-limit + input validation + Argon2; index on
   `question(group_id, created_at)`; nightly `pg_dump` to object storage;
   pino logs + a /metrics endpoint + uptime alert; a11y baseline from ui-scaffold;
   cost table ≈ $16/mo.
3. **DELIVERY_PLAN.md** — Phase 0: skeleton (sign in, empty group page, deployed,
   CI green). P1 Groups & membership. P2 Q&A threads. P3 Voting + ranking.
   P4 Notifications. P5 Weekly digest + GDPR export/delete. Dependency diagram;
   traceability table maps all 6 scope items to phases.
4. **Module specs** — e.g. `docs/modules/p2-qa-threads.md`: contract
   `createQuestion(groupId, authorId, {title, body}) -> Question`,
   `listQuestions(groupId, cursor) -> {items, nextCursor}`, REST routes,
   owns `question` + `answer` tables, depends on `auth` + `groups` contracts,
   build steps (migration → repo → service → routes → page), unit cases
   (empty title rejected, non-member cannot post, pagination stable across
   inserts), acceptance criteria, estimate 3d.
5. Seeded ARCHITECTURE/MODULES/PROGRESS; ADR-0001 modular-monolith,
   ADR-0002 Postgres. Gate 11/11.
