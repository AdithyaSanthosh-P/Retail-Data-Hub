# Note: the module name is psycopg, not psycopg3
import psycopg
from datetime import date, timedelta
import calendar

def clear_tables(cur):
    cur.execute("""
        TRUNCATE
        sales_fact,
        inventory_fact,
        shipments_fact,
        web_activity_fact,
        dim_date,
        dim_customers,
        dim_products,
        dim_stores
        RESTART IDENTITY CASCADE;
    """)

#need to modify dim to pd df in future to adapt for add on
def load_dim_customers(cur):
    cur.execute("INSERT INTO dim_customers SELECT * FROM customers;")

def load_dim_products(cur):
    cur.execute("INSERT INTO dim_products SELECT * FROM products;")

def load_dim_stores(cur):
    cur.execute("INSERT INTO dim_stores SELECT * FROM stores;")

def load_dim_date(cur):
    holidays = {
        date(2025, 1, 1): "New Year's Day",
        date(2025, 8, 15): "Independence Day",
        date(2025, 10, 2): "Gandhi Jayanti",
        date(2025, 12, 25): "Christmas"
    }
    start_date = date(2025, 1, 1)
    end_date = date(2025, 12, 31)

    rows = []

    current = start_date

    while current <= end_date:

        rows.append((
            int(current.strftime("%Y%m%d")),
            current,
            current.day,
            current.month,
            current.strftime("%B"),
            (current.month - 1) // 3 + 1,
            current.year,
            current.strftime("%A"),
            current.weekday() >= 5,
            current.day == 1,
            current.day == calendar.monthrange(current.year, current.month)[1],
            current in holidays,
            holidays.get(current)
        ))

        current += timedelta(days=1)

    cur.executemany("""
        INSERT INTO dim_date (
            date_id,
            full_date,
            day,
            month,
            month_name,
            quarter,
            year,
            weekday_name,
            is_weekend,
            is_month_start,
            is_month_end,
            is_holiday,
            holiday_name
        )
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s);
    """, rows)

def load_sales_fact(cur):
    cur.execute("""
        INSERT INTO sales_fact (
            order_id,
            date_id,
            customer_id,
            product_id,
            store_id,
            quantity,
            unit_price,
            revenue
        )
        SELECT 
            o.order_id,
            d.date_id,
            o.customer_id,
            oi.product_id,
            o.store_id,
            oi.quantity,
            oi.unit_price,
            oi.quantity * oi.unit_price
        FROM 
            Orders o
            JOIN Order_Items oi
                ON o.order_id = oi.order_id
            JOIN dim_date d
                ON o.order_date::date = d.full_date;
    """)
    
def load_inventory_fact(cur):
    cur.execute("""
        INSERT INTO inventory_fact (
            date_id,
            store_id,
            product_id,
            quantity_on_hand,
            reorder_level,
            stock_status
        )
        SELECT
            d.date_id,
            i.store_id,
            i.product_id,
            i.quantity_on_hand,
            i.reorder_level,
            i.stock_status
        FROM Inventory i
        JOIN dim_date d
            ON i.last_updated::date = d.full_date;
    """)

def load_shipments_fact(cur):
    cur.execute("""
        INSERT INTO shipments_fact (
            shipment_id,
            order_id,
            customer_id,
            shipment_date_id,
            delivery_date_id,
            status,
            delivery_time_days
        )
        SELECT
            s.shipment_id,
            s.order_id,
            o.customer_id,
            sd.date_id,
            dd.date_id,
            s.status,
            s.delivery_time_days
        FROM Shipments s
        JOIN Orders o
            ON s.order_id = o.order_id
        JOIN dim_date sd
            ON s.shipment_date = sd.full_date
        JOIN dim_date dd
            ON s.delivery_date = dd.full_date;
    """)

def load_web_activity_fact(cur):
    cur.execute("""
        INSERT INTO web_activity_fact (
            date_id,
            customer_id,
            product_id,
            action,
            session_id
        )
        SELECT
            d.date_id,
            w.customer_id,
            w.product_id,
            w.action,
            w.session_id
        FROM Web_Logs w
        JOIN dim_date d
            ON w.view_date::date = d.full_date;
    """)

def main():
    # Connect to an existing database
    with psycopg.connect("dbname=retail_hub user=adi") as conn:

        # Open a cursor to perform database operations
        with conn.cursor() as cur:
            # cur.execute("SELECT * FROM customers")
            # for i in cur.fetchall():
            #     print(i)
        
            clear_tables(cur)

            load_dim_customers(cur)
            load_dim_products(cur)
            load_dim_stores(cur)
            load_dim_date(cur)

            load_sales_fact(cur)
            load_inventory_fact(cur)
            load_shipments_fact(cur)
            load_web_activity_fact(cur)

            # Make the changes to the database persistent
            conn.commit()

if __name__=="__main__":
    main()