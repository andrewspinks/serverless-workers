const accessToken = process.env.MONITORING_ACCESS_TOKEN;
const projectId = process.env.MONITORING_PROJECT_ID;
const promql = process.env.MONITORING_PROMQL;

if (!accessToken || !projectId || !promql) {
  throw new Error("Monitoring query environment is incomplete");
}

const url = new URL(
  `https://monitoring.googleapis.com/v1/projects/${projectId}/location/global/prometheus/api/v1/query`,
);
url.searchParams.set("query", promql);

const response = await fetch(url, {
  headers: { Authorization: `Bearer ${accessToken}` },
});
if (!response.ok) {
  throw new Error(
    `Cloud Monitoring query failed: ${response.status} ${await response.text()}`,
  );
}

const payload = await response.json();
if (!Array.isArray(payload?.data?.result) || payload.data.result.length === 0) {
  process.exitCode = 1;
}
