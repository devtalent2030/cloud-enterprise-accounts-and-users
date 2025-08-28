variable "security_ou_id" {
  type        = string
  description = "OU ID where the Auth account will live (your Security OU ID)."
}

variable "auth_account_email" {
  type        = string
  description = "Root email for the Auth account (use your +alias)."
}

variable "auth_account_name" {
  type        = string
  default     = "auth-identity"
  description = "Friendly name for the Auth account."
}
