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


## 🔍 Query 2: Bounce rate per traffic source in July 2017 (order by total_visit DESC)

The goal of this analysis is to evaluate the **quality of traffic from each source**. A high bounce rate means visitors leave after viewing only one page, which signals that the source may be bringing in the wrong audience or that the landing experience does not match what users expect. Comparing bounce rates across sources helps the business decide **where to invest marketing effort** and which channels need improvement.

#### 🚀 Query

```sql
SELECT
  trafficSource.source AS source,
  COUNT(totals.visits) AS total_visits,
  COUNT(totals.bounces) AS total_no_of_bounces,
  ROUND(COUNT(totals.bounces) / COUNT(totals.visits) * 100.0, 3) AS bounce_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
GROUP BY source
ORDER BY total_visits DESC;
```

#### 💡 Query Result

<img width="772" height="556" alt="image" src="https://github.com/user-attachments/assets/d1f96fe3-8d03-4c27-a77d-dcff76a4ad03" />


## 🔍 Query 3: Revenue by traffic source by week and by month in June 2017

The goal of this analysis is to identify **which traffic sources actually generate revenue**, not just traffic. Looking at revenue at both the **monthly** and **weekly** level shows which channels drive sales overall and whether their performance is stable or fluctuates week to week. This helps the business allocate marketing budget to the sources that bring in real value and spot short-term spikes or drops worth investigating.

#### 🚀 Query

```sql
SELECT 
   'month' AS time_type,
   FORMAT_DATE('%Y%m',(parse_date('%Y%m%d', date))) AS time,
   trafficSource.source AS source,
   SUM(product.productRevenue)/1000000 AS revenue,
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`,
  UNNEST (hits) hits,
  UNNEST (hits.product) product
  WHERE product.productRevenue IS NOT NULL
  GROUP BY time,source

UNION ALL


SELECT 
   'week' as time_type,
   FORMAT_DATE('%G%V', (parse_date('%Y%m%d', date))) AS time,
   trafficSource.source AS source,
   SUM(product.productRevenue)/1000000 AS revenue,
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`,
  UNNEST (hits) hits,
  UNNEST (hits.product) product
  WHERE product.productRevenue is not null
  GROUP BY time,source
  ORDER BY source, time_type, time;

```

#### 💡 Query Result

<img width="795" height="546" alt="image" src="https://github.com/user-attachments/assets/1711d2f0-3e13-4f67-bbfd-6b932c96bcc0" />


## 🔍 Query 4: Conversion rate by traffic source in 2017 (order by conversion_rate DESC)

The goal of this analysis is to find out **which traffic sources are best at turning visitors into buyers**. Traffic volume alone can be misleading: a source may send many visits but few purchases. By comparing conversion rates, and keeping only sources with **at least 50 transactions** so the results are reliable, the business can see which channels deliver the highest-quality customers and deserve more investment.

#### 🚀 Query

```sql
SELECT  
    trafficSource.source as source,
    COUNT(totals. visits) AS visits,
    SUM(totals.transactions) AS transaction,
    ROUND(SUM(totals.transactions) / SUM(totals.visits)  * 100, 2) AS conversion_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
GROUP BY source
HAVING SUM(totals.transactions) >= 50
ORDER BY conversion_rate DESC;

```

#### 💡 Query Result

<img width="739" height="202" alt="image" src="https://github.com/user-attachments/assets/93246b53-49ab-4815-8ebd-88dab08dbc9e" />


## 🔍 Query 5: Average number of pageviews by purchaser type (purchasers vs. non-purchasers) in June and July 2017

The goal of this analysis is to understand **how browsing behavior differs between customers who buy and those who don't**. If purchasers view many more pages, engagement is a strong signal of buying intent, and the business can focus on keeping visitors exploring the site through better navigation, product recommendations, and content. If the gap is small, non-purchasers may be browsing but hitting a barrier at checkout, which points to a different set of fixes.

#### 🚀 Query

```sql
WITH purchaser AS (
  SELECT
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
    SUM(totals.pageviews) / COUNT(DISTINCT fullVisitorId) AS avg_pageviews_purchase
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
  WHERE _table_suffix BETWEEN '0601' AND '0731'
    AND totals.transactions >= 1
    AND product.productRevenue IS NOT NULL
  GROUP BY month
),

non_purchaser AS (
  SELECT
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
    SUM(totals.pageviews) / COUNT(DISTINCT fullVisitorId) AS avg_pageviews_non_purchase
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
  WHERE _table_suffix BETWEEN '0601' AND '0731'
    AND totals.transactions IS NULL
    AND product.productRevenue IS NULL
  GROUP BY month
)

SELECT
  p.month,
  p.avg_pageviews_purchase,
  np.avg_pageviews_non_purchase
FROM purchaser AS p
LEFT JOIN non_purchaser AS np
  ON p.month = np.month
ORDER BY p.month;
```

#### 💡 Query Result

<img width="593" height="189" alt="image" src="https://github.com/user-attachments/assets/cd3f0205-6496-4614-9922-0959eb1d04b1" />




