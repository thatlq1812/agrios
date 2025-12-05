================================================================================
                              AGRIOS PROJECT NOTES
================================================================================

--------------------------------------------------------------------------------
PENDING ISSUES
--------------------------------------------------------------------------------

[ ] Service communication issues
    - Service 1 and 2 cannot communicate
    - Service 1 cannot link to Service 2
    - Scenario: Service 1 running, Service 2 stopped

[ ] Request validation
    - Block invalid requests before processing (weak logic handling)

--------------------------------------------------------------------------------
Dec 03, 2025 - PLANNED TASKS
--------------------------------------------------------------------------------

[x] Setup JSON logging library
[x] Standardize error handling (Sentinel Error pattern)
[x] Move hardcoded configs to dynamic configuration
[x] Setup Regex for string validation
[x] Complete login/logout with password and token limits
[x] Setup user authentication for article creation
[~] Display API token expiration status

--------------------------------------------------------------------------------
Dec 04, 2025 - PROGRESS
--------------------------------------------------------------------------------

[x] Fix all API code to gRPC
[x] Restructure response format to standard
[x] Document all gRPC and REST commands
[x] Recreate all documentation and API structure
[x] Fix partial update for user (only update provided fields)
[~] Setup deployment guide (temporary OK - auto pull and run)

[x] Fix article list, check all APIs, check error descriptions
[ ] Document access token and refresh token workflow
[ ] Configure Redis blacklist token management (redis-cli)

--------------------------------------------------------------------------------
Dec 05, 2025 - PROGRESS
--------------------------------------------------------------------------------

Làm sao để - < TÁCH CÁC THƯ MỤC SERVICE RIÊNG BIỆT, KHÔNG CHUNG 1 THƯ MỤC, KHỞI CHẠY RIÊNG BIỆT TỪNG SERVICE VÀ CÓ THỂ GỌI NHAU QUA GRPC, CÓ THỂ HOẠT ĐỘNG TỐT VÀ ĐỘC LẬP>



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
                              REFERENCE SECTION
================================================================================

--------------------------------------------------------------------------------
API RESPONSE FORMAT
--------------------------------------------------------------------------------

Standard Response:
{
    "code": "000",
    "message": "success",
    "data": {}
}

List Response:
{
    "code": "000",
    "message": "success",
    "data": {
        "items": [],
        "total": 66,
        "page": 1,
        "size": 1,
        "has_more": true
    }
}

--------------------------------------------------------------------------------
GRPC COMMAND EXAMPLES
--------------------------------------------------------------------------------

Create User:
grpcurl -plaintext -d '{"email": "test4@example.com", "name": "Test User", "password": "password123"}' localhost:50051 user.UserService/CreateUser

Create Article:
grpcurl -plaintext -d '{"title": "My First Article", "content": "Article content", "user_id": 4}' localhost:50052 article.ArticleService/CreateArticle

Get User:
grpcurl -plaintext -d '{"id": 1}' localhost:50051 user.UserService/GetUser

--------------------------------------------------------------------------------
HOW TO: CHANGE FIELD ORDER IN RESPONSE
--------------------------------------------------------------------------------

Step 1: Edit proto file (change field numbers)

Step 2: Regenerate code
    cd service-1-user
    protoc --go_out=. --go-grpc_out=. proto/user_service.proto

Step 3: Rebuild service
    go build -o bin/user-service ./cmd/server

Step 4: Test
    grpcurl -plaintext -d '{"id": 1}' localhost:50051 user.UserService/GetUser

================================================================================