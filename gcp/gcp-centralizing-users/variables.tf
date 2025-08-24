variable "service_account_key_path" {
  type        = string
  description = "Path to where the service account key is located"
}

variable "customer_id" {
  type        = string
  description = <<DESCRIPTION
Customer ID for your Google Workspace account.
Find it at https://admin.google.com/ac/accountsettings
DESCRIPTION
}

variable "impersonated_user_email" {
  type        = string
  description = "The email address of a privileged (super admin) user in your Google Workspace"
}

variable "identity_project_id" {
  type        = string
  description = "The project ID for your centralized Identity project"
}

variable "target_project_id" {
  type        = string
  description = "The project ID to give the group read-only access"
}

variable "users" {
  type = map(object({
    given_name  = string
    family_name = string
  }))
  description = "Map of user objects to create (key = email)"
}

variable "team_name" {
  type        = string
  description = "The name of the team"
}

variable "team_description" {
  type        = string
  description = "The description of the team"
}

variable "team_email" {
  type        = string
  description = "The email address for the team group"
}
