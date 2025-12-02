# Agrios Services Cookbook

This cookbook contains standard commands and procedures for working with the Agrios microservices platform, including database operations, service management, and development workflows.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Environment Setup](#environment-setup)
- [Docker Operations](#docker-operations)
- [Database Operations](#database-operations)
- [Service Operations](#service-operations)
- [Development Workflows](#development-workflows)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Tools

```bash
# Check installed versions
go version        # Go 1.21 or higher
docker --version  # Docker 20.10 or higher
docker compose version  # Docker Compose v2.0 or higher
psql --version    # PostgreSQL client 15 or higher
```

### Environment Variables

Create a `.env` file in the project root:

```bash
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=agrios

# Service Ports
GRPC_PORT_USER=50051
GRPC_PORT_ARTICLE=50052

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-in-production

# Service URLs
USER_SERVICE_ADDR=localhost:50051
```

---

## Environment Setup

### Initial Setup

```bash
# Clone repository
git clone https://github.com/thatlq1812/agrios.git
cd agrios

# Create .env file
cp .env.example .env  # or create manually

# Install Go dependencies (root level)
go mod download

# Install dependencies for each service
cd service-1-user && go mod tidy && go mod vendor
cd ../service-2-article && go mod tidy && go mod vendor
cd ..
```

### Verify Setup

```bash
# Check Go modules
go mod verify

# Verify Docker Compose configuration
docker compose config
```

---

## Docker Operations

### Basic Docker Commands

```bash
# Start all services
docker compose up -d

# Start specific service
docker compose up -d postgres
docker compose up -d user-service
docker compose up -d article-service

# View logs
docker compose logs -f                    # All services
docker compose logs -f user-service       # Specific service
docker compose logs -f --tail=100 postgres  # Last 100 lines

# Stop services
docker compose stop                       # Stop all
docker compose stop user-service          # Stop specific service

# Restart services
docker compose restart                    # Restart all
docker compose restart user-service       # Restart specific service

# Remove containers
docker compose down                       # Stop and remove
docker compose down -v                    # Stop, remove, and delete volumes
```

### Build and Rebuild

```bash
# Build all services
docker compose build

# Build specific service
docker compose build user-service

# Rebuild without cache
docker compose build --no-cache

# Build and start
docker compose up -d --build
```

### Container Management

```bash
# List running containers
docker compose ps

# Execute command in container
docker compose exec postgres psql -U postgres -d agrios
docker compose exec user-service sh
docker compose exec article-service sh

# View resource usage
docker compose stats

# Inspect service
docker compose inspect user-service
```

---

## Database Operations

### Access Database

```bash
# Connect to PostgreSQL via Docker
docker compose exec postgres psql -U postgres -d agrios

# Connect to PostgreSQL via local client
psql -h localhost -p 5432 -U postgres -d agrios

# Connect to specific database
psql -h localhost -p 5432 -U postgres -d agrios -c "SELECT version();"
```

### Database Management

```bash
# Create database (if not exists)
docker compose exec postgres psql -U postgres -c "CREATE DATABASE agrios;"

# Drop database (CAUTION: data loss)
docker compose exec postgres psql -U postgres -c "DROP DATABASE IF EXISTS agrios;"

# List databases
docker compose exec postgres psql -U postgres -c "\l"

# List tables
docker compose exec postgres psql -U postgres -d agrios -c "\dt"

# Describe table structure
docker compose exec postgres psql -U postgres -d agrios -c "\d users"
docker compose exec postgres psql -U postgres -d agrios -c "\d articles"
```

### Run Migrations

```bash
# Apply User Service migrations
docker compose exec postgres psql -U postgres -d agrios -f /docker-entrypoint-initdb.d/001_create_users_table.sql

# Manual migration via Docker
docker compose exec postgres psql -U postgres -d agrios < service-1-user/migrations/001_create_users_table.sql

# Manual migration via local client
psql -h localhost -p 5432 -U postgres -d agrios -f service-1-user/migrations/001_create_users_table.sql
psql -h localhost -p 5432 -U postgres -d agrios -f service-2-article/migrations/001_create_articles_table.sql
```

### Database Queries

```bash
# Count records
docker compose exec postgres psql -U postgres -d agrios -c "SELECT COUNT(*) FROM users;"
docker compose exec postgres psql -U postgres -d agrios -c "SELECT COUNT(*) FROM articles;"

# View recent records
docker compose exec postgres psql -U postgres -d agrios -c "SELECT * FROM users ORDER BY created_at DESC LIMIT 10;"
docker compose exec postgres psql -U postgres -d agrios -c "SELECT * FROM articles ORDER BY created_at DESC LIMIT 10;"

# Find specific user
docker compose exec postgres psql -U postgres -d agrios -c "SELECT * FROM users WHERE email='test@example.com';"

# View articles by user
docker compose exec postgres psql -U postgres -d agrios -c "SELECT a.*, u.email FROM articles a JOIN users u ON a.user_id = u.id WHERE u.email='test@example.com';"
```

### Database Backup and Restore

```bash
# Backup database
docker compose exec postgres pg_dump -U postgres agrios > backup_$(date +%Y%m%d_%H%M%S).sql

# Backup specific table
docker compose exec postgres pg_dump -U postgres -t users agrios > users_backup.sql

# Restore database
docker compose exec -T postgres psql -U postgres agrios < backup_20231201_120000.sql

# Restore from SQL file
cat backup.sql | docker compose exec -T postgres psql -U postgres agrios
```

### PgAdmin Access

```bash
# Access PgAdmin web interface
# URL: http://localhost:5050
# Email: admin@admin.com
# Password: admin

# Add server in PgAdmin:
# Name: Agrios
# Host: postgres (use container name)
# Port: 5432
# Username: postgres
# Password: postgres
```

---

## Service Operations

### User Service (gRPC Port: 50051)

#### Development Mode

```bash
# Navigate to service directory
cd service-1-user

# Run service locally
go run cmd/server/main.go

# Build binary
go build -o bin/user-service cmd/server/main.go

# Run built binary
./bin/user-service

# With environment variables
DB_HOST=localhost DB_PORT=5432 DB_USER=postgres DB_PASSWORD=postgres DB_NAME=agrios GRPC_PORT=50051 go run cmd/server/main.go
```

#### Production Mode

```bash
# Build and run via Docker
docker compose up -d user-service

# View logs
docker compose logs -f user-service

# Restart service
docker compose restart user-service

# Check health
docker compose exec user-service nc -z localhost 50051
```

#### Testing User Service

```bash
# Install grpcurl (if not installed)
go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest

# List services
grpcurl -plaintext localhost:50051 list

# List methods
grpcurl -plaintext localhost:50051 list user.UserService

# Call CreateUser
grpcurl -plaintext -d '{"name":"John Doe","email":"john@example.com","password":"securepass123"}' localhost:50051 user.UserService/CreateUser

# Call GetUser
grpcurl -plaintext -d '{"id":1}' localhost:50051 user.UserService/GetUser

# Call UpdateUser
grpcurl -plaintext -d '{"id":1,"name":"John Updated","email":"john@example.com"}' localhost:50051 user.UserService/UpdateUser

# Call DeleteUser
grpcurl -plaintext -d '{"id":1}' localhost:50051 user.UserService/DeleteUser

# Call ListUsers
grpcurl -plaintext -d '{}' localhost:50051 user.UserService/ListUsers

# Call Login
grpcurl -plaintext -d '{"email":"john@example.com","password":"securepass123"}' localhost:50051 user.UserService/Login

# Call ValidateToken
grpcurl -plaintext -d '{"token":"your-jwt-token-here"}' localhost:50051 user.UserService/ValidateToken

# Call Logout
grpcurl -plaintext -d '{"token":"your-jwt-token-here"}' localhost:50051 user.UserService/Logout
```

### Article Service (gRPC Port: 50052)

#### Development Mode

```bash
# Navigate to service directory
cd service-2-article

# Run service locally
go run cmd/server/main.go

# Build binary
go build -o bin/article-service cmd/server/main.go

# Run built binary
./bin/article-service

# With environment variables
DB_HOST=localhost DB_PORT=5432 DB_USER=postgres DB_PASSWORD=postgres DB_NAME=agrios GRPC_PORT=50052 USER_SERVICE_ADDR=localhost:50051 go run cmd/server/main.go
```

#### Production Mode

```bash
# Build and run via Docker
docker compose up -d article-service

# View logs
docker compose logs -f article-service

# Restart service
docker compose restart article-service

# Check health
docker compose exec article-service nc -z localhost 50052
```

#### Testing Article Service

```bash
# List services
grpcurl -plaintext localhost:50052 list

# List methods
grpcurl -plaintext localhost:50052 list article.ArticleService

# Call CreateArticle
grpcurl -plaintext -d '{"user_id":1,"title":"My First Article","content":"This is the content of my first article."}' localhost:50052 article.ArticleService/CreateArticle

# Call GetArticle
grpcurl -plaintext -d '{"id":1}' localhost:50052 article.ArticleService/GetArticle

# Call UpdateArticle
grpcurl -plaintext -d '{"id":1,"title":"Updated Article","content":"Updated content"}' localhost:50052 article.ArticleService/UpdateArticle

# Call DeleteArticle
grpcurl -plaintext -d '{"id":1}' localhost:50052 article.ArticleService/DeleteArticle

# Call ListArticles
grpcurl -plaintext -d '{"page_size":10,"page_number":1}' localhost:50052 article.ArticleService/ListArticles

# Call ListArticles filtered by user
grpcurl -plaintext -d '{"user_id":1,"page_size":10,"page_number":1}' localhost:50052 article.ArticleService/ListArticles
```

---

## Development Workflows

### Code Generation

```bash
# Generate protobuf code for User Service
cd service-1-user
protoc --go_out=. --go-grpc_out=. proto/user_service.proto

# Generate protobuf code for Article Service
cd service-2-article
protoc --go_out=. --go-grpc_out=. proto/article_service.proto proto/user_service.proto
```

### Dependency Management

```bash
# Update dependencies
go get -u ./...
go mod tidy

# Vendor dependencies
go mod vendor

# Clean module cache
go clean -modcache

# Verify dependencies
go mod verify
```

### Code Quality

```bash
# Format code
go fmt ./...
gofmt -w .

# Lint code (requires golangci-lint)
golangci-lint run

# Vet code
go vet ./...

# Run tests
go test ./...
go test -v ./...
go test -cover ./...
```

---

## Testing

### Unit Tests

```bash
# Run all tests
go test ./...

# Run tests with verbose output
go test -v ./...

# Run tests with coverage
go test -cover ./...
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out

# Run specific package tests
go test ./internal/repository/...
go test ./internal/server/...

# Run specific test
go test -v -run TestCreateUser ./internal/repository
```

### Integration Tests

```bash
# Start dependencies
docker compose up -d postgres

# Wait for database to be ready
sleep 5

# Run migrations
psql -h localhost -p 5432 -U postgres -d agrios -f service-1-user/migrations/001_create_users_table.sql
psql -h localhost -p 5432 -U postgres -d agrios -f service-2-article/migrations/001_create_articles_table.sql

# Run integration tests
go test -tags=integration ./...
```

### Load Testing

```bash
# Install ghz (gRPC load testing tool)
go install github.com/bojand/ghz/cmd/ghz@latest

# Load test User Service
ghz --insecure --proto service-1-user/proto/user_service.proto --call user.UserService/ListUsers -d '{}' -n 1000 -c 10 localhost:50051

# Load test Article Service
ghz --insecure --proto service-2-article/proto/article_service.proto --call article.ArticleService/ListArticles -d '{"page_size":10,"page_number":1}' -n 1000 -c 10 localhost:50052
```

---

## Troubleshooting

### Common Issues

#### Service won't start

```bash
# Check if port is already in use
netstat -ano | findstr :50051
netstat -ano | findstr :50052

# Kill process using port (Windows - Git Bash)
cmd //c taskkill //PID <process_id> //F

# Kill process using port (Windows - PowerShell)
Stop-Process -Id <process_id> -Force

# Check service logs
docker compose logs user-service
docker compose logs article-service

# Check if local Go services are running and conflicting
netstat -ano | findstr :5005
```

#### Database connection issues

```bash
# Check if PostgreSQL is running
docker compose ps postgres

# Test database connection
psql -h localhost -p 5432 -U postgres -d agrios -c "SELECT 1;"

# Check database logs
docker compose logs postgres

# Restart database
docker compose restart postgres
```

#### Migration failures

```bash
# Check current database state
docker compose exec postgres psql -U postgres -d agrios -c "\dt"

# Drop and recreate tables
docker compose exec postgres psql -U postgres -d agrios -c "DROP TABLE IF EXISTS users CASCADE;"
docker compose exec postgres psql -U postgres -d agrios -c "DROP TABLE IF EXISTS articles CASCADE;"

# Reapply migrations
psql -h localhost -p 5432 -U postgres -d agrios -f service-1-user/migrations/001_create_users_table.sql
psql -h localhost -p 5432 -U postgres -d agrios -f service-2-article/migrations/001_create_articles_table.sql
```

#### gRPC connection errors

```bash
# Test gRPC connectivity
grpcurl -plaintext localhost:50051 list
grpcurl -plaintext localhost:50052 list

# Common error: "target server does not expose service"
# This means you're using wrong service name
# Check actual service names with:
grpcurl -plaintext localhost:50051 list
# Use the correct package.Service format (e.g., user.UserService not user_service.UserService)

# Enable gRPC reflection (check main.go)
# reflection.Register(grpcServer)

# Check service health
docker compose exec user-service nc -z localhost 50051
docker compose exec article-service nc -z localhost 50052

# Check inter-service communication
docker compose exec article-service nc -zv user-service 50051
```

#### User/Data not found errors

```bash
# Error: "user with ID X not found"
# This usually means you're testing with wrong user ID or empty database

# 1. Check if users exist
docker compose exec postgres psql -U postgres -d agrios -c "SELECT id, name, email FROM users;"

# 2. If empty, create a user via gRPC
grpcurl -plaintext -d '{"name":"Test User","email":"test@example.com","password":"password123"}' localhost:50051 user.UserService/CreateUser

# 3. Use the returned user ID for article operations
grpcurl -plaintext -d '{"user_id":1,"title":"Test Article","content":"Content here"}' localhost:50052 article.ArticleService/CreateArticle

# 4. Verify data
docker compose exec postgres psql -U postgres -d agrios -c "SELECT COUNT(*) FROM users;"
docker compose exec postgres psql -U postgres -d agrios -c "SELECT COUNT(*) FROM articles;"
```

#### Proto file synchronization issues

```bash
# If article service can't communicate with user service correctly:
# Ensure proto files are in sync between services

# 1. Check if proto files match
diff service-1-user/proto/user_service.proto service-2-article/proto/user_service.proto

# 2. If different, copy the correct version
cp service-1-user/proto/user_service.proto service-2-article/proto/

# 3. Regenerate proto code (from service directory)
cd service-2-article
rm proto/user_service.pb.go proto/user_service_grpc.pb.go
protoc --proto_path=proto --go_out=. --go_opt=paths=source_relative --go-grpc_out=. --go-grpc_opt=paths=source_relative proto/user_service.proto
mv user_service*.pb.go proto/

# 4. Rebuild and restart
docker compose build article-service
docker compose restart article-service
```

### Debug Mode

```bash
# Run service with debug logging
GRPC_GO_LOG_VERBOSITY_LEVEL=99 GRPC_GO_LOG_SEVERITY_LEVEL=info go run cmd/server/main.go

# Enable PostgreSQL query logging
docker compose exec postgres psql -U postgres -c "ALTER SYSTEM SET log_statement = 'all';"
docker compose exec postgres psql -U postgres -c "SELECT pg_reload_conf();"

# View slow queries
docker compose exec postgres psql -U postgres -d agrios -c "SELECT * FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 10;"
```

### Reset Everything

```bash
# Stop all services
docker compose down

# Remove all volumes (CAUTION: data loss)
docker compose down -v

# Remove all containers and images
docker compose down --rmi all -v

# Clean up Go cache
go clean -cache -modcache -testcache

# Start fresh
docker compose up -d --build
```

---

## Performance Monitoring

### Database Performance

```bash
# Check active connections
docker compose exec postgres psql -U postgres -d agrios -c "SELECT count(*) FROM pg_stat_activity WHERE state = 'active';"

# View table sizes
docker compose exec postgres psql -U postgres -d agrios -c "SELECT relname, pg_size_pretty(pg_total_relation_size(relid)) FROM pg_catalog.pg_statio_user_tables ORDER BY pg_total_relation_size(relid) DESC;"

# Check index usage
docker compose exec postgres psql -U postgres -d agrios -c "SELECT schemaname, tablename, indexname, idx_scan FROM pg_stat_user_indexes ORDER BY idx_scan DESC;"

# View cache hit ratio
docker compose exec postgres psql -U postgres -d agrios -c "SELECT sum(heap_blks_read) as heap_read, sum(heap_blks_hit) as heap_hit, sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)) as ratio FROM pg_statio_user_tables;"
```

### Service Monitoring

```bash
# Check service resource usage
docker stats agrios-user-service agrios-article-service

# Monitor gRPC requests (requires prometheus metrics)
curl http://localhost:9090/metrics

# Check service health endpoints
curl http://localhost:50051/health
curl http://localhost:50052/health
```

---

## Quick Reference

### Most Used Commands

```bash
# Start everything
docker compose up -d

# View all logs
docker compose logs -f

# Access database
docker compose exec postgres psql -U postgres -d agrios

# List available services
grpcurl -plaintext localhost:50051 list  # User Service
grpcurl -plaintext localhost:50052 list  # Article Service

# Create test user
grpcurl -plaintext -d '{"name":"Test User","email":"test@example.com","password":"password123"}' localhost:50051 user.UserService/CreateUser

# Create test article (use returned user ID)
grpcurl -plaintext -d '{"user_id":1,"title":"Test Article","content":"Test content"}' localhost:50052 article.ArticleService/CreateArticle

# Restart services
docker compose restart

# Stop everything
docker compose down
```

### Common Workflow Example

```bash
# 1. Start all services
docker compose up -d

# 2. Wait for services to be ready
sleep 5

# 3. Apply migrations (if needed)
docker compose exec -T postgres psql -U postgres -d agrios < service-1-user/migrations/001_create_users_table.sql
docker compose exec -T postgres psql -U postgres -d agrios < service-2-article/migrations/001_create_articles_table.sql

# 4. Create a test user
grpcurl -plaintext -d '{"name":"John Doe","email":"john@example.com","password":"securepass123"}' localhost:50051 user.UserService/CreateUser
# Note the returned user ID (e.g., 1)

# 5. Login
grpcurl -plaintext -d '{"email":"john@example.com","password":"securepass123"}' localhost:50051 user.UserService/Login
# Note the accessToken

# 6. Create article
grpcurl -plaintext -d '{"user_id":1,"title":"My Article","content":"Article content here"}' localhost:50052 article.ArticleService/CreateArticle

# 7. Get article with user info
grpcurl -plaintext -d '{"id":1}' localhost:50052 article.ArticleService/GetArticle

# 8. List all articles
grpcurl -plaintext -d '{"page_size":10,"page_number":1}' localhost:50052 article.ArticleService/ListArticles
```

### Environment-Specific Commands

#### Local Development

```bash
cd service-1-user && go run cmd/server/main.go
cd service-2-article && go run cmd/server/main.go
```

#### Docker Development

```bash
docker compose up -d
docker compose logs -f
```

#### Production Deployment

See `DOCKER_DEPLOYMENT.md` for full production deployment instructions.

---

## Additional Resources

- [Docker Deployment Guide](DOCKER_DEPLOYMENT.md)
- [Refactoring Report](REFACTORING_REPORT.md)
- [gRPC Documentation](https://grpc.io/docs/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Go Documentation](https://golang.org/doc/)

---

**Last Updated:** December 2, 2025
