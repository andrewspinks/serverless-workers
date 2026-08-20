# Temporal Worker on a Cloud Run worker pool

This directory is a repeatable, deliberately hands-on example for deploying a
versioned Temporal TypeScript Worker to Google Cloud Run worker pools. Every
Worker Build ID has its own zero-instance pool and immutable image digest. The
Temporal Cloud compute connection controls when that pool runs.

Google Cloud Monitoring and Managed Service for Prometheus provide the GCP
equivalent of CloudWatch. The Worker pushes Temporal SDK metrics over OTLP to a
Google-built OpenTelemetry Collector sidecar. Terraform installs a dashboard
based on Temporal's
[Core SDK OpenTelemetry dashboard](https://github.com/temporalio/dashboards/blob/master/sdk/temporal-core-sdks-otel.json).

## Layout

- `src/` contains the hello-world Workflow, Activity, Worker, starter, and tests.
- `terraform/bootstrap/` creates the versioned GCS state bucket.
- `terraform/main/` creates identities, Artifact Registry, secrets, worker
  pools, the collector sidecar, IAM, and the Cloud Monitoring dashboard.
- `terraform/main/versions.auto.tfvars.json` retains one immutable pool per
  Build ID.
- `scripts/` implements the mise tasks and release safety checks.

## Prerequisites

Install [mise](https://mise.jdx.dev/), then install every project dependency:

```shell
cd cloud-run
mise install
mise run install
mise run check
```

The mise configuration pins Node.js, pnpm, Terraform, gcloud, the Temporal CLI,
and every linter used by the project. Authenticate `gcloud` with a principal
that can initially create the bootstrap resources and IAM grants.

## Configure and provision shared infrastructure

Create a globally unique state bucket and initialize the main Terraform root:

```shell
mise run infra:bootstrap -- my-gcp-project my-gcp-project-temporal-worker-tfstate us-central1
cp terraform/main/terraform.tfvars.example terraform/main/terraform.tfvars
```

Edit `terraform/main/terraform.tfvars`. The impersonator service-account list
comes from Temporal Cloud's GCP Cloud Run compute-connection screen. Then run:

```shell
mise run infra:apply
```

The bootstrap state is local and ignored; the bucket is easy to import if that
local file is lost. All main infrastructure uses the remote GCS backend.

Add the Temporal Cloud API key without placing it in a file, command argument,
or Terraform state:

```shell
mise run secret:set-api-key
# or
printf '%s' "$TEMPORAL_API_KEY" | mise run secret:set-api-key
```

For production, set `temporal_api_key_secret_version` to a numeric version in
`terraform.tfvars`. `latest` is the example default and is resolved whenever a
new pool instance starts.

## Release a Worker version

The deploy task runs all checks, submits the image build with the dedicated
Cloud Build service account, resolves the pushed digest, updates the retained
version manifest, and applies Terraform:

```shell
mise run release:deploy -- build-1
```

Cloud Run pool names are deterministic DNS-safe names derived from the Build ID.
Tags are used only while building; Terraform always receives an `@sha256`
image reference.

Temporal's public CLI and Terraform provider do not currently expose the GCP
compute-connection fields. The deploy task therefore prints the exact values
for the Temporal Cloud UI and pauses. Once you type `connected`, it verifies the
Worker Deployment Version and automatically makes it current. A failure before
that point leaves the prior version current. Resume without rebuilding with:

```shell
mise run release:promote -- build-1
```

Deploying another Build ID adds a new pool without replacing old pools:

```shell
mise run release:deploy -- build-2
mise run release:rollback -- build-1
```

After Temporal reports an inactive version drained, remove its pool:

```shell
mise run release:prune -- build-1
```

The prune task refuses current and ramping versions and requires the Build ID
as interactive confirmation. It intentionally retains the Artifact Registry
image for auditability.

## Smoke test and observability

After promotion, start a Workflow and verify that its `temporal_worker_start`
metric reached Managed Service for Prometheus:

```shell
mise run smoke -- build-2 Andy
```

Metric ingestion can take a few minutes. The installed dashboard covers Cloud
Run CPU, memory, and instance count plus Temporal RPCs, Workflows, Workflow
Tasks, Activities, task slots, and sticky cache behavior. Temporal metrics are
stored against the `prometheus_target` monitored resource and retain
`environment`, `exported_namespace`, `task_queue`, `deployment_name`, and
`build_id` labels for version comparison. The collector renames `namespace` to
avoid a Managed Prometheus resource-label collision.

## Local development

Run a local Temporal development server, then use two terminals:

```shell
temporal server start-dev
mise run worker
```

```shell
mise run start-workflow -- World
```

Local defaults disable Worker Versioning and metrics export. Cloud Run enables
both through Terraform-managed environment variables.

## Secret and state safety

- Never put API keys in mise environment files or Terraform variables.
- Local Terraform state, backend configuration, release metadata, credentials,
  and local mise overrides are ignored.
- Rotate any key that has previously been committed or printed in plaintext.
- Do not prune a pool until Temporal shows that its version is inactive and
  drained.
