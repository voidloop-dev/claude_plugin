# Keyless CI auth (OIDC) — cheatsheet

The CI provider issues a signed JWT describing the workflow. The cloud trusts
that issuer and swaps the JWT for a short-lived credential. Nothing is stored.

## GitHub Actions → AWS

1. IAM OIDC provider: `token.actions.githubusercontent.com`, audience
   `sts.amazonaws.com`.
2. IAM role with trust policy conditioned on `sub`:
   - PRs / plan:  `repo:ORG/REPO:pull_request`
   - deploy:      `repo:ORG/REPO:ref:refs/heads/main`
   - per env:     `repo:ORG/REPO:environment:production`
3. Workflow:
   ```yaml
   permissions: { id-token: write, contents: read }
   steps:
     - uses: aws-actions/configure-aws-credentials@v4
       with:
         role-to-assume: arn:aws:iam::<acct>:role/deploy-prod
         aws-region: eu-west-1
   ```

## GitHub Actions → GCP

Workload Identity Federation pool + provider; grant the CI principal
`roles/iam.workloadIdentityUser` on a service account.
`google-github-actions/auth@v2` with `workload_identity_provider` + `service_account`.

## GitHub Actions → Azure

`azure/login@v2` with `client-id`, `tenant-id`, `subscription-id` and a federated
credential on the app registration matching the repo/branch/environment. No client secret.

## Registries

- GHCR: `GITHUB_TOKEN` with `packages: write` — nothing to store.
- ECR: OIDC role + `aws ecr get-login-password`.
- Docker Hub / GAR / ACR: OIDC where supported; else a scoped bot token in the
  secret store, rotated.

## Other CI

- GitLab: `id_tokens:` + cloud OIDC, same model.
- CircleCI / Buildkite: OIDC token support → cloud federation.

## Rule

If you're pasting a long-lived `AKIA...` / service-account JSON into CI secrets,
stop — wire OIDC instead.
