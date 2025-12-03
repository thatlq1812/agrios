# Lộ trình phát triển Backend Developer (Fresher to Junior)
*Dành cho kỹ sư AI chuyển hướng sang Backend (Go/Microservices)*

Tài liệu này phác thảo lộ trình phát triển kỹ năng backend, tập trung vào hệ sinh thái Go, Microservices và chuẩn bị cho việc tích hợp AI (Phase 3).

## Giai đoạn 1: Củng cố nền tảng (Tuần 1-2)

Mục tiêu: Viết code "chuẩn Go" (Idiomatic Go), dễ đọc, dễ bảo trì và cấu hình đúng chuẩn.

### 1. Refactor & Clean Code
- **Dependency Injection (DI):**
  - Hiện tại: Đang khởi tạo trực tiếp các thành phần.
  - Cải thiện: Truyền các dependencies (như DB connection, Config) vào struct thông qua constructor (hàm `New...`).
- **Layered Architecture:**
  - Đảm bảo tách biệt rõ ràng 3 lớp:
    1. **Handler/Transport:** Nhận request gRPC/HTTP, validate input cơ bản.
    2. **Service/Usecase:** Chứa logic nghiệp vụ (business logic).
    3. **Repository:** Chỉ tương tác với Database (CRUD), không chứa logic nghiệp vụ.
- **Error Handling:**
  - Thay vì check lỗi bằng chuỗi (`strings.Contains`), hãy định nghĩa các biến lỗi chuẩn (Sentinel Errors) như `ErrNotFound`, `ErrDuplicate`.
  - Sử dụng `errors.Is()` để kiểm tra loại lỗi.

### 2. Configuration Management
- **Environment Variables:**
  - Không bao giờ hardcode các thông số nhạy cảm (DB password, API Key, Secret Key).
  - Sử dụng thư viện như `Viper` hoặc `godotenv` để load config từ file `.env` và biến môi trường hệ thống.
  - Cấu hình riêng cho từng môi trường (Dev, Staging, Prod).

### 3. Structured Logging
- Thay thế `fmt.Println` hoặc `log.Println` bằng thư viện log có cấu trúc (JSON).
- Thư viện gợi ý: `log/slog` (có sẵn trong Go 1.21+) hoặc `uber-go/zap`.
- Lợi ích: Dễ dàng filter và search log trên các hệ thống giám sát (ELK, Grafana Loki).

---

## Giai đoạn 2: Chất lượng và Quy trình (Tuần 3-4)

Mục tiêu: Đảm bảo code chạy đúng, ổn định và dễ dàng triển khai.

### 1. Unit Testing
- **Mocking:** Học cách mock các dependencies (ví dụ: mock Repository khi test Service) bằng thư viện `stretchr/testify` và `vektra/mockery`.
- **Table-Driven Tests:** Viết test case theo phong cách đặc trưng của Go.
- **Coverage:** Đặt mục tiêu coverage cho các hàm logic quan trọng (> 80%).

### 2. API Gateway & REST
- **gRPC-Gateway:**
  - Tìm hiểu cách generate RESTful API từ file `.proto` có sẵn.
  - Giúp Frontend/Mobile dễ dàng tích hợp nếu họ chưa hỗ trợ gRPC.
- **Swagger/OpenAPI:** Tự động sinh document API từ code.

### 3. Containerization & Orchestration
- **Docker Compose:**
  - Viết file `docker-compose.yml` để khởi chạy toàn bộ hệ thống (User Service + Article Service + Postgres + Redis) chỉ với 1 lệnh `docker-compose up`.
- **Health Checks:** Thêm endpoint health check cho container.

---

## Giai đoạn 3: Nâng cao & Chuẩn bị cho AI (Tháng 2 trở đi)

Mục tiêu: Xử lý hiệu năng cao và tích hợp các mô hình AI.

### 1. Concurrency (Xử lý đồng thời)
- **Goroutines & Channels:**
  - Hiểu sâu về cơ chế lập lịch của Go (Go Scheduler).
  - Patterns: Worker Pool, Pipeline, Fan-in/Fan-out.
  - Ứng dụng: Xử lý batch job, xử lý dữ liệu song song.

### 2. Message Queue (Hàng đợi thông điệp)
- **Công nghệ:** RabbitMQ hoặc Kafka.
- **Use case cho AI:**
  - User upload ảnh -> API nhận và đẩy vào Queue -> Trả về "Processing".
  - AI Worker (Python/Go) lấy ảnh từ Queue -> Xử lý -> Cập nhật kết quả vào DB.
  - Giúp hệ thống không bị treo khi AI model chạy lâu.

### 3. Python Interop (Giao tiếp với Python)
- Xây dựng một AI Service nhỏ bằng Python (FastAPI hoặc gRPC Python).
- Thực hành gọi gRPC từ Go Service sang Python Service.
- Chia sẻ file `.proto` giữa Go và Python để đảm bảo data contract.

### 4. Caching & Performance
- **Redis:** Sử dụng Redis để cache các dữ liệu hay truy vấn (ví dụ: thông tin User, danh sách bài viết hot).
- **Database Indexing:** Tối ưu query SQL.

---

## Tài nguyên học tập gợi ý

1. **Sách:** "Let's Go" và "Let's Go Further" (Alex Edwards) - Rất thực tế.
2. **Github:** Đọc code của các dự án Go nổi tiếng (ví dụ: `moby/moby` (Docker), `kubernetes/kubernetes`, `gofiber/fiber`).
3. **Practice:** Thử viết lại một project nhỏ (như To-Do List) nhưng áp dụng đầy đủ các kiến thức trên.
