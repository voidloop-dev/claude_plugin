---
name: cicd-setup
description: >-
  Add professional CI/CD to a repo with GitHub Actions: lint + typecheck + test +
  build on every PR, a secret-scan gate, and deploy workflows per target (Vercel,
  Netlify, Docker/GHCR, npm, Expo/EAS, desktop installers). Then wire the job
  names into branch protection as required status checks. Use after repo-bootstrap,
  or when a repo has no CI, flaky CI, or merges that skip tests. Not for repo
  guardrails themselves (repo-bootstrap) or app code.
---

# cicd-setup

Give the repo an automated gate that a senior engineer would trust: nothing
reaches `main` without passing lint, types, tests, a build, and a secret scan —
and deploys are reproducible from a workflow, not a laptop.

## When this applies

- `repo-bootstrap` just ran and branch protection has empty `contexts`.
- `.github/workflows/` is missing, or only has a stub.
- The user asks for "CI", "pipeline", "GitHub Actions", "auto-deploy", "run tests
  on PRs", "release workflow".
- CI exists but doesn't block merge, doesn't cache, or has no deploy path.

Not for: `.gitignore`/protection/templates (`repo-bootstrap`), status docs
(`project-docs`).

## Absolute rules

| Rule | Why |
|---|---|
| Never put a real secret in a workflow file or in `env:` literals. Use `${{ secrets.NAME }}`. | Workflow files are in git history and often public. |
| Never `pull_request_target` with a checkout of the PR head + secrets. | Lets a forked PR exfiltrate your secrets. Use `pull_request`. |
| Always pin third-party actions to a full commit SHA (or at minimum a major tag you trust). | A moved tag can run arbitrary code in your pipeline. |
| Always set `permissions:` explicitly at workflow or job level; start from `contents: read`. | Default token is over-privileged. |
| Never deploy from the `pull_request` event. Deploy on `push` to `main`, tags, or `workflow_dispatch`. | PR builds are untrusted and would deploy unreviewed code. |
| Every workflow gets `concurrency:` so superseded runs cancel. | Saves minutes and avoids racing deploys. |
| The CI job names are a public contract — once added to branch protection, renaming a job blocks all merges. Change them deliberately. | Silent lockout of the whole team. |

## Procedure

### 1. Detect stack + package manager + targets

| Signal | Stack | CI template | Deploy template(s) |
|---|---|---|---|
| `package.json` (+ lockfile picks pm) | Node/TS | `node-ci.yml` | `deploy-vercel.yml`, `deploy-netlify.yml`, `deploy-docker.yml`, `publish-npm.yml` |
| `next.config.*` | Next.js | `node-ci.yml` | `deploy-vercel.yml` |
| `pyproject.toml` / `requirements.txt` | Python | `python-ci.yml` | `deploy-docker.yml` |
| `pubspec.yaml` | Flutter | `flutter-ci.yml` | `deploy-expo-eas.yml` (RN) or build-apk job |
| `Cargo.toml` | Rust | `rust-ci.yml` | `deploy-docker.yml` / release-binaries |
| `go.mod` | Go | `go-ci.yml` | `deploy-docker.yml` |
| Electron/Tauri in `package.json` | Desktop | `node-ci.yml` | `release-desktop.yml` (matrix mac/win/linux) |

Lockfile → package manager: `package-lock.json`→npm, `pnpm-lock.yaml`→pnpm,
`yarn.lock`→yarn, `bun.lockb`→bun. Poetry/uv/pip from the Python project files.

Ask the user which deploy target(s) they actually use before adding deploy
workflows. Don't guess.

### 2. Add the CI workflow

Copy `references/workflows/<stack>-ci.yml` to `.github/workflows/ci.yml`.
Adjust: package-manager commands, Node/Python/etc. version (read from
`.nvmrc` / `engines` / `python_requires` / `go.mod`), test command, whether a
build step applies.

Standard jobs (keep these names stable — they become the required checks):
`lint`, `typecheck`, `test`, `build`. Plus `secret-scan` (gitleaks) always.

Requirements every CI workflow must meet:
- Triggers: `pull_request` + `push` to `main`.
- `concurrency: { group: ci-${{ github.ref }}, cancel-in-progress: true }`.
- `permissions: { contents: read }` (raise per-job only where needed).
- Dependency caching via the official setup action's `cache:` input.
- Actions pinned to SHA or trusted major tag.
- `timeout-minutes` on every job.

### 3. Secret-scan gate

Add the `secret-scan` job from `references/workflows/secret-scan.yml` (gitleaks,
full history fetch `fetch-depth: 0`). This is the CI counterpart of
`repo-bootstrap`'s local pre-commit hook.

### 4. Deploy workflow(s)

Only for confirmed targets. Copy the matching `references/workflows/deploy-*.yml`.
Each must:
- Trigger on `push` to `main` (and/or `v*` tags) and `workflow_dispatch`.
- Use a GitHub **Environment** (`production`) so required reviewers / secrets
  scope apply.
- Depend on CI passing (`needs:` or a separate required check).
- Pull all credentials from `secrets`.

Tell the user exactly which repo secrets to add (names + where to get each):
e.g. `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`; or
`EXPO_TOKEN`; or registry creds. Provide the `gh secret set` commands.

### 5. Wire into branch protection

Once the workflows have run once on a PR (so the check names are registered):

```
gh api -X PATCH repos/{OWNER}/{REPO}/branches/main/protection/required_status_checks \
  -f strict=true \
  -F 'checks[][context]=lint' -F 'checks[][context]=typecheck' \
  -F 'checks[][context]=test'  -F 'checks[][context]=build' \
  -F 'checks[][context]=secret-scan'
```

(Only include jobs that actually exist for this stack.)

### 6. Dependabot / auto-merge (optional)

If `repo-bootstrap` added `dependabot.yml`, optionally add
`references/workflows/dependabot-automerge.yml` to auto-merge passing
minor/patch bumps.

## Verification gate (must all pass)

1. `.github/workflows/ci.yml` parses: `gh workflow view ci.yml` or
   `actionlint` reports no errors.
2. Every third-party action is pinned (grep for `uses:` — no bare `@main` /
   `@master`).
3. No literal secrets: `grep -rnE '(password|token|api[_-]?key)\s*[:=]\s*["'\'']?[A-Za-z0-9_\-]{16,}' .github/workflows/` returns nothing.
4. Each workflow has `concurrency:` and `permissions:`.
5. A test PR: all of `lint/typecheck/test/build/secret-scan` run and the ones
   that should fail on bad input do fail.
6. Branch protection `required_status_checks.checks` lists the CI job names;
   a PR with a failing check cannot be merged.
7. Deploy workflow does NOT trigger on `pull_request` (only push/tag/dispatch).

Report each pass/fail with output.

## Worked example

Next.js app, pnpm, deploys to Vercel, solo dev.

1. Detect: `package.json` + `pnpm-lock.yaml` + `next.config.js` → `node-ci.yml`,
   Vercel deploy. Node 20 from `.nvmrc`.
2. `.github/workflows/ci.yml`: jobs `lint` (`pnpm lint`), `typecheck`
   (`pnpm tsc --noEmit`), `test` (`pnpm test -- --run`), `build` (`pnpm build`),
   `secret-scan` (gitleaks). `pull_request` + `push:main`, concurrency, caching,
   `permissions: contents: read`.
3. `secret-scan` job added.
4. `deploy-production.yml`: `push:main` + `workflow_dispatch`, environment
   `production`, `amondnet/vercel-action` pinned to SHA, needs `VERCEL_TOKEN` /
   `VERCEL_ORG_ID` / `VERCEL_PROJECT_ID`. Gave `gh secret set` commands.
5. Opened a throwaway PR → checks registered → `gh api PATCH ...required_status_checks`
   with the 5 contexts.
6. Gate: 7/7. Human TODO: add the 3 Vercel secrets, then re-run deploy.
