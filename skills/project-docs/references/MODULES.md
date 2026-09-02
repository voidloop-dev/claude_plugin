# Modules

_One row per module. "Public contract" = what other modules may depend on._

| Module | Path | Responsibility | Public contract | Depends on | Owner |
|---|---|---|---|---|---|
| {{auth}} | `src/auth` | {{sessions, login, RBAC}} | {{`getSession()`, `requireRole()`}} | {{db}} | {{@handle}} |
| {{billing}} | `src/billing` | {{subscriptions, invoices}} | {{`createCheckout()`, webhook handler}} | {{auth, db, stripe}} | {{@handle}} |

## Boundary rules

- {{e.g. "UI never imports from `db` directly — always through a module's contract."}}
- {{e.g. "`billing` may not import `auth` internals, only its public contract."}}

## Adding a module

1. Add a row above.
2. Define its public contract as a single entry file (`index.ts` / `__init__.py`).
3. Update `ARCHITECTURE.md` if it changes the data flow.
