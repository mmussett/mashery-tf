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
