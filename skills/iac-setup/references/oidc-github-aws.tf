# infra/global/iam-oidc/main.tf
# GitHub Actions -> AWS via OIDC. No long-lived keys anywhere.

data "aws_caller_identity" "me" {}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["ffffffffffffffffffffffffffffffffffffffff"] # AWS validates the cert chain; value is legacy
}

variable "repo" { type = string } # "voidloop-dev/myapp"

locals { envs = ["dev", "staging", "prod"] }

# read-only role used for `plan` (PRs)
resource "aws_iam_role" "plan" {
  for_each = toset(local.envs)
  name     = "tf-plan-${each.value}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = { "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com" }
        StringLike   = { "token.actions.githubusercontent.com:sub" = "repo:${var.repo}:*" }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "plan_ro" {
  for_each   = aws_iam_role.plan
  role       = each.value.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
# + a small inline policy granting s3:*Object on the state bucket path and
#   dynamodb Get/Put/Delete on the lock table.

# write role used for `apply` (merge to main) — scope tightly per env, and
# restrict the trust `sub` to the environment / branch that may assume it, e.g.
#   "repo:${var.repo}:environment:production"
resource "aws_iam_role" "apply" {
  for_each = toset(local.envs)
  name     = "tf-apply-${each.value}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = "repo:${var.repo}:ref:refs/heads/main"
        }
      }
    }]
  })
}
# attach a least-privilege policy per env (only the services this stack manages).
