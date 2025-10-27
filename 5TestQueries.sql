USE sakila_dw;

# Get revenue of each store for every month + year
SELECT d.year, d.month, s.store_id, SUM(f.amount) AS revenue
FROM fact_payments f
JOIN dim_date   d ON d.date_key  = f.payment_date_key
JOIN dim_store  s ON s.store_key = f.store_key
GROUP BY d.year, d.month, s.store_id
ORDER BY d.year, d.month, s.store_id;

# Get which staff earned the most revenue for the company
SELECT ds.first_name, ds.last_name, SUM(fp.amount) AS revenue
FROM fact_payments fp
JOIN dim_staff ds ON fp.staff_key = ds.staff_key
GROUP BY ds.first_name, ds.last_name
ORDER BY revenue DESC;

# Compare total revenue by day + weekend vs weekday 
SELECT d.day_of_week, d.is_weekend, SUM(fp.amount) AS revenue
FROM fact_payments fp
JOIN dim_date d ON fp.payment_date_key = d.date_key
GROUP BY d.day_of_week, d.is_weekend
ORDER BY d.day_of_week;

# Get total revenue by customer country sorted from highest to lowest (must run LoadCSV first)
SELECT
  COALESCE(dc.continent, 'Unknown') AS continent,
  ROUND(SUM(fp.amount), 2)          AS total_revenue,
  COUNT(*)                          AS num_payments
FROM fact_payments fp
JOIN dim_customer dc
  ON dc.customer_key = fp.customer_key
GROUP BY COALESCE(dc.continent, 'Unknown')
ORDER BY total_revenue DESC;

# Get average revenue by loyalty status
SELECT
  t.loyalty_tier,
  t.avg_payment_amount,
  t.total_revenue,
  t.num_payments
FROM (
  SELECT
    COALESCE(UPPER(dc.loyalty_tier), 'NONE') AS loyalty_tier,
    ROUND(AVG(fp.amount), 2) AS avg_payment_amount,
    ROUND(SUM(fp.amount), 2) AS total_revenue,
    COUNT(*) AS num_payments
  FROM fact_payments fp
  JOIN dim_customer dc
    ON dc.customer_key = fp.customer_key
  GROUP BY COALESCE(UPPER(dc.loyalty_tier), 'NONE')
) AS t
ORDER BY FIELD(t.loyalty_tier, 'PLATINUM','GOLD','SILVER','BRONZE','NONE');