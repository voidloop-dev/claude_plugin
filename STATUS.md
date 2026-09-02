# Build status — pro-product-builder plugin

_Last updated: 2026-09-02_

## Current status

All five skills drafted with full `SKILL.md` (rules, procedure, verification gate,
worked example) plus reference files. Plugin is its own independent git repo
(`skill_made_by_claude/`, branch `main`), separate from SabaqAI. Not yet pushed
to GitHub.

## In progress

- [ ] `blueprint` skill on branch `feat/blueprint` (pushed, NOT merged) —
  SYSTEM_DESIGN + DELIVERY_PLAN + per-module MODULE_SPEC + REQUIREMENTS +
  nfr-checklist templates. Awaiting user review before merge.

## Done

- [x] Independent git repo (`git init`), own `.gitignore`
- [x] Parent repo `d:\Hackathon_Project` local-excludes `SabaqAI/` and `skill_made_by_claude/` (`.git/info/exclude`) — no more untracked nagging
- [x] Plugin scaffold: `.claude-plugin/plugin.json`, `marketplace.json`
- [x] `repo-bootstrap` — SKILL.md + 10 gitignore bases + 9 github reference files
- [x] `cicd-setup` — SKILL.md + workflow templates: node/python/flutter/go/rust CI, secret-scan, deploy-vercel/netlify/docker/expo, release-desktop, publish-npm, dependabot-automerge
- [x] `project-docs` — SKILL.md + templates: PROGRESS, ARCHITECTURE, MODULES, README, ADR
- [x] `dev-workflow` — SKILL.md + phase prompt blocks
- [x] `ui-scaffold` — SKILL.md + tokens.css, theme-toggle.tsx, theme.dart, UI.md

## Repo

- Remote: https://github.com/voidloop-dev/claude_plugin
- `main` = baseline (skills + LICENSE), pushed.
- `.github/`: `validate.yml` workflow (JSON/frontmatter/YAML checks), PR template,
  issue templates, CODEOWNERS. `CONTRIBUTING.md` added.

## Next

1. Enable branch protection on `main` in GitHub settings (require PR + `validate` check).
2. Install locally and smoke-test each skill triggers on the right prompt.
3. Optional: `claude plugin eval` suite.
4. Optional: dogfood — run `repo-bootstrap` + `cicd-setup` on this very repo.

## Open questions for the user

- GitHub handle/org for CODEOWNERS defaults?
- Solo or team? (branch protection "1 approving review" vs "PR required only")
- Priority stacks for the hackathon product? (which CI/deploy templates matter first)
- Repo name + public or private?
