# vpc
output "vpc_id" {
  value = google_compute_network.vpc_network.id
}

output "vpc_name" {
  value = google_compute_network.vpc_network.name
}

# subnet
output "subnet_id" {
  value = google_compute_subnetwork.network-backend.id
}

output "subnet_name" {
  value = google_compute_subnetwork.network-backend.name
}

output "subnet_ip_range" {
  value = google_compute_subnetwork.network-backend.ip_cidr_range
}