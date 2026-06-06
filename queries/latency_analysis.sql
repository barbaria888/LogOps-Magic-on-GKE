-- Latency Analysis for Frontend Microservice
-- Finds the minimum, maximum, and average latencies (in milliseconds) per hour
-- by parsing JSON payload fields within container log entries.

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
    -- Replace with your actual project-scoped BigQuery/Log Analytics table name:
    `qwiklabs-gcp-03-67635a27c244.global.day2ops-log._AllLogs`
  WHERE
    timestamp > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
    AND json_payload IS NOT NULL
    AND SEARCH(labels, "frontend")
    AND JSON_VALUE(json_payload.message) = "request complete"
  ORDER BY
    took_ms DESC,
    timestamp ASC
)
GROUP BY
  hour
ORDER BY
  hour ASC;
