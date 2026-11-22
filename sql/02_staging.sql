CREATE SCHEMA IF NOT EXISTS stg;

-- orders: cast tanggal, hitung lama kirim
CREATE OR REPLACE TABLE stg.orders AS
SELECT order_id, customer_id, lower(order_status) AS order_status,
  CAST(order_purchase_timestamp AS TIMESTAMP)      AS purchased_at,
  CAST(order_approved_at AS TIMESTAMP)             AS approved_at,
  CAST(order_delivered_customer_date AS TIMESTAMP) AS delivered_at,
  CAST(order_estimated_delivery_date AS TIMESTAMP) AS estimated_at,
  date_diff('day', CAST(order_purchase_timestamp AS TIMESTAMP),
            CAST(order_delivered_customer_date AS TIMESTAMP)) AS delivery_days,
  CAST(order_delivered_customer_date AS TIMESTAMP)
    > CAST(order_estimated_delivery_date AS TIMESTAMP) AS is_late
FROM raw.orders;

-- customers: rapikan kota
CREATE OR REPLACE TABLE stg.customers AS
SELECT customer_id, customer_unique_id,
  lpad(CAST(customer_zip_code_prefix AS VARCHAR), 5, '0') AS zip_prefix,
  lower(trim(customer_city)) AS city, upper(customer_state) AS state
FROM raw.customers;

-- products: fix typo kolom + translate kategori
CREATE OR REPLACE TABLE stg.products AS
SELECT p.product_id,
        coalesce(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
  p.product_weight_g AS weight_g
FROM raw.products p
LEFT JOIN raw.category_translation t USING (product_category_name);

-- sellers
CREATE OR REPLACE TABLE stg.sellers AS
SELECT seller_id, lower(trim(seller_city)) AS city, upper(seller_state) AS state
FROM raw.sellers;

-- order_items
CREATE OR REPLACE TABLE stg.order_items AS
SELECT order_id, order_item_id, product_id, seller_id,
  price, freight_value, price + freight_value AS total_value
FROM raw.order_items;

-- payments: agregat per order
CREATE OR REPLACE TABLE stg.payments AS
SELECT order_id, sum(payment_value) AS payment_total,
  arg_max(payment_type, payment_value) AS main_payment_type,
  max(payment_installments) AS installments
FROM raw.payments GROUP BY order_id;

-- reviews: buang duplikat, ambil review terbaru per order
CREATE OR REPLACE TABLE stg.reviews AS
SELECT order_id, review_score
FROM raw.reviews
QUALIFY row_number() OVER (PARTITION BY order_id ORDER BY review_answer_timestamp DESC) = 1;