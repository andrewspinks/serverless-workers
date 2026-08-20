# Temporal Cloud Run identity

Vendored from `temporalio/terraform-modules`, module
`modules/serverless-workers/gcp/cloud-run`, commit
`4549300570398c3c91c829a5b0e70a93fa06afbc`.

The upstream module's `google ~> 4.0` constraint was intentionally omitted:
`google_cloud_run_v2_worker_pool` requires a newer Google provider. Resource
behavior is otherwise unchanged from that commit.
