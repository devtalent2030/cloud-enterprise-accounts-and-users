resource "aws_organizations_account" "auth" {
  name      = var.auth_account_name
  email     = var.auth_account_email
  parent_id = var.security_ou_id

  # Leave these unchanged; the default bootstrap role will be created for you.
  lifecycle {
    ignore_changes = [role_name, iam_user_access_to_billing]
  }
}

output "auth_account_id" {
  value = aws_organizations_account.auth.id
}
