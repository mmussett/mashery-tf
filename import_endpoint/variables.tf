variable "vault_url" {
  default = "http://localhost:8200"
  description = "Vault URL to read data the data from; defaults to the development server."
}

variable "vault_role" {
  default = "demo"
  description = "Vault secret engine role to use"
}

variable "traffic_manager_domain" {
  default = "presalesemeanorth2.api.mashery.com"
  description = "Mashery Traffic Manager domain"
}

variable "service_name" {
  default = "echo-test"
  description = "Service name where an endpoint should be edited"
}

