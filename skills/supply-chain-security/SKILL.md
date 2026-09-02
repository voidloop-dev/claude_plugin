---
name: supply-chain-security
description: >-
  Harden the software supply chain: lockfile-pinned dependencies with automated
  update PRs, dependency + container + IaC vulnerability scanning as merge gates,
  SBOM generation, build provenance / artifact signing (SLSA, cosign), pinned and
  least-privilege CI actions, and secret scanning. Use when a project has
  unpinned deps, no vulnerability scanning, unsigned build artifacts, CI actions
  pinned to floating tags, or no SBOM. Complements cicd-setup (pipeline shape)
  and secrets-and-access (credentials).
---

# supply-chain-security

Everything between a developer's commit and a running artifact should be pinned,
scanned, attested, and least-privilege — so a compromised dependency or a
tampered build is caught, not shipped.

## When this applies

- Dependencies not lockfile-pinned, or updated manually/rarely.
- No `npm audit` / `pip-audit` / Trivy / Grype gate; CVEs merge freely.
- CI uses `uses: some/action@v3` (floating tag) instead of a commit SHA.
- Build artifacts (images, binaries, packages) are unsigned; no SBOM; no
  provenance.
- "Supply chain", "SBOM", "SLSA", "sign our images", "dependency scanning",
  "Dependabot/Renovate", "pin actions".

## Absolute rules

| Rule | Why |
|---|---|
| A lockfile is committed and CI installs with `--frozen-lockfile` / `--locked` / `pip install -r requirements.lock` — the exact pinned graph, never a resolver run. | A drifting transitive dep can introduce malicious or breaking code silently. |
| Third-party CI actions/orbs/plugins are pinned to a full commit SHA, not a tag. Re-pin deliberately via automation. | Tags are mutable; `@v3` can be moved to a malicious commit (see past incidents). |
| Dependency, container-image, and IaC vulnerability scans run in CI and **block merge** on fixable HIGH/CRITICAL (with a documented, expiring exception process). | Unblocked scans are noise; a gate is what changes behavior. |
| Automated dependency-update PRs (Dependabot / Renovate) are enabled, grouped, and run the full test + scan suite; minor/patch can auto-merge on green, majors are reviewed. | Manual updating doesn't happen; stale deps are the top breach vector. |
| Every release artifact has an SBOM (CycloneDX or SPDX) generated from the actual build and published alongside it. | You cannot respond to the next Log4Shell without knowing what's in your artifacts. |
| Release artifacts are signed (cosign / Sigstore) and carry build provenance (SLSA provenance attestation). Deploys verify the signature + provenance before running. | Proves the artifact came from your pipeline and wasn't swapped. |
| CI jobs declare minimal `permissions:` (start `contents: read`); the release job's elevated scopes are isolated to that job. Build and publish steps don't run untrusted PR code with secrets. | Limits what a compromised step or a malicious PR can do. |
| Secret scanning (gitleaks/trufflehog) runs pre-commit and in CI with history scan and blocks on a hit. | Last line before a credential reaches a public mirror. |
| Base images and toolchains are pinned by digest and rebuilt on a schedule to absorb upstream fixes; the rebuild re-runs all scans. | Pinning without refresh means shipping known-vulnerable bases forever. |
| Prefer packages from the primary registry with provenance; avoid abandoned or single-maintainer-critical deps; watch for typosquats on add. | Reduces the odds of pulling a hostile package in the first place. |

## Procedure

1. **Pin dependencies**: ensure a lockfile exists and is committed; switch CI to
   frozen installs; enable the ecosystem's integrity checks
   (`npm config set audit-level`, hashes in `requirements.txt`, `go.sum`, `cargo`
   `--locked`).
2. **Pin CI actions**: replace every `@vX` with `@<sha>  # vX.Y.Z`; add
   `zizmor` / `ratchet` / `pin-github-action` and a Renovate rule to keep SHAs
   updated via PR. Set `permissions:` per workflow/job.
3. **Dependency scanning** (`references/scanning.yml`): add an `osv-scanner` /
   `npm audit` / `pip-audit` / `govulncheck` job that fails on fixable
   HIGH/CRITICAL. Wire into branch protection.
4. **Image + IaC scanning**: Trivy (or Grype) on the built image and on the repo
   (misconfig + secrets + licenses); fail the build on fixable HIGH/CRITICAL.
5. **Update automation** (`references/renovate.json` or `dependabot.yml`):
   grouped, scheduled, auto-merge patch/minor on green (reuse
   `cicd-setup`'s dependabot-automerge), majors labelled for review.
6. **SBOM** (`references/sbom-and-signing.yml`): generate CycloneDX from the
   build (`syft` / `cdxgen` / `trivy sbom`); attach to the release and as an
   image attestation.
7. **Signing + provenance**: sign images/artifacts with `cosign` (keyless via
   OIDC); generate SLSA provenance (`slsa-github-generator` or
   `actions/attest-build-provenance`); publish both.
8. **Verify on deploy**: the deploy step runs `cosign verify` +
   `cosign verify-attestation` (or a Kyverno/admission policy in k8s) and refuses
   unsigned / unattested artifacts.
9. **Secret scanning**: confirm pre-commit hook (repo-bootstrap) + CI history
   scan; document the allowlist/exception policy.
10. **Scheduled hygiene** (`references/scheduled-rebuild.yml`): weekly rebuild +
    rescan of images; a monthly report of outstanding advisories and their
    remediation SLA.
11. **Document** `docs/SUPPLY_CHAIN.md`: the gates, the exception process (who
    approves, max duration), how to verify an artifact, the SBOM location.

## Verification gate

1. CI installs dependencies from the lockfile with a frozen/locked flag; a
   deliberate lockfile/manifest mismatch fails CI.
2. `grep -rnE 'uses:\s+[^@]+@(v?[0-9]|main|master)$' .github/` returns nothing —
   every action is SHA-pinned.
3. Every workflow sets `permissions:`; no job has broader scope than it uses.
4. Introducing a dependency with a known fixable HIGH CVE fails the merge; the
   documented exception path can unblock it with an expiry.
5. Image scan runs on the built image and blocks on fixable HIGH/CRITICAL.
6. Dependency-update PRs are opening on schedule and run the full suite; patch/
   minor auto-merge on green.
7. A release produces an SBOM (CycloneDX/SPDX) published with the artifact; it
   lists real transitive deps.
8. Release artifacts are signed; `cosign verify` succeeds for a real release and
   fails for a tampered/unsigned one.
9. SLSA provenance attestation exists for the artifact and is verifiable.
10. The deploy path refuses an unsigned or unattested artifact (test it).
11. Secret-scan (with history) runs in CI and blocks a planted key.
12. A scheduled rebuild/rescan job exists; `docs/SUPPLY_CHAIN.md` documents gates
    + exception process + verification steps.

Report pass/fail per item with evidence.

## Worked example

Node service, GitHub Actions, images to GHCR, deploys to k8s.

1. `pnpm-lock.yaml` committed; CI `pnpm i --frozen-lockfile`.
2. `pin-github-action` run → all `uses:` now `@<sha>  # vX`; Renovate
   `pinDigests: true` keeps them current. Every workflow `permissions: contents: read`.
3. `osv-scanner` job fails on fixable HIGH/CRITICAL; added to required checks.
4. Trivy scans the built image + the repo (config/secret/license); blocks build.
5. Renovate: grouped weekly, `automerge` for patch+minor after checks, majors →
   `deps-major` label.
6. `syft` generates `sbom.cdx.json`; attached to the GitHub Release and pushed as
   an OCI attestation.
7. `cosign sign` (keyless, GH OIDC) on the image digest;
   `actions/attest-build-provenance` emits SLSA provenance.
8. Kyverno `verifyImages` policy in the cluster: only images signed by the repo's
   OIDC identity **with** provenance may run. Tested: unsigned deploy rejected.
9. gitleaks pre-commit + CI history scan verified against a planted key.
10. Weekly `workflow_dispatch`+cron rebuild re-runs all scans; monthly advisory
    report via a scheduled job. `docs/SUPPLY_CHAIN.md` written. Gate 12/12.
