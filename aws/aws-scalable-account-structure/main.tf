############################
# Org structure (OUs)
############################

# Top-level OUs under Root
resource "aws_organizations_organizational_unit" "security" {
  name      = "Security"
  parent_id = var.root_id
}

resource "aws_organizations_organizational_unit" "workloads" {
  name      = "Workloads"
  parent_id = var.root_id
}

resource "aws_organizations_organizational_unit" "infrastructure" {
  name      = "Infrastructure"
  parent_id = var.root_id
}

# Optional “nice to have” OUs (uncomment if you want them now)
# resource "aws_organizations_organizational_unit" "sandbox"       { name = "Sandbox"       parent_id = var.root_id }
# resource "aws_organizations_organizational_unit" "suspended"     { name = "Suspended"     parent_id = var.root_id }
# resource "aws_organizations_organizational_unit" "exceptions"    { name = "Exceptions"    parent_id = var.root_id }
# resource "aws_organizations_organizational_unit" "policystaging" { name = "PolicyStaging" parent_id = var.root_id }

# Team OU under Workloads
resource "aws_organizations_organizational_unit" "team" {
  name      = var.team_name
  parent_id = aws_organizations_organizational_unit.workloads.id
}

############################
# Per-workload accounts
############################

resource "aws_organizations_account" "production" {
  name      = "${var.team_name}-production"
  email     = var.account_emails.production
  parent_id = aws_organizations_organizational_unit.team.id
  lifecycle { ignore_changes = [role_name, iam_user_access_to_billing] }
}

resource "aws_organizations_account" "preproduction" {
  name      = "${var.team_name}-preproduction"
  email     = var.account_emails.preproduction
  parent_id = aws_organizations_organizational_unit.team.id
  lifecycle { ignore_changes = [role_name, iam_user_access_to_billing] }
}

resource "aws_organizations_account" "development" {
  name      = "${var.team_name}-development"
  email     = var.account_emails.development
  parent_id = aws_organizations_organizational_unit.team.id
  lifecycle { ignore_changes = [role_name, iam_user_access_to_billing] }
}

resource "aws_organizations_account" "shared" {
  name      = "${var.team_name}-shared"
  email     = var.account_emails.shared
  parent_id = aws_organizations_organizational_unit.team.id
  lifecycle { ignore_changes = [role_name, iam_user_access_to_billing] }
}

output "ou_ids" {
  value = {
    security      = aws_organizations_organizational_unit.security.id
    workloads     = aws_organizations_organizational_unit.workloads.id
    infrastructure= aws_organizations_organizational_unit.infrastructure.id
    team          = aws_organizations_organizational_unit.team.id
  }
}

output "accounts" {
  value = {
    production    = aws_organizations_account.production.id
    preproduction = aws_organizations_account.preproduction.id
    development   = aws_organizations_account.development.id
    shared        = aws_organizations_account.shared.id
  }
}
