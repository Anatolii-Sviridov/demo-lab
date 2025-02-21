resource "random_password" "db_admin_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "google_secret_manager_secret" "db_admin_password" {
  secret_id = "db-admin-password"
  project = var.project_id

  replication {
    user_managed {
      replicas {
        # Do not replicate the secret to other regions
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "db_admin_password" {
  secret      = google_secret_manager_secret.db_admin_password.id
  secret_data = random_password.db_admin_password.result # Stores secret as a plain txt in state

  lifecycle {
    ignore_changes = [secret_data]
  }
}