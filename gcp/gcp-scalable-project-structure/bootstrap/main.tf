// labs/gcp/bootstrap/main.tf (ASCII only)

data "google_organization" "this" {
  domain = var.org_domain
}

resource "google_folder" "bootstrap" {
  display_name = "Bootstrap"
  parent       = data.google_organization.this.name
}

resource "google_folder" "common" {
  count        = var.create_common_folder ? 1 : 0
  display_name = "Common"
  parent       = data.google_organization.this.name
}

// Extract the numeric folder id (e.g., 123456789012) in a local,
// so we don't need any tricky quotes in the command string.
locals {
  bootstrap_folder_num = element(split("/", google_folder.bootstrap.id), 1)
}

// Move your existing project under the Bootstrap folder.
// Use explicit bash interpreter and a SINGLE-LINE ASCII command.
resource "null_resource" "move_initial_project" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-lc"]
    command     = "gcloud beta --quiet projects move ${var.project_id} --folder ${local.bootstrap_folder_num}"
  }
}

output "bootstrap_folder_name" {
  value = google_folder.bootstrap.name // e.g., folders/123456789012
}

output "common_folder_name" {
  value = try(google_folder.common[0].name, null)
}
