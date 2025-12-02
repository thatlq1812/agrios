# Changelog

All notable changes to the Agrios Microservices project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [1.0.0] - 2025-12-02

### Added

#### Service 1 - User Service
- Implemented complete gRPC User Service on port 50051
- Created PostgreSQL repository layer with pgx driver
- Implemented 5 RPC methods:
  - CreateUser: Create new user with name and email
  - GetUser: Retrieve user by ID
  - ListUsers: List all users with pagination support
  - UpdateUser: Update user information
  - DeleteUser: Remove user from database
- Added database connection pooling
- Configured gRPC reflection for development testing
- Created `users` table schema with indexes
- Total: ~418 lines of Go code manually typed

#### Service 2 - Article Service
- Implemented complete gRPC Article Service on port 50052
- Created PostgreSQL repository layer with pgx driver
- Implemented gRPC client to communicate with User Service
- Implemented 5 RPC methods:
  - CreateArticle: Create article with user verification
  - GetArticle: Retrieve article with user info via cross-service call
  - ListArticles: List articles with optional user filter, includes user info
  - UpdateArticle: Update article content
  - DeleteArticle: Remove article from database
- Added user existence validation before article creation
- Created `articles` table schema with user_id reference
- Implemented cross-service communication pattern
- Total: ~450 lines of Go code manually typed

#### Database
- Created separate databases for each service:
  - `agrios_users`: User service database
  - `agrios_articles`: Article service database
- Implemented migration scripts for both databases
- Created proper indexes for performance
- Set up PostgreSQL 15 in Docker container

#### Documentation
- Created comprehensive COOKBOOK.md with:
  - Quick start guide
  - Complete API examples for all operations
  - Cross-service testing scenarios
  - Database operation guides
  - Troubleshooting section
  - Performance testing examples
  - Architecture diagram
  - Development notes
- Created action plans and sprint reports
- Documented technical decisions and constraints

#### Infrastructure
- Set up Docker container for PostgreSQL
- Configured database connection strings
- Implemented proper error handling across services
- Added gRPC reflection for both services

### Technical Details

**Architecture**:
- Microservices pattern with independent services
- Database per service pattern
- gRPC for inter-service communication
- Repository pattern for data access
- Clean separation of concerns

**Technology Stack**:
- Go 1.21+
- gRPC with Protocol Buffers
- PostgreSQL 15
- pgx/v5 driver
- Docker for containerization

**Code Quality**:
- 100% manually typed code (no AI generation)
- Clean architecture principles
- Proper error handling
- Connection pooling
- Prepared statements for SQL injection prevention

**Testing**:
- Manual testing with grpcurl
- Cross-service integration verified
- User validation working correctly
- All CRUD operations tested successfully

### Changed
- Fixed database connection configuration to match PostgreSQL container settings
- Updated Service 1 config: User from "agrios" to "postgres", Database from "userdb" to "agrios_users"
- Updated Service 2 config: User from "agrios" to "postgres", Database from "articledb" to "agrios_articles"

### Performance
- Implemented connection pooling for database efficiency
- Used binary gRPC protocol for fast communication
- Indexed database columns for query performance

### Security
- Used prepared statements to prevent SQL injection
- Validated user existence before creating articles
- Proper error messages without exposing internal details

---

## Project Milestones

### Sprint 1: Project Setup (1 hour)
- Learned Go basics
- Set up development environment
- Created project structure

### Sprint 2: Service 1 Implementation (1.5 hours)
- Implemented User Service completely
- Created database schema
- Tested all CRUD operations

### Sprint 3: Service 2 Implementation (1.5 hours)
- Implemented Article Service
- Added gRPC client for Service 1
- Implemented cross-service verification

### Sprint 4: Integration Testing (1 hour)
- Tested all operations end-to-end
- Verified cross-service communication
- Fixed configuration issues

### Sprint 5: Documentation (0.5 hours)
- Created COOKBOOK.md
- Updated sprint reports
- Documented architecture

### Sprint 6: Final Review (0.5 hours)
- Verified all requirements met
- Tested complete workflows
- Updated CHANGELOG.md

**Total Development Time**: 6 hours  
**Completion**: 100%

---

## Requirements Status

| Requirement | Status | Notes |
|------------|--------|-------|
| 2 separate services | ✅ Complete | Service 1 and Service 2 fully independent |
| gRPC communication | ✅ Complete | Service 2 calls Service 1 for user verification |
| PostgreSQL database | ✅ Complete | Separate databases for each service |
| CRUD users | ✅ Complete | 5 operations fully implemented |
| CRUD articles | ✅ Complete | 5 operations fully implemented |
| Article belongs to user | ✅ Complete | user_id field with runtime verification |
| User verification | ✅ Complete | Service 2 verifies user exists via gRPC |
| Manual coding only | ✅ Complete | 100% manually typed, 0% AI-generated |

---

## Known Issues

None. All features working as expected.

---

## Future Enhancements (Not Required)

- Add authentication and authorization
- Implement rate limiting
- Add metrics and monitoring
- Implement circuit breaker pattern
- Add caching layer
- Implement event-driven architecture
- Add API gateway
- Implement distributed tracing

---

**Project Status**: COMPLETE  
**Last Updated**: December 2, 2025  
**Author**: That Le Quang
