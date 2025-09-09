terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # Match the book’s recipe; we can bump to v3 later if you want.
      version = "~> 2"
    }
  }
}

provider "azurerm" {
  features {}
  # Auth: uses your current `az login` session (Specter Cloud Admin).
}
