# Service Resilience and Failure Handling

> Training guide on handling service failures and implementing resilient microservices

**Date:** December 5, 2025  
**Author:** Training Team  
**Topic:** Graceful Degradation & Service Recovery

---

## Table of Contents

1. [Overview](#overview)
2. [Problem Statement](#problem-statement)
3. [Connection Patterns](#connection-patterns)
4. [Implementation](#implementation)
5. [Testing Scenarios](#testing-scenarios)
6. [Best Practices](#best-practices)
7. [Production Checklist](#production-checklist)

---

## Overview

In microservices architecture, services can become unavailable due to:
- Network issues
- Service crashes
- Deployment/updates
- Resource exhaustion
- Configuration errors

**Key Question:** How should services behave when dependencies are unavailable?

---

## Problem Statement

### Initial Behavior (Before Fix)

**Service-2 (Article Service):**
```go
// ❌ Old code: Fail fast, no retry
userClient, err := client.NewUserClient(cfg.UserServiceAddr)
if err != nil {
    log.Fatalf("Failed to connect: %v", err) // DIE immediately
}
```

**Result:** Crash and restart loop when User Service unavailable
- ✅ Good: Fails fast, easy to detect issues
- ❌ Bad: No resilience, keeps restarting

**Service-3 (Gateway):**
```go
// ❌ Old code: Non-blocking dial (false success)
userConn, err := grpc.Dial(
    userServiceAddr,
    grpc.WithTimeout(5*time.Second), // Deprecated, doesn't block
)
// Connection appears successful but isn't really connected
```

**Result:** Starts successfully but returns 503 errors
- ✅ Good: Service starts
- ❌ Bad: False positive - looks healthy but fails on requests
- ❌ Bad: No automatic reconnection

### Test Results

```bash
# Test 1: Start Service-2 without Service-1
$ docker-compose up -d
# Result: Service-2 crashes every 5-6 seconds
[UserClient] Failed to connect: context deadline exceeded
Failed to connect to user service: rpc error: code = Unavailable
# Container restarts infinitely ♻️

# Test 2: Start Service-3 without backends
$ docker-compose up -d
# Result: Starts OK, but API fails
$ curl http://localhost:8080/api/v1/users
HTTP/1.1 503 Service Unavailable
{"code":"014","message":"connection error: connection refused"}
```

---

## Connection Patterns

### Pattern 1: Fail Fast (Service-2 Current)

**When to use:**
- Development environment
- Detecting configuration errors early
- Services that can't function without dependencies

**Pros:**
- ✅ Clear error visibility
- ✅ Fast feedback on misconfigurations
- ✅ Simple to understand

**Cons:**
- ❌ No resilience during temporary outages
- ❌ Restart loop wastes resources
- ❌ Can cause cascading failures

### Pattern 2: Retry with Exponential Backoff (Recommended)

**When to use:**
- Production environments
- Handling temporary network issues
- Service startup ordering flexibility

**Pros:**
- ✅ Handles temporary failures gracefully
- ✅ Automatic recovery when service returns
- ✅ Reduces restart churn
- ✅ Flexible startup ordering

**Cons:**
- ⚠️ Slower startup if dependencies down
- ⚠️ More complex error handling

### Pattern 3: Circuit Breaker (Advanced)

**When to use:**
- High-traffic production systems
- Preventing cascading failures
- When you need fast failure detection

**Pros:**
- ✅ Protects from overloading failing services
- ✅ Fast failure mode
- ✅ Automatic recovery testing

**Cons:**
- ⚠️ Requires additional library (e.g., gobreaker)
- ⚠️ More complex state management

---

## Implementation

### Fixed: Service-3 Gateway with Retry Logic

```go
// connectWithRetry attempts to establish gRPC connection with exponential backoff
func connectWithRetry(address string, serviceName string, maxRetries int) (*grpc.ClientConn, error) {
    backoff := 1 * time.Second
    maxBackoff := 30 * time.Second

    for i := 0; i < maxRetries; i++ {
        log.Printf("[%s] Connection attempt %d/%d to %s", serviceName, i+1, maxRetries, address)

        ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
        conn, err := grpc.DialContext(
            ctx,
            address,
            grpc.WithTransportCredentials(insecure.NewCredentials()),
            grpc.WithBlock(), // Block until connected or timeout
        )
        cancel()

        if err == nil {
            log.Printf("[%s] Successfully connected to %s", serviceName, address)
            return conn, nil
        }

        log.Printf("[%s] Connection attempt %d failed: %v", serviceName, i+1, err)

        if i < maxRetries-1 {
            log.Printf("[%s] Retrying in %v...", serviceName, backoff)
            time.Sleep(backoff)

            // Exponential backoff
            backoff *= 2
            if backoff > maxBackoff {
                backoff = maxBackoff
            }
        }
    }

    return nil, fmt.Errorf("failed to connect after %d retries", maxRetries)
}
```

**Key Changes:**
1. ✅ `grpc.WithBlock()` - Actually waits for connection
2. ✅ Retry loop with configurable attempts
3. ✅ Exponential backoff (1s → 2s → 4s → 8s → 16s → 30s max)
4. ✅ Detailed logging for debugging
5. ✅ Context timeout per attempt

### Enhanced Health Check

```go
router.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")
    
    // Check User Service connection state
    userState := userConn.GetState().String()
    userHealthy := userState == "READY"
    
    // Check Article Service connection state
    articleState := articleConn.GetState().String()
    articleHealthy := articleState == "READY"
    
    // Overall health
    overallHealthy := userHealthy && articleHealthy
    statusCode := http.StatusOK
    status := "healthy"
    
    if !overallHealthy {
        statusCode = http.StatusServiceUnavailable
        status = "degraded"
    }
    
    response := fmt.Sprintf(`{
        "status": "%s",
        "services": {
            "user_service": {
                "status": "%s",
                "healthy": %v
            },
            "article_service": {
                "status": "%s",
                "healthy": %v
            }
        }
    }`, status, userState, userHealthy, articleState, articleHealthy)
    
    w.WriteHeader(statusCode)
    w.Write([]byte(response))
}).Methods("GET")
```

**Health Check States:**
- `READY` - Connection healthy ✅
- `CONNECTING` - Attempting to connect 🔄
- `TRANSIENT_FAILURE` - Temporary failure ⚠️
- `IDLE` - Connection idle but available 💤
- `SHUTDOWN` - Connection closed ❌

---

## Testing Scenarios

### Scenario 1: Cold Start (No Services Running)

```bash
# Start Gateway first (wrong order)
cd service-3-gateway
docker-compose up

# Expected behavior:
# [User Service] Connection attempt 1/5 to host.docker.internal:50051
# [User Service] Connection attempt 1 failed: context deadline exceeded
# [User Service] Retrying in 1s...
# [User Service] Connection attempt 2/5 to host.docker.internal:50051
# ... continues retrying with exponential backoff ...
# After 5 retries: Failed to connect to User Service after retries
# Container exits with error (Docker will restart if configured)
```

**Result:** ✅ Clear failure with detailed logs, no silent failures

### Scenario 2: Gradual Service Startup

```bash
# Step 1: Start Gateway (will retry)
cd service-3-gateway
docker-compose up -d

# Step 2: Start User Service (Gateway auto-connects)
cd ../service-1-user
docker-compose up -d
sleep 15

# Step 3: Start Article Service (Gateway auto-connects)
cd ../service-2-article
docker-compose up -d

# Check logs
docker logs gateway
# [User Service] Connection attempt 3/5 to host.docker.internal:50051
# [User Service] ✓ Successfully connected to host.docker.internal:50051
# ✓ Connected to User Service
# [Article Service] Connection attempt 2/5 to host.docker.internal:50052
# [Article Service] ✓ Successfully connected to host.docker.internal:50052
# ✓ Connected to Article Service
# API Gateway listening on :8080
```

**Result:** ✅ Automatic recovery as services become available

### Scenario 3: Service Goes Down Mid-Operation

```bash
# All services running
docker ps

# Kill User Service
docker stop user-service-app

# Test Gateway
curl http://localhost:8080/health
# {
#   "status": "degraded",
#   "services": {
#     "user_service": {"status": "TRANSIENT_FAILURE", "healthy": false},
#     "article_service": {"status": "READY", "healthy": true}
#   }
# }

# API calls fail gracefully
curl http://localhost:8080/api/v1/users
# HTTP 503 Service Unavailable
# {"code":"014","message":"connection error: ..."}

# Restart User Service
docker start user-service-app
sleep 10

# Check health again
curl http://localhost:8080/health
# {
#   "status": "healthy",
#   "services": {
#     "user_service": {"status": "READY", "healthy": true},
#     "article_service": {"status": "READY", "healthy": true}
#   }
# }
```

**Result:** ✅ Gateway automatically reconnects when service returns

### Scenario 4: Network Partition

```bash
# Simulate network issue by blocking ports
iptables -A INPUT -p tcp --dport 50051 -j DROP  # Linux
# Or use Docker network disconnect

# Gateway logs:
# [GET] /api/v1/users 172.20.0.1:59308
# Error: rpc error: code = Unavailable desc = connection error

# Fix network
iptables -D INPUT -p tcp --dport 50051 -j DROP

# Gateway automatically recovers (gRPC handles reconnection internally)
```

**Result:** ✅ Automatic recovery after network restoration

---

## Best Practices

### 1. Connection Management

**DO:**
- ✅ Use `grpc.WithBlock()` for explicit connection verification
- ✅ Implement retry logic with exponential backoff
- ✅ Set reasonable timeout per connection attempt (10s recommended)
- ✅ Log all connection attempts with detail
- ✅ Use context for cancellation and timeouts

**DON'T:**
- ❌ Use deprecated `grpc.WithTimeout()` (use context instead)
- ❌ Infinite retry without backoff (wastes resources)
- ❌ Silent failures (always log errors)
- ❌ Assume connection is ready without checking

### 2. Retry Configuration

```go
const (
    maxRetries       = 5              // Total attempts
    initialBackoff   = 1 * time.Second
    maxBackoff       = 30 * time.Second
    connectionTimeout = 10 * time.Second // Per attempt
)
```

**Tuning Guidelines:**
- **Development:** 3-5 retries, short backoff (faster feedback)
- **Production:** 5-10 retries, longer backoff (handle temporary issues)
- **Critical Services:** Consider infinite retry with max backoff cap

### 3. Health Checks

**Implement Multi-Level Health:**
```
/health           - Overall service health
/health/ready     - Ready to serve traffic (all dependencies up)
/health/live      - Service alive (not hung/crashed)
```

**Response Codes:**
- `200 OK` - Fully healthy
- `503 Service Unavailable` - Degraded (some dependencies down)
- `500 Internal Server Error` - Critical failure

### 4. Error Handling

```go
// Good: Specific error messages
return nil, fmt.Errorf("failed to connect to %s after %d retries (last error: %v)", 
    serviceName, maxRetries, lastErr)

// Bad: Generic errors
return nil, fmt.Errorf("connection failed")
```

### 5. Observability

**Log Critical Events:**
- Service startup
- Connection attempts (with attempt number)
- Connection failures (with reason)
- Successful connections
- Connection state changes

**Metrics to Track:**
- Connection retry count
- Time to establish connection
- Failed connection rate
- Service dependency availability percentage

---

## Production Checklist

### Before Deployment

- [ ] All services have retry logic implemented
- [ ] Connection timeouts configured appropriately
- [ ] Health checks return accurate status
- [ ] Logs include enough detail for debugging
- [ ] Error messages are actionable
- [ ] Exponential backoff prevents resource exhaustion

### Service Configuration

```yaml
# docker-compose.yml
services:
  gateway:
    restart: unless-stopped  # Auto-restart on failure
    depends_on:
      user-service:
        condition: service_healthy
      article-service:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 40s  # Grace period during startup
```

### Monitoring Alerts

```yaml
alerts:
  - name: ServiceConnectionFailure
    condition: connection_retry_count > 10 in 5min
    severity: warning
    
  - name: ServiceDependencyDown
    condition: health_check_status == "degraded" for 5min
    severity: critical
    
  - name: HighConnectionRetryRate
    condition: retry_rate > 50% in 10min
    severity: warning
```

### Kubernetes Considerations

```yaml
# deployment.yaml
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  template:
    spec:
      containers:
      - name: gateway
        livenessProbe:
          httpGet:
            path: /health/live
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
```

---

---

## Enterprise-Grade Implementation (Updated)

### Phase 2 Improvements: Production-Ready Patterns

Based on enterprise feedback, we've implemented additional critical patterns:

#### 1. Request-Level Timeout (Context Deadline)

**Problem:** Gateway waiting forever for slow backend → Resource exhaustion

**Solution:**
```go
// Global timeout middleware
router.Use(middleware.TimeoutMiddleware(5 * time.Second))

// Per-request context
func (h *UserHandler) CreateUser(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context() // Gets context from middleware with timeout
    
    // Fallback if no timeout set
    if _, hasDeadline := ctx.Deadline(); !hasDeadline {
        var cancel context.CancelFunc
        ctx, cancel = context.WithTimeout(ctx, 3*time.Second)
        defer cancel()
    }
    
    resp, err := h.userClient.CreateUser(ctx, &userpb.CreateUserRequest{...})
}
```

**Impact:**
- ✅ Prevents hanging requests
- ✅ Returns 504 Gateway Timeout after 5s
- ✅ Frees resources quickly

#### 2. Circuit Breaker Implementation

**Problem:** Continuous retries to dead service wastes resources and delays failure response

**Solution:**
```go
// Simple but effective circuit breaker
type Breaker struct {
    maxFailures  uint32        // 5 failures → Open
    resetTimeout time.Duration // 30s wait before retry
    state        State         // Closed/Open/Half-Open
    failures     uint32
}

// Usage in handler
err = h.circuitBreaker.Execute(ctx, func(ctx context.Context) error {
    resp, err = h.userClient.CreateUser(ctx, &userpb.CreateUserRequest{...})
    return err
})

if err == circuit.ErrCircuitOpen {
    response.ServiceUnavailable(w, "user service temporarily unavailable")
    return
}
```

**States:**
- **Closed (Normal):** All requests pass through
- **Open (Tripped):** After 5 failures, block all requests for 30s
- **Half-Open (Testing):** After 30s, allow 1 test request
  - Success → Back to Closed
  - Failure → Back to Open

**Impact:**
- ✅ Fast failure (immediate 503 response when circuit open)
- ✅ Prevents thundering herd on recovery
- ✅ Automatic service health testing
- ✅ Reduces load on failing service

#### 3. Enhanced Health Check with Circuit State

```go
router.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
    userState := userConn.GetState().String()
    userCircuitState := userCircuit.GetStateString()
    
    response := {
        "status": "healthy",
        "services": {
            "user_service": {
                "connection": userState,      // "READY", "CONNECTING", etc.
                "circuit_breaker": userCircuitState, // "CLOSED", "OPEN", "HALF_OPEN"
                "healthy": userState == "READY" && userCircuitState == "CLOSED"
            }
        }
    }
    
    if !healthy {
        w.WriteHeader(http.StatusServiceUnavailable)
    }
})
```

**Impact:**
- ✅ Kubernetes/Load Balancer knows when to stop routing traffic
- ✅ Monitoring systems get detailed service state
- ✅ Operations team can diagnose issues quickly

---

## Summary

### Key Takeaways

1. **Fail Fast vs Resilient:** Choose based on environment and criticality
2. **Retry with Backoff:** Essential for production resilience
3. **Circuit Breaker:** Mandatory for preventing cascading failures ⭐
4. **Request Timeouts:** Must-have to prevent resource exhaustion ⭐
5. **Health Checks:** Must reflect actual dependency status
6. **Observability:** Detailed logs and metrics crucial for debugging
7. **Testing:** Regularly test failure scenarios

### Implementation Timeline

**Phase 1 (Initial):**
- Service-2: Fail-fast approach (crash loop)
- Service-3: Silent failure, 503 errors
- No timeout protection
- Basic health checks

**Phase 2 (After First Fix):**
- Service-3: Retry logic with exponential backoff ✅
- Enhanced health checks with connection state ✅
- Automatic recovery ✅

**Phase 3 (Enterprise-Grade - Current):**
- Request-level timeouts (5s global, 3s per gRPC call) ✅
- Circuit breaker pattern (5 failures → 30s cooldown) ✅
- Health checks with circuit state ✅
- Graceful degradation ready (503 with clear message) ✅

### Production Readiness Checklist

**Must-Have (Implemented):**
- [x] Connection retry with exponential backoff
- [x] Request timeout (context deadline)
- [x] Circuit breaker for each backend service
- [x] Detailed health checks
- [x] Graceful error responses
- [x] Structured logging

**Should-Have (Next Phase):**
- [ ] Response caching (Redis) for graceful degradation
- [ ] Metrics export (Prometheus) for monitoring
- [ ] Distributed tracing (Jaeger/OpenTelemetry)
- [ ] Rate limiting per client
- [ ] Bulkhead pattern (resource isolation)

**Nice-to-Have (Advanced):**
- [ ] Service mesh (Istio/Linkerd) for policy management
- [ ] Chaos engineering tests (Chaos Monkey)
- [ ] Automatic failover to read replicas
- [ ] Dynamic circuit breaker thresholds based on SLO

### Comparison: Standard vs Enterprise

| Pattern | Startup | Small Company | Enterprise |
|---------|---------|---------------|------------|
| Connection Retry | ❌ | ✅ | ✅ |
| Request Timeout | ❌ | ⚠️ (Optional) | ✅ (Required) |
| Circuit Breaker | ❌ | ⚠️ (Optional) | ✅ (Required) |
| Caching Layer | ❌ | ❌ | ✅ |
| Service Mesh | ❌ | ❌ | ✅ (High scale) |
| Distributed Tracing | ❌ | ⚠️ | ✅ |

**Current State:** Between "Small Company" and "Enterprise" ✅

### Real-World Scenario Test

```bash
# Scenario: User Service dies mid-operation

# Before (Phase 1):
# - Gateway hangs for 60s
# - Returns generic 500 error
# - All requests to User Service affected

# After (Phase 3):
# Request 1-5: Normal operation
# Request 6: User Service crashes
#   → Circuit: Still Closed
#   → Gateway: Timeout after 3s → 504 error
#   → Circuit: 1 failure recorded

# Request 7-10: Same pattern
#   → Circuit: Failures = 2, 3, 4, 5
#   → Gateway: Still trying with timeout

# Request 11: Circuit trips
#   → Circuit: OPEN (5 failures reached)
#   → Gateway: Immediate 503 "service unavailable"
#   → No gRPC call made (saves resources)

# Request 12-100: All instant failures
#   → Circuit: Still OPEN
#   → Response time: <1ms (immediate rejection)
#   → Backend protected from load

# After 30s: Circuit → HALF_OPEN
# Request 101: Test request
#   → If User Service back: Circuit → CLOSED ✅
#   → If still down: Circuit → OPEN (retry in 30s)
```

**Result:**
- Requests 1-10: Slow failures (3s each)
- Requests 11+: Fast failures (<1ms)
- Resources: Protected after detection
- Recovery: Automatic when service returns

---

## Next Steps

### Immediate (This Week):
1. ✅ Implement circuit breaker pattern
2. ✅ Add request-level timeouts
3. ✅ Enhanced health checks

### Short-term (This Month):
1. Add Redis caching for GET requests (graceful degradation)
2. Implement Prometheus metrics export
3. Add rate limiting middleware
4. Write chaos engineering tests

### Long-term (Next Quarter):
1. Evaluate service mesh (Istio) for traffic management
2. Implement distributed tracing (OpenTelemetry)
3. Add automatic retry budget management
4. Set up SLO monitoring and alerting

---

## References

- [gRPC Connection Management](https://grpc.io/docs/guides/performance/)
- [Exponential Backoff Algorithm](https://en.wikipedia.org/wiki/Exponential_backoff)
- [Circuit Breaker Pattern - Martin Fowler](https://martinfowler.com/bliki/CircuitBreaker.html)
- [Health Check Response Format](https://tools.ietf.org/id/draft-inadarei-api-health-check-01.html)
- [Google SRE Book - Handling Overload](https://sre.google/sre-book/handling-overload/)
- [Release It! - Michael Nygard](https://pragprog.com/titles/mnee2/release-it-second-edition/)

**Last Updated:** December 5, 2025 (Phase 3: Enterprise Patterns)
