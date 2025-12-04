# Agrios Platform - Complete Guide

> **All-in-one documentation for the Agrios Microservices Platform**  
> Version: 2.0.0 | Last Updated: December 4, 2025

---

## 📖 Table of Contents

1. [System Overview](#1-system-overview)
2. [Architecture](#2-architecture)
3. [Quick Start with Docker](#3-quick-start-with-docker)
4. [Docker Commands Reference](#4-docker-commands-reference)
5. [API Documentation](#5-api-documentation)
6. [Testing with curl](#6-testing-with-curl)
7. [Testing with grpcurl](#7-testing-with-grpcurl)
8. [Development Guide](#8-development-guide)
9. [Operations & Monitoring](#9-operations--monitoring)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. System Overview

### What is Agrios?

Agrios is an enterprise-grade microservices platform featuring:
- **API Gateway** for HTTP REST API interface
- **User Service** for authentication and user management
- **Article Service** for content management
- **JWT-based authentication** with Redis blacklist
- **gRPC** for efficient inter-service communication

### Technology Stack

- **Language:** Go 1.21+
- **Communication:** gRPC (internal), REST (external)
- **Databases:** PostgreSQL 15, Redis 7
- **Container:** Docker & Docker Compose

### Key Features

- ✅ API Gateway pattern (REST → gRPC)
- ✅ JWT authentication with access/refresh tokens
- ✅ Token blacklisting with Redis
- ✅ **Standardized wrapped response format** (both REST and gRPC)
- ✅ Microservices architecture
- ✅ Docker containerization

### Response Format

**All API responses (both REST and gRPC) follow this standardized format:**

**Success Response:**
```json
{
  "code": "000",
  "message": "success",
  "data": {
    // Response-specific data here
  }
}
```

**Error Response:**
```json
{
  "code": "XXX",
  "message": "error description"
}
```

**Response Codes:**
- `000` - Success
- `003` - Invalid request / validation error
- `005` - Not found
- `006` - Already exists (duplicate)
- `007` - Permission denied
- `013` - Internal server error
- `014` - Authentication required
- `015` - Service unavailable
- `016` - Unauthorized

**Examples:**

```bash
# Success
curl http://localhost:8080/api/v1/users/1
{"code":"000","message":"success","data":{"id":1,"name":"John"}}

# Validation error
curl -X POST http://localhost:8080/api/v1/articles -d '{"content":"No title"}'
{"code":"003","message":"title is required"}

# Not found
curl http://localhost:8080/api/v1/articles/99999
{"code":"005","message":"article not found"}

# Authentication error
curl -X POST http://localhost:8080/api/v1/articles -d '{"title":"Test"}'
{"code":"014","message":"authentication required"}
```

> **Note:** This wrapped format applies to BOTH REST API and gRPC responses for consistency.

---

## 2. Architecture

### System Architecture

```
Client (Browser/Mobile/API Consumer)
         ↓
    HTTP REST API (port 8080)
    {"code":"000", "message":"success", "data":{}}
         ↓
┌────────────────────────────┐
│      API GATEWAY           │
│  service-gateway:8080      │
│                            │
│  Functions:                │
│  1. Receive HTTP REST      │
│  2. Convert to gRPC        │
│  3. Call User/Article      │
│  4. Format response        │
│  5. Map gRPC → API codes   │
└──┬──────────────────────┬──┘
   │                      │
   │ gRPC (Pure)         │ gRPC (Pure)
   │ port 50051          │ port 50052
   ↓                     ↓
┌──────────────┐    ┌─────────────────┐
│ User Service │◄───┤ Article Service │
│   :50051     │    │     :50052      │
│              │    │                 │
│ gRPC Server  │    │ gRPC Server     │
│ - JWT Auth   │    │ - CRUD          │
│ - User CRUD  │    │ - User Join     │
└──────┬───────┘    └────────┬────────┘
       │                     │
       ├─────────────────────┤
       │                     │
    ┌──▼───┐  ┌──────┐  ┌───▼────┐
    │Redis │  │Users │  │Articles│
    │:6379 │  │  DB  │  │   DB   │
    └──────┘  └──────┘  └────────┘
```

### Services

#### 1. API Gateway (service-gateway)
- **Port:** 8080
- **Protocol:** HTTP REST
- **Purpose:** External API interface
- **Features:**
  - HTTP to gRPC conversion
  - Response format mapping
  - JWT token forwarding
  - CORS handling

#### 2. User Service (service-1-user)
- **Port:** 50051
- **Protocol:** gRPC
- **Database:** agrios_users (PostgreSQL)
- **Cache:** Redis (token blacklist)
- **Features:**
  - User registration/login
  - JWT token generation
  - Token validation/revocation
  - User CRUD operations

#### 3. Article Service (service-2-article)
- **Port:** 50052
- **Protocol:** gRPC
- **Database:** agrios_articles (PostgreSQL)
- **Features:**
  - Article CRUD operations
  - User service integration
  - JWT authentication required
  - Graceful degradation

### Response Format

All API responses follow this standardized format:

```json
{
  "code": "000",           // String code: "000"-"016"
  "message": "success",    // Human-readable message
  "data": {                // Response payload (optional)
    "id": 1,
    "name": "John Doe"
  }
}
```

### Response Codes

| Code | gRPC Status | HTTP Status | Description |
|------|-------------|-------------|-------------|
| 000 | OK | 200 | Success |
| 001 | CANCELLED | 499 | Request cancelled |
| 002 | UNKNOWN | 500 | Unknown error |
| 003 | INVALID_ARGUMENT | 400 | Invalid input/validation error |
| 004 | DEADLINE_EXCEEDED | 504 | Timeout |
| 005 | NOT_FOUND | 404 | Resource not found |
| 006 | ALREADY_EXISTS | 409 | Duplicate resource |
| 007 | PERMISSION_DENIED | 403 | No permission |
| 008 | RESOURCE_EXHAUSTED | 429 | Rate limit exceeded |
| 009 | FAILED_PRECONDITION | 400 | Precondition failed |
| 010 | ABORTED | 409 | Operation aborted |
| 011 | OUT_OF_RANGE | 400 | Out of range |
| 012 | UNIMPLEMENTED | 501 | Not implemented |
| 013 | INTERNAL | 500 | Internal server error |
| 014 | UNAVAILABLE | 503 | Service unavailable |
| 015 | DATA_LOSS | 500 | Data loss |
| 016 | UNAUTHENTICATED | 401 | Authentication required |

### Token Management

- **Access Token:**
  - Duration: 15 minutes
  - Purpose: API authentication
  - Format: JWT (HS256)
  
- **Refresh Token:**
  - Duration: 7 days (168 hours)
  - Purpose: Get new access tokens
  - Format: JWT (HS256)

- **Blacklist:**
  - Storage: Redis
  - Key format: `blacklist:<token>`
  - TTL: Token's remaining lifetime

---

## 3. Quick Start with Docker

### Prerequisites

**Required:**
- Docker version 20.10+ 
- Docker Compose version 2.0+

**Check installed versions:**
```bash
docker --version
# Expected: Docker version 20.10.x or higher

docker-compose --version
# Expected: Docker Compose version v2.x.x or higher
```

**Optional (for testing):**
- curl (HTTP API testing)
- grpcurl (gRPC testing)
- jq (JSON formatting)

---

### Step-by-Step Deployment

#### Step 1: Clone & Navigate to Project

```bash
# Clone repository (if not already done)
git clone https://github.com/thatlq1812/agrios.git

# Navigate to project root
cd agrios

# Or if already cloned
cd d:/agrios
```

#### Step 2: Start All Services

```bash
# Start all services in background mode (-d = detached)
docker-compose up -d

# Expected output:
# [+] Running 6/6
#  ✔ Container agrios-postgres         Started
#  ✔ Container agrios-redis            Started  
#  ✔ Container agrios-user-service     Started
#  ✔ Container agrios-article-service  Started
#  ✔ Container agrios-gateway          Started
#  ✔ Container agrios-pgadmin          Started
```

#### Step 3: Verify Services are Running

```bash
# Check all containers status
docker-compose ps

# Expected output (all STATUS should be "Up" or "healthy"):
# NAME                     STATUS
# agrios-postgres          Up (healthy)
# agrios-redis             Up (healthy)
# agrios-user-service      Up (healthy)
# agrios-article-service   Up (healthy)
# agrios-gateway           Up (healthy)
# agrios-pgadmin           Up
```

#### Step 4: Run Database Migrations

```bash
# Create tables for user service
docker exec -i agrios-postgres psql -U postgres -d agrios_users < service-1-user/migrations/001_create_users_table.sql

# Create tables for article service
docker exec -i agrios-postgres psql -U postgres -d agrios_articles < service-2-article/migrations/001_create_articles_table.sql

# Expected output:
# CREATE TABLE
# CREATE INDEX
```

#### Step 5: Test Health Check

```bash
# Test gateway health endpoint
curl http://localhost:8080/health

# Expected response:
# {"status":"healthy"}
```

**🎉 Congratulations! All services are now running!**

---

### Quick Test Flow

```bash
# 1. Create a user
curl -X POST http://localhost:8080/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","password":"pass123"}'

# Expected: {"code":"000","message":"success","data":{...}}

# 2. Login to get token
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"pass123"}'

# Expected: {"code":"000","message":"success","data":{"access_token":"...","refresh_token":"..."}}

# 3. Save the access_token from response above, then create article
TOKEN="<your_access_token_here>"

curl -X POST http://localhost:8080/api/v1/articles \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"My Article","content":"Article content","user_id":1}'

# Expected: {"code":"000","message":"success","data":{...}}
```

---

## 4. Docker Commands Reference

### Basic Commands

#### Starting Services

```bash
# Start all services in background
docker-compose up -d

# Start specific service
docker-compose up -d gateway

# Start with rebuild (after code changes)
docker-compose up -d --build

# Start and follow logs
docker-compose up

# Start specific services only
docker-compose up -d postgres redis
```

#### Stopping Services

```bash
# Stop all services (containers still exist)
docker-compose stop

# Stop specific service
docker-compose stop gateway

# Stop and remove containers
docker-compose down

# Stop and remove containers + volumes (⚠️ deletes all data!)
docker-compose down -v

# Stop and remove containers + images
docker-compose down --rmi all
```

#### Restarting Services

```bash
# Restart all services
docker-compose restart

# Restart specific service
docker-compose restart gateway

# Restart with rebuild
docker-compose up -d --build gateway
```

---

### Viewing Logs

```bash
# View all logs (follow mode)
docker-compose logs -f

# View logs of specific service
docker-compose logs -f gateway
docker-compose logs -f user-service
docker-compose logs -f article-service

# View last 50 lines
docker-compose logs --tail=50 gateway

# View logs since 10 minutes ago
docker-compose logs --since 10m gateway

# View logs without follow mode (one-time output)
docker-compose logs gateway
```

---

### Checking Status

```bash
# Check status of all containers
docker-compose ps

# More detailed container info
docker ps

# Check specific container
docker ps | grep gateway

# View resource usage (CPU, Memory)
docker stats

# View specific container stats
docker stats agrios-gateway
```

---

### Building Images

```bash
# Build all images
docker-compose build

# Build specific service
docker-compose build gateway

# Build without cache (clean build)
docker-compose build --no-cache

# Build with specific dockerfile
docker build -t agrios-gateway -f service-gateway/Dockerfile .
```

---

### Executing Commands in Containers

```bash
# Execute command in running container
docker exec -it agrios-postgres psql -U postgres

# Run bash shell in container
docker exec -it agrios-gateway sh

# Run command without interactive mode
docker exec agrios-postgres psql -U postgres -c "SELECT * FROM users;"

# Copy files from container
docker cp agrios-postgres:/var/lib/postgresql/data/backup.sql ./backup.sql

# Copy files to container
docker cp ./config.json agrios-gateway:/app/config.json
```

---

### Database Operations

```bash
# Connect to PostgreSQL
docker exec -it agrios-postgres psql -U postgres

# Connect to specific database
docker exec -it agrios-postgres psql -U postgres -d agrios_users

# Execute SQL file
docker exec -i agrios-postgres psql -U postgres -d agrios_users < migration.sql

# Backup database
docker exec agrios-postgres pg_dump -U postgres agrios_users > backup.sql

# Restore database
docker exec -i agrios-postgres psql -U postgres -d agrios_users < backup.sql

# List all databases
docker exec -it agrios-postgres psql -U postgres -c "\l"

# List tables in database
docker exec -it agrios-postgres psql -U postgres -d agrios_users -c "\dt"
```

---

### Redis Operations

```bash
# Connect to Redis CLI
docker exec -it agrios-redis redis-cli

# Check blacklisted tokens
docker exec -it agrios-redis redis-cli KEYS "blacklist:*"

# Get specific key
docker exec -it agrios-redis redis-cli GET "blacklist:token123"

# Flush all Redis data (⚠️ deletes everything!)
docker exec -it agrios-redis redis-cli FLUSHALL
```

---

### Inspecting Containers

```bash
# View container details (JSON format)
docker inspect agrios-gateway

# View container IP address
docker inspect agrios-gateway | grep IPAddress

# View container environment variables
docker inspect agrios-gateway | grep -A 20 Env

# View container logs location
docker inspect agrios-gateway | grep LogPath
```

---

### Cleaning Up

```bash
# Remove stopped containers
docker-compose rm

# Remove all unused containers, networks, images
docker system prune

# Remove all including volumes (⚠️ deletes data!)
docker system prune -a --volumes

# Remove specific container
docker rm agrios-gateway

# Remove specific image
docker rmi agrios-gateway

# View disk usage
docker system df
```

---

### Network Operations

```bash
# List networks
docker network ls

# Inspect network
docker network inspect agrios-network

# Check which containers are in network
docker network inspect agrios-network | grep Name
```

---

### Troubleshooting Commands

```bash
# Check why container failed to start
docker-compose logs gateway

# View real-time container events
docker events

# Check container health
docker inspect --format='{{.State.Health.Status}}' agrios-gateway

# Test network connectivity between containers
docker exec agrios-gateway ping agrios-postgres

# Check port mapping
docker port agrios-gateway
```

---

### Advanced: Docker Compose Profiles

```bash
# Run only development services
docker-compose --profile dev up -d

# Run with specific environment file
docker-compose --env-file .env.prod up -d

# Override configuration
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

---

## 5. API Documentation

### Base URL

```
http://localhost:8080/api/v1
```

### Authentication

Most endpoints require JWT authentication via `Authorization` header:

```
Authorization: Bearer <access_token>
```

### Response Format

All API responses follow this standardized format:

```json
{
  "code": "000",           // String code: "000" = success, "001"-"016" = errors
  "message": "success",    // Human-readable message
  "data": {                // Response payload (optional, null on errors)
    "id": 1,
    "name": "John Doe"
  }
}
```

### Response Codes

| Code | gRPC Status | HTTP Status | Description |
|------|-------------|-------------|-------------|
| 000 | OK | 200 | Success |
| 001 | CANCELLED | 499 | Request cancelled by client |
| 002 | UNKNOWN | 500 | Unknown error |
| 003 | INVALID_ARGUMENT | 400 | Invalid input/validation error |
| 004 | DEADLINE_EXCEEDED | 504 | Request timeout |
| 005 | NOT_FOUND | 404 | Resource not found |
| 006 | ALREADY_EXISTS | 409 | Duplicate resource (e.g., email exists) |
| 007 | PERMISSION_DENIED | 403 | No permission to access |
| 008 | RESOURCE_EXHAUSTED | 429 | Rate limit exceeded |
| 009 | FAILED_PRECONDITION | 400 | Precondition not met |
| 010 | ABORTED | 409 | Operation aborted |
| 011 | OUT_OF_RANGE | 400 | Value out of range |
| 012 | UNIMPLEMENTED | 501 | Feature not implemented |
| 013 | INTERNAL | 500 | Internal server error |
| 014 | UNAVAILABLE | 503 | Service temporarily unavailable |
| 015 | DATA_LOSS | 500 | Unrecoverable data loss |
| 016 | UNAUTHENTICATED | 401 | Authentication required/failed |

---

### User APIs

#### 1. Create User

```bash
POST /api/v1/users
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "securepass123"
}
```

**Response:**
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

#### 2. Login

```bash
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "securepass123"
}
```

**Response:**
```json
{
  "code": "000",
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

#### 3. Get User

```bash
GET /api/v1/users/{id}
```

**Response:**
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

#### 4. Update User

```bash
PUT /api/v1/users/{id}
Content-Type: application/json

{
  "name": "John Updated",
  "email": "john.new@example.com",
  "password": "newpass123"
}
```

#### 5. Delete User

```bash
DELETE /api/v1/users/{id}
```

**Response:**
```json
{
  "code": "000",
  "message": "success",
  "data": {
    "success": true
  }
}
```

#### 6. List Users

```bash
GET /api/v1/users?page=1&page_size=10
```

**Response:**
```json
{
  "code": "000",
  "message": "success",
  "data": {
    "items": [...],
    "total": 10,
    "page": 1,
    "size": 10,
    "has_more": false
  }
}
```

#### 7. Validate Token

```bash
POST /api/v1/auth/validate
Content-Type: application/json

{
  "token": "<access_token>"
}
```

**Response:**
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

#### 8. Logout

```bash
POST /api/v1/auth/logout
Content-Type: application/json

{
  "token": "<access_token>"
}
```

**Response:**
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

### Article APIs

**⚠️ All article endpoints require authentication via `Authorization: Bearer <token>` header**

#### 1. Create Article

```bash
POST /api/v1/articles
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "title": "My First Article",
  "content": "This is the article content...",
  "user_id": 1
}
```

**Response:**
```json
{
  "code": "000",
  "message": "success",
  "data": {
    "id": 1,
    "title": "My First Article",
    "content": "This is the article content...",
    "user_id": 1,
    "created_at": "2025-12-04T10:00:00Z",
    "updated_at": "2025-12-04T10:00:00Z"
  }
}
```

#### 2. Get Article

```bash
GET /api/v1/articles/{id}
```

**Response:**
```json
{
  "code": "000",
  "message": "success",
  "data": {
    "id": 1,
    "title": "My First Article",
    "content": "This is the article content...",
    "user_id": 1,
    "created_at": "2025-12-04T10:00:00Z",
    "updated_at": "2025-12-04T10:00:00Z",
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "created_at": "2025-12-04T09:00:00Z",
      "updated_at": "2025-12-04T09:00:00Z"
    }
  }
}
```

#### 3. Update Article

```bash
PUT /api/v1/articles/{id}
Content-Type: application/json

{
  "title": "Updated Title",
  "content": "Updated content..."
}
```

#### 4. Delete Article

```bash
DELETE /api/v1/articles/{id}
```

#### 5. List Articles

```bash
GET /api/v1/articles?page=1&page_size=10&user_id=1
```

**Response:**
```json
{
  "code": "000",
  "message": "success",
  "data": {
    "items": [
      {
        "id": 1,
        "title": "Article 1",
        "content": "Content...",
        "user_id": 1,
        "user": {...}
      }
    ],
    "total": 5,
    "page": 1,
    "page_size": 10
  }
}
```

---

## 8. Development Guide

### Project Structure

```
agrios/
├── service-1-user/
│   ├── cmd/server/main.go          # Entry point
│   ├── internal/
│   │   ├── auth/jwt.go             # JWT token manager
│   │   ├── config/config.go        # Configuration
│   │   ├── db/                     # Database connections
│   │   ├── repository/             # Data access layer
│   │   └── server/user_server.go   # gRPC handlers
│   ├── proto/                      # Protocol buffers
│   ├── migrations/                 # Database migrations
│   └── .env                        # Environment config
│
├── service-2-article/
│   ├── cmd/server/main.go
│   ├── internal/
│   │   ├── auth/auth.go            # JWT validation
│   │   ├── client/user_client.go   # User service client
│   │   ├── config/config.go
│   │   ├── db/
│   │   ├── repository/
│   │   └── server/article_server.go
│   ├── proto/
│   ├── migrations/
│   └── .env
│
├── service-gateway/
│   ├── cmd/server/main.go
│   ├── internal/
│   │   ├── handler/                # HTTP handlers
│   │   │   ├── user_handler.go
│   │   │   └── article_handler.go
│   │   └── response/wrapper.go     # Response formatter
│   └── .env
│
├── pkg/common/                     # Shared utilities
├── docs/                           # Documentation
└── docker-compose.yml
```

### Environment Configuration

#### service-1-user/.env

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

#### service-2-article/.env

```env
DB_HOST=127.0.0.1
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=agrios_articles

USER_SERVICE_ADDR=localhost:50051
GRPC_PORT=50052
```

#### service-gateway/.env

```env
USER_SERVICE_ADDR=127.0.0.1:50051
ARTICLE_SERVICE_ADDR=127.0.0.1:50052
GATEWAY_PORT=8080
```

### Adding a New Endpoint

#### 1. Define Protocol Buffer

```protobuf
// In proto/user_service.proto
message NewFeatureRequest {
  string param = 1;
}

message NewFeatureResponse {
  bool success = 1;
  string message = 2;
}

service UserService {
  rpc NewFeature(NewFeatureRequest) returns (NewFeatureResponse);
}
```

#### 2. Generate Code

```bash
cd service-1-user
protoc --go_out=. --go-grpc_out=. proto/user_service.proto
```

#### 3. Implement gRPC Handler

```go
// In internal/server/user_server.go
func (s *userServiceServer) NewFeature(ctx context.Context, req *pb.NewFeatureRequest) (*pb.NewFeatureResponse, error) {
    if req.Param == "" {
        return nil, status.Error(codes.InvalidArgument, "param is required")
    }
    
    // Implementation...
    
    return &pb.NewFeatureResponse{
        Success: true,
        Message: "Feature executed successfully",
    }, nil
}
```

#### 4. Add Gateway Handler

```go
// In service-gateway/internal/handler/user_handler.go
func (h *UserHandler) NewFeature(w http.ResponseWriter, r *http.Request) {
    var req NewFeatureRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        response.BadRequest(w, "invalid request body")
        return
    }
    
    resp, err := h.userClient.NewFeature(context.Background(), &userpb.NewFeatureRequest{
        Param: req.Param,
    })
    
    if err != nil {
        response.Error(w, err)
        return
    }
    
    response.Success(w, map[string]interface{}{
        "success": resp.Success,
        "message": resp.Message,
    })
}
```

#### 5. Register Route

```go
// In service-gateway/cmd/server/main.go
api.HandleFunc("/feature/new", userHandler.NewFeature).Methods("POST")
```

---

## 6. Testing with curl

### What is curl?

curl is a command-line tool for transferring data with URLs. It's perfect for testing REST APIs.

**Installation:**
- Windows: Included in Windows 10+ or download from https://curl.se/
- Linux: `sudo apt install curl`
- Mac: Pre-installed

**Basic curl syntax:**
```bash
curl [options] [URL]
```

**Common curl options:**
- `-X METHOD`: HTTP method (GET, POST, PUT, DELETE)
- `-H "Header"`: Add custom header
- `-d 'data'`: Send data in request body
- `-v`: Verbose mode (show request/response details)
- `-i`: Include response headers
- `-s`: Silent mode (no progress bar)
- `-w "\n"`: Add newline at end

---

### Quick curl Examples

#### 1. Simple GET Request

```bash
# Basic GET
curl http://localhost:8080/health

# GET with verbose output
curl -v http://localhost:8080/health

# GET and show HTTP status code
curl -w "\nHTTP Status: %{http_code}\n" http://localhost:8080/health
```

#### 2. POST Request with JSON

```bash
# Basic POST
curl -X POST http://localhost:8080/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John","email":"john@example.com","password":"pass123"}'

# POST with formatted JSON (multi-line)
curl -X POST http://localhost:8080/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "securepass123"
  }'

# POST with JSON file
curl -X POST http://localhost:8080/api/v1/users \
  -H "Content-Type: application/json" \
  -d @user.json
```

#### 3. Authenticated Request (with Token)

```bash
# Set token as variable
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# Use token in request
curl -X POST http://localhost:8080/api/v1/articles \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"My Article","content":"Content","user_id":1}'
```

#### 4. PUT Request (Update)

```bash
curl -X PUT http://localhost:8080/api/v1/users/1 \
  -H "Content-Type: application/json" \
  -d '{"name":"Updated Name","email":"updated@example.com"}'
```

#### 5. DELETE Request

```bash
curl -X DELETE http://localhost:8080/api/v1/users/1
```

#### 6. GET with Query Parameters

```bash
# Simple query
curl "http://localhost:8080/api/v1/users?page=1&page_size=10"

# Multiple parameters
curl "http://localhost:8080/api/v1/articles?page=1&page_size=20&user_id=5"
```

---

### Complete Testing Workflow

#### Step 1: Health Check

```bash
curl http://localhost:8080/health
```

**Expected:**
```json
{"status":"healthy"}
```

---

#### Step 2: Create User

```bash
curl -X POST http://localhost:8080/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com","password":"securepass123"}'
```

**Expected:**
```json
{
  "code": "000",
  "message": "success",
  "data": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "created_at": "2025-12-04T10:00:00Z",
    "updated_at": ""
  }
}
```

**Common Errors:**

Error: Duplicate email
```json
{
  "code": "006",
  "message": "email is already registered"
}
```

Error: Invalid email format
```json
{
  "code": "003",
  "message": "invalid email format"
}
```

---

#### Step 3: Login to Get Token

```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"john@example.com","password":"securepass123"}'
```

**Expected:**
```json
{
  "code": "000",
  "message": "success",
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoxLCJFbWFpbCI6ImpvaG5AZXhhbXBsZS5jb20iLCJleHAiOjE3MzM0MDI0MDAsImlhdCI6MTczMzQwMTUwMH0.abc123...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoxLCJFbWFpbCI6ImpvaG5AZXhhbXBsZS5jb20iLCJleHAiOjE3MzQwMDY0MDAsImlhdCI6MTczMzQwMTUwMH0.xyz789...",
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com"
    }
  }
}
```

**⚠️ IMPORTANT:** Copy the `access_token` value for next steps!

---

#### Step 4: Save Token as Variable

```bash
# Copy access_token from login response and save
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoxLCJFbWFpbCI6ImpvaG5AZXhhbXBsZS5jb20iLCJleHAiOjE3MzM0MDI0MDAsImlhdCI6MTczMzQwMTUwMH0.abc123..."

# Verify token is set
echo $TOKEN
```

**OR extract automatically with jq:**

```bash
# Install jq first: sudo apt install jq (Linux) or brew install jq (Mac)

# Login and extract token automatically
TOKEN=$(curl -s -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"john@example.com","password":"securepass123"}' \
  | jq -r '.data.access_token')

echo "Token: $TOKEN"
```

---

#### Step 5: Get User by ID

```bash
curl http://localhost:8080/api/v1/users/1
```

**Expected:**
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

**Error: User not found**
```json
{
  "code": "005",
  "message": "user not found"
}
```

---

#### Step 6: List Users with Pagination

```bash
curl "http://localhost:8080/api/v1/users?page=1&page_size=10"
```

**Expected:**
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

#### Step 7: Update User

```bash
curl -X PUT http://localhost:8080/api/v1/users/1 \
  -H "Content-Type: application/json" \
  -d '{"name":"John Updated","email":"john.updated@example.com","password":"newpass123"}'
```

**Expected:**
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

#### Step 8: Create Article (Requires Authentication)

```bash
# Use the TOKEN variable from Step 4
curl -X POST http://localhost:8080/api/v1/articles \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"My First Article","content":"This is the content of my first article.","user_id":1}'
```

**Expected:**
```json
{
  "code": "000",
  "message": "success",
  "data": {
    "id": 1,
    "title": "My First Article",
    "content": "This is the content of my first article.",
    "user_id": 1,
    "created_at": "2025-12-04T10:10:00Z",
    "updated_at": "2025-12-04T10:10:00Z"
  }
}
```

**Error: No token provided**
```json
{
  "code": "016",
  "message": "authorization token required"
}
```

**Error: Invalid/expired token**
```json
{
  "code": "016",
  "message": "authentication required"
}
```

---

#### Step 9: Get Article (with User Join)

```bash
curl http://localhost:8080/api/v1/articles/1
```

**Expected:**
```json
{
  "code": "000",
  "message": "success",
  "data": {
    "id": 1,
    "title": "My First Article",
    "content": "This is the content of my first article.",
    "user_id": 1,
    "created_at": "2025-12-04T10:10:00Z",
    "updated_at": "2025-12-04T10:10:00Z",
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "created_at": "2025-12-04T10:00:00Z",
      "updated_at": "2025-12-04T10:05:00Z"
    }
  }
}
```

**Note:** Response includes joined user information!

---

#### Step 10: List Articles

```bash
# All articles
curl "http://localhost:8080/api/v1/articles?page=1&page_size=10"

# Filter by user
curl "http://localhost:8080/api/v1/articles?page=1&page_size=10&user_id=1"
```

**Expected:**
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

#### Step 11: Update Article

```bash
curl -X PUT http://localhost:8080/api/v1/articles/1 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"Updated Title","content":"Updated content here"}'
```

---

#### Step 12: Delete Article

```bash
curl -X DELETE http://localhost:8080/api/v1/articles/1 \
  -H "Authorization: Bearer $TOKEN"
```

**Expected:**
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

#### Step 13: Validate Token

```bash
curl -X POST http://localhost:8080/api/v1/auth/validate \
  -H "Content-Type: application/json" \
  -d "{\"token\":\"$TOKEN\"}"
```

**Expected (valid token):**
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

**Expected (invalid token):**
```json
{
  "code": "016",
  "message": "invalid token"
}
```

---

#### Step 14: Logout (Blacklist Token)

```bash
curl -X POST http://localhost:8080/api/v1/auth/logout \
  -H "Content-Type: application/json" \
  -d "{\"token\":\"$TOKEN\"}"
```

**Expected:**
```json
{
  "code": "000",
  "message": "success",
  "data": {
    "success": true
  }
}
```

After logout, the token is blacklisted. Trying to use it again:

```bash
curl -X POST http://localhost:8080/api/v1/articles \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test","content":"Test","user_id":1}'
```

**Expected:**
```json
{
  "code": "016",
  "message": "token has been revoked"
}
```

---

### Automated Test Script

Save as `test-api.sh`:

```bash
#!/bin/bash

BASE_URL="http://localhost:8080"

echo "=== Testing Agrios API ==="

# 1. Create User
echo -e "\n1. Create User"
USER_RESP=$(curl -s -X POST $BASE_URL/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","password":"pass123"}')
echo $USER_RESP | jq
USER_ID=$(echo $USER_RESP | jq -r '.data.id')

# 2. Login
echo -e "\n2. Login"
LOGIN_RESP=$(curl -s -X POST $BASE_URL/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"pass123"}')
echo $LOGIN_RESP | jq
TOKEN=$(echo $LOGIN_RESP | jq -r '.data.access_token')

# 3. Create Article
echo -e "\n3. Create Article"
ARTICLE_RESP=$(curl -s -X POST $BASE_URL/api/v1/articles \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"title\":\"Test Article\",\"content\":\"Test content\",\"user_id\":$USER_ID}")
echo $ARTICLE_RESP | jq
ARTICLE_ID=$(echo $ARTICLE_RESP | jq -r '.data.id')

# 4. Get Article
echo -e "\n4. Get Article"
curl -s $BASE_URL/api/v1/articles/$ARTICLE_ID | jq

# 5. List Articles
echo -e "\n5. List Articles"
curl -s "$BASE_URL/api/v1/articles?page=1&page_size=10" | jq

# 6. Logout
echo -e "\n6. Logout"
curl -s -X POST $BASE_URL/api/v1/auth/logout \
  -H "Content-Type: application/json" \
  -d "{\"token\":\"$TOKEN\"}" | jq

echo -e "\n=== All Tests Complete ==="
```

**Run the script:**

```bash
# Make executable
chmod +x test-api.sh

# Run
./test-api.sh

# Or run directly with bash
bash test-api.sh
```

---

### curl Tips & Tricks

#### Pretty Print JSON with jq

```bash
# Install jq first
# Linux: sudo apt install jq
# Mac: brew install jq
# Windows: download from https://stedolan.github.io/jq/

# Use with curl
curl http://localhost:8080/api/v1/users/1 | jq

# Extract specific field
curl -s http://localhost:8080/api/v1/users/1 | jq '.data.email'

# Format and colorize
curl -s http://localhost:8080/api/v1/users | jq '.'
```

#### Save Response to File

```bash
# Save response
curl http://localhost:8080/api/v1/users/1 > user.json

# Save with headers
curl -i http://localhost:8080/api/v1/users/1 > response.txt
```

#### Timing Requests

```bash
# Show request time
curl -w "\nTime: %{time_total}s\n" http://localhost:8080/api/v1/users/1

# Detailed timing
curl -w "\nDNS: %{time_namelookup}s\nConnect: %{time_connect}s\nTotal: %{time_total}s\n" \
  http://localhost:8080/api/v1/users/1
```

#### Testing Multiple Endpoints

```bash
# Create simple test loop
for i in {1..5}; do
  echo "Testing user $i:"
  curl -s http://localhost:8080/api/v1/users/$i | jq '.data.name'
done
```

---

## 7. Testing with grpcurl

> **📖 For complete gRPC testing reference with all updated examples, see:** [GRPC_COMMANDS.md](GRPC_COMMANDS.md)

### What is grpcurl?

grpcurl is like curl but for gRPC APIs. It allows you to test gRPC services directly without going through the HTTP gateway.

**Tool:** grpcurl - https://github.com/fullstorydev/grpcurl

**Installation:**

```bash
# Linux
sudo apt install grpcurl

# Mac
brew install grpcurl

# Windows (with Go)
go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest

# Verify installation
grpcurl --version
```

---

### Why Test with grpcurl?

- ✅ Test gRPC services directly (bypass gateway)
- ✅ Verify proto file definitions  
- ✅ Debug service-to-service communication
- ✅ Check gRPC performance
- ✅ Test internal endpoints not exposed via HTTP
- ✅ Verify wrapped response format consistency

---

### ⚠️ Important: Response Format

**All gRPC responses now use wrapped format:**

```json
{
  "code": "000",
  "message": "success",
  "data": {
    // Response data here
  }
}
```

**Error responses:**
```json
{
  "code": "014",
  "message": "authentication required"
}
```

**See [Response Format section](#response-format) for complete code mapping.**

---

### Quick Examples

#### 1. Create User
```bash
grpcurl -plaintext -d '{"name":"John","email":"john@example.com","password":"pass123"}' \
  localhost:50051 user.UserService.CreateUser
```

**Response:**
```json
{
  "code": "000",
  "message": "success",
  "data": {
    "user": {
      "id": 1,
      "name": "John",
      "email": "john@example.com",
      "createdAt": "2025-12-04T10:00:00Z"
    }
  }
}
```

#### 2. Login and Get Token
```bash
grpcurl -plaintext -d '{"email":"john@example.com","password":"pass123"}' \
  localhost:50051 user.UserService.Login
```

#### 3. Create Article (Requires Auth)
```bash
TOKEN="your_access_token_here"
grpcurl -plaintext -H "authorization: Bearer $TOKEN" \
  -d '{"title":"Test Article","content":"Content here"}' \
  localhost:50052 article.ArticleService.CreateArticle
```

**Response:**
```json
{
  "code": "000",
  "message": "success",
  "data": {
    "article": {
      "id": 1,
      "title": "Test Article",
      "content": "Content here",
      "userId": 1
    }
  }
}
```

#### 4. Error Example (No Auth)
```bash
grpcurl -plaintext -d '{"title":"Fail","content":"No token"}' \
  localhost:50052 article.ArticleService.CreateArticle
```

**Response:**
```json
{
  "code": "014",
  "message": "authentication required"
}
```

---

### Service Discovery

#### List All Services

```bash
# User Service
grpcurl -plaintext localhost:50051 list

# Article Service
grpcurl -plaintext localhost:50052 list
```

#### List Methods in Service

```bash
# User Service methods
grpcurl -plaintext localhost:50051 list user.UserService

# Article Service methods
grpcurl -plaintext localhost:50052 list article.ArticleService
```

#### Describe Service/Method

```bash
# Describe UserService
grpcurl -plaintext localhost:50051 describe user.UserService

# Describe specific method
grpcurl -plaintext localhost:50051 describe user.UserService.CreateUser
```

---

### Full Testing Guide

**For complete examples of all endpoints with wrapped responses:**

👉 **See [GRPC_COMMANDS.md](GRPC_COMMANDS.md)** for:
- All User Service endpoints (8 methods)
- All Article Service endpoints (5 methods)  
- Error handling examples
- Complete test workflow
- Tips & tricks

---

## 8. Deployment

### Docker Compose Configuration

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: agrios-postgres
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
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
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  user-service:
    build: ./service-1-user
    container_name: agrios-user-service
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    environment:
      DB_HOST: postgres
      DB_USER: postgres
      DB_PASSWORD: postgres
      DB_NAME: agrios_users
      REDIS_ADDR: redis:6379
    ports:
      - "50051:50051"

  article-service:
    build: ./service-2-article
    container_name: agrios-article-service
    depends_on:
      - postgres
      - user-service
    environment:
      DB_HOST: postgres
      DB_USER: postgres
      DB_PASSWORD: postgres
      DB_NAME: agrios_articles
      USER_SERVICE_ADDR: user-service:50051
    ports:
      - "50052:50052"

  gateway:
    build: ./service-gateway
    container_name: agrios-gateway
    depends_on:
      - user-service
      - article-service
    environment:
      USER_SERVICE_ADDR: user-service:50051
      ARTICLE_SERVICE_ADDR: article-service:50052
    ports:
      - "8080:8080"

volumes:
  postgres_data:
```

### Deployment Commands

```bash
# Build and start
docker-compose up -d --build

# View logs
docker-compose logs -f

# Restart specific service
docker-compose restart gateway

# Stop all
docker-compose down

# Stop and remove volumes
docker-compose down -v
```

---

## 9. Operations & Monitoring

### Monitoring

#### Check Service Status
```bash
docker-compose ps
```

#### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f gateway
docker-compose logs -f user-service
docker-compose logs -f article-service

# Last 100 lines
docker-compose logs --tail=100
```

#### Database Operations
```bash
# Connect to PostgreSQL
docker exec -it agrios-postgres psql -U postgres -d agrios_users

# List tables
\dt

# Query users
SELECT * FROM users;

# Exit
\q
```

#### Redis Operations
```bash
# Connect to Redis
docker exec -it agrios-redis redis-cli

# Check blacklisted tokens
KEYS blacklist:*

# Get token details
GET blacklist:<token>

# Exit
exit
```

### Maintenance

#### Database Backup
```bash
# Backup
docker exec agrios-postgres pg_dump -U postgres agrios_users > backup_users.sql
docker exec agrios-postgres pg_dump -U postgres agrios_articles > backup_articles.sql

# Restore
docker exec -i agrios-postgres psql -U postgres -d agrios_users < backup_users.sql
```

#### Scaling Services
```bash
# Scale user service to 3 instances
docker-compose up -d --scale user-service=3

# Note: Need load balancer for multiple instances
```

---

## 10. Troubleshooting

### Common Issues

#### Issue 1: Port Already in Use

**Error:**
```
Error starting userland proxy: listen tcp 0.0.0.0:8080: bind: address already in use
```

**Solution:**
```bash
# Find process using port
netstat -ano | findstr :8080

# Kill process (Windows)
taskkill /PID <process_id> /F

# Or change port in docker-compose.yml
ports:
  - "8081:8080"  # Use different host port
```

#### Issue 2: Database Connection Failed

**Error:**
```
failed to connect to database: connection refused
```

**Solution:**
```bash
# Check PostgreSQL container
docker ps | grep postgres

# Restart PostgreSQL
docker-compose restart postgres

# Check logs
docker-compose logs postgres

# Verify credentials in .env files match docker-compose.yml
```

#### Issue 3: JWT Token Invalid

**Error:**
```json
{"code":"016","message":"token has been revoked"}
```

**Solution:**
- Token was logged out (blacklisted)
- Login again to get new token
- Check Redis connection: `docker exec -it agrios-redis redis-cli ping`

#### Issue 4: Article Creation Fails (No Auth)

**Error:**
```json
{"code":"016","message":"authorization token required"}
```

**Solution:**
```bash
# Must include Authorization header
curl -X POST http://localhost:8080/api/v1/articles \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{"title":"Test","content":"Test","user_id":1}'
```

#### Issue 5: Service Unavailable

**Error:**
```json
{"code":"014","message":"user service is currently unavailable"}
```

**Solution:**
```bash
# Check if user service is running
docker-compose ps user-service

# Restart user service
docker-compose restart user-service

# Check logs for errors
docker-compose logs user-service
```

### Debug Mode

Enable debug logging:

```bash
# Set in .env files
LOG_LEVEL=debug

# Or in docker-compose.yml
environment:
  LOG_LEVEL: debug
```

### Performance Monitoring

```bash
# Check container resource usage
docker stats

# Check specific container
docker stats agrios-gateway

# View container details
docker inspect agrios-gateway
```

---

## Appendix

### Useful Commands Reference

```bash
# Docker
docker-compose up -d              # Start all services
docker-compose down               # Stop all services
docker-compose logs -f            # View logs
docker-compose ps                 # Check status
docker-compose restart <service>  # Restart service

# Database
docker exec -it agrios-postgres psql -U postgres -d agrios_users
docker exec agrios-postgres pg_dump -U postgres agrios_users > backup.sql

# Redis
docker exec -it agrios-redis redis-cli
KEYS blacklist:*
GET blacklist:<token>

# Testing
curl http://localhost:8080/health
curl http://localhost:8080/api/v1/users
./test-api.sh
```

### Environment Variables Reference

| Variable | Service | Default | Description |
|----------|---------|---------|-------------|
| DB_HOST | User, Article | localhost | PostgreSQL host |
| DB_PORT | User, Article | 5432 | PostgreSQL port |
| DB_USER | User, Article | postgres | Database user |
| DB_PASSWORD | User, Article | postgres | Database password |
| DB_NAME | User | agrios_users | User database |
| DB_NAME | Article | agrios_articles | Article database |
| JWT_SECRET | User | - | JWT signing key |
| ACCESS_TOKEN_DURATION | User | 15m | Access token lifetime |
| REFRESH_TOKEN_DURATION | User | 168h | Refresh token lifetime |
| REDIS_ADDR | User | localhost:6379 | Redis address |
| GRPC_PORT | User | 50051 | User service port |
| GRPC_PORT | Article | 50052 | Article service port |
| USER_SERVICE_ADDR | Article, Gateway | localhost:50051 | User service address |
| ARTICLE_SERVICE_ADDR | Gateway | localhost:50052 | Article service address |
| GATEWAY_PORT | Gateway | 8080 | Gateway HTTP port |

---

## Appendix A: Quick Reference

### Common Docker Commands

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f gateway

# Restart service
docker-compose restart gateway

# Rebuild and start
docker-compose up -d --build

# Check status
docker-compose ps

# Execute command in container
docker exec -it agrios-postgres psql -U postgres
```

---

## Appendix B: Architecture Diagrams

### System Overview

```
External World
      │
      │ HTTP/REST
      │ Port 8080
      ↓
┌─────────────────┐
│  API Gateway    │ ← Entry Point (REST API)
│  :8080          │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    │ gRPC    │ gRPC
    ↓         ↓
┌────────────┐  ┌────────────┐
│ User Svc   │  │ Article Svc│
│ :50051     │←─┤ :50052     │  
└─────┬──────┘  └────────────┘
      │
      │
      ↓
┌────────────┐
│ PostgreSQL │  
│ Redis      │  
└────────────┘
```

---

## Appendix C: Development Checklist

### Before Pushing Code

- [ ] Code follows Go conventions
- [ ] Added tests for new features
- [ ] Updated proto files if needed
- [ ] Regenerated proto code: `protoc --go_out=. --go-grpc_out=. proto/*.proto`
- [ ] Updated documentation
- [ ] Tested locally with Docker
- [ ] Checked logs for errors
- [ ] Verified migrations work
- [ ] No hardcoded credentials
- [ ] Environment variables documented

### Before Deploying

- [ ] All services build successfully
- [ ] Database migrations tested
- [ ] Health checks passing
- [ ] Integration tests passing
- [ ] Load tested (if applicable)
- [ ] Backup procedures verified
- [ ] Rollback plan ready
- [ ] Monitoring configured
- [ ] Logs aggregation working
- [ ] Security review completed

---

## Appendix D: Resources

### Official Documentation

- **Go**: https://go.dev/doc/
- **gRPC**: https://grpc.io/docs/
- **Protocol Buffers**: https://protobuf.dev/
- **Docker**: https://docs.docker.com/
- **PostgreSQL**: https://www.postgresql.org/docs/
- **Redis**: https://redis.io/docs/

### Tools

- **curl**: https://curl.se/
- **grpcurl**: https://github.com/fullstorydev/grpcurl
- **jq**: https://stedolan.github.io/jq/
- **Postman**: https://www.postman.com/
- **PgAdmin**: https://www.pgadmin.org/

### Learning Resources

- **gRPC Go Tutorial**: https://grpc.io/docs/languages/go/quickstart/
- **REST API Best Practices**: https://restfulapi.net/
- **JWT Authentication**: https://jwt.io/introduction
- **Docker Compose**: https://docs.docker.com/compose/

---

**Document Version:** 2.0.0  
**Last Updated:** December 4, 2025  
**Maintained By:** Development Team  
**Repository:** https://github.com/thatlq1812/agrios

For questions or issues, refer to this guide or open an issue on GitHub.

---

**📝 Note:** This is a complete, all-in-one guide. You should not need other documentation files for daily development and operations.
  localhost:50051 user.UserService.Login \
  | jq -r '.access_token')

# 3. Validate token
grpcurl -plaintext \
  -d "{\"token\":\"$TOKEN\"}" \
  localhost:50051 user.UserService.ValidateToken

# 4. Create article
grpcurl -plaintext \
  -d '{"title":"Test Article","content":"Content here","user_id":1}' \
  localhost:50052 article.ArticleService.CreateArticle

# 5. Get article with user info
grpcurl -plaintext \
  -d '{"id":1}' \
  localhost:50052 article.ArticleService.GetArticle

# 6. List articles
grpcurl -plaintext \
  -d '{"page":1,"page_size":10}' \
  localhost:50052 article.ArticleService.ListArticles

# 7. Logout (revoke token)
grpcurl -plaintext \
  -d "{\"token\":\"$TOKEN\"}" \
  localhost:50051 user.UserService.RevokeToken

# 8. Verify token is revoked
grpcurl -plaintext \
  -d "{\"token\":\"$TOKEN\"}" \
  localhost:50051 user.UserService.ValidateToken
# Should return: Code: Unauthenticated
```

---

### Tips & Tricks

#### Save Request to File

```bash
# Create request.json
cat > request.json <<EOF
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "pass123"
}
EOF

# Use file
grpcurl -plaintext -d @request.json \
  localhost:50051 user.UserService.CreateUser
```

#### Pretty Print with jq

```bash
grpcurl -plaintext -d '{"id":1}' \
  localhost:50051 user.UserService.GetUser | jq
```

#### Add Metadata (Headers)

```bash
grpcurl -plaintext \
  -H "authorization: Bearer $TOKEN" \
  -H "x-request-id: 12345" \
  -d '{"id":1}' \
  localhost:50051 user.UserService.GetUser
```

#### Check Service Health

```bash
# Check if service is responding
grpcurl -plaintext localhost:50051 list
grpcurl -plaintext localhost:50052 list

# If no response, service is down
```

---

### Comparison: REST API vs gRPC

**Same operation, different protocols:**

#### REST (via Gateway):
```bash
curl http://localhost:8080/api/v1/users/1
```
**Response:**
```json
{
  "code": "000",
  "message": "success",
  "data": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com"
  }
}
```

#### gRPC (Direct):
```bash
grpcurl -plaintext -d '{"id":1}' localhost:50051 user.UserService.GetUser
```
**Response:**
```json
{
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com"
  }
}
```

**Key Differences:**
- REST: Wrapped response with code/message
- gRPC: Raw protobuf message
- REST: HTTP status codes (200, 404, 500)
- gRPC: gRPC status codes (OK, NOT_FOUND, INTERNAL)

---

## 7. Deployment

### Docker Compose Configuration

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: agrios-postgres
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
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
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  user-service:
    build: ./service-1-user
    container_name: agrios-user-service
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    environment:
      DB_HOST: postgres
      DB_USER: postgres
      DB_PASSWORD: postgres
      DB_NAME: agrios_users
      REDIS_ADDR: redis:6379
    ports:
      - "50051:50051"

  article-service:
    build: ./service-2-article
    container_name: agrios-article-service
    depends_on:
      - postgres
      - user-service
    environment:
      DB_HOST: postgres
      DB_USER: postgres
      DB_PASSWORD: postgres
      DB_NAME: agrios_articles
      USER_SERVICE_ADDR: user-service:50051
    ports:
      - "50052:50052"

  gateway:
    build: ./service-gateway
    container_name: agrios-gateway
    depends_on:
      - user-service
      - article-service
    environment:
      USER_SERVICE_ADDR: user-service:50051
      ARTICLE_SERVICE_ADDR: article-service:50052
    ports:
      - "8080:8080"

volumes:
  postgres_data:
```

### Deployment Commands

```bash
# Build and start
docker-compose up -d --build

# View logs
docker-compose logs -f

# Restart specific service
docker-compose restart gateway

# Stop all
docker-compose down

# Stop and remove volumes
docker-compose down -v
```

---

## 9. Operations & Monitoring

### Monitoring

#### Check Service Status
```bash
docker-compose ps
```

#### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f gateway
docker-compose logs -f user-service
docker-compose logs -f article-service

# Last 100 lines
docker-compose logs --tail=100
```

#### Database Operations
```bash
# Connect to PostgreSQL
docker exec -it agrios-postgres psql -U postgres -d agrios_users

# List tables
\dt

# Query users
SELECT * FROM users;

# Exit
\q
```

#### Redis Operations
```bash
# Connect to Redis
docker exec -it agrios-redis redis-cli

# Check blacklisted tokens
KEYS blacklist:*

# Get token details
GET blacklist:<token>

# Exit
exit
```

### Maintenance

#### Database Backup
```bash
# Backup
docker exec agrios-postgres pg_dump -U postgres agrios_users > backup_users.sql
docker exec agrios-postgres pg_dump -U postgres agrios_articles > backup_articles.sql

# Restore
docker exec -i agrios-postgres psql -U postgres -d agrios_users < backup_users.sql
```

#### Scaling Services
```bash
# Scale user service to 3 instances
docker-compose up -d --scale user-service=3

# Note: Need load balancer for multiple instances
```

---

## 10. Troubleshooting

### Common Issues

#### Issue 1: Port Already in Use

**Error:**
```
Error starting userland proxy: listen tcp 0.0.0.0:8080: bind: address already in use
```

**Solution:**
```bash
# Find process using port
netstat -ano | findstr :8080

# Kill process (Windows)
taskkill /PID <process_id> /F

# Or change port in docker-compose.yml
ports:
  - "8081:8080"  # Use different host port
```

#### Issue 2: Database Connection Failed

**Error:**
```
failed to connect to database: connection refused
```

**Solution:**
```bash
# Check PostgreSQL container
docker ps | grep postgres

# Restart PostgreSQL
docker-compose restart postgres

# Check logs
docker-compose logs postgres

# Verify credentials in .env files match docker-compose.yml
```

#### Issue 3: JWT Token Invalid

**Error:**
```json
{"code":"016","message":"token has been revoked"}
```

**Solution:**
- Token was logged out (blacklisted)
- Login again to get new token
- Check Redis connection: `docker exec -it agrios-redis redis-cli ping`

#### Issue 4: Article Creation Fails (No Auth)

**Error:**
```json
{"code":"016","message":"authorization token required"}
```

**Solution:**
```bash
# Must include Authorization header
curl -X POST http://localhost:8080/api/v1/articles \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{"title":"Test","content":"Test","user_id":1}'
```

#### Issue 5: Service Unavailable

**Error:**
```json
{"code":"014","message":"user service is currently unavailable"}
```

**Solution:**
```bash
# Check if user service is running
docker-compose ps user-service

# Restart user service
docker-compose restart user-service

# Check logs for errors
docker-compose logs user-service
```

### Debug Mode

Enable debug logging:

```bash
# Set in .env files
LOG_LEVEL=debug

# Or in docker-compose.yml
environment:
  LOG_LEVEL: debug
```

### Performance Monitoring

```bash
# Check container resource usage
docker stats

# Check specific container
docker stats agrios-gateway

# View container details
docker inspect agrios-gateway
```

---

## Appendix

### Useful Commands Reference

```bash
# Docker
docker-compose up -d              # Start all services
docker-compose down               # Stop all services
docker-compose logs -f            # View logs
docker-compose ps                 # Check status
docker-compose restart <service>  # Restart service

# Database
docker exec -it agrios-postgres psql -U postgres -d agrios_users
docker exec agrios-postgres pg_dump -U postgres agrios_users > backup.sql

# Redis
docker exec -it agrios-redis redis-cli
KEYS blacklist:*
GET blacklist:<token>

# Testing
curl http://localhost:8080/health
curl http://localhost:8080/api/v1/users
./test-api.sh
```

### Environment Variables Reference

| Variable | Service | Default | Description |
|----------|---------|---------|-------------|
| DB_HOST | User, Article | localhost | PostgreSQL host |
| DB_PORT | User, Article | 5432 | PostgreSQL port |
| DB_USER | User, Article | postgres | Database user |
| DB_PASSWORD | User, Article | postgres | Database password |
| DB_NAME | User | agrios_users | User database |
| DB_NAME | Article | agrios_articles | Article database |
| JWT_SECRET | User | - | JWT signing key |
| ACCESS_TOKEN_DURATION | User | 15m | Access token lifetime |
| REFRESH_TOKEN_DURATION | User | 168h | Refresh token lifetime |
| REDIS_ADDR | User | localhost:6379 | Redis address |
| GRPC_PORT | User | 50051 | User service port |
| GRPC_PORT | Article | 50052 | Article service port |
| USER_SERVICE_ADDR | Article, Gateway | localhost:50051 | User service address |
| ARTICLE_SERVICE_ADDR | Gateway | localhost:50052 | Article service address |
| GATEWAY_PORT | Gateway | 8080 | Gateway HTTP port |

---

## Appendix A: Quick Reference

### Common Docker Commands

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f gateway

# Restart service
docker-compose restart gateway

# Rebuild and start
docker-compose up -d --build

# Check status
docker-compose ps

# Execute command in container
docker exec -it agrios-postgres psql -U postgres
```

---

### Common curl Commands

```bash
# Create user
curl -X POST http://localhost:8080/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John","email":"john@example.com","password":"pass123"}'

# Login
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"john@example.com","password":"pass123"}'

# Get user
curl http://localhost:8080/api/v1/users/1

# Create article (with auth)
curl -X POST http://localhost:8080/api/v1/articles \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"Article","content":"Content","user_id":1}'
```

---

### Common grpcurl Commands

```bash
# List services
grpcurl -plaintext localhost:50051 list

# Describe service
grpcurl -plaintext localhost:50051 describe user_service.UserService

# Create user
grpcurl -plaintext -d '{"name":"John","email":"john@example.com","password":"pass123"}' \
  localhost:50051 user_service.UserService.CreateUser

# Get user
grpcurl -plaintext -d '{"id":1}' \
  localhost:50051 user_service.UserService.GetUser
```

---

### Service Ports Reference

| Service | Protocol | Port | URL |
|---------|----------|------|-----|
| Gateway | HTTP | 8080 | http://localhost:8080 |
| User Service | gRPC | 50051 | localhost:50051 |
| Article Service | gRPC | 50052 | localhost:50052 |
| PostgreSQL | TCP | 5432 | localhost:5432 |
| Redis | TCP | 6379 | localhost:6379 |
| PgAdmin | HTTP | 5050 | http://localhost:5050 |

---

### Environment Variables Reference

**User Service:**
```env
DB_HOST=postgres
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=agrios_users
JWT_SECRET=your-secret-key
ACCESS_TOKEN_DURATION=15m
REFRESH_TOKEN_DURATION=168h
REDIS_ADDR=redis:6379
GRPC_PORT=50051
```

**Article Service:**
```env
DB_HOST=postgres
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=agrios_articles
USER_SERVICE_ADDR=user-service:50051
GRPC_PORT=50052
```

**Gateway:**
```env
USER_SERVICE_ADDR=user-service:50051
ARTICLE_SERVICE_ADDR=article-service:50052
GATEWAY_PORT=8080
```

---

### Response Codes Quick Reference

| Code | Status | Description |
|------|--------|-------------|
| 000 | OK | Success |
| 003 | INVALID_ARGUMENT | Validation error |
| 005 | NOT_FOUND | Resource not found |
| 006 | ALREADY_EXISTS | Duplicate (e.g., email exists) |
| 013 | INTERNAL | Server error |
| 014 | UNAVAILABLE | Service down |
| 016 | UNAUTHENTICATED | Auth required/failed |

---

### Useful One-Liners

```bash
# Complete test flow
curl -X POST http://localhost:8080/api/v1/users -H "Content-Type: application/json" -d '{"name":"Test","email":"test@example.com","password":"pass123"}' && \
TOKEN=$(curl -s -X POST http://localhost:8080/api/v1/auth/login -H "Content-Type: application/json" -d '{"email":"test@example.com","password":"pass123"}' | jq -r '.data.access_token') && \
curl -X POST http://localhost:8080/api/v1/articles -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d '{"title":"Test","content":"Content","user_id":1}'

# Watch logs in real-time
docker-compose logs -f --tail=50

# Check all container health
docker ps --format "table {{.Names}}\t{{.Status}}"

# Restart everything
docker-compose restart && docker-compose logs -f

# Clean and rebuild
docker-compose down -v && docker-compose up -d --build

# Database backup
docker exec agrios-postgres pg_dump -U postgres agrios_users > backup_$(date +%Y%m%d).sql

# Check Redis tokens
docker exec -it agrios-redis redis-cli KEYS "blacklist:*"
```

---

## Appendix B: Architecture Diagrams

### System Overview

```
External World
      │
      │ HTTP/REST
      │ Port 8080
      ↓
┌─────────────────┐
│  API Gateway    │ ← Entry Point (REST API)
│  :8080          │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    │ gRPC    │ gRPC
    ↓         ↓
┌─────────┐ ┌─────────────┐
│  User   │ │  Article    │
│ Service │←┤  Service    │
│ :50051  │ │  :50052     │
└────┬────┘ └──────┬──────┘
     │             │
  ┌──┴──┐      ┌──┴──┐
  │ DB  │      │ DB  │
  │Redis│      │     │
  └─────┘      └─────┘
```

### Request Flow

```
1. Client → Gateway
   POST /api/v1/users
   {"name":"John","email":"john@example.com"}

2. Gateway → User Service (gRPC)
   CreateUser(CreateUserRequest)

3. User Service → PostgreSQL
   INSERT INTO users...

4. User Service → Gateway
   User{id:1, name:"John", email:"john@example.com"}

5. Gateway → Client
   {"code":"000","message":"success","data":{...}}
```

---

## Appendix C: Development Checklist

### Before Pushing Code

- [ ] Code follows Go conventions
- [ ] Added tests for new features
- [ ] Updated proto files if needed
- [ ] Regenerated proto code: `protoc --go_out=. --go-grpc_out=. proto/*.proto`
- [ ] Updated documentation
- [ ] Tested locally with Docker
- [ ] Checked logs for errors
- [ ] Verified migrations work
- [ ] No hardcoded credentials
- [ ] Environment variables documented

### Before Deploying

- [ ] All services build successfully
- [ ] Database migrations tested
- [ ] Health checks passing
- [ ] Integration tests passing
- [ ] Load tested (if applicable)
- [ ] Backup procedures verified
- [ ] Rollback plan ready
- [ ] Monitoring configured
- [ ] Logs aggregation working
- [ ] Security review completed

---

## Appendix D: Resources

### Official Documentation

- **Go**: https://go.dev/doc/
- **gRPC**: https://grpc.io/docs/
- **Protocol Buffers**: https://protobuf.dev/
- **Docker**: https://docs.docker.com/
- **PostgreSQL**: https://www.postgresql.org/docs/
- **Redis**: https://redis.io/docs/

### Tools

- **curl**: https://curl.se/
- **grpcurl**: https://github.com/fullstorydev/grpcurl
- **jq**: https://stedolan.github.io/jq/
- **Postman**: https://www.postman.com/
- **PgAdmin**: https://www.pgadmin.org/

### Learning Resources

- **gRPC Go Tutorial**: https://grpc.io/docs/languages/go/quickstart/
- **REST API Best Practices**: https://restfulapi.net/
- **JWT Authentication**: https://jwt.io/introduction
- **Docker Compose**: https://docs.docker.com/compose/

---

**Document Version:** 2.0.0  
**Last Updated:** December 4, 2025  
**Maintained By:** Development Team  
**Repository:** https://github.com/thatlq1812/agrios

For questions or issues, refer to this guide or open an issue on GitHub.

---

**📝 Note:** This is a complete, all-in-one guide. You should not need other documentation files for daily development and operations.
