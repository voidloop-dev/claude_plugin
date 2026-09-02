# Feature flags

Deploy != release. Ship code dark, flip the flag separately, use the flag as a
kill switch.

## Rules

- **Default off.** New code path is inert until explicitly enabled.
- **Typed, not stringly.** `flags.newCheckout` is a boolean/enum in code, not a
  magic string scattered around.
- **Owner + expiry** per flag, recorded where flags are defined. A flag with no
  removal date is tech debt from birth.
- **Kill-switch semantics.** Turning a flag off must fully disable the feature
  with no deploy and no restart (poll/stream flag changes).
- **Short-lived by default.** Release flags: remove within ~2 sprints of 100%.
  Long-lived only for genuine ops toggles / entitlements.
- **No nesting.** Don't gate a flag behind another flag.
- **Test both states.** CI runs the suite with the new flag on and off.
- **Clean up.** A recurring task deletes flags past expiry; the code path becomes
  unconditional.

## Categories

| Type | Lifetime | Example |
|---|---|---|
| Release toggle | days–weeks | `newDigestEmail` |
| Ops / kill switch | permanent | `disableSignups`, `readOnlyMode` |
| Experiment | length of the test | `checkoutVariantB` |
| Entitlement / permission | permanent | `plan.enterpriseReports` |

## Implementation

- Standard: **OpenFeature** SDK + a provider (flagd, LaunchDarkly, Unleash,
  GrowthBook, or a config file for tiny projects).
- Minimal: a JSON/YAML in object storage or a `feature_flags` table, polled every
  30–60s, with an in-memory cache and a typed accessor module.
- Evaluate flags server-side where possible; pass resolved values to the client.
