terraform {
  required_version = "~> 1.8.2"

  required_providers {
    # https://github.com/hashicorp/terraform-provider-google
    google = {
      source  = "hashicorp/google"
      version = "~> 5.15.0, >= 3.33.0"
    }
    # https://github.com/hashicorp/terraform-provider-google-beta
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.15.0, >= 3.33.0"
    }
  }
}
