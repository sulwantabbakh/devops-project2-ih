# ---------------------------------------------
# Azure WAF Policy (New model, replaces inline)
# ---------------------------------------------
resource "azurerm_web_application_firewall_policy" "burgerbuilder_waf_policy" {
  name                = "burgerbuilder-waf-policy"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  # Basic WAF settings — same as your old inline block
  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
  }

  # Use OWASP managed rules
  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }

  # Optional custom rule to allow health checks
  custom_rules {
    name      = "AllowHealthProbe"
    priority  = 1
    rule_type = "MatchRule"

    match_conditions {
      match_variables {
        variable_name = "RequestUri"
      }
      operator     = "Contains"
      match_values = ["/actuator/health"]
    }

    action = "Allow"
  }

  tags = {
    Environment = "Production"
    Project     = "BurgerBuilder"
    Owner       = "Selwan"
  }
}
