variable "project_id" {
  description = "Google Cloud project that owns the Terraform state bucket."
  type        = string
}

variable "region" {
  description = "Default Google Cloud region."
  type        = string
  default     = "us-central1"
}

variable "state_bucket_name" {
  description = "Globally unique name for the Terraform state bucket."
  type        = string
}
