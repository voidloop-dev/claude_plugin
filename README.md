# pro-product-builder

A Claude Code **plugin**: a bundle of focused, senior-developer-grade skills for
standing up and shipping professional products (web, mobile, desktop).

Not one mega-skill. Each skill covers one moment in the lifecycle, with concrete
reference files, decision tables, absolute rules, and a verification gate so the
error rate stays low.

## Skills

| Skill | Status | Purpose |
|---|---|---|
| `blueprint` | ✅ built | Full up-front plan for any project: deep system design doc (C4, data model, APIs, NFRs, security, deployment), phased delivery plan ordered by risk, and a fine-grained spec for every module in every phase |
| `repo-bootstrap` | ✅ built | Git/GitHub foundations: `.gitignore`, branch protection, PR template, CODEOWNERS, LICENSE, secret guardrails, README skeleton |
| `cicd-setup` | ✅ built | GitHub Actions per stack: lint + test + build, `gitleaks` gate, deploy workflows, wire status checks into branch protection |
| `project-docs` | ✅ built | Fixed templates + update rules for `PROGRESS.md`, `ARCHITECTURE.md`, `MODULES.md`; kept current after each change |
| `dev-workflow` | ✅ built | Ordered clarify → design → slice → self-review → test → docs checklist |
| `ui-scaffold` | ✅ built | Stack-specific UI setup (tokens, theming, a11y); defers visual design to the built-in `design` / `artifact-design` skills |

## Design principles (why this is reliable)

1. **Reference files, not advice** — skills copy from known-good artifacts.
2. **Verification gates** — nothing is "done" until its check command passes.
3. **Decision tables** — remove judgement calls where a lookup works.
4. **Absolute never/always rules** — each with its one-line reason.
5. **Narrow scope + sharp description** — the skill triggers at the right moment only.
6. **A worked example** in every `SKILL.md`.

## Install

```
/plugin marketplace add voidloop-dev/claude_plugin
/plugin install pro-product-builder@pro-product-builder-marketplace
```

Or point Claude Code at a local clone via `.claude/settings.json`
`extraKnownMarketplaces`.

## Layout

```
skill_made_by_claude/
  .claude-plugin/
    plugin.json
    marketplace.json
  skills/
    repo-bootstrap/
      SKILL.md
      references/
        gitignore/   # per-stack .gitignore bases
        github/      # PR template, CODEOWNERS, branch-protection.json, hooks, ...
  STATUS.md          # build progress for this plugin itself
```
