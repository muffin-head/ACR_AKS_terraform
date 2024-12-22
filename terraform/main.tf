terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-aks-acr-terraformv1"
  location = var.location
}

# Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "acrterraformSepsisStreamingv1" # Must be globally unique
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic" # Options: Basic, Standard, Premium

  admin_enabled = true # Enable admin access for ACR
  tags = {
    environment = "dev"
  }
}

# Azure Kubernetes Service
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-terraform-clusterv1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "aksterraformSepsisStreamingv1"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "dev"
  }
}

# Role Assignment for AKS to Pull Images from ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

# Output AKS Cluster JSON
output "aks_cluster_json" {
  value = jsonencode(azurerm_kubernetes_cluster.aks)
}

# Save AKS Details to a Local File
resource "local_file" "aks_cluster_details" {
  content  = jsonencode(azurerm_kubernetes_cluster.aks)
  filename = "${path.module}/aks-cluster-details.json"
}
