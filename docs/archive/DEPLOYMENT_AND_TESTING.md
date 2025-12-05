# Deployment and Testing Guide

## Table of Contents
1. [Docker Deployment](#docker-deployment)
2. [Local Development Deployment](#local-development-deployment)
3. [API Testing Examples](#api-testing-examples)
4. [Common Issues](#common-issues)

---

## Docker Deployment

### Advantages of Docker Deployment
- ✅ **One-command startup**: Chỉ cần `docker-compose up` là chạy tất cả services
- ✅ **Isolated environment**: Mỗi service chạy trong container riêng biệt
- ✅ **Easy cleanup**: `docker-compose down` để tắt và xóa toàn bộ
- ✅ **Production-ready**: Môi trường giống production
- ✅ **No dependency conflicts**: Không xung đột với các ứng dụng khác trên máy

### Prerequisites
```bash
# Check Docker installed
docker --version
docker-compose --version
```

### Step 1: Build Docker Images

```bash
# Navigate to project root
cd d:/agrios

# Build User Service image
docker build -t agrios-user-service:latest -f service-1-user/Dockerfile service-1-user/

# Build Article Service image
docker build -t agrios-article-service:latest -f service-2-article/Dockerfile service-2-article/

# Build Gateway Service image
docker build -t agrios-gateway:latest -f service-gateway/Dockerfile service-gateway/

# Verify images created
docker images | grep agrios
```

### Step 2: Create Docker Compose File

Create `docker-compose.yml` at project root:

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: agrios-postgres
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./scripts/init-databases.sh:/docker-entrypoint-initdb.d/init-databases.sh
    networks:
      - agrios-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: agrios-redis
    ports:
      - "6379:6379"
    networks:
      - agrios-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  user-service:
    image: agrios-user-service:latest
    container_name: agrios-user-service
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    environment:
      DB_HOST: postgres
      DB_PORT: 5432
      DB_USER: postgres
      DB_PASSWORD: postgres
      DB_NAME: agrios_users
      REDIS_ADDR: redis:6379
      REDIS_PASSWORD: ""
      REDIS_DB: 0
      JWT_SECRET: JCnk0Rlhh23uuDAunpeDtW2uHUqKF//jNBwNDM0KxtE=
      ACCESS_TOKEN_DURATION: 15m
      REFRESH_TOKEN_DURATION: 168h
      GRPC_PORT: 50051
    ports:
      - "50051:50051"
    networks:
      - agrios-network
    restart: unless-stopped

  article-service:
    image: agrios-article-service:latest
    container_name: agrios-article-service
    depends_on:
      postgres:
        condition: service_healthy
      user-service:
        condition: service_started
    environment:
      DB_HOST: postgres
      DB_PORT: 5432
      DB_USER: postgres
      DB_PASSWORD: postgres
      DB_NAME: agrios_articles
      USER_SERVICE_ADDR: user-service:50051
      GRPC_PORT: 50052
    ports:
      - "50052:50052"
    networks:
      - agrios-network
    restart: unless-stopped

  gateway:
    image: agrios-gateway:latest
    container_name: agrios-gateway
    depends_on:
      - user-service
      - article-service
    environment:
      USER_SERVICE_ADDR: user-service:50051
      ARTICLE_SERVICE_ADDR: article-service:50052
      GATEWAY_PORT: 8080
    ports:
      - "8080:8080"
    networks:
      - agrios-network
    restart: unless-stopped

networks:
  agrios-network:
    driver: bridge

volumes:
  postgres_data:
```

### Step 3: Start All Services

```bash
# Start all services in background
docker-compose up -d

# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f gateway
docker-compose logs -f user-service
docker-compose logs -f article-service

# Check service status
docker-compose ps
```

### Step 4: Run Database Migrations

```bash
# Run migrations for User Service
docker exec -i agrios-postgres psql -U postgres -d agrios_users < service-1-user/migrations/001_create_users_table.sql

# Run migrations for Article Service
docker exec -i agrios-postgres psql -U postgres -d agrios_articles < service-2-article/migrations/001_create_articles_table.sql

# Verify tables created
docker exec -it agrios-postgres psql -U postgres -d agrios_users -c "\dt"
docker exec -it agrios-postgres psql -U postgres -d agrios_articles -c "\dt"
```

### Step 5: Test Health Check

```bash
curl http://localhost:8080/health
# Expected: {"status":"healthy"}
```

### Stop Services

```bash
# Stop all services
docker-compose stop

# Stop and remove containers
docker-compose down

# Stop and remove everything (including volumes)
docker-compose down -v
```

### Restart Services

```bash
# Restart all services
docker-compose restart

# Restart specific service
docker-compose restart gateway
```

---

## Local Development Deployment

### Advantages of Local Deployment
- ✅ **Fast iteration**: Không cần rebuild Docker image
- ✅ **Easy debugging**: Có thể dùng debugger trực tiếp
- ✅ **Hot reload**: Dùng `air` hoặc restart nhanh
- ✅ **Lower resource usage**: Không cần Docker overhead

### Prerequisites

```bash
# Check Go installed
go version  # Should be 1.21+

# Install Air for hot reload (optional)
go install github.com/cosmtrek/air@latest
```

### Step 1: Start Infrastructure (Docker)

```bash
# Start only PostgreSQL and Redis
docker-compose up -d postgres redis

# Verify running
docker ps | grep -E "postgres|redis"
```

### Step 2: Setup Databases

```bash
# Create databases
docker exec -i agrios-postgres psql -U postgres -c "CREATE DATABASE agrios_users;"
docker exec -i agrios-postgres psql -U postgres -c "CREATE DATABASE agrios_articles;"

# Run migrations
docker exec -i agrios-postgres psql -U postgres -d agrios_users < service-1-user/migrations/001_create_users_table.sql
docker exec -i agrios-postgres psql -U postgres -d agrios_articles < service-2-article/migrations/001_create_articles_table.sql
```

### Step 3: Configure Environment Variables

**service-1-user/.env:**
```env
DB_HOST=127.0.0.1
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=agrios_users

JWT_SECRET=JCnk0Rlhh23uuDAunpeDtW2uHUqKF//jNBwNDM0KxtE=
ACCESS_TOKEN_DURATION=15m
REFRESH_TOKEN_DURATION=168h

REDIS_ADDR=localhost:6379
REDIS_PASSWORD=
REDIS_DB=0

GRPC_PORT=50051
```

**service-2-article/.env:**
```env
DB_HOST=127.0.0.1
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=agrios_articles

USER_SERVICE_ADDR=localhost:50051
GRPC_PORT=50052
```

**service-gateway/.env:**
```env
USER_SERVICE_ADDR=127.0.0.1:50051
ARTICLE_SERVICE_ADDR=127.0.0.1:50052
GATEWAY_PORT=8080
```

### Step 4: Start Services

**Terminal 1 - User Service:**
```bash
cd d:/agrios/service-1-user
go run cmd/server/main.go

# Or with hot reload:
air
```

**Terminal 2 - Article Service:**
```bash
cd d:/agrios/service-2-article
go run cmd/server/main.go

# Or with hot reload:
air
```

**Terminal 3 - Gateway:**
```bash
cd d:/agrios/service-gateway
go run cmd/server/main.go

# Or with hot reload:
air
```

### Step 5: Verify Services Running

```bash
# Check processes
ps aux | grep "go run"

# Test health
curl http://localhost:8080/health
```

### Stop Services

```bash
# In each terminal, press Ctrl+C

# Stop Docker infrastructure
docker-compose stop postgres redis
```

---

## API Testing Examples

### 1. Health Check

```bash
curl http://localhost:8080/health
```

**Expected Response:**
```json
{"status":"healthy"}
```

---

### 2. Create User

```bash
curl -X POST http://localhost:8080/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "securepass123"
  }'
```

**Expected Response:**
```json
{
  "code": "000",
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

---

### 3. Login

```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "securepass123"
  }'
```

**Expected Response:**
```json
{
  "code": "000",
  "message": "success",
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com"
    }
  }
}
```

**⚠️ Important:** Save the `access_token` for next requests!

---

### 4. Get User by ID

```bash
curl http://localhost:8080/api/v1/users/1
```

**Expected Response:**
```json
{
  "code": "000",
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

---

### 5. List Users (Pagination)

```bash
curl "http://localhost:8080/api/v1/users?page=1&page_size=10"
```

**Expected Response:**
```json
{
  "code": "000",
  "message": "success",
  "data": {
    "items": [
      {
        "id": 1,
        "name": "John Doe",
        "email": "john@example.com",
        "created_at": "2025-12-04T10:00:00Z",
        "updated_at": "2025-12-04T10:00:00Z"
      }
    ],
    "total": 1,
    "page": 1,
    "size": 10,
    "has_more": false
  }
}
```

---

### 6. Update User

```bash
curl -X PUT http://localhost:8080/api/v1/users/1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Updated",
    "email": "john.updated@example.com",
    "password": "newpass123"
  }'
```

**Expected Response:**
```json
{
  "code": "000",
  "message": "success",
  "data": {
    "id": 1,
    "name": "John Updated",
    "email": "john.updated@example.com",
    "created_at": "2025-12-04T10:00:00Z",
    "updated_at": "2025-12-04T10:05:00Z"
  }
}
```

---

### 7. Create Article (Requires Authentication)

**⚠️ Important:** Replace `<ACCESS_TOKEN>` with token from login response!

```bash
curl -X POST http://localhost:8080/api/v1/articles \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <ACCESS_TOKEN>" \
  -d '{
    "title": "My First Article",
    "content": "This is the content of my first article. It can be very long text with multiple paragraphs.",
    "user_id": 1
  }'
```

**Expected Response:**
```json
{
  "code": "000",
  "message": "success",
  "data": {
    "id": 1,
    "title": "My First Article",
    "content": "This is the content of my first article...",
    "user_id": 1,
    "created_at": "2025-12-04T10:10:00Z",
    "updated_at": "2025-12-04T10:10:00Z"
  }
}
```

**Error Response (No Token):**
```json
{
  "code": "016",
  "message": "authorization token required"
}
```

**Error Response (Invalid Token):**
```json
{
  "code": "016",
  "message": "authentication required"
}
```

---

### 8. Get Article by ID

```bash
curl http://localhost:8080/api/v1/articles/1
```

**Expected Response:**
```json
{
  "code": "000",
  "message": "success",
  "data": {
    "id": 1,
    "title": "My First Article",
    "content": "This is the content of my first article...",
    "user_id": 1,
    "created_at": "2025-12-04T10:10:00Z",
    "updated_at": "2025-12-04T10:10:00Z",
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "created_at": "2025-12-04T10:00:00Z",
      "updated_at": "2025-12-04T10:00:00Z"
    }
  }
}
```

**Note:** Response includes user information (joined data)

---

### 9. List Articles (Pagination)

```bash
# All articles
curl "http://localhost:8080/api/v1/articles?page=1&page_size=10"

# Articles by specific user
curl "http://localhost:8080/api/v1/articles?page=1&page_size=10&user_id=1"
```

**Expected Response:**
```json
{
  "code": "000",
  "message": "success",
  "data": {
    "items": [
      {
        "id": 1,
        "title": "My First Article",
        "content": "This is the content...",
        "user_id": 1,
        "created_at": "2025-12-04T10:10:00Z",
        "updated_at": "2025-12-04T10:10:00Z",
        "user": {
          "id": 1,
          "name": "John Doe",
          "email": "john@example.com"
        }
      }
    ],
    "total": 1,
    "page": 1,
    "page_size": 10
  }
}
```

---

### 10. Update Article

```bash
curl -X PUT http://localhost:8080/api/v1/articles/1 \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Updated Article Title",
    "content": "Updated content here..."
  }'
```

**Expected Response:**
```json
{
  "code": "000",
  "message": "success",
  "data": {
    "id": 1,
    "title": "Updated Article Title",
    "content": "Updated content here...",
    "user_id": 1,
    "created_at": "2025-12-04T10:10:00Z",
    "updated_at": "2025-12-04T10:15:00Z"
  }
}
```

---

### 11. Delete Article

```bash
curl -X DELETE http://localhost:8080/api/v1/articles/1
```

**Expected Response:**
```json
{
  "code": "000",
  "message": "success",
  "data": {
    "id": 1,
    "title": "Updated Article Title",
    "content": "Updated content here...",
    "user_id": 1,
    "created_at": "2025-12-04T10:10:00Z",
    "updated_at": "2025-12-04T10:15:00Z"
  }
}
```

---

### 12. Delete User

```bash
curl -X DELETE http://localhost:8080/api/v1/users/1
```

**Expected Response:**
```json
{
  "code": "000",
  "message": "success",
  "data": {
    "success": true
  }
}
```

---

### 13. Validate Token

```bash
curl -X POST http://localhost:8080/api/v1/auth/validate \
  -H "Content-Type: application/json" \
  -d '{
    "token": "<ACCESS_TOKEN>"
  }'
```

**Expected Response:**
```json
{
  "code": "000",
  "message": "success",
  "data": {
    "valid": true,
    "user_id": 1,
    "email": "john@example.com"
  }
}
```

---

### 14. Logout (Blacklist Token)

```bash
curl -X POST http://localhost:8080/api/v1/auth/logout \
  -H "Content-Type: application/json" \
  -d '{
    "token": "<ACCESS_TOKEN>"
  }'
```

**Expected Response:**
```json
{
  "code": "000",
  "message": "success",
  "data": {
    "success": true
  }
}
```

**After logout, the token is blacklisted in Redis and cannot be used anymore.**

---

## Complete Test Script

Save as `test-api.sh`:

```bash
#!/bin/bash

BASE_URL="http://localhost:8080"

echo "=== 1. Health Check ==="
curl -s $BASE_URL/health | jq
echo -e "\n"

echo "=== 2. Create User ==="
USER_RESPONSE=$(curl -s -X POST $BASE_URL/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","password":"pass123"}')
echo $USER_RESPONSE | jq
USER_ID=$(echo $USER_RESPONSE | jq -r '.data.id')
echo "User ID: $USER_ID"
echo -e "\n"

echo "=== 3. Login ==="
LOGIN_RESPONSE=$(curl -s -X POST $BASE_URL/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"pass123"}')
echo $LOGIN_RESPONSE | jq
ACCESS_TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.data.access_token')
echo "Access Token: ${ACCESS_TOKEN:0:50}..."
echo -e "\n"

echo "=== 4. Get User ==="
curl -s $BASE_URL/api/v1/users/$USER_ID | jq
echo -e "\n"

echo "=== 5. List Users ==="
curl -s "$BASE_URL/api/v1/users?page=1&page_size=10" | jq
echo -e "\n"

echo "=== 6. Create Article (with auth) ==="
ARTICLE_RESPONSE=$(curl -s -X POST $BASE_URL/api/v1/articles \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d "{\"title\":\"Test Article\",\"content\":\"Test content\",\"user_id\":$USER_ID}")
echo $ARTICLE_RESPONSE | jq
ARTICLE_ID=$(echo $ARTICLE_RESPONSE | jq -r '.data.id')
echo "Article ID: $ARTICLE_ID"
echo -e "\n"

echo "=== 7. Get Article ==="
curl -s $BASE_URL/api/v1/articles/$ARTICLE_ID | jq
echo -e "\n"

echo "=== 8. List Articles ==="
curl -s "$BASE_URL/api/v1/articles?page=1&page_size=10" | jq
echo -e "\n"

echo "=== 9. Update Article ==="
curl -s -X PUT $BASE_URL/api/v1/articles/$ARTICLE_ID \
  -H "Content-Type: application/json" \
  -d '{"title":"Updated Title","content":"Updated content"}' | jq
echo -e "\n"

echo "=== 10. Validate Token ==="
curl -s -X POST $BASE_URL/api/v1/auth/validate \
  -H "Content-Type: application/json" \
  -d "{\"token\":\"$ACCESS_TOKEN\"}" | jq
echo -e "\n"

echo "=== 11. Logout ==="
curl -s -X POST $BASE_URL/api/v1/auth/logout \
  -H "Content-Type: application/json" \
  -d "{\"token\":\"$ACCESS_TOKEN\"}" | jq
echo -e "\n"

echo "=== 12. Try using token after logout (should fail) ==="
curl -s -X POST $BASE_URL/api/v1/articles \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d "{\"title\":\"Should Fail\",\"content\":\"Test\",\"user_id\":$USER_ID}" | jq
echo -e "\n"

echo "=== Test Complete ==="
```

Run:
```bash
chmod +x test-api.sh
./test-api.sh
```

---

## Common Issues

### Issue 1: Connection Refused

**Error:**
```
curl: (7) Failed to connect to localhost port 8080: Connection refused
```

**Solution:**
```bash
# Check if Gateway is running
ps aux | grep gateway

# Check if services are up (Docker)
docker-compose ps

# Restart Gateway
docker-compose restart gateway
# Or (local)
cd service-gateway && go run cmd/server/main.go
```

---

### Issue 2: Database Connection Error

**Error:**
```
failed to connect to database: connection refused
```

**Solution:**
```bash
# Check PostgreSQL running
docker ps | grep postgres

# Check connection from host
psql -h localhost -U postgres -d agrios_users

# Restart PostgreSQL
docker-compose restart postgres
```

---

### Issue 3: Token Authentication Failed

**Error:**
```json
{"code":"016","message":"token has been revoked"}
```

**Solution:**
- Token was blacklisted after logout
- Login again to get new token
- Check Redis is running: `docker ps | grep redis`

---

### Issue 4: Article Creation Failed (No Token)

**Error:**
```json
{"code":"016","message":"authorization token required"}
```

**Solution:**
- Add Authorization header: `-H "Authorization: Bearer <TOKEN>"`
- Make sure to login first and copy access_token
- Token expires after 15 minutes - login again if expired

---

### Issue 5: User Service Unavailable

**Error:**
```json
{"code":"014","message":"user service is currently unavailable"}
```

**Solution:**
```bash
# Check User Service running
docker-compose ps user-service
# Or
ps aux | grep "github.com/thatlq1812/service-1-user"

# Check logs
docker-compose logs user-service

# Restart
docker-compose restart user-service
```

---

## Response Code Reference

| Code | Meaning | HTTP Status | Description |
|------|---------|-------------|-------------|
| 000 | OK | 200 | Request successful |
| 003 | INVALID_ARGUMENT | 400 | Invalid input / validation error |
| 005 | NOT_FOUND | 404 | Resource not found |
| 006 | ALREADY_EXISTS | 409 | Duplicate resource (email exists) |
| 007 | PERMISSION_DENIED | 403 | No permission |
| 013 | INTERNAL | 500 | Internal server error |
| 016 | UNAUTHENTICATED | 401 | Authentication required/failed |

---

## Docker vs Local Development Comparison

| Aspect | Docker | Local Development |
|--------|--------|-------------------|
| **Startup** | `docker-compose up -d` | Need 3 terminals + manual setup |
| **Stop** | `docker-compose down` | Ctrl+C in each terminal |
| **Rebuild** | Need rebuild image | Instant with hot reload |
| **Debugging** | Complex (need attach) | Easy (standard debugger) |
| **Resource** | Higher (containers) | Lower (native processes) |
| **Isolation** | Complete isolation | Share host network |
| **Production** | Same as production | Different environment |
| **Best For** | Testing, Demo, CI/CD | Active development |

---

## Tips and Best Practices

### 1. Use `jq` for JSON Formatting
```bash
# Install jq
brew install jq  # macOS
apt install jq   # Ubuntu

# Pretty print JSON
curl http://localhost:8080/api/v1/users | jq
```

### 2. Save Token to Variable
```bash
# Login and save token
TOKEN=$(curl -s -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"pass123"}' \
  | jq -r '.data.access_token')

# Use token in subsequent requests
curl -X POST http://localhost:8080/api/v1/articles \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test","content":"Content","user_id":1}'
```

### 3. Use Postman or Insomnia
- Import API collection
- Environment variables for token
- Better UI for testing

### 4. Monitor Logs
```bash
# Docker logs
docker-compose logs -f --tail=100

# Specific service
docker-compose logs -f gateway

# Local logs
# Services print to stdout
```

### 5. Database Inspection
```bash
# Connect to PostgreSQL
docker exec -it agrios-postgres psql -U postgres -d agrios_users

# Useful queries
SELECT * FROM users;
SELECT * FROM articles;

# Check Redis
docker exec -it agrios-redis redis-cli
> KEYS blacklist:*
> GET blacklist:<token>
```

---

## Quick Reference Commands

```bash
# === Docker Deployment ===
docker-compose up -d              # Start all services
docker-compose ps                 # Check status
docker-compose logs -f            # View logs
docker-compose restart gateway    # Restart service
docker-compose down               # Stop all services

# === Local Development ===
cd service-1-user && go run cmd/server/main.go    # Terminal 1
cd service-2-article && go run cmd/server/main.go # Terminal 2
cd service-gateway && go run cmd/server/main.go   # Terminal 3

# === Testing ===
curl http://localhost:8080/health                 # Health check
./test-api.sh                                     # Run full test suite

# === Database ===
docker exec -it agrios-postgres psql -U postgres -d agrios_users
docker exec -it agrios-redis redis-cli

# === Debugging ===
docker-compose logs user-service                  # View logs
docker exec -it agrios-user-service sh            # Shell into container
netstat -an | grep 8080                          # Check port
```

---

**Câu hỏi: "Nếu deploy lên Docker thì chỉ cần bật là dùng được nhỉ?"**

**Trả lời:** Đúng! Sau khi build images lần đầu, chỉ cần:
```bash
docker-compose up -d
```
Tất cả services (PostgreSQL, Redis, User Service, Article Service, Gateway) sẽ tự động start và ready to use trong vài giây. Không cần setup gì thêm!

Nếu có thay đổi code, cần rebuild image:
```bash
docker-compose down
docker-compose build
docker-compose up -d
```
