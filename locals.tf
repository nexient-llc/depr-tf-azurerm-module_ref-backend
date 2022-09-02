# Copyright 2022 Nexient LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

locals {
  # The first region in the list. This is where the front-door instance would be installed
  primary_region = var.backend_regions[0]

  # Construct the below local variables to pass in the objects to all dependent modules
  resource_groups = {
    for region in var.backend_regions : region => {
      location = region
      name     = module.resource_group[region].resource_group.name
    }
  }

  storage_accounts = {
    for region in var.backend_regions : region => {
      name    = length(module.resource_name["storage_account-${region}"].lower_case) > var.resource_types["storage_account"].maximum_length ? module.resource_name["storage_account-${region}"].recommended_per_length_restriction : module.resource_name["storage_account-${region}"].lower_case
      rg_name = module.resource_group[region].resource_group.name
    }
  }

  application_insights = var.enable_application_insights ? {
    for region in var.backend_regions : region => {
      name    = module.resource_name["app_insights-${region}"].recommended_per_length_restriction
      rg_name = module.resource_group[region].resource_group.name
    }
    } : {
    for region in var.backend_regions : region => {}
  }

  service_plans = {
    for region in var.backend_regions : region => {
      name    = module.resource_name["service_plan-${region}"].recommended_per_length_restriction
      rg_name = module.resource_group[region].resource_group.name
    }
  }

  key_vaults = {
    for region in var.backend_regions : region => {
      name    = module.resource_name["key_vault-${region}"].recommended_per_length_restriction
      rg_name = module.resource_group[region].resource_group.name
    }
  }

  default_tags = {
    provisioner = "Terraform"
  }

  tags = merge(var.custom_tags, local.default_tags)

  azure_region_abbr_map = {
    eastus         = "eus"
    westus         = "wus"
    eastus2        = "eus2"
    westus2        = "wus2"
    centralus      = "cus"
    northcentralus = "ncus"
    southcentralus = "scus"
    westcentralus  = "wcus"
  }

  # Construct a map of all resource types for all backend regions
  all_resource_types = merge([for region in var.backend_regions : { for key, value in var.resource_types : "${key}-${region}" => value }]...)

  # construct the backend pool

  # inject the address and host_header from web_app module
  backends = {
    for key, backend in var.backend_pool.backends :
    key => merge(backend, {
      address     = module.web_app[key].default_host_name
      host_header = module.web_app[key].default_host_name
    })
  }
  # This module just supports 1 backend pool
  backend_pools = {
    default-backend-pool = {
      backends       = local.backends
      health_probe   = var.backend_pool.health_probe
      load_balancing = var.backend_pool.load_balancing
    }
  }

  # Forwarding configuration for the default-backend-pool
  forwarding_configurations = {
    default-backend-pool = var.forwarding_configurations
  }

  # Default routing rule name
  routing_rule_name = "default-routing-rule"

  # Construct the frontend_endpoint_names here instead of having a variable as this module supports only 1 routing rule
  frontend_endpoint_names = [for key, endpoint in var.frontend_endpoints : key]

  # Construct the key vault object for the primary region (first region in the var.backend_regions)
  primary_key_vault = {
    key_vault_name = module.resource_name["key_vault-${local.primary_region}"].recommended_per_length_restriction
    key_vault_rg   = module.resource_group[local.primary_region].resource_group.name

  }

  # Inject the key vault name and rg to the custom_user_managed_certs variable
  custom_user_managed_certs = length(var.custom_user_managed_certs) > 0 ? { for key, cert in var.custom_user_managed_certs : key => merge(cert, local.primary_key_vault) } : {}

  # Principal IDs of all deployment slots
  deployment_slots_identities_principals = {
    for region in var.backend_regions :
    region => {
      for stage, identity in module.web_app[region].web_app_linux_slot_identities :
      stage => identity.principal_id
    }
  }

  # Principal IDs of all deployment slots and the production slot
  all_identities_principals = {
    for region, identities in local.deployment_slots_identities_principals :
    region => merge(identities, { production = module.web_app[region].web_app_identity.principal_id })
  }

  # Construct the key_vault access policy object to retrieve the secrets from the key-vault
  web_app_slots_kv_access_policies = {
    for region, identities in local.all_identities_principals :
    region => {
      for stage, principal_id in identities :
      stage => {
        object_id               = principal_id
        tenant_id               = data.azurerm_client_config.current.tenant_id
        key_permissions         = []
        certificate_permissions = []
        secret_permissions      = ["Get", "Set", "List", "Delete", "Purge"]
        storage_permissions     = []
      }
    }
  }

  # Merge any access policies passed in by the user
  all_kv_access_policies = {
    for region, policies in local.web_app_slots_kv_access_policies :
    region => merge(policies, var.kv_access_policies)
  }

}
