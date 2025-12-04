# Agrios Microservices - Operations Guide

**Last Updated:** December 3, 2025  
**Version:** 1.0

This guide provides comprehensive instructions for deploying, operating, and managing the Agrios microservices system consisting of User Service and Article Service.

---

## Table of Contents

1. [System Architecture](#system-architecture)
2. [Prerequisites](#prerequisites)
3. [Environment Setup](#environment-setup)
4. [Database Setup](#database-setup)
5. [Running Services Locally](#running-services-locally)
6. [Docker Deployment](#docker-deployment)
7. [Testing APIs](#testing-apis)
8. [Data Operations](#data-operations)
9. [Troubleshooting](#troubleshooting)
10. [Monitoring and Maintenance](#monitoring-and-maintenance)

---

## System Architecture

### Services Overview

```
┌─────────────────┐         ┌──────────────────┐
│  User Service   │◄────────┤ Article Service  │
│    (gRPC)       │         │     (gRPC)       │
│   Port: 50051   │         │   Port: 50052    │
└────────┬────────┘         └────────┬─────────┘
         │                           │
         ├──────────┬────────────────┤
         │          │                │
    ┌────▼───┐   ┌──▼────┐       ┌───▼────┐
    │ Redis  │   │ Users │       │Articles│
    │ :6379  │   │  DB   │       │   DB   │
    └────────┘   └───────┘       └────────┘
                PostgreSQL
```

### Components

- **User Service (service-1-user)**: Handles user authentication, registration, and user management
  - JWT token generation and validation
  - Token blacklisting with Redis
  - User CRUD operations
  
- **Article Service (service-2-article)**: Manages articles with user integration
  - Article CRUD operations
  - Integrates with User Service to fetch user information
  - Graceful degradation when User Service is unavailable

- **PostgreSQL**: Relational database for persistent storage
  - `agrios_users`: User data
  - `agrios_articles`: Article data

- **Redis**: In-memory cache for token blacklisting and session management

---

## Prerequisites

### Required Software

- **Go**: Version 1.21 or higher
- **PostgreSQL**: Version 13 or higher
- **Redis**: Version 6 or higher
- **Docker & Docker Compose**: For containerized deployment
- **Git**: For version control

### Optional Tools

- **grpcurl**: For testing gRPC APIs
- **PgAdmin**: Database management UI
- **Postman**: API testing (with gRPC support)

### Installation Commands

```bash
# Install Go (Windows - using Chocolatey)
choco install golang

# Install PostgreSQL
choco install postgresql

# Install Redis (or use Docker)
docker pull redis:alpine

# Install grpcurl
go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest
```

---

## Environment Setup

### 1. Clone Repository

```bash
cd d:\
git clone <repository-url> agrios
cd agrios
```

### 2. Configure Environment Variables

#### User Service (.env)

Create `service-1-user/.env`:

```env
# Database Configuration
DB_HOST=127.0.0.1
DB_PORT=5432
DB_USER=agrios
DB_PASSWORD=agrios123
DB_NAME=agrios_users

# Connection Pool Settings
DB_MAX_CONNS=10
DB_MIN_CONNS=2
DB_MAX_CONN_LIFETIME=1h
DB_MAX_CONN_IDLE_TIME=30m
DB_CONNECT_TIMEOUT=5s

# JWT Configuration
JWT_SECRET=JCnk0Rlhh23uuDAunpeDtW2uHUqKF//jNBwNDM0KxtE=
ACCESS_TOKEN_DURATION=15m
REFRESH_TOKEN_DURATION=7d

# Redis Configuration
REDIS_ADDR=localhost:6379
REDIS_PASSWORD=
REDIS_DB=0

# Server Configuration
GRPC_PORT=50051
SHUTDOWN_TIMEOUT=10s
```

#### Article Service (.env)

Create `service-2-article/.env`:

```env
# Database Configuration
DB_HOST=127.0.0.1
DB_PORT=5432
DB_USER=agrios
DB_PASSWORD=agrios123
DB_NAME=agrios_articles

# Connection Pool Settings
DB_MAX_CONNS=10
DB_MIN_CONNS=2
DB_MAX_CONN_LIFETIME=1h
DB_MAX_CONN_IDLE_TIME=30m
DB_CONNECT_TIMEOUT=5s

# Server Configuration
GRPC_PORT=50052
USER_SERVICE_ADDR=localhost:50051
SHUTDOWN_TIMEOUT=10s
```

---

## Database Setup

### 1. Start PostgreSQL

#### Windows (if installed as service):

```bash
# Start PostgreSQL service
net start postgresql-x64-18

# Or use Services Manager
services.msc
```

#### Using Docker:

```bash
docker run -d \
  --name postgres \
  -e POSTGRES_USER=agrios \
  -e POSTGRES_PASSWORD=agrios123 \
  -p 5432:5432 \
  postgres:13-alpine
```

### 2. Create Databases

```bash
# Add PostgreSQL to PATH (adjust version number)
export PATH=$PATH:"/c/Program Files/PostgreSQL/18/bin"

# Connect to PostgreSQL
psql -U postgres

# Create user and databases
CREATE USER agrios WITH PASSWORD 'agrios123';
CREATE DATABASE agrios_users OWNER agrios;
CREATE DATABASE agrios_articles OWNER agrios;

# Grant privileges
GRANT ALL PRIVILEGES ON DATABASE agrios_users TO agrios;
GRANT ALL PRIVILEGES ON DATABASE agrios_articles TO agrios;

\q
```

### 3. Run Migrations

#### User Service:

```bash
cd d:\agrios\service-1-user

psql -U agrios -d agrios_users -f migrations/001_create_users_table.sql
```

#### Article Service:

```bash
cd d:\agrios\service-2-article

psql -U agrios -d agrios_articles -f migrations/001_create_articles_table.sql
```

### 4. Verify Tables

```bash
# Check users table
psql -U agrios -d agrios_users -c "\dt"
psql -U agrios -d agrios_users -c "\d users"

# Check articles table
psql -U agrios -d agrios_articles -c "\dt"
psql -U agrios -d agrios_articles -c "\d articles"
```

### 5. Start Redis

```bash
# Using Docker
docker run -d --name redis -p 6379:6379 redis:alpine

# Verify Redis is running
docker exec -it redis redis-cli ping
# Should return: PONG
```

---

## Running Services Locally

### Build Services

```bash
# Build User Service
cd d:\agrios\service-1-user
go mod tidy
go build -o bin/user-service cmd/server/main.go

# Build Article Service
cd d:\agrios\service-2-article
go mod tidy
go build -o bin/article-service cmd/server/main.go
```

### Start Services

Open separate terminal windows for each service:

#### Terminal 1 - User Service:

```bash
cd d:\agrios\service-1-user
./bin/user-service
```

Expected output:
```
Connected to Redis successfully
Connected to PostgreSQL successfully
User Service (gRPC) listening on port 50051
```

#### Terminal 2 - Article Service:

```bash
cd d:\agrios\service-2-article
./bin/article-service
```

Expected output:
```
Connected to PostgreSQL successfully
Connected to User Service at localhost:50051
Article Service (gRPC) listening on port 50052
```

### Stop Services

Press `Ctrl+C` in each terminal. Services will perform graceful shutdown.

---

## Docker Deployment

### Using Docker Compose (Recommended)

Docker Compose starts all services together with proper networking and dependencies.

#### 1. Build and Start All Services

```bash
cd d:\agrios

# Start all services in background
docker-compose up -d --build

# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f user-service
docker-compose logs -f article-service
```

#### 2. Verify Services

```bash
# Check running containers
docker-compose ps

# Should show:
# - agrios-postgres (healthy)
# - agrios-redis (healthy)
# - agrios-user-service (running)
# - agrios-article-service (running)
# - agrios-pgadmin (running)
```

#### 3. Access PgAdmin

Open browser: `http://localhost:5050`

**Login:**
- Email: `admin@admin.com`
- Password: `admin`

**Add Server:**
- Name: `Agrios`
- Host: `postgres`
- Port: `5432`
- Username: `postgres`
- Password: `postgres`
- Database: `agrios`

#### 4. Stop Services

```bash
# Stop all services
docker-compose down

# Stop and remove volumes (WARNING: deletes all data)
docker-compose down -v
```

#### 5. Rebuild After Code Changes

```bash
# Rebuild specific service
docker-compose up -d --build user-service

# Rebuild all services
docker-compose up -d --build
```

---

## Testing APIs

### Using grpcurl

grpcurl is a command-line tool for interacting with gRPC servers.

#### List Available Services

```bash
# User Service
grpcurl -plaintext localhost:50051 list

# Article Service
grpcurl -plaintext localhost:50052 list
```

#### List Service Methods

```bash
grpcurl -plaintext localhost:50051 list user.UserService
```

### User Service API Examples

#### 1. Register User

```bash
grpcurl -plaintext -d '{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "securepassword123"
}' localhost:50051 user.UserService/CreateUser

```bash
grpcurl -plaintext -d '{
  "name": "That",
  "email": "jthat@example.com",
  "password": "securepassword123"
}' localhost:50051 user.UserService/CreateUser
```

```bash
grpcurl -plaintext -d '{
  "name": "John Doe",
  "email": "john3@example.com",
  "password": "securepassword123"
}' localhost:50051 user.UserService/CreateUser
```

Response:
```json
{
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "created_at": "2025-12-03T10:00:00Z",
    "updated_at": "2025-12-03T10:00:00Z"
  }
}
```

#### 2. Login

```bash
grpcurl -plaintext -d '{
  "email": "john3@example.com",
  "password": "securepassword123"
}' localhost:50051 user.UserService/Login

grpcurl -plaintext -d '{
  "email": "jthat@example.com",
  "password": "securepassword123"
}' localhost:50051 user.UserService/Login
```

Response:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com"
  }
}
```

#### 3. Validate Token

```bash
grpcurl -plaintext -d '{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}' localhost:50051 user.UserService/ValidateToken
```

#### 4. Get User

```bash
grpcurl -plaintext -d '{
  "id": 1
}' localhost:50051 user.UserService/GetUser
```

#### 5. List Users

```bash
grpcurl -plaintext -d '{
  "page": 1,
  "page_size": 10
}' localhost:50051 user.UserService/ListUsers
```

#### 6. Update User

```bash
grpcurl -plaintext -d '{
  "id": 1,
  "name": "John Updated",
  "email": "john.updated@example.com"
}' localhost:50051 user.UserService/UpdateUser
```

#### 7. Logout

```bash
grpcurl -plaintext -d '{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}' localhost:50051 user.UserService/Logout
```

#### 8. Delete User

```bash
grpcurl -plaintext -d '{
  "id": 1
}' localhost:50051 user.UserService/DeleteUser
```

### Article Service API Examples

#### 1. Create Article

```bash
grpcurl -plaintext -d '{
  "title": "My First Article",
  "content": "This is the content of my article",
  "user_id": 1
}' localhost:50052 article.ArticleService/CreateArticle
```

Response:
```json
{
  "article": {
    "id": 1,
    "title": "My First Article",
    "content": "This is the content of my article",
    "user_id": 1,
    "created_at": "2025-12-03T10:05:00Z",
    "updated_at": "2025-12-03T10:05:00Z"
  }
}
```

#### 2. Get Article with User Info

```bash
grpcurl -plaintext -d '{
  "id": 1
}' localhost:50052 article.ArticleService/GetArticleWithUser
```

Response includes article and user information:
```json
{
  "article": {
    "id": 1,
    "title": "My First Article",
    "content": "This is the content of my article",
    "user_id": 1
  },
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com"
  }
}
```

#### 3. List Articles by User

```bash
grpcurl -plaintext -d '{
  "user_id": 1,
  "page": 1,
  "page_size": 10
}' localhost:50052 article.ArticleService/ListArticlesByUser
```

#### 4. Update Article

```bash
grpcurl -plaintext -d '{
  "id": 1,
  "title": "Updated Title",
  "content": "Updated content"
}' localhost:50052 article.ArticleService/UpdateArticle
```

#### 5. Delete Article

```bash
grpcurl -plaintext -d '{
  "id": 1
}' localhost:50052 article.ArticleService/DeleteArticle
```

---

## Data Operations

### Bulk Data Loading

For testing purposes, you can bulk load data using Python scripts or SQL.

#### Method 1: Python Script for Bulk User Creation

Create `scripts/load_users.py`:

```python
import grpc
import csv
import sys
import os

# Add proto path
sys.path.append(os.path.join(os.path.dirname(__file__), '../service-1-user/proto'))

import user_service_pb2 as pb
import user_service_pb2_grpc as pb_grpc

def load_users_from_csv(csv_file, server_address='localhost:50051'):
    """Load users from CSV file into User Service"""
    channel = grpc.insecure_channel(server_address)
    stub = pb_grpc.UserServiceStub(channel)
    
    success_count = 0
    error_count = 0
    
    with open(csv_file, 'r', encoding='utf-8') as file:
        reader = csv.DictReader(file)
        for row in reader:
            request = pb.CreateUserRequest(
                name=row['name'],
                email=row['email'],
                password=row['password']
            )
            try:
                response = stub.CreateUser(request)
                print(f"✓ Created user: {response.user.name} (ID: {response.user.id})")
                success_count += 1
            except grpc.RpcError as e:
                print(f"✗ Error creating {row['email']}: {e.details()}")
                error_count += 1
    
    print(f"\nSummary: {success_count} success, {error_count} errors")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python load_users.py <csv_file>")
        sys.exit(1)
    
    load_users_from_csv(sys.argv[1])
```

**CSV Format** (`data/users.csv`):

```csv
name,email,password
John Doe,john@example.com,password123
Jane Smith,jane@example.com,password456
Bob Wilson,bob@example.com,password789
```

**Run:**

```bash
# Install dependencies
pip install grpcio grpcio-tools

# Generate Python proto files
cd service-1-user/proto
python -m grpc_tools.protoc -I. --python_out=. --grpc_python_out=. user_service.proto

# Load users
cd ../../scripts
python load_users.py ../data/users.csv
```

#### Method 2: Direct SQL Insert

```bash
# Load users directly
psql -U agrios -d agrios_users << EOF
INSERT INTO users (name, email, password_hash) VALUES
  ('John Doe', 'john@example.com', '$2a$10$hashedpassword1'),
  ('Jane Smith', 'jane@example.com', '$2a$10$hashedpassword2'),
  ('Bob Wilson', 'bob@example.com', '$2a$10$hashedpassword3');
EOF

# Load articles
psql -U agrios -d agrios_articles << EOF
INSERT INTO articles (user_id, title, content) VALUES
  (1, 'First Article', 'Content of first article'),
  (1, 'Second Article', 'Content of second article'),
  (2, 'Jane Article', 'Content by Jane');
EOF
```

### Data Export

```bash
# Export users to CSV
psql -U agrios -d agrios_users -c "\COPY users TO 'users_export.csv' CSV HEADER"

# Export articles to CSV
psql -U agrios -d agrios_articles -c "\COPY articles TO 'articles_export.csv' CSV HEADER"
```

### Database Backup and Restore

```bash
# Backup
pg_dump -U agrios -d agrios_users > backup_users.sql
pg_dump -U agrios -d agrios_articles > backup_articles.sql

# Restore
psql -U agrios -d agrios_users < backup_users.sql
psql -U agrios -d agrios_articles < backup_articles.sql
```

---

## Troubleshooting

### Common Issues

#### 1. PostgreSQL Connection Refused

**Error:**
```
Failed to connect to database: dial tcp 127.0.0.1:5432: connectex: No connection could be made
```

**Solutions:**

1. Check if PostgreSQL is running:
   ```bash
   # Windows
   Get-Service -Name postgresql*
   
   # Start if stopped
   net start postgresql-x64-18
   ```

2. Verify port 5432 is listening:
   ```bash
   netstat -ano | findstr :5432
   ```

3. Check PostgreSQL logs:
   ```bash
   # Windows: C:\Program Files\PostgreSQL\18\data\log\
   tail -f "C:\Program Files\PostgreSQL\18\data\log\postgresql-*.log"
   ```

4. Test connection directly:
   ```bash
   psql -U agrios -d agrios_users -h localhost -p 5432
   ```

#### 2. Redis Connection Failed

**Error:**
```
Failed to connect to Redis: dial tcp 127.0.0.1:6379: connectex: No connection could be made
```

**Solutions:**

1. Start Redis:
   ```bash
   docker run -d --name redis -p 6379:6379 redis:alpine
   ```

2. Test connection:
   ```bash
   docker exec -it redis redis-cli ping
   ```

#### 3. Port Already in Use

**Error:**
```
Failed to listen on port 50051: bind: address already in use
```

**Solutions:**

1. Find process using the port:
   ```bash
   netstat -ano | findstr :50051
   ```

2. Kill the process:
   ```bash
   taskkill /PID <process_id> /F
   ```

3. Or change port in `.env` file:
   ```env
   GRPC_PORT=50053
   ```

#### 4. Database Does Not Exist

**Error:**
```
database "agrios_users" does not exist
```

**Solution:**

```bash
psql -U postgres -c "CREATE DATABASE agrios_users OWNER agrios;"
psql -U agrios -d agrios_users -f migrations/001_create_users_table.sql
```

#### 5. Migration Already Applied

**Error:**
```
relation "users" already exists
```

This is normal if tables already exist. You can safely ignore or drop tables first:

```bash
psql -U agrios -d agrios_users -c "DROP TABLE IF EXISTS users CASCADE;"
```

#### 6. User Service Unavailable (Article Service)

Article Service has graceful degradation. If User Service is down:

- `CreateArticle`: Returns error (user validation required)
- `GetArticleWithUser`: Returns article without user info

Check User Service logs and restart if needed.

#### 7. JWT Token Invalid

**Error:**
```
rpc error: code = Unauthenticated desc = invalid token
```

**Causes:**
- Token expired (15 minutes for access token)
- Token was logged out (blacklisted in Redis)
- Wrong JWT_SECRET in configuration

**Solution:**
Login again to get new token.

### Debug Mode

Enable verbose logging by modifying service code temporarily:

```go
// In main.go, add after config load
log.SetFlags(log.LstdFlags | log.Lshortfile)
```

---

## Monitoring and Maintenance

### Health Checks

#### Check Service Health

```bash
# User Service
grpcurl -plaintext localhost:50051 grpc.health.v1.Health/Check

# Article Service  
grpcurl -plaintext localhost:50052 grpc.health.v1.Health/Check
```

#### Check Database Connections

```bash
# PostgreSQL
psql -U agrios -d agrios_users -c "SELECT COUNT(*) FROM users;"

# Redis
docker exec -it redis redis-cli ping
```

### Monitoring Commands

```bash
# View service logs (Docker)
docker-compose logs -f --tail=100 user-service
docker-compose logs -f --tail=100 article-service

# View container stats
docker stats agrios-user-service agrios-article-service

# Check database size
psql -U agrios -d agrios_users -c "SELECT pg_size_pretty(pg_database_size('agrios_users'));"

# Check active connections
psql -U agrios -d agrios_users -c "SELECT count(*) FROM pg_stat_activity;"
```

### Maintenance Tasks

#### Clean Up Old Logs

```bash
# Docker logs
docker-compose logs --no-log-prefix > logs_backup.txt
docker-compose down
docker-compose up -d
```

#### Vacuum Database

```bash
psql -U agrios -d agrios_users -c "VACUUM ANALYZE;"
psql -U agrios -d agrios_articles -c "VACUUM ANALYZE;"
```

#### Clear Redis Cache

```bash
docker exec -it redis redis-cli FLUSHDB
```

#### Restart Services

```bash
# Docker
docker-compose restart user-service
docker-compose restart article-service

# Local
# Press Ctrl+C in terminal, then restart binary
```

---

## Performance Tips

### Database Optimization

1. **Add indexes for frequent queries:**
   ```sql
   CREATE INDEX idx_users_created_at ON users(created_at DESC);
   CREATE INDEX idx_articles_created_at ON articles(created_at DESC);
   ```

2. **Monitor slow queries:**
   ```sql
   ALTER DATABASE agrios_users SET log_min_duration_statement = 1000;
   ```

3. **Adjust connection pool:**
   ```env
   DB_MAX_CONNS=20
   DB_MIN_CONNS=5
   ```

### Redis Optimization

1. **Set expiration for blacklisted tokens:**
   Already implemented - tokens expire automatically

2. **Monitor memory usage:**
   ```bash
   docker exec -it redis redis-cli INFO memory
   ```

---

## Security Considerations

### Production Checklist

- [ ] Change default JWT_SECRET to strong random value
- [ ] Use environment-specific .env files (never commit to git)
- [ ] Enable TLS/SSL for gRPC connections
- [ ] Use strong database passwords
- [ ] Enable Redis authentication
- [ ] Set up firewall rules to restrict port access
- [ ] Implement rate limiting
- [ ] Enable audit logging
- [ ] Regular security updates for dependencies
- [ ] Backup database regularly

### Generate Secure JWT Secret

```bash
openssl rand -base64 32
```

---

## Additional Resources

- **gRPC Documentation**: https://grpc.io/docs/
- **PostgreSQL Documentation**: https://www.postgresql.org/docs/
- **Redis Documentation**: https://redis.io/documentation
- **Docker Compose**: https://docs.docker.com/compose/

---

## Support and Contact

For issues or questions:
1. Check troubleshooting section above
2. Review service logs for error messages
3. Check CHANGELOG.md for recent changes
4. Contact: thatlq1812

---

**Document Version:** 1.0  
**Last Updated:** December 3, 2025
