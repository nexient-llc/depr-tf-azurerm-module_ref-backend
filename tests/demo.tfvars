backend_regions = ["eastus", "westus"]

logical_product_name  = "demo"
class_env             = "dev"
instance_resource     = 2
use_azure_region_abbr = "true"

# Storage account
storage_account = {
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    "provisioner" = "Terraform"
  }
}

storage_shares = {
  assets = {
    name  = "assets"
    quota = 5
  }
  logs = {
    name  = "logs"
    quota = 1
  }
}

blob_cors_rule = {
  cors = {
    allowed_headers    = ["Content-Type"]
    allowed_methods    = ["GET", "PUT", "POST"]
    allowed_origins    = ["nexient.com"]
    exposed_headers    = ["Content-Type", "Max-Age"]
    max_age_in_seconds = 3600
  }
  cors2 = {
    allowed_headers    = ["Content-Type"]
    allowed_methods    = ["GET", "PUT"]
    allowed_origins    = ["nexient.com"]
    exposed_headers    = ["Content-Type", "Max-Age"]
    max_age_in_seconds = 3600
  }
}

# Key Vault

kv_access_policies = {
  # Access Policy for AzureFrontDoor-Cdn, mandatory for access certs from Key Vault. The Object ID is copied from an existing KeyVault which had this access policy added
  "azure-frontdoor-cdn" = {
    tenant_id = ""
    object_id = "a84f0a79-b9df-4c8f-bc8d-309eed0402b4"
    certificate_permissions = [
      "Get"
    ]
    key_permissions = [
      "Get", "List", "Delete", "Create", "Purge"
    ]
    secret_permissions = [
      "Get", "List", "Delete", "Set", "Purge"
    ]
    storage_permissions = [
      "Get", "List", "Delete", "Set"
    ]
  }
  # Access Policy for AzureFrontDoor, mandatory to access certs from the Key Vault
  "azure-frontdoor" = {
    tenant_id = ""
    object_id = "e344ee3c-527c-43cd-aa22-1645ed7b0b95"
    certificate_permissions = [
      "Get"
    ]
    key_permissions = [
      "Get", "List", "Delete", "Create", "Purge"
    ]
    secret_permissions = [
      "Get", "List", "Delete", "Set", "Purge"
    ]
    storage_permissions = [
      "Get", "List", "Delete", "Set"
    ]
  }
}

certificates = {
  "azurecdn-dsahoo-com" = {
    certificate_name = "azurecdn.dsahoo.com.pfx"
    password         = ""
  }
}

secrets = {
  db_name  = "vanilla-vc-dev"
  password = "my-secret-password"
  username = "my-db-username"
}

# Web app
container_registry = {
  name    = "nexientacr000"
  rg_name = "deb-test-devops"
}

application_stack = "docker"

docker_image_name = "python-docker"
docker_image_tag  = "1.2.0"

application_settings = {
  provisioner = "Terraform"
  # WEBSITES_PORT = 5000
}

site_config = {
  health_check_path = "/"
}

http_logs_file_system = {
  retention_in_days = 14
  retention_in_mb   = 100
}

deployment_slots = ["stage"]

enable_system_managed_identity = true

storage_mounts = {
  assets = {
    share_name   = "assets"
    mount_type   = "AzureFiles"
    mount_path   = "/var/assets"
    account_name = ""
    access_key   = ""
  }
  logs = {
    share_name   = "logs"
    mount_type   = "AzureFiles"
    mount_path   = "/var/logs"
    account_name = ""
    access_key   = ""
  }
}

# Front door
backend_pool = {
  backends = {
    eastus = {
      enabled    = true
      http_port  = 80
      https_port = 443
      priority   = 1
      weight     = 50
    }
    westus = {
      enabled    = true
      http_port  = 80
      https_port = 443
      priority   = 1
      weight     = 50
    }
  }
  health_probe = {
    # Can only be disabled when there is 1 backend
    enabled      = true
    path         = "/"
    name         = "dummy-health-probe"
    probe_method = "GET"
    protocol     = "Https"
  }
  load_balancing = {
    name                        = "dummy-load-balancer"
    sample_size                 = 4
    successful_samples_required = 2
    additional_latency_ms       = 0
  }

}
forwarding_configurations = {
  cache_duration                        = null
  cache_enabled                         = false
  cache_query_parameter_strip_directive = "StripAll"
  cache_query_parameters                = []
  cache_use_dynamic_compression         = false
  custom_forwarding_path                = ""
  forwarding_protocol                   = "MatchRequest"

}

frontend_endpoints = {
  azurecdn-dsahoo-com = {
    create_record = false
    endpoint_name = "azurecdn-dsahoo-com"
    record_name   = "azurecdn.dsahoo.com"
    record_type   = "CNAME"
    dns_zone      = null
    dns_rg        = null
  }
}

custom_user_managed_certs = {
  "azurecdn-dsahoo-com" = {
    # pragma: allowlist secret
    certificate_secret_name    = "azurecdn-dsahoo-com"
    certificate_secret_version = ""
    https_enabled              = true
  }
}
