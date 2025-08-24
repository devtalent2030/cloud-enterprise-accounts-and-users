variable "org_domain" {
  description = "Your GCP organization domain (e.g., talent-lab.xyz)"
  type        = string
}

variable "project_id" {
  description = "The existing bootstrap project ID to move under the Bootstrap folder"
  type        = string
}

variable "create_common_folder" {
  description = "Also create the Common folder (true/false)"
  type        = bool
  default     = true
}
