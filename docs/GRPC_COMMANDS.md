# gRPC Commands Reference

> **Quick reference for testing Agrios backend services directly via gRPC**

**Last Updated:** December 4, 2025  
**Services:** User Service (50051), Article Service (50052)

---

## Quick Start

**Prerequisites:**
- Services running: `docker-compose up -d`
- grpcurl installed (see installation below)

**Essential Commands:**
```bash
# 1. Create user
grpcurl -plaintext -d '{"name":"Test","email":"test@example.com","password":"pass123"}' localhost:50051 user.UserService.CreateUser

# 2. Login and save token
TOKEN=$(grpcurl -plaintext -d '{"email":"test@example.com","password":"pass123"}' localhost:50051 user.UserService.Login | grep 'accessToken' | cut -d'"' -f4)

# 3. Create article (with auth)
grpcurl -plaintext -H "authorization: Bearer $TOKEN" -d '{"title":"My Article","content":"Content..."}' localhost:50052 article.ArticleService.CreateArticle

# 4. Get article with user info
grpcurl -plaintext -d '{"id":1}' localhost:50052 article.ArticleService.GetArticle
```

**Response Format:** All endpoints return wrapped format:
```json
{
  "code": "000",
  "message": "success",
  "data": {...}
}
```

---

## Installation

**Tool:** grpcurl - https://github.com/fullstorydev/grpcurl

**Installation:**
```bash
# Linux
sudo apt install grpcurl

# Mac
brew install grpcurl

# Windows (with Go)
go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest
```

---

## Service Discovery

### List All Services
```bash
# User Service
grpcurl -plaintext localhost:50051 list

# Article Service
grpcurl -plaintext localhost:50052 list
```

### List Methods in Service
```bash
# User Service methods
grpcurl -plaintext localhost:50051 list user.UserService

# Article Service methods
grpcurl -plaintext localhost:50052 list article.ArticleService
```

### Describe Service/Method
```bash
# Describe UserService
grpcurl -plaintext localhost:50051 describe user.UserService

# Describe specific method
grpcurl -plaintext localhost:50051 describe user.UserService.CreateUser

# Describe message type
grpcurl -plaintext localhost:50051 describe user.CreateUserRequest
```

---

## User Service (port 50051)

### 1. Create User
```bash
grpcurl -plaintext \
  -d '{
    "name": "John Doe",
    "email": "john04@example.com",
    "password": "12345678"
  }' \
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
      "name": "John Doe",
      "email": "john02@example.com",
      "createdAt": "2025-12-04T10:00:00Z"
    }
  }
}
```

---

### 2. Login
```bash
grpcurl -plaintext \
  -d '{
    "email": "john04@example.com",
    "password": "12345678"
  }' \
  localhost:50051 user.UserService.Login
```

**Response:**
```json
{
  "code": "000",
  "message": "success",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "createdAt": "2025-12-04T10:00:00Z"
    }
  }
}
```

**Save token for later:**
```bash
# Method 1: Using jq (if installed)
TOKEN=$(grpcurl -plaintext \
  -d '{"email":"john02@example.com","password":"12345678"}' \
  localhost:50051 user.UserService.Login \
  | jq -r '.data.accessToken')

# Method 2: Using grep/cut (no jq needed)
TOKEN=$(grpcurl -plaintext \
  -d '{"email":"john02@example.com","password":"12345678"}' \
  localhost:50051 user.UserService.Login \
  | grep 'accessToken' | cut -d'"' -f4)

echo "Token: $TOKEN"
```

---

### 3. Get User by ID
```bash
grpcurl -plaintext \
  -d '{"id": 1}' \
  localhost:50051 user.UserService.GetUser
```

**Response:**
```json
{
  "code": "000",
  "message": "success",
  "data": {
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "createdAt": "2025-12-04T10:00:00Z",
      "updatedAt": "2025-12-04T10:00:00Z"
    }
  }
}
```

---

### 4. Update User
```bash
grpcurl -plaintext \
  -d '{
    "id": 1,
    "name": "John Updated",
    "email": "john.updated@example.com",
    "password": "newpass123"
  }' \
  localhost:50051 user.UserService.UpdateUser
```

**Response:**
```json
{
  "code": "000",
  "message": "success",
  "data": {
    "user": {
      "id": 1,
      "name": "John Updated",
      "email": "john.updated@example.com",
      "createdAt": "2025-12-04T10:00:00Z",
      "updatedAt": "2025-12-04T10:05:00Z"
    }
  }
}
```

---

### 5. List Users
```bash
grpcurl -plaintext \
  -d '{
    "page": 1,
    "page_size": 10
  }' \
  localhost:50051 user.UserService.ListUsers
```

**Response:**
```json
{
  "code": "000",
  "message": "success",
  "data": {
    "users": [
      {
        "id": 1,
        "name": "John Doe",
        "email": "john@example.com",
        "createdAt": "2025-12-04T10:00:00Z",
        "updatedAt": "2025-12-04T10:00:00Z"
      }
    ],
    "total": 1,
    "page": 1,
    "pageSize": 10,
    "totalPages": 1
  }
}
```

---

### 6. Validate Token
```bash
# Use token from login
grpcurl -plaintext \
  -d "{\"token\": \"$TOKEN\"}" \
  localhost:50051 user.UserService.ValidateToken
```

**Response (valid):**
```json
{
  "code": "000",
  "message": "success",
  "data": {
    "valid": true,
    "userId": 1,
    "email": "john@example.com"
  }
}
```

**Response (invalid):**
```json
{
  "code": "014",
  "message": "invalid token"
}
```

---

### 7. Logout
```bash
grpcurl -plaintext \
  -d "{\"token\": \"$TOKEN\"}" \
  localhost:50051 user.UserService.Logout
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

After logout, token is blacklisted:
```bash
# Try to validate revoked token
grpcurl -plaintext \
  -d "{\"token\": \"$TOKEN\"}" \
  localhost:50051 user.UserService.ValidateToken
```

**Response:**
```json
{
  "code": "014",
  "message": "token has been revoked"
}
```

---

### 8. Delete User
```bash
grpcurl -plaintext \
  -d '{"id": 1}' \
  localhost:50051 user.UserService.DeleteUser
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

## Article Service (port 50052)

### 1. Create Article

**Note:** Requires authentication via metadata (JWT token from login)

```bash
# With authentication
grpcurl -plaintext \
  -H "authorization: Bearer $TOKEN" \
  -d '{
    "title": "My First Article 3",
    "content": "This is the article content 3..."
  }' \
  localhost:50052 article.ArticleService.CreateArticle
```

**Response (success):**
```json
{
  "code": "000",
  "message": "success",
  "data": {
    "article": {
      "id": 1,
      "title": "My First Article",
      "content": "This is the article content...",
      "userId": 17,
      "createdAt": "2025-12-04T10:10:00Z",
      "updatedAt": "2025-12-04T10:10:00Z"
    }
  }
}
```

**Response (without auth):**
```json
{
  "code": "014",
  "message": "authentication required"
}
```

**Response (missing title):**
```json
{
  "code": "003",
  "message": "title is required"
}
```

---

### 2. Get Article (with User Join)
```bash
grpcurl -plaintext \
  -d '{"id": 1}' \
  localhost:50052 article.ArticleService.GetArticle
```

**Response (success):**
```json
{
  "code": "000",
  "message": "success",
  "data": {
    "article": {
      "article": {
        "id": 1,
        "title": "My First Article",
        "content": "This is the article content...",
        "userId": 1,
        "createdAt": "2025-12-04T10:10:00Z",
        "updatedAt": "2025-12-04T10:10:00Z"
      },
      "user": {
        "id": 1,
        "name": "John Doe",
        "email": "john@example.com",
        "createdAt": "2025-12-04T10:00:00Z"
      }
    }
  }
}
```

**Response (not found):**
```json
{
  "code": "005",
  "message": "article not found"
}
```

**Note:** Article Service calls User Service via gRPC to get user info!

---

### 3. Update Article
```bash
grpcurl -plaintext \
  -d '{
    "id": 1,
    "title": "Updated Title",
    "content": "Updated content here"
  }' \
  localhost:50052 article.ArticleService.UpdateArticle
```

**Response:**
```json
{
  "code": "000",
  "message": "success",
  "data": {
    "article": {
      "id": 1,
      "title": "Updated Title",
      "content": "Updated content here",
      "userId": 1,
      "createdAt": "2025-12-04T10:10:00Z",
      "updatedAt": "2025-12-04T10:15:00Z"
    }
  }
}
```

---

### 4. List Articles
```bash
# All articles
grpcurl -plaintext \
  -d '{
    "page": 1,
    "page_size": 10
  }' \
  localhost:50052 article.ArticleService.ListArticles

# Filter by user
grpcurl -plaintext \
  -d '{
    "page": 1,
    "page_size": 10,
    "user_id": 1
  }' \
  localhost:50052 article.ArticleService.ListArticles
```

**Response:**
```json
{
  "code": "000",
  "message": "success",
  "data": {
    "articles": [
      {
        "article": {
          "id": 1,
          "title": "My First Article",
          "content": "This is the article content...",
          "userId": 1,
          "createdAt": "2025-12-04T10:10:00Z",
          "updatedAt": "2025-12-04T10:10:00Z"
        },
        "user": {
          "id": 1,
          "name": "John Doe",
          "email": "john@example.com"
        }
      }
    ],
    "total": 1,
    "page": 1,
    "totalPages": 1
  }
}
```

---

### 5. Delete Article
```bash
grpcurl -plaintext \
  -d '{"id": 1}' \
  localhost:50052 article.ArticleService.DeleteArticle
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

## Response Format

### Wrapped Response Structure
All gRPC responses follow this format:

**Success:**
```json
{
  "code": "000",
  "message": "success",
  "data": {
    // Response-specific data here
  }
}
```

**Error:**
```json
{
  "code": "XXX",
  "message": "error description"
}
```

### Response Code Mapping

| Code | gRPC Code | Description | Example |
|------|-----------|-------------|---------|  
| 000 | OK | Success | Operation completed |
| 002 | UNKNOWN | Unknown error | Unexpected error |
| 003 | INVALID_ARGUMENT | Invalid input | Missing title, invalid email |
| 005 | NOT_FOUND | Resource not found | Article ID 999 not found |
| 006 | ALREADY_EXISTS | Duplicate | Email already registered |
| 007 | PERMISSION_DENIED | No permission | Insufficient permissions |
| 013 | INTERNAL | Internal error | Database error |
| 014 | UNAUTHENTICATED | Auth required | Missing/invalid token |
| 015 | UNAVAILABLE | Service unavailable | Service down |
| 016 | UNAUTHORIZED | Unauthorized | Invalid credentials |

---

## Legacy: Internal gRPC Error Codes

**Note:** These are internal gRPC codes for reference only. All responses are now wrapped with string codes (see Response Format section above).

| Code | Description | Example |
|------|-------------|---------|
| OK | Success | Operation completed successfully |
| CANCELLED | Client cancelled request | Client closed connection |
| UNKNOWN | Unknown error | Unexpected error occurred |
| INVALID_ARGUMENT | Invalid input | Missing required field, invalid email format |
| DEADLINE_EXCEEDED | Timeout | Request took too long |
| NOT_FOUND | Resource not found | User ID 999 does not exist |
| ALREADY_EXISTS | Duplicate | Email already registered |
| PERMISSION_DENIED | No permission | Insufficient permissions |
| UNAUTHENTICATED | Auth required | Invalid or missing token |
| UNAVAILABLE | Service down | User service is not responding |
| INTERNAL | Server error | Database connection failed |

---

## Complete Test Workflow

```bash
# 1. Create user
grpcurl -plaintext \
  -d '{"name":"Test User","email":"test@example.com","password":"pass123"}' \
  localhost:50051 user.UserService.CreateUser

# 2. Login and save token (no jq needed)
TOKEN=$(grpcurl -plaintext \
  -d '{"email":"test@example.com","password":"pass123"}' \
  localhost:50051 user.UserService.Login \
  | grep 'accessToken' | cut -d'"' -f4)

# 3. Validate token
grpcurl -plaintext \
  -d "{\"token\":\"$TOKEN\"}" \
  localhost:50051 user.UserService.ValidateToken

# 4. Create article (requires authentication)
grpcurl -plaintext \
  -H "authorization: Bearer $TOKEN" \
  -d '{"title":"Test Article","content":"Content here"}' \
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
  localhost:50051 user.UserService.Logout

# 8. Verify token is revoked
grpcurl -plaintext \
  -d "{\"token\":\"$TOKEN\"}" \
  localhost:50051 user.UserService.ValidateToken
# Should return: Code: Unauthenticated
```

---

## Tips & Tricks

### Save Request to File
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

### Extract Token Without jq
```bash
# If jq is not installed, use grep/cut:
TOKEN=$(grpcurl -plaintext -d '{"email":"user@example.com","password":"pass"}' \
  localhost:50051 user.UserService.Login | grep 'accessToken' | cut -d'"' -f4)

# Or use Python:
TOKEN=$(grpcurl -plaintext -d '{"email":"user@example.com","password":"pass"}' \
  localhost:50051 user.UserService.Login | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['accessToken'])")
```

### Add Metadata (Headers)
```bash
grpcurl -plaintext \
  -H "authorization: Bearer $TOKEN" \
  -H "x-request-id: 12345" \
  -d '{"id":1}' \
  localhost:50051 user.UserService.GetUser
```

### Check Service Health
```bash
# Check if service is responding
grpcurl -plaintext localhost:50051 list
grpcurl -plaintext localhost:50052 list

# If no response, service is down
```

---

**Document Version:** 1.0.0  
**Last Updated:** December 4, 2025  
**Services:** User Service (50051), Article Service (50052)
