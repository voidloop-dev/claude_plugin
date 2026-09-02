# Choosing base images

Always pin `tag@sha256:digest`. Get the digest:
`docker buildx imagetools inspect <image>:<tag>`

| Stack | Builder stage | Runtime stage | Notes |
|---|---|---|---|
| Node | `node:20-slim` | `gcr.io/distroless/nodejs20-debian12` | distroless: no shell → probe via orchestrator or a node healthcheck script |
| Node (needs shell) | `node:20-slim` | `node:20-slim` | keep if you need `curl`/entrypoint scripts |
| Python | `python:3.12-slim` | `python:3.12-slim` or `gcr.io/distroless/python3-debian12` | slim keeps pip; distroless needs venv copied |
| Go / Rust (static) | `golang:1.22` / `rust:1` | `gcr.io/distroless/static-debian12:nonroot` or `scratch` | scratch needs CA certs + tzdata copied |
| Rust (dynamic) | `rust:1` | `gcr.io/distroless/cc-debian12` | glibc present |
| Java | `eclipse-temurin:21-jdk` | `eclipse-temurin:21-jre` or distroless java | use jlink for a custom runtime |
| .NET | `mcr.microsoft.com/dotnet/sdk:8.0` | `mcr.microsoft.com/dotnet/aspnet:8.0` or `-chiseled` | chiseled = distroless-like, non-root |

Avoid: `alpine` for anything with native deps compiled against glibc (musl
breaks numpy, sharp, grpc, etc.) — use `-slim` (Debian) instead.

Rebuild images at least weekly so OS CVE fixes land; automate via a scheduled
pipeline (see supply-chain-security).
