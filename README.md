# 📊 Olist E-Commerce Analytics Project (SQL + Tableau)

This project analyzes an e-commerce dataset from **Olist** to evaluate **revenue performance, customer behavior, and retention trends** using **SQL for analytics** and **Tableau for visualization**.

The goal is to demonstrate an **end-to-end data analyst workflow** — from raw transactional data to executive-level insights.

---

## 🔍 Business Questions Answered

- What is total revenue, total orders, and average order value (AOV)?
- How do revenue and order volume trend month over month?
- Which product categories contribute the most revenue?
- How frequently do customers place repeat orders?
- How strong is customer retention across cohorts?
- Is revenue concentrated among a small group of customers?

---

## 🧠 Analytical Assumptions & KPI Rules

- Only **delivered orders** are considered completed transactions
- Revenue is calculated at the **item level** using `order_items.price`
- `customer_unique_id` represents a real customer (used for repeat analysis)
- Customer cohorts are defined by **first purchase month**
- Delivery metrics require both actual and estimated delivery dates

---

## 🗂️ Project Structure

```
olist_amazon_sql_tableau_project/
│
├── README.md
│
├── data/
│   ├── olist_orders_dataset.csv
│   ├── olist_order_items_dataset.csv
│   ├── olist_customers_dataset.csv
│   └── product_category_name_translation.csv
│
├── sql/
│   └── sql_olist_amazon.sql
│
├── images/
│   └── executive_dashboard.png
│
└── tableau/
    ├── Executive Overview Dashboard.twb
    └── Executive Summary Dashboard.twb
```

---

## 📂 Dataset Overview

The raw datasets are stored in the `data/` folder and include:

- **Orders**: order timestamps, status, and delivery information  
- **Order Items**: item-level pricing and freight values  
- **Customers**: customer identifiers and location data  
- **Category Translation**: Portuguese → English product category mapping  

---

## 🛠️ SQL Analysis Highlights

All SQL logic is stored in `sql/sql_olist_amazon.sql` and includes:

- Data validation & integrity checks
- Monthly KPIs (Revenue, Orders, AOV)
- Product category revenue analysis
- Customer repeat purchase analysis
- Cohort & retention analysis
- Revenue concentration using deciles
- High-value customer identification

Reusable **analytical views** were created to support BI tools and scalable analysis.

---

## 📈 Tableau Dashboards

Tableau dashboards were built on top of the SQL outputs to visualize:

- Executive revenue & order KPIs
- Monthly revenue and order trends
- Product category performance
- Revenue volatility and MoM change

A preview image is available in the `images/` folder and the `.twb` files are included in the `tableau/` directory.

---

## ✅ Key Insights

- Revenue shows strong **seasonality and volatility**
- A small segment of customers contributes a **disproportionate share of revenue**
- Customer retention declines significantly after early lifecycle months
- A few product categories dominate overall revenue performance

---

## 🧩 Skills Demonstrated

- SQL data modeling & transformations
- KPI engineering
- Window functions & aggregations
- Cohort & retention analysis
- Revenue concentration analysis
- Tableau dashboarding
- Analytics-ready project organization

---

## 📌 Tools Used

- **SQL (PostgreSQL-style syntax)**
- **Tableau**
- **GitHub**

---



