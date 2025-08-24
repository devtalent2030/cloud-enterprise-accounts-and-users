data "google_folder" "production" {
  folder = var.production_folder_name
}

data "google_folder" "nonproduction" {
  folder = var.nonproduction_folder_name
}

data "google_folder" "development" {
  folder = var.development_folder_name
}

# Team Production project
resource "google_project" "production" {
  name       = "${var.team_name}Production"
  project_id = "${var.project_prefix}-${var.team_name}-prod"
  folder_id  = data.google_folder.production.name
}

# Team PreProduction project (goes under NonProd folder)
resource "google_project" "preproduction" {
  name       = "${var.team_name}PreProduction"
  project_id = "${var.project_prefix}-${var.team_name}-preprod"
  folder_id  = data.google_folder.nonproduction.name
}

# Team Development project
resource "google_project" "development" {
  name       = "${var.team_name}Development"
  project_id = "${var.project_prefix}-${var.team_name}-dev"
  folder_id  = data.google_folder.development.name
}

# Team Shared project (common services; book places it under Production folder)
resource "google_project" "shared" {
  name       = "${var.team_name}Shared"
  project_id = "${var.project_prefix}-${var.team_name}-shared"
  folder_id  = data.google_folder.production.name
}

output "project_ids" {
  value = {
    production    = google_project.production.project_id
    preproduction = google_project.preproduction.project_id
    development   = google_project.development.project_id
    shared        = google_project.shared.project_id
  }
}
