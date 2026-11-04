# Provider
terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 5.0.0"
    }

  }
}

provider "azurerm" {
  features {}
}

# Variables
variable "location" {
  description = "Region"
  type        = string
  default     = "southeastasia"

}

variable "crawl4ai_api_token" {
  description = "Crawl4AI API Token"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.crawl4ai_api_token) >= 32
    error_message = "Crawl4AI API Token must be at least 32 characters long."
  }
}

# RG
resource "azurerm_resource_group" "crawl4ai" {
  name     = "rg-crawl4ai"
  location = var.location
}

# Container App Environment (Consumption)
resource "azurerm_container_app_environment" "crawl4ai" {
  name                = "cae-crawl4ai"
  location            = azurerm_resource_group.crawl4ai.location
  resource_group_name = azurerm_resource_group.crawl4ai.name
}

# Azure Container App (Crawl4AI)
resource "azurerm_container_app" "crawl4ai" {
  name                         = "ca-crawl4ai"
  resource_group_name          = azurerm_resource_group.crawl4ai.name
  container_app_environment_id = azurerm_container_app_environment.crawl4ai.id
  revision_mode                = "Single"

  secret {
    name  = "crawl4ai-api-token"
    value = var.crawl4ai_api_token
  }

  template {
    min_replicas = 0
    max_replicas = 1

    container {
      name   = "crawl4ai"
      image  = "unclecode/crawl4ai:0.9.5"
      cpu    = "2"
      memory = "4Gi"

      env {
        name        = "CRAWL4AI_API_TOKEN"
        secret_name = "crawl4ai-api-token"
      }

      startup_probe {
        transport               = "HTTP"
        port                    = 11235
        path                    = "health"
        interval_seconds        = 5
        timeout                 = 3
        failure_count_threshold = 3
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = 11235
    transport        = "http"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

}

# Output
output "crawl4ai_url" {
  description = "Crawl4AI URL"
  value       = "https://${azurerm_container_app.crawl4ai.ingress[0].fqdn}"
}
