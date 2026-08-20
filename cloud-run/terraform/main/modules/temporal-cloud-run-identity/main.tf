resource "google_service_account" "invoker" {
  project      = var.project_id
  account_id   = var.invoker_account_id
  display_name = var.invoker_display_name
}

resource "google_project_iam_member" "deploy_roles" {
  for_each = var.deploy_roles

  project = var.project_id
  role    = each.value
  member  = google_service_account.invoker.member
}

resource "google_service_account_iam_member" "impersonators" {
  for_each = var.impersonator_service_account_emails

  service_account_id = google_service_account.invoker.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${each.value}"
}

resource "google_service_account_iam_member" "invoker_act_as_runner" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.runner_service_account_email}"
  role               = "roles/iam.serviceAccountUser"
  member             = google_service_account.invoker.member
}
