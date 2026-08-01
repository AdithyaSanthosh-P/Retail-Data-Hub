
-- 1. Inventory Turnover Ratio (approximate, per product)
SELECT
    p.product_id,
    p.product_name,
    COALESCE(sold.units_sold, 0) AS units_sold_period,
    inv.total_on_hand,
    ROUND(COALESCE(sold.units_sold, 0)::NUMERIC / NULLIF(inv.total_on_hand, 0), 2) AS turnover_ratio
FROM (
    SELECT product_id, SUM(quantity_on_hand) AS total_on_hand
    FROM inventory_fact
    GROUP BY product_id
) inv
JOIN dim_products p ON inv.product_id = p.product_id
LEFT JOIN (
    SELECT product_id, SUM(quantity) AS units_sold
    FROM sales_fact
    GROUP BY product_id
) sold ON sold.product_id = inv.product_id
ORDER BY turnover_ratio DESC NULLS LAST;

-- 2. Inventory Turnover by Store
SELECT
    st.store_id,
    st.store_name,
    st.city,
    COALESCE(sold.units_sold, 0) AS units_sold_period,
    inv.total_on_hand,
    ROUND(COALESCE(sold.units_sold, 0)::NUMERIC / NULLIF(inv.total_on_hand, 0), 2) AS turnover_ratio
FROM (
    SELECT store_id, SUM(quantity_on_hand) AS total_on_hand
    FROM inventory_fact
    GROUP BY store_id
) inv
JOIN dim_stores st ON inv.store_id = st.store_id
LEFT JOIN (
    SELECT store_id, SUM(quantity) AS units_sold
    FROM sales_fact
    WHERE store_id IS NOT NULL
    GROUP BY store_id
) sold ON sold.store_id = inv.store_id
ORDER BY turnover_ratio DESC NULLS LAST;

-- 3. Average Delivery Time (overall + by status)
SELECT
    status,
    COUNT(*) AS shipment_count,
    ROUND(AVG(delivery_time_days), 2) AS avg_delivery_days,
    MIN(delivery_time_days) AS min_days,
    MAX(delivery_time_days) AS max_days
FROM shipments_fact
GROUP BY status
ORDER BY shipment_count DESC;

-- 4. Average Delivery Time by Destination City (via customer)
SELECT
    c.city,
    COUNT(*) AS shipment_count,
    ROUND(AVG(sf.delivery_time_days), 2) AS avg_delivery_days
FROM shipments_fact sf
JOIN dim_customers c ON sf.customer_id = c.customer_id
GROUP BY c.city
ORDER BY avg_delivery_days DESC;

-- 5. Stock-Out Analysis (by store)
SELECT
    st.store_id,
    st.store_name,
    st.city,
    COUNT(*) FILTER (WHERE inv.stock_status = 'out_of_stock') AS out_of_stock_count,
    COUNT(*) FILTER (WHERE inv.stock_status = 'low_stock') AS low_stock_count,
    COUNT(*) AS total_sku_count,
    ROUND(100.0 * COUNT(*) FILTER (WHERE inv.stock_status = 'out_of_stock') / COUNT(*), 2) AS pct_out_of_stock
FROM inventory_fact inv
JOIN dim_stores st ON inv.store_id = st.store_id
GROUP BY st.store_id, st.store_name, st.city
ORDER BY pct_out_of_stock DESC;

-- 6. Stock-Out Analysis (by product -- which SKUs are most problematic)
SELECT
    p.product_id,
    p.product_name,
    p.category,
    COUNT(*) FILTER (WHERE inv.stock_status = 'out_of_stock') AS stores_out_of_stock,
    COUNT(*) AS stores_carrying_product
FROM inventory_fact inv
JOIN dim_products p ON inv.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category
HAVING COUNT(*) FILTER (WHERE inv.stock_status = 'out_of_stock') > 0
ORDER BY stores_out_of_stock DESC;

-- 7. Seasonal Demand Trends (monthly units sold by category)
SELECT
    d.year,
    d.month,
    d.month_name,
    p.category,
    SUM(sf.quantity) AS units_sold
FROM sales_fact sf
JOIN dim_date d ON sf.date_id = d.date_id
JOIN dim_products p ON sf.product_id = p.product_id
GROUP BY d.year, d.month, d.month_name, p.category
ORDER BY d.year, d.month, units_sold DESC;

-- 8. Weekend vs Weekday Demand (quick seasonality cut)
SELECT
    d.is_weekend,
    SUM(sf.quantity) AS units_sold,
    SUM(sf.revenue) AS total_revenue,
    COUNT(DISTINCT sf.order_id) AS order_count
FROM sales_fact sf
JOIN dim_date d ON sf.date_id = d.date_id
GROUP BY d.is_weekend;