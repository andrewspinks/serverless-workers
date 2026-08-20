locals {
  temporal_metric_matcher = join(",", [
    "exported_namespace=\"${var.temporal_namespace}\"",
    "task_queue=\"${var.temporal_task_queue}\"",
    "deployment_name=\"${var.temporal_deployment_name}\"",
  ])

  prometheus_charts = [
    {
      title = "RPC Requests vs Failures"
      queries = [
        "sum by (build_id) (rate(temporal_request{${local.temporal_metric_matcher}}[5m]))",
        "sum by (build_id) (rate(temporal_request_failure{${local.temporal_metric_matcher}}[5m]))",
      ]
    },
    {
      title = "RPC Failures per Operation"
      queries = [
        "sum by (build_id, operation) (rate(temporal_request_failure{${local.temporal_metric_matcher}}[5m]))",
      ]
    },
    {
      title = "RPC Requests per Operation"
      queries = [
        "sum by (build_id, operation) (rate(temporal_request{${local.temporal_metric_matcher}}[5m]))",
      ]
    },
    {
      title = "RPC Latency p95"
      queries = [
        "histogram_quantile(0.95, sum by (build_id, operation, le) (rate(temporal_request_latency_bucket{${local.temporal_metric_matcher}}[5m])))",
      ]
    },
    {
      title = "Long RPC Failures per Operation"
      queries = [
        "sum by (build_id, operation) (rate(temporal_long_request_failure{${local.temporal_metric_matcher}}[5m]))",
      ]
    },
    {
      title = "Long RPC Latency p95"
      queries = [
        "histogram_quantile(0.95, sum by (build_id, operation, le) (rate(temporal_long_request_latency_bucket{${local.temporal_metric_matcher}}[5m])))",
      ]
    },
    {
      title = "Workflow Completion"
      queries = [
        "sum by (build_id, workflow_type) (rate(temporal_workflow_completed{${local.temporal_metric_matcher}}[5m]))",
      ]
    },
    {
      title = "Workflow End-to-End Latency p95"
      queries = [
        "histogram_quantile(0.95, sum by (build_id, workflow_type, le) (rate(temporal_workflow_endtoend_latency_bucket{${local.temporal_metric_matcher}}[5m])))",
      ]
    },
    {
      title = "Workflow Failures by Type"
      queries = [
        "sum by (build_id, workflow_type) (rate(temporal_workflow_failed{${local.temporal_metric_matcher}}[5m]))",
      ]
    },
    {
      title = "Workflow Task Throughput"
      queries = [
        "sum by (build_id, task_queue) (rate(temporal_workflow_task_queue_poll_succeed{${local.temporal_metric_matcher}}[5m]))",
      ]
    },
    {
      title = "Workflow Task Schedule-to-Start p95"
      queries = [
        "histogram_quantile(0.95, sum by (build_id, task_queue, le) (rate(temporal_workflow_task_schedule_to_start_latency_bucket{${local.temporal_metric_matcher}}[5m])))",
      ]
    },
    {
      title = "Workflow Task Failures"
      queries = [
        "sum by (build_id, workflow_type) (rate(temporal_workflow_task_execution_failed{${local.temporal_metric_matcher}}[5m]))",
      ]
    },
    {
      title = "Workflow Task Execution Latency p95"
      queries = [
        "histogram_quantile(0.95, sum by (build_id, workflow_type, le) (rate(temporal_workflow_task_execution_latency_bucket{${local.temporal_metric_matcher}}[5m])))",
      ]
    },
    {
      title = "Workflow Task Replay Latency p95"
      queries = [
        "histogram_quantile(0.95, sum by (build_id, workflow_type, le) (rate(temporal_workflow_task_replay_latency_bucket{${local.temporal_metric_matcher}}[5m])))",
      ]
    },
    {
      title = "Workflow Task Empty Polls"
      queries = [
        "sum by (build_id, task_queue) (rate(temporal_workflow_task_queue_poll_empty{${local.temporal_metric_matcher}}[5m]))",
      ]
    },
    {
      title = "Activity Throughput"
      queries = [
        "sum by (build_id, activity_type) (rate(temporal_activity_schedule_to_start_latency_count{${local.temporal_metric_matcher}}[5m]))",
      ]
    },
    {
      title = "Activity Failures"
      queries = [
        "sum by (build_id, activity_type) (rate(temporal_activity_execution_failed{${local.temporal_metric_matcher}}[5m]))",
      ]
    },
    {
      title = "Activity Execution Latency p95"
      queries = [
        "histogram_quantile(0.95, sum by (build_id, activity_type, le) (rate(temporal_activity_execution_latency_bucket{${local.temporal_metric_matcher}}[5m])))",
      ]
    },
    {
      title = "Activity Empty Polls"
      queries = [
        "sum by (build_id, task_queue) (rate(temporal_activity_poll_no_task{${local.temporal_metric_matcher}}[5m]))",
      ]
    },
    {
      title = "Activity Schedule-to-Start p95"
      queries = [
        "histogram_quantile(0.95, sum by (build_id, task_queue, le) (rate(temporal_activity_schedule_to_start_latency_bucket{${local.temporal_metric_matcher}}[5m])))",
      ]
    },
    {
      title = "Task Slots Available"
      queries = [
        "temporal_worker_task_slots_available{${local.temporal_metric_matcher}}",
      ]
    },
    {
      title = "Task Slots Used"
      queries = [
        "temporal_worker_task_slots_used{${local.temporal_metric_matcher}}",
      ]
    },
    {
      title = "Sticky Cache Size"
      queries = [
        "temporal_sticky_cache_size{${local.temporal_metric_matcher}}",
      ]
    },
    {
      title = "Sticky Cache Forced Evictions"
      queries = [
        "sum by (build_id) (rate(temporal_sticky_cache_total_forced_eviction{${local.temporal_metric_matcher}}[5m]))",
      ]
    },
    {
      title = "Sticky Cache Hits"
      queries = [
        "sum by (build_id) (rate(temporal_sticky_cache_hit{${local.temporal_metric_matcher}}[5m]))",
      ]
    },
    {
      title = "Sticky Cache Misses"
      queries = [
        "sum by (build_id, task_queue) (rate(temporal_sticky_cache_miss{${local.temporal_metric_matcher}}[5m]))",
      ]
    },
  ]

  cloud_run_pool_filter = length(var.worker_versions) == 0 ? "" : " AND (${join(" OR ", [
    for version in values(var.worker_versions) : "resource.label.worker_pool_name=\"${version.pool_name}\""
  ])})"

  cloud_run_charts = [
    {
      title   = "Cloud Run CPU Utilization p95"
      metric  = "run.googleapis.com/container/cpu/utilizations"
      aligner = "ALIGN_PERCENTILE_95"
      reducer = "REDUCE_MEAN"
      group_by = [
        "resource.label.worker_pool_name",
        "metric.label.container_name",
      ]
    },
    {
      title   = "Cloud Run Memory Utilization p95"
      metric  = "run.googleapis.com/container/memory/utilizations"
      aligner = "ALIGN_PERCENTILE_95"
      reducer = "REDUCE_MEAN"
      group_by = [
        "resource.label.worker_pool_name",
        "metric.label.container_name",
      ]
    },
    {
      title   = "Cloud Run Instance Count"
      metric  = "run.googleapis.com/container/instance_count"
      aligner = "ALIGN_MEAN"
      reducer = "REDUCE_SUM"
      group_by = [
        "resource.label.worker_pool_name",
        "metric.label.state",
      ]
    },
  ]

  cloud_run_tiles = [
    for index, chart in local.cloud_run_charts : {
      xPos   = (index % 2) * 24
      yPos   = floor(index / 2) * 16
      width  = 24
      height = 16
      widget = {
        title = chart.title
        xyChart = {
          chartOptions = { mode = "COLOR" }
          dataSets = [{
            plotType   = "LINE"
            targetAxis = "Y1"
            timeSeriesQuery = {
              timeSeriesFilter = {
                filter = "metric.type=\"${chart.metric}\" AND resource.type=\"cloud_run_worker_pool\" AND resource.label.location=\"${var.region}\"${local.cloud_run_pool_filter}"
                aggregation = {
                  alignmentPeriod    = "60s"
                  perSeriesAligner   = chart.aligner
                  crossSeriesReducer = chart.reducer
                  groupByFields      = chart.group_by
                }
              }
            }
          }]
          yAxis = {
            label = ""
            scale = "LINEAR"
          }
        }
      }
    }
  ]

  prometheus_y_offset = ceil(length(local.cloud_run_charts) / 2) * 16
  prometheus_tiles = [
    for index, chart in local.prometheus_charts : {
      xPos   = (index % 2) * 24
      yPos   = local.prometheus_y_offset + floor(index / 2) * 16
      width  = 24
      height = 16
      widget = {
        title = chart.title
        xyChart = {
          chartOptions = { mode = "COLOR" }
          dataSets = [
            for query in chart.queries : {
              plotType   = "LINE"
              targetAxis = "Y1"
              timeSeriesQuery = {
                prometheusQuery = query
              }
            }
          ]
          yAxis = {
            label = ""
            scale = "LINEAR"
          }
        }
      }
    }
  ]
}

resource "google_monitoring_dashboard" "worker" {
  project = var.project_id

  dashboard_json = jsonencode({
    displayName = "${var.temporal_deployment_name} - Temporal Cloud Run Worker"
    labels = {
      environment = local.environment_label
    }
    mosaicLayout = {
      columns = 48
      tiles   = concat(local.cloud_run_tiles, local.prometheus_tiles)
    }
  })

  depends_on = [google_project_service.required]
}
