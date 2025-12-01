# Maintainer Profile

**Name:** THAT Le Quang

- **Role:** AI & DS Major Student
- **GitHub:** [thatlq1812]

---

# Báo Cáo Sprint 2 - Database Connection & Repository

**Ngày:** 1 tháng 12, 2025  
**Sprint:** 2/6  
**Thời gian thực hiện:** 60 phút  
**Trạng thái:** ✅ Hoàn thành

---

## Mục Tiêu Sprint 2

Implement database connection và repository layer:
1. Cài đặt PostgreSQL driver (pgx)
2. Viết database connection pool
3. Tạo repository interface
4. Implement GetUserByID method
5. Test database query

---

## 1. Cài Đặt Dependencies

### 1.1 PostgreSQL Driver (pgx)

```bash
cd d:/agrios/service-1-user
go get github.com/jackc/pgx/v5
go get github.com/jackc/pgx/v5/pgxpool
```

**Kết quả:**
- ✅ pgx/v5 v5.7.6 installed
- ✅ pgxpool for connection pooling
- ✅ go.mod updated with dependencies

**Dependencies added:**
```go
require (
    github.com/jackc/pgx/v5 v5.7.6
    google.golang.org/grpc v1.77.0
    google.golang.org/protobuf v1.36.10
)
```

---

## 2. Database Connection Pool

### 2.1 File: `internal/db/postgres.go`

**Nội dung chính:**

```go
package db

import (
	"context"
	"fmt"
	"time"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Config struct {
	Host     string
	Port     string
	User     string
	Password string
	DBName   string
}

func NewPostgresPool(cfg Config) (*pgxpool.Pool, error) {
	dsn := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		cfg.Host, cfg.Port, cfg.User, cfg.Password, cfg.DBName,
	)

	config, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		return nil, fmt.Errorf("parse config failed: %w", err)
	}

	config.MaxConns = 10
	config.MinConns = 2
	config.MaxConnLifetime = time.Hour
	config.MaxConnIdleTime = 30 * time.Minute

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	pool, err := pgxpool.NewWithConfig(ctx, config)
	if err != nil {
		return nil, fmt.Errorf("connect to database failed: %w", err)
	}

	if err := pool.Ping(ctx); err != nil {
		return nil, fmt.Errorf("ping database failed: %w", err)
	}

	return pool, nil
}
```

**Giải thích kỹ thuật:**

1. **DSN (Data Source Name):**
   - Format: `host=X port=Y user=Z password=W dbname=V sslmode=disable`
   - `sslmode=disable`: Tắt SSL cho development (production nên enable)

2. **Connection Pool Configuration:**
   - `MaxConns = 10`: Maximum 10 concurrent connections
   - `MinConns = 2`: Always maintain 2 ready connections
   - `MaxConnLifetime = 1 hour`: Recycle old connections
   - `MaxConnIdleTime = 30 min`: Close idle connections

3. **Context with Timeout:**
   - 5 seconds timeout for initial connection
   - Prevents indefinite blocking if database is down

4. **Ping Test:**
   - Verify connection is actually working
   - Fail fast if database unreachable

---

## 3. Repository Pattern

### 3.1 File: `internal/repository/user_repository.go`

**Interface definition:**

```go
package repository

import (
	"context"
	pb "service-1-user/proto"
)

type UserRepository interface {
	GetByID(ctx context.Context, id int32) (*pb.User, error)
	Create(ctx context.Context, name, email string) (*pb.User, error)
	Update(ctx context.Context, id int32, name, email string) (*pb.User, error)
	Delete(ctx context.Context, id int32) error
	List(ctx context.Context, limit, offset int32) ([]*pb.User, int32, error)
}
```

**Design principles:**

1. **Interface-based design:**
   - Decouple business logic from database implementation
   - Easy to mock for unit testing
   - Can swap database (PostgreSQL → MySQL) without changing callers

2. **Context first:**
   - Every method accepts `context.Context` as first parameter
   - Enables cancellation, timeouts, and request-scoped values
   - Best practice in Go

3. **Proto types:**
   - Use `*pb.User` (generated from proto) as return type
   - Ensures consistency between gRPC API and internal types

4. **Error handling:**
   - All methods return error as last value
   - Enables proper error propagation

---

## 4. Repository Implementation

### 4.1 File: `internal/repository/user_postgres.go`

**Struct and constructor:**

```go
type userPostgresRepo struct {
	db *pgxpool.Pool
}

func NewUserPostgresRepository(db *pgxpool.Pool) UserRepository {
	return &userPostgresRepo{db: db}
}
```

**Key implementation: GetByID**

```go
func (r *userPostgresRepo) GetByID(ctx context.Context, id int32) (*pb.User, error) {
	query := `
		SELECT id, name, email, created_at 
		FROM users 
		WHERE id = $1
	`

	var user pb.User
	var createdAt time.Time

	err := r.db.QueryRow(ctx, query, id).Scan(
		&user.Id,
		&user.Name,
		&user.Email,
		&createdAt,
	)

	if err != nil {
		return nil, fmt.Errorf("query user failed: %w", err)
	}

	user.CreatedAt = createdAt.Format(time.RFC3339)

	return &user, nil
}
```

**Technical details:**

1. **Parameterized queries:**
   - `$1, $2, $3`: PostgreSQL placeholders
   - Prevents SQL injection attacks
   - pgx handles escaping automatically

2. **QueryRow vs Query:**
   - `QueryRow()`: Expect single row (GetByID)
   - `Query()`: Expect multiple rows (List)

3. **Scan pattern:**
   - Map columns to struct fields
   - Order must match SELECT clause
   - Type conversion automatic for compatible types

4. **Time handling:**
   - PostgreSQL returns `time.Time`
   - Proto expects `string`
   - Use `RFC3339` format: `2025-12-01T12:36:31Z`

5. **Error wrapping:**
   - `fmt.Errorf("context: %w", err)` with `%w`
   - Preserves original error for debugging
   - Adds context about operation

---

## 5. Test Program

### 5.1 File: `cmd/server/main.go`

```go
package main

import (
	"context"
	"fmt"
	"log"
	"service-1-user/internal/db"
	"service-1-user/internal/repository"
)

func main() {
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

	log.Println("Connected to Postgres database successfully")

	userRepo := repository.NewUserPostgresRepository(pool)

	ctx := context.Background()
	user, err := userRepo.GetByID(ctx, 1)
	if err != nil {
		log.Fatalf("Failed to get user by ID: %v", err)
	}

	fmt.Printf("User found: ID=%d, Name=%s, Email=%s, CreatedAt=%s\n",
		user.Id, user.Name, user.Email, user.CreatedAt)
}
```

### 5.2 Test Execution

```bash
cd d:/agrios/service-1-user
go run cmd/server/main.go
```

**Output:**
```
2025/12/01 12:36:22 Connected to Postgres database successfully
User found: ID=1, Name=THAT Le Quang, Email=that.le@example.com, CreatedAt=2025-12-01T05:36:31Z
```

**Verification:**
- ✅ Database connection successful
- ✅ Connection pool working
- ✅ GetByID query executed
- ✅ User data retrieved correctly
- ✅ Time format converted properly

---

## 6. Vấn Đề Gặp Phải và Giải Quyết

### Issue 1: Typo `packed` thay vì `package`

**Lỗi:**
```
internal\db\postgres.go:1:1: expected 'package', found packed
internal\repository\user_postgres.go:1:1: expected 'package', found packed
```

**Nguyên nhân:**
Gõ nhanh thiếu chữ "age" → `packed` thay vì `package`

**Giải pháp:**
Sửa lại đúng `package` ở đầu cả 2 files

**Bài học:**
- Go compiler rất strict về keywords
- Typo ở line 1 làm fail toàn bộ file

---

### Issue 2: Missing Dependencies

**Lỗi:**
```
no required module provides package google.golang.org/grpc
no required module provides package google.golang.org/protobuf
```

**Nguyên nhân:**
Proto generated files import gRPC packages nhưng chưa được thêm vào go.mod

**Giải pháp:**
```bash
go get google.golang.org/grpc google.golang.org/protobuf
```

**Bài học:**
- Generated code có dependencies riêng
- Cần install dependencies của generated code

---

### Issue 3: Missing go.sum Entry

**Lỗi:**
```
missing go.sum entry for module providing package golang.org/x/crypto/pbkdf2
```

**Nguyên nhân:**
pgx có transitive dependency chưa được resolve

**Giải pháp:**
```bash
go mod tidy
```

**Bài học:**
- `go mod tidy` resolve tất cả transitive dependencies
- Luôn chạy sau khi install packages mới

---

### Issue 4: Case Sensitivity Typos

**Lỗi:**
```
config.MaxconnLifetime undefined (type *pgxpool.Config has no field MaxconnLifetime)
```

**10 typos được fix:**
1. `MaxconnLifetime` → `MaxConnLifetime` (case sensitive)
2. `userPostgresRepor` → `userPostgresRepo` (thiếu chữ o)
3. `NewUserPostgresrepository` → `NewUserPostgresRepository` (lowercase r)
4. `querry` → `query` (double r)
5. `QurryRow` → `QueryRow` (typo)
6. `createAt` → `createdAt` (missing d)
7. `ceratedAt` → `createdAt` (typo)
8. `int32,` → `id int32,` (missing parameter name)
9. `use` → `user` (incomplete)
10. `DETELE` → `DELETE` (typo)
11. `mian` → `main` (swapped letters)

**Bài học:**
- Go is case-sensitive: `MaxConn` ≠ `Maxconn`
- Typos phổ biến: query, created, delete
- IDE với autocomplete giúp tránh lỗi này

---

### Issue 5: Table Not Exists

**Lỗi:**
```
Query user failed: ERROR: relation "users" does not exist (SQLSTATE 42P01)
```

**Nguyên nhân:**
Database connection OK nhưng bảng users chưa được tạo

**Giải pháp:**
```bash
docker exec -i agrios-postgres psql -U agrios -d userdb << 'EOF'
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (name, email) VALUES
    ('THAT Le Quang', 'that.le@example.com'),
    ('Nguyen Van A', 'nguyenvana@example.com'),
    ('Tran Thi B', 'tranthib@example.com')
ON CONFLICT DO NOTHING;
EOF
```

**Bài học:**
- Test connection != test schema exists
- Cần verify schema trước khi query

---

## 7. Cấu Trúc Code Sau Sprint 2

```
service-1-user/
├── cmd/
│   └── server/
│       └── main.go                    # Test program
├── internal/
│   ├── db/
│   │   └── postgres.go                # Connection pool (53 lines)
│   ├── repository/
│   │   ├── user_repository.go         # Interface (15 lines)
│   │   └── user_postgres.go           # Implementation (168 lines)
│   └── server/                        # Empty (Sprint 3)
├── proto/
│   ├── user_service.proto
│   ├── user_service.pb.go
│   └── user_service_grpc.pb.go
├── go.mod
└── go.sum
```

**Lines of code written:**
- postgres.go: 53 lines
- user_repository.go: 15 lines
- user_postgres.go: 168 lines
- main.go: 42 lines
- **Total: 278 lines** (manually typed, no AI generation)

---

## 8. Kiến Thức Học Được

### 8.1 Connection Pooling

**Tại sao cần pool?**
- Tạo connection mới mỗi request rất chậm (network handshake, auth)
- Pool maintain sẵn N connections ready to use
- Reuse connections → faster, lower latency

**Configuration trade-offs:**
- `MaxConns` cao: More concurrent queries, more memory
- `MinConns` cao: Always ready, waste resources if idle
- `MaxConnLifetime`: Balance between recycling và stability

### 8.2 Repository Pattern

**Benefits:**
- **Testability:** Mock interface thay vì real database
- **Flexibility:** Swap database implementation dễ dàng
- **Separation:** Business logic tách biệt persistence logic
- **Readability:** Interface là contract rõ ràng

**Example test:**
```go
type mockUserRepo struct {}
func (m *mockUserRepo) GetByID(ctx, id) (*pb.User, error) {
    return &pb.User{Id: 1, Name: "Test"}, nil
}
// Test server logic without real database
```

### 8.3 Error Handling Patterns

**Error wrapping with `%w`:**
```go
fmt.Errorf("operation failed: %w", originalErr)
```
- Preserves error chain
- Can use `errors.Is()` và `errors.As()` to check types
- Stack trace maintainable

**Context in errors:**
```go
fmt.Errorf("query user failed: %w", err)
```
- Adds operation context
- Easy to debug: know exactly which query failed

### 8.4 Context Usage

**Why context first parameter?**
```go
func GetByID(ctx context.Context, id int32) (*pb.User, error)
```

**Benefits:**
- **Cancellation:** Cancel long-running query
- **Timeout:** Set deadline for operation
- **Values:** Pass request-scoped data (trace ID, user auth)

**Example:**
```go
ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
defer cancel()
user, err := repo.GetByID(ctx, 1) // Auto-cancel after 2s
```

### 8.5 SQL Best Practices

**Parameterized queries:**
```go
// ❌ BAD - SQL injection risk
query := fmt.Sprintf("SELECT * FROM users WHERE id = %d", id)

// ✅ GOOD - safe
query := "SELECT * FROM users WHERE id = $1"
r.db.QueryRow(ctx, query, id)
```

**RETURNING clause:**
```go
INSERT INTO users (name, email) 
VALUES ($1, $2) 
RETURNING id, created_at
```
- Get generated values (SERIAL id, DEFAULT timestamp) in one query
- Avoid SELECT after INSERT

---

## 9. Checklist Sprint 2

### Dependencies
- [x] pgx/v5 installed
- [x] pgxpool installed
- [x] gRPC packages installed
- [x] Protobuf packages installed
- [x] go.mod updated
- [x] go mod tidy successful

### Code Implementation
- [x] `internal/db/postgres.go` completed
- [x] `internal/repository/user_repository.go` completed
- [x] `internal/repository/user_postgres.go` completed
- [x] `cmd/server/main.go` completed
- [x] All files compile without errors
- [x] `go build ./...` successful

### Database
- [x] PostgreSQL container running
- [x] Table `users` created
- [x] 3 sample records inserted
- [x] Connection successful
- [x] GetByID query working

### Testing
- [x] `go run cmd/server/main.go` successful
- [x] User ID=1 retrieved correctly
- [x] Time format correct (RFC3339)
- [x] No memory leaks (defer pool.Close())

---

## 10. Thời Gian Thực Hiện

| Task | Dự kiến | Thực tế | Ghi chú |
|------|---------|---------|---------|
| Install dependencies | 5 phút | 5 phút | ✅ Đúng |
| Write postgres.go | 15 phút | 20 phút | ⚠️ Debug typos |
| Write repository interface | 10 phút | 10 phút | ✅ Đúng |
| Write user_postgres.go | 20 phút | 30 phút | ⚠️ Nhiều typos |
| Write test main.go | 10 phút | 10 phút | ✅ Đúng |
| Debug và fix errors | - | 15 phút | ⚠️ Unplanned |
| **TỔNG** | **60 phút** | **90 phút** | ⚠️ Vượt 30 phút |

**Phân tích:**
- Vượt thời gian 30 phút (50%)
- Nguyên nhân: 11 typos cần fix
- Bài học: Gõ chậm hơn, check từng dòng

---

## 11. So Sánh Plan vs Reality

### Kế Hoạch Ban Đầu (ACTION_PLAN_VI.md)

**Sprint 2 tasks:**
1. ✅ Database connection implementation
2. ✅ Repository interface definition
3. ✅ GetUser method implementation

**Hoàn thành:** 3/3 tasks (100%)

### Công Việc Bổ Sung Không Dự Kiến

1. ✅ Implement toàn bộ CRUD methods (Create, Update, Delete, List)
   - Plan: Chỉ GetByID
   - Reality: Implement hết 5 methods

2. ✅ Fix 11 typos trong code
   - Không dự kiến trong plan
   - Mất 15 phút debug time

3. ✅ Setup database table
   - Plan: Đã tạo ở Sprint 1
   - Reality: Phải tạo lại vì missing

---

## 12. Chuẩn Bị Cho Sprint 3

### Sprint 3 Mục Tiêu

**Implement gRPC Server Handlers**

**File cần tạo:**
- `internal/server/user_server.go` - gRPC service implementation
- Update `cmd/server/main.go` - Start gRPC server

**Kiến thức cần ôn:**
- gRPC server setup
- gRPC status codes
- Error handling in gRPC
- Server interceptors (optional)

**Dependencies cần cài:**
```bash
# Already installed in Sprint 2
google.golang.org/grpc
```

**Time estimate:** 50-60 phút
- Write gRPC handlers: 30 phút
- Update main.go: 10 phút  
- Test với grpcurl: 10-20 phút

---

## 13. Bài Học Quan Trọng

### Technical
1. **Typos chiếm nhiều thời gian nhất** - 11 typos = 15 phút debug
2. **Go is strictly typed** - Compiler catches errors immediately
3. **Interface pattern powerful** - Easy to test and swap implementations
4. **Connection pooling essential** - Don't create new connection per request
5. **Context first parameter** - Standard Go idiom for cancellation

### Process
1. **Write incrementally** - Test sau mỗi file, không chờ viết hết
2. **Read error messages carefully** - Go compiler hints rất clear
3. **Use IDE autocomplete** - Tránh typos
4. **Check spelling** - `query` not `querry`, `created` not `cerated`
5. **Test database first** - Verify schema exists before coding

### Time Management
1. **Buffer 50% for debugging** - 60 phút → 90 phút actual
2. **Typos unpredictable** - Can't estimate fix time accurately
3. **First time slower** - Learning curve for new patterns
4. **Plan breaks** - Don't code 90 phút straight without testing

---

## 14. Metrics

### Code Quality
- **Compilation:** ✅ No warnings, no errors
- **Test coverage:** 🟡 Manual test only (1 test case)
- **Error handling:** ✅ All functions return errors
- **Documentation:** 🟡 Comments exist but minimal

### Performance
- **Connection pool:** ✅ Configured (10 max, 2 min)
- **Query efficiency:** ✅ Parameterized queries
- **Resource cleanup:** ✅ defer pool.Close() and rows.Close()

### Best Practices
- [x] Interface-based design
- [x] Context propagation
- [x] Error wrapping with %w
- [x] Parameterized queries (SQL injection safe)
- [x] Time formatting (RFC3339)
- [ ] Unit tests (Sprint 6)
- [ ] Integration tests (Sprint 6)

---

**Người thực hiện:** THAT Le Quang  
**Thời gian hoàn thành:** 1/12/2025 - Sprint 2  
**Trạng thái:** ✅ Hoàn thành (90/60 phút - vượt 30 phút)  
**Next Sprint:** Sprint 3 - gRPC Server Handlers (50-60 phút)
