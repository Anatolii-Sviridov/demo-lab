/*
    This code is to enable required APIs if project was created for us.
*/
locals {
  services = toset(var.required_apis)
}

resource "google_project_service" "enable_project_apis" {
  provider = google-beta
  for_each = local.services
  project =  var.project_id
  service = each.value
  depends_on = [
    google_service_account.terraform_service_account
  ]
}