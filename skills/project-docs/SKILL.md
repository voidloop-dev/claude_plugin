---
name: project-docs
description: >-
  Create and maintain a project's living documentation to a professional standard:
  README, PROGRESS.md (status + changelog), ARCHITECTURE.md (system design, data
  flow, decisions), MODULES.md (per-module ownership and contracts), and an ADR
  log. Use when starting a project, when docs are missing/stale, or after any
  change that alters behavior, architecture, or module boundaries. These are
  fixed templates that get UPDATED, not free-form prose.
---

# project-docs

Keep a small, fixed set of documents that always reflect reality. A reader (or a
future Claude session) should get the true state of the project from these files
without reading all the code.

## The document set

| File | Answers | Update trigger |
|---|---|---|
| `README.md` | What is this, how do I run it | Setup/scripts/stack change |
| `docs/PROGRESS.md` | What works, what's in flight, what's next, what changed | **Every** behavior change or completed task |
| `docs/ARCHITECTURE.md` | How the system is shaped, how data flows, why | Any structural change |
| `docs/MODULES.md` | What each module does, its public contract, who owns it | New module, moved boundary, changed contract |
| `docs/adr/NNNN-*.md` | Why we chose X over Y (immutable once accepted) | A decision with lasting consequences |

Do not invent extra docs. Do not let these drift.

## Absolute rules

| Rule | Why |
|---|---|
| Update `PROGRESS.md` in the SAME change that alters behavior — never "later". | Stale status is worse than none; people trust it. |
| ADRs are append-only. To reverse a decision, write a new ADR that supersedes the old one; don't edit the old one. | The reasoning history is the point. |
| `ARCHITECTURE.md` describes what IS, not aspirations. Future plans go under an explicit "Planned" heading. | Prevents docs from lying about the current system. |
| Every diagram is text (Mermaid) so it lives in git and diffs. | Binary diagrams rot silently. |
| Keep each file scannable — headings, tables, short paragraphs. If a section exceeds ~1 screen, it needs subheadings. | Docs no one can scan are docs no one reads. |
| Dates are absolute (`2026-09-02`), never "today"/"last week". | The file outlives the context it was written in. |

## Procedure

### Starting fresh

1. Create `docs/` and copy all templates from `references/`.
2. Fill `README.md`: title, one-line pitch, Quick start (exact commands),
   Scripts table, Tech stack, License.
3. Fill `ARCHITECTURE.md` from what exists: components, a Mermaid flow diagram,
   data stores, external services, key constraints.
4. Seed `MODULES.md` with one row per top-level module/package/route group.
5. `PROGRESS.md`: set "Current status" and list the first milestones.
6. Write ADR-0001 recording the initial stack choice.

### On every subsequent change (this is the habit)

After completing any task that changes behavior, before considering it done:

1. `PROGRESS.md`:
   - Move the item from "In progress" / "Next" to "Changelog" with today's date.
   - Update "Current status" if the headline state changed.
   - Add any new follow-ups to "Next".
2. If a module was added or its public contract changed → update `MODULES.md`.
3. If the system shape/data flow changed → update `ARCHITECTURE.md` (incl. the
   Mermaid diagram).
4. If a lasting decision was made → new ADR.
5. If setup/scripts changed → `README.md`.

### Reviewing staleness

Run the checklist in the verification gate. Any "no" → fix before proceeding.

## Verification gate

1. Every `docs/` file exists and has no `{{PLACEHOLDER}}` left.
2. `PROGRESS.md` "Changelog" newest entry date is within this working session if
   any behavior changed this session.
3. `ARCHITECTURE.md` Mermaid block renders (no syntax error) and its component
   list matches the actual top-level code layout.
4. `MODULES.md` row count matches the number of real modules (±0).
5. Every accepted ADR has status `Accepted` or `Superseded by NNNN`, never blank.
6. README Quick start commands actually run on a clean checkout.

Report pass/fail per item.

## Worked example

Task just finished: "added CSV export endpoint".

- `PROGRESS.md`: Changelog gets `- 2026-09-02 — CSV export endpoint
  (`GET /api/export.csv`) shipped`. "Current status" unchanged. "Next" gains
  "rate-limit the export endpoint".
- `MODULES.md`: `api/export` row's contract updated to list the new route.
- `ARCHITECTURE.md`: data-flow diagram gains `Report page --> Export API -->
  DB (read replica)` edge.
- No ADR (routine feature).
- README unchanged.
- Gate: 6/6.
