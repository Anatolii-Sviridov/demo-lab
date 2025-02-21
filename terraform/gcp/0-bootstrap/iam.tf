/*
    Service Account to provision infrastructure
    NB: Verify that google_project_iam_policy is not used in current GCP Org before proceeding
*/

resource "google_service_account" "terraform_service_account" {
  project = var.project_id

  account_id   = "terraform-sa"
  display_name = "Terraform Service Account"
}

resource "google_project_iam_member" "project_sa_terraform_owner" {
  project = var.project_id

  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.terraform_service_account.email}"
  depends_on = [
    google_service_account.terraform_service_account
  ]
}
