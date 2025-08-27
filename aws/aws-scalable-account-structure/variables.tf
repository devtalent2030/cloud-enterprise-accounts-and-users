variable "root_id" {
  description = "Root ID of the org (looks like r-xxxx)"
  type        = string
}

variable "team_name" {
  description = "Logical team identifier (e.g., payments)"
  type        = string
}

variable "account_emails" {
  description = "Emails for the four accounts"
  type = object({
    production     = string
    preproduction  = string
    development    = string
    shared         = string
  })
}
