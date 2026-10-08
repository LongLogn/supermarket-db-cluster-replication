# Quy trình hoạt động của hệ thống MySQL Cluster

## 1. Tổng quan

Hệ thống chúng ta đang xây dựng là một mô hình cơ sở dữ liệu phân tán gồm:
- 1 Master
- 2 Slave
- 1 ProxySQL làm bộ điều phối truy vấn

Mục tiêu của mô hình này là:
- Chỉ cho phép ghi dữ liệu ở Master
- Chuyển các truy vấn đọc sang Slave
- Đồng bộ dữ liệu từ Master sang Slave
- Giảm tải cho Master
- Bảo vệ dữ liệu không bị sửa trực tiếp trên Slave

---

## 2. Cách hệ thống hoạt động

### 2.1 ProxySQL làm trung tâm điều hướng

ProxySQL là nơi mọi ứng dụng hoặc người dùng kết nối trước. Thay vì kết nối trực tiếp vào MySQL, họ sẽ kết nối vào ProxySQL.

ProxySQL sẽ kiểm tra từng câu SQL:
- Nếu câu lệnh là INSERT, UPDATE, DELETE:
  - nó sẽ gửi thẳng tới Master
- Nếu câu lệnh là SELECT:
  - nó sẽ gửi theo vòng luân phiên (Round-Robin) tới Slave 1 hoặc Slave 2

Nói đơn giản:
- Ghi → Master
- Đọc → Slave

Vì vậy, Master không bị quá tải khi có nhiều truy vấn đọc.

---

### 2.2 MySQL Replication đồng bộ dữ liệu

Master và 2 Slave hoạt động theo cơ chế replicated data.

#### Master
Master là nơi lưu dữ liệu chính. Khi có thao tác ghi, MySQL sẽ ghi sự kiện vào binary log.

#### Slave
Mỗi Slave sẽ kết nối tới Master và thực hiện 2 nhiệm vụ chính:
- I/O Thread:
  - Kết nối sang Master
  - Lấy các thay đổi dữ liệu mới từ binary log
- SQL Thread:
  - Đọc các thay đổi đó
  - Thực thi lại trên database của Slave

Nhờ vậy, dữ liệu trên Slave sẽ giống với dữ liệu trên Master.

---

### 2.3 Slave chỉ được đọc, không được ghi

Hai Slave được kích hoạt chế độ:
- read_only = 1

Nghĩa là:
- Slave chỉ cho phép thực hiện SELECT
- Nếu cố tình ghi vào Slave thì hệ thống sẽ từ chối

Điều này rất quan trọng vì:
- đảm bảo dữ liệu trên Slave không bị lệch
- tránh sai sót khi người dùng ghi nhầm vào Slave
- giữ cho dữ liệu luôn thống nhất theo hướng Master → Slave

---

## 3. Quy trình khi demo trên 3 máy

Khi demo trên thực tế, mỗi người sẽ chạy một máy riêng.

### Máy Long – Master + ProxySQL
Long sẽ chạy container cho:
- Master
- ProxySQL

Sau khi chạy xong, Long kiểm tra trạng thái Master bằng lệnh:

```sql
SHOW MASTER STATUS;
```

Lúc này hệ thống sẽ trả về thông tin ví dụ:
- File: mysql-bin.000001
- Position: 156

Long sẽ chia sẻ cho Dương và Cường:
- IP của máy Long
- File log
- Position hiện tại

---

### Máy Dương – Slave 1
Dương chạy container Slave 1 và cấu hình:

```sql
CHANGE MASTER TO
  MASTER_HOST='192.168.1.15',
  MASTER_USER='repl_user',
  MASTER_PASSWORD='matkhau123',
  MASTER_LOG_FILE='mysql-bin.000001',
  MASTER_LOG_POS=156;

START SLAVE;

SHOW SLAVE STATUS\G;
```

Nếu:
- Slave_IO_Running = Yes
- Slave_SQL_Running = Yes

thì Slave 1 đã kết nối thành công với Master.

---

### Máy Cường – Slave 2
Cường làm tương tự nhưng dùng cấu hình Slave 2:

```sql
CHANGE MASTER TO
  MASTER_HOST='192.168.1.15',
  MASTER_USER='repl_user',
  MASTER_PASSWORD='matkhau123',
  MASTER_LOG_FILE='mysql-bin.000001',
  MASTER_LOG_POS=156;

START SLAVE;

SHOW SLAVE STATUS\G;
```

Nếu có trạng thái chạy thành công thì Slave 2 cũng đã sẵn sàng.

---

## 4. Cập nhật ProxySQL

Sau khi 2 Slave đã kết nối tới Master, cần cấu hình ProxySQL để biết:
- Master là nơi ghi dữ liệu
- Slave 1 và Slave 2 là nơi đọc dữ liệu

Ví dụ:
- Writer: 127.0.0.1:3306
- Reader 1: IP_Dương:3306
- Reader 2: IP_Cường:3306

Sau đó, ProxySQL sẽ:
- yêu cầu ghi đi qua Master
- yêu cầu đọc phân phối đều giữa 2 Slave

---

## 5. Kịch bản demo trước giảng viên

### 5.1 Demo dữ liệu đồng bộ
- Long chạy một câu INSERT trên Master
- Dương chạy SELECT trên Slave 1
- Cường chạy SELECT trên Slave 2

Nếu cả 2 Slave đều hiển thị dữ liệu vừa insert, nghĩa là replication đang hoạt động tốt.

---

### 5.2 Demo Slave không được ghi
- Dương hoặc Cường thử chạy lệnh INSERT trực tiếp trên máy của mình

Nếu hệ thống báo lỗi:
- “read-only mode”
- hoặc lỗi về quyền ghi

nghĩa là Slave đang hoạt động đúng cách và không cho phép ghi.

---

### 5.3 Demo cân bằng tải
- Gửi nhiều câu SELECT qua ProxySQL
- Quan sát phân phối truy vấn

Nếu nhận thấy truy vấn được chia đều giữa Slave 1 và Slave 2, thì ProxySQL đang làm nhiệm vụ đúng.

---

## 6. Kết luận

Hệ thống này có ý nghĩa rất rõ:
- Master là nơi ghi dữ liệu
- Slave là nơi đọc dữ liệu
- Replication đảm bảo dữ liệu đồng bộ
- ProxySQL giúp chia tải và tối ưu hiệu năng
- Slave read-only giúp bảo vệ dữ liệu

Nói ngắn gọn, đây là mô hình phù hợp để:
- xử lý lượng truy vấn lớn
- tách biệt đọc/ghi
- tăng tốc độ truy xuất
- đảm bảo dữ liệu được đồng bộ và an toàn

---