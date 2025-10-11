############################################################
# Variables — SQL Admin Credentials
############################################################

variable "sql_admin_username" {
  description = "Administrator username for the SQL Server"
  type        = string
  default     = "sqladminuser"
}

variable "sql_admin_password" {
  description = "Administrator password for the SQL Server"
  type        = string
  sensitive   = true
  default     = "StrongPassword123!"
}

variable "cert_password" {
  description = "Password protecting the PFX certificate"
  type        = string
  sensitive   = true
}

variable "frontend_image" {
  description = "Frontend Docker image"
  default     = "burgerbuilderacr.azurecr.io/burgerbuilder-frontend:latest"
}

variable "backend_image" {
  description = "Backend Docker image"
  default     = "burgerbuilderacr.azurecr.io/burgerbuilder-backend:latest"
}
