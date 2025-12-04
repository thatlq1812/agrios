# HƯỚNG DẪN KIẾN TRÚC gRPC + REST API GATEWAY

## TÓM TẮT GIẢI PHÁP

**Vấn đề**: Mentor yêu cầu format REST API với codes "0"-"16", nhưng services đang dùng gRPC

**Giải pháp**: API Gateway Pattern
- **Internal**: gRPC thuần túy giữa services (codes.InvalidArgument, status.Error)
- **External**: HTTP REST API với format mentor yêu cầu (`{"code":"0", "message":"success", "data":{}}`)

---

## KIẾN TRÚC MỚI

```
┌──────────────────┐
│     CLIENT       │
│   (Browser/App)  │
└────────┬─────────┘
         │
         │ HTTP REST (port 8080)
         │ {"code":"0", "message":"success", "data":{}}
         ↓
┌────────────────────────────┐
│      API GATEWAY           │
│  service-gateway:8080      │
│                            │
│  Chức năng:                │
│  1. Nhận HTTP REST         │
│  2. Convert → gRPC         │
│  3. Gọi User/Article       │
│  4. Format response        │
│  5. Map gRPC codes → API   │
└──┬──────────────────────┬──┘
   │                      │
   │ gRPC (PURE)         │ gRPC (PURE)
   │ port 50051          │ port 50052
   ↓                     ↓
┌──────────────┐    ┌─────────────────┐
│ User Service │◄───┤ Article Service │
│   :50051     │    │     :50052      │
│              │    │                 │
│ gRPC Server  │    │ gRPC Server     │
│ Uses:        │    │ Uses:           │
│ - status     │    │ - status        │
│ - codes      │    │ - codes         │
└──────┬───────┘    └────────┬────────┘
       │                     │
       ├─────────────────────┤
       │                     │
    ┌──▼───┐  ┌──────┐  ┌───▼────┐
    │Redis │  │Users │  │Articles│
    │:6379 │  │  DB  │  │   DB   │
    └──────┘  └──────┘  └────────┘
```

---

## VỊ TRÍ CÁC FILE QUAN TRỌNG

### 1. API Gateway (MỚI)

**Location**: `service-gateway/`

#### **File: `internal/response/wrapper.go`**
**Vai trò**: Convert gRPC responses/errors sang format mentor

```go
// Mapping gRPC codes sang string format
const (
    CodeOK                 = "000" // codes.OK
    CodeCancelled          = "001" // codes.Cancelled
    CodeUnknown            = "002" // codes.Unknown
    CodeInvalidArgument    = "003" // codes.InvalidArgument
    CodeDeadlineExceeded   = "004" // codes.DeadlineExceeded
    CodeNotFound           = "005" // codes.NotFound
    CodeAlreadyExists      = "006" // codes.AlreadyExists
    CodePermissionDenied   = "007" // codes.PermissionDenied
    CodeResourceExhausted  = "008" // codes.ResourceExhausted
    CodeFailedPrecondition = "009" // codes.FailedPrecondition
    CodeAborted            = "010" // codes.Aborted
    CodeOutOfRange         = "011" // codes.OutOfRange
    CodeUnimplemented      = "012" // codes.Unimplemented
    CodeInternal           = "013" // codes.Internal
    CodeUnavailable        = "014" // codes.Unavailable
    CodeDataLoss           = "015" // codes.DataLoss
    CodeUnauthenticated    = "016" // codes.Unauthenticated
)

// Convert gRPC error → API response
func Error(w http.ResponseWriter, err error) {
    st, ok := status.FromError(err)
    apiCode := MapGRPCCodeToString(st.Code())
    httpStatus := MapGRPCCodeToHTTPStatus(st.Code())
    
    json.NewEncoder(w).Encode(APIResponse{
        Code:    apiCode,      // "3", "5", "16", etc.
        Message: st.Message(),
    })
}
```

#### **File: `internal/handler/user_handler.go`**
**Vai trò**: HTTP handlers cho User APIs

```go
// POST /api/v1/users
func (h *UserHandler) CreateUser(w http.ResponseWriter, r *http.Request) {
    // 1. Parse HTTP JSON request
    var req CreateUserRequest
    json.NewDecoder(r.Body).Decode(&req)
    
    // 2. Call gRPC User Service
    resp, err := h.userClient.CreateUser(ctx, &userpb.CreateUserRequest{
        Name:     req.Name,
        Email:    req.Email,
        Password: req.Password,
    })
    
    // 3. Handle gRPC error
    if err != nil {
        // Tự động convert: codes.InvalidArgument → {"code":"3", "message":"..."}
        response.Error(w, err)
        return
    }
    
    // 4. Format success response
    response.Success(w, map[string]interface{}{
        "id":    resp.User.Id,
        "name":  resp.User.Name,
        "email": resp.User.Email,
    })
}
```

**Luồng xử lý**:
```
Client → HTTP POST /api/v1/users
       → UserHandler.CreateUser()
       → gRPC UserService.CreateUser()
       → gRPC returns error: status.Error(codes.InvalidArgument, "email is required")
       → response.Error() converts to: {"code":"3", "message":"email is required"}
       → Client nhận HTTP 400 với body trên
```

#### **File: `internal/handler/article_handler.go`**
**Vai trò**: HTTP handlers cho Article APIs

Tương tự user_handler.go nhưng gọi Article Service

#### **File: `cmd/server/main.go`**
**Vai trò**: Main server, setup routes

```go
// Connect to gRPC services
userConn, _ := grpc.Dial("localhost:50051", ...)
userClient := userpb.NewUserServiceClient(userConn)

articleConn, _ := grpc.Dial("localhost:50052", ...)
articleClient := articlepb.NewArticleServiceClient(articleConn)

// Setup HTTP routes
router := mux.NewRouter()
router.HandleFunc("/api/v1/users", userHandler.CreateUser).Methods("POST")
router.HandleFunc("/api/v1/users/{id}", userHandler.GetUser).Methods("GET")
// ... more routes

http.ListenAndServe(":8080", router)
```

---

### 2. User Service (CẦN REFACTOR)

**Location**: `service-1-user/`

#### **File: `proto/user_service.proto`**
**Status**: ✅ ĐÃ ĐÚNG - Proto đã clean, không có code/message fields

```proto
message CreateUserResponse {
  User user = 1;  // Chỉ có data, không có code/message
}

message LoginResponse {
  string access_token = 1;
  string refresh_token = 2;
  User user = 3;
}
```

#### **File: `internal/server/user_server.go`**
**Status**: ❌ CẦN SỬA - Đang return responses với code/message

**HIỆN TẠI (SAI)**:
```go
func (s *UserServer) CreateUser(ctx, req) (*pb.CreateUserResponse, error) {
    if req.Name == "" {
        return &pb.CreateUserResponse{
            Code:    common.CodeInvalidArgument,  // ❌ SAI
            Message: "name is required",           // ❌ SAI
        }, nil
    }
    // ...
}
```

**CẦN SỬA THÀNH**:
```go
func (s *UserServer) CreateUser(ctx, req) (*pb.CreateUserResponse, error) {
    if req.Name == "" {
        // ✅ ĐÚNG: Return gRPC error
        return nil, status.Error(codes.InvalidArgument, "name is required")
    }
    
    user, err := s.repo.Create(ctx, req.Name, req.Email, req.Password)
    if err != nil {
        if err == ErrUserAlreadyExists {
            return nil, status.Error(codes.AlreadyExists, "email already registered")
        }
        return nil, status.Error(codes.Internal, err.Error())
    }
    
    // ✅ ĐÚNG: Return only data
    return &pb.CreateUserResponse{
        User: user,
    }, nil
}
```

**Cần sửa tất cả methods**:
- CreateUser
- GetUser
- UpdateUser
- DeleteUser
- ListUsers
- Login
- ValidateToken
- Logout

---

### 3. Article Service

**Location**: `service-2-article/`

#### **File: `internal/server/article_server.go`**
**Status**: ✅ ĐÃ ĐÚNG - Đã dùng gRPC status codes

```go
func (s *ArticleServer) CreateArticle(ctx, req) (*pb.Article, error) {
    if req.Title == "" {
        return nil, status.Error(codes.InvalidArgument, "title is required")
    }
    
    // Validate user exists - gọi User Service qua gRPC
    _, err := s.userClient.GetUser(ctx, &userpb.GetUserRequest{Id: req.UserId})
    if err != nil {
        st, _ := status.FromError(err)
        if st.Code() == codes.NotFound {
            return nil, status.Error(codes.InvalidArgument, "user not found")
        }
    }
    
    article, err := s.repo.Create(ctx, req.Title, req.Content, req.UserId)
    return article, nil
}
```

**VỊ TRÍ GIAO TIẾP gRPC GIỮA SERVICES**:

**File**: `service-2-article/internal/client/user_client.go`

```go
type UserClient struct {
    client userpb.UserServiceClient
}

// Gọi User Service để validate user
func (c *UserClient) GetUser(ctx, userID) (*userpb.User, error) {
    resp, err := c.client.GetUser(ctx, &userpb.GetUserRequest{Id: userID})
    if err != nil {
        return nil, err  // gRPC error: status.Error(codes.NotFound, ...)
    }
    return resp.User, nil
}
```

**Usage trong Article Server**:
```go
// Article Service gọi User Service
userServiceUser, err := s.userClient.GetUser(ctx, article.UserId)
if err != nil {
    st := status.Convert(err)
    switch st.Code() {
    case codes.NotFound:
        // User not found - graceful degradation
        return &pb.ArticleWithUser{Article: article, User: nil}, nil
    case codes.Unavailable:
        // Service down
        return nil, status.Error(codes.Unavailable, "user service unavailable")
    }
}
```

---

## LUỒNG XỬ LÝ CHI TIẾT

### Scenario 1: Create User (Success)

```
1. Client gửi HTTP POST
   → POST http://localhost:8080/api/v1/users
   → Body: {"name":"John","email":"john@example.com","password":"pass123"}

2. API Gateway (port 8080)
   → UserHandler.CreateUser() nhận request
   → Parse JSON body
   
3. Gateway gọi User Service qua gRPC
   → grpc.Dial("localhost:50051")
   → userClient.CreateUser(ctx, &pb.CreateUserRequest{...})
   
4. User Service (port 50051)
   → user_server.go: CreateUser()
   → Validate input
   → Hash password
   → Save to database
   → Return: &pb.CreateUserResponse{User: user}, nil
   
5. Gateway nhận response
   → resp.User có data
   → Call response.Success(w, userData)
   
6. response.Success() format response
   → APIResponse{Code: "0", Message: "success", Data: userData}
   
7. Client nhận HTTP 200
   → Body: {"code":"0","message":"success","data":{"id":1,"name":"John",...}}
```

### Scenario 2: Create User (Error - Email Already Exists)

```
1. Client gửi HTTP POST
   → POST http://localhost:8080/api/v1/users
   → Body: {"name":"John","email":"existing@example.com","password":"pass123"}

2. Gateway gọi User Service

3. User Service
   → Check database: email đã tồn tại
   → Return: nil, status.Error(codes.AlreadyExists, "email already registered")
   
4. Gateway nhận gRPC error
   → err != nil
   → Call response.Error(w, err)
   
5. response.Error() xử lý
   → st := status.FromError(err)
   → st.Code() = codes.AlreadyExists (6)
   → apiCode = MapGRPCCodeToString(6) = "6"
   → httpStatus = MapGRPCCodeToHTTPStatus(6) = 409
   
6. Client nhận HTTP 409 Conflict
   → Body: {"code":"6","message":"email already registered"}
```

### Scenario 3: Create Article (Validate User)

```
1. Client gửi HTTP POST
   → POST http://localhost:8080/api/v1/articles
   → Body: {"title":"My Article","content":"...","user_id":1}

2. Gateway gọi Article Service

3. Article Service
   → Validate input
   → Gọi User Service để check user exists:
      userClient.GetUser(ctx, &pb.GetUserRequest{Id: 1})
   
4. User Service
   → Query database
   → Return: &pb.GetUserResponse{User: user}, nil
   
5. Article Service
   → User exists ✓
   → Create article in database
   → Return: article, nil
   
6. Gateway format response
   → {"code":"0","message":"success","data":{article}}

7. Client nhận HTTP 200 OK
```

### Scenario 4: Get Article with User Info (Inter-service Communication)

```
1. Client: GET http://localhost:8080/api/v1/articles/1

2. Gateway → Article Service (gRPC)

3. Article Service
   → Get article from database
   → article.user_id = 5
   → Gọi User Service qua gRPC:
      userClient.GetUser(ctx, &pb.GetUserRequest{Id: 5})
   
4. User Service → Article Service (gRPC response)
   → Return user data
   
5. Article Service → Gateway
   → Return: ArticleWithUser{Article: article, User: user}
   
6. Gateway format response
   → Combine article + user data
   → {"code":"0","message":"success","data":{
        "id":1,
        "title":"...",
        "user":{"id":5,"name":"..."}
      }}

7. Client nhận HTTP 200 với full data
```

---

## CHECKLIST IMPLEMENT

### ✅ DONE: API Gateway
- [x] Response wrapper với gRPC codes mapping
- [x] User handler (HTTP → gRPC)
- [x] Article handler (HTTP → gRPC)
- [x] Main server với routes
- [x] go.mod setup
- [x] README documentation

### ⏳ TODO: User Service Refactor
- [ ] Update user_server.go: Sửa tất cả methods
  - [ ] CreateUser: Remove code/message, return status.Error()
  - [ ] GetUser: Return status.Error() for not found
  - [ ] UpdateUser: Return status.Error()
  - [ ] DeleteUser: Return status.Error()
  - [ ] ListUsers: Return status.Error()
  - [ ] Login: Return status.Error(codes.Unauthenticated)
  - [ ] ValidateToken: Return status.Error()
  - [ ] Logout: Return status.Error()

### ✅ DONE: Article Service
- [x] Đã dùng gRPC status codes
- [x] Đã có inter-service communication với User Service

### ⏳ TODO: Documentation
- [ ] Update main README.md
- [ ] Update CHANGELOG.md
- [ ] Create API documentation

---

## CÁCH CHẠY HỆ THỐNG

### Step 1: Start Database Services
```bash
docker run -d --name postgres -p 5432:5432 -e POSTGRES_PASSWORD=postgres postgres:15
docker run -d --name redis -p 6379:6379 redis:alpine
```

### Step 2: Start User Service
```bash
cd service-1-user
go run cmd/server/main.go
# Listening on :50051
```

### Step 3: Start Article Service
```bash
cd service-2-article
go run cmd/server/main.go
# Listening on :50052
```

### Step 4: Start API Gateway
```bash
cd service-gateway
go run cmd/server/main.go
# Listening on :8080
```

### Step 5: Test với curl
```bash
# Create user qua Gateway
curl -X POST http://localhost:8080/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","password":"password123"}'

# Response:
# {"code":"0","message":"success","data":{"id":1,...}}

# Login
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Create article
curl -X POST http://localhost:8080/api/v1/articles \
  -H "Content-Type: application/json" \
  -d '{"title":"My Article","content":"Content","user_id":1}'
```

---

## SO SÁNH TRƯỚC VÀ SAU

### TRƯỚC (SAI)
```
Client → gRPC directly → User Service
                         (proto có code/message fields)
                         (return code trong response body)
```

### SAU (ĐÚNG)
```
Client → HTTP REST → API Gateway → gRPC → User Service
         (JSON)      (convert)    (pure) (status.Error())
         
Format:                Mapping:           Internal:
{"code":"0",...}      gRPC codes         codes.InvalidArgument
{"code":"3",...}   →  to strings    ←   codes.NotFound
{"code":"5",...}      "0"-"16"           codes.AlreadyExists
```

---

## LỢI ÍCH CỦA KIẾN TRÚC NÀY

1. **Separation of Concerns**
   - Services chỉ lo logic, dùng gRPC thuần
   - Gateway lo format response cho client

2. **Flexibility**
   - Thay đổi API format không cần sửa services
   - Dễ add thêm protocols (GraphQL, WebSocket)

3. **Maintainability**
   - Services đơn giản, chuẩn gRPC
   - Centralized error handling ở Gateway

4. **Scalability**
   - Gateway có thể scale độc lập
   - Services có thể scale theo nhu cầu

5. **Standards Compliance**
   - Internal: Chuẩn gRPC với status codes
   - External: Custom format theo yêu cầu mentor

---

## NEXT STEPS

1. **Refactor User Service** (QUAN TRỌNG)
   - Sửa user_server.go theo pattern của Article Service
   - Test lại tất cả endpoints

2. **Testing**
   - Test Gateway với cả 2 services
   - Test error scenarios
   - Test inter-service communication

3. **Docker Compose**
   - Add Gateway vào docker-compose.yml
   - Config networking

4. **Documentation**
   - Update README.md
   - Create Postman collection
   - Write deployment guide
