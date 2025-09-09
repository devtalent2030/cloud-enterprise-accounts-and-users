############################################
# Root-level management groups (exact names)
############################################

############################################
# Management Group Hierarchy (exact names)
############################################
# Root (Tenant Root Group - var.management_group_parent_id)
# ├─ Sandbox
# ├─ Platform
# │  ├─ Identity
# │  ├─ Management
# │  └─ Connectivity
# ├─ Decommissioned
# └─ Landing zones
#    ├─ Online
#    │  └─ <Team> (e.g., Specter)
#    └─ Corp
############################################

# Under ROOT
resource "azurerm_management_group" "sandbox" {
  display_name               = "Sandbox"
  parent_management_group_id = var.management_group_parent_id

}

resource "azurerm_management_group" "platform" {
  display_name               = "Platform"
  parent_management_group_id = var.management_group_parent_id
}

resource "azurerm_management_group" "decommissioned" {
  display_name               = "Decommissioned"
  parent_management_group_id = var.management_group_parent_id
}

resource "azurerm_management_group" "landing_zones" {
  display_name               = "Landing zones"
  parent_management_group_id = var.management_group_parent_id
}

# Platform children
resource "azurerm_management_group" "platform_identity" {
  display_name               = "Identity"
  parent_management_group_id = azurerm_management_group.platform.id
}

resource "azurerm_management_group" "platform_management" {
  display_name               = "Management"
  parent_management_group_id = azurerm_management_group.platform.id
}

resource "azurerm_management_group" "platform_connectivity" {
  display_name               = "Connectivity"
  parent_management_group_id = azurerm_management_group.platform.id
}

# Landing zones children
resource "azurerm_management_group" "lz_online" {
  display_name               = "Online"
  parent_management_group_id = azurerm_management_group.landing_zones.id

}

resource "azurerm_management_group" "lz_corp" {
  display_name               = "Corp"
  parent_management_group_id = azurerm_management_group.landing_zones.id
}

############################################
# Team management group (under Online or Corp)
############################################
locals {
  team_parent_mg_id = var.landing_zone_flavor == "Online" ? azurerm_management_group.lz_online.id : azurerm_management_group.lz_corp.id
}


resource "azurerm_management_group" "team" {
  display_name               = var.team_name
  parent_management_group_id = local.team_parent_mg_id
}

############################################
# Subscriptions to create (Team: 4, Platform: 3)
############################################
# Team subscriptions
resource "azurerm_subscription" "production" {
  billing_scope_id  = var.invoice_section_id
  subscription_name = "${var.team_name}Production"

  timeouts {
    create = "2h"
    read   = "30m"
    delete = "2h"
  }
}

resource "azurerm_subscription" "preproduction" {
  billing_scope_id  = var.invoice_section_id
  subscription_name = "${var.team_name}Preproduction"

  timeouts {
    create = "2h"
    read   = "30m"
    delete = "2h"
  }
}

resource "azurerm_subscription" "development" {
  billing_scope_id  = var.invoice_section_id
  subscription_name = "${var.team_name}Development"

  timeouts {
    create = "2h"
    read   = "30m"
    delete = "2h"
  }
}

/*
resource "azurerm_subscription" "shared" {
  billing_scope_id  = var.invoice_section_id
  subscription_name = "${var.team_name}Shared"
}
*/

# Platform subscriptions
resource "azurerm_subscription" "platform_identity" {
  billing_scope_id  = var.invoice_section_id
  subscription_name = "Platform-Identity"
}

resource "azurerm_subscription" "platform_management" {
  billing_scope_id  = var.invoice_section_id
  subscription_name = "Platform-Management"
}

resource "azurerm_subscription" "platform_connectivity" {
  billing_scope_id  = var.invoice_section_id
  subscription_name = "Platform-Connectivity"
}

############################################
# Attach subscriptions to their Management Groups
# NOTE: subscription_id must be the FULL ARM ID:
#       "/subscriptions/<GUID>"
############################################

# Team → Specter (or your team_name) MG
resource "azurerm_management_group_subscription_association" "team_prod" {
  management_group_id = azurerm_management_group.team.id
  subscription_id     = "/subscriptions/${azurerm_subscription.production.subscription_id}"
}

resource "azurerm_management_group_subscription_association" "team_preprod" {
  management_group_id = azurerm_management_group.team.id
  subscription_id     = "/subscriptions/${azurerm_subscription.preproduction.subscription_id}"
}

resource "azurerm_management_group_subscription_association" "team_dev" {
  management_group_id = azurerm_management_group.team.id
  subscription_id     = "/subscriptions/${azurerm_subscription.development.subscription_id}"
}

resource "azurerm_management_group_subscription_association" "team_shared" {
  management_group_id = azurerm_management_group.team.id
  subscription_id     = "/subscriptions/${var.existing_shared_subscription_id}"
}


# Platform → Identity / Management / Connectivity MGs
resource "azurerm_management_group_subscription_association" "plat_identity_assoc" {
  management_group_id = azurerm_management_group.platform_identity.id
  subscription_id     = "/subscriptions/${azurerm_subscription.platform_identity.subscription_id}"
}

resource "azurerm_management_group_subscription_association" "plat_management_assoc" {
  management_group_id = azurerm_management_group.platform_management.id
  subscription_id     = "/subscriptions/${azurerm_subscription.platform_management.subscription_id}"
}

resource "azurerm_management_group_subscription_association" "plat_connectivity_assoc" {
  management_group_id = azurerm_management_group.platform_connectivity.id
  subscription_id     = "/subscriptions/${azurerm_subscription.platform_connectivity.subscription_id}"
}

############################################
# Helpful outputs
############################################
output "root_tree" {
  value = {
    Sandbox        = azurerm_management_group.sandbox.id
    Platform       = azurerm_management_group.platform.id
    Identity       = azurerm_management_group.platform_identity.id
    Management     = azurerm_management_group.platform_management.id
    Connectivity   = azurerm_management_group.platform_connectivity.id
    Decommissioned = azurerm_management_group.decommissioned.id
    Landing_zones  = azurerm_management_group.landing_zones.id
    Online         = azurerm_management_group.lz_online.id
    Corp           = azurerm_management_group.lz_corp.id
  }
}

output "team_management_group_id" {
  value = azurerm_management_group.team.id
}

output "team_subscription_ids" {
  value = [
    azurerm_subscription.production.subscription_id,
    azurerm_subscription.preproduction.subscription_id,
    azurerm_subscription.development.subscription_id,
    var.existing_shared_subscription_id
  ]
}


output "platform_subscription_ids" {
  value = {
    identity     = azurerm_subscription.platform_identity.subscription_id
    management   = azurerm_subscription.platform_management.subscription_id
    connectivity = azurerm_subscription.platform_connectivity.subscription_id
  }
}
