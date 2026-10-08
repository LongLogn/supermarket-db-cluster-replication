import random
import time

from locust import HttpUser, between, task


class SupermarketReader(HttpUser):
    wait_time = between(0.2, 0.8)
    host = "http://localhost:6033"

    @task(3)
    def read_product_catalog(self):
        product_id = random.randint(1, 6)
        self.client.get(f"/query?product_id={product_id}", name="read_products")

    @task(1)
    def read_orders_summary(self):
        self.client.get("/query?report=orders", name="read_order_summary")

    @task(1)
    def read_customers(self):
        self.client.get("/query?report=customers", name="read_customers")
