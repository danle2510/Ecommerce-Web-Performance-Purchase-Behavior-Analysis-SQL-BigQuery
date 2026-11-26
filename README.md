# Ecommerce-Web-Performance-Purchase-Behavior-Analysis-SQL-BigQuery



### 🔍 Query 1: Calculate total visits, pageviews, and transactions for January, February, and March 2017 (order by month)

The goal of this analysis is to build a **monthly baseline of website traffic, engagement, and sales** for Q1 2017. By comparing visits, pageviews, and transactions month by month, we can see whether the site is attracting more users, whether those users are engaging, and most importantly, whether traffic is **converting into transactions**.

#### 🚀 Query

```sql
SELECT
  FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
  SUM(totals.visits) AS total_visit,
  SUM(totals.pageviews) AS total_pageview,
  SUM(totals.transactions) AS total_transaction
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
WHERE _table_suffix BETWEEN '0101' AND '0331'
GROUP BY month
ORDER BY month;
```

#### 💡 Query Result

<img width="655" height="215" alt="image" src="https://github.com/user-attachments/assets/978591e7-6829-4089-9f18-1d5e72245ed2" />

#### 📌 Key Insights

- **March was the strongest month:** visits rose **12.4%** vs. February, while transactions jumped **35.5%** (733 → 993).
- **Conversion improved steadily:** from **1.10%** in January to **1.18%** in February and **1.42%** in March, so traffic quality improved, not just volume.
- **February dipped in traffic (-3.9%)** but still grew transactions, suggesting more purchase-ready visitors.
- **Pageviews per visit declined slightly** (3.98 → 3.71): users found what they needed faster, worth checking against bounce rate.


