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

variable "backend_regions" {
  description = "A list of valid Azure regions where the backend web-app is to be deployed. The first region in the list is considered the primary region and the front-door will be provisioned in that region"
  type        = list(string)
  validation {
    condition     = length(regexall("\\b \\b", var.backend_regions[0])) == 0
    error_message = "Spaces between the words are not allowed."
  }
  default = ["eastus", "westus"]
}

#################################################
#Variables associated with resource naming module
##################################################

variable "resource_types" {
  description = "Map of cloud resource types to be used in this module. These values are used in the resource_name module to generate resource names"
  type = map(object({
    type           = string
    maximum_length = number
  }))

  default = {
    "resource_group" = {
      type           = "rg"
      maximum_length = 63
    }
    "front_door" = {
      type           = "fd"
      maximum_length = 60
    }
    "web_app" = {
      type           = "app"
      maximum_length = 63
    }
    "storage_account" = {
      type           = "sa"
      maximum_length = 24
    }
    "key_vault" = {
      type           = "kv"
      maximum_length = 24
    }
    "app_insights" = {
      type           = "appins"
      maximum_length = 260
    }
    "service_plan" = {
      type           = "plan"
      maximum_length = 60
    }
    "log_analytics" = {
      type           = "log"
      maximum_length = 63
    }
  }
}

variable "logical_product_name" {
  type        = string
  description = "(Required) Name of the application for which the resource is created."
  nullable    = false

  validation {
    condition     = length(trimspace(var.logical_product_name)) <= 15 && length(trimspace(var.logical_product_name)) > 0
    error_message = "Length of the logical product name must be between 1 to 15 characters."
  }
}

variable "class_env" {
  type        = string
  description = "(Required) Environment where resource is going to be deployed. For ex. dev, qa, uat"
  nullable    = false

  validation {
    condition     = length(trimspace(var.class_env)) <= 15 && length(trimspace(var.class_env)) > 0
    error_message = "Length of the environment must be between 1 to 15 characters."
  }

  validation {
    condition     = length(regexall("\\b \\b", var.class_env)) == 0
    error_message = "Spaces between the words are not allowed."
  }
}

variable "instance_env" {
  type        = number
  description = "Number that represents the instance of the environment."
  default     = 0

  validation {
    condition     = var.instance_env >= 0 && var.instance_env <= 999
    error_message = "Instance number should be between 1 to 999."
  }
}

variable "instance_resource" {
  type        = number
  description = "Number that represents the instance of the resource."
  default     = 0

  validation {
    condition     = var.instance_resource >= 0 && var.instance_resource <= 100
    error_message = "Instance number should be between 1 to 100."
  }
}

variable "use_azure_region_abbr" {
  description = "Whether to use region abbreviation e.g. eastus -> eus"
  type        = bool
  default     = false
}

########################################################
# Variables associated with storage account module
########################################################

variable "storage_account" {
  description = "Storage account config"
  type = object({
    account_tier             = string
    account_replication_type = string
    tags                     = map(string)
  })
}

variable "storage_containers" {
  description = "Map of storage container configs, keyed polymorphically. container_access_type can be blob, web etc."
  type = map(object({
    name                  = string
    container_access_type = string
  }))
  default = {}
}

variable "storage_shares" {
  description = "Map of storage file shares configs, keyed polymorphically. Quota is the storage in GB"
  type = map(object({
    name  = string
    quota = number
  }))
  default = {}
}

variable "storage_queues" {
  description = "Map of storage queue configs, keyed polymorphically"
  type = map(object({
    name = string
  }))
  default = {}
}

variable "static_website" {
  description = "The static website details if the storage account needs to be used as a static website"
  type = object({
    index_document     = string
    error_404_document = string
  })
  default = null
}

variable "enable_https_traffic_only" {
  description = "Boolean flag that forces HTTPS traffic only"
  type        = bool
  default     = true
}

variable "access_tier" {
  description = "Access tier for the Storage account. Choose between Hot or Cool"
  type        = string
  default     = "Hot"
  validation {
    condition     = (contains(["Hot", "Cold"], var.access_tier))
    error_message = "The access_tier must be either \"Hot\" or \"Cold\"."
  }

}

variable "account_kind" {
  description = "Defines the kind of account"
  type        = string
  default     = "StorageV2"
}

# Blob related inputs

variable "blob_cors_rule" {
  description = "Blob cors rules"
  type = map(object({
    allowed_headers    = list(string)
    allowed_methods    = list(string)
    allowed_origins    = list(string)
    exposed_headers    = list(string)
    max_age_in_seconds = number
  }))

  default = null
}

variable "blob_delete_retention_policy" {
  description = "Number of days the blob should be retained. Set 0 to disable"
  type        = number
  default     = 0
}

variable "blob_versioning_enabled" {
  description = "Is blob versioning enabled for blob?"
  type        = bool
  default     = false
}

variable "blob_change_feed_enabled" {
  description = "Is the blobl service properties for change feed enabled for blob?"
  type        = bool
  default     = false
}

variable "blob_last_access_time_enabled" {
  description = "Is the last access time based tracking enabled?"
  type        = bool
  default     = false
}

variable "blob_container_delete_retention_policy" {
  description = "Specify the number of days that the container should be retained. Set 0 to disable"
  type        = number
  default     = 0
}

########################################################
# Variables associated with key vault module
########################################################

variable "kv_soft_delete_retention_days" {
  description = "Number of retention days for soft delete for key vault"
  type        = number
  default     = 7
}

variable "kv_sku" {
  description = "SKU for the key vault - standard or premium"
  type        = string
  default     = "standard"
  validation {
    condition     = (contains(["standard", "premium"], var.kv_sku))
    error_message = "The kv_sku must be either \"standard\" or \"premium\"."
  }
}

variable "kv_access_policies" {
  description = "Additional Access policies for the vault except the current user which are added by default"
  type = map(object({
    object_id               = string
    tenant_id               = string
    key_permissions         = list(string)
    certificate_permissions = list(string)
    secret_permissions      = list(string)
    storage_permissions     = list(string)
  }))

  default = {}
}

# Variables to import pre existing certificates to the key vault
variable "certificates" {
  description = "List of certificates to be imported. The pfx files should be present in the root of the module (path.root) and its name denoted as certificate_name"
  type = map(object({
    certificate_name = string
    password         = string
  }))

  default = {}
}

# Variables to import secrets
variable "secrets" {
  description = "List of secrets (name and value)"
  type        = map(string)
  default     = {}
}

# Variables to import Keys
variable "keys" {
  description = "List of keys to be created in key vault. Name of the key is the key of the map"
  type = map(object({
    key_type = string
    key_size = number
    key_opts = list(string)
  }))
  default = {}
}

variable "custom_tags" {
  description = "Custom Tags associated with this module"
  type        = map(string)
  default     = {}
}

########################################################
# Variables associated with application insights module
########################################################

variable "app_insights" {
  description = "App insights primitive."
  type = object({
    application_type = string
    custom_tags      = map(string)
  })
  default = {
    application_type = "web"
    custom_tags      = {}
  }
}

variable "log_analytics" {
  description = "Log analytics primitive."
  type = object({
    sku                                = string
    retention_in_days                  = number
    daily_quota_gb                     = number
    custom_tags                        = map(string)
    internet_ingestion_enabled         = bool
    internet_query_enabled             = bool
    reservation_capacity_in_gb_per_day = number
  })
  default = {
    sku                                = "PerGB2018"
    retention_in_days                  = 30
    daily_quota_gb                     = 0.5
    custom_tags                        = {}
    internet_ingestion_enabled         = true
    internet_query_enabled             = true
    reservation_capacity_in_gb_per_day = 100
  }
}

########################################################
# Variables associated with service plan module
########################################################

variable "service_plan" {
  description = "Object containing the details for a service plan"
  type = object({
    os_type      = string
    sku_name     = string
    custom_tags  = map(string)
    worker_count = number
  })
  default = {
    os_type      = "Linux"
    sku_name     = "P1v2"
    worker_count = 1
    custom_tags  = {}
  }
}

########################################################
# Variables associated with web app module
########################################################

variable "container_registry" {
  description = "The Container Registry associated with the web-app. Required only when application_stack = docker"
  type = object({
    name    = string
    rg_name = string
  })

  default = {
    name    = ""
    rg_name = ""
  }
}

variable "enabled" {
  description = "Switch to enable linux web-app. Default is true"
  type        = bool
  default     = true
}

variable "https_only" {
  description = "Switch for the flag https_only. Default is false"
  type        = bool
  default     = false
}

variable "storage_mounts" {
  description = "A map of storage mounts for the web-app. The account_name and access_key are optional and will be fetched from the storage_account variable if not specified. The share_name is either a blob or a fileshare in the storage_account. The mount_type can be either AzureFiles or AzureBlob"
  type = map(object({
    share_name   = string
    mount_type   = string
    mount_path   = string
    account_name = string # optional
    access_key   = string # optional
  }))
  default = {}
}

variable "application_stack" {
  description = "One of these options - docker, dotnet, java, node, python, php, ruby"
  default     = "docker"
  validation {
    condition     = contains(["docker", "dotnet", "java", "node", "python", "ruby", "php"], lower(var.application_stack))
    error_message = "The application_stack can take one of these values - docker, dotnet, java, node, python, php, ruby."
  }
}

variable "docker_image_name" {
  description = "The docker image name. Required only when application_stack = docker. More information on configuring a custom container https://docs.microsoft.com/en-us/azure/app-service/configure-custom-container?pivots=container-linux"
  default     = "sample-app"
}

variable "docker_image_tag" {
  description = "The docker image tag. Required only when application_stack = docker"
  default     = "1001"
}

variable "dotnet_version" {
  default     = null
  description = "Dotnet version for web-app runtime. Required only when application_stack = dotnet. Must be 3.1 or 5.0 or 6.0"
}

variable "java_version" {
  default     = null
  description = "Java version for web-app runtime. Required only when application_stack = java"
  type        = string
}

variable "java_server" {
  default     = null
  description = "Java Server for web-app runtime. Required only when application_stack = java. Use command 'az webapp list-runtimes --os-type=linux' for more details"
}

variable "java_server_version" {
  default     = null
  description = "Java server version for web-app runtime. Required only when application_stack = java. Use command 'az webapp list-runtimes --os-type=linux' for more details"
  type        = string
}

variable "node_version" {
  default     = null
  description = "Node version for web-app runtime. Required only when application_stack = node. Possible values are 12-lts, 14-lts, 16-lts"
  type        = string
}

variable "python_version" {
  default     = null
  description = "Python version for web-app runtime. Required only when application_stack = python. Possible values are 3.7, 3.8, 3.9."
  type        = string
}

variable "ruby_version" {
  default     = null
  description = "Ruby version for web-app runtime. Required only when application_stack = ruby. Possible values are 2.6 or 2.7."
  type        = string
}

variable "php_version" {
  default     = null
  description = "Php version for the web-app runtime. Required only when application_stack = php. Possible values are 7.4 or 8.0."
  type        = string
}

variable "site_config" {
  description = "All the site config mentioned in https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_function_app#site_config except application_stack"
  type        = any
  default     = {}
}

variable "application_settings" {
  description = "The environment variables passed in to the web-app"
  type        = map(string)
  default     = {}
}

variable "connection_strings" {
  description = "List of connection strings (name, type, value)"
  type = list(object({
    name  = string
    type  = string
    value = string
  }))
  default = []
}

variable "cors" {
  description = "CORS block (allowed_origins, support_credentials)"
  type = object({
    allowed_origins     = list(string)
    support_credentials = bool
  })
  default = null
}

# Variables related to the logs

variable "detailed_error_messages" {
  description = "Should detailed error messages be enabled?"
  type        = bool
  default     = false
}

variable "failed_request_tracing" {
  description = "Should failed request tracing be enabled?"
  type        = bool
  default     = false
}

variable "http_logs_file_system" {
  description = "HTTP Logs properties for type filesystem"
  type = object({
    retention_in_days = number
    retention_in_mb   = number
  })
  default = {
    retention_in_days = 14
    retention_in_mb   = 100
  }
}

variable "http_logs_azure_blob_storage" {
  description = "HTTP Logs properties type for Azure Blob Storage"
  type = object({
    level             = string
    retention_in_days = string
    sas_url           = string
  })
  default = null
}

variable "enable_system_managed_identity" {
  description = "Should system_managed_identity be enabled? Identity is used to interact with other Azure services like key-vault and container registry"
  type        = bool
  default     = true
}

variable "enable_application_insights" {
  description = "Should app Insights be enabled for the web-app? If enabled, application_insights is required variable."
  type        = bool
  default     = true
}

variable "deployment_slots" {
  description = "List of the names of deployment_slots for this app service"
  type        = list(string)
  default     = []
}

########################################################
# Variables associated with Front Door module
########################################################

variable "friendly_name" {
  description = "A friendly name to be attached to the front-door"
  default     = ""
  type        = string
}

variable "load_balancer_enabled" {
  description = "Whether the load balancer is enabled"
  type        = bool
  default     = true
}

variable "backend_pool" {
  description = "Backend pool for the front-door. This module supports only 1 pool. Each pool must have at least one backend (enabled). Backend must have the same keys as variable 'backend_regions'. Backend - address and host_header would be injected in locals file. Each backend must have a health probe and a load balancing."
  type = object({
    backends = map(object({
      enabled = bool
      # address     = string # Address must be a valid DNS or IP Address
      # host_header = string
      http_port  = number
      https_port = number
      priority   = number
      weight     = number
    }))
    health_probe = object({
      enabled      = bool
      name         = string
      path         = string
      protocol     = string
      probe_method = string
    })
    load_balancing = object({
      name                        = string
      sample_size                 = number # defaults to 4
      successful_samples_required = number # defaults to 2
      additional_latency_ms       = number # defaults to 0
    })
  })


}

# Front-end configuration for custom domains
variable "frontend_endpoints" {
  description = "Custom domain names to be attached to the front-door instance. The DNS records will be created if create_record=true. record_name must be a fqdn if create_record=false (DNS record must be created outside terraform pointing to the front-door instance), else it should be without the zone_name"
  type = map(object({
    create_record = bool
    endpoint_name = string
    record_name   = string # test1 if create_record=true, test1.nexient.com if create_record=false
    record_type   = string
    dns_zone      = string
    dns_rg        = string
  }))

  default = {}
}

# Primary Routing rule related variables

variable "accepted_protocols" {
  description = "Protocol schemes to match for the Backend Routing Rule. Defaults to Http"
  type        = list(string)
  default     = ["Http", "Https"]
}

variable "patterns_to_match" {
  description = "The route patterns for the Backend Routing Rule. Defaults to /*"
  type        = list(string)
  default     = ["/*"]
}

variable "routing_rule_enabled" {
  description = "Whether the routing rule should be enabled. Default is enabled. Cannot be disabled unless there are other routing rule enabled"
  type        = bool
  default     = true
}

variable "forwarding_configurations" {
  description = "Routing rules to forward the traffic to configured backends. Currently supports just 1 forwarding configuration rule for the 'default-backend-pool'. This conflicts with 'redirect_configurations'. Either one of these can exist for a routing rule"
  type = object({
    cache_enabled                         = bool         # defaults to false
    cache_use_dynamic_compression         = bool         # defaults to false
    cache_query_parameter_strip_directive = string       # defaults to StripAll
    cache_query_parameters                = list(string) # works only with strip_directive = StringOnly or StripAllExcept
    cache_duration                        = string       # number between 0 and 365. Works only when cache_enabled = true
    custom_forwarding_path                = string
    forwarding_protocol                   = string # defaults to HttpsOnly
  })

}

variable "redirect_configurations" {
  description = "Routing rules to redirect the traffic to the configured backend. This conflicts with 'forwarding_configurations'. Either one of these can exist for a routing rule"
  type = object({
    custom_host         = string
    redirect_protocol   = string # defaults to MatchRequest
    redirect_type       = string # valid options are Moved, Found, TemporaryRedirect, PermanentRedirect
    custom_fragment     = string
    custom_path         = string
    custom_query_string = string
  })

  default = null

}

variable "additional_routing_rules" {
  description = "Optional additional routing rules for the Front Door (One routing rule named 'primary' will be created by default based on the variables defined above). Multiple routing rules cannot have same set of AcceptedProtocol, FrontendEndpoint, and PatternsToMatch"
  type = map(object({
    name                    = string
    frontend_endpoint_names = list(string) #The first end point should be <front_door_name>.azurefd.net. The others can be list of custom domains if any
    accepted_protocols      = list(string)
    patterns_to_match       = list(string)
    enabled                 = bool
    forwarding_configuration = map(object({
      cache_enabled                         = bool         # defaults to false
      cache_use_dynamic_compression         = bool         # defaults to false
      cache_query_parameter_strip_directive = string       # defaults to StripAll
      cache_query_parameters                = list(string) # works only with strip_directive = StringOnly or StripAllExcept
      cache_duration                        = string       # number between 0 and 365. Works only when cache_enabled = true
      custom_forwarding_path                = string
      forwarding_protocol                   = string # defaults to HttpsOnly
    }))
    redirect_configuration = object({
      custom_host         = string
      redirect_protocol   = string # defaults to MatchRequest
      redirect_type       = string # valid options are Moved, Found, TemporaryRedirect, PermanentRedirect
      custom_fragment     = string
      custom_path         = string
      custom_query_string = string
    })
  }))

  default = {}
}

variable "backend_pool_settings" {
  description = "Settings for the backend pool of frontdoor. These settings are common for all backend pools"
  type = object({
    backend_pools_send_receive_timeout_seconds   = number
    enforce_backend_pools_certificate_name_check = bool
  })
  default = {
    backend_pools_send_receive_timeout_seconds   = 60
    enforce_backend_pools_certificate_name_check = false
  }
}



# Object ID for FrontDoor: e344ee3c-527c-43cd-aa22-1645ed7b0b95. Needs to be configured as Access Policy in key-vault
variable "custom_user_managed_certs" {
  description = "TLS configuration for custom frontend endpoints. Only supported certificate source is key-vault. The key should match the key of the variable 'frontend_endpoints'"
  type = map(object({
    https_enabled              = bool
    certificate_secret_name    = string
    certificate_secret_version = string # Leave empty or null for 'Latest'
  }))

  default = {}
}