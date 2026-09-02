# Break-glass access — {{PROJECT}}

Emergency path past normal least-privilege. Rare, loud, time-boxed, reviewed.

## The role

- `prod-break-glass` — broad prod admin (the powers on-call might need mid-incident).
- **Not** assumable by default. No standing members.
- Grant is temporary: a session of {{60}} minutes, auto-expires.

## How to invoke

1. Requester opens a break-glass request (issue-ops / Slack command / PagerDuty)
   stating: incident link, what access is needed, why normal roles don't suffice.
2. Approval:
   - During a declared SEV1/SEV2: {{one}} other on-call approves (or auto-grant
     with mandatory review).
   - Otherwise: {{two}} approvers, one a lead.
3. On approval, automation grants the role for the time box and:
   - pages the engineering lead + security,
   - posts to `#incidents`,
   - starts a dedicated audit trail.
4. Session auto-revokes at the time box. Extension = a new request.

## During use

- Every action is logged (CloudTrail / audit log), tagged to the incident.
- Prefer the smallest change that restores service; note each change in the
  incident doc as you go.

## After use (mandatory, within {{48}}h)

- [ ] Review every action taken under the role
- [ ] Confirm no persistent backdoors / new users / loosened policies remain
- [ ] Rotate anything exposed
- [ ] Postmortem action: did we need break-glass because a normal role is too
      tight? Adjust if so.
- [ ] File the review; security signs off.

## Test

Exercise this quarterly in a game-day so the automation and approvals actually work.
