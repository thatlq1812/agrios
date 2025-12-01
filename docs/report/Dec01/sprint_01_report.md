# Maintainer Profile

**Name:** THAT Le Quang

- **Role:** AI & DS Major Student
- **GitHub:** [thatlq1812]

---

# Báo Cáo Sprint 1 - Setup Môi Trường & Proto Files

**Ngày:** 1 tháng 12, 2025  
**Sprint:** 1/6  
**Thời gian thực hiện:** 50 phút  
**Trạng thái:** ✅ Hoàn thành

---

## Mục Tiêu Sprint 1

Thiết lập nền tảng cho dự án gồm:

1. Setup PostgreSQL database
2. Tạo schema cho 2 bảng (users, articles)
3. Viết Proto files cho 2 services
4. Generate Go code từ Proto files
5. Khởi tạo Go modules

---

## 1. Setup PostgreSQL Database

### 1.1 Khởi động PostgreSQL Container

```bash
docker run --name agrios-postgres \
  -e POSTGRES_PASSWORD=postgres123 \
  -e POSTGRES_USER=agrios \
  -e POSTGRES_DB=userdb \
  -p 5432:5432 \
  -d postgres:15-alpine
```

**Kết quả:**

- ✅ Container running trên port 5432
- ✅ Database `userdb` đã được tạo
- ✅ User `agrios` với password `postgres123`

### 1.2 Tạo Database Schema

**Bảng Users (Service 1):**

```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (name, email) VALUES
    ('THAT Le Quang', 'that.le@example.com'),
    ('Nguyen Van A', 'nguyenvana@example.com'),
    ('Tran Thi B', 'tranthib@example.com');
```

**Bảng Articles (Service 2):**

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

INSERT INTO articles (title, content, user_id) VALUES
    ('Bài viết đầu tiên', 'Nội dung về Go language', 1),
    ('Hướng dẫn gRPC', 'Học gRPC với PostgreSQL', 1),
    ('Thiết kế Database', 'Best practices cho database', 2);
```

**Kết quả:**

- ✅ Bảng `users` với 3 records
- ✅ Bảng `articles` với 3 records
- ✅ Foreign key constraint: article.user_id → users.id
- ✅ Cascade delete: xóa user → xóa articles

**Verify:**

```sql
SELECT * FROM users;
SELECT * FROM articles;
SELECT a.title, u.name FROM articles a JOIN users u ON a.user_id = u.id;
```

---

## 2. Viết Proto Files

### 2.1 Service 1: User Service

**File:** `service-1-user/proto/user_service.proto`

**Nội dung chính:**

```protobuf
syntax = "proto3";
package user;
option go_package = "service-1-user/proto";

message User {
    int32 id = 1;
    string name = 2;
    string email = 3;
    string created_at = 4;
}

service UserService {
    rpc CreateUser(CreateUserRequest) returns (User);
    rpc GetUser(GetUserRequest) returns (User);
    rpc UpdateUser(UpdateUserRequest) returns (User);
    rpc DeleteUser(DeleteUserRequest) returns (User);
    rpc ListUsers(ListUsersRequest) returns (ListUsersResponse);
}
```

**Messages định nghĩa:**

- ✅ User (entity)
- ✅ CreateUserRequest
- ✅ GetUserRequest
- ✅ UpdateUserRequest
- ✅ DeleteUserRequest
- ✅ ListUsersRequest
- ✅ ListUsersResponse (với pagination)

### 2.2 Service 2: Article Service

**File:** `service-2-article/proto/article_service.proto`

**Nội dung chính:**

```protobuf
syntax = "proto3";
package article;
option go_package = "service-2-article/proto";

import "user_service.proto";

message Article {
    int32 id = 1;
    string title = 2;
    string content = 3;
    int32 user_id = 4;
    string created_at = 5;
    string updated_at = 6;
}

message ArticleWithUser {
    Article article = 1;
    user.User user = 2;
}

service ArticleService {
    rpc CreateArticle(CreateArticleRequest) returns (Article);
    rpc GetArticle(GetArticleRequest) returns (ArticleWithUser);
    rpc UpdateArticle(UpdateArticleRequest) returns (Article);
    rpc DeleteArticle(DeleteArticleRequest) returns (Article);
    rpc ListArticles(ListArticlesRequest) returns (ListArticlesResponse);
}
```

**Messages định nghĩa:**

- ✅ Article (entity với user_id)
- ✅ ArticleWithUser (joined data)
- ✅ CreateArticleRequest
- ✅ GetArticleRequest
- ✅ UpdateArticleRequest
- ✅ DeleteArticleRequest
- ✅ ListArticlesRequest (với filter by user_id)
- ✅ ListArticlesResponse

**Đặc điểm:**

- Import `user_service.proto` để dùng User message
- `ArticleWithUser` combine Article + User info
- Service 2 sẽ gọi Service 1 qua gRPC để lấy User data

---

## 3. Generate Go Code từ Proto Files

### 3.1 Cài Đặt Công Cụ

```bash
# Protoc compiler (đã cài)
protoc --version
# Output: libprotoc 3.x.x

# Go plugins
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
```

### 3.2 Generate Code cho Service 1

```bash
cd service-1-user

# Khởi tạo Go module
go mod init service-1-user

# Generate từ proto
protoc --go_out=. --go_opt=paths=source_relative \
    --go-grpc_out=. --go-grpc_opt=paths=source_relative \
    proto/user_service.proto
```

**Files được tạo:**

- ✅ `proto/user_service.pb.go` (message definitions)
- ✅ `proto/user_service_grpc.pb.go` (service interfaces)

**Nội dung generated:**

- User struct với GetId(), GetName(), GetEmail() methods
- UserServiceServer interface (để implement)
- UserServiceClient interface (để gọi)
- Registration functions

### 3.3 Generate Code cho Service 2

```bash
cd service-2-article

# Copy user_service.proto để import
cp ../service-1-user/proto/user_service.proto proto/

# Sửa go_package trong user_service.proto copy
# Từ: option go_package = "service-1-user/proto";
# Thành: option go_package = "service-2-article/proto";

# Khởi tạo Go module
go mod init service-2-article

# Generate user_service trước
protoc -I./proto --go_out=. --go_opt=paths=source_relative \
    --go-grpc_out=. --go-grpc_opt=paths=source_relative \
    proto/user_service.proto

# Generate article_service
protoc -I./proto --go_out=. --go_opt=paths=source_relative \
    --go-grpc_out=. --go-grpc_opt=paths=source_relative \
    proto/article_service.proto
```

**Files được tạo:**

- ✅ `proto/user_service.pb.go`
- ✅ `proto/user_service_grpc.pb.go`
- ✅ `proto/article_service.pb.go`
- ✅ `proto/article_service_grpc.pb.go`

**Lưu ý quan trọng:**

- Service 2 có bản copy riêng của User message
- `go_package` phải là "service-2-article/proto" để tránh conflict
- Import path đúng trong generated code

---

## 4. Khởi Tạo Go Modules và Dependencies

### 4.1 Service 1

```bash
cd service-1-user
go mod init service-1-user
go mod tidy
```

**go.mod content:**

```go
module service-1-user

go 1.21

require (
    google.golang.org/grpc v1.77.0
    google.golang.org/protobuf v1.36.10
)
```

### 4.2 Service 2

```bash
cd service-2-article
go mod init service-2-article
go mod tidy
```

**go.mod content:**

```go
module service-2-article

go 1.21

require (
    google.golang.org/grpc v1.77.0
    google.golang.org/protobuf v1.36.10
)
```

### 4.3 Verify Compilation

```bash
# Service 1
cd service-1-user
go build ./...
# ✅ No errors

# Service 2
cd service-2-article
go build ./...
# ✅ No errors
```

---

## 5. Vấn Đề Gặp Phải và Cách Giải Quyết

### Issue 1: Typo trong Proto File

**Lỗi:**

```protobuf
messsage DeleteArticleRequest {  // Thừa chữ "s"
```

**Giải pháp:**
Sửa thành `message` (đúng spelling)

### Issue 2: Import Not Found

**Lỗi:**

```
user_service.proto: File not found
```

**Nguyên nhân:**
Protoc không tìm thấy imported file

**Giải pháp:**

- Copy `user_service.proto` vào Service 2
- Dùng flag `-I./proto` khi generate

### Issue 3: Package Import Error

**Lỗi:**

```
package service-1-user/proto is not in std
```

**Nguyên nhân:**
Service 2 đang import package từ Service 1 (khác module)

**Giải pháp:**
Sửa `go_package` trong `service-2-article/proto/user_service.proto` thành `"service-2-article/proto"`

### Issue 4: Missing go.mod

**Lỗi:**

```
go: cannot find main module
go get: go.mod file not found
```

**Giải pháp:**

```bash
go mod init service-name
go mod tidy
```

---

## 6. Cấu Trúc Thư Mục Sau Sprint 1

```
agrios/
├── service-1-user/
│   ├── proto/
│   │   ├── user_service.proto
│   │   ├── user_service.pb.go
│   │   └── user_service_grpc.pb.go
│   ├── go.mod
│   └── go.sum
│
├── service-2-article/
│   ├── proto/
│   │   ├── user_service.proto        (copy từ Service 1)
│   │   ├── user_service.pb.go
│   │   ├── user_service_grpc.pb.go
│   │   ├── article_service.proto
│   │   ├── article_service.pb.go
│   │   └── article_service_grpc.pb.go
│   ├── go.mod
│   └── go.sum
│
└── docs/
    ├── ACTION_PLAN.md
    ├── ACTION_PLAN_VI.md
    └── report/
        └── Dec01/
            └── sprint_01_report.md
```

---

## 7. Kiến Thức Đã Học

### Protocol Buffers

- ✅ Cú pháp proto3
- ✅ Message definitions với field numbers
- ✅ Service definitions với RPC methods
- ✅ Import và nested messages
- ✅ Repeated fields (arrays)
- ✅ Package và go_package options

### Go Modules

- ✅ Khởi tạo module với `go mod init`
- ✅ Quản lý dependencies với `go mod tidy`
- ✅ go.mod và go.sum files
- ✅ Import paths và package structure

### gRPC Code Generation

- ✅ protoc compiler usage
- ✅ Go plugins: protoc-gen-go, protoc-gen-go-grpc
- ✅ Generated structs và interfaces
- ✅ Server và Client interfaces

### PostgreSQL

- ✅ Docker container setup
- ✅ CREATE TABLE với constraints
- ✅ Foreign keys và CASCADE
- ✅ SERIAL (auto-increment) primary keys
- ✅ INSERT sample data

---

## 8. Checklist Sprint 1

### Database

- [x] PostgreSQL container running
- [x] Database `userdb` created
- [x] Table `users` created với 3 records
- [x] Table `articles` created với 3 records
- [x] Foreign key constraint hoạt động

### Proto Files

- [x] `service-1-user/proto/user_service.proto` hoàn thiện
- [x] `service-2-article/proto/article_service.proto` hoàn thiện
- [x] Syntax đúng, không có lỗi
- [x] Import statement đúng

### Generated Code

- [x] Service 1: 2 files generated
- [x] Service 2: 4 files generated
- [x] Không có compile errors
- [x] Import paths đúng

### Go Modules

- [x] Service 1: go.mod initialized
- [x] Service 2: go.mod initialized
- [x] Dependencies installed
- [x] `go build ./...` thành công

---

## 9. Thời Gian Thực Hiện Chi Tiết

| Task                | Thời gian dự kiến | Thời gian thực tế | Ghi chú                  |
| ------------------- | ----------------- | ----------------- | ------------------------ |
| Setup PostgreSQL    | 15 phút           | 15 phút           | ✅ Đúng kế hoạch         |
| Tạo database schema | 10 phút           | 10 phút           | ✅ Đúng kế hoạch         |
| Viết proto files    | 15 phút           | 20 phút           | ⚠️ Có typo cần sửa       |
| Generate Go code    | 10 phút           | 15 phút           | ⚠️ Gặp import errors     |
| **TỔNG**            | **50 phút**       | **60 phút**       | ⚠️ Vượt 10 phút do debug |

---

## 10. Bài Học Rút Ra

### Kỹ Thuật

1. **Kiểm tra syntax cẩn thận** - Typo nhỏ khiến protoc fail im lặng
2. **Import paths phức tạp** - Microservices cần duplicate proto definitions
3. **go.mod quan trọng** - Phải init module trước khi dùng go commands
4. **-I flag hữu ích** - Chỉ định import paths cho protoc

### Quy Trình

1. **Test từng bước** - Verify sau mỗi command
2. **Read errors carefully** - Error messages có hints để fix
3. **Documentation first** - Đọc kỹ proto syntax trước khi viết
4. **Build incrementally** - Generate từng service một, test ngay

### Thời Gian

1. **Buffer time cần thiết** - 50 phút lên 60 phút do debugging
2. **Debug chiếm thời gian** - 10 phút fix typo và import issues
3. **Learning curve** - Lần đầu làm nên chậm hơn dự kiến

---

## 11. Kế Hoạch Sprint 2

**Mục tiêu:** Implement Service 1 - Database Connection và GetUser

**Thời gian:** 60 phút

**Công việc:**

1. Tạo cấu trúc thư mục cho Service 1
2. Implement database connection (pgx driver)
3. Tạo repository interface
4. Implement GetUserByID method
5. Test database query

**Chuẩn bị:**

- Đọc pgx documentation
- Hiểu Go context package
- Ôn lại SQL SELECT syntax

---

## 12. Ghi Chú Quan Trọng

⚠️ **Nhớ không dùng AI để viết code** - Chỉ dùng để:

- Đọc documentation
- Giải thích concepts
- Review code đã viết

✅ **Đã tuân thủ:** Tất cả code proto đều tự tay gõ, không copy-paste

💪 **Tự tin hơn:** Đã hiểu được:

- Proto syntax
- Go module system
- gRPC code generation flow
- PostgreSQL basics

---

**Người thực hiện:** THAT Le Quang  
**Thời gian hoàn thành:** 1/12/2025 - Sprint 1  
**Trạng thái:** ✅ Hoàn thành (60/50 phút - vượt 10 phút)
