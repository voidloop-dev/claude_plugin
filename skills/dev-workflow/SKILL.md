---
name: dev-workflow
description: >-
  The ordered senior-developer workflow for taking a feature or product from idea
  to merged, tested code: clarify requirements, design, break down, implement in
  reviewable slices, self-review, test, and update docs. Use when the user asks to
  "build" / "add" / "implement" a feature or a whole product and hasn't already
  been given a plan. Keeps work scoped, reviewable, and verified rather than a
  large unreviewed dump.
---

# dev-workflow

Follow this sequence for any non-trivial build. Each phase has an exit condition;
do not enter the next phase until the current one is met. The point is to catch
mistakes early (in requirements and design) where they are cheap.

## When this applies

- "Build / add / implement / create <feature or product>".
- A task large enough to need more than one commit.
- Skip for: one-line fixes, pure refactors with tests already green, answering
  questions.

Pair with: `repo-bootstrap` (first, if no repo), `project-docs` (updates at the
end of each cycle), `cicd-setup` (so the gate exists).

## Absolute rules

| Rule | Why |
|---|---|
| Do not write implementation code until requirements are confirmed and a design is stated. | Reworking wrong code costs 10x reworking a wrong sentence. |
| One branch, one concern. If mid-work you find an unrelated problem, note it — don't fix it here. | Keeps PRs reviewable and revertable. |
| Every slice ends green: it builds, lint passes, tests pass. Never leave the tree broken between slices. | A broken intermediate state hides new breakage. |
| Write or update tests in the same slice as the code they cover. | "Tests later" means "tests never" and untested edges ship. |
| Self-review the diff as if it were someone else's before asking for review. | The author catches ~half their own bugs on a deliberate second pass. |
| Surface assumptions and trade-offs explicitly to the user at the design phase. | The user owns product decisions; you own execution. |

## The sequence

### 1. Clarify — exit: requirements confirmed by the user

- Restate the goal in your own words.
- List explicit acceptance criteria (what "done" looks like, observable).
- List what is **out of scope** for this piece.
- Ask only the questions whose answers change the design. Batch them.
- Note constraints: perf, security, compatibility, deadlines.

### 2. Design — exit: user agrees with the approach

- Identify affected modules (`MODULES.md`) and whether boundaries move.
- Describe the approach: data model changes, new interfaces, control flow.
- Call out 1–2 alternatives and why you rejected them.
- Flag risks and the migration/rollback story.
- If the decision is lasting → an ADR (`project-docs`).

### 3. Break down — exit: a slice list

- Split into slices that are each independently mergeable and reviewable
  (roughly < ~300 changed lines, each leaving the tree green).
- Order them so the riskiest / most foundational is first.
- Identify the test for each slice.

### 4. Implement — per slice

1. Write the slice, matching surrounding code style.
2. Add/update its tests.
3. Run lint + typecheck + tests locally. Green or fix before continuing.
4. Commit with a Conventional Commit message.

### 5. Self-review — exit: you'd approve this PR

Walk the full diff and check:
- Does it do exactly what the requirements said — no more, no less?
- Edge cases: empty, null, huge, concurrent, unauthorized, network failure.
- Errors handled and surfaced, not swallowed.
- No secrets, no debug logging, no commented-out code, no TODOs without an issue.
- Names and comments match the code's actual behavior.
- Tests actually fail if you break the code (mutate one line and check).

### 6. Verify — exit: the gate is green

- Full test suite passes.
- The app runs and the feature works end to end (use the `run` skill).
- CI checks pass on the PR.

### 7. Wrap up

- Update `PROGRESS.md`, and `MODULES.md` / `ARCHITECTURE.md` if they changed
  (`project-docs`).
- Open the PR with the template filled in; link the issue.
- List any follow-ups you deferred.

## Verification gate

1. Requirements + out-of-scope were written and confirmed.
2. Design was stated with alternatives before code.
3. Work landed as ordered slices, each green.
4. Tests added/updated in the same slices; suite green.
5. A documented self-review pass happened.
6. Feature verified running end to end.
7. Docs updated; PR opened with template.

Report pass/fail per item; name any deferred follow-ups.

## Worked example

"Add CSV export to the reports page."

1. **Clarify:** criteria = button on `/reports`, downloads `report.csv` with the
   currently filtered rows, ≤ 50k rows, auth required. Out of scope: XLSX,
   scheduled exports, email delivery.
2. **Design:** new `GET /api/export.csv` streaming response reusing the existing
   `buildReportQuery()`; rejected client-side generation (memory) and a new
   worker job (overkill at 50k). Risk: large query on primary → use read replica.
3. **Slices:** (a) `buildReportQuery` accepts a stream sink + test; (b) API route
   + auth + test; (c) UI button + loading state + test.
4. **Implement:** three commits, each green.
5. **Self-review:** found unescaped commas in a name field → fixed + test.
6. **Verify:** suite green, exported a 40k-row file locally, CI green.
7. **Wrap up:** `PROGRESS.md` changelog + "Next: rate-limit export"; PR opened.
