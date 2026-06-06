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
