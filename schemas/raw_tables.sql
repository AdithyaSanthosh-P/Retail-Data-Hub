CREATE TABLE Customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    city VARCHAR(255),
    registration_date DATE,
    customer_type VARCHAR(100)
);

CREATE TABLE Stores (
    store_id INT PRIMARY KEY,
    store_name VARCHAR(255) NOT NULL,
    city VARCHAR(255),
    region VARCHAR(255),
    opening_date DATE
);

CREATE TABLE Products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    category VARCHAR(255),
    price DECIMAL(10, 2),
    stock_status VARCHAR(50)
);

CREATE TABLE Orders (
    order_id INT PRIMARY KEY, 
    customer_id INT NOT NULL, 
    store_id INT, 
    order_date TIMESTAMP NOT NULL, 
    channel VARCHAR(50), 
    total_amount DECIMAL(10, 2), 
    payment_method VARCHAR (50),
    discount DECIMAL(10, 2),

    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id),
    FOREIGN KEY (store_id) REFERENCES Stores(store_id)
);

CREATE TABLE Order_Items (
    order_item_id INT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

CREATE TABLE Inventory (
    inventory_id INT PRIMARY KEY,
    store_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity_on_hand INT NOT NULL,
    reorder_level INT NOT NULL,
    last_updated TIMESTAMP NOT NULL,

    FOREIGN KEY (store_id) REFERENCES Stores(store_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

CREATE TABLE Shipments (
    shipment_id INT PRIMARY KEY,
    order_id INT NOT NULL,
    shipment_date DATE,
    delivery_date DATE,
    status VARCHAR(50),
    delivery_time_days INT,

    FOREIGN KEY (order_id) REFERENCES Orders(order_id)
);

CREATE TABLE Web_Logs (
    web_log_id INT PRIMARY KEY,
    customer_id INT NOT NULL,
    product_id INT NOT NULL,
    view_date TIMESTAMP NOT NULL,
    action VARCHAR(50) NOT NULL,
    session_id VARCHAR(255) NOT NULL,

    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);