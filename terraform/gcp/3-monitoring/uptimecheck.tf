# Get the Cloud Run service URL
data "google_cloud_run_service" "api" {
  project  = var.project_id
  name     = "api"
  location = "us-central1"
}

# Create an Uptime Check
resource "google_monitoring_uptime_check_config" "uptime_check" {
    project  = var.project_id
  display_name = "Cloud Run Uptime Check"
  timeout      = "10s"
  period       = "60s"

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host = split("/", data.google_cloud_run_service.api.status[0].url)[2]
    }
  }

  http_check {
    path         = "/"
    port         = 443
    use_ssl      = true
    validate_ssl = true
  }
}

resource "google_monitoring_notification_channel" "basic" {
    project  = var.project_id
  display_name = "basic"
  type         = "email"
  labels = {
    email_address = "sviridovtl@gmail.com"
  }
  force_delete = false
}

# Optional: Alerting Policy for Uptime Check
resource "google_monitoring_alert_policy" "uptime_alert" {
  project      = var.project_id
  display_name = "Cloud Run Uptime Alert"

  conditions {
    display_name = "Uptime Check Failed"
    condition_threshold {
      filter          = "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" AND resource.type=\"uptime_url\""
      duration        = "60s"
      comparison      = "COMPARISON_LT"
      threshold_value = 1

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_NEXT_OLDER"
        cross_series_reducer = "REDUCE_COUNT"  # Change to REDUCE_COUNT
      }
    }
  }

  combiner = "OR"

  notification_channels = [google_monitoring_notification_channel.basic.id]
}