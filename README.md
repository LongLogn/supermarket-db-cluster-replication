# Supermarket Database Cluster (1 Master - 2 Slaves Replication & Load Balancing)

Dự án bài tập lớn môn **Hệ quản trị Cơ sở dữ liệu**.  
Đề tài: **A2 - Thiết lập nhân bản 1 Master, 2 Slave áp dụng cho CSDL siêu thị**.

---

## 1. Giới thiệu dự án

Hệ thống mô phỏng kiến trúc phân tán cơ sở dữ liệu cho một chuỗi siêu thị nhằm tối ưu hóa hiệu năng và tăng độ sẵn sàng:
* **Phân tách Đọc/Ghi (Read/Write Splitting):** Toàn bộ thao tác ghi (`INSERT`, `UPDATE`, `DELETE`) từ quầy thanh toán được tập trung về **Master**. Mọi truy vấn tra cứu, báo cáo (`SELECT`) được điều hướng sang **2 Slave**.
* **Đồng bộ tự động (Replication):** Dữ liệu được đồng bộ liên tục từ Master sang 2 Slave thông qua cơ chế MySQL Binary Log (chế độ ROW).
* **Bảo đảm an toàn dữ liệu:** Hai node Slave kích hoạt cờ `read_only = 1`, từ chối mọi thao tác ghi thủ công từ bên ngoài.
* **Cân bằng tải (Load Balancing):** Dùng ProxySQL điều phối truy vấn tự động theo thuật toán Round-Robin cho 2 node Slave.

---

## 2. Thành viên & Phân công nhiệm vụ

* **Trần Hoàng Long (24022813):** Xây dựng hạ tầng (Docker/Cluster), cấu hình đồng bộ Replication Master-Slave và thiết lập tầng cân bằng tải ProxySQL.
* **Quách Đại Dương (24021444):** Phân tích mô hình ERD, xây dựng Schema CSDL Siêu thị (`schema.sql`) và tạo tập dữ liệu mẫu (`seed_data.sql`).
* **Nguyễn Văn Cường (23020019):** Xây dựng kịch bản kiểm thử (Stress Test, Data Consistency, Read-only Enforcement) và đo đạc hiệu năng.

---

## 3. Cấu trúc thư mục

```text
hqtcsdl-supermarket-cluster/
├── README.md                          # Tài liệu hướng dẫn dự án
├── .gitignore
│
├── infra/                             # Module Hạ tầng & Cân bằng tải (Long)
│   ├── docker-compose.yml             # Định nghĩa cụm 3 DB + ProxySQL
│   ├── config/
│   │   ├── master.cnf                 # Cấu hình log-bin, server-id=1
│   │   ├── slave1.cnf                 # Cấu hình read_only, server-id=2
│   │   ├── slave2.cnf                 # Cấu hình read_only, server-id=3
│   │   └── proxysql.cnf               # Luật phân luồng Read/Write
│   └── scripts/
│       ├── 01-init-master.sql         # Tạo user replication
│       └── 02-setup-replication.sh    # Script tự động nối Slave vào Master
│
├── database/                          # Module Thiết kế CSDL (Dương)
│   ├── docs/
│   │   └── erd_diagram.png            # Sơ đồ quan hệ thực thể ERD
│   ├── 01_schema.sql                  # Script tạo bảng hệ thống siêu thị
│   └── 02_seed_data.sql               # Dữ liệu kiểm thử ban đầu
│
├── tests/                             # Module Kiểm thử & Hiệu năng (Cường)
│   ├── test_replication.py            # Kiểm thử tính nhất quán & chặn ghi
│   ├── benchmark_locust.py            # Kịch bản bắn tải giả lập truy cập
│   └── results/                       # Báo cáo, đồ thị đo đạc
│
└── docs/                              # Tài liệu báo cáo nhóm
    ├── bao_cao_nhom.docx
    └── slide_thuyet_trinh.pptx 