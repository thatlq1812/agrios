# Maintainer Profile

**Name:** THAT Le Quang

- **Role:** AI & DS Major Student
- **GitHub:** [thatlq1812]

---

# Task Analysis - Instruction 002

**Date:** December 1, 2025  
**Assigned by:** Anh Lợi Nguyễn  
**Deadline:** TBD (report required)

## Requirements Summary

Sếp yêu cầu tạo một bài tập thực hành để báo cáo, thể hiện khả năng học và áp dụng Golang + gRPC:

### Core Requirements

1. **2 Repositories (Services)**:

   - Service A (Data Provider): Cung cấp data từ database
   - Service B (Consumer): Gọi Service A qua gRPC để lấy data

2. **Technology Stack**:

   - Language: Golang
   - Communication: gRPC (không phải REST API)
   - Database: PostgreSQL

3. **Purpose**:
   - Chứng minh đã học được Golang và gRPC
   - Tạo báo cáo cho sếp review
   - Thực hành microservices architecture

## Architecture Design

```
┌─────────────────────┐         gRPC          ┌─────────────────────┐
│   Service B         │ ──────────────────────>│   Service A         │
│   (Consumer)        │  Request: GetUser()    │   (Data Provider)   │
│                     │ <───────────────────── │                     │
│   - Call gRPC       │  Response: User data   │   - PostgreSQL      │
│   - Display result  │                        │   - CRUD operations │
└─────────────────────┘                        └─────────────────────┘
                                                        │
                                                        │ SQL queries
                                                        ▼
                                                ┌──────────────┐
                                                │  PostgreSQL  │
                                                │   Database   │
                                                └──────────────┘
```

## Implementation Plan

### Phase 1: Setup Project Structure (30 mins)

- [ ] Create 2 separate directories (simulate 2 repos)
- [ ] Initialize Go modules for each service
- [ ] Setup PostgreSQL database (Docker or local)
- [ ] Define .proto file for service contract

### Phase 2: Service A - Data Provider (1-2 hours)

- [ ] Setup PostgreSQL connection
- [ ] Create simple schema (e.g., Users table)
- [ ] Implement gRPC server
- [ ] CRUD operations with database
- [ ] Error handling and logging

### Phase 3: Service B - Consumer (1 hour)

- [ ] Implement gRPC client
- [ ] Call Service A to fetch data
- [ ] Display results (CLI or simple API)
- [ ] Error handling

### Phase 4: Testing & Documentation (1 hour)

- [ ] Test both services together
- [ ] Write README with setup instructions
- [ ] Document API endpoints (gRPC methods)
- [ ] Prepare demo script
- [ ] Write report for manager

## Technical Specifications

### Database Schema (Example)

```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (name, email) VALUES
    ('John Doe', 'john@example.com'),
    ('Jane Smith', 'jane@example.com');
```

### Proto File (Draft)

```protobuf
syntax = "proto3";

package userservice;

service UserService {
  rpc GetUser(GetUserRequest) returns (User);
  rpc ListUsers(ListUsersRequest) returns (ListUsersResponse);
  rpc CreateUser(CreateUserRequest) returns (User);
}

message User {
  int32 id = 1;
  string name = 2;
  string email = 3;
  string created_at = 4;
}

message GetUserRequest {
  int32 id = 1;
}

message ListUsersRequest {
  int32 page = 1;
  int32 page_size = 2;
}

message ListUsersResponse {
  repeated User users = 1;
  int32 total = 2;
}

message CreateUserRequest {
  string name = 1;
  string email = 2;
}
```

### Technology Stack Details

**Service A (Data Provider):**

- `github.com/lib/pq` or `github.com/jackc/pgx` - PostgreSQL driver
- `google.golang.org/grpc` - gRPC server
- `database/sql` - Database interface

**Service B (Consumer):**

- `google.golang.org/grpc` - gRPC client
- Simple CLI or HTTP server to trigger calls

**Shared:**

- Protocol Buffers definitions
- Generated gRPC code

## Directory Structure

```
agrios/
├── service-a-user-provider/     # Repository 1
│   ├── proto/
│   │   └── user_service.proto
│   ├── pb/                      # Generated code
│   ├── internal/
│   │   ├── db/                  # Database connection
│   │   ├── repository/          # Data access layer
│   │   └── grpc/                # gRPC server implementation
│   ├── cmd/
│   │   └── server/
│   │       └── main.go
│   ├── go.mod
│   ├── .env                     # Database config
│   └── README.md
│
└── service-b-user-consumer/     # Repository 2
    ├── proto/
    │   └── user_service.proto   # Same proto file
    ├── pb/                      # Generated code
    ├── internal/
    │   └── client/              # gRPC client wrapper
    ├── cmd/
    │   └── main.go              # CLI application
    ├── go.mod
    └── README.md
```

## Success Criteria

### Functional Requirements

✅ Service A can connect to PostgreSQL  
✅ Service A exposes gRPC endpoints  
✅ Service B can call Service A via gRPC  
✅ Data flows: PostgreSQL → Service A → Service B  
✅ Basic error handling implemented

### Report Requirements

✅ Clear documentation in README  
✅ Setup instructions for running both services  
✅ Example commands and expected output  
✅ Architecture diagram  
✅ Lessons learned (what you struggled with, what you learned)

## Estimated Timeline

| Task                         | Duration       | Priority |
| ---------------------------- | -------------- | -------- |
| Setup databases and projects | 30 mins        | High     |
| Service A implementation     | 2 hours        | High     |
| Service B implementation     | 1 hour         | High     |
| Testing and debugging        | 1 hour         | Medium   |
| Documentation and report     | 1 hour         | High     |
| **Total**                    | **~5-6 hours** |          |

## Key Learning Points

This task demonstrates:

1. **Microservices Architecture**: Two independent services communicating
2. **gRPC**: Service-to-service communication (better than REST for internal)
3. **Database Integration**: PostgreSQL with Go
4. **Go Best Practices**: Project structure, error handling, logging
5. **DevOps Basics**: Running multiple services, configuration management

## Questions to Clarify (if needed)

- [ ] Có cần deploy lên server hay chỉ run local?
- [ ] Database schema cụ thể là gì, hay em tự design đơn giản?
- [ ] Service B có cần expose HTTP API không, hay chỉ CLI?
- [ ] Có cần viết unit test không?
- [ ] Deadline cụ thể là khi nào?

## Next Steps

1. **Immediate**: Setup PostgreSQL (Docker recommended)
2. **Today**: Complete Service A (Data Provider)
3. **Tomorrow**: Complete Service B and testing
4. **Report**: Document everything and send to manager

## Resources Needed

- Docker Desktop (for PostgreSQL)
- PostgreSQL client (pgAdmin or CLI)
- Go PostgreSQL driver documentation
- gRPC Go examples from official docs
