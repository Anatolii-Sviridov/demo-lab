resource "google_sql_database_instance" "postgres" {
  provider = google-beta
  project = var.project_id
  name             = "postgres"
  region           = var.region
  database_version = "POSTGRES_15"

  #depends_on = [google_service_networking_connection.default]

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled                                  = false # true?
      private_network                               = data.terraform_remote_state.networking.outputs.vpc_id
      enable_private_path_for_google_cloud_services = true
    }

    # increase if it's required
    database_flags {
      name  = "max_connections"
      value = "200"
    }

  }
}

resource "google_sql_database" "main_database" {
  name     = "main"
  project = var.project_id
  instance = google_sql_database_instance.postgres.name
  depends_on = [google_sql_database_instance.postgres]
}

resource "google_sql_user" "users" {
  name     = "api"
  project = var.project_id
  instance = google_sql_database_instance.postgres.name
  password = google_secret_manager_secret.db_admin_password.name
}