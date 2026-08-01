
-- Daily revenue
SELECT
    d.full_date,
    SUM(sf.revenue) AS daily_revenue,
    COUNT(DISTINCT sf.order_id) AS order_count,
    ROUND(SUM(sf.revenue) / NULLIF(COUNT(DISTINCT sf.order_id), 0), 2) AS avg_order_value
FROM sales_fact sf
JOIN dim_date d ON sf.date_id = d.date_id
GROUP BY d.full_date
ORDER BY d.full_date;

-- Monthly Revenue
SELECT
    d.year,
    d.month,
    d.month_name,
    SUM(sf.revenue) AS monthly_revenue,
    COUNT(DISTINCT sf.order_id) AS order_count
FROM sales_fact sf
JOIN dim_date d ON sf.date_id = d.date_id
GROUP BY d.year, d.month, d.month_name
ORDER BY d.year, d.month;

--City wise sales
SELECT
    COALESCE(st.city, c.city) AS city,
    SUM(sf.revenue) AS total_revenue,
    COUNT(DISTINCT sf.order_id) AS order_count
FROM sales_fact sf
JOIN dim_customers c ON sf.customer_id = c.customer_id
LEFT JOIN dim_stores st ON sf.store_id = st.store_id
GROUP BY COALESCE(st.city, c.city)
ORDER BY total_revenue DESC;

--Revenue by channel 
SELECT
    CASE WHEN sf.store_id IS NULL THEN 'Online' ELSE 'POS' END AS channel,
    SUM(sf.revenue) AS total_revenue,
    COUNT(DISTINCT sf.order_id) AS order_count,
    ROUND(100.0 * SUM(sf.revenue) / SUM(SUM(sf.revenue)) OVER (), 2) AS pct_of_total_revenue
FROM sales_fact sf
GROUP BY CASE WHEN sf.store_id IS NULL THEN 'Online' ELSE 'POS' END;

-- Top Selling Products (rev)
SELECT
    p.product_id,
    p.product_name,
    p.category,
    SUM(sf.quantity) AS units_sold,
    SUM(sf.revenue) AS total_revenue
FROM sales_fact sf
JOIN dim_products p ON sf.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY total_revenue DESC
LIMIT 20;

-- 6. Top-Selling Products (units) 
SELECT
    p.product_id,
    p.product_name,
    p.category,
    SUM(sf.quantity) AS units_sold
FROM sales_fact sf
JOIN dim_products p ON sf.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY units_sold DESC
LIMIT 20;

-- Revenue by Cat
SELECT
    p.category,
    SUM(sf.revenue) AS total_revenue,
    SUM(sf.quantity) AS units_sold
FROM sales_fact sf
JOIN dim_products p ON sf.product_id = p.product_id
GROUP BY p.category
ORDER BY total_revenue DESC;