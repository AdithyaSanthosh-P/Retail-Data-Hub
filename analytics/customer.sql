-- New vs Returning Customers 
WITH customer_orders AS (
    SELECT customer_id, COUNT(DISTINCT order_id) AS order_count
    FROM sales_fact
    GROUP BY customer_id
)
SELECT
    CASE WHEN order_count = 1 THEN 'New' ELSE 'Returning' END AS customer_segment,
    COUNT(*) AS customer_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_customers
FROM customer_orders
GROUP BY CASE WHEN order_count = 1 THEN 'New' ELSE 'Returning' END;

-- Repeat Purchase Rate (single number)
WITH customer_orders AS (
    SELECT customer_id, COUNT(DISTINCT order_id) AS order_count
    FROM sales_fact
    GROUP BY customer_id
)
SELECT
    ROUND(100.0 * COUNT(*) FILTER (WHERE order_count > 1) / COUNT(*), 2) AS repeat_purchase_rate_pct
FROM customer_orders;

-- Customer Lifetime Value 
SELECT
    c.customer_id,
    c.customer_name,
    c.city,
    c.customer_type,
    COUNT(DISTINCT sf.order_id) AS total_orders,
    SUM(sf.revenue) AS total_revenue,
    ROUND(SUM(sf.revenue) / NULLIF(COUNT(DISTINCT sf.order_id), 0), 2) AS avg_order_value
FROM sales_fact sf
JOIN dim_customers c ON sf.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name, c.city, c.customer_type
ORDER BY total_revenue DESC
LIMIT 50;

-- CLV Summary by City (average CLV per customer, by city)
WITH clv AS (
    SELECT
        c.customer_id,
        c.city,
        SUM(sf.revenue) AS customer_revenue
    FROM sales_fact sf
    JOIN dim_customers c ON sf.customer_id = c.customer_id
    GROUP BY c.customer_id, c.city
)
SELECT
    city,
    COUNT(*) AS customer_count,
    ROUND(AVG(customer_revenue), 2) AS avg_clv,
    ROUND(SUM(customer_revenue), 2) AS total_revenue
FROM clv
GROUP BY city
ORDER BY avg_clv DESC;

SELECT
    pa.product_name AS product_a,
    pb.product_name AS product_b,
    COUNT(DISTINCT a.order_id) AS times_bought_together
FROM sales_fact a
JOIN sales_fact b
    ON a.order_id = b.order_id
    AND a.product_id < b.product_id
JOIN dim_products pa ON a.product_id = pa.product_id
JOIN dim_products pb ON b.product_id = pb.product_id
GROUP BY pa.product_name, pb.product_name
HAVING COUNT(DISTINCT a.order_id) >= 3   -- filter noise
ORDER BY times_bought_together DESC
LIMIT 30;

-- Customer Acquisition Trend 
SELECT
    d.year,
    d.month,
    d.month_name,
    COUNT(*) AS new_customers
FROM dim_customers c
JOIN dim_date d ON c.registration_date = d.full_date
GROUP BY d.year, d.month, d.month_name
ORDER BY d.year, d.month;