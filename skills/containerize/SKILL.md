---
name: containerize
description: >-
  Containerise an application to production standard: a small, secure,
  reproducible multi-stage image (non-root, pinned base, minimal layers, correct
  signal handling), a .dockerignore, a healthcheck, and a docker-compose for
  local development with its dependencies. Use when a project needs a Dockerfile,
  has a bad/bloated/root Dockerfile, or needs a reproducible local stack. Not for
  deploying the image (deploy-strategies, k8s) or the registry pipeline
  (supply-chain-security, cicd-setup).
---

# containerize

Produce an image a platform team would accept: minimal attack surface, no root,
pinned and reproducible, fast to build via cache, and correct as PID 1.

## When this applies

- No `Dockerfile`, or one that runs as root / uses `:latest` / is single-stage
  and huge / copies the whole context.
- "Dockerise this", "containerise", "add a Dockerfile", "local stack with
  Postgres/Redis".

## Absolute rules

| Rule | Why |
|---|---|
| Multi-stage: build deps in a builder stage, copy only artifacts to a slim/distroless runtime stage. | Keeps toolchains and source out of the shipped image. |
| Pin the base image by tag **and** digest (`node:20.11-slim@sha256:...`). Never `:latest`. | Reproducible builds; a moved tag can't change what ships. |
| Run as a non-root user (`USER`). Create one if the base lacks it. | A container escape starts unprivileged. |
| Add a `.dockerignore` before the first build (`.git`, `node_modules`, `.env`, build output, tests, CI). | Smaller context, faster builds, no secrets leaked into layers. |
| Order layers stale→fresh: base, system deps, dependency manifest + install, then source. | Maximises cache hits; source changes don't reinstall deps. |
| One concern per container. No init systems, no SSH, no cron inside the app image. | Containers are processes, not VMs. |
| Handle signals: exec-form `CMD ["..."]`, and an init (`--init` / `tini`) only if the process doesn't reap children. | `SIGTERM` must reach the app for graceful shutdown. |
| Never `COPY . .` before dependency install; never bake secrets with `ENV`/`ARG`. Use build secrets (`--mount=type=secret`) or runtime env. | Secrets in `ARG`/`ENV`/layers are recoverable from the image. |
| Declare a `HEALTHCHECK` (or document the orchestrator probe endpoint). | Platforms need a real readiness signal. |
| Set `WORKDIR`, non-buffered logs to stdout/stderr, and a fixed `EXPOSE`. | Predictable, observable, 12-factor. |

## Procedure

1. **Detect** language, package manager, build output, runtime entrypoint, the
   port, and runtime deps (DB, cache, queue).
2. **Pick bases** from `references/base-images.md` (builder = full SDK; runtime =
   slim or distroless or `scratch` for static binaries). Pin tag + digest.
3. **Write `.dockerignore`** from `references/dockerignore.txt`.
4. **Write the Dockerfile** from the matching `references/Dockerfile.<stack>`:
   builder stage (install deps from lockfile, build) → runtime stage (copy
   artifact, `USER`, `WORKDIR`, `EXPOSE`, `HEALTHCHECK`, exec-form `CMD`).
5. **Add `docker-compose.yml`** from `references/compose.yml` for local dev: the
   app plus its dependencies, named volumes, healthcheck-gated `depends_on`,
   `.env` wiring, no bind-mount of `node_modules`.
6. **Optimise**: enable BuildKit cache mounts for the package cache; verify final
   image size and layer count.
7. **Document** in the README: build, run, compose-up commands and required env.

## Verification gate

1. `docker build` succeeds from a clean clone; a second build with only a source
   change reuses the dependency layer (cache hit).
2. `docker run` the image: app starts, healthcheck goes healthy, `docker stop`
   exits within the grace period (SIGTERM handled), no errors.
3. `docker image inspect` shows a non-root `Config.User`.
4. Base image is pinned with a digest; no `:latest` anywhere (`grep`).
5. Final image size is reasonable for the stack (e.g. Node API < ~200 MB, Go
   < ~30 MB) — justify if larger.
6. `dive` / `docker history`: no `.env`, secrets, `.git`, or source in the
   runtime stage; no secret in any `ARG`/`ENV`.
7. `.dockerignore` exists and excludes VCS, deps, env, build output.
8. `docker compose up` brings up the full local stack; the app reaches its
   dependencies.
9. Trivy/grype scan of the image: no fixable HIGH/CRITICAL OS vulns (or
   documented).

Report pass/fail per item with output.

## Worked example

Next.js (standalone output), pnpm, needs Postgres + Redis locally.

- Builder: `node:20.11-slim@sha256:...`, `corepack enable`, copy
  `package.json pnpm-lock.yaml`, `pnpm i --frozen-lockfile` (cache mount), copy
  source, `pnpm build`.
- Runtime: `gcr.io/distroless/nodejs20-debian12@sha256:...`, copy
  `.next/standalone`, `.next/static`, `public`; `USER nonroot`; `EXPOSE 3000`;
  `HEALTHCHECK` curl `/api/health`; `CMD ["server.js"]`.
- `.dockerignore`: `.git .next node_modules .env* **/*.test.* coverage`.
- `compose.yml`: `app` (build .), `db` (postgres:16-alpine, volume, healthcheck),
  `redis` (redis:7-alpine); `app.depends_on` both `condition: service_healthy`.
- Gate: build cache hit on source-only change ✓; non-root ✓; image 174 MB ✓;
  `docker history` clean ✓; trivy 0 fixable HIGH ✓ → 9/9.
