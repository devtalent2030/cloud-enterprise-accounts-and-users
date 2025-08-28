terraform {
  required_version = ">= 1.4.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Management acct creds (what you’re using now to provision)
provider "aws" {
  region = "us-east-1"
}

# Assume into the new Auth account's bootstrap role
provider "aws" {
  alias  = "auth"
  region = "us-east-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.auth_account_id}:role/OrganizationAccountAccessRole"
  }
}

# Assume into the target (e.g., SANDBOX) account's bootstrap role
provider "aws" {
  alias  = "target"
  region = "us-east-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.target_account_id}:role/OrganizationAccountAccessRole"
  }
}
