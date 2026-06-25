
--dbg
DROP TABLE IF EXISTS sales_fact CASCADE;
DROP TABLE IF EXISTS inventory_fact CASCADE;
DROP TABLE IF EXISTS shipments_fact CASCADE;
DROP TABLE IF EXISTS web_activity_fact CASCADE;

DROP TABLE IF EXISTS dim_date CASCADE;
DROP TABLE IF EXISTS dim_customers CASCADE;
DROP TABLE IF EXISTS dim_products CASCADE;
DROP TABLE IF EXISTS dim_stores CASCADE;

CREATE TABLE dim_date (
    date_id INT PRIMARY KEY,
    full_date DATE NOT NULL UNIQUE,
    day INT,
    month INT,
    month_name VARCHAR(20),
    quarter INT,
    year INT
);

CREATE TABLE dim_customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(255),
    email VARCHAR(255),
    city VARCHAR(255),
    registration_date DATE,
    customer_type VARCHAR(100)
);

CREATE TABLE dim_products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(255),
    category VARCHAR(255),
    price DECIMAL(10,2)
);

CREATE TABLE dim_stores (
    store_id INT PRIMARY KEY,
    store_name VARCHAR(255),
    city VARCHAR(255),
    region VARCHAR(255),
    opening_date DATE
);


CREATE TABLE sales_fact (
    sales_id SERIAL PRIMARY KEY,

    order_id INT NOT NULL,
    date_id INT NOT NULL,
    customer_id INT NOT NULL,
    product_id INT NOT NULL,
    store_id INT,

    quantity INT NOT NULL,
    unit_price DECIMAL(10,2),
    revenue DECIMAL(10,2),

    FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (customer_id) REFERENCES dim_customers(customer_id),
    FOREIGN KEY (product_id) REFERENCES dim_products(product_id),
    FOREIGN KEY (store_id) REFERENCES dim_stores(store_id)
);


CREATE TABLE inventory_fact (
    inventory_id SERIAL PRIMARY KEY,

    date_id INT NOT NULL,
    store_id INT NOT NULL,
    product_id INT NOT NULL,

    quantity_on_hand INT,
    reorder_level INT,
    stock_status VARCHAR(50),

    FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (store_id) REFERENCES dim_stores(store_id),
    FOREIGN KEY (product_id) REFERENCES dim_products(product_id)
);


CREATE TABLE shipments_fact (
    shipment_id INT PRIMARY KEY,

    order_id INT,
    customer_id INT,
    shipment_date_id INT,
    delivery_date_id INT,

    status VARCHAR(50),
    delivery_time_days INT,

    FOREIGN KEY (customer_id) REFERENCES dim_customers(customer_id),
    FOREIGN KEY (shipment_date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (delivery_date_id) REFERENCES dim_date(date_id)
);


CREATE TABLE web_activity_fact (
    web_activity_id SERIAL PRIMARY KEY,

    date_id INT,
    customer_id INT,
    product_id INT,
    action VARCHAR(50),
    session_id VARCHAR(255),

    FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (customer_id) REFERENCES dim_customers(customer_id),
    FOREIGN KEY (product_id) REFERENCES dim_products(product_id)
);


CREATE INDEX idx_sales_date ON sales_fact(date_id);
CREATE INDEX idx_sales_customer ON sales_fact(customer_id);
CREATE INDEX idx_sales_product ON sales_fact(product_id);

CREATE INDEX idx_inventory_store ON inventory_fact(store_id);
CREATE INDEX idx_inventory_product ON inventory_fact(product_id);

CREATE INDEX idx_shipment_customer ON shipments_fact(customer_id);

CREATE INDEX idx_web_customer ON web_activity_fact(customer_id);
CREATE INDEX idx_web_product ON web_activity_fact(product_id);