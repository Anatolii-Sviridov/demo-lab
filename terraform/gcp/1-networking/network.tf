resource "google_compute_network" "vpc_network" {
  project                 = var.project_id
  name                    = "vpc-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "network-backend" {
  project                 = var.project_id
  name          = "backend"
  ip_cidr_range = "10.2.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
    filter_expr          = "true"
  }
  depends_on = [
    google_compute_network.vpc_network
  ]
}

data "google_compute_network" "main" {
  name    = "vpc-network"
  project  = var.project_id
  depends_on = [
    google_compute_network.vpc_network
  ]
}

resource "google_compute_global_address" "private_ip_alloc" {
  project = var.project_id

  name          = "private-ip-alloc"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16 # must be at least 16 for CloudSQL
  network       = google_compute_network.vpc_network.id
}

resource "google_service_networking_connection" "default" {
  provider      = google-beta
  network                 = data.google_compute_network.main.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
  depends_on = [
    google_compute_network.vpc_network
  ]
}
