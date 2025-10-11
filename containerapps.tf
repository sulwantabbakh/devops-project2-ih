# -----------------------------
# Log Analytics Workspace
# -----------------------------
resource "azurerm_log_analytics_workspace" "burgerbuilder_law" {
  name                = "burgerbuilder-law"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# -----------------------------
# Managed Identity
# -----------------------------
resource "azurerm_user_assigned_identity" "aca_identity" {
  name                = "burgerbuilder-aca-identity"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# -----------------------------
# Container Apps Environment (private)
# -----------------------------
resource "azurerm_container_app_environment" "burgerbuilder_env" {
  name                           = "burgerbuilder-aca-env"
  location                       = azurerm_resource_group.main.location
  resource_group_name            = azurerm_resource_group.main.name
  infrastructure_subnet_id       = azurerm_subnet.aca.id
  internal_load_balancer_enabled = true
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.burgerbuilder_law.id

  workload_profile {
    name                  = "default"
    workload_profile_type = "D4"
    minimum_count         = 1
    maximum_count         = 3
  }

  tags = {
    project     = "BurgerBuilder"
    environment = "development"
  }
}

# -----------------------------
# Frontend Container App
# -----------------------------
resource "azurerm_container_app" "frontend" {
  name                         = "burgerbuilder-frontend"
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = azurerm_container_app_environment.burgerbuilder_env.id
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aca_identity.id]
  }

  registry {
    server   = "burgerbuilderacr.azurecr.io"
    identity = azurerm_user_assigned_identity.aca_identity.id
  }

  ingress {
    external_enabled = false
    target_port      = 80
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    container {
      name   = "frontend"
      image  = "burgerbuilderacr.azurecr.io/burgerbuilder-frontend:latest"
      cpu    = 1.0
      memory = "2.0Gi"

      env {
        name  = "REACT_APP_API_URL"
        value = "http://burgerbuilder-backend"
      }
    }
  }

  tags = {
    app         = "burgerbuilder"
    component   = "frontend"
    environment = "development"
  }
}

# -----------------------------
# Backend Container App
# -----------------------------
resource "azurerm_container_app" "backend" {
  name                         = "burgerbuilder-backend"
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = azurerm_container_app_environment.burgerbuilder_env.id
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aca_identity.id]
  }

  registry {
    server   = "burgerbuilderacr.azurecr.io"
    identity = azurerm_user_assigned_identity.aca_identity.id
  }

  ingress {
    external_enabled = false
    target_port      = 8080
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    container {
      name   = "backend"
      image  = "burgerbuilderacr.azurecr.io/burgerbuilder-backend:latest"
      cpu    = 1.0
      memory = "2.0Gi"

      env {
        name  = "DATABASE_URL"
        value = "Server=tcp:burgerbuilder-sqlserver.privatelink.database.windows.net,1433;Database=burgerbuilder-db;User ID=sqladminuser;Password=StrongPassword123!;Encrypt=true;Connection Timeout=30;"
      }
    }
  }

  tags = {
    app         = "burgerbuilder"
    component   = "backend"
    environment = "development"
  }
}
