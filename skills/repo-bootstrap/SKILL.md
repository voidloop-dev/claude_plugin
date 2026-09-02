---
name: repo-bootstrap
description: >-
  Set up a Git/GitHub repository to a professional standard: .gitignore, branch
  protection, PR template, CODEOWNERS, LICENSE, security guardrails, and a README
  skeleton. Use at the START of a project, or when an existing repo is missing
  these foundations (no branch protection, secrets committed, no PR template).
  Not for CI/CD pipelines (see cicd-setup) or writing project docs (see project-docs).
---

# repo-bootstrap

Bring a repository up to the baseline a senior engineer would expect before the
first feature branch: history is clean, secrets cannot be committed, `main` is
protected, and contribution rules are explicit.

## When this applies

Trigger when ANY of these is true:

- A new repo was just `git init`'d or `gh repo create`'d.
- `git log` shows an initial commit but there is no `.gitignore`, no
  `.github/` directory, or no `LICENSE`.
- The user asks to "set up the repo properly", "add guardrails", "make it
  professional", "protect main", or similar.
- A review finds committed secrets, a missing `.gitignore`, or an unprotected
  default branch.

Do NOT trigger for: pipeline/workflow authoring (`cicd-setup`), status/architecture
markdown (`project-docs`), or day-to-day feature work.

## Absolute rules

| Rule | Why |
|---|---|
| Never `git push --force` / `--force-with-lease` to the default branch. | Rewrites shared history; unrecoverable for collaborators. |
| Never commit `.env`, `*.pem`, `*.key`, `id_rsa`, cloud credential files, or `secrets.*`. | Public leak is permanent even after deletion; keys must be rotated. |
| Always create a branch before the first non-trivial commit; never develop on `main`. | Keeps `main` deployable and reviewable. |
| Never disable branch protection to merge; fix the failing check instead. | Protection only works if it is never bypassed. |
| Never run destructive git ops (`reset --hard`, `clean -fdx`, `branch -D`) without showing the user what will be lost first. | These discard uncommitted work silently. |
| If a secret was already committed, STOP and tell the user it must be rotated + history purged — do not just delete the file in a new commit. | The secret stays in history and is still compromised. |

## Procedure

Work top to bottom. After each step, run its check before moving on.

### 1. Assess

```
git status --porcelain          # uncommitted work?
git log --oneline -5            # history state
git remote -v                   # GitHub remote present?
gh auth status                  # gh CLI authenticated?
ls -a                          # existing .gitignore / .github / LICENSE?
```

Scan tracked files for already-committed secrets:

```
git ls-files | grep -iE '(^|/)(\.env|secrets?|credentials?)(\..*)?$|\.(pem|key|p12|pfx)$|id_rsa'
```

If that returns anything → apply the "secret already committed" rule above and stop for user direction.

### 2. Detect the stack

Pick the `.gitignore` base from `references/gitignore/` using this table. Combine
bases when a repo is polyglot (e.g. web + mobile).

| Signal file / dir | Stack | gitignore base |
|---|---|---|
| `package.json`, `node_modules/` | Node / JS / TS | `node.gitignore` |
| `next.config.*`, `.next/` | Next.js (adds to Node) | `node.gitignore` + `next.gitignore` |
| `pyproject.toml`, `requirements.txt`, `*.py` | Python | `python.gitignore` |
| `pubspec.yaml` | Flutter / Dart | `flutter.gitignore` |
| `Cargo.toml` | Rust | `rust.gitignore` |
| `go.mod` | Go | `go.gitignore` |
| `*.xcodeproj`, `Podfile` | iOS / macOS native | `apple.gitignore` |
| `build.gradle`, `settings.gradle` | Android / JVM | `android.gitignore` |
| Electron / Tauri in `package.json` | Desktop | `node.gitignore` + `desktop.gitignore` |
| always | universal | `common.gitignore` (OS files, editors, `.env*`, logs) |

Always append `common.gitignore`. Merge, de-duplicate, keep sections labelled with
`# ---- <source> ----` headers so it stays auditable.

Check: `git check-ignore -v .env node_modules dist` (adjust per stack) prints a
matching rule for each.

### 3. Foundational files

Create from `references/github/`, substituting `{{PLACEHOLDERS}}`:

- `.github/pull_request_template.md`
- `.github/CODEOWNERS` — ask the user for the GitHub handle(s) that own the repo;
  default `* @{{OWNER}}`.
- `.github/ISSUE_TEMPLATE/bug_report.md` and `feature_request.md`
- `.github/dependabot.yml` — package-ecosystem set from the detected stack.
- `SECURITY.md` — how to report a vulnerability (private advisory link).
- `LICENSE` — ask which one. Default MIT for apps, Apache-2.0 if the user wants an
  explicit patent grant. Fill year `2026` and holder name.
- `CONTRIBUTING.md` — branch naming (`type/short-desc`), commit style
  (Conventional Commits), "open a PR, never push to main", how to run tests.
- `README.md` — only a skeleton (title, one-line pitch, Quick start, Scripts,
  License). Full content is `project-docs`' job; do not duplicate.

Check: every file exists and has no unresolved `{{` placeholder:
`grep -rn '{{' .github README.md LICENSE SECURITY.md CONTRIBUTING.md` returns nothing.

### 4. Secret-leak prevention

- Add a `.env.example` with keys but blank values, tracked.
- Install a pre-commit guard. If the project already uses `pre-commit`
  (`.pre-commit-config.yaml`) add the `detect-secrets` or `gitleaks` hook there;
  otherwise write `.githooks/pre-commit` (see `references/github/pre-commit.sh`)
  and set `git config core.hooksPath .githooks`.
- Tell the user the hook is local-only and CI must also gate (that is
  `cicd-setup`'s `gitleaks` job).

Check: `printf 'AWS_SECRET_ACCESS_KEY=AKIA...\n' > /tmp/x.env` staged in a scratch
copy is rejected by the hook. (Explain rather than run if risky.)

### 5. First commit / branch hygiene

If history is empty or only scaffolding:

```
git add -A
git commit -m "chore: repository foundations (gitignore, guardrails, templates)"
git branch -M main
git push -u origin main        # only if remote exists and user confirms
```

Then create the working branch: `git switch -c <type>/<desc>`.

### 6. Branch protection (needs `gh` + push access + remote)

Get `OWNER/REPO` from `gh repo view --json nameWithOwner -q .nameWithOwner`.

```
gh api -X PUT repos/{OWNER}/{REPO}/branches/main/protection \
  --input references/github/branch-protection.json
```

`branch-protection.json` requires: PR before merge, 1 approving review, dismiss
stale reviews, conversation resolution, linear history, no force-push, no
deletion. Status-check contexts are left empty here and filled by `cicd-setup`
once workflows exist.

Also enable repo-level guardrails:

```
gh api -X PATCH repos/{OWNER}/{REPO} \
  -f delete_branch_on_merge=true -f allow_squash_merge=true \
  -f allow_merge_commit=false -f allow_rebase_merge=false
gh api -X PUT repos/{OWNER}/{REPO}/vulnerability-alerts
gh api -X PUT repos/{OWNER}/{REPO}/automated-security-fixes
```

Check: `gh api repos/{OWNER}/{REPO}/branches/main/protection` returns 200 and
`required_pull_request_reviews.required_approving_review_count` is 1.

### 7. Report

Give the user a checklist of what was done and what still needs a human:

- [ ] Confirm CODEOWNERS handles are correct
- [ ] Add teammates as collaborators
- [ ] Run `cicd-setup` so status checks can be added to branch protection
- [ ] If solo, decide whether to keep "1 approving review" (can self-approve via
      a second account, or relax to 0 but keep "PR required")

## Verification gate (must all pass)

1. `git check-ignore -v` matches for every stack artifact dir + `.env`.
2. No secrets in `git ls-files`.
3. `.github/pull_request_template.md`, `CODEOWNERS`, `LICENSE`, `SECURITY.md`,
   `CONTRIBUTING.md` all present, no `{{` left.
4. Pre-commit secret hook installed and rejects a fake AWS key.
5. `gh api .../branches/main/protection` → 200 with review requirement.
6. `delete_branch_on_merge=true`, Dependabot alerts on.
7. Working branch checked out, `main` untouched by feature work.

Report each as pass/fail with the command output. Do not claim "done" with any
item unchecked.

## Worked example

New Next.js + Supabase app, fresh `gh repo create acme/dashboard --private`.

1. Assess: empty history, remote present, `gh` authed, no `.gitignore`.
2. Detect: `package.json` + `next.config.js` → `node` + `next` + `common`.
3. Files: PR template, `CODEOWNERS` = `* @acme-lead`, MIT LICENSE (2026, "Acme
   Inc."), `SECURITY.md`, `CONTRIBUTING.md`, README skeleton, `.env.example` with
   `NEXT_PUBLIC_SUPABASE_URL=` / `SUPABASE_SERVICE_ROLE_KEY=`.
4. `.githooks/pre-commit` + `git config core.hooksPath .githooks`.
5. `git commit -m "chore: repository foundations…"`, push, `git switch -c
   feat/auth-flow`.
6. `gh api -X PUT …/branches/main/protection --input branch-protection.json`;
   `delete_branch_on_merge=true`; vulnerability alerts on.
7. Report: 7/7 gate passed; human TODO = add collaborators, run `cicd-setup`.
