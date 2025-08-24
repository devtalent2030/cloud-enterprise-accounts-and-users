variable "organization_domain" {
  type        = string
  description = "Your org domain (e.g., talent-lab.xyz)"
}

variable "allowed_regions" {
  type        = list(string)
  description = "Explicit region IDs to allow (no 'in:' prefix)"
}
