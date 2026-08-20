output "artifact_repository" {
  description = "Artifact Registry repository used by release builds."
  value       = google_artifact_registry_repository.workers.name
}

output "artifact_repository_host" {
  description = "Regional Artifact Registry host."
  value       = "${var.region}-docker.pkg.dev"
}

output "project_id" {
  value = var.project_id
}

output "region" {
  value = var.region
}

output "name_prefix" {
  value = var.name_prefix
}

output "artifact_repository_id" {
  value = google_artifact_registry_repository.workers.repository_id
}

output "temporal_address" {
  value = var.temporal_address
}

output "temporal_namespace" {
  value = var.temporal_namespace
}

output "temporal_task_queue" {
  value = var.temporal_task_queue
}

output "temporal_deployment_name" {
  value = var.temporal_deployment_name
}

output "build_service_account" {
  description = "Dedicated Cloud Build execution service account."
  value       = google_service_account.builder.email
}

output "build_source_bucket" {
  description = "GCS bucket used to stage gcloud build submissions."
  value       = google_storage_bucket.build_source.name
}

output "runner_service_account" {
  description = "Cloud Run worker pool runtime identity."
  value       = google_service_account.runner.email
}

output "temporal_connection" {
  description = "Values to enter when creating the GCP Cloud Run compute connection in Temporal Cloud."
  value = {
    project_id              = var.project_id
    region                  = var.region
    invoker_service_account = module.temporal_cloud_run_identity.invoker_email
    worker_pools = {
      for build_id, pool in google_cloud_run_v2_worker_pool.version : build_id => pool.name
    }
  }
}

output "temporal_api_key_secret" {
  description = "Secret to populate with mise run secret:set-api-key."
  value       = google_secret_manager_secret.temporal_api_key.secret_id
}
