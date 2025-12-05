================================================================================
                              AGRIOS PROJECT NOTES
================================================================================
Last Updated: December 5, 2025

--------------------------------------------------------------------------------
CURRENT STATUS
--------------------------------------------------------------------------------

✅ COMPLETED MAJOR MILESTONES:
    [x] JWT Authentication System (access + refresh tokens)
    [x] gRPC Microservices Architecture (3 services)
    [x] Standardized Response Format
    [x] Token Rotation & Blacklist
    [x] Service Independence (can run separately)
    [x] Complete Documentation (4 comprehensive READMEs)
    [x] Docker & Terminal Setup Options
    [x] Graceful Degradation Implementation (Article Service)
    [x] Complete Logout (blacklist both tokens)

📋 IMPROVEMENT PLANS:
    → Service-1-User security hardening: See Note_Dec05.md
    → Service-2-Article: Completed with graceful degradation
    → Service-3-Gateway: Completed with enterprise resilience patterns

⚠️ KNOWN ISSUES (High-Level Summary):
    [ ] Service-1-User: Security gaps (password validation, rate limiting, etc.)
        → Detailed fix plan: docs/training/Note_Dec05.md
    [x] Service-2-Article: Graceful degradation implemented
    [x] Service-3-Gateway: Circuit breaker + timeout implemented

--------------------------------------------------------------------------------
NEXT STEPS
--------------------------------------------------------------------------------

IMMEDIATE (This Week):
    [x] Review Service-2-Article completeness → Graceful degradation done
    [x] Review Service-3-Gateway completeness → Enterprise patterns done
    [ ] Start implementing critical fixes from Note_Dec05.md (rate limiting, etc.)

ONGOING:
    [x] Monitor service health and performance → Health checks enhanced
    [x] Test all features thoroughly → Failure scenarios tested
    [x] Update documentation as needed → Training guide created
--------------------------------------------------------------------------------
COMPLETED FEATURES (Recent Work)
--------------------------------------------------------------------------------

### December 5, 2025 (Part 5 - Enterprise Resilience)
[x] Service-3-Gateway: Enterprise-Grade Resilience Patterns
    - Request-level timeout: 5s global HTTP + 3s per gRPC call
    - Circuit breaker: 5 failures → OPEN for 30s → HALF_OPEN test
    - Enhanced health checks: Shows connection + circuit breaker state
    - ServiceUnavailable response (503) when circuit open
    - Automatic recovery detection and reconnection
    
[x] Service Independence & Startup Order
    - Tested wrong startup order scenarios
    - Service-2: Crash loop without Service-1 (expected behavior)
    - Service-3: Retry with exponential backoff (1s → 2s → 4s → 8s → 16s)
    - Automatic reconnection when dependencies become available
    - Updated README with sequential startup guide
    
[x] Training Documentation: SERVICE_RESILIENCE.md
    - Problem statement with real test results
    - 3 connection patterns: Fail Fast, Retry, Circuit Breaker
    - Enterprise vs Startup comparison table
    - Production readiness checklist (6/10 items done)
    - Real-world failure scenario walkthrough
    - Phase 1 → Phase 2 → Phase 3 (Enterprise) progression
    
[x] Version Management
    - Bumped all services to v1.3.0
    - Fixed service-3 module paths to use GitHub
    - Removed replace directives (using published packages)
    - All services now independently versioned on GitHub

### December 5, 2025 (Part 4)
[x] Complete Logout Implementation (Blacklist Both Tokens)
    - Updated proto: LogoutRequest now accepts refresh_token (optional)
    - Modified Logout handler to blacklist BOTH access + refresh tokens
    - Gateway forwards both tokens to User Service
    - Tested: Both tokens added to blacklist with appropriate TTL
    - Security improved: Refresh token cannot be reused after logout
    
[x] Testing & Verification
    - Graceful Degradation: Article Service returns user:null when User Service down
    - Service Recovery: Auto-recovery when User Service back online
    - JWT Blacklist: Access token blacklisted with TTL ~900s (15 min)
    - Complete Logout: Both access + refresh tokens blacklisted
    - IAuto-cleanup: Redis TTL countdown verified (898s → 892s → 886s...)

### December 5, 2025 (Part 3)
[x] Documentation Restructuring & Cleanup
    - Moved DEPLOYMENT.md to root level (platform-wide)
    - Moved GRACEFUL_DEGRADATION_TESTING.md to service-2-article
    - Removed duplicate docs: COMPLETE_GUIDE.md, ARCHITECTURE_GUIDE.md, GRPC_COMMANDS.md
    - Consolidated JWT blacklist docs into service-1-user/README.md
    - Updated all cross-references in READMEs
    - docs/ folder now only contains subfolders (archive, templates, training, tutorials)

[x] JWT Blacklist System Documentation & Verification
    - Confirmed Redis TTL auto-cleanup works correctly
    - Access tokens: Auto-deleted after 15 minutes
    - Refresh tokens: Auto-deleted after 7 days
    - No manual cleanup needed - Redis handles automatically
    - Added comprehensive blacklist commands to User Service README
    - Verified TTL countdown behavior (898s → 892s → 886s...)

[x] Graceful Degradation Implementation (Article Service)
    - GetArticle: Returns article with author: null when User Service down
    - GetArticleWithUser: Enhanced error handling for all User Service failures
    - ListArticles: Tracks failed user fetches, continues returning articles
    - Added custom success message: "success (author information unavailable)"
    - Improved logging with WARN/ERROR levels for monitoring
    - Article Service no longer crashes when User Service unavailable

### December 5, 2025 (Part 2)
[x] Service Independence & Documentation Overhaul
    - Created 4 comprehensive README files (main + 3 services)
    - Each service can run independently with Docker or Terminal
    - Complete API documentation (13 endpoints with examples)
    - Troubleshooting guides for each service
    
[x] Response Cleanup
    - Removed redundant user data from login response
    - Login now returns only access_token and refresh_token

[x] Refresh Token Configuration
    - Set refresh token expiration to 7 days (168h)
    - Implemented token rotation security

### December 4, 2025
[x] JWT Refresh Token System
    - RefreshToken endpoint with token rotation
    - Token type validation (access vs refresh)
    - Redis blacklist integration
    - Separate validation methods for each token type

[x] API & Documentation Restructuring
    - Migrated all endpoints to gRPC backend
    - Standardized response format across all APIs
    - Complete gRPC and REST command documentation
    - Fixed partial update (optional fields support)

[x] Article Service Enhancements
    - Fixed article list pagination
    - Improved error descriptions
    - Added user authentication for article operations

### December 3, 2025
[x] Foundation Setup
    - JSON logging library
    - Sentinel Error pattern for standardized errors
    - Dynamic configuration (moved from hardcoded values)
    - Regex validation for strings
    - Login/logout with password hashing
    - Token expiration management



    ### 1. HTTP & REST API
    - HTTP là gì?
    - Method: `GET`, `POST`, `PUT`, `DELETE`, `PATCH`
    - Status Code: `200`, `201`, `400`, `401`, `403`, `404`, `500`
    - Header, Body, Query, Path param
    - RESTful API là gì?
    - JSON, form-data, multipart

    ### 2. SQL
    - `SELECT`, `INSERT`, `UPDATE`, `DELETE`
    - `WHERE`, `GROUP BY`, `HAVING`, `ORDER BY`
    - `JOIN`: `INNER`, `LEFT`, `RIGHT`
    - Index là gì? Khi nào cần index?
    - Transaction (`BEGIN`, `COMMIT`, `ROLLBACK`)
    - ACID

    ### 3. Authentication & Authorization
    - JWT là gì? Access token vs Refresh token
    - Role-based access control (RBAC)
    - Phân biệt:
        - Authentication (xác thực)
        - Authorization (phân quyền)
    ### 4. Git cơ bản
    - `clone`, `pull`, `push`
    - `commit`, `branch`, `merge`
    - `rebase`
    - Resolve conflict

    ### 5. Clean Code
    - Naming rõ ràng
    - Tách hàm nhỏ
    - Không hard-code

    ### 6. Bảo mật Backend
    - SQL Injection
    - XSS, CSRF
    - Hash password: bcrypt, argon2
    - HTTPS vs HTTP
    - Rate limit, brute force
    - Không log password, token

    ### 7. Performance & Scalability
    - Pagination
    - Caching (Redis)

================================================================================
                           QUICK REFERENCE GUIDE
================================================================================

--------------------------------------------------------------------------------
STANDARD RESPONSE FORMATS
--------------------------------------------------------------------------------

### Success Response (Single Item)
{
    "code": "000",
    "message": "success",
    "data": {
        "user": {...}  // or "article": {...}
    }
}

### Success Response (List with Pagination)
{
    "code": "000",
    "message": "success",
    "data": {
        "users": [...],  // or "articles": [...]
        "pagination": {
            "page": 1,
            "page_size": 10,
            "total_count": 66,
            "total_pages": 7
        }
    }
}

### Error Response
{
    "code": "001",  // Error code (001-006)
    "message": "Invalid email format"
}

### Error Codes Reference
| Code | Meaning           | HTTP Status |
|------|-------------------|-------------|
| 000  | Success           | 200         |
| 001  | Invalid argument  | 400         |
| 002  | Not found         | 404         |
| 003  | Already exists    | 409         |
| 004  | Unauthorized      | 401         |
| 005  | Permission denied | 403         |
| 006  | Internal error    | 500         |

--------------------------------------------------------------------------------
QUICK COMMAND REFERENCE
--------------------------------------------------------------------------------

### Start Services
# All services with Docker
docker-compose up -d

# Initialize databases
bash scripts/init-services.sh

# Seed test data (optional)
bash scripts/seed-data.sh

### Stop Services
docker-compose down

# With data cleanup
docker-compose down -v

### View Logs
docker-compose logs -f user-service
docker-compose logs -f article-service
docker-compose logs -f gateway

### Rebuild After Changes
docker-compose up -d --build user-service
docker-compose up -d --build article-service
docker-compose up -d --build gateway

--------------------------------------------------------------------------------
COMMON GRPC COMMANDS
--------------------------------------------------------------------------------

### User Service (Port 50051)

# Create User
grpcurl -plaintext \
  -d '{"name":"John Doe","email":"john@example.com","password":"pass123"}' \
  localhost:50051 user.UserService.CreateUser

# Login
grpcurl -plaintext \
  -d '{"email":"john@example.com","password":"pass123"}' \
  localhost:50051 user.UserService.Login

# Get User
grpcurl -plaintext -d '{"id":1}' localhost:50051 user.UserService.GetUser

# Refresh Token
grpcurl -plaintext \
  -d '{"refresh_token":"<token>"}' \
  localhost:50051 user.UserService.RefreshToken

### Article Service (Port 50052)

# Create Article
grpcurl -plaintext \
  -d '{"user_id":1,"title":"My Article","content":"Content..."}' \
  localhost:50052 article.ArticleService.CreateArticle

# Get Article
grpcurl -plaintext -d '{"id":1}' localhost:50052 article.ArticleService.GetArticle

# List Articles
grpcurl -plaintext \
  -d '{"page":1,"page_size":10}' \
  localhost:50052 article.ArticleService.ListArticles

--------------------------------------------------------------------------------
COMMON REST API COMMANDS
--------------------------------------------------------------------------------

### Authentication Flow

# 1. Register
curl -X POST http://localhost:8080/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John","email":"john@example.com","password":"pass123"}'

# 2. Login (save tokens)
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"john@example.com","password":"pass123"}'

# 3. Use access token
curl http://localhost:8080/api/v1/articles \
  -H "Authorization: Bearer <access_token>"

# 4. Refresh when expired
curl -X POST http://localhost:8080/api/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refresh_token":"<refresh_token>"}'

# 5. Logout
curl -X POST http://localhost:8080/api/v1/auth/logout \
  -H "Authorization: Bearer <access_token>"

--------------------------------------------------------------------------------
DEVELOPMENT WORKFLOWS
--------------------------------------------------------------------------------

### Regenerate Proto Files (After .proto Changes)

# User Service
cd service-1-user
protoc --go_out=. --go_opt=paths=source_relative \
  --go-grpc_out=. --go-grpc_opt=paths=source_relative \
  proto/user_service.proto

# Article Service
cd service-2-article
protoc --go_out=. --go_opt=paths=source_relative \
  --go-grpc_out=. --go-grpc_opt=paths=source_relative \
  proto/article_service.proto

### Rebuild Service After Code Changes

# User Service
cd service-1-user
go build -o bin/user-service ./cmd/server
docker-compose up -d --build user-service

# Article Service
cd service-2-article
go build -o bin/article-service ./cmd/server
docker-compose up -d --build article-service

# Gateway
cd service-3-gateway
go build -o bin/gateway ./cmd/server
docker-compose up -d --build gateway

### Database Operations

# Connect to PostgreSQL
docker-compose exec postgres psql -U agrios_user -d agrios_db

# Check users table
docker-compose exec postgres psql -U agrios_user -d agrios_db -c "SELECT * FROM users;"

# Check articles table
docker-compose exec postgres psql -U agrios_user -d agrios_db -c "SELECT * FROM articles;"

# Connect to Redis
docker-compose exec redis redis-cli

# Check blacklisted tokens
docker-compose exec redis redis-cli KEYS "blacklist:*"

### Clean Up and Reset

# Clean all data
bash scripts/clean-data.sh

# Restart fresh
docker-compose down -v
docker-compose up -d
sleep 15
bash scripts/init-services.sh
bash scripts/seed-data.sh

--------------------------------------------------------------------------------
TROUBLESHOOTING QUICK FIXES
--------------------------------------------------------------------------------

### "Port already in use"
netstat -ano | findstr :8080   # Find process
# Kill process or change port in docker-compose.yml

### "Database files incompatible"
bash scripts/clean-data.sh
docker-compose up -d

### "Cannot connect to service"
docker-compose ps  # Check service status
docker-compose restart <service-name>

### "Token invalid"
# Access token expires after 15 minutes - use refresh token
curl -X POST http://localhost:8080/api/v1/auth/refresh \
  -d '{"refresh_token":"<refresh_token>"}'

================================================================================
                           DOCUMENTATION INDEX
================================================================================

📁 Main Documentation:
   - README.md                          → Platform overview + all APIs
   - CHANGELOG.md                       → Version history
   - docs/ARCHITECTURE_GUIDE.md         → System design details
   - docs/DEPLOYMENT.md                 → Infrastructure setup
   - docs/GRPC_COMMANDS.md              → gRPC testing reference
✅ RECENTLY COMPLETED:
    [x] Circuit breaker pattern (Service-3-Gateway)
    [x] Request timeout pattern (context deadline)
    [x] Exponential backoff retry
    [x] Health checks and monitoring (enhanced)
    [x] Graceful degradation (Article Service)
📁 Training Materials:
   - docs/training/note.md              → This file (project overview)
   - docs/training/Note_Dec05.md        → Service-1-User improvement plan
   - docs/training/SERVICE_RESILIENCE.md → Service failure handling (NEW)
   - docs/training/training_p1.md       → Backend fundamentals
   - docs/training/Tranning.md          → Additional training content

📚 TO LEARN (Next Phase):
    [ ] Role-based access control (RBAC)
    [ ] CAPTCHA integration
    [ ] Email verification flow
    [ ] Password reset flow
    [ ] Audit logging
    [ ] Request ID tracing
    [ ] Graceful shutdown patterns
    [ ] Load balancing and scaling
    [ ] Response caching (Redis) for graceful degradation
    [ ] Metrics export (Prometheus)
    [ ] Distributed tracing (OpenTelemetry)
    [ ] Service mesh (Istio/Linkerd)G CHECKLIST
================================================================================

### Backend Fundamentals (See training_p1.md for details)

✅ COMPLETED:
    [x] HTTP & REST API basics
    [x] SQL fundamentals (CRUD, JOIN, Index, Transaction)
    [x] JWT Authentication (access + refresh tokens)
    [x] Git basics (clone, commit, push, merge)
    [x] Clean Code principles
    [x] Backend security (password hashing, SQL injection prevention)
    [x] Caching with Redis
    [x] Pagination

🚧 IN PROGRESS:
    [~] Rate limiting implementation
    [~] Circuit breaker pattern
    [~] Input validation and sanitization

📚 TO LEARN:
    [ ] Role-based access control (RBAC)
    [ ] CAPTCHA integration
    [ ] Email verification flow
    [ ] Password reset flow
    [ ] Audit logging
    [ ] Request ID tracing
    [ ] Health checks and monitoring
    [ ] Graceful shutdown patterns
    [ ] Load balancing and scaling

================================================================================