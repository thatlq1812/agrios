# Agrios Microservices Platform Documentation

> **Enterprise-grade documentation for the Agrios distributed system**  
> Last Updated: December 4, 2025 | Version: 2.0.0

---

## 📖 Overview

Agrios is a microservices-based platform built with Go, gRPC, and REST API Gateway pattern featuring **wrapped response format** for all endpoints.

**Core Services:**
- **User Service** (port 50051) - Authentication, authorization, user management
- **Article Service** (port 50052) - Content management with user integration
- **API Gateway** (port 8080) - HTTP REST interface with gRPC backend

**Technology Stack:**
- Language: Go 1.21+
- Communication: gRPC (internal), REST (external)
- Databases: PostgreSQL 15, Redis 7
- Architecture: Microservices with API Gateway pattern

**Response Format:** All APIs use wrapped format:
```json
{
  "code": "000",
  "message": "success",
  "data": {...}
}
```

---

## 📚 Documentation Structure

### 📘 Primary Documentation

| Document | Description | Audience |
|----------|-------------|----------|
| **[COMPLETE_GUIDE.md](./COMPLETE_GUIDE.md)** | Comprehensive all-in-one guide with all sections | Everyone |
| **[GRPC_COMMANDS.md](./GRPC_COMMANDS.md)** | Complete gRPC testing reference with wrapped response examples | Developers, QA |
| **[ARCHITECTURE_GUIDE.md](./ARCHITECTURE_GUIDE.md)** | System architecture, design patterns, technical decisions | Architects, Senior Developers |

**Start with:** COMPLETE_GUIDE.md for full overview, then GRPC_COMMANDS.md for testing reference

---

### 📁 Additional Resources

| Folder | Contents |
|--------|----------|
| **[archive/](./archive/)** | Deprecated docs (pre-wrapped format, old guides) |
| **[templates/](./templates/)** | Report templates for documentation |
| **[tutorials/](./tutorials/)** | Step-by-step guides (JWT, Redis, workflows) |
| **[Architecture Guide](./ARCHITECTURE_GUIDE.md)** | Deep dive into system design | Understanding technical architecture |

### 📖 Tutorials

| Document | Description | Target Audience |
|----------|-------------|-----------------|
| **[JWT Blacklist with Redis](./tutorials/JWT_BLACKLIST_REDIS.md)** | Token revocation implementation | Backend Developers |
| **[Workflow Guide](./tutorials/WORKFLOW_GUIDE.md)** | Development workflow and Git practices | All Team Members |

### 📦 Archive

Previous documentation versions stored in **[archive/](./archive/)** directory.

---

## 🎯 Quick Navigation by Role

### 👨‍💻 I'm a... New Developer

**Read:** [📘 Complete Guide](./COMPLETE_GUIDE.md)
- Sections 1-5: Overview → Architecture → Quick Start → APIs → Development
- **Time:** 1-2 hours

### 🧪 I'm a... QA Engineer

**Read:** [📘 Complete Guide](./COMPLETE_GUIDE.md)
- Sections 3, 4, 6: Quick Start → APIs → Testing
- **Time:** 30-45 minutes

### ⚙️ I'm a... DevOps Engineer

**Read:** [📘 Complete Guide](./COMPLETE_GUIDE.md)
- Sections 2, 3, 7, 8: Architecture → Quick Start → Deployment → Operations
- **Time:** 30 minutes

### 🎨 I'm a... Frontend Developer

**Read:** [📘 Complete Guide](./COMPLETE_GUIDE.md)
- Sections 3, 4: Quick Start → API Documentation
- **Time:** 20-30 minutes

### 📊 I'm a... Manager/Product Owner

**Read:** [📘 Complete Guide](./COMPLETE_GUIDE.md)
- Section 1: System Overview
- **Time:** 10 minutes

---

## 🏗️ System Architecture at a Glance

```
Client (Browser/Mobile)
         ↓
    HTTP REST API (port 8080)
         ↓
    API Gateway
    ├─→ User Service (gRPC :50051)
    └─→ Article Service (gRPC :50052)
         ↓
    PostgreSQL + Redis
```

**Key Features:**
- ✅ JWT-based authentication with Redis blacklist
- ✅ gRPC for internal service communication
- ✅ REST API for external clients
- ✅ Standardized response format: `{"code":"000", "message":"success", "data":{}}`
- ✅ Microservices architecture with independent deployment
- ✅ Docker containerization support

---

## 📦 Repository Structure

```
agrios/
├── docs/                           # Documentation (you are here)
│   ├── README.md                   # This file
│   ├── ARCHITECTURE_GUIDE.md       # System architecture
│   ├── DEPLOYMENT_AND_TESTING.md   # Complete deployment guide
│   ├── API_REFERENCE.md            # API documentation
│   ├── OPERATIONS_GUIDE.md         # Operations manual
│   ├── TESTING_GUIDE.md            # Testing procedures
│   ├── tutorials/                  # Step-by-step guides
│   │   ├── JWT_BLACKLIST_REDIS.md
│   │   └── WORKFLOW_GUIDE.md
│   └── archive/                    # Deprecated docs
│
├── service-1-user/                 # User Service (gRPC)
├── service-2-article/              # Article Service (gRPC)
├── service-gateway/                # API Gateway (HTTP REST)
├── pkg/                            # Shared packages
└── scripts/                        # Utility scripts
```

---

## 🔑 Key Concepts

### Response Format Standard

All API responses follow this format:

```json
{
  "code": "000",           // String code: "000"-"016" (gRPC status codes)
  "message": "success",    // Human-readable message
  "data": {                // Response payload (optional)
    // ... actual data
  }
}
```

### Response Codes

| Code | Status | Description |
|------|--------|-------------|
| 000 | OK | Request successful |
| 003 | INVALID_ARGUMENT | Invalid input/validation error |
| 005 | NOT_FOUND | Resource not found |
| 006 | ALREADY_EXISTS | Duplicate resource |
| 016 | UNAUTHENTICATED | Authentication required |

[See complete list in API Reference](./API_REFERENCE.md#response-codes)

### Token Management

- **Access Token:** 15 minutes validity, used for API requests
- **Refresh Token:** 7 days validity, used to get new access tokens
- **Blacklist:** Revoked tokens stored in Redis with TTL

---

## 🚀 Quick Start Commands

### Docker Deployment (Recommended)

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### Local Development

```bash
# Terminal 1: User Service
cd service-1-user && go run cmd/server/main.go

# Terminal 2: Article Service
cd service-2-article && go run cmd/server/main.go

# Terminal 3: API Gateway
cd service-gateway && go run cmd/server/main.go
```

### Test API

```bash
# Health check
curl http://localhost:8080/health

# Create user
curl -X POST http://localhost:8080/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@example.com","password":"pass123"}'
```

[See complete testing guide](./DEPLOYMENT_AND_TESTING.md#api-testing-examples)

---

## 📞 Support & Contact

For questions or issues:

1. Check relevant documentation section
2. Review [Operations Guide](./OPERATIONS_GUIDE.md) for troubleshooting
3. Contact development team

---

## 📝 Documentation Standards

All documentation in this repository follows these standards:

- ✅ Written in English (code and docs)
- ✅ Markdown format with proper headings
- ✅ Code examples with syntax highlighting
- ✅ Clear section navigation
- ✅ Up-to-date with latest changes
- ✅ Versioned with last update date

---

## 🔄 Recent Updates

### December 4, 2025 - v1.0.0

- ✅ Restructured documentation to enterprise standards
- ✅ Consolidated deployment and testing guides
- ✅ Added comprehensive API testing examples
- ✅ Improved navigation and quick start guides
- ✅ Archived deprecated documentation

---

---

## 📊 Documentation Changes

### Version 2.0.0 (December 4, 2025)

**Major Consolidation:**
- ✅ Created **COMPLETE_GUIDE.md** - single comprehensive document
- ✅ Consolidated 5 separate docs into 1 unified guide
- ✅ Reduced documentation from ~80 pages to 1 complete reference
- ✅ Eliminated redundancy and outdated content
- ✅ Moved old docs to archive/

**Benefits:**
- 🎯 Single source of truth
- ⚡ Faster information access
- 📝 Easier maintenance
- 🔄 No duplicate content

### Previous Versions

See **[archive/](./archive/)** for historical documentation.

---

## 📄 License

Copyright © 2025 Agrios Platform. All rights reserved

1. Follow **[Operations Guide](./OPERATIONS_GUIDE.md)** for deployment procedures
2. Review monitoring and maintenance sections
3. Check troubleshooting guides for common issues

---

## 📖 Document Details

### API Reference
**File:** `API_REFERENCE.md`  
**Contains:**
- Service endpoints and ports
- Complete API method documentation
- Request/response examples for both User and Article services
- Authentication flow diagrams
- Error handling guidelines
- Development checklist

### Operations Guide
**File:** `OPERATIONS_GUIDE.md`  
**Contains:**
- System architecture overview
- Prerequisites and environment setup
- Database setup and migrations
- Local development instructions
- Docker deployment procedures
- Testing methods
- Troubleshooting common issues
- Monitoring and maintenance best practices

### Testing Guide
**File:** `TESTING_GUIDE.md`  
**Contains:**
- Testing prerequisites and setup
- 20+ test cases covering:
  - User Service (11 tests)
  - Article Service (7 tests)
  - Integration tests (2 tests)
- Expected request/response examples
- Troubleshooting tips
- Configuration notes

### Response Format Migration
**File:** `RESPONSE_FORMAT_MIGRATION.md`  
**Contains:**
- Current vs target response formats
- Migration strategies (proto-level vs application-level)
- Implementation guide
- Code examples
- Best practices

### JWT Blacklist Tutorial
**File:** `tutorials/JWT_BLACKLIST_REDIS.md`  
**Contains:**
- Step-by-step Redis integration
- Token invalidation implementation
- Configuration setup
- Code examples
- Testing procedures

### Workflow Guide
**File:** `tutorials/WORKFLOW_GUIDE.md`  
**Contains:**
- GitHub Flow process
- Branch naming conventions
- Commit message standards
- Pull Request procedures
- Common Git commands

---

## 🏗️ System Architecture

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

### Key Components

- **User Service:** Authentication, user management, JWT token handling
- **Article Service:** Article CRUD with user integration
- **PostgreSQL:** Primary data storage
- **Redis:** Token blacklisting and caching
- **PgAdmin:** Database management UI (optional)

---

## 🔧 Common Commands

### Start All Services
```bash
cd /d/agrios
docker-compose up -d --build
```

### Check Service Status
```bash
docker ps
```

### View Logs
```bash
# User Service
docker logs agrios-user-service --tail 50 -f

# Article Service
docker logs agrios-article-service --tail 50 -f
```

### Test gRPC Endpoints
```bash
# List available methods
grpcurl -plaintext localhost:50051 list

# Call a method
grpcurl -plaintext -d '{"id": 1}' localhost:50051 user.UserService/GetUser
```

### Database Access
```bash
# Connect to PostgreSQL
docker exec -it agrios-postgres psql -U postgres

# Connect to Redis
docker exec -it agrios-redis redis-cli
```

---

## 📝 Response Code Standards

All services use standardized response codes:

| Code | Meaning | Usage |
|------|---------|-------|
| `000` | Success | Operation completed successfully |
| `400` | Bad Request | Invalid input or validation error |
| `401` | Unauthorized | Authentication failed or token invalid |
| `404` | Not Found | Resource does not exist |
| `409` | Conflict | Duplicate resource (e.g., email exists) |
| `500` | Internal Error | Server-side error |

---

## 🔐 Authentication

### Token Types

- **Access Token:** Short-lived (24 hours), used for API requests
- **Refresh Token:** Long-lived (7 days), used to obtain new access tokens

### Token Usage

All Article Service endpoints require authentication:

```bash
grpcurl -plaintext \
  -H "authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{"id": 1}' \
  localhost:50052 article.ArticleService/GetArticle
```

### Token Blacklisting

Tokens are blacklisted in Redis upon logout:
- Key format: `blacklist:{token}`
- TTL matches token expiration
- Validated on every request

---

## 🧪 Testing Workflow

1. **Setup Environment**
   ```bash
   docker-compose up -d --build
   ```

2. **Create Test User**
   ```bash
   grpcurl -plaintext -d '{
     "name": "Test User",
     "email": "test@example.com",
     "password": "Test123456"
   }' localhost:50051 user.UserService/CreateUser
   ```

3. **Login and Save Token**
   ```bash
   grpcurl -plaintext -d '{
     "email": "test@example.com",
     "password": "Test123456"
   }' localhost:50051 user.UserService/Login
   
   # Save the accessToken from response
   export TOKEN="YOUR_ACCESS_TOKEN"
   ```

4. **Test Protected Endpoints**
   ```bash
   grpcurl -plaintext \
     -H "authorization: Bearer $TOKEN" \
     -d '{"title": "Test", "content": "Content", "user_id": 1}' \
     localhost:50052 article.ArticleService/CreateArticle
   ```

---

## 🐛 Troubleshooting

### Services Won't Start

1. Check Docker is running: `docker ps`
2. Check logs: `docker logs agrios-user-service`
3. Verify ports are available: `netstat -an | grep 50051`
4. Rebuild: `docker-compose down && docker-compose up -d --build`

### Database Connection Issues

1. Verify PostgreSQL is healthy: `docker ps`
2. Check connection: `docker exec -it agrios-postgres psql -U postgres`
3. Verify databases exist: `\l` in psql
4. Check permissions: See Operations Guide

### Redis Connection Issues

1. Verify Redis is running: `docker ps`
2. Test connection: `docker exec -it agrios-redis redis-cli ping`
3. Check keys: `docker exec -it agrios-redis redis-cli KEYS *`

### gRPC Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `Unauthenticated` | Missing/invalid token | Check token in authorization header |
| `NotFound` | Resource doesn't exist | Verify ID exists in database |
| `Internal` | Server error | Check service logs |
| `Unavailable` | Service down | Verify service is running |

---

## 📦 Templates

Template documents are available in the `templates/` directory:

- **Report Templates:** PR templates, commit message conventions
- **Issue Templates:** Bug reports, feature requests

---

## 🤝 Contributing

When adding new documentation:

1. Follow the existing structure and format
2. Use clear, concise language
3. Include code examples where appropriate
4. Update this README with links to new docs
5. Add entry to Change Log in the document

---

## 📞 Support

For questions or issues:

1. Check the relevant documentation first
2. Review troubleshooting sections
3. Check service logs for errors
4. Contact the development team

---

## 📄 Change Log

| Date | Changes | Author |
|------|---------|--------|
| 2025-12-04 | Initial documentation index created | GitHub Copilot |
| 2025-12-04 | Added comprehensive testing guide | GitHub Copilot |
| 2025-12-03 | Added operations guide and API reference | Team |

---

## 📚 Additional Resources

- [Go Documentation](https://golang.org/doc/)
- [gRPC Documentation](https://grpc.io/docs/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Redis Documentation](https://redis.io/documentation)
- [Docker Documentation](https://docs.docker.com/)

---

**For the latest updates, always refer to the individual documentation files.**
