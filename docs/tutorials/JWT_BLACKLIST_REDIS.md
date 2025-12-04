# Hướng dẫn triển khai JWT Blacklist với Redis

Tài liệu này hướng dẫn chi tiết các bước để xử lý vấn đề "Token vẫn dùng được sau khi Logout" (TODO #4) bằng cách sử dụng Redis làm Blacklist.

## Bước 1: Cập nhật Hạ tầng (Infrastructure)

Thêm service Redis vào file `docker-compose.yml` để có database chạy.

**File:** `docker-compose.yml`
```yaml
services:
  # ... (các service cũ)
  
  redis:
    image: redis:7-alpine
    container_name: agrios-redis
    ports:
      - "6379:6379"
    networks:
      - agrios-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  user-service:
    # ...
    environment:
      - REDIS_ADDR=redis:6379
      - REDIS_PASSWORD=
      - REDIS_DB=0
    depends_on:
      redis:
        condition: service_healthy
```

## Bước 2: Cài đặt thư viện Go

Cài đặt thư viện client Redis phổ biến nhất cho Go.

**Terminal:**
```bash
cd service-1-user
go get github.com/redis/go-redis/v9
```

## Bước 3: Cập nhật Cấu hình (Config)

Thêm thông tin kết nối Redis vào struct Config.

**File:** `service-1-user/internal/config/config.go`
1. Thêm struct `RedisConfig`:
   ```go
   type RedisConfig struct {
       Addr     string
       Password string
       DB       int
   }
   ```
2. Thêm field `Redis` vào struct `Config` chính.
3. Load giá trị từ Env trong hàm `Load()`:
   - `REDIS_ADDR` (default: "localhost:6379")
   - `REDIS_PASSWORD` (default: "")
   - `REDIS_DB` (default: 0)

## Bước 4: Tạo Redis Client

Tạo một package mới để quản lý kết nối Redis.

**File:** `service-1-user/internal/db/redis.go` (Tạo mới)
- Viết hàm `NewRedisClient(cfg config.RedisConfig) *redis.Client`.
- Hàm này khởi tạo kết nối và trả về `*redis.Client`.
- Nhớ `Ping` thử để đảm bảo kết nối thành công.

## Bước 5: Cập nhật TokenManager (Logic chính)

Sửa `TokenManager` để nó có thể "nói chuyện" với Redis.

**File:** `service-1-user/internal/auth/jwt.go`

1. **Cập nhật Struct:**
   Thêm `redisClient *redis.Client` vào struct `TokenManager`.

2. **Cập nhật Constructor:**
   Hàm `NewTokenManager` cần nhận thêm tham số `redisClient`.

3. **Thêm hàm `InvalidateToken` (Logout):**
   ```go
   func (m *TokenManager) InvalidateToken(tokenString string) error {
       // 1. Parse token để lấy thời gian hết hạn (exp)
       // 2. Tính thời gian còn lại (TTL = exp - now)
       // 3. Lưu vào Redis: SET key=tokenString, value="revoked", expiration=TTL
   }
   ```

4. **Cập nhật hàm `ValidateToken`:**
   Trước khi verify chữ ký, hãy kiểm tra Redis:
   ```go
   // Kiểm tra xem token có trong blacklist không
   val, err := m.redisClient.Get(ctx, tokenString).Result()
   if err == nil {
       return nil, errors.New("token has been revoked")
   }
   ```

## Bước 6: Kết nối mọi thứ (Wiring)

**File:** `service-1-user/cmd/server/main.go`

1. Khởi tạo Redis Client từ config.
2. Truyền Redis Client vào `NewTokenManager`.
3. Trong hàm `Logout` của `user_server.go`: Gọi `s.tokenManager.InvalidateToken(req.Token)`.

---
**Lưu ý:**
- Token string dùng làm key trong Redis có thể rất dài. Nếu muốn tối ưu, bạn có thể hash nó (MD5/SHA256) trước khi lưu làm key.
- Đảm bảo xử lý lỗi khi Redis bị chết (nếu Redis chết, có cho phép login không? Thường là Fail-open hoặc Fail-close tùy policy).
