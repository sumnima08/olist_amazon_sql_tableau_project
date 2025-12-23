# 📊 Executive Overview: Revenue and Order Performance

This project delivers an end-to-end **SQL-based business analytics workflow** on an e-commerce dataset.  
It moves from **data validation → KPI creation → customer behavior → cohort & revenue concentration analysis**, designed for real-world analytics and BI dashboards.

---

## 🎯 Business Questions Answered

- What is total revenue, total orders, and AOV?
- How does revenue and order volume trend monthly?
- Which product categories drive the most revenue?
- How often do customers repeat purchases?
- How strong is customer retention by cohort?
- Is revenue concentrated among a small group of customers?

---

## 🧠 KPI Rules & Analytical Assumptions

- **Completed transactions only**:  
  Only `order_status = 'delivered'` orders are used for revenue and KPI calculations.
- **Revenue definition**:  
  Revenue is calculated at the **item level** using `order_items.price`.
- **Customer definition**:  
  `customer_unique_id` represents a real customer.  
  `customer_id` is order-level and not used for repeat analysis.
- **Cohorts**:  
  Cohorts are defined by **first purchase month**.
- **Delivery metrics**:  
  Calculated only when both actual and estimated delivery dates are available.

---

## 🛠️ SQL: Data Model, Validation & Analysis

TABLE CREATION

```sql
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
```

BASIC DATA CHECKS

```
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM order_items;
SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM products;

SELECT *
FROM order_items
LIMIT 5;
```

DATA VALIDATION & EDA


-- Data grain validation
```
SELECT COUNT(*), COUNT(DISTINCT order_id)
FROM orders;
```
-- Time coverage
```
SELECT 
    MIN(order_purchase_timestamp),
    MAX(order_purchase_timestamp)
FROM orders;
```
-- Order status distribution
```
SELECT order_status, COUNT(*)
FROM orders
GROUP BY order_status;
```
-- Delivered orders with missing delivery timestamps
```
SELECT
    COUNT(*) FILTER (WHERE order_status = 'deliverd') AS delivered_orders,
    COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS missing_delivery_date
FROM orders;
```
-- Revenue sanity check
```
SELECT 
    MIN(price), 
    MAX(price), 
    AVG(price)
FROM order_items;
```
-- Orders per customer
```
SELECT
    customer_unique_id,
    COUNT(DISTINCT order_id) AS order_count
FROM orders o
JOIN customers c
  ON o.customer_id = c.customer_id
GROUP BY customer_unique_id
ORDER BY order_count DESC;
```
Top categories by revenue
```SELECT 
    p.product_category_name, 
    SUM(oi.price) AS revenue
FROM order_items oi
JOIN products p 
  ON oi.product_id = p.product_id
GROUP BY p.product_category_name;
```

ANALYTICAL VIEWS

```
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

CREATE OR REPLACE VIEW vw_monthly_kpis AS
SELECT
    DATE_TRUNC('month', order_purchase_timestamp) AS month,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(price) AS revenue,
    ROUND(SUM(price) / COUNT(DISTINCT order_id), 2) AS aov
FROM vw_delivered_order_items
GROUP BY 1
ORDER BY 1;
```
CREATE OR REPLACE VIEW vw_customer_orders AS
```
SELECT
    customer_unique_id,
    COUNT(DISTINCT order_id) AS order_count
FROM vw_delivered_order_items
GROUP BY customer_unique_id;
```
CREATE OR REPLACE VIEW vw_customer_first_purchase AS
```SELECT 
    customer_unique_id,
    DATE_TRUNC('month', MIN(order_purchase_timestamp)) AS cohort_month
FROM vw_delivered_order_items
GROUP BY customer_unique_id;
```
CREATE OR REPLACE VIEW vw_category_revenue AS
```SELECT
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
```
COHORT & RETENTION

```
CREATE OR REPLACE VIEW vw_customer_cohorts AS 
SELECT 
    customer_unique_id,
    DATE_TRUNC('month', MIN(order_purchase_timestamp)) AS cohort_month
FROM vw_delivered_order_items
GROUP BY customer_unique_id;

CREATE OR REPLACE VIEW vw_customer_activity AS 
SELECT
    customer_unique_id,
    DATE_TRUNC('month', order_purchase_timestamp) AS activity_month
FROM vw_delivered_order_items
GROUP BY customer_unique_id, activity_month;

CREATE OR REPLACE VIEW vw_cohort_retention AS 
SELECT
    c.cohort_month,
    a.activity_month,
    EXTRACT(MONTH FROM AGE(a.activity_month, c.cohort_month)) AS month_number,
    COUNT(DISTINCT a.customer_unique_id) AS active_customers
FROM vw_customer_cohorts c 
JOIN vw_customer_activity a 
  ON c.customer_unique_id = a.customer_unique_id 
GROUP BY c.cohort_month, a.activity_month 
ORDER BY c.cohort_month, month_number;

CREATE OR REPLACE VIEW vw_cohort_sizes AS
SELECT
    cohort_month,
    COUNT(DISTINCT customer_unique_id) AS cohort_size
FROM vw_customer_cohorts
GROUP BY cohort_month;
```

CUSTOMER VALUE ANALYSIS

```
CREATE OR REPLACE VIEW vw_customer_revenue AS
SELECT
    customer_unique_id,
    SUM(price) AS total_revenue
FROM vw_delivered_order_items
GROUP BY customer_unique_id;

SELECT
    revenue_decile,
    SUM(total_revenue) AS revenue
FROM (
    SELECT
        customer_unique_id,
        total_revenue,
        NTILE(10) OVER (ORDER BY total_revenue DESC) AS revenue_decile
    FROM vw_customer_revenue
) t
GROUP BY revenue_decile
ORDER BY revenue_decile;

SELECT
    order_count,
    COUNT(*) AS customers
FROM vw_customer_orders
GROUP BY order_count
ORDER BY order_count;

SELECT
    customer_unique_id,
    total_revenue
FROM vw_customer_revenue
ORDER BY total_revenue DESC
LIMIT 10;
```

---

## 📈 Dashboard Preview

![Executive Dashboard](Screenshot%202025-12-23%20at%2012.25.47 PM.png)

---

## ✅ Key Takeaways

- Revenue growth is **not linear** and shows sharp monthly volatility
- A small group of customers contributes **disproportionate revenue**
- Retention drops significantly after early lifecycle months
- Category-level revenue concentration highlights growth opportunities

---

## 🧩 Skills Demonstrated

- SQL data modeling
- KPI design
- Window functions
- Cohort & retention analysis
- Revenue concentration analysis
- Analytics-ready view creation

---


