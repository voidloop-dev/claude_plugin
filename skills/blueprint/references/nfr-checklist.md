# Non-functional requirement checklist

Force a concrete target + a mechanism for each. "Later" / "we'll see" is not an
answer at design time — these shape the architecture.

| NFR | Ask | Design must state |
|---|---|---|
| Performance | Expected RPS, data volume, p95/p99 latency budget per key operation | bottlenecks, caching, indexing, async, pooling |
| Scalability | Growth over 12 months; burst pattern | scale-out path, statelessness, partitioning trigger |
| Availability | Uptime target; acceptable downtime/mo; maintenance windows | redundancy, health checks, graceful degradation |
| Reliability | RPO / RTO; data-loss tolerance | backups + tested restore, retries, idempotency, DLQ |
| Disaster recovery | Region loss survivable? | replica/region strategy, runbook |
| Security | Auth model, roles, threat surface, secrets, compliance regime | authN/authZ, encryption in transit/at rest, threat list + mitigations, supply-chain |
| Privacy | PII inventory; retention; deletion/export rights | data map, retention policy, GDPR/CCPA endpoints |
| Observability | What must be visible; who gets paged | logs schema, metrics list, traces, dashboards, alert thresholds |
| Accessibility | Target standard (WCAG level); assistive tech | baseline (see ui-scaffold), automated + manual checks |
| Internationalisation | Languages, locales, RTL, currencies, timezones | copy externalised, locale-aware formatting, storage in UTC |
| Portability / lock-in | Acceptable vendor lock-in | abstraction seams, IaC, data export |
| Cost | Monthly ceiling; per-unit economics | cost table at target scale, main drivers, caps/alerts |
| Maintainability | Team size & skills; bus factor | stack familiarity, docs, module size, test strategy |
| Compliance / legal | SOC2, HIPAA, PCI, GDPR, age gates | controls mapped to requirements, audit logging |
| Usability | Key task success rate / time | primary flows designed, error recovery |
