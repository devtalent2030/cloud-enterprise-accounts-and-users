data "aws_organizations_organization" "this" {}

resource "aws_organizations_policy" "region_lock" {
  name    = "region-lock"
  content = data.aws_iam_policy_document.region_lock_policy.json
}

resource "aws_organizations_policy_attachment" "attach_to_root" {
  policy_id = aws_organizations_policy.region_lock.id
  target_id = data.aws_organizations_organization.this.roots[0].id
}

data "aws_iam_policy_document" "region_lock_policy" {
  statement {
    effect     = "Deny"
    not_actions = local.service_exemptions
    resources   = ["*"]

    condition {
      test     = "StringNotEquals"
      variable = "aws:RequestedRegion"
      values   = var.allowed_regions
    }
  }
}
