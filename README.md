Here’s a **detailed Wiki** explaining the Terraform and GitHub Actions setup for deploying **Azure Container Registry (ACR)** and **Azure Kubernetes Service (AKS)**. This guide breaks down each piece step-by-step for clarity and understanding.

---

# **Deploying ACR and AKS Using Terraform and GitHub Actions**

## **Introduction**
This guide automates the creation of an Azure Container Registry (ACR) and an Azure Kubernetes Service (AKS) cluster using **Terraform**. The infrastructure is deployed through a **GitHub Actions workflow**. This setup is perfect for managing scalable infrastructure for deploying and managing containerized applications.

---

## **1. Terraform Overview**

**Terraform** is an Infrastructure-as-Code (IaC) tool that allows you to define and provision cloud resources using declarative configuration files. The main files in Terraform are:

- **main.tf**: Defines the resources to be created.
- **variables.tf**: Contains variable definitions for flexibility.
- **outputs.tf**: Outputs information about created resources.

### **Terraform Key Components**
1. **Provider**: Specifies the cloud platform (e.g., Azure).
2. **Resources**: Represents the services being created (e.g., ACR, AKS).
3. **Variables**: Allows dynamic inputs for reusable configurations.
4. **Outputs**: Exposes key information about created resources for later use.

---

## **2. Terraform Configuration Files**

### **main.tf**
This file contains the primary configuration for creating ACR and AKS.

#### **1. Terraform Block**
```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.0.0"
}
```
- **Purpose**:
  - Specifies the `azurerm` provider for Azure.
  - Ensures a compatible Terraform version.

#### **2. Provider Block**
```hcl
provider "azurerm" {
  features {}
}
```
- **Purpose**:
  - Configures the Azure provider for managing resources.
  - The `features {}` block is required, but it can remain empty.

#### **3. Resource Group**
```hcl
resource "azurerm_resource_group" "rg" {
  name     = "rg-aks-acr-terraform"
  location = var.location
}
```
- **Purpose**: Creates a resource group named `rg-aks-acr-terraform` in the specified location.
- **Key Parameters**:
  - **`name`**: The name of the resource group.
  - **`location`**: The Azure region (e.g., `East US`) set via the `variables.tf` file.

#### **4. Azure Container Registry**
```hcl
resource "azurerm_container_registry" "acr" {
  name                = "acrterraformexample"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true

  tags = {
    environment = "dev"
  }
}
```
- **Purpose**: Creates a container registry for storing Docker images.
- **Key Parameters**:
  - **`name`**: A globally unique name for the registry.
  - **`admin_enabled`**: Enables admin access for simplified image pushing and pulling.

#### **5. Azure Kubernetes Service**
```hcl
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-terraform-cluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "aksterraformexample"

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
```
- **Purpose**: Creates an AKS cluster to deploy and manage containerized applications.
- **Key Components**:
  - **`default_node_pool`**: Defines the cluster nodes (count and VM size).
  - **`identity`**: Assigns a system-managed identity for resource access.

#### **6. Role Assignment**
```hcl
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}
```
- **Purpose**: Grants the AKS cluster permissions to pull images from the ACR.
- **Key Parameters**:
  - **`role_definition_name`**: Defines the role (`AcrPull` for image pulling).
  - **`principal_id`**: Links the AKS identity to the ACR.

---

### **variables.tf**
```hcl
variable "location" {
  default = "East US"
}
```
- **Purpose**: Allows dynamic assignment of the Azure region.

---

### **outputs.tf**
```hcl
output "acr_name" {
  value = azurerm_container_registry.acr.name
}

output "aks_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}
```
- **Purpose**: Exposes key resource details (ACR name, AKS name, resource group) for later use.

---

## **3. GitHub Actions Workflow**

### **Overview**
The GitHub Actions workflow automates the deployment process using Terraform.

#### **Trigger Conditions**
```yaml
on:
  push:
    branches:
      - main
  workflow_dispatch:
```
- **Purpose**: Runs the workflow on:
  - Pushes to the `main` branch.
  - Manual triggers via GitHub.

#### **Job: Deploy ACR and AKS**
```yaml
jobs:
  deploy-acr-aks:
    name: Deploy ACR and AKS
    runs-on: ubuntu-latest
```
- **Purpose**: Defines a job to deploy infrastructure on an Ubuntu runner.

---

#### **Steps in the Job**

1. **Checkout the Repository**
```yaml
- name: Checkout repository
  uses: actions/checkout@v3
```
- **Purpose**: Clones the repository to access Terraform files.

2. **Authenticate with Azure CLI**
```yaml
- name: Authenticate with Azure CLI
  run: az login --use-device-code
```
- **Purpose**: Authenticates with Azure using device code authentication.

3. **Set Up Terraform**
```yaml
- name: Set up Terraform
  uses: hashicorp/setup-terraform@v2
  with:
    terraform_version: 1.5.6
```
- **Purpose**: Installs and configures Terraform on the runner.

4. **Run Terraform Commands**
   - **Initialize Terraform**:
     ```yaml
     - name: Terraform Init
       run: terraform -chdir=terraform init
     ```
     - Initializes Terraform and downloads required providers.

   - **Plan Infrastructure**:
     ```yaml
     - name: Terraform Plan
       run: terraform -chdir=terraform plan
     ```
     - Prepares an execution plan, showing changes to be made.

   - **Apply Changes**:
     ```yaml
     - name: Terraform Apply
       run: terraform -chdir=terraform apply -auto-approve
     ```
     - Creates the infrastructure automatically without prompting for approval.

---

## **4. Key Learnings**

1. **Terraform**:
   - Break configurations into logical files (`main.tf`, `variables.tf`, `outputs.tf`) for readability.
   - Use `azurerm` resources to define Azure infrastructure components.

2. **GitHub Actions**:
   - Automate Terraform workflows using pre-built actions.
   - Device code authentication allows secure and interactive Azure login.

3. **Infrastructure Integration**:
   - Role assignments link ACR and AKS for seamless container image pulling.

---

## **5. Summary**

This setup provides:
- An automated pipeline for provisioning ACR and AKS.
- A repeatable, scalable, and secure infrastructure using Terraform.
- CI/CD integration through GitHub Actions for consistent deployments.

You can now focus on deploying and managing your applications without manual intervention! 🚀

Other Information for naming convention below:
The **`resource "azurerm_role_assignment" "aks_acr_pull"`** line in Terraform follows a specific **naming convention** and structure defined by Terraform's configuration syntax. Let's break it down:

---

### **1. General Syntax**
The general format for defining a resource in Terraform is:

```hcl
resource "<resource_type>" "<resource_name>" {
  # Configuration for the resource
}
```

- **`<resource_type>`**: Specifies the type of resource you want to create (e.g., `azurerm_role_assignment`).
- **`<resource_name>`**: A logical name you assign to this resource in your Terraform code for reference.

---

### **2. Explanation of Each Component**

#### **`resource`**
- This keyword tells Terraform that you are defining a resource block, which represents a real-world infrastructure component.

#### **`azurerm_role_assignment`** (Resource Type)
- This is the **type** of resource you are creating.
- In this case, `azurerm_role_assignment` is used to create a **role assignment** in Azure, which defines permissions for a principal (like a user, group, or managed identity) on a specific resource.
- Terraform knows how to create this resource because the `azurerm` provider (Azure Resource Manager) is included.

#### **`aks_acr_pull`** (Resource Name)
- This is the **logical name** you assign to this specific role assignment within your Terraform configuration.
- It is a user-defined name used for internal referencing in Terraform. For example:
  - You can reference this role assignment later using `azurerm_role_assignment.aks_acr_pull.id`.

---

### **3. Why This Naming Convention?**
The naming convention **`azurerm_role_assignment` "aks_acr_pull"`** is used for clarity and structure:
1. **Resource Type (`azurerm_role_assignment`)**:
   - Clearly states what type of resource is being created.
   - Ensures that Terraform knows how to manage the resource.

2. **Logical Name (`aks_acr_pull`)**:
   - Indicates the specific purpose of the resource:
     - **`aks`**: Refers to the Azure Kubernetes Service (AKS).
     - **`acr`**: Refers to the Azure Container Registry (ACR).
     - **`pull`**: Specifies the action being enabled, i.e., granting the AKS cluster permission to pull images from ACR.

By following this convention, the purpose of the resource is easily understood by anyone reading the code.

---

### **4. What Does This Resource Do?**
The **`azurerm_role_assignment` "aks_acr_pull"`** block configures a **role assignment** to allow the AKS cluster to pull container images from the ACR.

#### Key Elements in the Role Assignment:
1. **`scope`**:
   - Specifies the resource (in this case, the ACR) that the role assignment applies to.

2. **`role_definition_name`**:
   - The name of the role being assigned (`AcrPull`), which grants permissions to pull images from the ACR.

3. **`principal_id`**:
   - Specifies the identity (the AKS cluster's kubelet identity) that will receive the role assignment.

---

### **5. Example Block**
Here’s the full resource definition again for reference:

```hcl
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}
```

#### What Happens Here:
- **Scope**: Applies the role assignment to the ACR (`azurerm_container_registry.acr.id`).
- **Role**: Assigns the `AcrPull` role, which allows pulling container images.
- **Principal**: Grants this role to the AKS cluster's kubelet identity, enabling it to access the ACR securely.

---

### **6. Benefits of This Convention**
- **Clarity**: Makes it clear what resource is being created and for what purpose.
- **Readability**: Logical names like `aks_acr_pull` make it easier for team members to understand the resource’s purpose.
- **Reusability**: You can create multiple resources of the same type with different logical names (e.g., `aks_admin_role` or `dev_acr_pull`).
- **Internal Referencing**: The logical name allows you to reference this resource within other parts of your Terraform code (e.g., outputs or dependencies).

---

### **7. Summary**
- **`resource`**: Defines a resource block in Terraform.
- **`azurerm_role_assignment`**: Specifies the type of resource, a role assignment in Azure.
- **`aks_acr_pull`**: Logical name for internal referencing and clarity.
- **Purpose**: Assigns the `AcrPull` role to the AKS cluster for secure image pulling from the ACR.

By adhering to this convention, you ensure a structured, readable, and maintainable Terraform configuration!

