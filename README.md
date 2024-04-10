[![terraform-github-push-actions](https://github.com/mmussett/mashery-tf/actions/workflows/tf-push-action.yml/badge.svg)](https://github.com/mmussett/mashery-tf/actions/workflows/tf-push-action.yml)

# Using Terraform for IaaC with APIM

## version 0.1

#

## Building and Installation

### Pre-requisites

The solution was tested on Ubuntu Linux 22.04 but should in theory work on Mac or Windows.

The following tools are required to be installed on your machine in order to have a working solution:

- golang SDK (tested with go 1.22.1)
- Hashicorp Terraform pre-compiled binary (see <https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli>)
- Hashicorp Vault pre-compiled binary (see <https://developer.hashicorp.com/vault/docs/install>)
- jq (see <https://jqlang.github.io/jq/download/>)
- make
- gh

You will also need to download the following github repositories from Aliaksei Yanchuk…

- [aliakseiyanchuk/mashery-v3-go-client](https://github.com/aliakseiyanchuk/mashery-v3-go-client)
- [aliakseiyanchuk/mashery-terraform-provider](https://github.com/aliakseiyanchuk/mashery-terraform-provider)
- [aliakseiyanchuk/hcvault-mashery-api-auth](https://github.com/aliakseiyanchuk/hcvault-mashery-api-auth)

Please ensure that the Mashery v3 Go Client repository has been downloaded and sits alongside the provider repository e.g. $GOPATH/src

```
$ ls -ltr

drwxrwxr-x 14 mmussett mmussett 4096 Mar 21 09:18 mashery-v3-go-client
drwxrwxr-x 15 mmussett mmussett 4096 Mar 21 16:56 hcvault-mashery-api-auth
drwxrwxr-x 14 mmussett mmussett 4096 Mar 22 15:34 mashery-terraform-provider

```


## Mashery v3 Go Client

The Mashery v3 Go Client has been written by Aliaksei Yanchuk under a MIT License model and is available for download from his Github repository here: <https://github.com/aliakseiyanchuk/mashery-v3-go-client>

Ensure that all vendor libraries are downloaded to your local golang cache by running the following:

```
$ go mod tidy
$ go mod vendor
```

Run make:

```
$ make
$ go mod vendor
```

## Mashery Terraform Provider

The Mashery Terraform Provider has been written by Aliaksei Yanchuk under a MIT License model and is available for download from his Github repository here: <https://github.com/aliakseiyanchuk/mashery-terraform-provider>

Instructions within the project for building from source are provided. You may need to modify the Makefile to set the OS_ARCH to your environment e.g. OS_ARCH=linux_amd64

Ensure that all vendor libraries are downloaded to your local golang cache by running the following:

```
$ go mod tidy
$ go mod vendor
```

Run make to build and install the plugin:

```
$ make

go build -o terraform-provider-mashery
mkdir -p ~/.terraform.d/plugins/github.com/aliakseiyanchuk/mashery/0.5/linux_amd64
mv terraform-provider-mashery ~/.terraform.d/plugins/github.com/aliakseiyanchuk/mashery/0.5/linux_amd64
```

## Hashicorp Vault Plugin

The Hashicorp Vault Plugin been written by Aliaksei Yanchuk under a MIT License model and is available for download from his Github repository here: <https://github.com/aliakseiyanchuk/hcvault-mashery-api-auth>
The Hashicorp Vault plugin configures Vault to be able to retrieve OAuth tokens from APIM.
Run make to build and install the plugin:

```
$ make install

go build -o hcvault-mashery-api-auth_v0.5 cmd/main.go
mkdir -p ./vault/plugins
mv hcvault-mashery-api-auth_v0.5 ./vault/plugins
```

# Running

## Starting Hashicorp Vault

A development Vault Server can be launched from the Makefile using the launch_dev_mode target.

```
$ make launch_dev_mode
```

Example: 
```
$ make launch_dev_mode

./scripts/killDevVault.sh
mkdir -p ./vault/plugins
find ./vault/plugins -type f -exec /bin/rm {} \\;
go build -o ./vault/plugins/hcvault-mashery-api-auth_v0.5 cmd/main.go
vault server -dev -dev-listen-address=0.0.0.0:8200 -dev-root-token-id=root -dev-plugin-dir=./vault/plugins -log-level=trace > ./vault/dev-server.log 2>&1 &
\# Let the server start-up before proceeding with the mount
sleep 5
echo root | vault login -address=<http://localhost:8200/> -
WARNING! The VAULT_TOKEN environment variable is set! The value of this
variable will take precedence; if this is unwanted please unset VAULT_TOKEN or update its value accordingly.

Success! You are now authenticated. The token information displayed below is already stored in the token helper. You do NOT need to run "vault login" again. Future Vault requests will automatically use this token.

Key Value
--- -----
token root
token_accessor <REDACTED>
token_duration ∞
token_renewable false
token_policies ["root"]
identity_policies []
policies ["root"]
vault secrets enable -address=<http://localhost:8200/> -path=mash-auth \
  -allowed-response-headers="X-Total-Count" \
  -allowed-response-headers="X-Mashery-Responder" \
  -allowed-response-headers="X-Server-Date" \
  -allowed-response-headers="X-Proxy-Mode" \
  -allowed-response-headers="WWW-Authenticate" \
  -allowed-response-headers="X-Mashery-Error-Code" \
  -allowed-response-headers="X-Mashery-Responder" \

hcvault-mashery-api-auth_v0.5

Success! Enabled the hcvault-mashery-api-auth_v0.5 secrets engine at: mash-auth/
vault write -address=<http://localhost:8200/> mash-auth/roles/demoRole area_id=abc area_nid=10 username=user password=password api_key=apiKey secret=secret
Success! Data written to: mash-auth/roles/demoRole
vault policy write -address=<http://localhost:8200/> agent-mcc ./samples/agent/grant_demoRole_policy.hcl
Success! Uploaded policy: agent-mcc
vault auth enable -address=<http://localhost:8200/> approle
Success! Enabled approle auth method at: approle/
vault write -address=<http://localhost:8200/> auth/approle/role/agent-demoRole token_policies=agent-mcc
Success! Data written to: auth/approle/role/agent-demoRole
if \[ ! -d ./.secrets \]; then mkdir .secrets > /dev/null; fi
vault read -address=<http://localhost:8200/> -format=json auth/approle/role/agent-demoRole/role-id | jq -r .data.role_id > ./.secrets/role-id.txt
vault write -address=<http://localhost:8200/> -format=json -f auth/approle/role/agent-demoRole/secret-id | jq -r .data.secret_id > ./.secrets/secret-id.txt
```


To interact with Vault you need to set the following environment variables:

```
$ export VAULT_ADDR='<http://127.0.0.1:8200>'
$ export VAULT_TOKEN=root
```


The VAULT_TOKEN is a shared-secret between the CLI and the Server.

Once the Vault server has started you can validate by running the vault status CLI.

```
$ vault status
```


Example:

```
$ vault status

Key Value
--- -----
Seal Type shamir
Initialized true
Sealed false
Total Shares 1
Threshold 1
Version 1.15.6
Build Date 2024-02-28T17:07:34Z
Storage Type inmem
Cluster Name vault-cluster-c6fb586f
Cluster ID db5eda68-6647-afc3-4e07-c5dcd538f108
HA Enabled false

```

## Configuring Hashicorp Vault Role

Once the Vault Server has started successfully the Mashery Auth Secrets Engine must be configured with the necessary parameters to allow it to request authorisation tokens from Mashery Token API.

You will need the following information to proceed:

- Mashery API Key
- Mashery API Secret
- Mashery Username
- Mashery Password
- Mashery UUID

You will need to register for access to the Mashery Platform APIs here : <https://developer.mashery.com/member/register>

To setup the Vault Role issue the following vault write command:

```
$ vault write mash-auth/roles/demo api_key=<api_key> secret=<api_secret> username=<username> password=<password> area_id=<area_uuid>
```

You can verify that Vault is able to issue new Mashery OAuth Tokens by issuing a vault read command:


```
$ vault read mash-auth/roles/demo/token
```

Example:

```
$ vault read mash-auth/roles/demo/token

Key Value
--- -----

access_token 2q2eempr48h\*\*\*\*d5xtq7my
expiry 2024-03-22T18:56:37Z
expiry_epoch 1711133797
qps 2
token_time_remaining 3600

```


## Terraform Setup

To use the Mashery Terraform Provider you need to configure the provider like such that the provider knows the Vault url and role. E.g.

### variables.tf

```
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


```

#### provider.tf

```
terraform {
  required_providers {
    mashery = {
      version = "0.5"
      source = "github.com/aliakseiyanchuk/mashery"
    }
  }
}

provider "mashery" {
  vault_addr = var.vault_url
  vault_mount = "mash-auth"
  role = var.vault_role
  qps = 1
}

```


To execute any Terraform scripts you must make sure that the Vault Token is set in the environment.

```
export TF_MASHERY_VAULT_TOKEN=<shared-token>
```


### Creating an API Service and Endpoint

#### service.tf


```
data "mashery_organization" "tf_org" {
  search = {
    "name": "Terraform"
  }
}

resource "mashery_service" "srv" {
  name_prefix="tf-debug"
  iodocs_accessed_by = toset(\[data.mashery_role.internal_dev.id\])
  organization = data.mashery_organization.tf_org.id
  description = "this service was created by Terraform Mashery Provider"
  version = "1.0"
  qps_limit_overall = 10
}

resource "mashery_service_endpoint" "endp" {
  # An endpoint belongs to the service
  service_ref = mashery_service.srv.id
  name = "service-endpoint-1"
  request_authentication_type = "apiKey"
  developer_api_key_locations = \["request-header"\]
  request_path_alias = "/echo-get"
  supported_http_methods = \["get"\]
  system_domains = \["postman-echo.com"\]
  public_domains = \["presalesemeanorth2.api.mashery.com"\]
  developer_api_key_field_name = "X-Api-Key"
  traffic_manager_domain = var.traffic_manager_domain
  inbound_mutual_ssl_required = false
  inbound_ssl_required = false
  outbound_request_target_path = "/get"
  outbound_request_target_query_parameters = "a=b"
  outbound_transport_protocol = "http"
  connection_timeout_for_system_domain_request = 2
  connection_timeout_for_system_domain_response = 300
}

```


### Initialise Terraform

```
$ terraform init

Initializing the backend...

Initializing provider plugins...

- Reusing previous version of github.com/aliakseiyanchuk/mashery from the dependency lock file

- Using previously-installed github.com/aliakseiyanchuk/mashery v0.5.0

Terraform has been successfully initialized!
You may now begin working with Terraform. Try running "terraform plan" to see any changes that are required for your infrastructure. All Terraform commands should now work. 
If you ever set or change modules or backend configuration for Terraform, rerun this command to reinitialize your working directory. If you forget, other commands will detect it and remind you to do so if necessary

```


### Create Terraform Plan

```
$ terraform plan

data.mashery_organization.tf_org: Reading...

data.mashery_role.internal_dev: Reading...

data.mashery_application.root_app: Reading...

data.mashery_organization.tf_org: Read complete after 0s \[id=fcda4c29-de4b-43c9-bb3b-270966ed610e\]

data.mashery_role.internal_dev: Read complete after 1s \[id=21f2f09c-5212-4bae-a8b1-2bb122689ad2\]

data.mashery_application.root_app: Read complete after 2s \[id=eyJtaWQiOiIiLCJ1IjoibW11c3NldHQyMDE4MDQyNDEzMDQ2NDMiLCJhaWQiOiIwMTliNTZlYi05YmM4LTQwMDEtYTA5ZC1jMTQzMmZlOTU1MjYifQ==\]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:

\+ create

Terraform will perform the following actions:

\# mashery_service.srv will be created

\+ resource "mashery_service" "srv" {

\+ created = (known after apply)

\+ crossdomain_policy = (known after apply)

\+ description = "this service was created by Terraform Mashery Provider"

\+ editor_handle = (known after apply)

\+ id = (known after apply)

\+ iodocs_accessed_by = \[

\+ "21f2f09c-5212-4bae-a8b1-2bb122689ad2",

\]

\+ name = (known after apply)

\+ name_prefix = "tf-test"

\+ organization = "fcda4c29-de4b-43c9-bb3b-270966ed610e"

\+ qps_limit_overall = 10

\+ revision_number = (known after apply)

\+ rfc3986_encode = true

\+ robots_policy = (known after apply)

\+ service_id = (known after apply)

\+ updated = (known after apply)

\+ version = "1.0"

}

\# mashery_service_endpoint.endp will be created

\+ resource "mashery_service_endpoint" "endp" {

\+ allow_missing_api_key = false

\+ api_method_detection_locations = (known after apply)

\+ connection_timeout_for_system_domain_request = 2

\+ connection_timeout_for_system_domain_response = 300

\+ cookies_during_http_redirects_enabled = true

\+ created = (known after apply)

\+ developer_api_key_field_name = "X-Api-Key"

\+ developer_api_key_locations = \[

\+ "request-header",

\]

\+ drop_api_key_from_incoming_call = true

\+ force_gzip_of_backend_call = true

\+ forwarded_headers = (known after apply)

\+ gzip_passthrough_support_enabled = true

\+ high_security = true

\+ host_passthrough_included_in_backend_call_header = true

\+ id = (known after apply)

\+ inbound_mutual_ssl_required = false

\+ inbound_ssl_required = false

\+ name = "service-endpoint-1"

\+ number_of_http_redirects_to_follow = 0

\+ outbound_request_target_path = "/get"

\+ outbound_request_target_query_parameters = "a=b"

\+ outbound_transport_protocol = "http"

\+ public_domains = \[

\+ "presalesemeanorth2.api.mashery.com",

\]

\+ request_authentication_type = "apiKey"

\+ request_path_alias = "/echo/get"

\+ request_protocol = "rest"

\+ returned_headers = (known after apply)

\+ service_endpoint_id = (known after apply)

\+ service_ref = (known after apply)

\+ supported_http_methods = \[

\+ "get",

\]

\+ system_domains = \[

\+ "postman-echo.com",

\]

\+ traffic_manager_domain = "presalesemeanorth2.api.mashery.com"

\+ updated = (known after apply)

\+ use_system_domain_credentials = false

}

Plan: 2 to add, 0 to change, 0 to destroy.

Changes to Outputs:

\+ app_id = "eyJtaWQiOiIiLCJ1IjoibW11c3NldHQyMDE4MDQyNDEzMDQ2NDMiLCJhaWQiOiIwMTliNTZlYi05YmM4LTQwMDEtYTA5ZC1jMTQzMmZlOTU1MjYifQ=="

────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.

```


### Applying the Terraform Plan

```
$ terraform apply

data.mashery_application.root_app: Reading...

data.mashery_role.internal_dev: Reading...

data.mashery_organization.tf_org: Reading...

data.mashery_organization.tf_org: Read complete after 0s \[id=fcda4c29-de4b-43c9-bb3b-270966ed610e\]

data.mashery_application.root_app: Read complete after 0s \[id=eyJtaWQiOiIiLCJ1IjoibW11c3NldHQyMDE4MDQyNDEzMDQ2NDMiLCJhaWQiOiIwMTliNTZlYi05YmM4LTQwMDEtYTA5ZC1jMTQzMmZlOTU1MjYifQ==\]

data.mashery_role.internal_dev: Read complete after 1s \[id=21f2f09c-5212-4bae-a8b1-2bb122689ad2\]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:

\+ create

Terraform will perform the following actions:

\# mashery_service.srv will be created

\+ resource "mashery_service" "srv" {

\+ created = (known after apply)

\+ crossdomain_policy = (known after apply)

\+ description = "this service was created by Terraform Mashery Provider"

\+ editor_handle = (known after apply)

\+ id = (known after apply)

\+ iodocs_accessed_by = \[

\+ "21f2f09c-5212-4bae-a8b1-2bb122689ad2",

\]

\+ name = (known after apply)

\+ name_prefix = "tf-test"

\+ organization = "fcda4c29-de4b-43c9-bb3b-270966ed610e"

\+ qps_limit_overall = 10

\+ revision_number = (known after apply)

\+ rfc3986_encode = true

\+ robots_policy = (known after apply)

\+ service_id = (known after apply)

\+ updated = (known after apply)

\+ version = "1.0"

}

\# mashery_service_endpoint.endp will be created

\+ resource "mashery_service_endpoint" "endp" {

\+ allow_missing_api_key = false

\+ api_method_detection_locations = (known after apply)

\+ connection_timeout_for_system_domain_request = 2

\+ connection_timeout_for_system_domain_response = 300

\+ cookies_during_http_redirects_enabled = true

\+ created = (known after apply)

\+ developer_api_key_field_name = "X-Api-Key"

\+ developer_api_key_locations = \[

\+ "request-header",

\]

\+ drop_api_key_from_incoming_call = true

\+ force_gzip_of_backend_call = true

\+ forwarded_headers = (known after apply)

\+ gzip_passthrough_support_enabled = true

\+ high_security = true

\+ host_passthrough_included_in_backend_call_header = true

\+ id = (known after apply)

\+ inbound_mutual_ssl_required = false

\+ inbound_ssl_required = false

\+ name = "service-endpoint-1"

\+ number_of_http_redirects_to_follow = 0

\+ outbound_request_target_path = "/get"

\+ outbound_request_target_query_parameters = "a=b"

\+ outbound_transport_protocol = "http"

\+ public_domains = \[

\+ "presalesemeanorth2.api.mashery.com",

\]

\+ request_authentication_type = "apiKey"

\+ request_path_alias = "/echo/get"

\+ request_protocol = "rest"

\+ returned_headers = (known after apply)

\+ service_endpoint_id = (known after apply)

\+ service_ref = (known after apply)

\+ supported_http_methods = \[

\+ "get",

\]

\+ system_domains = \[

\+ "postman-echo.com",

\]

\+ traffic_manager_domain = "presalesemeanorth2.api.mashery.com"

\+ updated = (known after apply)

\+ use_system_domain_credentials = false

}

Plan: 2 to add, 0 to change, 0 to destroy.

Changes to Outputs:

\+ app_id = "eyJtaWQiOiIiLCJ1IjoibW11c3NldHQyMDE4MDQyNDEzMDQ2NDMiLCJhaWQiOiIwMTliNTZlYi05YmM4LTQwMDEtYTA5ZC1jMTQzMmZlOTU1MjYifQ=="

Do you want to perform these actions?

Terraform will perform the actions described above.

Only 'yes' will be accepted to approve.

Enter a value: yes

mashery_service.srv: Creating...

mashery_service.srv: Creation complete after 1s \[id=eyJzaWQiOiJ1ZjRlMmVuenk0eDR3cWtreWc2aDc5eWUifQ==\]

mashery_service_endpoint.endp: Creating...

mashery_service_endpoint.endp: Creation complete after 1s \[id=eyJzaWQiOiJ1ZjRlMmVuenk0eDR3cWtreWc2aDc5eWUiLCJlaWQiOiJ4dXV6bWRjYmIydGI1d3U1OXl2ZXV6bTUifQ==\]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

app_id = "eyJtaWQiOiIiLCJ1IjoibW11c3NldHQyMDE4MDQyNDEzMDQ2NDMiLCJhaWQiOiIwMTliNTZlYi05YmM4LTQwMDEtYTA5ZC1jMTQzMmZlOTU1MjYifQ=="
```


