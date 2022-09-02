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

data "azurerm_client_config" "current" {
}

module "resource_name" {
  source = "github.com/nexient-llc/tf-module-resource_name.git?ref=0.1.0"

  for_each = local.all_resource_types

  logical_product_name  = var.logical_product_name
  region                = split("-", each.key)[1]
  class_env             = var.class_env
  cloud_resource_type   = each.value.type
  instance_env          = var.instance_env
  instance_resource     = var.instance_resource
  maximum_length        = each.value.maximum_length
  use_azure_region_abbr = var.use_azure_region_abbr
}

module "resource_group" {
  source              = "github.com/nexient-llc/tf-azurerm-module-resource_group.git?ref=0.1.0"
  for_each            = toset(var.backend_regions)
  resource_group      = { location = each.value }
  resource_group_name = module.resource_name["resource_group-${each.value}"].standard

  tags = local.tags

}

module "storage_account" {
  source = "github.com/nexient-llc/tf-azurerm-module-storage_account.git?ref=0.2.0"

  for_each = toset(var.backend_regions)

  resource_group                         = local.resource_groups[each.value]
  storage_account_name                   = length(module.resource_name["storage_account-${each.value}"].lower_case) > var.resource_types["storage_account"].maximum_length ? module.resource_name["storage_account-${each.value}"].recommended_per_length_restriction : module.resource_name["storage_account-${each.value}"].lower_case
  storage_account                        = var.storage_account
  storage_containers                     = var.storage_containers
  storage_shares                         = var.storage_shares
  storage_queues                         = var.storage_queues
  static_website                         = var.static_website
  enable_https_traffic_only              = var.enable_https_traffic_only
  access_tier                            = var.access_tier
  account_kind                           = var.account_kind
  blob_cors_rule                         = var.blob_cors_rule
  blob_delete_retention_policy           = var.blob_delete_retention_policy
  blob_versioning_enabled                = var.blob_versioning_enabled
  blob_change_feed_enabled               = var.blob_change_feed_enabled
  blob_last_access_time_enabled          = var.blob_last_access_time_enabled
  blob_container_delete_retention_policy = var.blob_container_delete_retention_policy
}

module "key_vault" {
  source   = "github.com/nexient-llc/tf-azurerm-module-key_vault.git?ref=0.2.0"
  for_each = toset(var.backend_regions)

  resource_group             = local.resource_groups[each.value]
  key_vault_name             = module.resource_name["key_vault-${each.value}"].recommended_per_length_restriction
  soft_delete_retention_days = var.kv_soft_delete_retention_days
  sku_name                   = var.kv_sku
  access_policies            = local.all_kv_access_policies[each.value]
  certificates               = var.certificates
  secrets                    = var.secrets
  keys                       = var.keys

  custom_tags = local.tags
}

module "app_insights" {
  source   = "github.com/nexient-llc/tf-azurerm-module-app_insights.git?ref=0.1.0"
  for_each = var.enable_application_insights ? toset(var.backend_regions) : toset([])

  resource_group               = local.resource_groups[each.value]
  app_insights                 = var.app_insights
  app_insights_name            = module.resource_name["app_insights-${each.value}"].recommended_per_length_restriction
  log_analytics                = var.log_analytics
  log_analytics_workspace_name = module.resource_name["log_analytics-${each.value}"].recommended_per_length_restriction


}

module "service_plan" {
  source = "github.com/nexient-llc/tf-azurerm-module-service_plan.git?ref=0.1.0"

  for_each = toset(var.backend_regions)

  resource_group    = local.resource_groups[each.value]
  service_plan      = var.service_plan
  service_plan_name = module.resource_name["service_plan-${each.value}"].recommended_per_length_restriction
}

module "web_app" {
  source = "git@github.com:nexient-llc/tf-azurerm-module-linux_web_app.git?ref=0.1.0"

  for_each = toset(var.backend_regions)

  resource_group                 = local.resource_groups[each.value]
  storage_account                = local.storage_accounts[each.value]
  application_insights           = local.application_insights[each.value]
  service_plan                   = local.service_plans[each.value]
  container_registry             = var.container_registry
  web_app_name                   = module.resource_name["web_app-${each.value}"].recommended_per_length_restriction
  enabled                        = var.enabled
  https_only                     = var.https_only
  storage_mounts                 = var.storage_mounts
  application_stack              = var.application_stack
  docker_image_name              = var.docker_image_name
  docker_image_tag               = var.docker_image_tag
  dotnet_version                 = var.java_version
  java_version                   = var.java_version
  java_server                    = var.java_server
  java_server_version            = var.java_server_version
  node_version                   = var.node_version
  python_version                 = var.python_version
  php_version                    = var.php_version
  site_config                    = var.site_config
  application_settings           = var.application_settings
  connection_strings             = var.connection_strings
  cors                           = var.cors
  detailed_error_messages        = var.detailed_error_messages
  failed_request_tracing         = var.failed_request_tracing
  http_logs_file_system          = var.http_logs_file_system
  http_logs_azure_blob_storage   = var.http_logs_azure_blob_storage
  enable_system_managed_identity = var.enable_system_managed_identity
  enable_application_insights    = var.enable_application_insights
  deployment_slots               = var.deployment_slots
  custom_tags                    = local.tags

  depends_on = [
    module.app_insights,
    module.service_plan,
    module.storage_account
  ]

}

module "front_door" {
  source = "git@github.com:nexient-llc/tf-azurerm-module-front_door.git?ref=0.1.0"

  resource_group            = local.resource_groups[local.primary_region]
  front_door_name           = module.resource_name["front_door-${local.primary_region}"].recommended_per_length_restriction
  friendly_name             = var.friendly_name
  load_balancer_enabled     = var.load_balancer_enabled
  backend_pools             = local.backend_pools
  frontend_endpoints        = var.frontend_endpoints
  routing_rule_name         = local.routing_rule_name
  frontend_endpoint_names   = local.frontend_endpoint_names
  accepted_protocols        = var.accepted_protocols
  patterns_to_match         = var.patterns_to_match
  routing_rule_enabled      = var.routing_rule_enabled
  additional_routing_rules  = var.additional_routing_rules
  forwarding_configurations = local.forwarding_configurations
  redirect_configurations   = var.redirect_configurations
  backend_pool_settings     = var.backend_pool_settings
  custom_user_managed_certs = local.custom_user_managed_certs
  custom_tags               = local.tags

  depends_on = [
    module.key_vault
  ]

}
