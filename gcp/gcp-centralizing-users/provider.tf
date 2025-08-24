provider "google" {
  project = var.identity_project_id
}

provider "googleworkspace" {
  credentials             = var.service_account_key_path
  customer_id             = var.customer_id
  impersonated_user_email = var.impersonated_user_email
  oauth_scopes = [
    "https://www.googleapis.com/auth/admin.directory.user",
    "https://www.googleapis.com/auth/admin.directory.group",
  ]
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      # Works fine with v5; bump if your env has newer
      version = "~> 5.0"
    }
    googleworkspace = {
      source  = "hashicorp/googleworkspace"
      version = "~> 0.7"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.4.0"
}
