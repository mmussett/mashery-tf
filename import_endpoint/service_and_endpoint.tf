# ---------------------------------------------------------------------------------------------------
# Example of how to use the Terraform provider edit an existing endpoint in place.
# ---------------------------------------------------------------------------------------------------

# You need to establish a service to which this endpoint belongs first
data "mashery_service" "svc" {
  search = {
    "name" = var.service_name
  }
}

# To edit-in-place, you need to import the endpoint definition to be managed by Terraform
# to achieve this, you need to create the following minimal configuration. Note that
# you need to adjust the actual values to what you would like to have.
#
# Next, you need to import the endpoint to be managed by running the following command:
# terraform import STATE_ADDRESS /services/<service_id>/endpoints/<endpoint_id>
#
# In the case of this example:
# - the STATE_ADDR is mashery_service_endpoint.imported_endpoint
# - the import URL is easiest to be copy-pased from the Mashery control center where
#   you are looking at an

resource "mashery_service_endpoint" "imported_endpoint" {
  service_ref = data.mashery_service.svc.id
  name        = "echo-test"
  public_domains = ["presalesemeanorth2.api.mashery.com"]
  request_authentication_type = "oauth"
  request_path_alias = ""
  supported_http_methods = []
  system_domains = [ "postman-echo.com" ]
  traffic_manager_domain = ""
}

