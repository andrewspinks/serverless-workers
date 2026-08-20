variable "project_id" {
  description = "GCP project that hosts the worker pool and invoker account."
  type        = string
}

variable "invoker_account_id" {
  description = "Account ID of the service account assumed by Temporal Cloud."
  type        = string
}

variable "invoker_display_name" {
  description = "Display name for the invoker service account."
  type        = string
  default     = "Temporal Serverless Worker Pool Invoker"
}

variable "impersonator_service_account_emails" {
  description = "Temporal Cloud accounts allowed to impersonate the invoker."
  type        = set(string)
}

variable "deploy_roles" {
  description = "Roles giving the invoker permission to read and scale worker pools."
  type        = set(string)
  default     = ["roles/run.developer"]
}

variable "runner_service_account_email" {
  description = "Service account attached to the worker pool."
  type        = string
}
