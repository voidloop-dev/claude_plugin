# Requirements — {{PROJECT}}

_Status: Draft | Confirmed by {{user}} on {{DATE}}_

## Problem & users

- **Problem:** {{what pain, for whom}}
- **Primary users:** {{persona — context, goals}}
- **Secondary users / operators:** {{admins, support, ...}}
- **Success looks like:** {{observable outcome, ideally a metric}}

## Functional scope (v1)

Each item is a user goal, not a feature name.

| # | Capability | Notes |
|---|---|---|
| F1 | {{As a student I can post a question to my group}} | |
| F2 | {{...}} | |

## Non-goals (explicitly out for v1)

- {{real-time chat}}
- {{native mobile apps}}

## Non-functional targets (concrete numbers)

| Attribute | Target | Source / reasoning |
|---|---|---|
| Scale — users | {{2,000 active first term}} | |
| Scale — throughput | {{≤ 300 RPS peak}} | |
| Scale — data volume | {{~50k rows/yr}} | |
| Latency | {{p95 < 400 ms server}} | |
| Availability | {{99.5% monthly}} | |
| Security / authN | {{email + password, sessions}} | |
| Privacy / compliance | {{GDPR: export + delete my data; PII = name, email}} | |
| Accessibility | {{WCAG 2.1 AA}} | |
| Platforms | {{mobile-first web + installable PWA; last 2 browser versions}} | |
| Offline | {{read-only cached view}} | |
| Budget | {{< $30 / month infra}} | |
| Team | {{1 developer, TS/React}} | |
| Deadline | {{MVP by {{DATE}}}} | |

## Constraints

- {{must integrate with existing SSO}} / {{mandated cloud}} / {{license limits}}

## Assumptions

- {{traffic is business-hours, single region is fine}}

## Open questions (block design until answered)

- [ ] {{question}} — needed because {{which decision it changes}}
