CREATE SCHEMA IF NOT EXISTS mart;

CREATE OR REPLACE TABLE mart.dim_customer AS
SELECT customer_id, customer_unique_id, city, state FROM stg.customers;

CREATE OR REPLACE TABLE mart.dim_product AS
SELECT product_id, category, weight_g FROM stg.products;

CREATE OR REPLACE TABLE mart.dim_seller AS
SELECT seller_id, city, state FROM stg.sellers;

CREATE OR REPLACE TABLE mart.dim_date AS
SELECT CAST(d AS DATE) AS date_key,
  year(d) AS year, month(d) AS month, monthname(d) AS month_name,
  quarter(d) AS quarter, dayname(d) AS day_name
FROM range(DATE '2016-01-01', DATE '2019-01-01', INTERVAL 1 DAY) t(d);

-- fact: 1 baris = 1 item dalam order
CREATE OR REPLACE TABLE mart.fact_order_items AS
SELECT i.order_id, i.order_item_id,
  o.customer_id, i.product_id, i.seller_id,
  CAST(o.purchased_at AS DATE) AS date_key,
  o.order_status, i.price, i.freight_value, i.total_value,
  o.delivery_days, o.is_late,
  p.main_payment_type, r.review_score
FROM stg.order_items i
JOIN stg.orders o USING (order_id)
LEFT JOIN stg.payments p USING (order_id)
LEFT JOIN stg.reviews r USING (order_id);