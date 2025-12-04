# API Gateway Service

API Gateway cung cấp HTTP REST API interface cho các gRPC microservices (User Service và Article Service).

## Chức năng

- **HTTP → gRPC Conversion**: Nhận HTTP REST requests từ client, convert sang gRPC calls
- **Response Formatting**: Format gRPC responses theo chuẩn mentor yêu cầu với codes "0"-"16"
- **Error Handling**: Convert gRPC status codes sang API response format chuẩn
- **CORS Support**: Enable CORS cho development
- **Request Logging**: Log tất cả incoming requests

## Response Format

Tất cả API responses theo format:

### Success Response
```json
{
  "code": "0",
  "message": "success",
  "data": {
    ...
  }
}
```

### List Response
```json
{
  "code": "0",
  "message": "success",
  "data": {
    "items": [...],
    "total": 66,
    "page": 1,
    "size": 10,
    "has_more": true
  }
}
```

### Error Response
```json
{
  "code": "3",
  "message": "invalid argument"
}
```

## Response Codes (gRPC Standard)

| Code | gRPC Status | HTTP Status | Description |
|------|-------------|-------------|-------------|
| 000 | OK | 200 | Success |
| 001 | CANCELLED | 499 | Request cancelled |
| 002 | UNKNOWN | 500 | Unknown error |
| 003 | INVALID_ARGUMENT | 400 | Invalid argument |
| 004 | DEADLINE_EXCEEDED | 504 | Request timeout |
| 005 | NOT_FOUND | 404 | Resource not found |
| 006 | ALREADY_EXISTS | 409 | Resource already exists |
| 007 | PERMISSION_DENIED | 403 | Permission denied |
| 013 | INTERNAL | 500 | Internal server error |
| 014 | UNAVAILABLE | 503 | Service unavailable |
| 016 | UNAUTHENTICATED | 401 | Authentication required |

## Environment Variables

```env
USER_SERVICE_ADDR=localhost:50051      # User Service gRPC address
ARTICLE_SERVICE_ADDR=localhost:50052   # Article Service gRPC address
GATEWAY_PORT=8080                      # Gateway HTTP port
```

## Build & Run

### Local Development

```bash
cd service-gateway
go build -o bin/gateway cmd/server/main.go
./bin/gateway
```

### Docker

```bash
docker build -t agrios-gateway .
docker run -p 8080:8080 \
  -e USER_SERVICE_ADDR=user-service:50051 \
  -e ARTICLE_SERVICE_ADDR=article-service:50052 \
  agrios-gateway
```

## API Endpoints

### User APIs

#### Create User
```bash
POST /api/v1/users
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123"
}

# Response
{
  "code": "0",
  "message": "success",
  "data": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "created_at": "2025-12-04T10:00:00Z",
    "updated_at": "2025-12-04T10:00:00Z"
  }
}
```

#### Get User
```bash
GET /api/v1/users/{id}

# Response
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

#### List Users
```bash
GET /api/v1/users?page=1&page_size=10

# Response
{
  "code": "0",
  "message": "success",
  "data": {
    "items": [...],
    "total": 66,
    "page": 1,
    "size": 10,
    "has_more": true
  }
}
```

#### Update User
```bash
PUT /api/v1/users/{id}
Content-Type: application/json

{
  "name": "John Updated",
  "email": "john.updated@example.com"
}
```

#### Delete User
```bash
DELETE /api/v1/users/{id}

# Response
{
  "code": "0",
  "message": "success",
  "data": {
    "success": true
  }
}
```

### Auth APIs

#### Login
```bash
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "password123"
}

# Response
{
  "code": "0",
  "message": "success",
  "data": {
    "access_token": "eyJhbGc...",
    "refresh_token": "eyJhbGc...",
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com"
    }
  }
}
```

#### Validate Token
```bash
POST /api/v1/auth/validate
Content-Type: application/json

{
  "token": "eyJhbGc..."
}

# Response
{
  "code": "0",
  "message": "success",
  "data": {
    "valid": true,
    "user_id": 1,
    "email": "john@example.com"
  }
}
```

#### Logout
```bash
POST /api/v1/auth/logout
Content-Type: application/json

{
  "token": "eyJhbGc..."
}

# Response
{
  "code": "0",
  "message": "success",
  "data": {
    "success": true
  }
}
```

### Article APIs

#### Create Article
```bash
POST /api/v1/articles
Content-Type: application/json

{
  "title": "My Article",
  "content": "Article content here...",
  "user_id": 1
}

# Response
{
  "code": "0",
  "message": "success",
  "data": {
    "id": 1,
    "title": "My Article",
    "content": "Article content here...",
    "user_id": 1,
    "created_at": "2025-12-04T10:00:00Z",
    "updated_at": "2025-12-04T10:00:00Z"
  }
}
```

#### Get Article
```bash
GET /api/v1/articles/{id}

# Response (with user info)
{
  "code": "0",
  "message": "success",
  "data": {
    "id": 1,
    "title": "My Article",
    "content": "Article content here...",
    "user_id": 1,
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com"
    }
  }
}
```

#### List Articles
```bash
GET /api/v1/articles?page=1&page_size=10&user_id=1

# Response
{
  "code": "0",
  "message": "success",
  "data": {
    "items": [
      {
        "id": 1,
        "title": "Article 1",
        "user": {
          "id": 1,
          "name": "John Doe"
        }
      }
    ],
    "total": 5,
    "page": 1,
    "size": 10,
    "has_more": false
  }
}
```

#### Update Article
```bash
PUT /api/v1/articles/{id}
Content-Type: application/json

{
  "title": "Updated Title",
  "content": "Updated content"
}
```

#### Delete Article
```bash
DELETE /api/v1/articles/{id}

# Response
{
  "code": "0",
  "message": "success",
  "data": {
    "id": 1,
    "title": "Deleted Article"
  }
}
```

## Testing với curl

```bash
# Create user
curl -X POST http://localhost:8080/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","password":"password123"}'

# Login
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Get user
curl http://localhost:8080/api/v1/users/1

# List users
curl "http://localhost:8080/api/v1/users?page=1&page_size=10"

# Create article
curl -X POST http://localhost:8080/api/v1/articles \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Article","content":"Content here","user_id":1}'

# List articles
curl "http://localhost:8080/api/v1/articles?page=1&page_size=10"
```

## Error Examples

### Invalid Argument (code "3")
```json
{
  "code": "3",
  "message": "email is required"
}
```

### Not Found (code "5")
```json
{
  "code": "5",
  "message": "user not found"
}
```

### Already Exists (code "6")
```json
{
  "code": "6",
  "message": "user with this email already exists"
}
```

### Unauthenticated (code "16")
```json
{
  "code": "16",
  "message": "invalid email or password"
}
```

### Internal Error (code "13")
```json
{
  "code": "13",
  "message": "internal server error"
}
```

## Architecture

```
┌─────────────┐
│   Client    │ ← HTTP REST (port 8080)
│  (Browser)  │   Format: {"code":"0", "message":"success", "data":{}}
└──────┬──────┘
       │
       ↓
┌─────────────────────────┐
│    API Gateway          │
│  (HTTP → gRPC)          │
│   Port: 8080            │
│                         │
│  - Response Wrapper     │
│  - Error Mapping        │
│  - CORS, Logging        │
└──┬──────────────────┬───┘
   │ gRPC (pure)      │ gRPC (pure)
   ↓                  ↓
┌──────────┐    ┌─────────────┐
│  User    │←───┤  Article    │
│ Service  │    │  Service    │
│  :50051  │    │   :50052    │
└──────────┘    └─────────────┘
```

## Development Notes

### Response Wrapper Logic

File: `internal/response/wrapper.go`

- `MapGRPCCodeToString()`: Convert gRPC codes.Code → string "0"-"16"
- `MapGRPCCodeToHTTPStatus()`: Convert gRPC codes → HTTP status codes
- `Error()`: Main function để convert gRPC errors sang API format

### Handler Pattern

Files: `internal/handler/*_handler.go`

1. Parse HTTP request body
2. Call gRPC service
3. Handle gRPC errors với `response.Error()`
4. Format success response với `response.Success()` hoặc `response.SuccessList()`

### Middleware

- `loggingMiddleware`: Log tất cả requests
- `corsMiddleware`: Enable CORS cho development

## Production Considerations

1. **Authentication**: Thêm JWT middleware cho protected routes
2. **Rate Limiting**: Implement rate limiting
3. **Circuit Breaker**: Add circuit breaker cho gRPC calls
4. **Metrics**: Add Prometheus metrics
5. **Tracing**: Implement distributed tracing
6. **TLS**: Enable TLS cho production
