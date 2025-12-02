# Báo Cáo Ngày 01/12/2025 - Golang & gRPC Microservices
---

## YÊU CẦU

1. Tạo 2 repos riêng biệt sử dụng Golang
2. Giao tiếp giữa services qua gRPC
3. Database: PostgreSQL
4. Service 1: CRUD bảng users - github.com/thatlq1812/service-1-user
5. Service 2: CRUD bảng articles - github.com/thatlq1812/service-2-article
6. Không dùng AI để viết code

## ĐÃ HOÀN THÀNH

1. **Service 1 (User Service)** - Port 50051
   - 5 RPCs: GetUser, CreateUser, UpdateUser, DeleteUser, ListUsers
   - Repository pattern + PostgreSQL connection pooling
   - Error handling & validation (email format, duplicate check)
   - 500 dòng Go code (tự tay gõ)

2. **Service 2 (Article Service)** - Port 50052
   - 5 RPCs: GetArticle, CreateArticle, UpdateArticle, DeleteArticle, ListArticles
   - gRPC Client gọi Service 1 để lấy user info
   - Mỗi article response tự động bao gồm thông tin user

3. **Database & Testing**
   - PostgreSQL 15 với 2 bảng (users + articles, có foreign key)
   - 14/14 test cases passed với grpcurl
   - Inter-service communication hoạt động tốt

