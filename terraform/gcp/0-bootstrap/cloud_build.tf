data "google_secret_manager_secret_version" "github_pat_secret" {
  provider = google-beta
  project = var.project_id
  secret  = "cloubuild_github_pat"
  depends_on = [
      google_project_service.enable_project_apis
    ]
}

data "google_project" "cloudbuild_project_id" {
  project_id = var.project_id
  depends_on = [
      google_project_service.enable_project_apis
    ]
}

data "google_iam_policy" "сloudbuild_sa_secretAccessor" {
  binding {
    role = "roles/secretmanager.secretAccessor"
    members = ["serviceAccount:service-${data.google_project.cloudbuild_project_id.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"]
  }
  depends_on = [
      google_project_service.enable_project_apis
    ]
}

resource "google_secret_manager_secret_iam_policy" "cloudbuild_github_policy" {
  project = var.project_id
  secret_id = "projects/${data.google_project.cloudbuild_project_id.id}/secrets/cloubuild_github_pat"
  policy_data = data.google_iam_policy.сloudbuild_sa_secretAccessor.policy_data

  depends_on = [
      google_project_service.enable_project_apis
    ]
}

# Create connection to GitHub
resource "google_cloudbuildv2_connection" "cloudbuild_github_connection" {
  project = var.project_id
  location = var.region
  name = "github-connection"

  github_config {
    app_installation_id = var.cloudbuild_github_app_instalation_id
    authorizer_credential {
      oauth_token_secret_version = data.google_secret_manager_secret_version.github_pat_secret.id
    }
  }
  depends_on = [
      google_secret_manager_secret_iam_policy.cloudbuild_github_policy
    ]
}

## Add repo from GitHub
resource "google_cloudbuildv2_repository" "cloudbuild_github_repository" {
  project = var.project_id
  for_each = toset(var.github_repos)
  name = each.key
  location = var.region
  parent_connection = google_cloudbuildv2_connection.cloudbuild_github_connection.id
  remote_uri = "https://github.com/${var.github_org}/${each.key}.git"
  depends_on = [
      google_cloudbuildv2_connection.cloudbuild_github_connection
    ]
}
