############################
# 1) Target account role(s)
############################

# Admin role in the target (for labs only)
data "aws_iam_policy_document" "target_admin_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.auth_account_id}:root"]
    }

    # Require MFA when assuming the role (elite hygiene)
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
  }
}

resource "aws_iam_role" "target_admin" {
  provider           = aws.target
  name               = var.role_name_admin
  assume_role_policy = data.aws_iam_policy_document.target_admin_trust.json
  max_session_duration = var.session_duration
}

# Attach AWS managed AdministratorAccess to that role
resource "aws_iam_role_policy_attachment" "target_admin_attach" {
  provider   = aws.target
  role       = aws_iam_role.target_admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

#################################
# 2) Auth account IAM users/groups
#################################

# Users (human) who will assume the SandboxAdmin role
resource "aws_iam_user" "labs" {
  provider      = aws.auth
  for_each      = toset(var.labs_users)
  name          = each.value
  force_destroy = true
  path          = "/labs/"
}

# Optional: You can create console login profiles yourself later to set passwords
# and enforce MFA. For strict IaC: use aws_iam_user_login_profile with pgp_key.

# Group to hold “labs users”
resource "aws_iam_group" "labs" {
  provider = aws.auth
  name     = "labs-sandbox-admin"
  path     = "/labs/"
}

# Add users to the group
resource "aws_iam_group_membership" "labs_members" {
  provider = aws.auth
  name     = "labs-sandbox-admin-members"
  users    = [for u in aws_iam_user.labs : u.name]
  group    = aws_iam_group.labs.name
}

# Group policy: allow sts:AssumeRole into target SandboxAdmin role (require MFA)
data "aws_iam_policy_document" "labs_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    resources = [aws_iam_role.target_admin.arn]

    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
  }
}

resource "aws_iam_group_policy" "labs_assume" {
  provider = aws.auth
  name     = "AllowAssume_SandboxAdmin_${var.target_account_id}"
  group    = aws_iam_group.labs.name
  policy   = data.aws_iam_policy_document.labs_assume.json
}

output "target_admin_role_arn" {
  value = aws_iam_role.target_admin.arn
}

output "auth_console_url" {
  value = "https://${var.auth_account_id}.signin.aws.amazon.com/console"
}
