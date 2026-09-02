# Terraform repo layout

```
infra/
  global/                     # one-per-org, rarely changes
    state-backend/            # the S3 bucket + lock table (bootstrap)
    iam-oidc/                 # GitHub OIDC provider + tf-plan/apply roles
    dns/                      # hosted zones
  modules/                    # reusable, environment-agnostic
    network/
      main.tf variables.tf outputs.tf versions.tf README.md
    database/
    service/
  envs/
    dev/
      backend.tf              # key = "envs/dev/terraform.tfstate"
      main.tf                 # module "network" { source = "../../modules/network" ... }
      terraform.tfvars        # non-secret env values
    staging/
    prod/                     # identical structure; differs only by tfvars
```

## Rules

- `modules/*` never reference a provider config directly — the caller passes it.
- Every module: typed variables **with `description` and `validation`**, explicit
  `outputs`, pinned `versions.tf`.
- `envs/*/backend.tf` — distinct `key`/`prefix` per env. Same bucket is fine;
  same key is not.
- `envs/*/main.tf` — only module calls + wiring. No `resource` blocks except
  truly env-unique one-offs.
- Commit `.terraform.lock.hcl` in every env dir.
- `prod` and `staging` diff = a `diff terraform.tfvars`, nothing structural.

## backend.tf example (S3)

```hcl
terraform {
  required_version = "~> 1.9.0"
  backend "s3" {
    bucket         = "myorg-tfstate"
    key            = "envs/prod/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "myorg-tflock"
    encrypt        = true
  }
}
```
