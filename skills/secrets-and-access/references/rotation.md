# Secret rotation

## Principles

- Every secret has an interval (30/60/90/180 d by blast radius). Track in the
  inventory; alert when `now - last_rotated > interval`.
- Rotation must be **zero-downtime**: two credentials valid during an overlap
  window.
- Automate where the provider supports it (AWS RDS/Secrets Manager rotation
  Lambdas, GCP, Vault dynamic secrets). Calendar + runbook for the rest.

## Dual-key overlap procedure (manual secret)

1. Create secret **v2** at the provider (don't delete v1).
2. Add v2 to the secret manager as the new value; keep v1 readable as
   `<name>_previous` if the app supports verifying both.
3. Deploy so all instances accept **both** v1 and v2 (verify), and sign/send
   with v2.
4. Wait past the max token lifetime / cache TTL / in-flight window.
5. Revoke v1 at the provider.
6. Remove `<name>_previous`. Update `last_rotated` in the inventory.

## Examples

- **JWT signing key**: keep a small keyring (`kid` header); verify against all
  keys in the ring, sign with the newest; drop old keys after `max session age`.
- **DB password**: use two DB users (`app_a`, `app_b`); rotate the inactive
  one's password, switch `DATABASE_URL`, then rotate the other.
- **Third-party API key** (Stripe/Resend): create new restricted key, deploy,
  confirm traffic on the new key in their dashboard, delete the old key.

## Dynamic secrets (best when available)

Vault / cloud brokers issue short-TTL credentials per workload on demand — no
rotation needed because nothing is long-lived. Prefer this for DB and cloud
access.
