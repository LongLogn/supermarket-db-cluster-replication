import time
import mysql.connector
from mysql.connector import Error

MASTER_CONFIG = {
    'host': '127.0.0.1',
    'port': 3307,
    'user': 'appuser',
    'password': 'apppass',
    'database': 'supermarket',
    'autocommit': True,
}

SLAVE_CONFIG = {
    'host': '127.0.0.1',
    'port': 3308,
    'user': 'appuser',
    'password': 'apppass',
    'database': 'supermarket',
    'autocommit': True,
}


def get_connection(config):
    return mysql.connector.connect(**config)


def wait_for_replication(table_name: str, expected_value: int, timeout: int = 20):
    deadline = time.time() + timeout
    while time.time() < deadline:
        with get_connection(SLAVE_CONFIG) as conn:
            with conn.cursor() as cursor:
                cursor.execute(f"SELECT COUNT(*) FROM {table_name} WHERE product_id = %s", (expected_value,))
                count = cursor.fetchone()[0]
                if count > 0:
                    return True
        time.sleep(1)
    return False


def main():
    product_name = f"Test Product {int(time.time())}"

    with get_connection(MASTER_CONFIG) as conn:
        with conn.cursor() as cursor:
            cursor.execute(
                "INSERT INTO products (product_name, category_id, supplier_id, unit_price, stock_quantity) VALUES (%s, 1, 1, 25000, 50)",
                (product_name,),
            )
            product_id = cursor.lastrowid

    print(f"Inserted product id: {product_id}")

    if not wait_for_replication('products', product_id):
        raise RuntimeError('Replication did not propagate to the slave in time.')

    with get_connection(SLAVE_CONFIG) as conn:
        with conn.cursor() as cursor:
            cursor.execute("SELECT product_name FROM products WHERE product_id = %s", (product_id,))
            result = cursor.fetchone()
            if result is None or result[0] != product_name:
                raise RuntimeError('Slave data mismatch after replication.')

    try:
        with get_connection(SLAVE_CONFIG) as conn:
            with conn.cursor() as cursor:
                cursor.execute("INSERT INTO products (product_name, category_id, supplier_id, unit_price, stock_quantity) VALUES ('should fail', 1, 1, 1000, 1)")
        raise AssertionError('Write operation on slave should have been blocked by read_only=1.')
    except Error as exc:
        print(f"Slave write blocked as expected: {exc}")

    print("Replication and read-only enforcement checks passed.")


if __name__ == '__main__':
    main()
