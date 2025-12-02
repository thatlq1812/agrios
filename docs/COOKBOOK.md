# Agrios Microservices Cookbook

Complete guide for running, testing, and troubleshooting the Agrios microservices project.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Service 1 - User Service](#service-1---user-service)
3. [Service 2 - Article Service](#service-2---article-service)
4. [Cross-Service Operations](#cross-service-operations)
5. [Database Operations](#database-operations)
6. [Troubleshooting](#troubleshooting)

---

## Quick Start

### Prerequisites

- Go 1.21+
- Docker and Docker Compose
- grpcurl (for testing)

### Start Services

**Step 1: Start PostgreSQL**

```bash
docker ps
# If agrios-postgres is not running:
docker start agrios-postgres
# Or if container doesn't exist:
docker run -d --name agrios-postgres -e POSTGRES_PASSWORD=postgres -p 5432:5432 postgres:15-alpine
```

**Step 2: Verify Databases Exist**

```bash
# List databases
docker exec -it agrios-postgres psql -U postgres -c "\l"

# Create if not exist
docker exec -it agrios-postgres psql -U postgres -c "CREATE DATABASE agrios_users;"
docker exec -it agrios-postgres psql -U postgres -c "CREATE DATABASE agrios_articles;"
```

**Step 3: Run Migrations**

```bash
# Users table
docker exec -it agrios-postgres psql -U postgres -d agrios_users -c "
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);"

# Articles table
docker exec -it agrios-postgres psql -U postgres -d agrios_articles -c "
CREATE TABLE IF NOT EXISTS articles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);"
```

**Step 4: Start Service 1 (Terminal 1)**

```bash
cd service-1-user
go run cmd/server/main.go
```

Expected output:
```
Connected to PostgreSQL
User service listening on port :50051
```

**Step 5: Start Service 2 (Terminal 2)**

```bash
cd service-2-article
go run cmd/server/main.go
```

Expected output:
```
Connected to PostgreSQL
Connected to User Service at localhost:50051
Article service listening on port :50052
```

---

## Service 1 - User Service

**Port**: `50051`  
**Service Name**: `user.UserService`

### List Available Methods

```bash
grpcurl -plaintext localhost:50051 list user.UserService
```

### 1. Create User

```bash
grpcurl -plaintext -d '{
  "name": "Nguyen Van A",
  "email": "vana@example.com"
}' localhost:50051 user.UserService/CreateUser
```

**Response Example:**
```json
{
  "id": 1,
  "name": "Nguyen Van A",
  "email": "vana@example.com",
  "createdAt": "2025-12-02T05:00:00Z",
  "updatedAt": "2025-12-02T05:00:00Z"
}
```

### 2. Get User

```bash
grpcurl -plaintext -d '{
  "id": 1
}' localhost:50051 user.UserService/GetUser
```

### 3. List Users

```bash
grpcurl -plaintext -d '{}' localhost:50051 user.UserService/ListUsers
```

**Response Example:**
```json
{
  "users": [
    {
      "id": 1,
      "name": "Nguyen Van A",
      "email": "vana@example.com",
      "createdAt": "2025-12-02T05:00:00Z",
      "updatedAt": "2025-12-02T05:00:00Z"
    }
  ],
  "total": 1
}
```

### 4. Update User

```bash
grpcurl -plaintext -d '{
  "id": 1,
  "name": "Nguyen Van A Updated",
  "email": "vana.updated@example.com"
}' localhost:50051 user.UserService/UpdateUser
```

### 5. Delete User

```bash
grpcurl -plaintext -d '{
  "id": 1
}' localhost:50051 user.UserService/DeleteUser
```

**Response Example:**
```json
{
  "success": true,
  "message": "User deleted successfully"
}
```

---

## Service 2 - Article Service

**Port**: `50052`  
**Service Name**: `article.ArticleService`

### List Available Methods

```bash
grpcurl -plaintext localhost:50052 list article.ArticleService
```

### 1. Create Article

**Important**: Must have valid `user_id` from Service 1

```bash
# First, create a user
grpcurl -plaintext -d '{
  "name": "Test User",
  "email": "test@example.com"
}' localhost:50051 user.UserService/CreateUser

# Then create article with that user_id
grpcurl -plaintext -d '{
  "user_id": 1,
  "title": "My First Article",
  "content": "This is the content of my article"
}' localhost:50052 article.ArticleService/CreateArticle
```

**Response Example:**
```json
{
  "id": 1,
  "title": "My First Article",
  "content": "This is the content of my article",
  "userId": 1,
  "createdAt": "2025-12-02T05:10:00Z",
  "updatedAt": "2025-12-02T05:10:00Z"
}
```

### 2. Get Article

```bash
grpcurl -plaintext -d '{
  "id": 1
}' localhost:50052 article.ArticleService/GetArticle
```

**Response includes user info:**
```json
{
  "article": {
    "id": 1,
    "title": "My First Article",
    "content": "This is the content of my article",
    "userId": 1,
    "createdAt": "2025-12-02T05:10:00Z",
    "updatedAt": "2025-12-02T05:10:00Z"
  },
  "user": {
    "id": 1,
    "name": "Test User",
    "email": "test@example.com",
    "createdAt": "2025-12-02T05:00:00Z"
  }
}
```

### 3. List Articles

```bash
# List all articles
grpcurl -plaintext -d '{}' localhost:50052 article.ArticleService/ListArticles

# List articles by specific user
grpcurl -plaintext -d '{
  "user_id": 1
}' localhost:50052 article.ArticleService/ListArticles
```

### 4. Update Article

```bash
grpcurl -plaintext -d '{
  "id": 1,
  "title": "Updated Title",
  "content": "Updated content here"
}' localhost:50052 article.ArticleService/UpdateArticle
```

### 5. Delete Article

```bash
grpcurl -plaintext -d '{
  "id": 1
}' localhost:50052 article.ArticleService/DeleteArticle
```

---

## Cross-Service Operations

### Test User Verification

Service 2 verifies user exists before creating article:

```bash
# This should FAIL - user_id 999 doesn't exist
grpcurl -plaintext -d '{
  "user_id": 999,
  "title": "Test Article",
  "content": "This should fail"
}' localhost:50052 article.ArticleService/CreateArticle
```

**Expected Error:**
```
ERROR:
  Code: Internal
  Message: failed to verify user
```

### Complete Workflow Example

```bash
# 1. Create user
grpcurl -plaintext -d '{
  "name": "John Doe",
  "email": "john@example.com"
}' localhost:50051 user.UserService/CreateUser
# Note the returned id (e.g., id: 2)

# 2. Create article for that user
grpcurl -plaintext -d '{
  "user_id": 2,
  "title": "Johns Article",
  "content": "Article content here"
}' localhost:50052 article.ArticleService/CreateArticle

# 3. List all articles (includes user info)
grpcurl -plaintext -d '{}' localhost:50052 article.ArticleService/ListArticles

# 4. Update the article
grpcurl -plaintext -d '{
  "id": 1,
  "title": "Updated Article Title",
  "content": "Updated content"
}' localhost:50052 article.ArticleService/UpdateArticle

# 5. Delete the article
grpcurl -plaintext -d '{
  "id": 1
}' localhost:50052 article.ArticleService/DeleteArticle

# 6. Delete the user
grpcurl -plaintext -d '{
  "id": 2
}' localhost:50051 user.UserService/DeleteUser
```

---

## Database Operations

### View Data Directly

```bash
# View all users
docker exec -it agrios-postgres psql -U postgres -d agrios_users -c "SELECT * FROM users;"

# View all articles
docker exec -it agrios-postgres psql -U postgres -d agrios_articles -c "SELECT * FROM articles;"

# View articles with user info (join query)
docker exec -it agrios-postgres psql -U postgres -d agrios_articles -c "
SELECT a.id, a.title, a.user_id, u.name as user_name, u.email 
FROM articles a 
LEFT JOIN dblink('host=localhost port=5432 dbname=agrios_users user=postgres password=postgres',
  'SELECT id, name, email FROM users') AS u(id int, name varchar, email varchar)
ON a.user_id = u.id;"
```

### Insert Test Data

```bash
# Insert test user
docker exec -it agrios-postgres psql -U postgres -d agrios_users -c "
INSERT INTO users (name, email) VALUES 
('Test User 1', 'test1@example.com'),
('Test User 2', 'test2@example.com');"

# Insert test article
docker exec -it agrios-postgres psql -U postgres -d agrios_articles -c "
INSERT INTO articles (user_id, title, content) VALUES 
(1, 'Sample Article', 'This is sample content');"
```

### Clear All Data

```bash
# Clear articles
docker exec -it agrios-postgres psql -U postgres -d agrios_articles -c "TRUNCATE articles RESTART IDENTITY;"

# Clear users
docker exec -it agrios-postgres psql -U postgres -d agrios_users -c "TRUNCATE users RESTART IDENTITY CASCADE;"
```

### Database Schema

```bash
# View users table structure
docker exec -it agrios-postgres psql -U postgres -d agrios_users -c "\d users"

# View articles table structure
docker exec -it agrios-postgres psql -U postgres -d agrios_articles -c "\d articles"
```

---

## Troubleshooting

### Service Won't Start

**Error**: `Failed to connect to database`

**Solution**:
```bash
# Check PostgreSQL is running
docker ps | grep postgres

# If not running, start it
docker start agrios-postgres

# Verify connection
docker exec -it agrios-postgres psql -U postgres -c "SELECT version();"
```

**Error**: `Port already in use`

**Solution**:
```bash
# Find process using port 50051
netstat -ano | findstr :50051

# Kill the process (Windows)
taskkill /PID <PID> /F

# Or on Linux/Mac
lsof -ti:50051 | xargs kill -9
```

### Database Issues

**Error**: `database "agrios_users" does not exist`

**Solution**:
```bash
docker exec -it agrios-postgres psql -U postgres -c "CREATE DATABASE agrios_users;"
docker exec -it agrios-postgres psql -U postgres -c "CREATE DATABASE agrios_articles;"
```

**Error**: `relation "users" does not exist`

**Solution**: Run migrations again (see Quick Start Step 3)

### gRPC Errors

**Error**: `target server does not expose service`

**Solution**: Check correct service name
```bash
# List services
grpcurl -plaintext localhost:50051 list

# Use exact service name from output
# Correct: user.UserService NOT user.v1.UserService
```

**Error**: `failed to verify user`

**Solution**: User doesn't exist, create user first
```bash
# Check what users exist
docker exec -it agrios-postgres psql -U postgres -d agrios_users -c "SELECT id, name FROM users;"

# Use existing user_id or create new user
```

### Service 2 Cannot Connect to Service 1

**Error**: `Failed to connect to user service`

**Solution**:
1. Make sure Service 1 is running first
2. Check Service 1 is on port 50051
3. Check firewall not blocking port

```bash
# Test Service 1 is reachable
grpcurl -plaintext localhost:50051 list
```

### Reset Everything

```bash
# Stop services (Ctrl+C in terminals)

# Stop and remove container
docker stop agrios-postgres
docker rm agrios-postgres

# Start fresh
docker run -d --name agrios-postgres \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  postgres:15-alpine

# Wait 3 seconds for startup
sleep 3

# Create databases and tables (see Quick Start)
```

---

## Testing Checklist

- [ ] PostgreSQL container running
- [ ] Databases created (agrios_users, agrios_articles)
- [ ] Tables created (users, articles)
- [ ] Service 1 running on port 50051
- [ ] Service 2 running on port 50052
- [ ] Can create user via Service 1
- [ ] Can list users via Service 1
- [ ] Can create article via Service 2 (with valid user_id)
- [ ] Article creation fails with invalid user_id
- [ ] Can list articles with user info
- [ ] Can update and delete articles
- [ ] Can update and delete users

---

## Performance Testing

### Load Test with Multiple Requests

```bash
# Create 10 users quickly
for i in {1..10}; do
  grpcurl -plaintext -d "{\"name\":\"User $i\",\"email\":\"user$i@example.com\"}" \
    localhost:50051 user.UserService/CreateUser
done

# Create articles for each user
for i in {1..10}; do
  grpcurl -plaintext -d "{\"user_id\":$i,\"title\":\"Article $i\",\"content\":\"Content $i\"}" \
    localhost:50052 article.ArticleService/CreateArticle
done

# List all (should show 10 articles with user info)
grpcurl -plaintext -d '{}' localhost:50052 article.ArticleService/ListArticles
```

---

## Development Notes

### Configuration

Both services use hardcoded database configs in `cmd/server/main.go`:

**Service 1:**
```go
dbConfig := db.Config{
    Host:     "127.0.0.1",
    Port:     "5432",
    User:     "postgres",
    Password: "postgres",
    DBName:   "agrios_users",
}
```

**Service 2:**
```go
dbConfig := db.Config{
    Host:     "127.0.0.1",
    Port:     "5432",
    User:     "postgres",
    Password: "postgres",
    DBName:   "agrios_articles",
}
userServiceAddr := "localhost:50051"
```

### Architecture

```
┌─────────────────┐
│   Client        │
│   (grpcurl)     │
└────────┬────────┘
         │
         ├─────────────────┐
         │                 │
         ▼                 ▼
┌─────────────────┐  ┌──────────────────┐
│  Service 1      │  │   Service 2      │
│  User Service   │◄─┤  Article Service │
│  Port: 50051    │  │  Port: 50052     │
└────────┬────────┘  └────────┬─────────┘
         │                    │
         ▼                    ▼
┌─────────────────┐  ┌──────────────────┐
│  PostgreSQL     │  │   PostgreSQL     │
│  agrios_users   │  │ agrios_articles  │
└─────────────────┘  └──────────────────┘
```

### Key Features

1. **Microservices Architecture**: Two independent services
2. **gRPC Communication**: Fast binary protocol
3. **Service Discovery**: Service 2 knows Service 1 address
4. **Data Validation**: Service 2 verifies users before creating articles
5. **Clean Architecture**: Repository pattern, separation of concerns
6. **Database per Service**: Each service has own database

---

## Quick Command Reference

```bash
# Start PostgreSQL
docker start agrios-postgres

# Start Service 1
cd service-1-user && go run cmd/server/main.go

# Start Service 2
cd service-2-article && go run cmd/server/main.go

# Create user
grpcurl -plaintext -d '{"name":"User","email":"user@example.com"}' localhost:50051 user.UserService/CreateUser

# Create article
grpcurl -plaintext -d '{"user_id":1,"title":"Title","content":"Content"}' localhost:50052 article.ArticleService/CreateArticle

# List users
grpcurl -plaintext -d '{}' localhost:50051 user.UserService/ListUsers

# List articles
grpcurl -plaintext -d '{}' localhost:50052 article.ArticleService/ListArticles

# View DB data
docker exec -it agrios-postgres psql -U postgres -d agrios_users -c "SELECT * FROM users;"
docker exec -it agrios-postgres psql -U postgres -d agrios_articles -c "SELECT * FROM articles;"
```

---

**Last Updated**: December 2, 2025  
**Project**: Agrios Microservices  
**Author**: That Le Quang
