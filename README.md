#  GKE Day-2 Ops: Cloud Logging & Log Analytics Engine

<img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/googlecloud/googlecloud-original.svg" height="60" alt="Google Cloud" /> &nbsp;
<img src="https://raw.githubusercontent.com/barbaria888/barbaria888/main/gke-icon.png.png" height="70" alt="Google Kubernetes Engine"/>&nbsp;
<img src="https://github.com/barbaria888/LogOps-Magic-on-GKE/blob/main/images/BigQuery.png" height="70">&nbsp;
<img src="https://github.com/barbaria888/LogOps-Magic-on-GKE/blob/main/images/CloudLogging.png" height="70">

A production-grade demonstration showcasing **Day-2 Kubernetes Operations** on Google Kubernetes Engine (GKE) using **Cloud Logging**, custom **Log Sinks**, and **Log Analytics** with linked **BigQuery Datasets** for SQL-driven application insight.

This repository serves as a proof of work illustrating telemetry pipelines, log-routing optimization, and custom monitoring queries built to analyze a distributed microservices architecture (Google's *Online Boutique*).

---

## 🏗️ Architecture Flow

```mermaid
graph TD
    subgraph GKE Cluster ["☸️ GKE Day-2 Cluster (day2-ops)"]
        frontend[Frontend Service] --> |Logs & Requests| K8s["Kubernetes Node Agents"]
        checkout[Checkout Service] --> |Logs & Requests| K8s
        others[Other Services] --> |Logs & Requests| K8s
    end

    subgraph Observability ["🔍 Cloud Logging Platform"]
        K8s -->|Structured JSON stdout/stderr| Router["Log Router (Filter: resource.type='k8s_container')"]
        Router -->|Routed Telemetry| Sink["day2ops-sink (Log Sink)"]
        Sink -->|Optimized Write| Bucket["day2ops-log (Log Bucket w/ Log Analytics)"]
    end

    subgraph Analytics ["📊 Query & Analytics Layer"]
        Bucket -->|Federated Access| BQ["day2ops_log (BigQuery Linked Dataset)"]
        BQ -->|Custom Queries| Analyst["Cloud Logging & Log Analytics Console"]
        Analyst -->|Insight| Dashboard["Operational Dashboards (Latency, Sessions, Funnels)"]
    end

    style GKE Cluster fill:#e6f3ff,stroke:#326ce5,stroke-width:2px
    style Observability fill:#e6ffe6,stroke:#00a300,stroke-width:2px
    style Analytics fill:#fff0e6,stroke:#ff6600,stroke-width:2px
```

---

## 🛠️ Technology & Operations Stack

- **GKE (Google Kubernetes Engine)**: Managed Kubernetes environment running v1.31.5.
- **Google Cloud Logging**: Logs Router, custom Log Sinks, and upgraded Log Analytics buckets.
- **BigQuery (Linked Datasets)**: Real-time SQL query compilation over raw logs.
- **Online Boutique**: Multi-service microservices application (Go, Python, Java, C#, NodeJS) used to generate operational traffic patterns.
    > <img src="https://github.com/barbaria888/LogOps-Magic-on-GKE/blob/main/images/application-ss.png">
---

## 📁 Repository Structure

```text
.
├── README.md                  # Comprehensive proof-of-work documentation
├── scripts/
│   └── setup.sh               # Shell script automating GKE cluster authorization & app deployment
└── queries/
    ├── latency_analysis.sql   # SQL query analyzing Min/Max/Avg frontend latencies
    ├── product_visits.sql     # SQL query calculating product detail page metrics
    └── checkout_funnel.sql    # SQL query tracking sessions completing checkout process
```

---

## 🚀 Step-by-Step Operations Walkthrough

### Task 1: Infrastructure Initialization & Cluster Verification

Use the custom script or manual commands to authenticate to the Kubernetes cluster and verify nodes:

```bash
# Verify cluster status
gcloud container clusters list

# Fetch credentials for the active cluster
gcloud container clusters get-credentials day2-ops --region europe-west4

# Ensure nodes are provisioned and Ready
kubectl get nodes
```
<img src="https://github.com/barbaria888/LogOps-Magic-on-GKE/blob/main/images/clustter-day2-op.png">

### Task 2: Deploying Microservices Workloads

Clone the Google Microservices Demo and apply manifests to test telemetry capturing:

```bash
# Clone the demo source repository
git clone https://github.com/GoogleCloudPlatform/microservices-demo.git
cd microservices-demo

# Apply all resources
kubectl apply -f release/kubernetes-manifests.yaml

# Poll pod deployment status until all replicas report "Running"
kubectl get pods --watch

# Confirm service readiness by acquiring the External Load Balancer IP and querying HTTP status:
export EXTERNAL_IP=$(kubectl get service frontend-external -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
curl -o /dev/null -s -w "HTTP Response Code: %{http_code}\n" http://${EXTERNAL_IP}

```
<img src="https://github.com/barbaria888/LogOps-Magic-on-GKE/blob/main/images/microservices-getting-deployed-over-container.png">
<img src="https://github.com/barbaria888/LogOps-Magic-on-GKE/blob/main/images/cluster-up-and-running.png">
<img src="https://github.com/barbaria888/LogOps-Magic-on-GKE/blob/main/images/frontend-external-lb-ip.png">

---

## 🪵 Log Routing & Storage Administration (Day-2 Tasks)

To run advanced diagnostics, we optimize storage and filter noise by upgrading log destinations.

### 1. Upgrade Default Bucket to Log Analytics
- Upgraded the existing default log bucket `_Default` to support SQL querying engine.
- Configured native Log Analytics views `_AllLogs` in the global scope.

### 2. Provision Custom Log Bucket & Sink Routing
- Created a new target Log Bucket `day2ops-log` in region `Global` with **Log Analytics** enabled.
- Created an associated **BigQuery Linked Dataset** named `day2ops_log` to run complex analytical scripts directly on raw logging formats.
- Configured a routing **Log Sink** (`day2ops-sink`) targeting container workloads:
  ```text
  resource.type="k8s_container"
  ```
<img src="https://github.com/barbaria888/LogOps-Magic-on-GKE/blob/main/images/create-another-global-log-buckt-with-bq.png">
  
  This routes only target application logs, reducing indexing costs by filtering out GKE control plane noise.

---

## 📈 SQL Analytics & Operational Dashboarding

With logging schemas synced to BigQuery, we execute analytical queries within **Log Analytics**:

### 📊 Latency Metrics (Frontend Service)
To monitor API quality of service (QoS) and alert on performance regressions, run:
👉 **[latency_analysis.sql](./queries/latency_analysis.sql)**

```sql
SELECT
  hour,
  MIN(took_ms) AS min_latency_ms,
  MAX(took_ms) AS max_latency_ms,
  AVG(took_ms) AS avg_latency_ms
FROM (
  SELECT
    FORMAT_TIMESTAMP("%H", timestamp) AS hour,
    CAST(JSON_VALUE(json_payload, '$."http.resp.took_ms"') AS INT64) AS took_ms
  FROM
    `day2ops-log._AllLogs`
  WHERE
    timestamp > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
    AND json_payload IS NOT NULL
    AND SEARCH(labels, "frontend")
    AND JSON_VALUE(json_payload.message) = "request complete"
)
GROUP BY 1 ORDER BY 1;
```
<img src="https://github.com/barbaria888/LogOps-Magic-on-GKE/blob/main/images/Avg-http-200.png">


### 🛒 Marketing & Business Funnel Analysis
Identify traffic patterns for product page hits and track conversions (sessions completing checks):
👉 **[product_visits.sql](./queries/product_visits.sql)** & **[checkout_funnel.sql](./queries/checkout_funnel.sql)**

```sql
-- Tracking session checkouts
SELECT
  JSON_VALUE(json_payload.session) AS session_id,
  COUNT(*) AS checkout_count
FROM
  `day2ops-log._AllLogs`
WHERE
  JSON_VALUE(json_payload['http.req.method']) = "POST"
  AND JSON_VALUE(json_payload['http.req.path']) = "/cart/checkout"
  AND timestamp > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR)
GROUP BY 1;
```
<img src="https://github.com/barbaria888/LogOps-Magic-on-GKE/blob/main/images/No-of-times-checkout-visited.png">

```sql
-- Product Page Visit Counter
-- Counts the total occurrences of visits to a specific product (product ID: L9ECAV7KIM)
-- in the last 1 hour using pattern matching on the text payload.

SELECT
  COUNT(*) AS total_product_visits
FROM
  -- Replace with your actual project-scoped BigQuery/Log Analytics table name:
  `qwiklabs-gcp-03-67635a27c244.global.day2ops-log._AllLogs`
WHERE
  text_payload LIKE "GET %/product/L9ECAV7KIM %"
  AND timestamp > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR);
```
<img src="https://github.com/barbaria888/LogOps-Magic-on-GKE/blob/main/images/Product-page-visits-Charts.png">




---

## 🛡️ Key Takeaways for Day-2 Ops

1. **Storage Optimization**: Log buckets filtered via Sinks ensure that only queryable application logs consume analytics budgets.
2. **Real-time Analytics**: Linkage with BigQuery enables engineers to write native SQL queries on unstructured and structured logging data without spinning up manual pipelines.
3. **Decoupled Monitoring**: Metrics parsed from JSON payloads reduce the overhead of application code modifications for telemetry collection.

---

