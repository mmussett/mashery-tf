data "mashery_application" "root_app" {
  search = {
    "tags" = "terraform-please-find-me"
  }
}

output "app_id" {
  value = data.mashery_application.root_app.id
}
