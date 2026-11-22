CREATE SCHEMA IF NOT EXISTS dq;

CREATE OR REPLACE TABLE dq.results AS
-- 1. Uniqueness: primary key tidak dobel
SELECT 'orders_pk_unique' AS check_name, count(*) - count(DISTINCT order_id) AS failed_rows FROM stg.orders
UNION ALL
SELECT 'fact_pk_unique', count(*) - count(DISTINCT (order_id, order_item_id)) FROM mart.fact_order_items
-- 2. Not null: kolom wajib
UNION ALL
SELECT 'orders_purchase_not_null', count(*) FILTER (WHERE purchased_at IS NULL) FROM stg.orders
-- 3. Referential integrity: FK harus ada di dim
UNION ALL
SELECT 'fact_customer_fk', count(*) FROM mart.fact_order_items f
  LEFT JOIN mart.dim_customer c USING (customer_id) WHERE c.customer_id IS NULL
UNION ALL
SELECT 'fact_product_fk', count(*) FROM mart.fact_order_items f
  LEFT JOIN mart.dim_product p USING (product_id) WHERE p.product_id IS NULL
-- 4. Valid range: harga & skor masuk akal
UNION ALL
SELECT 'price_positive', count(*) FILTER (WHERE price <= 0) FROM mart.fact_order_items
UNION ALL
SELECT 'review_score_1_to_5', count(*) FILTER (WHERE review_score NOT BETWEEN 1 AND 5) FROM stg.reviews
-- 5. Business logic
UNION ALL
SELECT 'delivered_before_purchase', count(*) FILTER (WHERE delivered_at < purchased_at) FROM stg.orders
UNION ALL
SELECT 'canceled_but_delivered', count(*) FILTER (WHERE order_status = 'canceled' AND delivered_at IS NOT NULL) FROM stg.orders
UNION ALL
SELECT 'delivered_missing_date', count(*) FILTER (WHERE order_status = 'delivered' AND delivered_at IS NULL) FROM stg.orders
UNION ALL
SELECT 'unknown_category', count(*) FILTER (WHERE category = 'unknown') FROM mart.dim_product;


CREATE OR REPLACE TABLE dq.summary AS
SELECT *,
  CASE WHEN failed_rows = 0 THEN 'PASS'
       WHEN check_name IN ('canceled_but_delivered','delivered_missing_date','unknown_category') THEN 'WARN'
       ELSE 'FAIL' END AS status
FROM dq.results;