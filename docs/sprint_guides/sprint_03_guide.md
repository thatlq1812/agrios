# Maintainer Profile

**Name:** THAT Le Quang

- **Role:** AI & DS Major Student
- **GitHub:** [thatlq1812]

---

# Sprint 3 - gRPC Server Implementation Guide

**Sprint:** 3/6  
**Thời gian dự kiến:** 50-60 phút  
**Mục tiêu:** Implement gRPC server handlers và start server

---

## Tổng Quan Sprint 3

Sprint này bạn sẽ:

1. Tạo gRPC server struct
2. Implement 5 RPC handlers (Create, Get, Update, Delete, List)
3. Handle errors với gRPC status codes
4. Update main.go để start gRPC server
5. Test với grpcurl

**Prerequisites:**

- ✅ Sprint 1: Proto files và database schema
- ✅ Sprint 2: Repository layer hoạt động
- ✅ Database có 3 sample users

---

## Cấu Trúc Thư Mục Sprint 3

**Trước Sprint 3:**

```
service-1-user/
├── cmd/
│   └── server/
│       └── main.go                    # ✅ Đã có (Sprint 2 test code)
├── internal/
│   ├── db/
│   │   └── postgres.go                # ✅ Đã có
│   ├── repository/
│   │   ├── user_repository.go         # ✅ Đã có
│   │   └── user_postgres.go           # ✅ Đã có
│   └── server/                        # ❌ Folder rỗng
├── proto/
│   ├── user_service.proto             # ✅ Đã có
│   ├── user_service.pb.go             # ✅ Đã có
│   └── user_service_grpc.pb.go        # ✅ Đã có
├── go.mod
└── go.sum
```

**Sau Sprint 3:**

```
service-1-user/
├── cmd/
│   └── server/
│       └── main.go                    # ✏️ SỬA (start gRPC server)
├── internal/
│   ├── db/
│   │   └── postgres.go
│   ├── repository/
│   │   ├── user_repository.go
│   │   └── user_postgres.go
│   └── server/
│       └── user_server.go             # ➕ MỚI (5 handlers + helpers)
├── proto/
│   ├── user_service.proto
│   ├── user_service.pb.go
│   └── user_service_grpc.pb.go
├── go.mod
└── go.sum
```

**Files cần làm việc:**

1. **TẠO MỚI:** `internal/server/user_server.go` (~200 lines)
2. **SỬA:** `cmd/server/main.go` (thay test code bằng gRPC server code)

---

## Kiến Thức Cần Biết Trước

### gRPC Server Pattern

```go
// 1. Tạo struct implement generated interface
type userServiceServer struct {
    pb.UnimplementedUserServiceServer  // Embed để tương thích future updates
    repo repository.UserRepository      // Dependency injection
}

// 2. Implement RPC methods
func (s *userServiceServer) GetUser(ctx context.Context, req *pb.GetUserRequest) (*pb.User, error) {
    // Business logic here
}

// 3. Register server
grpc.NewServer()
pb.RegisterUserServiceServer(server, &userServiceServer{repo: repo})
```

### gRPC Status Codes

| Code                    | Khi nào dùng                 | HTTP equivalent    |
| ----------------------- | ---------------------------- | ------------------ |
| `codes.OK`              | Success (default)            | 200 OK             |
| `codes.InvalidArgument` | Client gửi invalid data      | 400 Bad Request    |
| `codes.NotFound`        | Resource không tồn tại       | 404 Not Found      |
| `codes.AlreadyExists`   | Duplicate (email unique)     | 409 Conflict       |
| `codes.Internal`        | Server error (database down) | 500 Internal Error |

**Usage:**

```go
if err != nil {
    return nil, status.Errorf(codes.NotFound, "user with id %d not found", id)
}
```

---

## Bước 1: Tạo gRPC Server Struct (5 phút)

### Tạo file mới: `internal/server/user_server.go`

**Vị trí:** Line 1 - 30 (đầu file)

```go
package server

import (
	"context"
	"fmt"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	pb "service-1-user/proto"
	"service-1-user/internal/repository"
)

// userServiceServer implement UserServiceServer interface
type userServiceServer struct {
	pb.UnimplementedUserServiceServer
	repo repository.UserRepository
}

// NewUserServiceServer tạo server mới
func NewUserServiceServer(repo repository.UserRepository) pb.UserServiceServer {
	return &userServiceServer{
		repo: repo,
	}
}
```

**Giải thích:**

1. **UnimplementedUserServiceServer:**

   - Generated struct từ proto file
   - Provide default implementations cho future RPC methods
   - Tránh compile error khi proto file thêm methods mới

2. **Dependency injection:**

   - Nhận `repository.UserRepository` qua constructor
   - Không tạo dependency trực tiếp trong struct
   - Dễ test: mock repository

3. **Constructor pattern:**
   - `NewUserServiceServer` return interface, không phải concrete type
   - Caller chỉ cần biết interface

---

## Bước 2: Implement GetUser Handler (10 phút)

### Thêm vào `internal/server/user_server.go`

**Vị trí:** Line 32 - 50 (sau constructor)

```go
// GetUser implement RPC GetUser
func (s *userServiceServer) GetUser(ctx context.Context, req *pb.GetUserRequest) (*pb.User, error) {
	// 1. Validate input
	if req.Id <= 0 {
		return nil, status.Errorf(codes.InvalidArgument, "user id must be positive, got %d", req.Id)
	}

	// 2. Call repository
	user, err := s.repo.GetByID(ctx, req.Id)
	if err != nil {
		// Check if not found error
		if err.Error() == "no rows in result set" {
			return nil, status.Errorf(codes.NotFound, "user with id %d not found", req.Id)
		}
		// Other errors are internal
		return nil, status.Errorf(codes.Internal, "failed to get user: %v", err)
	}

	// 3. Return success
	return user, nil
}
```

**Giải thích:**

1. **Input validation:**

   - Check `id > 0` (business rule)
   - Return `InvalidArgument` nếu sai
   - Client biết họ gửi sai data

2. **Error classification:**

   - "no rows in result set" → `NotFound` (404)
   - Other errors → `Internal` (500)
   - Client có thể handle khác nhau

3. **Return directly:**
   - `user` đã đúng type `*pb.User`
   - Không cần transform

**Lưu ý:**

- Trong production, nên dùng `errors.Is()` thay vì so sánh string
- pgx có error types: `pgx.ErrNoRows`

## Bước 3: Implement CreateUser Handler (10 phút)

### Thêm vào `internal/server/user_server.go`

**Vị trí:** Line 52 - 130 (sau GetUser, bao gồm helper functions ở cuối)

```go
// CreateUser implement RPC CreateUser
func (s *userServiceServer) CreateUser(ctx context.Context, req *pb.CreateUserRequest) (*pb.User, error) {
	// 1. Validate input
	if req.Name == "" {
		return nil, status.Errorf(codes.InvalidArgument, "name is required")
	}
	if req.Email == "" {
		return nil, status.Errorf(codes.InvalidArgument, "email is required")
	}

	// 2. Basic email validation (optional)
	if !isValidEmail(req.Email) {
		return nil, status.Errorf(codes.InvalidArgument, "email format invalid: %s", req.Email)
	}

	// 3. Call repository
	user, err := s.repo.Create(ctx, req.Name, req.Email)
	if err != nil {
		// Check if duplicate email (unique constraint violation)
		if containsString(err.Error(), "duplicate") || containsString(err.Error(), "unique") {
			return nil, status.Errorf(codes.AlreadyExists, "email %s already exists", req.Email)
		}
		return nil, status.Errorf(codes.Internal, "failed to create user: %v", err)
	}

	return user, nil
}

// Helper: check if valid email (simple check)
func isValidEmail(email string) bool {
	// Simple check: contains @ and .
	hasAt := false
	hasDot := false
	for _, c := range email {
		if c == '@' {
			hasAt = true
		}
		if c == '.' {
			hasDot = true
		}
	}
	return hasAt && hasDot && len(email) >= 5
}

// Helper: check if string contains substring
func containsString(s, substr string) bool {
	return len(s) >= len(substr) &&
		(s == substr || len(s) > len(substr) && hasSubstring(s, substr))
}

func hasSubstring(s, substr string) bool {
	for i := 0; i <= len(s)-len(substr); i++ {
		match := true
		for j := 0; j < len(substr); j++ {
			if s[i+j] != substr[j] {
				match = false
				break
			}
		}
		if match {
			return true
		}
	}
	return false
}
```

**Giải thích:**

1. **Validation layers:**

   - Required fields: name, email
   - Format validation: email có @ và .
   - Business rules: email unique (handled by DB)

2. **AlreadyExists error:**

   - PostgreSQL unique constraint violation
   - Error message contains "duplicate" or "unique"
   - Return `AlreadyExists` (409 Conflict)

3. **Helper functions:**
   - `isValidEmail()`: Simple email check (không cần regex)
   - `containsString()`: Check substring without importing strings package

**Alternative (using standard library):**

````go
import "strings"

func containsString(s, substr string) bool {
    return strings.Contains(s, substr)
}
## Bước 4: Implement UpdateUser Handler (10 phút)

### Thêm vào `internal/server/user_server.go`

**Vị trí:** Line 132 - 155 (sau CreateUser và helper functions)

```go
// UpdateUser implement RPC UpdateUser
## Bước 4: Implement UpdateUser Handler (10 phút)

```go
// UpdateUser implement RPC UpdateUser
func (s *userServiceServer) UpdateUser(ctx context.Context, req *pb.UpdateUserRequest) (*pb.User, error) {
	// 1. Validate input
	if req.Id <= 0 {
		return nil, status.Errorf(codes.InvalidArgument, "user id must be positive")
	}
	if req.Name == "" {
		return nil, status.Errorf(codes.InvalidArgument, "name is required")
	}
	if req.Email == "" {
		return nil, status.Errorf(codes.InvalidArgument, "email is required")
	}

	// 2. Call repository
	user, err := s.repo.Update(ctx, req.Id, req.Name, req.Email)
	if err != nil {
		// Check if not found
		if err.Error() == "no rows in result set" {
			return nil, status.Errorf(codes.NotFound, "user with id %d not found", req.Id)
		}
		// Check if duplicate email
		if containsString(err.Error(), "duplicate") || containsString(err.Error(), "unique") {
			return nil, status.Errorf(codes.AlreadyExists, "email %s already exists", req.Email)
		}
		return nil, status.Errorf(codes.Internal, "failed to update user: %v", err)
	}

	return user, nil
}
````

**Giải thích:**

1. **Similar to CreateUser:**

   - Same validations
   - Same error handling

2. **NotFound case:**

   - User với ID không tồn tại
   - UPDATE returns no rows

3. **AlreadyExists case:**
   - Update email thành email của user khác

## Bước 5: Implement DeleteUser Handler (5 phút)

### Thêm vào `internal/server/user_server.go`

**Vị trí:** Line 157 - 180 (sau UpdateUser)

```go
// DeleteUser implement RPC DeleteUser
## Bước 5: Implement DeleteUser Handler (5 phút)

// DeleteUser implement RPC DeleteUser
func (s *userServiceServer) DeleteUser(ctx context.Context, req *pb.DeleteUserRequest) (*pb.User, error) {
	// 1. Validate input
	if req.Id <= 0 {
		return nil, status.Errorf(codes.InvalidArgument, "user id must be positive")
	}

	// 2. Get user first (to return in response)
	user, err := s.repo.GetByID(ctx, req.Id)
	if err != nil {
		if err.Error() == "no rows in result set" {
			return nil, status.Errorf(codes.NotFound, "user with id %d not found", req.Id)
		}
		return nil, status.Errorf(codes.Internal, "failed to get user: %v", err)
	}

	// 3. Delete user
	err = s.repo.Delete(ctx, req.Id)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to delete user: %v", err)
	}

	// 4. Return deleted user info
	return user, nil
}
```

**Giải thích:**

1. **Get before delete:**

   - Proto định nghĩa DeleteUser return `User` (not empty)
   - Cần fetch user trước khi delete để return

2. **Two database calls:**
   - SELECT để get user
   - DELETE để xóa
   - Có thể optimize với `DELETE ... RETURNING *`

**Optimized version (nếu muốn):**

````go
// Trong user_postgres.go:
func (r *userPostgresRepo) Delete(ctx context.Context, id int32) (*pb.User, error) {
    query := `DELETE FROM users WHERE id = $1 RETURNING id, name, email, created_at`

    var user pb.User
    var createdAt time.Time

    err := r.db.QueryRow(ctx, query, id).Scan(&user.Id, &user.Name, &user.Email, &createdAt)
    // ...
}
## Bước 6: Implement ListUsers Handler (10 phút)

### Thêm vào `internal/server/user_server.go`

**Vị trí:** Line 182 - 210 (cuối file)

```go
// ListUsers implement RPC ListUsers
## Bước 6: Implement ListUsers Handler (10 phút)

```go
// ListUsers implement RPC ListUsers
func (s *userServiceServer) ListUsers(ctx context.Context, req *pb.ListUsersRequest) (*pb.ListUsersResponse, error) {
	// 1. Validate pagination params
	limit := req.Limit
	offset := req.Offset

	if limit <= 0 {
		limit = 10 // Default limit
	}
	if limit > 100 {
		return nil, status.Errorf(codes.InvalidArgument, "limit too large, max 100, got %d", limit)
	}
	if offset < 0 {
		return nil, status.Errorf(codes.InvalidArgument, "offset must be non-negative, got %d", offset)
	}

	// 2. Call repository
	users, total, err := s.repo.List(ctx, limit, offset)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to list users: %v", err)
	}

	// 3. Build response
	return &pb.ListUsersResponse{
		Users: users,
		Total: total,
	}, nil
}
````

**Giải thích:**

1. **Pagination parameters:**

   - `limit`: Số items per page (default 10, max 100)
   - `offset`: Skip first N items
   - Example: Page 2 with 10 items/page → limit=10, offset=10

2. **Prevent abuse:**

   - Max limit = 100 (tránh client request 1 triệu records)

## Bước 7: Update Main.go để Start Server (10 phút)

### Sửa file: `cmd/server/main.go`

**Vị trí:** Thay TOÀN BỘ file (xóa test code của Sprint 2, viết lại từ đầu)

**File structure:**

- Line 1-10: Package và imports
- Line 12-60: main() function

````go
package main
## Bước 7: Update Main.go để Start Server (10 phút)

### File: `cmd/server/main.go`

**Thay toàn bộ nội dung bằng:**

package main

import (
	"log"
	"net"

	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"

	"service-1-user/internal/db"
	"service-1-user/internal/repository"
	"service-1-user/internal/server"
	pb "service-1-user/proto"
)

func main() {
	// 1. Setup database
	dbConfig := db.Config{
		Host:     "localhost",
		Port:     "5432",
		User:     "agrios",
		Password: "postgres123",
		DBName:   "userdb",
	}

	pool, err := db.NewPostgresPool(dbConfig)
	if err != nil {
		log.Fatalf("Failed to connect database: %v", err)
	}
	defer pool.Close()
	log.Println("✅ Connected to PostgreSQL")

	// 2. Create repository
	userRepo := repository.NewUserPostgresRepository(pool)

	// 3. Create gRPC server
	grpcServer := grpc.NewServer()

	// 4. Register service
	userService := server.NewUserServiceServer(userRepo)
	pb.RegisterUserServiceServer(grpcServer, userService)

	// 5. Enable reflection (for grpcurl)
	reflection.Register(grpcServer)

	// 6. Listen on port 50051
	listener, err := net.Listen("tcp", ":50051")
	if err != nil {
		log.Fatalf("Failed to listen on port 50051: %v", err)
	}

	log.Println("🚀 gRPC server listening on :50051")

	// 7. Start serving (blocking call)
	if err := grpcServer.Serve(listener); err != nil {
		log.Fatalf("Failed to serve: %v", err)
	}
}
````

**Giải thích:**

1. **grpc.NewServer():**

   - Tạo gRPC server instance
   - Chưa có services registered

2. **RegisterUserServiceServer:**

   - Register implementation vào server
   - Generated function từ proto file

3. **reflection.Register:**

   - Enable server reflection protocol
   - Cho phép grpcurl discover services
   - Không cần proto file ở client side

4. **net.Listen:**

   - Bind TCP socket trên port 50051
   - Accept incoming connections

5. **grpcServer.Serve:**
   - Blocking call
   - Process requests forever
   - Chỉ return khi có error hoặc shutdown

---

## Bước 8: Build và Start Server

```bash
cd d:/agrios/service-1-user

# Build để check compile errors
go build ./...

# Start server
go run cmd/server/main.go
```

**Expected output:**

```
✅ Connected to PostgreSQL
🚀 gRPC server listening on :50051
```

Server đang chạy! **Không tắt terminal này.**

---

## Bước 9: Test với grpcurl (10 phút)

### 9.1 Install grpcurl (nếu chưa có)

**Windows (với Go):**

```bash
go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest
```

**Verify:**

```bash
grpcurl -version
```

### 9.2 List Services

```bash
grpcurl -plaintext localhost:50051 list
```

**Expected output:**

```
grpc.reflection.v1alpha.ServerReflection
user.UserService
```

### 9.3 Describe Service

```bash
grpcurl -plaintext localhost:50051 describe user.UserService
```

**Expected output:**

```
user.UserService is a service:
service UserService {
  rpc CreateUser ( .user.CreateUserRequest ) returns ( .user.User );
  rpc DeleteUser ( .user.DeleteUserRequest ) returns ( .user.User );
  rpc GetUser ( .user.GetUserRequest ) returns ( .user.User );
  rpc ListUsers ( .user.ListUsersRequest ) returns ( .user.ListUsersResponse );
  rpc UpdateUser ( .user.UpdateUserRequest ) returns ( .user.User );
}
```

### 9.4 Test GetUser

```bash
grpcurl -plaintext -d '{"id": 1}' localhost:50051 user.UserService/GetUser
```

**Expected output:**

```json
{
  "id": 1,
  "name": "THAT Le Quang",
  "email": "that.le@example.com",
  "createdAt": "2025-12-01T05:36:31Z"
}
```

### 9.5 Test ListUsers

```bash
grpcurl -plaintext -d '{"limit": 10, "offset": 0}' localhost:50051 user.UserService/ListUsers
```

**Expected output:**

```json
{
  "users": [
    {
      "id": 1,
      "name": "THAT Le Quang",
      "email": "that.le@example.com",
      "createdAt": "2025-12-01T05:36:31Z"
    },
    {
      "id": 2,
      "name": "Nguyen Van A",
      "email": "nguyenvana@example.com",
      "createdAt": "2025-12-01T05:36:31Z"
    },
    {
      "id": 3,
      "name": "Tran Thi B",
      "email": "tranthib@example.com",
      "createdAt": "2025-12-01T05:36:31Z"
    }
  ],
  "total": 3
}
```

### 9.6 Test CreateUser

```bash
grpcurl -plaintext -d '{"name": "Test User", "email": "test@example.com"}' localhost:50051 user.UserService/CreateUser
```

**Expected output:**

```json
{
  "id": 4,
  "name": "Test User",
  "email": "test@example.com",
  "createdAt": "2025-12-01T..."
}
```

### 9.7 Test UpdateUser

```bash
grpcurl -plaintext -d '{"id": 4, "name": "Updated Name", "email": "updated@example.com"}' localhost:50051 user.UserService/UpdateUser
```

### 9.8 Test DeleteUser

```bash
grpcurl -plaintext -d '{"id": 4}' localhost:50051 user.UserService/DeleteUser
```

### 9.9 Test Error Cases

**Invalid ID:**

```bash
grpcurl -plaintext -d '{"id": -1}' localhost:50051 user.UserService/GetUser
```

**Expected error:**

```json
{
  "error": "user id must be positive, got -1",
  "code": "INVALID_ARGUMENT"
}
```

**Not found:**

```bash
grpcurl -plaintext -d '{"id": 999}' localhost:50051 user.UserService/GetUser
```

**Expected error:**

```json
{
  "error": "user with id 999 not found",
  "code": "NOT_FOUND"
}
```

---

## Checklist Sprint 3

### Code Implementation

- [ ] File `internal/server/user_server.go` created
- [ ] Struct `userServiceServer` defined
- [ ] GetUser handler implemented
- [ ] CreateUser handler implemented
- [ ] UpdateUser handler implemented
- [ ] DeleteUser handler implemented
- [ ] ListUsers handler implemented
- [ ] Helper functions (isValidEmail, containsString) implemented
- [ ] File `cmd/server/main.go` updated

### Build & Run

- [ ] `go build ./...` successful
- [ ] `go run cmd/server/main.go` starts without error
- [ ] Server logs "Connected to PostgreSQL"
- [ ] Server logs "gRPC server listening on :50051"

### Testing

- [ ] grpcurl installed
- [ ] `grpcurl list` shows UserService
- [ ] GetUser returns correct data
- [ ] ListUsers returns all users
- [ ] CreateUser creates new user
- [ ] UpdateUser updates existing user
- [ ] DeleteUser removes user
- [ ] Invalid ID returns InvalidArgument error
- [ ] Non-existent ID returns NotFound error

---

## Troubleshooting

### Issue: "connection refused"

**Lỗi:**

```
Failed to dial target host "localhost:50051": dial tcp 127.0.0.1:50051: connect: connection refused
```

**Nguyên nhân:**

- Server chưa start
- Server crashed

**Giải pháp:**

- Check terminal có log "listening on :50051"
- Restart server: `go run cmd/server/main.go`

---

### Issue: "service not found"

**Lỗi:**

```
Failed to list services: server does not support the reflection API
```

**Nguyên nhân:**

- Chưa enable reflection

**Giải pháp:**

- Thêm vào main.go: `reflection.Register(grpcServer)`

---

### Issue: "unknown method"

**Lỗi:**

```
Error invoking method "user.UserService/GetUser": unknown service user.UserService
```

**Nguyên nhân:**

- Package name trong proto không match

**Giải pháp:**

- Check proto file: `package user;`
- Service name: `user.UserService`

---

## Kiến Thức Bổ Sung

### gRPC Interceptors (Optional)

Nếu muốn thêm logging cho mọi requests:

```go
func loggingInterceptor(ctx context.Context, req interface{}, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (interface{}, error) {
	log.Printf("→ %s called with %+v", info.FullMethod, req)
	resp, err := handler(ctx, req)
	if err != nil {
		log.Printf("← %s error: %v", info.FullMethod, err)
	} else {
		log.Printf("← %s success", info.FullMethod)
	}
	return resp, err
}

// In main.go:
grpcServer := grpc.NewServer(
	grpc.UnaryInterceptor(loggingInterceptor),
)
```

### Context Timeout

Client nên set timeout:

```go
ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()

user, err := client.GetUser(ctx, &pb.GetUserRequest{Id: 1})
```

---

## Thời Gian Dự Kiến

| Task               | Thời gian   |
| ------------------ | ----------- |
| Tạo server struct  | 5 phút      |
| GetUser handler    | 10 phút     |
| CreateUser handler | 10 phút     |
| UpdateUser handler | 10 phút     |
| DeleteUser handler | 5 phút      |
| ListUsers handler  | 10 phút     |
| Update main.go     | 10 phút     |
| Test với grpcurl   | 10 phút     |
| **TỔNG**           | **60 phút** |

---

## Kết Quả Mong Đợi

Sau Sprint 3:

- ✅ Service 1 hoàn chỉnh
- ✅ 5 RPC methods hoạt động
- ✅ Error handling đúng
- ✅ Server chạy stable
- ✅ Test thành công với grpcurl

**Chuẩn bị cho Sprint 4:**

- Implement Service 2 (Article Service)
- Service 2 gọi Service 1 qua gRPC
- Foreign key relationship

---

**Người hướng dẫn:** GitHub Copilot  
**Người thực hiện:** THAT Le Quang  
**Thời gian:** 1/12/2025 - Sprint 3 Preparation
