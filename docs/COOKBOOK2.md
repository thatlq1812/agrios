# Agrios Microservices - Deployment & Operations Guide

Hướng dẫn đầy đủ về deployment, testing và operations cho Agrios microservices system.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Local Development Setup](#local-development-setup)
3. [Docker Deployment](#docker-deployment)
4. [Testing Services](#testing-services)
5. [Health Checks & Monitoring](#health-checks--monitoring)
6. [Failure Scenarios Testing](#failure-scenarios-testing)
7. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

### Services Structure

```
agrios/
├── service-1-user/          # User Service (Port 50051)
│   ├── gRPC endpoints: User management, Authentication
│   └── Database: PostgreSQL (users table)
│
└── service-2-article/       # Article Service (Port 50052)
    ├── gRPC endpoints: Article management
    ├── Database: PostgreSQL (articles table)
    └── Dependencies: Calls User Service for user verification
```

### Communication Flow

```
Client → Article Service (50052) → User Service (50051) → PostgreSQL
                ↓
           PostgreSQL
```

### Key Features Implemented

- **Error Handling**: Proper gRPC status codes (NotFound, Unavailable, DeadlineExceeded, etc.)
- **Retry Logic**: Exponential backoff for transient failures
- **Graceful Degradation**: Article Service returns partial data when User Service is down
- **Timeout Management**: 3s per request, 5s connection timeout
- **Detailed Logging**: Structured logs with operation context

---

## Local Development Setup

### Prerequisites

```bash
# Required tools
- Go 1.24.0+
- PostgreSQL 15+
- Protocol Buffers compiler (protoc)
```

### Step 1: Setup PostgreSQL Databases

```bash
# Start PostgreSQL
sudo systemctl start postgresql

# Create databases
psql -U postgres

CREATE DATABASE user_service_db;
CREATE DATABASE article_service_db;

# Exit psql
\q
```

### Step 2: Configure Environment Variables

**User Service** - Create `service-1-user/.env`:

```env
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=your_password
DB_NAME=user_service_db
DB_SSLMODE=disable

# Server Configuration
SERVER_PORT=50051

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRY=24h
JWT_REFRESH_EXPIRY=168h
```

**Article Service** - Create `service-2-article/.env`:

```env
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=your_password
DB_NAME=article_service_db
DB_SSLMODE=disable

# Server Configuration
SERVER_PORT=50052

# User Service Configuration
USER_SERVICE_ADDRESS=localhost:50051
```

### Step 3: Run Database Migrations

**User Service:**

```bash
cd service-1-user

# Run migration
psql -U postgres -d user_service_db -f migrations/001_create_users_table.sql
```

**Article Service:**

```bash
cd service-2-article

# Run migration
psql -U postgres -d article_service_db -f migrations/001_create_articles_table.sql
```

### Step 4: Build and Run Services

**Terminal 1 - User Service:**

```bash
cd service-1-user

# Install dependencies
go mod tidy
go mod vendor

# Build
go build -o bin/user-service cmd/server/main.go

# Run
./bin/user-service
```

**Expected output:**

```
[Main] Starting User Service...
[Main] Database initialized successfully
[Main] User service started on :50051
```

**Terminal 2 - Article Service:**

```bash
cd service-2-article

# Install dependencies
go mod tidy
go mod vendor

# Build
go build -o bin/article-service cmd/server/main.go

# Run
./bin/article-service
```

**Expected output:**

```
[Main] Starting Article Service...
[Main] Database initialized successfully
[UserClient] Connecting to user service at localhost:50051
[UserClient] Successfully connected to user service at localhost:50051
[Main] User service client initialized successfully
[Main] Article service started on :50052
```

---

## Docker Deployment

### Step 1: Build Docker Images

```bash
# Build User Service image
cd service-1-user
docker build -t agrios-user-service:latest .

# Build Article Service image
cd ../service-2-article
docker build -t agrios-article-service:latest .
```

### Step 2: Run with Docker Compose

**Create `docker-compose.yml` (root directory):**

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: agrios-postgres
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres123
      POSTGRES_DB: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./service-1-user/migrations:/docker-entrypoint-initdb.d/01-user
      - ./service-2-article/migrations:/docker-entrypoint-initdb.d/02-article
    networks:
      - agrios-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5

  user-service:
    image: agrios-user-service:latest
    container_name: agrios-user-service
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      DB_HOST: postgres
      DB_PORT: 5432
      DB_USER: postgres
      DB_PASSWORD: postgres123
      DB_NAME: user_service_db
      DB_SSLMODE: disable
      SERVER_PORT: 50051
      JWT_SECRET: production-secret-key-change-this
      JWT_EXPIRY: 24h
      JWT_REFRESH_EXPIRY: 168h
    ports:
      - "50051:50051"
    networks:
      - agrios-network
    restart: unless-stopped

  article-service:
    image: agrios-article-service:latest
    container_name: agrios-article-service
    depends_on:
      - user-service
    environment:
      DB_HOST: postgres
      DB_PORT: 5432
      DB_USER: postgres
      DB_PASSWORD: postgres123
      DB_NAME: article_service_db
      DB_SSLMODE: disable
      SERVER_PORT: 50052
      USER_SERVICE_ADDRESS: user-service:50051
    ports:
      - "50052:50052"
    networks:
      - agrios-network
    restart: unless-stopped

volumes:
  postgres_data:

networks:
  agrios-network:
    driver: bridge
```

### Step 3: Start Services

```bash
# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f user-service
docker-compose logs -f article-service
```

### Step 4: Stop Services

```bash
# Stop all services
docker-compose down

# Stop and remove volumes
docker-compose down -v
```

---

## Testing Services

### Using grpcurl

**Install grpcurl:**

```bash
# macOS
brew install grpcurl

# Linux
go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest
```

### Test User Service

**1. Create a User:**

```bash
grpcurl -plaintext -d '{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123"
}' localhost:50051 user.UserService/CreateUser
```

**Expected response:**

```json
{
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "createdAt": "2025-12-02T10:30:00Z",
    "updatedAt": "2025-12-02T10:30:00Z"
  }
}
```

**2. Login:**

```bash
grpcurl -plaintext -d '{
  "email": "john@example.com",
  "password": "password123"
}' localhost:50051 user.UserService/Login
```

**Expected response:**

```json
{
  "accessToken": "eyJhbGc...",
  "refreshToken": "eyJhbGc...",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com"
  },
  "message": "login successful"
}
```

**3. Get User:**

```bash
grpcurl -plaintext -d '{
  "id": 1
}' localhost:50051 user.UserService/GetUser
```

**4. List Users:**

```bash
grpcurl -plaintext -d '{
  "pageSize": 10,
  "page": 0
}' localhost:50051 user.UserService/ListUsers
```

### Test Article Service

**1. Create Article (requires existing user):**

```bash
grpcurl -plaintext -d '{
  "title": "My First Article",
  "content": "This is the content of my article",
  "userId": 1
}' localhost:50052 article.ArticleService/CreateArticle
```

**Expected response:**

```json
{
  "id": 1,
  "title": "My First Article",
  "content": "This is the content of my article",
  "userId": 1,
  "createdAt": "2025-12-02T10:35:00Z",
  "updatedAt": "2025-12-02T10:35:00Z"
}
```

**2. Get Article with User Info:**

```bash
grpcurl -plaintext -d '{
  "id": 1
}' localhost:50052 article.ArticleService/GetArticleWithUser
```

**Expected response:**

```json
{
  "article": {
    "id": 1,
    "title": "My First Article",
    "content": "This is the content of my article",
    "userId": 1,
    "createdAt": "2025-12-02T10:35:00Z",
    "updatedAt": "2025-12-02T10:35:00Z"
  },
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "createdAt": "2025-12-02T10:30:00Z",
    "updatedAt": "2025-12-02T10:30:00Z"
  }
}
```

**3. List Articles:**

```bash
grpcurl -plaintext -d '{
  "pageSize": 10,
  "pageNumber": 0
}' localhost:50052 article.ArticleService/ListArticles
```

**4. Update Article:**

```bash
grpcurl -plaintext -d '{
  "id": 1,
  "title": "Updated Title",
  "content": "Updated content"
}' localhost:50052 article.ArticleService/UpdateArticle
```

**5. Delete Article:**

```bash
grpcurl -plaintext -d '{
  "id": 1
}' localhost:50052 article.ArticleService/DeleteArticle
```

---

## Health Checks & Monitoring

### Check Service Health

**User Service:**

```bash
# Try to get non-existent user (should return NotFound, not error)
grpcurl -plaintext -d '{"id": 99999}' localhost:50051 user.UserService/GetUser
```

**Expected:**

```
ERROR:
  Code: NotFound
  Message: user with ID 99999 not found
```

**Article Service → User Service connectivity:**

```bash
# Create article with non-existent user
grpcurl -plaintext -d '{
  "title": "Test",
  "content": "Test",
  "userId": 99999
}' localhost:50052 article.ArticleService/CreateArticle
```

**Expected:**

```
ERROR:
  Code: InvalidArgument
  Message: user with ID 99999 not found
```

### Monitor Logs

**User Service logs pattern:**

```
[GetUser] Invalid argument: user_id=-1
[GetUser] User not found: user_id=99999
[GetUser] Success: user_id=1, email=john@example.com
[CreateUser] Success: user_id=1, email=john@example.com
[Login] Success: user_id=1, email=john@example.com
```

**Article Service logs pattern:**

```
[UserClient.GetUser] Calling user service: user_id=1
[UserClient.GetUser] Success: user_id=1, email=john@example.com
[CreateArticle] Verifying user exists: user_id=1
[CreateArticle] Success: article_id=1, user_id=1
[GetArticleWithUser] Fetching user info: article_id=1, user_id=1
[GetArticleWithUser] Success: article_id=1, user_id=1, user_email=john@example.com
```

---

## Failure Scenarios Testing

### Scenario 1: User Service Down

**Simulate:**

```bash
# Stop User Service
docker-compose stop user-service

# Or kill process if running locally
pkill -f user-service
```

**Test Article Service behavior:**

```bash
# Try to create article
grpcurl -plaintext -d '{
  "title": "Test",
  "content": "Test",
  "userId": 1
}' localhost:50052 article.ArticleService/CreateArticle
```

**Expected behavior:**

- After 3 retry attempts with exponential backoff
- Returns: `Code: Unavailable, Message: user service is currently unavailable, please try again later`

**Check logs:**

```
[UserClient.GetUserWithRetry] Retrying after error: user_id=1, attempt=1/3, backoff=100ms
[UserClient.GetUserWithRetry] Retrying after error: user_id=1, attempt=2/3, backoff=200ms
[UserClient.GetUserWithRetry] All retries exhausted: user_id=1, attempts=3
[CreateArticle] User service unavailable: user_id=1
```

**Get existing article (Graceful Degradation):**

```bash
grpcurl -plaintext -d '{"id": 1}' localhost:50052 article.ArticleService/GetArticleWithUser
```

**Expected:**

```json
{
  "article": {
    "id": 1,
    "title": "My First Article",
    "content": "Content...",
    "userId": 1
  },
  "user": null  // User info unavailable but article still returned
}
```

**Check logs:**

```
[GetArticleWithUser] User service unavailable (graceful degradation): article_id=1, user_id=1, code=Unavailable
```

### Scenario 2: User Not Found

```bash
grpcurl -plaintext -d '{
  "title": "Test",
  "content": "Test",
  "userId": 99999
}' localhost:50052 article.ArticleService/CreateArticle
```

**Expected:**

```
ERROR:
  Code: InvalidArgument
  Message: user with ID 99999 not found
```

**Check logs:**

```
[UserClient.GetUser] User not found: user_id=99999
[CreateArticle] User not found: user_id=99999
```

### Scenario 3: Request Timeout

**Simulate slow User Service** (modify User Service code temporarily):

```go
// In user_server.go GetUser method, add:
time.Sleep(5 * time.Second)  // Exceeds 3s timeout
```

**Test:**

```bash
grpcurl -plaintext -d '{
  "title": "Test",
  "content": "Test",
  "userId": 1
}' localhost:50052 article.ArticleService/CreateArticle
```

**Expected:**

```
ERROR:
  Code: DeadlineExceeded
  Message: request timeout while verifying user
```

**Check logs:**

```
[UserClient.GetUser] Timeout: user_id=1, timeout=3s
[CreateArticle] User service timeout: user_id=1
```

### Scenario 4: Database Connection Lost

**Simulate:**

```bash
# Stop PostgreSQL
docker-compose stop postgres
```

**Test:**

```bash
grpcurl -plaintext -d '{"id": 1}' localhost:50051 user.UserService/GetUser
```

**Expected:**

```
ERROR:
  Code: Internal
  Message: failed to get user: <database error>
```

**Check logs:**

```
[GetUser] Database error: user_id=1, error=connection refused
```

### Scenario 5: Network Partition

**Simulate using iptables (Linux):**

```bash
# Block traffic to User Service
sudo iptables -A INPUT -p tcp --dport 50051 -j DROP

# Test from Article Service
grpcurl -plaintext -d '{
  "title": "Test",
  "content": "Test",
  "userId": 1
}' localhost:50052 article.ArticleService/CreateArticle

# Restore
sudo iptables -D INPUT -p tcp --dport 50051 -j DROP
```

**Expected:** Same as User Service Down scenario with retries

---

## Troubleshooting

### Common Issues

#### 1. "connection refused" on startup

**Symptoms:**

```
[UserClient] Failed to connect to user service: address=localhost:50051, error=connection refused
```

**Solutions:**

- Verify User Service is running: `ps aux | grep user-service`
- Check port availability: `lsof -i :50051`
- Verify firewall rules
- Check `.env` configuration

#### 2. Database migration errors

**Symptoms:**

```
failed to initialize database: relation "users" does not exist
```

**Solutions:**

```bash
# Check database exists
psql -U postgres -l

# Re-run migrations
psql -U postgres -d user_service_db -f migrations/001_create_users_table.sql
```

#### 3. gRPC import errors

**Symptoms:**

```
could not import service-1-user/proto
```

**Solutions:**

```bash
cd service-2-article
go mod tidy
go mod vendor
```

#### 4. Proto type mismatch

**Symptoms:**

```
cannot use user (variable of type *"service-1-user/proto".User) as *"article-service/proto".User
```

**Solutions:**

- Use `convertUser()` function to convert between types
- Verify proto definitions are in sync

#### 5. Docker network issues

**Symptoms:**

```
user-service: connection refused
```

**Solutions:**

```bash
# Check network
docker network inspect agrios_agrios-network

# Verify service names in docker-compose.yml
# Use service name, not localhost: user-service:50051
```

### Debug Commands

```bash
# Check service logs
docker-compose logs -f user-service | grep ERROR
docker-compose logs -f article-service | grep ERROR

# Check service health
docker-compose ps

# Inspect container
docker exec -it agrios-user-service sh
docker exec -it agrios-article-service sh

# Check database
docker exec -it agrios-postgres psql -U postgres -d user_service_db -c "SELECT * FROM users;"

# Check network connectivity
docker exec -it agrios-article-service ping user-service
docker exec -it agrios-article-service nc -zv user-service 50051
```

---

## Performance Considerations

### Timeouts

- **Request timeout**: 3s (configurable in `user_client.go`)
- **Connection timeout**: 5s
- **Retry attempts**: 3 with exponential backoff (100ms, 200ms, 400ms)

### Connection Pooling

gRPC automatically manages connection pooling. One connection per client is sufficient for most cases.

### Logging Overhead

Logs are written synchronously. For high-throughput production:

- Use async logging library (e.g., zap)
- Reduce log verbosity
- Use log sampling

---

## Production Checklist

- [ ] Change JWT secret keys
- [ ] Enable SSL/TLS for gRPC
- [ ] Use PostgreSQL with replication
- [ ] Implement rate limiting
- [ ] Add metrics collection (Prometheus)
- [ ] Set up centralized logging (ELK/Loki)
- [ ] Configure health check endpoints
- [ ] Implement circuit breakers
- [ ] Set up monitoring alerts
- [ ] Enable distributed tracing (Jaeger/Zipkin)
- [ ] Use secrets management (Vault/K8s secrets)
- [ ] Configure proper resource limits
- [ ] Set up backup strategy
- [ ] Implement graceful shutdown
- [ ] Add API gateway (Envoy/Kong)

---

## Next Steps

1. **Implement API Gateway**: Add REST API gateway using gRPC-Gateway
2. **Add Authentication Middleware**: Implement JWT validation interceptor
3. **Kubernetes Deployment**: Create K8s manifests with auto-scaling
4. **CI/CD Pipeline**: Set up automated testing and deployment
5. **Observability**: Integrate Prometheus, Grafana, and Jaeger

---

**Last Updated**: December 2, 2025  
**Version**: 1.0.0
