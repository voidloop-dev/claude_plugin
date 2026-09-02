# Zero-downtime schema changes: expand / contract

The previous app version must keep working against the new schema. Split every
breaking change across releases.

## The pattern

| Phase | Release | Schema change | App change |
|---|---|---|---|
| Expand | N | Add new column/table/index (nullable, default, `CREATE INDEX CONCURRENTLY`) | Write to both old & new; read old |
| Migrate | N (or background job) | Backfill new column from old | — |
| Transition | N+1 | — | Read new; still write both |
| Contract | N+2 | Drop old column/constraint | Write new only |

Each release is independently rollback-safe because the schema is a superset of
what any live code needs.

## Rules

- Migrations run as a **separate pipeline step before** the app rollout, never
  from app boot.
- Additive only in the release that adds the feature. Destructive changes wait
  until the code that used the old shape is fully gone (usually 1–2 releases).
- Renames = add new + backfill + switch + drop. Never `ALTER ... RENAME` in place.
- Postgres: `CREATE INDEX CONCURRENTLY`, `ADD COLUMN ... NULL` (no table rewrite),
  add `NOT NULL` via `CHECK ... NOT VALID` then `VALIDATE CONSTRAINT`.
- Long backfills: batch with sleeps, run out-of-band, make idempotent & resumable.
- Every migration has a tested `down` (or a documented forward-fix if truly
  irreversible).
- Guard with a migration linter in CI (e.g. `squawk`, `atlas migrate lint`).

## Example — rename `users.name` → `users.full_name`

1. R-N: `ADD COLUMN full_name text`; app writes both, reads `name`.
2. Backfill: `UPDATE users SET full_name = name WHERE full_name IS NULL` (batched).
3. R-N+1: app reads `full_name`, still writes both.
4. R-N+2: `ALTER TABLE users DROP COLUMN name`; app writes `full_name` only.
