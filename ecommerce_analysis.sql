-- Q1 -  calculate total visit, pageview, transaction for Jan, Feb and March 2017 (order by month)

SELECT 
   FORMAT_DATE('%Y%m',(PARSE_DATE('%Y%m%d', date))) AS month,
   COUNT(totals.visits) AS visit,
   SUM(totals.pageviews) AS pageview,
   SUM(totals.transactions) AS transaction,
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
WHERE _table_suffix BETWEEN '0101' AND '0331'
GROUP BY month
ORDER BY month ASC

-- Q2 -  Bounce rate per traffic source in July 2017 (Bounce_rate = num_bounce/total_visit) (order by total_visit DESC)

SELECT 
   trafficSource.source AS source,
   COUNT(totals.visits) AS total_visits,
   COUNT(totals. bounces) AS total_no_of_bounces,
   ROUND((COUNT(totals. bounces)/COUNT(totals.visits))*100.0, 3) AS bounce_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
GROUP BY  source
ORDER BY total_visits desc

-- Q3 -  Revenue by traffic source by week, by month in June 2017

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

  -- Q4-  Conversion rate by traffic source in 2017. (order by conversion_rate desc)

SELECT  
    trafficSource.source as source,
    COUNT(totals. visits) AS visits,
    SUM(totals.transactions) AS transaction,
    ROUND(SUM(totals.transactions) / SUM(totals.visits)  * 100, 2) AS conversion_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
GROUP BY source
HAVING SUM(totals.transactions) >= 50
ORDER BY conversion_rate DESC;

-- Q5 -  Average number of pageviews by purchaser type (purchasers vs non-purchasers) in June, July 2017.

with purchaser AS (
   SELECT 
      FORMAT_DATE('%Y%m', parse_date('%Y%m%d', date)) AS month,
      SUM(totals.pageviews)/COUNT(DISTINCT fullvisitorId) AS Avg_pageview,
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST (hits) hits,
    UNNEST (hits.product) product
    WHERE _table_suffix BETWEEN '0601' AND '0731'
        AND totals.transactions >=1
        AND product.productRevenue IS NOT NULL
    GROUP BY month
    ORDER BY month ASC
         ),

  non_purchaser AS (
   SELECT 
      FORMAT_DATE('%Y%m', parse_date('%Y%m%d', date)) AS month,
      SUM(totals.pageviews)/COUNT(DISTINCT fullvisitorId) AS Avg_non_pageview
   FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
   UNNEST (hits) hits,
   UNNEST (hits.product) product
   WHERE _table_suffix BETWEEN '0601' AND '0731'
            AND totals.transactions IS NULL
            AND product.productRevenue IS NULL
   GROUP BY month
   ORDER BY month ASC
        )

SELECT
   p1.month,
   p1.Avg_pageview,
   p2.Avg_non_pageview,
FROM purchaser AS p1
LEFT JOIN non_purchaser AS p2
  ON p1.month = p2.month
ORDER BY p1.month ASC

-- Q6 - Average number of transactions per user that made a purchase in July 2017

SELECT
   FORMAT_DATE('%Y%m',(parse_date('%Y%m%d', date))) AS month,
   ROUND(SUM(totals.transactions)/COUNT(DISTINCT fullvisitorId),9) AS Avg_pageview
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
UNNEST (hits) hits,
UNNEST (hits.product) product
WHERE product.productRevenue IS NOT NULL
    AND totals.transactions >=1
GROUP BY month


-- Q7-  Revenue contribution by device (desktop,mobile...) (order by ratio desc)

with revenue AS (
  SELECT
    ROUND(SUM(product.productRevenue) / 1000000,2) AS total_revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions*`,
  UNNEST(hits) AS hits,
  UNNEST(hits.product) AS product
     ),


 device AS ( 
   SELECT 
    DISTINCT device.deviceCategory AS Device,
    ROUND(SUM(product.productRevenue)/1000000,2) AS revenue_by_device
   FROM `bigquery-public-data.google_analytics_sample.ga_sessions*`,
   UNNEST (hits) hits,
   UNNEST (hits.product) product
   WHERE totals.transactions IS NOT NULL
     AND product.productRevenue IS NOT NULL
   GROUP BY Device
      )

SELECT 
   d.Device,
   d.revenue_by_device AS revenue_by_device,
   r.total_revenue AS total_revenue,
   ROUND(100.0*(d.revenue_by_device/r.total_revenue),2) AS ratio
FROM device AS d
CROSS JOIN revenue AS r
ORDER BY ratio DESC;


-- Q8 -  Other products purchased by customers who purchased product "YouTube Men's Vintage Henley" in July 2017. Output should show product name and the quantity was ordered.

with 
buyer_list as(
    SELECT
        distinct fullVisitorId  
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
    , UNNEST(hits) AS hits
    , UNNEST(hits.product) as product
    WHERE product.v2ProductName = "YouTube Men's Vintage Henley"
    AND totals.transactions>=1
    AND product.productRevenue is not null
)

SELECT
  product.v2ProductName AS other_purchased_products,
  SUM(product.productQuantity) AS quantity
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
, UNNEST(hits) AS hits
, UNNEST(hits.product) as product
JOIN buyer_list using(fullVisitorId)
WHERE product.v2ProductName != "YouTube Men's Vintage Henley"
 and product.productRevenue is not null
 AND totals.transactions>=1
GROUP BY other_purchased_products
ORDER BY quantity DESC;


--  Q9 -  Calculate cohort map from product view to addtocart to purchase in Jan, Feb and March 2017.

with product_data as(
select
    format_date('%Y%m', parse_date('%Y%m%d',date)) as month,
    count(CASE WHEN eCommerceAction.action_type = '2' THEN product.v2ProductName END) as num_product_view,
    count(CASE WHEN eCommerceAction.action_type = '3' THEN product.v2ProductName END) as num_add_to_cart,
    count(CASE WHEN eCommerceAction.action_type = '6' and product.productRevenue is not null THEN product.v2ProductName END) as num_purchase
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
,UNNEST(hits) as hits
,UNNEST (hits.product) as product
where _table_suffix between '20170101' and '20170331'
and eCommerceAction.action_type in ('2','3','6')
group by month
order by month
)

select
    month
    ,num_product_view
    ,num_add_to_cart
    ,num_purchase
    ,round(num_add_to_cart/num_product_view * 100, 2) as add_to_cart_rate
    ,round(num_purchase/num_product_view * 100, 2) as purchase_rate
from product_data;


-- Q10 -  Calculate revenue by week from May to July 2017 and culmulative revenue.

with 
raw_data AS ( -- get revenue by week
  SELECT
    FORMAT_DATE("%Y-%W", parse_date("%Y%m%d", date)) AS week,
    SUM(p.productRevenue)/1000000 AS weekly_revenue
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
  UNNEST(hits) hits,
  UNNEST(product) p
  WHERE _table_suffix BETWEEN '0501' AND '0731'
    AND p.productRevenue IS NOT NULL
  GROUP BY week
  ORDER BY week
)

-- calculate cumulative
SELECT
   week,
   weekly_revenue,
   SUM(weekly_revenue) OVER(ORDER BY week
                           rows between unbounded preceding and current row) AS cumulative_revenue
FROM raw_data
ORDER BY week;
