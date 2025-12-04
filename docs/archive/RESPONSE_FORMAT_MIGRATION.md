# API Response Format Migration Guide

## Overview

Hướng dẫn migrate từ raw protobuf responses sang standardized JSON response format.

## Current vs Target Format

### Current (Raw Proto)
```json
{
  "user": {
    "id": 1,
    "name": "Test"
  }
}
```

### Target (Standardized)
```json
{
  "code": "000",
  "message": "success",
  "data": {
    "user": {
      "id": 1,
      "name": "Test"
    }
  }
}
```

## Implementation Options

### Option A: Proto Level (Complex, requires regeneration)
- Modify proto files to wrap all responses
- Regenerate proto code
- Update all service methods
- **Pros:** Type-safe, consistent across all clients
- **Cons:** Breaking changes, more work

### Option B: Application Level (Simple, recommended)
- Keep proto files unchanged
- Use response helpers in application code
- Only affects how data is serialized
- **Pros:** No proto changes, gradual migration
- **Cons:** Only works for REST/JSON APIs, not pure gRPC

## Recommended Approach: Hybrid

For gRPC services, we recommend **keeping proto as-is** but adding a **REST Gateway** layer that wraps responses.

### Step-by-Step Guide

#### 1. Keep Current gRPC APIs Unchanged

Your gRPC APIs continue to work as-is:
```go
func (s *UserServer) GetUser(ctx context.Context, req *pb.GetUserRequest) (*pb.GetUserResponse, error) {
    // Current implementation stays the same
    return &pb.GetUserResponse{
        User: user,
    }, nil
}
```

#### 2. Add REST Gateway (Optional)

If you want to expose REST APIs with standardized format, add a gateway service:

```go
package gateway

import (
    "encoding/json"
    "net/http"
    "agrios/pkg/common/response"
)

// UserHandler wraps gRPC client calls
type UserHandler struct {
    userClient pb.UserServiceClient
}

func (h *UserHandler) GetUser(w http.ResponseWriter, r *http.Request) {
    // Parse request
    userID := r.URL.Query().Get("id")
    
    // Call gRPC service
    resp, err := h.userClient.GetUser(r.Context(), &pb.GetUserRequest{
        Id: parseInt(userID),
    })
    
    if err != nil {
        // Wrap error in standard format
        writeJSON(w, response.Error(response.CodeNotFound, "User not found"))
        return
    }
    
    // Wrap success response in standard format
    writeJSON(w, response.Success(resp.User))
}

func writeJSON(w http.ResponseWriter, data interface{}) {
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(data)
}
```

#### 3. Alternative: Custom Interceptor for JSON Logging

If you just want standardized **logging**, add a gRPC interceptor:

```go
package interceptor

import (
    "context"
    "encoding/json"
    "log"
    
    "agrios/pkg/common/response"
    "google.golang.org/grpc"
)

func LoggingInterceptor() grpc.UnaryServerInterceptor {
    return func(ctx context.Context, req interface{}, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (interface{}, error) {
        // Call handler
        resp, err := handler(ctx, req)
        
        // Log in standardized format
        if err != nil {
            logResponse := response.Error(response.CodeInternalError, err.Error())
            logJSON, _ := json.Marshal(logResponse)
            log.Printf("[ERROR] %s: %s", info.FullMethod, string(logJSON))
        } else {
            logResponse := response.Success(resp)
            logJSON, _ := json.Marshal(logResponse)
            log.Printf("[SUCCESS] %s: %s", info.FullMethod, string(logJSON))
        }
        
        return resp, err
    }
}
```

Register interceptor in server:
```go
grpcServer := grpc.NewServer(
    grpc.UnaryInterceptor(interceptor.LoggingInterceptor()),
)
```

## Migration Examples

### Example 1: User Service - GetUser

**Current Code (Keep as-is):**
```go
func (s *UserServer) GetUser(ctx context.Context, req *pb.GetUserRequest) (*pb.GetUserResponse, error) {
    user, err := s.repo.GetByID(ctx, req.Id)
    if err != nil {
        return nil, status.Error(codes.NotFound, "user not found")
    }
    
    return &pb.GetUserResponse{User: user}, nil
}
```

**Add REST Gateway Handler:**
```go
func (h *UserGateway) GetUser(w http.ResponseWriter, r *http.Request) {
    id := r.URL.Query().Get("id")
    
    grpcResp, err := h.userClient.GetUser(r.Context(), &pb.GetUserRequest{
        Id: parseInt(id),
    })
    
    if err != nil {
        writeJSON(w, response.Error(
            response.CodeNotFound,
            "User not found",
        ))
        return
    }
    
    writeJSON(w, response.Success(grpcResp.User))
}
```

**Response:**
```json
{
  "code": "000",
  "message": "success",
  "data": {
    "id": 1,
    "name": "Test User",
    "email": "test@example.com",
    "created_at": "2025-12-03T10:00:00Z",
    "updated_at": "2025-12-03T10:00:00Z"
  }
}
```

### Example 2: Article Service - ListArticles

**Current Code:**
```go
func (s *ArticleServer) ListArticles(ctx context.Context, req *pb.ListArticlesRequest) (*pb.ListArticlesResponse, error) {
    articles, total, err := s.repo.ListAll(ctx, req.PageSize, req.PageNumber)
    // ... existing logic
    return &pb.ListArticlesResponse{
        Articles: articles,
        Total: total,
        Page: req.PageNumber,
    }, nil
}
```

**Add REST Gateway Handler:**
```go
func (h *ArticleGateway) ListArticles(w http.ResponseWriter, r *http.Request) {
    page := parseInt(r.URL.Query().Get("page"))
    size := parseInt(r.URL.Query().Get("size"))
    
    grpcResp, err := h.articleClient.ListArticles(r.Context(), &pb.ListArticlesRequest{
        PageNumber: page,
        PageSize: size,
    })
    
    if err != nil {
        writeJSON(w, response.Error(
            response.CodeInternalError,
            "Failed to fetch articles",
        ))
        return
    }
    
    // Use standard list format
    writeJSON(w, response.SuccessList(
        grpcResp.Articles,
        grpcResp.Total,
        page,
        size,
    ))
}
```

**Response:**
```json
{
  "code": "000",
  "message": "success",
  "data": {
    "items": [
      {
        "article": {
          "id": 1,
          "title": "Article 1"
        },
        "user": {
          "id": 1,
          "name": "Author"
        }
      }
    ],
    "total": 66,
    "page": 1,
    "size": 10,
    "has_more": true
  }
}
```

## Error Handling

Use response helper for consistent error responses:

```go
import (
    "agrios/pkg/common/response"
    "google.golang.org/grpc/codes"
    "google.golang.org/grpc/status"
)

func (h *Gateway) handleGRPCError(err error) *response.ApiResponse {
    st := status.Convert(err)
    
    switch st.Code() {
    case codes.NotFound:
        return response.Error(response.CodeNotFound, st.Message())
    case codes.InvalidArgument:
        return response.Error(response.CodeInvalidRequest, st.Message())
    case codes.Unauthenticated:
        return response.Error(response.CodeAuthFailed, st.Message())
    case codes.PermissionDenied:
        return response.Error(response.CodeAuthorizeFailed, st.Message())
    case codes.Unavailable:
        return response.Error(response.CodeServiceUnavailable, st.Message())
    default:
        return response.Error(response.CodeInternalError, st.Message())
    }
}
```

## Summary

### Recommended Strategy

1. **Keep gRPC services as-is** - No breaking changes needed
2. **Add response package** - Already created in `pkg/common/response.go`
3. **Choose your approach:**
   - **For REST APIs**: Add gateway layer with standardized responses
   - **For Logging**: Add interceptor to log in standard format
   - **For Both**: Implement both gateway and interceptor

### Next Steps

1. Review `pkg/common/response.go` - Response helper utilities
2. Decide if you need REST gateway or just standardized logging
3. If REST gateway:
   - Create gateway service in each microservice
   - Implement HTTP handlers that wrap gRPC calls
   - Use response helpers for standardization
4. If logging only:
   - Add logging interceptor to gRPC servers
   - Use response helpers in interceptor

### Benefits of This Approach

- ✅ No breaking changes to existing gRPC APIs
- ✅ Gradual migration path
- ✅ Can support both gRPC and REST clients
- ✅ Consistent response format across REST APIs
- ✅ Easy to implement and maintain

## Testing

Test REST gateway responses:
```bash
# Old gRPC call (still works)
grpcurl -plaintext -d '{"id": 1}' localhost:50051 user.UserService/GetUser

# New REST call (standardized format)
curl http://localhost:8080/api/v1/users/1
```

Expected REST response:
```json
{
  "code": "000",
  "message": "success",
  "data": {
    "id": 1,
    "name": "Test User",
    "email": "test@example.com"
  }
}
```
