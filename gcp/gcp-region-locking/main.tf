data "google_organization" "this" {
  domain = var.organization_domain
}

resource "google_organization_policy" "region_lock" {
  org_id     = data.google_organization.this.org_id
  constraint = "constraints/gcp.resourceLocations"

  list_policy {
    allow {
      # explicit regions only, e.g., "australia-southeast1"
      values = var.allowed_regions
    }
  }
}
