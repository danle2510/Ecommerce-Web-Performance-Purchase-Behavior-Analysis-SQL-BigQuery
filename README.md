# Ecommerce-Web-Performance-Purchase-Behavior-Analysis-SQL-BigQuery

---

## 📑 Table of Contents

1. [Overview](#-overview)
2. [Dataset](#-dataset)
3. [Analysis Framework](#-analysis-framework)
4. [Analysis](#-analysis)
5. [Key Insights & Recommendations](#-key-insights--recommendations)

---

## 📌 Overview

This project analyzes the **Google Merchandise Store** e-commerce website using SQL in **Google BigQuery**. The goal is to understand how visitors find the site, how they behave once they arrive, and what drives them to purchase.

The analysis follows the full customer journey, from **traffic → engagement → conversion → revenue**, to help the business answer:

- Which traffic sources bring the most valuable customers?
- Where do customers drop off before purchasing?
- Which devices and products drive revenue?
- How is revenue trending over time?

**Skills demonstrated:** aggregations, `CASE WHEN`, CTEs, `UNNEST` of nested/repeated fields, `JOIN`, `UNION ALL`, window functions, date formatting, wildcard tables with `_table_suffix`.

---

## 🗂️ Dataset

| Item | Detail |
|---|---|
| **Source** | `bigquery-public-data.google_analytics_sample.ga_sessions_*` |
| **Business** | Google Merchandise Store (online store selling Google-branded products) |
| **Time range** | August 2016 – August 2017 |
| **Granularity** | One row per session, with nested `hits` and `product` arrays |

<details>
<summary><b>Key fields used</b></summary>
<br/>

| Field | Description |
|---|---|
| `fullVisitorId` | Unique visitor ID |
| `date` | Session date (`YYYYMMDD`) |
| `totals.visits` | Number of sessions |
| `totals.pageviews` | Total pageviews in the session |
| `totals.bounces` | 1 if the session bounced |
| `totals.transactions` | Number of transactions in the session |
| `trafficSource.source` | Source of the traffic (google, direct, etc.) |
| `device.deviceCategory` | Device type (desktop, mobile, tablet) |
| `hits.eCommerceAction.action_type` | Action type (2 = product view, 3 = add to cart, 6 = purchase) |
| `hits.product.v2ProductName` | Product name |
| `hits.product.productQuantity` | Quantity ordered |
| `hits.product.productRevenue` | Product revenue (× 10⁶) |

</details>

---

## 🧭 Analysis Framework

The analysis follows the **customer journey**, from the moment a visitor arrives on the site to the revenue they generate.

It starts with **traffic** (Q1, Q2), measuring how many people visit each month and whether each source brings in engaged visitors or ones who leave right away. It then looks at **engagement** (Q5, Q6), comparing how buyers and non-buyers browse the site and whether customers come back to purchase again. Next, it examines **conversion** (Q4, Q9), identifying which traffic sources turn visitors into buyers most effectively and where shoppers drop off between viewing a product, adding it to the cart, and checking out. Finally, it focuses on **revenue** (Q3, Q7, Q8, Q10), showing which channels, devices, and product combinations drive sales and how revenue builds up week by week.

---

## 🔬 Analysis


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


## 🔍 Query 6: Average number of transactions per purchasing user in July 2017

The goal of this analysis is to measure **how often customers come back to buy again** within the month. A value close to 1 means most buyers purchase only once, while a higher value shows **repeat buying and stronger customer loyalty**. This helps the business judge whether to focus on acquiring new customers or on retention tactics such as promotions, loyalty programs, and follow-up emails.

#### 🚀 Query

```sql
SELECT
  FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
  ROUND(SUM(totals.transactions) / COUNT(DISTINCT fullVisitorId), 2) AS avg_transactions_per_user
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
  UNNEST(hits) AS hits,
  UNNEST(hits.product) AS product
WHERE product.productRevenue IS NOT NULL
  AND totals.transactions >= 1
GROUP BY month;
```

#### 💡 Query Result

<img width="443" height="141" alt="image" src="https://github.com/user-attachments/assets/229b2408-d097-47a9-b672-4848b5dbac97" />


## 🔍 Query 7: Revenue contribution by device category (order by ratio DESC)

The goal of this analysis is to understand **which devices customers use when they actually spend money**. Knowing each device's share of total revenue tells the business where to prioritize: if desktop dominates, the desktop checkout must be flawless; if mobile's share is small despite high mobile traffic, the **mobile shopping experience may be losing sales** and needs improvement.

#### 🚀 Query

```sql
WITH revenue AS (
  SELECT
    SUM(product.productRevenue) / 1000000 AS total_revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
  WHERE totals.transactions IS NOT NULL
    AND product.productRevenue IS NOT NULL
),

device AS (
  SELECT
    device.deviceCategory AS device,
    SUM(product.productRevenue) / 1000000 AS revenue_by_device
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
  WHERE totals.transactions IS NOT NULL
    AND product.productRevenue IS NOT NULL
  GROUP BY device
)

SELECT
  d.device,
  ROUND(d.revenue_by_device, 2) AS revenue_by_device,
  ROUND(r.total_revenue, 2) AS total_revenue,
  ROUND(100.0 * d.revenue_by_device / r.total_revenue, 2) AS ratio
FROM device AS d
CROSS JOIN revenue AS r
ORDER BY ratio DESC;
```

#### 💡 Query Result

<img width="756" height="196" alt="image" src="https://github.com/user-attachments/assets/dbe8062f-51bc-4115-a14d-718404282fa4" />


## 🔍 Query 8: Other products purchased by customers who bought "YouTube Men's Vintage Henley" in July 2017

The goal of this analysis is to uncover **which products are frequently bought together**. By looking at what else customers buy alongside a specific product, the business can find natural product pairings and use them for **cross-selling**: "customers also bought" recommendations, product bundles, and targeted promotions that raise average order value.

#### 🚀 Query

```sql
WITH buyer_list AS (
  SELECT DISTINCT
    fullVisitorId
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
  WHERE product.v2ProductName = "YouTube Men's Vintage Henley"
    AND totals.transactions >= 1
    AND product.productRevenue IS NOT NULL
)

SELECT
  product.v2ProductName AS other_purchased_products,
  SUM(product.productQuantity) AS quantity
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
  UNNEST(hits) AS hits,
  UNNEST(hits.product) AS product
JOIN buyer_list USING (fullVisitorId)
WHERE product.v2ProductName != "YouTube Men's Vintage Henley"
  AND totals.transactions >= 1
  AND product.productRevenue IS NOT NULL
GROUP BY other_purchased_products
ORDER BY quantity DESC;
```

#### 💡 Query Result

<img width="450" height="646" alt="image" src="https://github.com/user-attachments/assets/b4ca25b4-2974-48ce-a5fa-cc1b30f698eb" />


## 🔍 Query 9: Conversion funnel from product view → add to cart → purchase in January, February, and March 2017

The goal of this analysis is to track **how customers move through the buying journey** and where they drop off. By measuring how many product views turn into add-to-carts, and how many turn into purchases, the business can pinpoint the **weakest stage of the funnel**. A low add-to-cart rate suggests problems with product pages, pricing, or product appeal, while a big drop between cart and purchase points to friction at checkout.

#### 🚀 Query

```sql
WITH product_data AS (
  SELECT
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
    COUNT(CASE WHEN hits.eCommerceAction.action_type = '2' THEN product.v2ProductName END) AS num_product_view,
    COUNT(CASE WHEN hits.eCommerceAction.action_type = '3' THEN product.v2ProductName END) AS num_add_to_cart,
    COUNT(CASE WHEN hits.eCommerceAction.action_type = '6'
               AND product.productRevenue IS NOT NULL THEN product.v2ProductName END) AS num_purchase
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
  WHERE _table_suffix BETWEEN '20170101' AND '20170331'
    AND hits.eCommerceAction.action_type IN ('2', '3', '6')
  GROUP BY month
)

SELECT
  month,
  num_product_view,
  num_add_to_cart,
  num_purchase,
  ROUND(num_add_to_cart / num_product_view * 100, 2) AS add_to_cart_rate,
  ROUND(num_purchase / num_product_view * 100, 2) AS purchase_rate
FROM product_data
ORDER BY month;
```

> 📝 Action types: `2` = product view, `3` = add to cart, `6` = completed purchase.

#### 💡 Query Result

<img width="888" height="195" alt="image" src="https://github.com/user-attachments/assets/fcf80621-e05a-4598-8428-fd0fba35fb94" />


## 🔍 Query 10: Weekly and cumulative revenue from May to July 2017

The goal of this analysis is to track **how revenue builds up week by week** over three months. Weekly revenue shows short-term ups and downs, such as the impact of a promotion or a slow week, while cumulative revenue shows the **overall growth trajectory** and whether the business is on pace to hit its targets. Together, they help the business spot momentum early and react before a slowdown affects monthly or quarterly results.

#### 🚀 Query

```sql
WITH raw_data AS (
  -- Revenue by week
  SELECT
    FORMAT_DATE('%Y-%W', PARSE_DATE('%Y%m%d', date)) AS week,
    SUM(product.productRevenue) / 1000000 AS weekly_revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
  WHERE _table_suffix BETWEEN '0501' AND '0731'
    AND product.productRevenue IS NOT NULL
  GROUP BY week
)

-- Cumulative revenue
SELECT
  week,
  ROUND(weekly_revenue, 2) AS weekly_revenue,
  ROUND(SUM(weekly_revenue) OVER (
    ORDER BY week
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ), 2) AS cumulative_revenue
FROM raw_data
ORDER BY week;
```

> 📝 `SUM() OVER (ORDER BY week ...)` is a window function that adds each week's revenue to the running total of all previous weeks.

#### 💡 Query Result

<img width="586" height="493" alt="image" src="https://github.com/user-attachments/assets/2e7e8518-4fd4-44c5-970c-bcd52959427a" />


---

## 📈 Key Insights & Recommendations

### Insights

**1. 🚦 Traffic: volume is concentrated, quality varies widely (Q1, Q2)**
- Traffic grew through Q1 2017, with March as the strongest month: visits rose **12.4%** vs. February, while transactions jumped **35.5%** (733 → 993).
- Conversion improved every month, from **1.10%** in January to **1.18%** in February and **1.42%** in March, so traffic quality improved, not just volume.
- In July 2017, **Google (38,400 visits)** and **Direct (19,891)** brought in the most traffic. Direct visitors were more engaged (**43.3%** bounce rate vs. **51.6%** for Google).
- Social and video sources bounced the most: **YouTube (66.7%)** and **m.facebook.com (64.3%)**. Smaller referral sources like **mail.google.com (24.8%)** and **reddit.com (28.6%)** brought highly engaged visitors.

**2. 👀 Engagement: browsing more does not mean buying more (Q5, Q6)**
- Non-purchasers viewed about **3.4×** more pages than purchasers in June and **2.7×** more in July, which suggests many visitors explore the site without finding what they need or without enough reason to buy.
- Purchaser engagement grew **32%** from June to July (94 → 124 pageviews), and purchasing users made an average of **4.16 transactions** in July, showing strong repeat buying among existing customers.

**3. 🛒 Conversion: Direct and DFA convert best, the funnel is improving (Q4, Q9)**
- **Direct (2.48%)** and **DFA (2.64%)** convert visitors far better than **Google search (0.92%)**. Google sends almost as many visits as Direct (179,804 vs. 189,447) but generates only about **one-third of the transactions** (1,661 vs. 4,697).
- The funnel improved every month in Q1 2017: add-to-cart rate rose from **28.5% → 34.3% → 37.3%**, and purchase rate from **8.3% → 9.6% → 12.6%**.
- The **biggest drop-off is after add to cart**: only about **28–34%** of carted items are purchased, so roughly two in three carts are abandoned.

**4. 💰 Revenue: desktop-driven, led by Direct traffic, with strong late-July momentum (Q3, Q7, Q8, Q10)**
- **Desktop generated 96.1%** of total revenue ($1.67M of $1.74M), while **mobile contributed only 3.3%** and tablet 0.6%.
- In June 2017, **Direct traffic generated $97.3K** in revenue, far ahead of DFA ($8.9K), and peaked in week 24 ($30.9K).
- From May to July 2017, revenue reached **$425.3K**, averaging about **$31.8K per week**. Weekly revenue was volatile ($19.8K–$57.1K), with the **strongest week in week 29 ($57.1K)**. *(Week 31 covers only July 31, so it is excluded from the average.)*
- Customers who bought the **YouTube Men's Vintage Henley** most often also bought **Google Sunglasses (20 units)**, followed by the Google Women's Vintage Hero Tee (7) and the SPF-15 Lip Balm (6). These are mainly apparel and summer accessories.

### Recommendations

- 🎯 **Optimize Google search traffic:** it brings high volume but converts at under 1%. Review keywords and landing pages so search visitors reach relevant products faster.
- 📢 **Invest more in high-converting channels:** Direct and DFA show the highest conversion rates; strengthen brand awareness, email, and display campaigns that drive these visits.
- 📱 **Fix the mobile experience:** mobile brings only 3.3% of revenue. Audit the mobile site and checkout for friction, as it is likely a large missed opportunity.
- 🛒 **Reduce cart abandonment:** with about two-thirds of carts abandoned, test simpler checkout, clearer shipping costs, and cart-reminder emails.
- 🧭 **Help browsers become buyers:** non-purchasers view far more pages without buying. Improve search, filters, and product recommendations to shorten the path to purchase.
- 🛍️ **Bundle frequently bought-together items:** pair apparel with accessories like sunglasses and lip balm in "Complete the look" bundles and summer promotions.
- 🔁 **Reward repeat customers:** purchasers buy multiple times per month, so a loyalty program or follow-up offers can grow revenue from existing customers.


