output "invoker_email" {
  description = "Email of the service account to provide to Temporal Cloud."
  value       = google_service_account.invoker.email
}

output "invoker_id" {
  description = "Fully qualified resource ID of the invoker account."
  value       = google_service_account.invoker.name
}

output "runner_service_account_email" {
  description = "Runtime identity attached to worker pools."
  value       = var.runner_service_account_email
}
