variable "management_group_parent_id" {
  type        = string
  description = "Root management group ID (your tenant GUID)."
}

variable "invoice_section_id" {
  type        = string
  description = "MCA Invoice Section resource ID used to bill new subscriptions."
}

variable "team_name" {
  type        = string
  description = "Team name to be onboarded (used as a prefix for the team subscriptions)."
}

variable "landing_zone_flavor" {
  type        = string
  default     = "Online"
  description = "Landing zone flavor for this team (Online or Corp)."
  validation {
    condition     = contains(["Online", "Corp"], var.landing_zone_flavor)
    error_message = "landing_zone_flavor must be Online or Corp."
  }
}

variable "existing_shared_subscription_id" {
  type        = string
  description = "GUID of the already-existing SpecterShared subscription (no /subscriptions/ prefix)."
}
