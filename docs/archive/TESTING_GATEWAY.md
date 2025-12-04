# HƯỚNG DẪN CHẠY & TEST API GATEWAY

## ✅ ĐÃ HOÀN THÀNH

### User Service Refactoring
- ✅ Đã refactor tất cả methods sử dụng gRPC status codes
- ✅ Removed dependency on `pkg/common` response codes
- ✅ Proto files đã clean (không có code/message fields)
- ✅ Build successful

### Changes Summary
**File đã sửa:** `service-1-user/internal/server/user_server.go`

**Các thay đổi:**
1. Added gRPC imports: `google.golang.org/grpc/codes` và `google.golang.org/grpc/status`
2. Removed `agrios/pkg/common` import
3. Refactored tất cả 8 methods:
   - CreateUser: Return `status.Error(codes.InvalidArgument, ...)`
   - GetUser: Return `status.Error(codes.NotFound, ...)`
   - UpdateUser: Return `status.Error(codes.AlreadyExists, ...)`
   - DeleteUser: Return `status.Error(codes.NotFound, ...)`
   - ListUsers: Return `status.Error(codes.InvalidArgument, ...)`
   - Login: Return `status.Error(codes.Unauthenticated, ...)`
   - ValidateToken: Return `status.Error(codes.Unauthenticated, ...)`
   - Logout: Return `status.Error(codes.Internal, ...)`

4. Added helper function `isValidEmail()` thay thế `common.IsValidEmail()`

---

## 🚀 CÁCH CHẠY HỆ THỐNG

### Bước 1: Start Dependencies

#### Option A: Sử dụng Docker
```bash
# Start PostgreSQL
docker run -d --name postgres -p 5432:5432 \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  postgres:15-alpine

# Start Redis
docker run -d --name redis -p 6379:6379 redis:alpine
```

#### Option B: Local PostgreSQL và Redis
```bash
# Windows
net start postgresql-x64-18
# Redis phải dùng Docker hoặc WSL
```

### Bước 2: Chạy Migrations

```bash
# User database
psql -U postgres -c "CREATE DATABASE agrios_users;"
psql -U postgres -d agrios_users -f d:/agrios/service-1-user/migrations/001_create_users_table.sql

# Article database
psql -U postgres -c "CREATE DATABASE agrios_articles;"
psql -U postgres -d agrios_articles -f d:/agrios/service-2-article/migrations/001_create_articles_table.sql
```

### Bước 3: Start Services (3 terminals)

#### Terminal 1: User Service
```bash
cd d:/agrios/service-1-user
go run cmd/server/main.go
```

**Expected output:**
```
Connected to Redis successfully
Connected to PostgreSQL successfully
User Service (gRPC) listening on port 50051
```

#### Terminal 2: Article Service
```bash
cd d:/agrios/service-2-article
go run cmd/server/main.go
```

**Expected output:**
```
Connected to PostgreSQL successfully
Article Service (gRPC) listening on port 50052
```

#### Terminal 3: API Gateway
```bash
cd d:/agrios/service-gateway
go run cmd/server/main.go
```

**Expected output:**
```
Starting API Gateway...
User Service: localhost:50051
Article Service: localhost:50052
✓ Connected to User Service
✓ Connected to Article Service
API Gateway listening on :8080
```

---

## 🧪 CÁCH TEST

### Test 1: Create User (Success)

```bash
curl -X POST http://localhost:8080/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com","password":"password123"}'
```

**Expected Response:**
```json
{
  "code": "0",
  "message": "success",
  "data": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "created_at": "2025-12-04T...",
    "updated_at": "2025-12-04T..."
  }
}
```

### Test 2: Create User (Error - Invalid Email)

```bash
curl -X POST http://localhost:8080/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"invalid-email","password":"pass123"}'
```

**Expected Response:**
```json
{
  "code": "3",
  "message": "invalid email format"
}
```

### Test 3: Create User (Error - Duplicate Email)

```bash
curl -X POST http://localhost:8080/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Jane","email":"john@example.com","password":"pass456"}'
```

**Expected Response:**
```json
{
  "code": "6",
  "message": "email is already registered"
}
```

### Test 4: Get User (Success)

```bash
curl http://localhost:8080/api/v1/users/1
```

**Expected Response:**
```json
{
  "code": "0",
  "message": "success",
  "data": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com"
  }
}
```

### Test 5: Get User (Error - Not Found)

```bash
curl http://localhost:8080/api/v1/users/999
```

**Expected Response:**
```json
{
  "code": "5",
  "message": "user not found"
}
```

### Test 6: Login (Success)

```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"john@example.com","password":"password123"}'
```

**Expected Response:**
```json
{
  "code": "0",
  "message": "success",
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com"
    }
  }
}
```

### Test 7: Login (Error - Invalid Credentials)

```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"john@example.com","password":"wrongpassword"}'
```

**Expected Response:**
```json
{
  "code": "16",
  "message": "invalid email or password"
}
```

### Test 8: List Users

```bash
curl "http://localhost:8080/api/v1/users?page=1&page_size=10"
```

**Expected Response:**
```json
{
  "code": "0",
  "message": "success",
  "data": {
    "items": [
      {
        "id": 1,
        "name": "John Doe",
        "email": "john@example.com"
      }
    ],
    "total": 1,
    "page": 1,
    "size": 10,
    "has_more": false
  }
}
```

### Test 9: Create Article

```bash
curl -X POST http://localhost:8080/api/v1/articles \
  -H "Content-Type: application/json" \
  -d '{"title":"My First Article","content":"This is the content","user_id":1}'
```

**Expected Response:**
```json
{
  "code": "0",
  "message": "success",
  "data": {
    "id": 1,
    "title": "My First Article",
    "content": "This is the content",
    "user_id": 1,
    "created_at": "2025-12-04T...",
    "updated_at": "2025-12-04T..."
  }
}
```

### Test 10: Get Article with User Info

```bash
curl http://localhost:8080/api/v1/articles/1
```

**Expected Response:**
```json
{
  "code": "0",
  "message": "success",
  "data": {
    "id": 1,
    "title": "My First Article",
    "content": "This is the content",
    "user_id": 1,
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com"
    }
  }
}
```

---

## 📋 RESPONSE CODE MAPPING

### gRPC Codes → API Response Codes

| gRPC Code | API Code | HTTP Status | Example Use Case |
|-----------|----------|-------------|------------------|
| OK (0) | "0" | 200 | Success |
| INVALID_ARGUMENT (3) | "3" | 400 | Invalid email format |
| NOT_FOUND (5) | "5" | 404 | User not found |
| ALREADY_EXISTS (6) | "6" | 409 | Email already registered |
| PERMISSION_DENIED (7) | "7" | 403 | No permission |
| INTERNAL (13) | "13" | 500 | Database error |
| UNAVAILABLE (14) | "14" | 503 | Service down |
| UNAUTHENTICATED (16) | "16" | 401 | Invalid password |

---

## 🔍 DEBUGGING

### Check Services Status

```bash
# Check if services are running
netstat -ano | findstr "50051"  # User Service
netstat -ano | findstr "50052"  # Article Service
netstat -ano | findstr "8080"   # Gateway

# Check databases
psql -U postgres -l
docker exec redis redis-cli ping
```

### View Logs

Gateway và services sẽ log tất cả requests:

```
[POST] /api/v1/users 127.0.0.1:xxxxx
[CreateArticle] Verifying user exists: user_id=1
[GetUser] Success: user_id=1
```

### Common Issues

#### 1. "connection refused" on port 50051/50052
→ User/Article service chưa chạy. Check terminal outputs.

#### 2. "dial tcp: lookup localhost: no such host"
→ Thay `localhost` thành `127.0.0.1` trong env vars.

#### 3. Response code "13" (Internal Error)
→ Check database connection, migrations, và service logs.

#### 4. Response code "14" (Unavailable)
→ Service bị down. Restart services.

---

## 🎯 KIẾN TRÚC HOẠT ĐỘNG

### Request Flow

```
1. Client sends HTTP POST
   → http://localhost:8080/api/v1/users
   → Body: {"name":"John","email":"john@example.com","password":"pass123"}

2. Gateway receives HTTP request
   → UserHandler.CreateUser()
   → Parse JSON body

3. Gateway calls User Service via gRPC
   → grpc.Dial("localhost:50051")
   → userClient.CreateUser(ctx, &pb.CreateUserRequest{...})

4. User Service processes request
   → user_server.go: CreateUser()
   → Validates input
   → If error: return nil, status.Error(codes.InvalidArgument, "...")
   → If success: return &pb.CreateUserResponse{User: user}, nil

5. Gateway receives gRPC response
   → If error: response.Error(w, err) 
     → Converts: codes.InvalidArgument → {"code":"3", "message":"..."}
   → If success: response.Success(w, userData)
     → Formats: {"code":"0", "message":"success", "data":{...}}

6. Client receives HTTP response
   → Status: 200 OK (success) or 4xx/5xx (error)
   → Body: {"code":"0", "message":"success", "data":{...}}
```

### Inter-Service Communication

```
Article Service → User Service (gRPC direct)

1. Create Article request
2. Article Service validates user:
   → userClient.GetUser(ctx, userID)
3. User Service returns:
   → Success: User data
   → Error: status.Error(codes.NotFound, "user not found")
4. Article Service handles:
   → If NotFound: return error to Gateway
   → If Success: create article
```

---

## ✅ VERIFICATION CHECKLIST

Test từng bước:

- [ ] User Service starts on port 50051
- [ ] Article Service starts on port 50052
- [ ] Gateway starts on port 8080
- [ ] Create User returns code "0"
- [ ] Invalid email returns code "3"
- [ ] Duplicate email returns code "6"
- [ ] User not found returns code "5"
- [ ] Login success returns code "0" with tokens
- [ ] Wrong password returns code "16"
- [ ] List users returns paginated data
- [ ] Create article with valid user_id succeeds
- [ ] Get article includes user info
- [ ] All responses follow format: `{"code":"...","message":"...","data":...}`

---

## 📚 REFERENCES

- **Gateway README**: `service-gateway/README.md`
- **Architecture Guide**: `docs/ARCHITECTURE_GUIDE.md`
- **gRPC Status Codes**: https://grpc.io/docs/guides/status-codes/
- **Test Script**: `scripts/test-gateway.sh`

---

**DONE! Bây giờ bạn có thể test hệ thống hoàn chỉnh! 🎉**
