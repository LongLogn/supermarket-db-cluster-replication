USE supermarket;

INSERT INTO categories (category_name, description) VALUES
('Thực phẩm', 'Sản phẩm thực phẩm tươi sống và đồ khô'),
('Đồ uống', 'Nước uống, nước ngọt, sinh tố'),
('Gia dụng', 'Hàng hóa gia dụng và vệ sinh');

INSERT INTO suppliers (supplier_name, phone, email, address) VALUES
('Công ty TNHH FoodBest', '0909001111', 'sales@foodbest.vn', 'Hồ Chí Minh'),
('Nhà phân phối FreshDrink', '0909111222', 'support@freshdrink.vn', 'Đà Nẵng'),
('Kho hàng HomeCare', '0909222333', 'hello@homecare.vn', 'Hà Nội');

INSERT INTO products (product_name, category_id, supplier_id, unit_price, stock_quantity) VALUES
('Gạo ST25', 1, 1, 32000, 150),
('Sữa tươi Vinamilk', 1, 1, 26000, 200),
('Nước ngọt Coca', 2, 2, 12000, 300),
('Nước cam đóng chai', 2, 2, 15000, 180),
('Bột giặt Ariel', 3, 3, 89000, 90),
('Nước rửa chén Sunlight', 3, 3, 34000, 120);

INSERT INTO customers (full_name, phone, email, address) VALUES
('Nguyễn Văn An', '0911111111', 'an.nguyen@gmail.com', 'Quận 1, TP.HCM'),
('Trần Thị Bình', '0911222233', 'binh.tran@gmail.com', 'Quận 7, TP.HCM'),
('Lê Hoàng Cường', '0911333344', 'cuong.le@gmail.com', 'Đà Nẵng');

INSERT INTO employees (full_name, position_title, hire_date, salary) VALUES
('Phạm Minh Long', 'Quản lý siêu thị', '2022-01-15', 18000000),
('Nguyễn Hồng Nhung', 'Nhân viên thu ngân', '2023-03-10', 9500000),
('Võ Quốc Khánh', 'Kiểm hàng', '2021-09-20', 11000000);

INSERT INTO orders (customer_id, employee_id, total_amount, status) VALUES
(1, 2, 52000, 'PAID'),
(2, 2, 65000, 'PAID'),
(3, 1, 110000, 'PENDING');

INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(1, 1, 1, 32000),
(1, 2, 1, 20000),
(2, 3, 2, 12000),
(2, 5, 1, 89000),
(3, 4, 2, 15000),
(3, 6, 2, 34000);

INSERT INTO inventory_log (product_id, change_type, quantity_change) VALUES
(1, 'SALE', -1),
(2, 'SALE', -1),
(3, 'SALE', -2),
(5, 'SALE', -1),
(4, 'RESTOCK', 10),
(6, 'RESTOCK', 20);
