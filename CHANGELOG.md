# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Comprehensive Failure Handling System:**
  - Implemented detailed error handling with proper gRPC status codes (NotFound, Unavailable, DeadlineExceeded, InvalidArgument, Internal)
  - Added retry logic with exponential backoff for transient failures (3 attempts: 100ms, 200ms, 400ms)
  - Implemented graceful degradation: Article Service returns partial data when User Service is unavailable
  - Added structured logging with operation context for all service methods
  - Timeout management: 3s per request, 5s connection timeout
  - Health check functionality for service monitoring

- **User Service Client (service-2-article/internal/client/user_client.go):**
  - Full error handling for all User Service call scenarios
  - `GetUser()`: Standard call with timeout and error conversion
  - `GetUserWithRetry()`: Retry logic for critical operations
  - `ValidateToken()`: JWT token validation
  - `HealthCheck()`: Service health verification
  - Detailed logging for debugging and monitoring

- **Enhanced Article Service (service-2-article/internal/server/article_server.go):**
  - Graceful degradation in `GetArticleWithUser()`: Returns article even when user info unavailable
  - Retry logic in `CreateArticle()`: Uses `GetUserWithRetry()` to ensure user exists
  - Error context preservation: Converts User Service errors to appropriate Article Service errors
  - User type conversion function for proto compatibility

- Documentation created: `docs/COOKBOOK2.md` with comprehensive guides for:
  - Local development setup
  - Docker deployment with docker-compose
  - Testing all endpoints with grpcurl examples
  - Health checks and monitoring
  - Failure scenarios testing (5 scenarios covered)
  - Troubleshooting common issues
  - Production checklist

### Added
- Created shared `pkg/common` package with reusable utilities:
  - Environment variable helpers (`GetEnvInt32`, `GetEnvDuration`, `GetEnvString`, `MustGetEnvString`)
  - Graceful shutdown signal handler (`WaitForShutdown`)
  - Email validation utility (`IsValidEmail`)

### Changed
- **service-1-user refactoring:**
  - Removed duplicate helper functions, now using shared `pkg/common` package
  - Improved error handling with consistent error messages (lowercase, informative)
  - Added constants for default values (`defaultGRPCPort`, `defaultPageSize`, `maxPageSize`)
  - Replaced inefficient custom string helpers with standard `strings.Contains()`
  - Implemented graceful shutdown with configurable timeout
  - Enhanced JWT security with warning for missing `JWT_SECRET` environment variable
  - Improved code documentation with better function comments
  - Fixed port configuration to use `GRPC_PORT` environment variable (was hardcoded to 50051)
  - Standardized error handling using `status.Error()` and `status.Errorf()`

- **service-1-user enhancements:**
  - Added comprehensive logging to all RPC methods with format `[MethodName] Context: details`
  - Log both success and error cases for better observability
  - Include relevant data in logs (user_id, email, error details)

- **service-2-article refactoring and enhancements:**
  - Removed duplicate helper functions and config loading logic
  - Fixed duplicate database configuration loading (removed redundant config in main)
  - Fixed port configuration bug (typo: `GRCP_PORT` → `GRPC_PORT`)
  - Implemented graceful shutdown with configurable timeout
  - Added `USER_SERVICE_ADDR` environment variable for configurable user service address
  - Improved error handling with consistent error messages and proper error wrapping
  - Added constants for default values and error messages
  - Removed code duplication in `GetArticle` (now delegates to `GetArticleWithUser`)
  - Enhanced documentation for inter-service communication patterns
  - Added comprehensive logging to all RPC methods
  - Implemented User type conversion between User Service and Article Service protos

### Fixed
- **Proto namespace conflict:** Resolved "proto: file user_service.proto is already registered" error
  - Removed duplicate user_service.proto from Article Service
  - Article Service now defines its own lightweight User message
  - Eliminates proto registration conflicts between services
- **Type compatibility:** Fixed type mismatch between User Service User (service-1-user/proto.User) and Article Service User (article-service/proto.User)
  - Added `convertUser()` function to convert between proto types
  - Maintains backward compatibility with existing API contracts

- **Authentication improvements:**
  - Added constants for token durations (`accessTokenDuration`, `refreshTokenDuration`)
  - Enhanced JWT signing method validation in `ValidateToken()`
  - Improved password hashing error handling
  - Better documentation for security considerations

### Fixed
- Fixed critical bug in `service-2-article/internal/client/user_client.go`: `GetUser()` now correctly returns user directly (proto returns `User` not `GetUserResponse`)
- Fixed hardcoded port issue in both services - now properly use environment variable
- Fixed typo in environment variable name: `GRCP_PORT` → `GRPC_PORT`
- Removed inefficient custom substring search implementation in favor of `strings.Contains()`
- Fixed missing error messages in various error returns
- Removed unused imports in both service main.go files

### Security
- Added security warning for default JWT secret key in development
- Improved error messages to avoid leaking sensitive information
- Enhanced JWT token validation with signing method verification

### Improved
- Code consistency across both services with standardized patterns
- Error handling with proper error wrapping and informative messages
- Documentation with detailed function comments
- Configuration management with environment variable defaults
- Inter-service communication reliability with proper timeouts and error handling
- Module structure with shared package and proper replace directives in go.mod

## [Previous Releases]
<!-- Add previous version history here -->
