# Maintainer Profile

**Name:** THAT Le Quang

- **Role:** AI & DS Major Student
- **GitHub:** [thatlq1812]

---

# Sprint 4 - Article Service & gRPC Client Guide

**Sprint:** 4/6  
**Thời gian dự kiến:** 70-80 phút  
**Mục tiêu:** Implement Service 2 (Article CRUD) + gRPC Client gọi Service 1

---

## 🎯 Mục Tiêu Sprint 4

Sprint này bạn sẽ học và implement:

1. **gRPC Client** - Gọi service khác (Service 1)
2. **Article Repository** - CRUD cho articles table
3. **Inter-service Communication** - Service 2 ↔ Service 1
4. **Data Aggregation** - Combine article + user data

**Prerequisites:**
- ✅ Service 1 đang chạy trên :50051
- ✅ Database có table articles
- ✅ Proto files đã generated

---

## 📚 Kiến Thức Cần Biết Trước

### Concept 1: gRPC Client vs Server

**Đã biết (Sprint 3):**
```go
// SERVER - Nhận requests
type userServiceServer struct { ... }
func (s *userServiceServer) GetUser(...) { ... }
```

**Mới học hôm nay:**
```go
// CLIENT - Gửi requests
conn, _ := grpc.Dial("localhost:50051")
client := pb.NewUserServiceClient(conn)
user, _ := client.GetUser(ctx, &pb.GetUserRequest{Id: 1})
```

**Analogy:**
- Server = Nhà hàng (nhận order, phục vụ món ăn)
- Client = Khách hàng (gọi món, nhận món)

**Service 2 vừa là Server vừa là Client:**
- Server: Nhận requests từ bên ngoài về articles
- Client: Gọi Service 1 để lấy user info

### Concept 2: Connection Management

**Problem:** Mỗi gRPC call cần connection. Tạo connection mới mỗi lần = chậm.

**Solution:** Connection pool/reuse
```go
// ❌ BAD - Tạo mới mỗi lần
func GetUser(id int32) {
    conn := grpc.Dial("localhost:50051")  // Slow!
    defer conn.Close()
    // use conn...
}

// ✅ GOOD - Tạo 1 lần, reuse
var globalConn *grpc.ClientConn

func init() {
    globalConn = grpc.Dial("localhost:50051")  // Once
}

func GetUser(id int32) {
    client := pb.NewUserServiceClient(globalConn)  // Fast!
}
```

### Concept 3: Context Propagation

**Tại sao context quan trọng trong gRPC:**

```
Browser → Service 2 (GetArticle)
              ↓ context.WithTimeout(5s)
          Service 1 (GetUser)
```

Nếu Service 1 chậm (3 giây), Service 2 cancel sau 5 giây.

**Pattern:**
```go
// Service 2 nhận context từ client
func (s *articleServer) GetArticle(ctx context.Context, req *pb.GetArticleRequest) {
    // Pass context xuống Service 1
    user, err := s.userClient.GetUser(ctx, &userPb.GetUserRequest{...})
    // Nếu ctx timeout → Service 1 call bị cancel
}
```

### Concept 4: Error Handling Across Services

**Scenario:**
```
Client → Service 2: GetArticle(id=1)
         Service 2 → Service 1: GetUser(user_id=999)
         Service 1 ← NOT_FOUND
Client ← Service 2: INTERNAL or NOT_FOUND?
```

**Rule:**
- Service 1 error = NOT_FOUND → Service 2 nên return INTERNAL
- Lý do: Client chỉ hỏi về article, không quan tâm user
- Hoặc: Return custom error "article found but user missing"

---

## 📂 Cấu Trúc Project Sprint 4

**Service 2 structure:**
```
service-2-article/
├── cmd/
│   └── server/
│       └── main.go              ➕ Tạo mới
├── internal/
│   ├── client/
│   │   └── user_client.go       ➕ Tạo mới (gRPC client)
│   ├── db/
│   │   └── postgres.go          ➕ Tạo mới (copy từ Service 1)
│   ├── repository/
│   │   ├── article_repository.go  ➕ Tạo mới (interface)
│   │   └── article_postgres.go    ➕ Tạo mới (implementation)
│   └── server/
│       └── article_server.go    ⏳ Sprint 5
├── proto/
│   ├── article_service.proto    ✅ Đã có
│   ├── article_service.pb.go    ✅ Generated
│   └── ... (other proto files)
├── go.mod                       ✅ Đã có
└── go.sum
```

**Files trong Sprint 4:** 4 files mới (~350 lines)

---

## Bước 1: Setup Database Connection (10 phút)

### Tại sao cần file này?

Service 2 cần connect vào **cùng database** với Service 1 (userdb), nhưng chỉ query table `articles`.

### File: `internal/db/postgres.go`

**Vị trí:** Copy từ Service 1, modify minimal

**Giống Service 1 (90%):**
- Config struct
- Connection pooling logic
- NewPostgresPool function

**Khác Service 1:**
- Package path: `service-2-article/internal/db` (không phải service-1-user)

```go
package db

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

// Config chứa database connection info
type Config struct {
	Host     string
	Port     string
	User     string
	Password string
	DBName   string
}

// NewPostgresPool tạo connection pool
func NewPostgresPool(cfg Config) (*pgxpool.Pool, error) {
	// 1. Tạo connection string
	dsn := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		cfg.Host, cfg.Port, cfg.User, cfg.Password, cfg.DBName,
	)

	// 2. Parse config
	config, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		return nil, fmt.Errorf("parse config failed: %w", err)
	}

	// 3. Connection pool settings
	config.MaxConns = 10
	config.MinConns = 2
	config.MaxConnLifetime = time.Hour
	config.MaxConnIdleTime = 30 * time.Minute

	// 4. Create pool với timeout
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	pool, err := pgxpool.NewWithConfig(ctx, config)
	if err != nil {
		return nil, fmt.Errorf("connect to database failed: %w", err)
	}

	// 5. Ping để verify
	if err := pool.Ping(ctx); err != nil {
		return nil, fmt.Errorf("ping database failed: %w", err)
	}

	return pool, nil
}
```

**Learning points:**
- ✅ Service 2 dùng **cùng database**, **cùng connection pattern**
- ✅ Code reuse: Copy-paste OK trong microservices (mỗi service độc lập)
- ✅ Không share code qua library để tránh coupling

---

## Bước 2: Tạo gRPC Client (20 phút)

### Tại sao cần gRPC Client?

Service 2 cần **gọi Service 1** để:
1. Validate user_id khi tạo article
2. Lấy user info khi trả về ArticleWithUser

### Learning: Client Pattern

**Pattern 1: Direct call (simple nhưng không tốt)**
```go
// ❌ BAD - Hard to test, hard to mock
func CreateArticle(userId int32) {
    conn := grpc.Dial("localhost:50051")
    client := pb.NewUserServiceClient(conn)
    user, _ := client.GetUser(...)
}
```

**Pattern 2: Injected client (better)**
```go
// ✅ GOOD - Testable với mock client
type ArticleService struct {
    userClient pb.UserServiceClient  // Interface
}

// Test:
mockClient := &MockUserClient{...}
service := ArticleService{userClient: mockClient}
```

### File: `internal/client/user_client.go`

**Vị trí:** Line 1-80 (new file)

```go
package client

import (
	"context"
	"fmt"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"

	pb "service-2-article/proto"
)

// UserClient wraps gRPC connection vào User Service
type UserClient struct {
	conn   *grpc.ClientConn
	client pb.UserServiceClient
}

// NewUserClient tạo client mới
func NewUserClient(address string) (*UserClient, error) {
	// 1. Dial với timeout
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// 2. Create connection
	conn, err := grpc.DialContext(
		ctx,
		address,
		grpc.WithTransportCredentials(insecure.NewCredentials()),  // No TLS
		grpc.WithBlock(),  // Wait cho connection ready
	)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to user service: %w", err)
	}

	// 3. Create client stub
	client := pb.NewUserServiceClient(conn)

	return &UserClient{
		conn:   conn,
		client: client,
	}, nil
}

// Close đóng connection
func (c *UserClient) Close() error {
	return c.conn.Close()
}

// GetUser gọi Service 1 để lấy user by ID
func (c *UserClient) GetUser(ctx context.Context, userId int32) (*pb.User, error) {
	// Set timeout cho RPC call
	ctx, cancel := context.WithTimeout(ctx, 2*time.Second)
	defer cancel()

	// Gọi Service 1
	resp, err := c.client.GetUser(ctx, &pb.GetUserRequest{
		Id: userId,
	})
	if err != nil {
		return nil, fmt.Errorf("get user from service-1 failed: %w", err)
	}

	return resp, nil
}

// ValidateUserExists check user có tồn tại không
func (c *UserClient) ValidateUserExists(ctx context.Context, userId int32) error {
	_, err := c.GetUser(ctx, userId)
	if err != nil {
		return fmt.Errorf("user %d does not exist: %w", userId, err)
	}
	return nil
}
```

**Giải thích chi tiết:**

**1. Connection options:**
```go
grpc.WithTransportCredentials(insecure.NewCredentials())
```
- `insecure`: Không dùng TLS/SSL
- Production: Nên dùng `credentials.NewTLS()`
- Development: OK để insecure

```go
grpc.WithBlock()
```
- Block cho đến khi connection ready
- Nếu Service 1 down → NewUserClient fail ngay
- Alternative: Non-blocking, check health sau

**2. Timeout layers:**
```go
// Layer 1: Connection timeout (5s)
ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
conn, err := grpc.DialContext(ctx, ...)

// Layer 2: RPC timeout (2s)
ctx, cancel := context.WithTimeout(ctx, 2*time.Second)
resp, err := c.client.GetUser(ctx, ...)
```
- Connection timeout: Chờ Service 1 online
- RPC timeout: Chờ Service 1 process request
- Tổng có thể lên 7s nếu cả 2 timeout

**3. Error handling:**
```go
return nil, fmt.Errorf("get user from service-1 failed: %w", err)
```
- Wrap error với context
- Caller biết lỗi từ Service 1, không phải Service 2

**Learning outcomes:**
- ✅ Hiểu gRPC client initialization
- ✅ Timeout management trong distributed systems
- ✅ Connection lifecycle (dial → use → close)
- ✅ Error propagation across services

---

## Bước 3: Article Repository Interface (10 phút)

### Tại sao cần Repository?

**Giống Service 1:**
- Tách business logic khỏi database logic
- Dễ test với mock
- Dễ đổi database

**Khác Service 1:**
- Articles có relationship với Users
- Cần filter by user_id

### File: `internal/repository/article_repository.go`

**Vị trí:** Line 1-25 (new file)

```go
package repository

import (
	"context"
	pb "service-2-article/proto"
)

// ArticleRepository định nghĩa CRUD operations cho articles
type ArticleRepository interface {
	// GetByID lấy article theo ID
	GetByID(ctx context.Context, id int32) (*pb.Article, error)
	
	// Create tạo article mới
	Create(ctx context.Context, title, content string, userId int32) (*pb.Article, error)
	
	// Update cập nhật article
	Update(ctx context.Context, id int32, title, content string) (*pb.Article, error)
	
	// Delete xóa article
	Delete(ctx context.Context, id int32) error
	
	// ListByUser lấy articles của 1 user (pagination)
	ListByUser(ctx context.Context, userId, limit, offset int32) ([]*pb.Article, int32, error)
	
	// ListAll lấy tất cả articles (pagination)
	ListAll(ctx context.Context, limit, offset int32) ([]*pb.Article, int32, error)
}
```

**So sánh với User Repository:**

| Method | User Repo | Article Repo | Notes |
|--------|-----------|--------------|-------|
| GetByID | ✅ | ✅ | Same |
| Create | name, email | title, content, user_id | Article thêm user_id |
| Update | id, name, email | id, title, content | Article không update user_id |
| Delete | ✅ | ✅ | Same |
| List | List() | ListAll() + ListByUser() | Article có 2 variants |

**Tại sao có ListByUser?**
```sql
-- Use case: Xem tất cả bài viết của THAT Le Quang
SELECT * FROM articles WHERE user_id = 1;
```

---

## Bước 4: Article Repository Implementation (30 phút)

### File: `internal/repository/article_postgres.go`

**Vị trí:** Line 1-180 (new file)

**Structure tương tự User Repository:**
```go
type → constructor → 6 methods
```

```go
package repository

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	pb "service-2-article/proto"
)

// articlePostgresRepo implement ArticleRepository với PostgreSQL
type articlePostgresRepo struct {
	db *pgxpool.Pool
}

// NewArticlePostgresRepository tạo repository mới
func NewArticlePostgresRepository(db *pgxpool.Pool) ArticleRepository {
	return &articlePostgresRepo{db: db}
}

// GetByID lấy article theo ID
func (r *articlePostgresRepo) GetByID(ctx context.Context, id int32) (*pb.Article, error) {
	query := `
		SELECT id, title, content, user_id, created_at, updated_at
		FROM articles
		WHERE id = $1
	`

	var article pb.Article
	var createdAt, updatedAt time.Time

	err := r.db.QueryRow(ctx, query, id).Scan(
		&article.Id,
		&article.Title,
		&article.Content,
		&article.UserId,
		&createdAt,
		&updatedAt,
	)

	if err != nil {
		return nil, fmt.Errorf("query article failed: %w", err)
	}

	// Convert time → string
	article.CreatedAt = createdAt.Format(time.RFC3339)
	article.UpdatedAt = updatedAt.Format(time.RFC3339)

	return &article, nil
}

// Create tạo article mới
func (r *articlePostgresRepo) Create(ctx context.Context, title, content string, userId int32) (*pb.Article, error) {
	query := `
		INSERT INTO articles (title, content, user_id)
		VALUES ($1, $2, $3)
		RETURNING id, title, content, user_id, created_at, updated_at
	`

	var article pb.Article
	var createdAt, updatedAt time.Time

	err := r.db.QueryRow(ctx, query, title, content, userId).Scan(
		&article.Id,
		&article.Title,
		&article.Content,
		&article.UserId,
		&createdAt,
		&updatedAt,
	)

	if err != nil {
		return nil, fmt.Errorf("insert article failed: %w", err)
	}

	article.CreatedAt = createdAt.Format(time.RFC3339)
	article.UpdatedAt = updatedAt.Format(time.RFC3339)

	return &article, nil
}

// Update cập nhật article
func (r *articlePostgresRepo) Update(ctx context.Context, id int32, title, content string) (*pb.Article, error) {
	query := `
		UPDATE articles
		SET title = $1, content = $2, updated_at = CURRENT_TIMESTAMP
		WHERE id = $3
		RETURNING id, title, content, user_id, created_at, updated_at
	`

	var article pb.Article
	var createdAt, updatedAt time.Time

	err := r.db.QueryRow(ctx, query, title, content, id).Scan(
		&article.Id,
		&article.Title,
		&article.Content,
		&article.UserId,
		&createdAt,
		&updatedAt,
	)

	if err != nil {
		return nil, fmt.Errorf("update article failed: %w", err)
	}

	article.CreatedAt = createdAt.Format(time.RFC3339)
	article.UpdatedAt = updatedAt.Format(time.RFC3339)

	return &article, nil
}

// Delete xóa article
func (r *articlePostgresRepo) Delete(ctx context.Context, id int32) error {
	query := `DELETE FROM articles WHERE id = $1`

	result, err := r.db.Exec(ctx, query, id)
	if err != nil {
		return fmt.Errorf("delete article failed: %w", err)
	}

	if result.RowsAffected() == 0 {
		return fmt.Errorf("article with id %d not found", id)
	}

	return nil
}

// ListByUser lấy articles của 1 user
func (r *articlePostgresRepo) ListByUser(ctx context.Context, userId, limit, offset int32) ([]*pb.Article, int32, error) {
	// Query articles
	query := `
		SELECT id, title, content, user_id, created_at, updated_at
		FROM articles
		WHERE user_id = $1
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3
	`

	rows, err := r.db.Query(ctx, query, userId, limit, offset)
	if err != nil {
		return nil, 0, fmt.Errorf("query articles failed: %w", err)
	}
	defer rows.Close()

	var articles []*pb.Article

	for rows.Next() {
		var article pb.Article
		var createdAt, updatedAt time.Time

		err := rows.Scan(
			&article.Id,
			&article.Title,
			&article.Content,
			&article.UserId,
			&createdAt,
			&updatedAt,
		)
		if err != nil {
			return nil, 0, fmt.Errorf("scan article failed: %w", err)
		}

		article.CreatedAt = createdAt.Format(time.RFC3339)
		article.UpdatedAt = updatedAt.Format(time.RFC3339)
		articles = append(articles, &article)
	}

	// Count total
	countQuery := `SELECT COUNT(*) FROM articles WHERE user_id = $1`
	var total int32
	err = r.db.QueryRow(ctx, countQuery, userId).Scan(&total)
	if err != nil {
		return nil, 0, fmt.Errorf("count articles failed: %w", err)
	}

	return articles, total, nil
}

// ListAll lấy tất cả articles
func (r *articlePostgresRepo) ListAll(ctx context.Context, limit, offset int32) ([]*pb.Article, int32, error) {
	// Query articles
	query := `
		SELECT id, title, content, user_id, created_at, updated_at
		FROM articles
		ORDER BY created_at DESC
		LIMIT $1 OFFSET $2
	`

	rows, err := r.db.Query(ctx, query, limit, offset)
	if err != nil {
		return nil, 0, fmt.Errorf("query articles failed: %w", err)
	}
	defer rows.Close()

	var articles []*pb.Article

	for rows.Next() {
		var article pb.Article
		var createdAt, updatedAt time.Time

		err := rows.Scan(
			&article.Id,
			&article.Title,
			&article.Content,
			&article.UserId,
			&createdAt,
			&updatedAt,
		)
		if err != nil {
			return nil, 0, fmt.Errorf("scan article failed: %w", err)
		}

		article.CreatedAt = createdAt.Format(time.RFC3339)
		article.UpdatedAt = updatedAt.Format(time.RFC3339)
		articles = append(articles, &article)
	}

	// Count total
	countQuery := `SELECT COUNT(*) FROM articles`
	var total int32
	err = r.db.QueryRow(ctx, countQuery).Scan(&total)
	if err != nil {
		return nil, 0, fmt.Errorf("count articles failed: %w", err)
	}

	return articles, total, nil
}
```

**Key differences từ User Repository:**

**1. Updated_at handling:**
```sql
UPDATE articles
SET title = $1, content = $2, updated_at = CURRENT_TIMESTAMP
```
- Articles track last modification time
- Users không có updated_at

**2. Filter by user_id:**
```sql
WHERE user_id = $1
```
- ListByUser cần filter
- ListAll không filter

**3. Order by created_at DESC:**
```sql
ORDER BY created_at DESC
```
- Newest articles first
- Users order by ID

**Learning outcomes:**
- ✅ SQL queries với WHERE clause
- ✅ Timestamp handling (created_at, updated_at)
- ✅ Multiple list methods cho different use cases

---

## Bước 5: Test Repository (10 phút)

### Tạo Test Program

**File:** `cmd/server/main.go` (temporary test version)

```go
package main

import (
	"context"
	"fmt"
	"log"

	"service-2-article/internal/db"
	"service-2-article/internal/repository"
)

func main() {
	// 1. Connect database
	dbConfig := db.Config{
		Host:     "127.0.0.1",
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
	articleRepo := repository.NewArticlePostgresRepository(pool)

	// 3. Test GetByID
	ctx := context.Background()
	article, err := articleRepo.GetByID(ctx, 1)
	if err != nil {
		log.Fatalf("Failed to get article: %v", err)
	}

	fmt.Printf("✅ Article found: ID=%d, Title=%s, Content=%s, UserID=%d\n",
		article.Id, article.Title, article.Content, article.UserId)

	// 4. Test ListByUser
	articles, total, err := articleRepo.ListByUser(ctx, 1, 10, 0)
	if err != nil {
		log.Fatalf("Failed to list articles: %v", err)
	}

	fmt.Printf("✅ Found %d articles by user 1 (total: %d)\n", len(articles), total)
	for _, a := range articles {
		fmt.Printf("   - %s\n", a.Title)
	}
}
```

**Run test:**
```bash
cd /d/agrios/service-2-article
go mod tidy
go run cmd/server/main.go
```

**Expected output:**
```
✅ Connected to PostgreSQL
✅ Article found: ID=1, Title=Bài viết đầu tiên, Content=Nội dung về Go language, UserID=1
✅ Found 2 articles by user 1 (total: 2)
   - Bài viết đầu tiên
   - Hướng dẫn PostgreSQL
```

---

## Bước 6: Test gRPC Client (10 phút)

### Update Test Program

Thêm test gRPC client vào `cmd/server/main.go`:

```go
package main

import (
	"context"
	"fmt"
	"log"

	"service-2-article/internal/client"
	"service-2-article/internal/db"
	"service-2-article/internal/repository"
)

func main() {
	// ... (database code như trên)

	// 5. Test gRPC Client
	log.Println("\n🔗 Testing gRPC Client...")
	
	userClient, err := client.NewUserClient("localhost:50051")
	if err != nil {
		log.Fatalf("Failed to create user client: %v", err)
	}
	defer userClient.Close()
	
	log.Println("✅ Connected to User Service")

	// Test GetUser
	user, err := userClient.GetUser(ctx, 1)
	if err != nil {
		log.Fatalf("Failed to get user: %v", err)
	}

	fmt.Printf("✅ User from Service 1: ID=%d, Name=%s, Email=%s\n",
		user.Id, user.Name, user.Email)

	// Test ValidateUserExists
	err = userClient.ValidateUserExists(ctx, 1)
	if err != nil {
		log.Fatalf("User validation failed: %v", err)
	}
	fmt.Println("✅ User validation passed")

	// Test với user không tồn tại
	err = userClient.ValidateUserExists(ctx, 999)
	if err != nil {
		fmt.Printf("✅ Correctly detected non-existent user: %v\n", err)
	}
}
```

**Chạy test (cần 2 terminals):**

Terminal 1 - Service 1:
```bash
cd /d/agrios/service-1-user
go run cmd/server/main.go
# Keep running
```

Terminal 2 - Service 2 test:
```bash
cd /d/agrios/service-2-article
go run cmd/server/main.go
```

**Expected output:**
```
✅ Connected to PostgreSQL
✅ Article found: ...
✅ Found 2 articles by user 1

🔗 Testing gRPC Client...
✅ Connected to User Service
✅ User from Service 1: ID=1, Name=THAT Le Quang, Email=that.le@example.com
✅ User validation passed
✅ Correctly detected non-existent user: user 999 does not exist
```

---

## Checklist Sprint 4

### Code Implementation
- [ ] `internal/db/postgres.go` created
- [ ] `internal/client/user_client.go` created
- [ ] `internal/repository/article_repository.go` created
- [ ] `internal/repository/article_postgres.go` created
- [ ] `cmd/server/main.go` test program created

### Testing
- [ ] Database connection successful
- [ ] Article repository GetByID works
- [ ] Article repository ListByUser works
- [ ] gRPC client connects to Service 1
- [ ] gRPC client GetUser returns data
- [ ] gRPC client validates user existence

### Understanding
- [ ] Hiểu gRPC client initialization
- [ ] Hiểu timeout management
- [ ] Hiểu inter-service communication
- [ ] Hiểu repository pattern cho articles
- [ ] Hiểu filter queries (WHERE user_id)

---

## Troubleshooting

### Issue: "Failed to connect to user service"

**Lỗi:**
```
Failed to connect to user service: context deadline exceeded
```

**Nguyên nhân:**
Service 1 chưa chạy hoặc chạy sai port

**Giải pháp:**
```bash
# Terminal 1
cd service-1-user
go run cmd/server/main.go
# Check: "gRPC server listening on :50051"
```

### Issue: "no rows in result set"

**Lỗi:**
```
query article failed: no rows in result set
```

**Nguyên nhân:**
Database chưa có articles

**Giải pháp:**
```bash
docker exec -i agrios-postgres psql -U agrios -d userdb << 'EOF'
SELECT * FROM articles;
EOF
```

Nếu empty, insert data:
```bash
docker exec -i agrios-postgres psql -U agrios -d userdb << 'EOF'
INSERT INTO articles (title, content, user_id) VALUES
('Test Article', 'Content here', 1);
EOF
```

---

## Learning Outcomes Sprint 4

### Technical Skills Learned

**gRPC Client:**
- ✅ Initialize connection với `grpc.Dial()`
- ✅ Manage connection lifecycle
- ✅ Set timeouts cho connections và calls
- ✅ Handle errors từ remote service

**Repository Pattern:**
- ✅ Filter queries với WHERE clause
- ✅ Multiple list methods (ListAll vs ListByUser)
- ✅ Timestamp handling (created_at, updated_at)

**Distributed Systems:**
- ✅ Service-to-service communication
- ✅ Timeout propagation với context
- ✅ Error handling across services

### Conceptual Understanding

**Microservices Communication:**
```
Client → Service 2 → Service 1
        (Article)    (User)
```

**Why separate services?**
- User service độc lập: có thể scale riêng
- Article service độc lập: có thể deploy riêng
- Loose coupling: Thay đổi User không ảnh hưởng Article

**Trade-offs:**
- ✅ Flexibility, scalability
- ❌ Network latency (gRPC call slower than function call)
- ❌ Complexity (2 processes thay vì 1)

---

## Next: Sprint 5

**Mục tiêu Sprint 5:**
- Implement Article gRPC Server (5 handlers)
- Combine article + user data (ArticleWithUser)
- Test end-to-end flow

**Estimated time:** 50-60 phút

---

**Người hướng dẫn:** GitHub Copilot  
**Người thực hiện:** THAT Le Quang  
**Thời gian:** 1/12/2025 - Sprint 4 Guide
