-- CREATE TABLE --

CREATE TABLE orders (
    order_id TEXT PRIMARY KEY,
    customer_id TEXT,
    order_status TEXT,
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

CREATE TABLE order_items (
    order_id TEXT,
    order_item_id INTEGER,
    product_id TEXT,
    seller_id TEXT,
    shipping_limit_date TIMESTAMP,
    price NUMERIC(10,2),
    freight_value NUMERIC(10,2)
);

CREATE TABLE customers (
    customer_id TEXT PRIMARY KEY,
    customer_unique_id TEXT,
    customer_zip_code_prefix INTEGER,
    customer_city TEXT,
    customer_state TEXT
);

CREATE TABLE products (
    product_id TEXT PRIMARY KEY,
    product_category_name TEXT
);

CREATE TABLE category_translation (
    product_category_name TEXT PRIMARY KEY,
    product_category_name_english TEXT
);

SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM order_items;
SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM products;

SELECT *
FROM order_items
LIMIT 5;

-- Data validation & Exploratory Analysis

-- Data grain validation
-- Purpose: Confirm that each row in the orders table represents a single order
SELECT COUNT(*), COUNT(DISTINCT order_id)
FROM orders;

-- Time coverage
-- Purpose: Identify the data range covered by customer purchases
SELECT MIN(order_purchase_timestamp),
		MAX(order_purchase_timestamp)
FROM orders;

--Order Status Distribution
--Purpose: Understand how orders are distributed across fulfillment statuses
SELECT order_status, COUNT(*)
FROM orders
GROUP BY order_status;

--Delivered orders with missing timestamps
--Purpose: Assess completeness of delivery timestamps for delivered orders
SELECT
	COUNT(*) FILTER (WHERE order_status = 'deliverd') AS delivered_orders,
	COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS missing_delivery_date
FROM orders;

-- Revenue sanity check
--Purpose: Validate price distribution to detect outliers or invalid values
SELECT 
	MIN(price), 
	MAX(price), 
	AVG(price)
FROM order_items;

--Order per customer
-- Purpose: Measure customer repeat purchase behavior using unique customer identifier
SELECT
    customer_unique_id,
    COUNT(DISTINCT order_id) AS order_count
FROM orders o
JOIN customers c
  ON o.customer_id = c.customer_id
GROUP BY customer_unique_id
ORDER BY order_count DESC;

--Top categories by revenue
-- Purpose: Identify product categories contributing the highest revenue
SELECT p.product_category_name, SUM(oi.price) AS revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_category_name;

-- KPI RULE NOTES

-- KPI RULES & ANALYTICAL ASSUMPTIONS
-- These rules are defined after EDA and applied consistently across all queries.

-- Revenue & Orders:
-- Only orders with order_status = 'delivered' are considered completed transactions.

-- Revenue Calculation:
-- Revenue is calculated at item-level using order_items.price.
-- Orders table does not contain monetary values.

-- Customer Identification:
-- customer_unique_id represents a real customer.
-- customer_id is order-specific and should not be used for repeat analysis.

-- Cohort Definition:
-- Customer cohorts are based on order_purchase_timestamp (first purchase date).
-- Delivery dates are not used for cohort analysis.

-- Delivery & Ops Metrics:
-- Delivery performance metrics are calculated only when both
-- order_delivered_customer_date and order_estimated_delivery_date are present.


-- Creating Analytical Views
-- View 1: Delivered Order Items (Core Fact View)
-- Purpose: Create a clean item-level fact view for completed (delivered) orders
CREATE OR REPLACE VIEW vw_delivered_order_items AS
SELECT
    o.order_id,
    o.order_purchase_timestamp,
    c.customer_unique_id,
    oi.product_id,
    oi.price,
    oi.freight_value
FROM orders o
JOIN order_items oi
  ON o.order_id = oi.order_id
JOIN customers c
  ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered';

-- View 2: Monthly Business KPIs
-- Purpose: Aggregate monthly revenue, orders, and AOV for delivered orders
CREATE OR REPLACE VIEW vw_monthly_kpis AS
SELECT
    DATE_TRUNC('month', order_purchase_timestamp) AS month,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(price) AS revenue,
    ROUND(SUM(price) / COUNT(DISTINCT order_id), 2) AS aov
FROM vw_delivered_order_items
GROUP BY 1
ORDER BY 1;

--View 3: Customer Order Summary (Repeat Behavior)
-- Purpose: Summarize total orders per unique customer
CREATE OR REPLACE VIEW vw_customer_orders AS
SELECT
    customer_unique_id,
    COUNT(DISTINCT order_id) AS order_count
FROM vw_delivered_order_items
GROUP BY customer_unique_id;

--View 4: Cohort Base (Foundation and Retention)
--Purpose: Identify first purchase month for each customer to support cohort analysis

CREATE OR REPLACE VIEW vw_customer_first_purchase AS
SELECT 
	customer_unique_id,
	DATE_TRUNC('month', MIN(order_purchase_timestamp)) AS cohort_month
FROM vw_delivered_order_items
GROUP BY customer_unique_id;

--View 5: Product Category Performance
-- Purpose: Aggregate revenue by product category
CREATE OR REPLACE VIEW vw_category_revenue AS
SELECT
    COALESCE(ct.product_category_name_english, p.product_category_name) AS category,
    SUM(v.price) AS revenue,
    COUNT(DISTINCT v.order_id) AS orders
FROM vw_delivered_order_items v
JOIN products p
  ON v.product_id = p.product_id
LEFT JOIN category_translation ct
  ON p.product_category_name = ct.product_category_name
GROUP BY 1
ORDER BY revenue DESC;

--Validation--
SELECT * FROM vw_monthly_kpis LIMIT 5;
SELECT * FROM vw_customer_orders LIMIT 5;
SELECT * FROM vw_category_revenue LIMIT 5;

--Advanced Analysis

--Customer Cohort & Retention

--1. Build customer cohort base
--Purpose: Assign each customer to a cohort based on first purchase month
CREATE OR REPLACE VIEW vw_customer_cohorts AS 
SELECT 
	customer_unique_id,
	DATE_TRUNC('month', MIN(order_purchase_timestamp)) AS cohort_month
FROM vw_delivered_order_items
GROUP BY customer_unique_id;

--2. Build customer activity by month
--Purpose: Track customer activity by month for retention analysis
CREATE OR REPLACE VIEW vw_customer_activity AS 
SELECT
	customer_unique_id,
	DATE_TRUNC('month', order_purchase_timestamp) AS activity_month
FROM vw_delivered_order_items
GROUP BY customer_unique_id, activity_month;

--3.Build cohort retention table 
--Orders per customer distribution
-- Purpose: Analyze distribution of order frequency per customer
SELECT
    order_count,
    COUNT(*) AS customers
FROM vw_customer_orders
GROUP BY order_count
ORDER BY order_count;

--High-value customers
-- Purpose: Identify highest-value customers by total revenue
SELECT
    customer_unique_id,
    total_revenue
FROM vw_customer_revenue
ORDER BY total_revenue DESC
LIMIT 10;

SELECT *
FROM vw_monthly_kpis;

SELECT *
FROM vw_customer_orders;

SELECT *
FROM vw_cohort_retention;

SELECT *
FROM vw_category_revenue;










