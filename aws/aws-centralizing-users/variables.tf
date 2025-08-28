variable "auth_account_id" {
  type        = string
  description = "Account ID of the Auth account (output from Step 1)."
}

variable "target_account_id" {
  type        = string
  description = "Target account to assume into (e.g., SANDBOX)."
}

variable "labs_users" {
  type        = list(string)
  description = "List of IAM usernames to create in Auth for labs (no spaces)."
  default     = ["lab.user"]
}

# Role names inside the target account
variable "role_name_admin" {
  type    = string
  default = "SandboxAdmin"
}

# Session duration for assumed roles (seconds)
variable "session_duration" {
  type    = number
  default = 3600
}
