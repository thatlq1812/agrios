# Deployment Guide - Agrios Microservices

> Complete guide to deploy Agrios from scratch on any machine

## Prerequisites

### Required Software

```bash
# Check if installed
docker --version          # Required: 20.10+
docker-compose --version  # Required: 1.29+
git --version            # Required: 2.0+

# Optional for local development
go version               # Optional: 1.21+
psql --version          # Optional: PostgreSQL 13+
redis-cli --version     # Optional: Redis 6+
```

### Installation Links

- **Docker Desktop**: https://www.docker.com/products/docker-desktop
- **Git**: https://git-scm.com/downloads
- **Go** (optional): https://go.dev/dl/

---

## Quick Start (Docker - Recommended)

### Step 1: Clone Repository

```bash
# Clone project
git clone https://github.com/thatlq1812/agrios.git
cd agrios
```

### Step 2: Configure Environment

```bash
# Copy environment files
cp service-1-user/.env.example service-1-user/.env
cp service-2-article/.env.example service-2-article/.env

# Edit if needed (optional - defaults work fine)
# nano service-1-user/.env
```

### Step 3: Start All Services

```bash
# Build and start all services
docker-compose up -d

# Wait 10-15 seconds for services to be ready
sleep 15
```

### Step 4: Initialize Services

```bash
# Run initialization script
bash scripts/init-services.sh

# Or manually run migrations:
# docker exec agrios-user-service sh -c "cd /app && go run cmd/server/main.go migrate"
# docker exec agrios-article-service sh -c "cd /app && go run cmd/server/main.go migrate"
```

### Step 5: Verify Services

```bash
# Check running containers
docker-compose ps

# Expected output:
# agrios-postgres        Up
# agrios-redis           Up  
# agrios-user-service    Up
# agrios-article-service Up
# agrios-gateway         Up
# agrios-pgadmin         Up (optional)

# Test gateway health
curl http://localhost:8080/health
# Expected: {"status":"ok"}
```

### Step 6: Test APIs

```bash
# Register new user
curl -X POST http://localhost:8080/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","password":"password123"}'

# Expected response:
# {
#   "code": "000",
#   "message": "User created successfully",
#   "data": {
#     "id": 1,
#     "name": "Test User",
#     "email": "test@example.com"
#   }
# }

# Login to get token
curl -X POST http://localhost:8080/api/v1/users/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Expected response includes access_token
# Copy the token for next requests
```

**Done! System is ready to use.**

---

## Alternative: Local Development Setup

### Step 1: Install Dependencies

```bash
# Install PostgreSQL
# Windows: Download from postgresql.org
# Mac: brew install postgresql
# Linux: sudo apt install postgresql

# Install Redis
# Windows: Download from redis.io
# Mac: brew install redis
# Linux: sudo apt install redis-server

# Install Go
# Download from go.dev/dl/ (version 1.21+)
```

### Step 2: Start Databases

```bash
# Start PostgreSQL (Windows - as service)
net start postgresql-x64-13

# Start Redis
redis-server

# Or use Docker for databases only
docker run -d --name postgres -p 5432:5432 \
  -e POSTGRES_PASSWORD=postgres postgres:15
  
docker run -d --name redis -p 6379:6379 redis:alpine
```

### Step 3: Setup Environment

```bash
# service-1-user/.env
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=agrios_user
REDIS_ADDR=localhost:6379
REDIS_PASSWORD=
JWT_SECRET=your-secret-key-change-in-production
JWT_EXPIRE_MINUTES=60
GRPC_PORT=50051

# service-2-article/.env  
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=agrios_article
REDIS_ADDR=localhost:6379
REDIS_PASSWORD=
USER_SERVICE_ADDR=localhost:50051
GRPC_PORT=50052

# service-gateway/.env
USER_SERVICE_ADDR=localhost:50051
ARTICLE_SERVICE_ADDR=localhost:50052
HTTP_PORT=8080
```

### Step 4: Create Databases

```bash
# Connect to PostgreSQL
psql -U postgres

# Create databases
CREATE DATABASE agrios_user;
CREATE DATABASE agrios_article;
\q
```

### Step 5: Run Migrations

```bash
# User Service
cd service-1-user
psql -U postgres -d agrios_user -f migrations/001_create_users_table.sql

# Article Service
cd ../service-2-article
psql -U postgres -d agrios_article -f migrations/001_create_articles_table.sql
```

### Step 6: Install Go Dependencies

```bash
# User Service
cd service-1-user
go mod download
go mod vendor

# Article Service
cd ../service-2-article
go mod download
go mod vendor

# Gateway
cd ../service-gateway
go mod download
go mod vendor
```

### Step 7: Start Services

```bash
# Terminal 1 - User Service
cd service-1-user
go run cmd/server/main.go
# Output: gRPC server listening on :50051

# Terminal 2 - Article Service
cd service-2-article
go run cmd/server/main.go
# Output: gRPC server listening on :50052

# Terminal 3 - Gateway
cd service-gateway
go run cmd/server/main.go
# Output: HTTP server listening on :8080
```

### Step 8: Test

```bash
# Same as Docker step 6
curl -X POST http://localhost:8080/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@example.com","password":"password123"}'
```

---

## Troubleshooting

### Port Already in Use

```bash
# Check what's using port (Windows)
netstat -ano | findstr :8080
netstat -ano | findstr :50051

# Kill process (Windows)
taskkill /PID <process_id> /F

# Check port (Linux/Mac)
lsof -i :8080
kill -9 <PID>

# Or change port in .env files
```

### Database Connection Failed

```bash
# Check PostgreSQL is running
docker ps | grep postgres

# Or Windows service
net start postgresql-x64-13

# Test connection
psql -U postgres -h localhost

# Check credentials in .env files
```

### Services Won't Start

```bash
# Check logs
docker-compose logs -f user-service
docker-compose logs -f article-service
docker-compose logs -f gateway

# Common issues:
# 1. Missing .env files → Copy from .env.example
# 2. Database not ready → Wait 15 seconds after docker-compose up
# 3. Port conflicts → Change ports in .env
# 4. Migration not run → Run scripts/init-services.sh
```

### Redis Connection Error

```bash
# Check Redis is running
docker ps | grep redis

# Test connection
redis-cli ping
# Expected: PONG

# If password protected
redis-cli -a <password> ping
```

### Docker Build Fails

```bash
# Clean build
docker-compose down -v
docker system prune -a

# Rebuild
docker-compose build --no-cache
docker-compose up -d
```

### Clean Start

```bash
# Stop and remove everything
docker-compose down -v

# Remove old data
rm -rf postgres_data redis_data

# Start fresh
docker-compose up -d
sleep 15
bash scripts/init-services.sh
```

### gRPC Connection Refused

```bash
# Check services are running
docker-compose ps

# Check service logs
docker logs agrios-user-service
docker logs agrios-article-service

# Verify ports in .env files match docker-compose.yml
```

---

## Production Considerations

### Security

```bash
# Generate strong JWT secret
openssl rand -base64 32

# Update all .env files with production values
JWT_SECRET=<generated-secret>
DB_PASSWORD=<strong-password>
REDIS_PASSWORD=<strong-password>

# Never commit .env files
# Use .env.example as template only
```

### Environment Variables

```bash
# Production checklist:
✓ Strong JWT_SECRET (32+ characters)
✓ Strong database passwords
✓ Redis password enabled
✓ Disable debug mode
✓ Set proper CORS origins
✓ Use HTTPS in production
✓ Set rate limiting

# Use secrets management in production
# Examples: AWS Secrets Manager, HashiCorp Vault, Azure Key Vault
```

### Database Backups

```bash
# Backup PostgreSQL
docker exec agrios-postgres pg_dumpall -U postgres > backup.sql

# Restore
cat backup.sql | docker exec -i agrios-postgres psql -U postgres

# Automated backups
# Add to crontab:
# 0 2 * * * cd /path/to/agrios && docker exec agrios-postgres pg_dumpall -U postgres > backup_$(date +\%Y\%m\%d).sql
```

### Monitoring

```bash
# Health checks
curl http://localhost:8080/health

# Service metrics
docker stats

# Logs
docker-compose logs -f --tail=100

# Database monitoring
docker exec -it agrios-postgres psql -U postgres

# Redis monitoring
docker exec -it agrios-redis redis-cli INFO
```

### Scaling

```bash
# Scale services
docker-compose up -d --scale user-service=3
docker-compose up -d --scale article-service=3

# Load balancer required for multiple instances
# Consider: Nginx, Traefik, or cloud load balancers
```

---

## Quick Commands Reference

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f gateway
docker-compose logs -f user-service

# Restart service
docker-compose restart user-service

# Rebuild and start
docker-compose up -d --build

# Run migrations
bash scripts/init-services.sh

# Access database
docker exec -it agrios-postgres psql -U postgres -d agrios_user

# Access Redis
docker exec -it agrios-redis redis-cli

# Clean everything
docker-compose down -v
docker system prune -a

# Check service health
curl http://localhost:8080/health
```

---

## Testing APIs

### Using cURL

See examples in Step 6 above or check:
- [COMPLETE_GUIDE.md](./COMPLETE_GUIDE.md#api-documentation)

### Using grpcurl

Install grpcurl first:
```bash
# Mac
brew install grpcurl

# Windows
# Download from: https://github.com/fullstorydev/grpcurl/releases

# Linux
go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest
```

Test gRPC services directly:
```bash
# List services
grpcurl -plaintext localhost:50051 list
grpcurl -plaintext localhost:50052 list

# For detailed examples, see:
# docs/GRPC_COMMANDS.md
```

---

## Next Steps

After successful deployment:

1. **Read API Documentation**: [COMPLETE_GUIDE.md](./COMPLETE_GUIDE.md#api-documentation)
2. **Test with gRPC**: [GRPC_COMMANDS.md](./GRPC_COMMANDS.md)
3. **Understand Architecture**: [ARCHITECTURE_GUIDE.md](./ARCHITECTURE_GUIDE.md)
4. **Development Workflow**: [tutorials/WORKFLOW_GUIDE.md](./tutorials/WORKFLOW_GUIDE.md)
5. **JWT & Redis**: [tutorials/JWT_BLACKLIST_REDIS.md](./tutorials/JWT_BLACKLIST_REDIS.md)

---

## Common Workflows

### Add New User

```bash
curl -X POST http://localhost:8080/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com","password":"secure123"}'
```

### Login and Get Token

```bash
curl -X POST http://localhost:8080/api/v1/users/login \
  -H "Content-Type: application/json" \
  -d '{"email":"john@example.com","password":"secure123"}'

# Save token
export TOKEN="<access_token_from_response>"
```

### Create Article (Authenticated)

```bash
curl -X POST http://localhost:8080/api/v1/articles \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"My Article","content":"Article content here..."}'
```

### Get All Articles

```bash
curl http://localhost:8080/api/v1/articles
```

---

## Support

- **Issues**: Check logs first with `docker-compose logs -f`
- **Questions**: Review [COMPLETE_GUIDE.md](./COMPLETE_GUIDE.md)
- **Bug Reports**: Include logs and steps to reproduce
- **Architecture Questions**: See [ARCHITECTURE_GUIDE.md](./ARCHITECTURE_GUIDE.md)

---

## Changelog

See [CHANGELOG.md](../CHANGELOG.md) for version history and updates.
