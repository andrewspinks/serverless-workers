variable "project_id" {
  description = "Google Cloud project in which to create the worker infrastructure."
  type        = string
}

variable "region" {
  description = "Cloud Run and Artifact Registry region."
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Short environment name used in resource names and metrics."
  type        = string
  default     = "demo"
}

variable "name_prefix" {
  description = "DNS-safe prefix for Google Cloud resources."
  type        = string
  default     = "temporal-worker"

  validation {
    condition     = can(regex("^[a-z]([a-z0-9-]*[a-z0-9])?$", var.name_prefix)) && length(var.name_prefix) <= 22
    error_message = "name_prefix must be a lowercase DNS-safe name of at most 22 characters."
  }
}

variable "artifact_repository_id" {
  description = "Artifact Registry Docker repository ID."
  type        = string
  default     = "temporal-workers"
}

variable "temporal_address" {
  description = "Temporal Cloud gRPC endpoint including port."
  type        = string
}

variable "temporal_namespace" {
  description = "Temporal Cloud Namespace."
  type        = string
}

variable "temporal_task_queue" {
  description = "Task Queue polled by the worker."
  type        = string
  default     = "cloud-run-worker"
}

variable "temporal_deployment_name" {
  description = "Temporal Worker Deployment name shared by every version."
  type        = string
  default     = "cloud-run-worker"
}

variable "temporal_api_key_secret_id" {
  description = "Secret Manager secret ID whose versions contain the Temporal API key."
  type        = string
  default     = "temporal-cloud-api-key"
}

variable "temporal_api_key_secret_version" {
  description = "Secret version injected into new pool instances. Pin a number for production; latest is convenient for this example."
  type        = string
  default     = "latest"
}

variable "temporal_invoker_account_id" {
  description = "Service account ID assumed by Temporal Cloud."
  type        = string
  default     = "temporal-worker-invoker"
}

variable "temporal_impersonator_service_account_emails" {
  description = "Temporal Cloud service accounts displayed in the Cloud Run compute connection UI."
  type        = set(string)
}

variable "deployer_principals" {
  description = "IAM members allowed to submit builds and impersonate the dedicated build account."
  type        = set(string)
  default     = []
}

variable "worker_cpu" {
  description = "CPU limit for the Temporal worker container."
  type        = string
  default     = "1"
}

variable "worker_memory" {
  description = "Memory limit for the Temporal worker container."
  type        = string
  default     = "1Gi"
}

variable "collector_cpu" {
  description = "CPU limit for the OpenTelemetry collector sidecar."
  type        = string
  default     = "1"
}

variable "collector_memory" {
  description = "Memory limit for the OpenTelemetry collector sidecar."
  type        = string
  default     = "512Mi"
}

variable "collector_image" {
  description = "Pinned Google-built OpenTelemetry collector image, preferably by digest."
  type        = string
  default     = "us-docker.pkg.dev/cloud-ops-agents-artifacts/google-cloud-opentelemetry-collector/otelcol-google@sha256:8a141713e33e4584b3bd24e0db39d56a8e650edb03d79b6bf3de82ff1cdd97f9"
}

variable "worker_versions" {
  description = "Retained immutable Worker versions. Keys are Temporal build IDs."
  type = map(object({
    image     = string
    pool_name = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for version in values(var.worker_versions) : can(regex("^[a-z]([a-z0-9-]{0,47}[a-z0-9])?$", version.pool_name))
    ])
    error_message = "Each pool_name must be a lowercase Cloud Run name of at most 49 characters."
  }

  validation {
    condition = alltrue([
      for version in values(var.worker_versions) : can(regex("@sha256:[0-9a-f]{64}$", version.image))
    ])
    error_message = "Each worker image must use an immutable @sha256 digest."
  }
}
