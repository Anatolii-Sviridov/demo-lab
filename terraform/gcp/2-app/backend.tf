terraform {
  backend "gcs" {
    bucket = "terraform-states-asvir-demolab"
    prefix = "terraform/app"
  }
}

data "terraform_remote_state" "networking" {
  backend = "gcs"
  config = {
    bucket = "terraform-states-asvir-demolab"
    prefix = "terraform/networking"
  }
}
