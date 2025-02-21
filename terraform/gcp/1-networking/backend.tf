terraform {
  backend "gcs" {
    bucket = "terraform-states-asvir-demolab"
    prefix = "terraform/networking"
  }
}
