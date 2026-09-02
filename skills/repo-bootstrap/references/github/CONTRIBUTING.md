# Contributing to {{PROJECT}}

## Ground rules

- **Never push to `main`.** Open a pull request.
- One PR = one concern. Split unrelated changes.
- No secrets, keys, or `.env` values in commits — the pre-commit hook and CI will
  block them anyway.

## Branch names

```
<type>/<short-description>
```

`type` is one of: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `perf`.
Example: `feat/csv-export`.

## Commits

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(export): add CSV download to the report page

Closes #42
```

## Local setup

```
{{INSTALL_COMMAND}}      # e.g. npm install
{{TEST_COMMAND}}         # e.g. npm test
{{LINT_COMMAND}}         # e.g. npm run lint
```

Enable the shared git hooks once:

```
git config core.hooksPath .githooks
```

## Pull requests

- Fill in the PR template.
- All status checks must pass; do not bypass branch protection.
- Get one approving review from a code owner.
- Squash-merge; delete the branch after merge.
