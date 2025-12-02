# Docker Deployment Guide

## Prerequisites

- Docker Desktop installed and running
- Docker Compose V2

## Quick Start

### 1. Build and Start All Services

```bash
# Build and start all services
docker-compose up --build -d

# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f user-service
docker-compose logs -f article-service
```

### 2. Stop Services

```bash
# Stop all services
docker-compose down

# Stop and remove volumes (WARNING: deletes database data)
docker-compose down -v
```

### 3. Rebuild After Code Changes

```bash
# Rebuild specific service
docker-compose up --build user-service -d
docker-compose up --build article-service -d

# Rebuild all
docker-compose up --build -d
```

## Services and Ports

| Service | Port | Description |
|---------|------|-------------|
| user-service | 50051 | User gRPC service |
| article-service | 50052 | Article gRPC service |
| postgres | 5432 | PostgreSQL database |
| pgadmin | 5050 | Database management UI |

## Access Services

### PgAdmin (Database UI)
- URL: http://localhost:5050
- Email: admin@admin.com
- Password: admin

**Add Database Server:**
- Host: postgres
- Port: 5432
- Username: postgres
- Password: postgres
- Database: agrios

### gRPC Services

Test with grpcurl:

```bash
# Install grpcurl
go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest

# List services
grpcurl -plaintext localhost:50051 list
grpcurl -plaintext localhost:50052 list

# Test user service
grpcurl -plaintext -d '{"name":"John Doe","email":"john@example.com"}' \
  localhost:50051 user.UserService/CreateUser

# Test article service
grpcurl -plaintext -d '{"title":"My Article","content":"Article content","user_id":1}' \
  localhost:50052 article.ArticleService/CreateArticle
```

## Environment Variables

### User Service
```env
DB_HOST=postgres
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=agrios
GRPC_PORT=50051
JWT_SECRET=your-secret-key
```

### Article Service
```env
DB_HOST=postgres
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=agrios
GRPC_PORT=50052
USER_SERVICE_ADDR=user-service:50051
```

## Database Migrations

Migrations are located in:
- `service-1-user/migrations/`
- `service-2-article/migrations/`

To run migrations manually:

```bash
# Enter container
docker exec -it agrios-user-service sh

# Run migrations using your preferred tool
# Or connect to database directly
docker exec -it agrios-postgres psql -U postgres -d agrios
```

## Troubleshooting

### Check Service Health

```bash
docker-compose ps
docker-compose logs user-service
docker-compose logs article-service
```

### Test Database Connection

```bash
docker exec -it agrios-postgres psql -U postgres -d agrios
```

### Restart Specific Service

```bash
docker-compose restart user-service
docker-compose restart article-service
```

### View Resource Usage

```bash
docker stats
```

## Production Deployment

For production, update:

1. **Environment Variables:**
   - Use strong passwords
   - Change JWT_SECRET
   - Use production database

2. **Security:**
   - Enable TLS for gRPC
   - Use secrets management
   - Configure firewall rules

3. **Monitoring:**
   - Add Prometheus metrics
   - Add logging aggregation
   - Add health check endpoints

## Architecture

```
┌─────────────────┐
│   Internet      │
└────────┬────────┘
         │
    ┌────▼─────┐
    │  Gateway │ (Future: REST/GraphQL API)
    └────┬─────┘
         │
    ┌────▼────────────────────┐
    │   Docker Network        │
    │  (agrios-network)       │
    │                         │
    │  ┌──────────────┐       │
    │  │ user-service │:50051 │
    │  └──────┬───────┘       │
    │         │               │
    │  ┌──────▼────────┐      │
    │  │article-service│:50052│
    │  └──────┬────────┘      │
    │         │               │
    │  ┌──────▼────────┐      │
    │  │   PostgreSQL  │:5432 │
    │  └───────────────┘      │
    └─────────────────────────┘
```

## Notes

- Services communicate via gRPC on internal Docker network
- Database is persistent (uses Docker volume)
- PgAdmin provides web-based database management
- All services have health checks and auto-restart
