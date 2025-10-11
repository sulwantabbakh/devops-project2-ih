# -----------------------------
# Public IP (for App Gateway)
# -----------------------------
resource "azurerm_public_ip" "burgerbuilder_appgw_pip" {
  name                = "burgerbuilder-appgw-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Project     = "BurgerBuilder"
    Environment = "Production"
    Owner       = "Selwan"
  }
}

# -----------------------------
# Application Gateway (WAF v2)
# -----------------------------
resource "azurerm_application_gateway" "burgerbuilder_appgw" {
  name                = "burgerbuilder-appgw"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Use detached WAF policy
  firewall_policy_id = azurerm_web_application_firewall_policy.burgerbuilder_waf_policy.id

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  # Enforce modern TLS
  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101"
  }

  # HTTPS certificate (public listener)
  ssl_certificate {
    name     = "burgerbuilder-cert"
    data     = filebase64("${path.module}/certs/burgerbuilder-cert.pfx")
    password = var.cert_password
  }

  # Gateway IP configuration
  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = azurerm_subnet.appgw.id
  }

  # Frontend ports
  frontend_port {
    name = "frontendPort"
    port = 80
  }

  frontend_port {
    name = "httpsPort"
    port = 443
  }

  # Frontend IP config
  frontend_ip_configuration {
    name                 = "frontendPublicIp"
    public_ip_address_id = azurerm_public_ip.burgerbuilder_appgw_pip.id
  }

  # -----------------------------
  # Backend Address Pools (Container Apps FQDNs)
  # -----------------------------
  backend_address_pool {
    name  = "frontendPool"
    fqdns = [azurerm_container_app.frontend.ingress[0].fqdn]
  }

  backend_address_pool {
    name  = "backendPool"
    fqdns = [azurerm_container_app.backend.ingress[0].fqdn]
  }

  # -----------------------------
  # Health Probes (INTERNAL HTTP)
  # -----------------------------
  # Frontend (Nginx/static) over HTTP:80
  probe {
    name                = "frontendProbe"
    protocol            = "Http"
    path                = "/"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    # Use host header from backend settings (needed for ACA FQDN)
    pick_host_name_from_backend_http_settings = true
  }

  # Backend (Spring Boot) over HTTP:8080
  probe {
    name                                      = "backendProbe"
    protocol                                  = "Http"
    path                                      = "/actuator/health"
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true
  }

  # -----------------------------
  # Backend HTTP Settings (INTERNAL HTTP)
  # -----------------------------
  # Frontend app listens on port 80 (HTTP)
  backend_http_settings {
    name                                = "frontendHttpSetting"
    port                                = 80
    protocol                            = "Http"
    request_timeout                     = 30
    cookie_based_affinity               = "Disabled"
    pick_host_name_from_backend_address = true
    probe_name                          = "frontendProbe"
  }

  # Backend app listens on port 8080 (HTTP)
  backend_http_settings {
    name                                = "backendHttpSetting"
    port                                = 8080
    protocol                            = "Http"
    request_timeout                     = 30
    cookie_based_affinity               = "Disabled"
    pick_host_name_from_backend_address = true
    probe_name                          = "backendProbe"
  }

  # -----------------------------
  # Listeners
  # -----------------------------
  # Port 80 (only to redirect -> 443)
  http_listener {
    name                           = "httpListener"
    frontend_ip_configuration_name = "frontendPublicIp"
    frontend_port_name             = "frontendPort"
    protocol                       = "Http"
  }

  # Port 443 (TLS terminated here)
  http_listener {
    name                           = "httpsListener"
    frontend_ip_configuration_name = "frontendPublicIp"
    frontend_port_name             = "httpsPort"
    protocol                       = "Https"
    ssl_certificate_name           = "burgerbuilder-cert"
  }

  # -----------------------------
  # URL path map (routing)
  # -----------------------------
  url_path_map {
    name = "pathBasedRouting"

    # / -> frontend
    default_backend_address_pool_name  = "frontendPool"
    default_backend_http_settings_name = "frontendHttpSetting"

    # /api/* -> backend
    path_rule {
      name                       = "apiRule"
      paths                      = ["/api/*"]
      backend_address_pool_name  = "backendPool"
      backend_http_settings_name = "backendHttpSetting"
    }

    # Optional: expose actuator for health checks (same backend settings)
    path_rule {
      name                       = "actuatorRule"
      paths                      = ["/actuator/*"]
      backend_address_pool_name  = "backendPool"
      backend_http_settings_name = "backendHttpSetting"
    }
  }

  # -----------------------------
  # Redirect HTTP → HTTPS
  # -----------------------------
  redirect_configuration {
    name                 = "redirectToHttps"
    redirect_type        = "Permanent"
    target_listener_name = "httpsListener"
    include_path         = true
    include_query_string = true
  }

  request_routing_rule {
    name                        = "redirectHttpToHttps"
    rule_type                   = "Basic"
    http_listener_name          = "httpListener"
    redirect_configuration_name = "redirectToHttps"
    priority                    = 100
  }

  # -----------------------------
  # HTTPS path-based rule (main)
  # -----------------------------
  request_routing_rule {
    name               = "pathBasedRuleHttps"
    rule_type          = "PathBasedRouting"
    http_listener_name = "httpsListener"
    url_path_map_name  = "pathBasedRouting"
    priority           = 200
  }

  tags = {
    Project     = "BurgerBuilder"
    Environment = "Production"
    Owner       = "Selwan"
  }
}
