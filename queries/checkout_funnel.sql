-- Shopping Cart Checkout Session Tracker
-- Group and list distinct sessions that successfully reached checkout 
-- (indicated by a POST request to '/cart/checkout') in the last 1 hour.

SELECT
  JSON_VALUE(json_payload.session) AS session_id,
  COUNT(*) AS success_checkout_requests
FROM
  -- Replace with your actual project-scoped BigQuery/Log Analytics table name:
  `qwiklabs-gcp-03-67635a27c244.global.day2ops-log._AllLogs`
WHERE
  JSON_VALUE(json_payload['http.req.method']) = "POST"
  AND JSON_VALUE(json_payload['http.req.path']) = "/cart/checkout"
  AND timestamp > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR)
GROUP BY
  session_id;
