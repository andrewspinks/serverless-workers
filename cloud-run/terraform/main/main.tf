provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_project" "current" {
  project_id = var.project_id
}

locals {
  required_services = toset([
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "monitoring.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "storage.googleapis.com",
  ])

  build_source_bucket_base = "${var.project_id}-${var.name_prefix}-build-source"
  build_source_bucket_name = "${substr(local.build_source_bucket_base, 0, 54)}-${substr(sha1(local.build_source_bucket_base), 0, 8)}"
  environment_label        = replace(lower(var.environment), "/[^a-z0-9_-]/", "-")
}

resource "google_project_service" "required" {
  for_each = local.required_services

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "workers" {
  project       = var.project_id
  location      = var.region
  repository_id = var.artifact_repository_id
  description   = "Immutable Temporal Cloud Run worker images"
  format        = "DOCKER"

  depends_on = [google_project_service.required]
}

resource "google_storage_bucket" "build_source" {
  name                        = local.build_source_bucket_name
  project                     = var.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type = "Delete"
    }
  }

  depends_on = [google_project_service.required]
}

resource "google_service_account" "runner" {
  project      = var.project_id
  account_id   = "${var.name_prefix}-runner"
  display_name = "Temporal Cloud Run worker runtime"

  depends_on = [google_project_service.required]
}

resource "google_service_account" "builder" {
  project      = var.project_id
  account_id   = "${var.name_prefix}-builder"
  display_name = "Temporal worker Cloud Build execution"

  depends_on = [google_project_service.required]
}

resource "google_secret_manager_secret" "temporal_api_key" {
  project   = var.project_id
  secret_id = var.temporal_api_key_secret_id

  replication {
    auto {}
  }

  depends_on = [google_project_service.required]
}

resource "google_secret_manager_secret" "collector_config" {
  project   = var.project_id
  secret_id = "${var.name_prefix}-otel-config"

  replication {
    auto {}
  }

  depends_on = [google_project_service.required]
}

resource "google_secret_manager_secret_version" "collector_config" {
  secret      = google_secret_manager_secret.collector_config.id
  secret_data = file("${path.module}/../../telemetry/otel-collector.yaml")
}

resource "google_secret_manager_secret_iam_member" "runner_api_key" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.temporal_api_key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = google_service_account.runner.member
}

resource "google_secret_manager_secret_iam_member" "runner_collector_config" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.collector_config.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = google_service_account.runner.member
}

resource "google_project_iam_member" "runner_monitoring_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = google_service_account.runner.member
}

resource "google_project_iam_member" "builder_roles" {
  for_each = toset([
    "roles/artifactregistry.writer",
    "roles/logging.logWriter",
  ])

  project = var.project_id
  role    = each.value
  member  = google_service_account.builder.member
}

resource "google_storage_bucket_iam_member" "builder_source_reader" {
  bucket = google_storage_bucket.build_source.name
  role   = "roles/storage.objectViewer"
  member = google_service_account.builder.member
}

resource "google_artifact_registry_repository_iam_member" "cloud_run_reader" {
  project    = var.project_id
  location   = google_artifact_registry_repository.workers.location
  repository = google_artifact_registry_repository.workers.repository_id
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:service-${data.google_project.current.number}@serverless-robot-prod.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "deployer_cloud_build" {
  for_each = var.deployer_principals

  project = var.project_id
  role    = "roles/cloudbuild.builds.editor"
  member  = each.value
}

resource "google_service_account_iam_member" "deployer_builder_act_as" {
  for_each = var.deployer_principals

  service_account_id = google_service_account.builder.name
  role               = "roles/iam.serviceAccountUser"
  member             = each.value
}

resource "google_storage_bucket_iam_member" "deployer_source_writer" {
  for_each = var.deployer_principals

  bucket = google_storage_bucket.build_source.name
  role   = "roles/storage.objectCreator"
  member = each.value
}

resource "google_storage_bucket_iam_member" "deployer_source_bucket_viewer" {
  for_each = var.deployer_principals

  bucket = google_storage_bucket.build_source.name
  role   = "roles/storage.bucketViewer"
  member = each.value
}

module "temporal_cloud_run_identity" {
  source = "./modules/temporal-cloud-run-identity"

  project_id                          = var.project_id
  invoker_account_id                  = var.temporal_invoker_account_id
  runner_service_account_email        = google_service_account.runner.email
  impersonator_service_account_emails = var.temporal_impersonator_service_account_emails

  depends_on = [google_project_service.required]
}

resource "google_cloud_run_v2_worker_pool" "version" {
  for_each = var.worker_versions

  project             = var.project_id
  location            = var.region
  name                = each.value.pool_name
  deletion_protection = false
  labels = {
    environment = local.environment_label
    build       = each.value.pool_name
  }

  scaling {
    manual_instance_count = 0
  }

  template {
    service_account = google_service_account.runner.email

    containers {
      name       = "worker"
      image      = each.value.image
      depends_on = ["collector"]

      resources {
        limits = {
          cpu    = var.worker_cpu
          memory = var.worker_memory
        }
      }

      env {
        name  = "DEPLOYMENT_ENVIRONMENT"
        value = var.environment
      }
      env {
        name  = "TEMPORAL_ADDRESS"
        value = var.temporal_address
      }
      env {
        name  = "TEMPORAL_NAMESPACE"
        value = var.temporal_namespace
      }
      env {
        name  = "TEMPORAL_TASK_QUEUE"
        value = var.temporal_task_queue
      }
      env {
        name  = "TEMPORAL_DEPLOYMENT_NAME"
        value = var.temporal_deployment_name
      }
      env {
        name  = "TEMPORAL_BUILD_ID"
        value = each.key
      }
      env {
        name  = "TEMPORAL_USE_VERSIONING"
        value = "true"
      }
      env {
        name  = "TEMPORAL_METRICS_OTEL_URL"
        value = "http://127.0.0.1:4317"
      }
      env {
        name = "TEMPORAL_API_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.temporal_api_key.secret_id
            version = var.temporal_api_key_secret_version
          }
        }
      }
    }

    containers {
      name  = "collector"
      image = var.collector_image
      args  = ["--config=/etc/otelcol-google/config.yaml"]

      resources {
        limits = {
          cpu    = var.collector_cpu
          memory = var.collector_memory
        }
      }

      volume_mounts {
        name       = "collector-config"
        mount_path = "/etc/otelcol-google"
      }

      startup_probe {
        initial_delay_seconds = 0
        timeout_seconds       = 5
        period_seconds        = 5
        failure_threshold     = 12

        http_get {
          path = "/"
          port = 13133
        }
      }

      liveness_probe {
        initial_delay_seconds = 10
        timeout_seconds       = 5
        period_seconds        = 30

        http_get {
          path = "/"
          port = 13133
        }
      }
    }

    volumes {
      name = "collector-config"
      secret {
        secret = google_secret_manager_secret.collector_config.secret_id
        items {
          version = google_secret_manager_secret_version.collector_config.version
          path    = "config.yaml"
        }
      }
    }
  }

  depends_on = [
    google_artifact_registry_repository_iam_member.cloud_run_reader,
    google_project_iam_member.runner_monitoring_writer,
    google_secret_manager_secret_iam_member.runner_api_key,
    google_secret_manager_secret_iam_member.runner_collector_config,
    module.temporal_cloud_run_identity,
  ]
}
