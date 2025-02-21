terraform {
  backend "gcs" {
    bucket = "terraform-states-asvir-demolab"
    prefix = "terraform/monitoring"
  }
}

data "terraform_remote_state" "networking" {
  backend = "gcs"
  config = {
    bucket = "terraform-states-asvir-demolab"
    prefix = "terraform/networking"
  }
}
