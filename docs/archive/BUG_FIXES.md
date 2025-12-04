# Bug Fixes and Configuration Updates

## Issues Fixed

### 1. Response Code Format (Test 5)

**Problem:** Response returned `"code":"000"` instead of `"code":"0"`

**Root Cause:** Code constants in `service-gateway/internal/response/wrapper.go` used 3-digit format

**Solution:** Changed all code constants to single/double digit format matching gRPC standard:
- `CodeOK = "0"` (was "000")
- `CodeInvalidArgument = "3"` (was "003")
- `CodeNotFound = "5"` (was "005")
- `CodeUnauthenticated = "16"` (was "016")

**Files Modified:**
- `service-gateway/internal/response/wrapper.go`

---

### 2. Article Creation Authentication (Test Failed)

**Problem:** Cannot create articles because JWT token not forwarded to Article Service

**Root Cause:** Gateway was calling Article Service with `context.Background()` without JWT token in metadata

**Solution:** 
1. Added `extractToken()` helper function to get JWT from HTTP `Authorization: Bearer <token>` header
2. Modified `CreateArticle()` to:
   - Extract token from HTTP request
   - Return 401 if no token
   - Forward token in gRPC metadata: `metadata.AppendToOutgoingContext(ctx, "authorization", "Bearer "+token)`

**Files Modified:**
- `service-gateway/internal/handler/article_handler.go`

**Usage:**
```bash
# 1. Login first
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"pass123"}'

# Response: {"code":"0","message":"success","data":{"access_token":"...","refresh_token":"...","user":{...}}}

# 2. Create article with token
curl -X POST http://localhost:8080/api/v1/articles \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <access_token>" \
  -d '{"title":"My Article","content":"Content here","user_id":1}'
```

---

### 3. Token Duration Configuration

**Problem:** Refresh token too long (mentor feedback)

**Root Cause:** Default configuration not specified in .env file, using hardcoded defaults

**Solution:**
1. Changed default Access Token duration from 24 hours to 15 minutes (security best practice)
2. Kept Refresh Token at 7 days (168 hours)
3. Added explicit configuration to `.env` file

**Files Modified:**
- `service-1-user/internal/config/config.go` - Changed default from `24*time.Hour` to `15*time.Minute`
- `service-1-user/.env` - Added:
  ```
  ACCESS_TOKEN_DURATION=15m
  REFRESH_TOKEN_DURATION=168h
  ```

**Explanation for Mentor:**
- **Access Token (15 minutes):** Short-lived token for API requests, expires quickly for security
- **Refresh Token (7 days):** Long-lived token to get new access tokens without re-login
- **Why Refresh Token is Longer:** 
  - Access tokens are used frequently and sent with every request (higher risk if stolen)
  - Refresh tokens are only used once every 15 minutes to get new access token
  - If access token stolen, it's only valid for 15 minutes
  - Refresh tokens can be revoked in Redis blacklist if needed

**Token Flow:**
```
1. User Login → Get both tokens
2. Use Access Token for 15 minutes
3. Access Token expires
4. Use Refresh Token to get new Access Token
5. Repeat until Refresh Token expires (7 days)
6. User must login again
```

**Security Benefits:**
- Access token exposure window: 15 minutes (was 24 hours)
- Reduced risk of token replay attacks
- Can revoke refresh token to block all future access

---

### 4. Test 7 GetArticle "Error"

**Status:** Not actually an error - working as expected

**Response:** `{"code":"005","message":"article with ID 1 not found"}`

**Explanation:** 
- Code "005" = NOT_FOUND (correct gRPC status)
- Article ID 1 doesn't exist yet (no articles created)
- This is the expected behavior when requesting non-existent resource

**To Fix:** Create an article first, then test GetArticle with the returned ID

---

## Testing Workflow

### Complete Test Sequence

```bash
# 1. Create User
curl -X POST http://localhost:8080/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","password":"pass123"}'

# Response: {"code":"0","message":"success","data":{"id":1,...}}

# 2. Login
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"pass123"}'

# Response: {"code":"0","message":"success","data":{"access_token":"eyJ...","refresh_token":"eyJ...","user":{...}}}
# Save the access_token for next requests

# 3. List Users (Test 5 - Fixed)
curl "http://localhost:8080/api/v1/users?page=1&page_size=10"

# Response: {"code":"0","message":"success","data":{"items":[...],"total":1,"page":1,"size":10,"has_more":false}}

# 4. Create Article (Now Works with Token)
curl -X POST http://localhost:8080/api/v1/articles \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <access_token_from_step_2>" \
  -d '{"title":"My First Article","content":"Article content","user_id":1}'

# Response: {"code":"0","message":"success","data":{"id":1,...}}

# 5. Get Article (Test 7 - Now Returns Data)
curl http://localhost:8080/api/v1/articles/1

# Response: {"code":"0","message":"success","data":{"id":1,"title":"My First Article",...}}

# 6. Logout
curl -X POST http://localhost:8080/api/v1/auth/logout \
  -H "Content-Type: application/json" \
  -d '{"token":"<access_token>"}'

# Response: {"code":"0","message":"success","data":{"success":true}}
```

---

## Configuration Summary

### Environment Variables

**service-1-user/.env:**
```env
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=agrios_users

JWT_SECRET=JCnk0Rlhh23uuDAunpeDtW2uHUqKF//jNBwNDM0KxtE=
ACCESS_TOKEN_DURATION=15m      # New: Short-lived for security
REFRESH_TOKEN_DURATION=168h    # New: 7 days for convenience

REDIS_ADDR=localhost:6379
```

**service-2-article/.env:**
```env
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=agrios_articles

USER_SERVICE_ADDR=localhost:50051
```

**service-gateway/.env:**
```env
USER_SERVICE_ADDR=127.0.0.1:50051
ARTICLE_SERVICE_ADDR=127.0.0.1:50052
GATEWAY_PORT=8080
```

---

## Restart Services

After these changes, restart all services:

```bash
# Terminal 1: User Service
cd d:/agrios/service-1-user
go run cmd/server/main.go

# Terminal 2: Article Service  
cd d:/agrios/service-2-article
go run cmd/server/main.go

# Terminal 3: Gateway
cd d:/agrios/service-gateway
go run cmd/server/main.go
```

---

## Response Code Reference

| Code | gRPC Status | HTTP Status | Description |
|------|-------------|-------------|-------------|
| 0 | OK | 200 | Success |
| 3 | INVALID_ARGUMENT | 400 | Bad request / validation error |
| 5 | NOT_FOUND | 404 | Resource not found |
| 6 | ALREADY_EXISTS | 409 | Duplicate resource |
| 7 | PERMISSION_DENIED | 403 | Forbidden |
| 13 | INTERNAL | 500 | Internal server error |
| 16 | UNAUTHENTICATED | 401 | Authentication required |
