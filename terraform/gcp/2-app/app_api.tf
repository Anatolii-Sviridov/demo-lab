# Cloudbuild for API
resource "google_cloudbuild_trigger" "api" {
  project  = var.project_id

  name        = "API"
  location = var.region
  description = "Trigger for API app"

  disabled = false
  filename = "apps/api/cloudbuild.yaml"
  included_files     = [
    "apps/api/**",
  ]

  repository_event_config {
    repository = "projects/${var.project_id}/locations/${var.region}/connections/github-connection/repositories/demo-lab"

    push {
      branch       = "^main$"
      invert_regex = false
    }
  }

  service_account = "projects/${var.project_id}/serviceAccounts/terraform-sa@${var.project_id}.iam.gserviceaccount.com"

  timeouts {}
}

locals {
  run_service_container_envs = [
    {
      name  = "DB_USER"
      value = google_sql_user.users.name
    },
    {
      name  = "DB_NAME"
      value = google_sql_database.main_database.name
    },
    {
      name  = "DB_HOST"
      value = google_sql_database_instance.postgres.ip_address.0.ip_address 
    },
    {
      name  = "GCP_PROJECT_ID"
      value = var.project_id
    }
  ]

  run_service_container_secrets = [
    {
      env_var_name = "DB_PASS"
      name         = google_secret_manager_secret.db_admin_password.name
    }
  ]
}

# CloudRun for api
resource "google_cloud_run_v2_service" "api" {
  name     = "api"
  location =  var.region
  project = var.project_id
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.api_service_account.email

    containers {
      name  = "api"
      image = "${var.region}-docker.pkg.dev/${var.project_id}/cloud-run-source-deploy/api:latest"
      #image = "us-docker.pkg.dev/cloudrun/container/hello"

      ports {
        container_port = 8080
        name = "http1"
      }

      volume_mounts {
        mount_path = "/cloudsql"
        name       = "cloudsql"
      }

      resources {
        cpu_idle  = true
        limits = {
          cpu    = "1000m"   # https://cloud.google.com/run/docs/configuring/services/cpu
          memory = "1Gi" # https://cloud.google.com/run/docs/configuring/services/memory-limits
        }
        startup_cpu_boost = true
      }

      dynamic "env" {
        for_each = local.run_service_container_envs
        content {
          name  = env.value.name
          value = env.value.value
        }
      }

      dynamic "env" {
        for_each = local.run_service_container_secrets
        content {
          name = env.value.env_var_name
          value_source {
            secret_key_ref {
              secret  = env.value.name
              version = "latest"
            }
          }
        }
      }

    }

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [
          google_sql_database_instance.postgres.connection_name
        ]
      }
    }

    vpc_access {
      egress    = "PRIVATE_RANGES_ONLY"
      network_interfaces {
        network    = data.terraform_remote_state.networking.outputs.vpc_name
        subnetwork = data.terraform_remote_state.networking.outputs.subnet_name
      }
    }

  }
}

resource "google_cloud_run_service_iam_member" "api_public_access" {
  location = google_cloud_run_v2_service.api.location
  project  = google_cloud_run_v2_service.api.project
  service  = google_cloud_run_v2_service.api.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_service_account" "api_service_account" {
  project = var.project_id

  account_id   = "api-sa"
  display_name = "API Service Account"
}

resource "google_project_iam_member" "api_sa_secret_accessor" {
  project = var.project_id

  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.api_service_account.email}"
}