# Agrios Microservices Platform

> Enterprise-grade microservices architecture with gRPC backend and REST API Gateway

[![Go Version](https://img.shields.io/badge/Go-1.21+-00ADD8?style=flat&logo=go)](https://golang.org)
[![gRPC](https://img.shields.io/badge/gRPC-Latest-244c5a?style=flat&logo=grpc)](https://grpc.io)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-336791?style=flat&logo=postgresql)](https://www.postgresql.org)
[![Redis](https://img.shields.io/badge/Redis-7-DC382D?style=flat&logo=redis)](https://redis.io)

Agrios is a modern microservices platform featuring JWT authentication, API Gateway pattern, and gRPC-based service communication.

## Quick Deployment

**New machine? Get started in 3 steps:**

```bash
# 1. Clone repository
git clone https://github.com/thatlq1812/agrios.git
cd agrios

# 2. Copy environment configuration
cp service-1-user/.env.example service-1-user/.env
cp service-2-article/.env.example service-2-article/.env

# 3. Start all services
docker-compose up -d
sleep 15

# 4. Initialize services (run migrations)
bash scripts/init-services.sh

# 5. Seed sample data (optional - for testing)
bash scripts/seed-data.sh

# 6. Verify deployment
curl http://localhost:8080/health
```

> ** PostgreSQL Version Conflict?**  
> If you see "database files are incompatible" error:
> ```bash
> bash scripts/clean-data.sh  # Remove old data
> docker-compose up -d && sleep 15 && bash scripts/init-services.sh
> ```

**[Complete Deployment Guide →](./docs/DEPLOYMENT.md)** | **[API Testing Guide →](./docs/GRPC_COMMANDS.md)**

---

## Documentation

| Document | Description |
|----------|-------------|
| **[Documentation Hub](./docs/README.md)** | Main documentation index |
| **[Documentation Map](./docs/DOCUMENTATION_MAP.md)** | Find docs by task or role |
| **[Deployment & Testing](./docs/DEPLOYMENT_AND_TESTING.md)** | Complete setup guide |
| **[Architecture Guide](./docs/ARCHITECTURE_GUIDE.md)** | System design & patterns |
| **[API Reference](./docs/API_REFERENCE.md)** | Complete API documentation |

---

## Architecture

```
Client (Browser/Mobile)
         ↓
    HTTP REST API
         ↓
┌─────────────────┐
│   API Gateway   │  Port 8080
│   (REST → gRPC) │
└────────┬────────┘
         │
    ┌────┴────┐
    ↓         ↓
┌─────────┐ ┌──────────┐
│  User   │ │ Article  │
│ Service │ │ Service  │
│  :50051 │ │  :50052  │
└────┬────┘ └────┬─────┘
     │           │
     └─────┬─────┘
           ↓
    ┌──────────────┐
    │ PostgreSQL   │
    │ + Redis      │
    └──────────────┘
```

### Services

- **API Gateway** (port 8080) - HTTP REST interface with gRPC backend
- **User Service** (port 50051) - Authentication, user management
- **Article Service** (port 50052) - Content management with user integration

**[→ View detailed architecture](./docs/ARCHITECTURE_GUIDE.md)**

---

## Key Features

- **API Gateway Pattern** - REST API with gRPC backend communication
- **JWT Authentication** - Access/refresh tokens with Redis blacklist
- **Microservices** - Independent, scalable services
- **gRPC Communication** - Efficient inter-service communication
- **Docker Ready** - Complete containerization support
- **Standardized Responses** - `{"code":"000", "message":"success", "data":{}}`

---

## Tech Stack

- **Language:** Go 1.21+
- **Communication:** gRPC (internal), REST (external)
- **Databases:** PostgreSQL 15, Redis 7
- **Container:** Docker & Docker Compose
- **Auth:** JWT with bcrypt password hashing

## Project Structure

```
agrios/
├── service-1-user/          # User Service (Port 50051)
│   ├── cmd/server/          # Main entry point
│   ├── internal/
│   │   ├── auth/            # JWT and password handling
│   │   ├── config/          # Configuration management
│   │   ├── db/              # PostgreSQL and Redis connections
│   │   ├── repository/      # Database operations
│   │   └── server/          # gRPC server implementation
│   ├── migrations/          # Database migrations
│   ├── proto/               # gRPC proto definitions
│   └── Dockerfile
│
├── service-2-article/       # Article Service (Port 50052)
│   ├── cmd/server/          # Main entry point
│   ├── internal/
│   │   ├── client/          # User Service gRPC client
│   │   ├── config/          # Configuration management
│   │   ├── db/              # PostgreSQL connection
│   │   ├── repository/      # Database operations
│   │   └── server/          # gRPC server implementation
│   ├── migrations/          # Database migrations
│   ├── proto/               # gRPC proto definitions
│   └── Dockerfile
│
├── pkg/common/              # Shared utilities
├── docs/                    # Documentation
├── docker-compose.yml       # Docker orchestration
└── README.md
```

## What's In This Repo

### Service 1 - User Service
**Database:** `agrios` (PostgreSQL)

**Features:**
- User registration with password hashing
- User authentication (Login/Logout)
- JWT token generation and validation
- Token blacklisting with Redis
- User CRUD operations
- List users with pagination

**APIs:**
- `CreateUser` - Register new user
- `Login` - Authenticate and get JWT tokens
- `Logout` - Invalidate token
- `ValidateToken` - Verify JWT token
- `GetUser` - Get user by ID
- `UpdateUser` - Update user information
- `DeleteUser` - Delete user
- `ListUsers` - List all users (paginated)

### Service 2 - Article Service
**Database:** `agrios_articles` (PostgreSQL)

**Features:**
- Article CRUD operations
- Validate article ownership via User Service (gRPC call)
- List articles with pagination
- Automatic user validation when creating articles

**APIs:**
- `CreateArticle` - Create new article (validates user exists)
- `GetArticle` - Get article by ID
- `UpdateArticle` - Update article
- `DeleteArticle` - Delete article
- `ListArticles` - List all articles (paginated)

### Architecture

```
┌─────────────────┐         ┌──────────────────┐
│  User Service   │◄────────┤ Article Service  │
│    (gRPC)       │         │     (gRPC)       │
│   Port: 50051   │         │   Port: 50052    │
└────────┬────────┘         └────────┬─────────┘
         │                           │
         ├──────────┬────────────────┤
         │          │                │
    ┌────▼───┐  ┌──▼────┐      ┌───▼────┐
    │ Redis  │  │ Users │      │Articles│
    │ :6379  │  │  DB   │      │   DB   │
    └────────┘  └───────┘      └────────┘
```

## Prerequisites

- Docker Desktop
- Docker Compose
- grpcurl (for testing)

Install grpcurl:
```bash
go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest
```

## How to Run

### 1. Start All Services with Docker Compose

```bash
# Clone repository
git clone <repo-url>
cd agrios

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Check status
docker-compose ps
```

### 2. Verify Services Are Running

```bash
# Should see 5 containers running:
# - agrios-postgres (PostgreSQL)
# - agrios-redis (Redis)
# - agrios-user-service (User Service)
# - agrios-article-service (Article Service)
# - agrios-pgadmin (Database UI)

docker ps
```

### 3. Access Services

- **User Service (gRPC):** `localhost:50051`
- **Article Service (gRPC):** `localhost:50052`
- **PgAdmin (Web UI):** `http://localhost:5050`
  - Email: `admin@admin.com`
  - Password: `admin`

## How to Test

### Test User Service

#### 1. Create User (Register)

```bash
grpcurl -plaintext -d '{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123"
}' localhost:50051 user.UserService/CreateUser
```

**Expected Response:**
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
  "email": "john@example.com",
  "password": "password123"
}' localhost:50051 user.UserService/Login
```

**Expected Response:**
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

#### 3. Get User

```bash
grpcurl -plaintext -d '{
  "id": 1
}' localhost:50051 user.UserService/GetUser
```

#### 4. Update User

```bash
grpcurl -plaintext -d '{
  "id": 1,
  "name": "John Updated",
  "email": "john.updated@example.com"
}' localhost:50051 user.UserService/UpdateUser
```

#### 5. List Users

```bash
grpcurl -plaintext -d '{
  "page": 1,
  "page_size": 10
}' localhost:50051 user.UserService/ListUsers
```

#### 6. Validate Token

```bash
grpcurl -plaintext -d '{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}' localhost:50051 user.UserService/ValidateToken
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

### Test Article Service

#### 1. Create Article

**Note:** User with user_id must exist first

```bash
grpcurl -plaintext -d '{
  "title": "My First Article",
  "content": "This is amazing content!",
  "user_id": 1
}' localhost:50052 article.ArticleService/CreateArticle
```

**Expected Response:**
```json
{
  "id": 1,
  "title": "My First Article",
  "content": "This is amazing content!",
  "userId": 1,
  "createdAt": "2025-12-03T10:05:00Z",
  "updatedAt": "2025-12-03T10:05:00Z"
}
```

#### 2. Get Article

```bash
grpcurl -plaintext -d '{
  "id": 1
}' localhost:50052 article.ArticleService/GetArticle
```

#### 3. Update Article

```bash
grpcurl -plaintext -d '{
  "id": 1,
  "title": "Updated Title",
  "content": "Updated content here"
}' localhost:50052 article.ArticleService/UpdateArticle
```

#### 4. List Articles

```bash
grpcurl -plaintext -d '{
  "page_size": 10,
  "page_number": 1
}' localhost:50052 article.ArticleService/ListArticles
```

#### 5. Delete Article

```bash
grpcurl -plaintext -d '{
  "id": 1
}' localhost:50052 article.ArticleService/DeleteArticle
```

### List Available Services and Methods

```bash
# List all services in User Service
grpcurl -plaintext localhost:50051 list

# List all methods in User Service
grpcurl -plaintext localhost:50051 list user.UserService

# List all services in Article Service
grpcurl -plaintext localhost:50052 list

# List all methods in Article Service
grpcurl -plaintext localhost:50052 list article.ArticleService
```

## Testing Workflow Example

```bash
# 1. Create a user
grpcurl -plaintext -d '{"name": "Alice", "email": "alice@example.com", "password": "pass123"}' \
  localhost:50051 user.UserService/CreateUser

# Response: user.id = 1

# 2. Create another user
grpcurl -plaintext -d '{"name": "Bob", "email": "bob@example.com", "password": "pass456"}' \
  localhost:50051 user.UserService/CreateUser

# Response: user.id = 2

# 3. Create articles for Alice (user_id=1)
grpcurl -plaintext -d '{"title": "Alice Article 1", "content": "Content 1", "user_id": 1}' \
  localhost:50052 article.ArticleService/CreateArticle

grpcurl -plaintext -d '{"title": "Alice Article 2", "content": "Content 2", "user_id": 1}' \
  localhost:50052 article.ArticleService/CreateArticle

# 4. Create article for Bob (user_id=2)
grpcurl -plaintext -d '{"title": "Bob Article", "content": "Content", "user_id": 2}' \
  localhost:50052 article.ArticleService/CreateArticle

# 5. List all articles
grpcurl -plaintext -d '{"page_size": 10, "page_number": 1}' \
  localhost:50052 article.ArticleService/ListArticles

# 6. Try to create article with non-existent user (should fail)
grpcurl -plaintext -d '{"title": "Invalid", "content": "Test", "user_id": 999}' \
  localhost:50052 article.ArticleService/CreateArticle
```

## Database Access

### Using PgAdmin (Web UI)

1. Open browser: `http://localhost:5050`
2. Login with:
   - Email: `admin@admin.com`
   - Password: `admin`
3. Add Server:
   - Name: `Agrios`
   - Host: `postgres`
   - Port: `5432`
   - Username: `postgres`
   - Password: `postgres`
   - Database: `agrios` (for users) or `agrios_articles` (for articles)

### Using psql (CLI)

```bash
# Connect to users database
docker exec -it agrios-postgres psql -U postgres -d agrios

# List users
SELECT * FROM users;

# Connect to articles database
docker exec -it agrios-postgres psql -U postgres -d agrios_articles

# List articles
SELECT * FROM articles;
```

## Stop Services

```bash
# Stop all services
docker-compose down

# Stop and remove all data (WARNING: deletes database)
docker-compose down -v
```

## Troubleshooting

### Service won't start

```bash
# Check logs
docker-compose logs user-service
docker-compose logs article-service

# Rebuild services
docker-compose build --no-cache
docker-compose up -d
```

### Database connection error

```bash
# Check PostgreSQL is running
docker exec -it agrios-postgres psql -U postgres -l

# Check Redis is running
docker exec -it agrios-redis redis-cli ping
```

### Port already in use

```bash
# Find process using port
netstat -ano | findstr :50051

# Kill process or change port in docker-compose.yml
```

## Development

### Local Development (Without Docker)

#### Prerequisites
- Go 1.24+
- PostgreSQL 15+
- Redis 7+

#### Setup

1. **Start PostgreSQL and Redis**
   ```bash
   # PostgreSQL (Windows)
   net start postgresql-x64-18
   
   # Redis (Docker)
   docker run -d --name redis -p 6379:6379 redis:alpine
   ```

2. **Create Databases**
   ```bash
   psql -U postgres
   CREATE USER agrios WITH PASSWORD 'agrios123';
   CREATE DATABASE agrios OWNER agrios;
   CREATE DATABASE agrios_articles OWNER agrios;
   \q
   ```

3. **Run Migrations**
   ```bash
   # User Service
   psql -U agrios -d agrios < service-1-user/migrations/001_create_users_table.sql
   
   # Article Service
   psql -U agrios -d agrios_articles < service-2-article/migrations/001_create_articles_table.sql
   ```

4. **Configure Environment**
   
   Create `.env` files in each service directory (see `docs/OPERATIONS_GUIDE.md` for details)

5. **Build and Run**
   ```bash
   # Terminal 1 - User Service
   cd service-1-user
   go run cmd/server/main.go
   
   # Terminal 2 - Article Service
   cd service-2-article
   go run cmd/server/main.go
   ```

## Documentation

- **Operations Guide**: `docs/OPERATIONS_GUIDE.md` - Detailed setup and operations
- **Changelog**: `CHANGELOG.md` - Version history and changes

## Features Highlights

- gRPC communication between services
- JWT authentication with token blacklisting
- Password hashing with bcrypt
- Connection pooling for PostgreSQL
- Redis for session management
- Docker Compose for easy deployment
- Health checks for all services
- Graceful shutdown handling
- Environment-based configurations