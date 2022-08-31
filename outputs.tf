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

output "resource_names" {
  description = "Resource names for debugging purpose. Must be removed"
  value       = { for key, val in module.resource_name : key => val.standard }
}

# Key Vault related outputs

output "key_vault_ids" {
  description = "Map of region to key_vault_id"
  value       = { for key, value in module.key_vault : key => value.key_vault_id }
}

output "key_vault_uris" {
  description = "Map of region to key_vault_uris"
  value       = { for key, value in module.key_vault : key => value.vault_uri }
}

output "key_vault_access_policies" {
  description = "Map of region to key_vault_access_policies"
  value       = { for key, value in module.key_vault : key => value.access_policies_object_ids }
  sensitive   = true
}

output "certificate_ids" {
  description = "Map of region to certificate_ids list"
  value       = { for key, value in module.key_vault : key => value.certificate_ids }
}

output "secret_ids" {
  description = "Map of region to secret_ids list"
  value       = { for key, value in module.key_vault : key => value.secret_ids }
}

output "key_ids" {
  description = "Map of region to keys_ids list"
  value       = { for key, value in module.key_vault : key => value.key_ids }
}

# Web App related outputs 

output "web_app_ids" {
  description = "Map of region to web-app ids"
  value       = { for key, value in module.web_app : key => value.web_app_id }
}

output "default_host_names" {
  description = "Map of region to default host names of web-app"
  value       = { for key, value in module.web_app : key => value.default_host_name }
}

output "outbound_ip_address_list" {
  description = "Map of region to outbound IP address of the web-app. Used for whitelist in firewall rules"
  value       = { for key, value in module.web_app : key => value.outbound_ip_address_list }
}

output "possible_outbound_ip_address_list" {
  description = "Map of region to possible list of outbound ip addresses of web-app. Can be used to whitelist in firewall rules"
  value       = { for key, value in module.web_app : key => value.possible_outbound_ip_address_list }
}

output "web_app_linux_slot_ids_map" {
  description = "Map of region to web-app slots ids"
  value       = { for key, value in module.web_app : key => value.web_app_linux_slot_ids_map }
}

output "connection_strings_list" {
  description = "Map of region to connection strings list"
  value       = { for key, value in module.web_app : key => value.connection_strings_list }
}

output "web_app_identities" {
  description = "Map of region to web-app identities"
  value       = { for key, value in module.web_app : key => value.web_app_identity }
}

output "web_app_slot_identities" {
  description = "Map of region to web-app deployment slot identities block"
  value       = { for key, value in module.web_app : key => value.web_app_linux_slot_identities }
}

# Storage account related outputs

output "storage_account_ids" {
  description = "Map of region to storage account ids"
  value       = { for key, value in module.storage_account : key => nonsensitive(value.storage_account.id) }
}

output "storage_shares" {
  description = "Map of region to storage shares list for a specific storage account"
  value       = { for key, value in module.storage_account : key => value.storage_shares }
}

output "storage_containers" {
  description = "Map of region to storage containers list for a specific storage account"
  value       = { for key, value in module.storage_account : key => value.storage_containers }
}

output "storage_queues" {
  description = "Map of region to storage queues list for a specific storage account"
  value       = { for key, value in module.storage_account : key => value.storage_queues }
}

# Front door related outputs

output "front_door_name" {
  description = "Name of the front-door instance"
  value       = module.front_door.front_door_name
}

output "front_door_id" {
  description = "Id of the front-door instance"
  value       = module.front_door.front_door_id
}

output "backend_pools" {
  description = "List of backend pools for the front-door. In this case, the list would contain only one backend pool"
  value       = module.front_door.backend_pools
}

output "frontend_endpoints" {
  description = "List of front-end endpoints for the front-door instance. Multiple values if custom domains are attached to the front-door"
  value       = module.front_door.frontend_endpoints
}

output "routing_rules" {
  description = "List of routing rules for the front-door instance"
  value       = module.front_door.routing_rules
}