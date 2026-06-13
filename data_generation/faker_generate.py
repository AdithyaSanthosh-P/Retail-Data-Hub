from faker import Faker
from datetime import datetime, timedelta
import random
import psycopg
from products import PRODUCT_CATALOG

fake = Faker("en_IN") 

# Database connection variables have been removed, might consider switching from peer auth to passwd auth

# Data counts
#NEed to update random() range to abide by decided data counts
#ex generate web logs can create 200000 web logs although limit here is 40k
NUM_CUSTOMERS = 5000
NUM_ORDERS = 20000
NUM_PRODUCTS = 100
NUM_STORES = 20
NUM_WEB_LOGS = 40000  

# Lists for random choice
CITIES = ["Mumbai", "Delhi", "Bangalore", "Chennai"]
CATEGORIES = ["Electronics", "Clothing", "Home & Garden", "Sports", "Books", "Beauty", "Food & Grocery"]
PAYMENT_METHODS = ["cash", "card", "upi", "wallet"]
ORDER_CHANNELS = ["POS", "Online"]
WEB_ACTIONS = ["view", "add_to_cart", "remove_from_cart", "search", "purchase"]
CUSTOMER_TYPES = ["new", "returning", "both"]
STOCK_STATUSES = ["active", "low_stock", "out_of_stock"]
SHIPMENT_STATUSES = ["delivered", "in_transit", "pending"]

# Date range for each tables 
STORE_OPEN_START = datetime(2019, 1, 1)
STORE_OPEN_END   = datetime(2024, 12, 31)

CUSTOMER_REG_START = datetime(2022, 1, 1)
CUSTOMER_REG_END   = datetime(2025, 6, 30)

ORDER_START = datetime(2025, 1, 1)
ORDER_END   = datetime(2025, 6, 30)

WEBLOG_START = datetime(2025, 1, 1)
WEBLOG_END   = datetime(2025, 6, 30)

INVENTORY_START = datetime(2025, 5, 1)
INVENTORY_END   = datetime(2025, 6, 30)

#This will help to track column "status" in shipments table 
#After finishin the mvp I must modify this to consider regular updates 
SIMULATION_DATE = datetime(2025, 7, 1) 



#All the generating functions:
'''
records = generate_customers()

for x in records:
    for i, j in x.items():
        print(i + ": " + str(j))

print(len(records))
'''

def generate_customer(id):
    customer = {
        "customer_id": id,
        "customer_name": fake.name(),
        "email": fake.unique.email(),
        "city": random.choice(CITIES),
        "registration_date": fake.date_between(
            start_date=CUSTOMER_REG_START,
            end_date=CUSTOMER_REG_END
        ),
        "customer_type": random.choice(CUSTOMER_TYPES)
    }

    return customer

def generate_customers():
    resultarr=[]
    for i in range(1, NUM_CUSTOMERS+1):
        # resultarr+=generate_customer(i)
        resultarr.append(generate_customer(i))
    return resultarr
        
def generate_store(store_id):
    store = {
        "store_id": store_id,
        "store_name": fake.company(),
        "city": random.choice(CITIES),
        "region": random.choice([
            "North",
            "South",
            "East",
            "West"
        ]),
        "opening_date": fake.date_between(
            start_date=STORE_OPEN_START,
            end_date=STORE_OPEN_END
        )
    }

    return store

def generate_stores():
    resultarr = []

    for store_id in range(1, NUM_STORES + 1):
        resultarr.append(
            generate_store(store_id)
        )

    return resultarr

def generate_product(product_id):

    category = random.choice(
        list(PRODUCT_CATALOG.keys())
    )

    product_name, base_price = random.choice(
        PRODUCT_CATALOG[category]
    )

    product = {
        "product_id": product_id,
        "product_name": product_name,
        "category": category,
        "price": round(
            random.uniform(
                base_price * 0.8,
                base_price * 1.2
            ),
            2
        )
    }

    return product

def generate_products():

    resultarr = []

    for product_id in range(
        1,
        NUM_PRODUCTS + 1
    ):
        resultarr.append(
            generate_product(product_id)
        )

    return resultarr

def generate_orders(customers, products, stores):

    orders = []
    order_items = []

    order_item_id = 1

    for order_id in range(1, NUM_ORDERS + 1):

        channel = random.choice(ORDER_CHANNELS)

        if channel == "POS":
            store_id = random.choice(stores)["store_id"]
        else:
            store_id = None

        customer_id = random.choice(customers)["customer_id"]

        order_date = fake.date_time_between(
            start_date=ORDER_START,
            end_date=ORDER_END
        )

        if channel == "POS":
            payment_method = random.choice([
                "cash",
                "card",
                "upi"
            ])
        else:
            payment_method = random.choice([
                "card",
                "upi",
                "wallet"
            ])

        discount = 0

        if random.random() < 0.3:
            discount = round(
                random.uniform(50, 500),
                2
            )

        total_amount = 0

        num_items = random.randint(1, 4)

        for _ in range(num_items):

            product = random.choice(products)

            quantity = random.randint(1, 5)

            order_item = {
                "order_item_id": order_item_id,
                "order_id": order_id,
                "product_id": product["product_id"],
                "quantity": quantity,
                "unit_price": product["price"]
            }

            order_items.append(order_item)

            total_amount += (
                quantity * product["price"]
            )

            order_item_id += 1

        order = {
            "order_id": order_id,
            "customer_id": customer_id,
            "store_id": store_id,
            "order_date": order_date,
            "channel": channel,
            "total_amount": max(
                0,
                total_amount - discount
            ),
            "payment_method": payment_method,
            "discount": discount
        }

        orders.append(order)

    return orders, order_items

def generate_inventory(stores, products):

    inventory = []

    inventory_id = 1

    for store in stores:

        for product in products:

            quantity_on_hand = random.randint(0, 500)

            reorder_level = random.randint(20, 100)

            if quantity_on_hand == 0:
                stock_status = "out_of_stock"

            elif quantity_on_hand < reorder_level:
                stock_status = "low_stock"

            else:
                stock_status = "active"

            inventory_record = {
                "inventory_id": inventory_id,
                "store_id": store["store_id"],
                "product_id": product["product_id"],
                "quantity_on_hand": quantity_on_hand,
                "reorder_level": reorder_level,
                "last_updated": fake.date_time_between(
                    start_date=INVENTORY_START,
                    end_date=INVENTORY_END
                ),
                "stock_status": stock_status
            }

            inventory.append(
                inventory_record
            )

            inventory_id += 1

    return inventory

def generate_shipments(orders):

    shipments = []

    shipment_id = 1

    for order in orders:

        if order["channel"] != "Online":
            continue

        shipment_date = (
            order["order_date"] +
            timedelta(days=random.randint(0, 2))
        )

        delivery_time_days = random.randint(1, 10)

        expected_delivery_date = (
            shipment_date +
            timedelta(days=delivery_time_days)
        )

        if shipment_date > SIMULATION_DATE:

            status = "pending"

            delivery_date = None

            delivery_time_days = None

        elif expected_delivery_date > SIMULATION_DATE:

            status = "in_transit"

            delivery_date = None

            delivery_time_days = None

        else:

            status = "delivered"

            delivery_date = expected_delivery_date

        shipment = {
            "shipment_id": shipment_id,
            "order_id": order["order_id"],
            "shipment_date": shipment_date,
            "delivery_date": delivery_date,
            "status": status,
            "delivery_time_days": delivery_time_days
        }

        shipments.append(shipment)

        shipment_id += 1

    return shipments

#very basic web log, (randomised)
#Should implement some logic to sequence actions like view and then add to cart instead of using weights in nexy phase
#uuid logic



def generate_web_logs(customers, products): 

    web_logs = []
    web_log_id = 1

    for customer in customers:

        num_sessions = random.randint(2, 5)

        for session_num in range(num_sessions):

            session_id = ("session_" + str(customer["customer_id"]) + "_" + str(session_num))

            session_date = fake.date_time_between(
                start_date=WEBLOG_START,
                end_date=WEBLOG_END
            )

            num_actions = random.randint(1, 5)

            for _ in range(num_actions):

                product = random.choice(products)

                web_log = {
                    "web_log_id": web_log_id,
                    "customer_id": customer["customer_id"],
                    "product_id": product["product_id"],
                    "view_date": session_date + timedelta(
                        minutes=random.randint(0, 60)
                    ),
                    "action": random.choice(WEB_ACTIONS),
                    "session_id": session_id
                }

                web_logs.append(web_log)

                web_log_id += 1

    return web_logs

def insertIntoDatabase():
    # Note: the module name is psycopg, not psycopg3

    # Connect to an existing database
    with psycopg.connect("dbname=retail_hub user=adi") as conn:

        # Open a cursor to perform database operations
        with conn.cursor() as cur:

            # Pass data to fill a query placeholders and let Psycopg perform
            # the correct conversion (no SQL injections!)

            # Query the database and obtain data as Python objects.

            # You can use `cur.executemany()` to perform an operation in batch


            def insert_table(cur, tableName, rows):
                columns = list(rows[0].keys())

                query = f""" INSERT INTO {tableName} ({', '.join(columns)}) VALUES ({', '.join(['%s'] * len(columns))}) """

                values = [
                    tuple(row[col] for col in columns)
                    for row in rows
                ]

                cur.executemany(query, values)

            customers = generate_customers()
            products = generate_products()
            stores = generate_stores()

            insert_table(cur, "Customers", customers)
            insert_table(cur, "Products", products)
            insert_table(cur, "Stores", stores)

            orders, order_items = generate_orders(
                customers,
                products,
                stores
            )

            insert_table(cur, "Orders", orders)
            insert_table(cur, "Order_Items", order_items)

            inventory = generate_inventory(
                stores,
                products
            )

            insert_table(cur, "Inventory", inventory)

            shipments = generate_shipments(orders)

            insert_table(cur, "Shipments", shipments)

            web_logs = generate_web_logs(
                customers,
                products
            )

            insert_table(cur, "Web_Logs", web_logs)


            # Ccode for induvidual tables (repetitive)
            '''
                customer_rows = []
                for c in customers:
                    customer_rows.append(
                        (
                            c["customer_id"],
                            c["customer_name"],
                            c["email"],
                            c["city"],
                            c["registration_date"],
                            c["customer_type"]
                        )
                    )

                cur.executemany(
                    "INSERT INTO Customers (customer_id, customer_name, email, city, registration_date, customer_type) values (%s, %s, %s, %s, %s, %s)",
                    customer_rows
                )
            '''
            


            # Make the changes to the database persistent
            conn.commit()

insertIntoDatabase()