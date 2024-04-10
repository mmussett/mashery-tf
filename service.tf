data "mashery_role" "internal_dev" {
  search = {
    "name": "API Manager"
  }
}

data "mashery_organization" "tf_org" {
  search = {
    "name": "Terraform"
  }
}

resource "mashery_service" "srv" {
  name="tf-test"
  iodocs_accessed_by = toset([data.mashery_role.internal_dev.id])
  organization = data.mashery_organization.tf_org.id
  description = "this service was created by Terraform Mashery Provider"
  version = "1.0"
  qps_limit_overall = 10
}

resource "mashery_service_endpoint" "endp" {
  # An endpoint belongs to the service
  service_ref                 = mashery_service.srv.id
  name                        = "service-endpoint-1"
  request_authentication_type = "apiKey"
  developer_api_key_locations = ["request-header"]
  request_path_alias          = "/v1/echo/get"
  supported_http_methods      = ["get"]
  system_domains              = ["postman-echo.com"]
  public_domains              = ["presalesemeanorth2.api.mashery.com"]
  developer_api_key_field_name = "X-Api-Key"

  traffic_manager_domain = var.traffic_manager_domain

  inbound_mutual_ssl_required = false
  inbound_ssl_required        = false

  outbound_request_target_path             = "/get"
  outbound_request_target_query_parameters = "a=b"
  outbound_transport_protocol              = "http"

  connection_timeout_for_system_domain_request = 2
  connection_timeout_for_system_domain_response = 300
}
