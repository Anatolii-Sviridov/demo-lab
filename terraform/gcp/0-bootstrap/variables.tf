variable "project_id" {
  type    = string
}

variable "required_apis" {
  type        = list(string)
  description = "If project was not created - we will enable APIs separately"
  default     = []
}

variable "region" {
  type = string
}

variable "cloudbuild_github_app_instalation_id" {
  type = string
}

variable "github_repos" {
  type    = list(string)
  default = []
}

variable "github_org" {
  type    = string
}
