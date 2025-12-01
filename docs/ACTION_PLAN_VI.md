# Maintainer Profile

**Name:** THAT Le Quang

- **Role:** AI & DS Major Student
- **GitHub:** [thatlq1812]

---

# Kế Hoạch Thực Hiện - Hai Services với gRPC & PostgreSQL

**Ngày:** 1 tháng 12, 2025  
**Tên dự án:** Agrios Microservices Demo  
**Deadline:** 6 giờ (cam kết với quản lý)  
**Phạm vi:** Chỉ CRUD operations  
**Mục đích:** Chứng minh khả năng Golang & gRPC

---

## ⚠️ RÀNG BUỘC QUAN TRỌNG

**🚫 KHÔNG được dùng AI để viết code**

- Anh Lợi cấm sử dụng AI để sinh code
- AI CHỈ được dùng cho:
  - ✅ Đọc tài liệu
  - ✅ Giải thích khái niệm
  - ✅ Tìm tài nguyên
  - ✅ Lên kế hoạch
- ❌ TẤT CẢ code PHẢI tự tay gõ

**⏰ Tiến trình Timeline:**

- Ước tính ban đầu: 3 giờ (có AI)
- Ước tính cuối cùng: **6 giờ** (code thủ công)

---

## Tổng Quan Yêu Cầu

**Cần xây dựng:**  
Hai microservices độc lập giao tiếp qua gRPC:

### Service 1 (user-service) - Quản lý Users

- CRUD cho bảng `users`
- Cung cấp dữ liệu user qua gRPC
- Port: 50051

### Service 2 (article-service) - Quản lý Articles

- CRUD cho bảng `articles`
- Mỗi article thuộc về 1 user (foreign key)
- Gọi Service 1 qua gRPC để lấy thông tin user
- Port: 50052

**Tech Stack:**

- Ngôn ngữ: Golang
- Giao tiếp: gRPC + Protocol Buffers
- Database: PostgreSQL
- Tools: Docker, pgx driver, grpc-go

---

## Kiến Trúc Hệ Thống

```
                    ┌─────────────────────────────┐
                    │     Client / CLI            │
                    └──────────┬──────────────────┘
                               │
                               │ Test CRUD
                               ▼
          ┌────────────────────────────────────────────┐
          │    Service 2: Article Service              │
          │    (Port: 50052)                           │
          │                                            │
          │    - CRUD bảng articles                    │
          │    - article.user_id → foreign key         │
          │    - gRPC Client gọi Service 1             │
          └────────┬──────────────────────┬────────────┘
                   │                      │
                   │ gRPC Call            │ SQL Query
                   │ GetUser(user_id)     │ (bảng articles)
                   │                      │
                   ▼                      ▼
    ┌──────────────────────┐    ┌───────────────────┐
    │  Service 1:          │    │   PostgreSQL      │
    │  User Service        │    │   Database        │
    │  (Port: 50051)       │    │                   │
    │                      │    │   Bảng:           │
    │  - CRUD bảng users   │    │   - users         │
    │  - gRPC Server       │───▶│   - articles      │
    └──────────────────────┘    └───────────────────┘
                 │
                 │ SQL Query
                 │ (bảng users)
                 │
                 └──────────────────┘

Luồng hoạt động:
1. Service 1: Quản lý users độc lập
2. Service 2: Quản lý articles + gọi Service 1 để lấy thông tin user
3. Mỗi article có user_id (foreign key tới users.id)
```

---

## Cấu Trúc Database

### Bảng Users (Service 1)

```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Dữ liệu mẫu:**

```sql
INSERT INTO users (name, email) VALUES
    ('THAT Le Quang', 'that.le@example.com'),
    ('Nguyen Van A', 'nguyenvana@example.com'),
    ('Tran Thi B', 'tranthib@example.com');
```

### Bảng Articles (Service 2)

```sql
CREATE TABLE articles (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    user_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

**Dữ liệu mẫu:**

```sql
INSERT INTO articles (title, content, user_id) VALUES
    ('Bài viết đầu tiên', 'Nội dung về Go language', 1),
    ('Hướng dẫn gRPC', 'Học gRPC với PostgreSQL', 1),
    ('Thiết kế Database', 'Best practices cho database', 2);
```

---

## Kế Hoạch Thực Hiện Chi Tiết (6 Giờ)

### ⏱️ Timeline Tổng Quan

| Giai đoạn     | Nhiệm vụ                                    | Thời gian   | Ưu tiên       | Trạng thái      |
| ------------- | ------------------------------------------- | ----------- | ------------- | --------------- |
| **Sprint 1**  | Setup môi trường & Proto files              | 50 phút     | 🔴 Cao        | ⏳ Chưa bắt đầu |
| **Sprint 2**  | Service 1 - Part 1 (DB + GetUser)           | 60 phút     | 🔴 Cao        | ⏳ Chưa bắt đầu |
| **Sprint 3**  | Service 1 - Part 2 (List, Create, Update)   | 60 phút     | 🔴 Cao        | ⏳ Chưa bắt đầu |
| **Sprint 4**  | Service 1 - Part 3 (Delete + gRPC handlers) | 50 phút     | 🔴 Cao        | ⏳ Chưa bắt đầu |
| **Sprint 5**  | Service 2 - Article Service                 | 80 phút     | 🔴 Cao        | ⏳ Chưa bắt đầu |
| **Sprint 6**  | Testing & Documentation                     | 60 phút     | 🟡 Trung bình | ⏳ Chưa bắt đầu |
| **TỔNG CỘNG** |                                             | **6h 0min** |               |                 |

---

## Chi Tiết Từng Sprint

### 🏃 Sprint 1: Nền Tảng (50 phút)

**Mục tiêu:** Setup PostgreSQL, tạo database schema, viết proto files

#### Bước 1.1: Setup PostgreSQL với Docker (15 phút)

```bash
# Chạy PostgreSQL container
docker run --name agrios-postgres \
  -e POSTGRES_PASSWORD=postgres123 \
  -e POSTGRES_USER=agrios \
  -e POSTGRES_DB=userdb \
  -p 5432:5432 \
  -d postgres:15-alpine

# Kiểm tra đang chạy
docker ps
```

#### Bước 1.2: Tạo Database Schema (10 phút)

```bash
# Kết nối vào database
docker exec -it agrios-postgres psql -U agrios -d userdb

# Chạy các câu lệnh SQL ở trên để tạo bảng
```

#### Bước 1.3: Viết Proto Files (15 phút)

**File:** `shared/proto/user_service.proto`

- Định nghĩa CRUD operations cho User
- Messages: User, CreateUserRequest, UpdateUserRequest, etc.

**File:** `shared/proto/article_service.proto`

- Định nghĩa CRUD operations cho Article
- Messages: Article, ArticleWithUser, UserInfo, etc.

#### Bước 1.4: Generate Go Code (10 phút)

```bash
# Generate cho Service 1
cd service-1-user
protoc --go_out=. --go-grpc_out=. proto/user_service.proto

# Generate cho Service 2
cd service-2-article
protoc --go_out=. --go-grpc_out=. proto/user_service.proto
protoc --go_out=. --go-grpc_out=. proto/article_service.proto
```

**✋ Nghỉ 10 phút**

---

### 🏃 Sprint 2: Service 1 - Phần 1 (60 phút)

**Mục tiêu:** Kết nối database + implement GetUser

#### Bước 2.1: Tạo cấu trúc project (10 phút)

```bash
cd service-1-user
go mod init github.com/thatlq1812/service-1-user
go get google.golang.org/grpc
go get github.com/jackc/pgx/v5
```

#### Bước 2.2: Viết Database Connection (20 phút)

**File:** `internal/db/postgres.go`

- Hàm NewPostgresPool() để tạo connection pool
- Test ping database

#### Bước 2.3: Viết Repository Interface (10 phút)

**File:** `internal/repository/user_repository.go`

- Định nghĩa struct UserRepository
- Khai báo các hàm CRUD (chưa implement)

#### Bước 2.4: Implement GetUser (20 phút)

**File:** `internal/repository/user_repository.go`

- Viết hàm GetUserByID()
- Query: `SELECT * FROM users WHERE id = $1`
- Test với psql trước khi code

**✋ Nghỉ 10 phút**

---

### 🏃 Sprint 3: Service 1 - Phần 2 (60 phút)

**Mục tiêu:** Implement List, Create, Update users

#### Bước 3.1: Implement ListUsers (20 phút)

- Query với pagination: `SELECT * FROM users LIMIT $1 OFFSET $2`
- Count total: `SELECT COUNT(*) FROM users`

#### Bước 3.2: Implement CreateUser (20 phút)

- Query: `INSERT INTO users (name, email) VALUES ($1, $2) RETURNING *`
- Validate email unique

#### Bước 3.3: Implement UpdateUser (20 phút)

- Query: `UPDATE users SET name=$1, email=$2 WHERE id=$3 RETURNING *`
- Check user exists trước khi update

**✋ Nghỉ 10 phút**

---

### 🏃 Sprint 4: Service 1 - Phần 3 (50 phút)

**Mục tiêu:** Hoàn thiện Service 1

#### Bước 4.1: Implement DeleteUser (15 phút)

- Query: `DELETE FROM users WHERE id=$1`
- Return success/failure

#### Bước 4.2: Viết gRPC Server Handlers (25 phút)

**File:** `internal/server/user_server.go`

- Implement tất cả RPC methods
- Call repository methods
- Handle errors với gRPC status codes

#### Bước 4.3: Viết Main Server (10 phút)

**File:** `cmd/server/main.go`

- Load .env file
- Kết nối database
- Start gRPC server trên port 50051

**✋ Nghỉ 15 phút (nghỉ dài hơn)**

---

### 🏃 Sprint 5: Service 2 - Article Service (80 phút)

**Mục tiêu:** CRUD articles + gọi Service 1 qua gRPC

#### Bước 5.1: Setup Service 2 (10 phút)

```bash
cd service-2-article
go mod init github.com/thatlq1812/service-2-article
go get google.golang.org/grpc
go get github.com/jackc/pgx/v5
```

#### Bước 5.2: Database Connection (10 phút)

- Tương tự Service 1
- Kết nối cùng database nhưng làm việc với bảng `articles`

#### Bước 5.3: gRPC Client để gọi Service 1 (20 phút)

**File:** `internal/client/user_client.go`

- Hàm NewUserClient() connect tới localhost:50051
- Wrapper method GetUser(userId)

#### Bước 5.4: Article Repository (30 phút)

**File:** `internal/repository/article_repository.go`

- CreateArticle
- GetArticle + fetch user info từ Service 1
- UpdateArticle
- DeleteArticle
- ListArticles (với user info)

#### Bước 5.5: gRPC Server + Main (10 phút)

- Server handlers gọi repository
- Main.go start server port 50052

**✋ Nghỉ 10 phút**

---

### 🏃 Sprint 6: Testing & Documentation (60 phút)

#### Bước 6.1: Test Service 1 (15 phút)

```bash
# Terminal 1: Start Service 1
cd service-1-user/cmd/server
go run main.go

# Terminal 2: Test với grpcurl hoặc viết CLI client
```

Test tất cả operations:

- ✅ Create user
- ✅ Get user by ID
- ✅ List users
- ✅ Update user
- ✅ Delete user

#### Bước 6.2: Test Service 2 (15 phút)

```bash
# Terminal 3: Start Service 2 (Service 1 phải đang chạy)
cd service-2-article/cmd/server
go run main.go

# Test
```

Test:

- ✅ Create article (với user_id hợp lệ)
- ✅ Get article (phải có thông tin user)
- ✅ List articles (tất cả có user info)
- ✅ Update article
- ✅ Delete article

#### Bước 6.3: Viết README (15 phút)

**Service 1 README:**

- Cách build và run
- Các RPC methods available
- Example requests

**Service 2 README:**

- Cách build và run
- Dependency: Service 1 phải chạy trước
- Các RPC methods
- Example với user info

#### Bước 6.4: Review cuối cùng (15 phút)

- Chạy full demo từ đầu đến cuối
- Verify tất cả operations hoạt động
- Chuẩn bị để show anh Lợi

---

## Checklist Hoàn Thành

### Service 1 (User Service)

- [ ] PostgreSQL running và có data mẫu
- [ ] Database connection hoạt động
- [ ] CreateUser works
- [ ] GetUser works
- [ ] UpdateUser works
- [ ] DeleteUser works
- [ ] ListUsers works
- [ ] gRPC server chạy trên port 50051

### Service 2 (Article Service)

- [ ] Database connection hoạt động
- [ ] gRPC client kết nối được Service 1
- [ ] CreateArticle works
- [ ] GetArticle returns article + user info
- [ ] UpdateArticle works
- [ ] DeleteArticle works
- [ ] ListArticles returns articles + user info
- [ ] gRPC server chạy trên port 50052

### Integration

- [ ] Service 2 gọi được Service 1 qua gRPC
- [ ] Foreign key constraint hoạt động
- [ ] Xóa user → cascade delete articles
- [ ] Tất cả error handling OK

### Documentation

- [ ] README cho Service 1
- [ ] README cho Service 2
- [ ] Hướng dẫn setup và chạy
- [ ] Demo script

---

## Cách Sử Dụng Plan Này Đúng

### ✅ ĐÚNG:

1. **ĐỌC** code examples để hiểu logic
2. **GHI CHÚ** các điểm quan trọng ra giấy
3. **ĐÓNG** tài liệu này lại
4. **GÕ** code từ sự hiểu biết của bạn
5. **TEST** ngay sau mỗi function
6. **NẾU BÍ**: Quay lại xem pattern, không phải copy

### ❌ SAI:

- ❌ Copy-paste nguyên code blocks
- ❌ Mở tài liệu này bên cạnh khi gõ
- ❌ Nhờ AI "viết" hoặc "generate" code
- ❌ Dùng như "điền vào chỗ trống"

---

## Lời Khuyên Khi Làm

### Quản lý thời gian:

- ⏰ Set timer cho mỗi sprint
- 🛑 Nếu bí quá 10 phút, skip sang task khác
- ✅ Ưu tiên code chạy được trước, refine sau
- 📝 Note lại những chỗ khó để hỏi sau

### Khi debug:

- 🔍 Đọc error message kỹ
- 🧪 Test từng phần nhỏ
- 📊 Dùng `log.Printf()` để debug
- 💡 Check database trực tiếp với `psql`

### Điều anh Lợi sẽ đánh giá:

1. ✅ Code chạy được không?
2. ✅ Hiểu được code mình viết không?
3. ✅ CRUD đầy đủ chưa?
4. ✅ gRPC communication OK chưa?
5. ✅ Foreign key relationship đúng chưa?
6. ✅ Code có structure tốt không?

### Dấu hiệu code thủ công (không dùng AI):

- ✅ Giải thích được từng dòng
- ✅ Có vài typo nhỏ (bình thường!)
- ✅ Biết phần nào khó nhất
- ✅ Có thể sửa code không cần giúp
- ✅ Style code nhất quán

---

## Tài Nguyên Tham Khảo

**Được phép xem:**

- ✅ https://go.dev/doc/ - Go documentation
- ✅ https://grpc.io/docs/languages/go/ - gRPC Go tutorial
- ✅ https://pkg.go.dev/github.com/jackc/pgx/v5 - PostgreSQL driver docs
- ✅ File này (ACTION_PLAN.md) - Để xem pattern
- ✅ Stack Overflow - Đọc solutions có sẵn

**Không được dùng:**

- ❌ GitHub Copilot
- ❌ ChatGPT để viết code
- ❌ Bất kỳ AI code generator nào
- ❌ Copy code từ đâu không hiểu

---

## Kết Luận

**Mục tiêu:** Sau 6 giờ, bạn có:

1. ✅ 2 services chạy được
2. ✅ CRUD đầy đủ cho cả users và articles
3. ✅ gRPC communication giữa 2 services
4. ✅ Foreign key relationship đúng
5. ✅ Documentation cơ bản
6. ✅ Demo được cho anh Lợi

**Quan trọng nhất:**

- 💪 Tự tay gõ tất cả code
- 🧠 Hiểu được những gì mình làm
- 🎯 Code chạy được và đúng requirements
- 📚 Học được Golang và gRPC thực tế

---

**Sẵn sàng bắt đầu Sprint 1 chưa?** Cài đặt PostgreSQL và tạo database schema trước nhé! 🚀

**Chúc may mắn! 💪**
