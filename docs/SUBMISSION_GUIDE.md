# Maintainer Profile

**Name:** THAT Le Quang

- **Role:** AI & DS Major Student
- **GitHub:** [thatlq1812]

---

# Hướng Dẫn Nộp Bài - Step by Step

**Thời gian:** 10-15 phút  
**Mục tiêu:** Commit code, push lên GitHub, và gửi báo cáo cho Anh Lợi

---

## BƯỚC 1: COMMIT CODE (5 phút)

### Service 1 - User Service

```bash
cd /d/agrios/service-1-user

# Add all files
git add cmd/ internal/ proto/ go.mod go.sum

# Check trước khi commit
git status

# Commit với message rõ ràng
git commit -m "feat: implement User Service with gRPC

- Add 5 CRUD RPCs (GetUser, CreateUser, UpdateUser, DeleteUser, ListUsers)
- Add repository pattern with PostgreSQL integration
- Add error handling with gRPC status codes
- Add input validation (email format, duplicate detection)
- Add connection pooling with pgx/v5
- 500 lines of manually typed Go code"

# Push lên GitHub
git push origin master
```

### Service 2 - Article Service

```bash
cd /d/agrios/service-2-article

# Add files (không add main.exe - binary file)
git add cmd/ internal/ proto/*.proto proto/*.go go.mod go.sum

# Check
git status

# Commit
git commit -m "feat: implement Article Service with inter-service gRPC

- Add 5 CRUD RPCs for articles
- Add gRPC client to call User Service
- Add data aggregation (Article + User info)
- Add business logic (verify user exists before create)
- Add repository pattern with PostgreSQL
- Add foreign key constraint (article.user_id -> users.id)
- 691 lines of manually typed Go code"

# Push
git push origin master
```

### Workspace Documentation (Optional nhưng nên làm)

```bash
cd /d/agrios

# Nếu đây là git repo
git add docs/
git commit -m "docs: add project documentation and sprint reports"
git push origin master
```

---

## BƯỚC 2: VERIFY PUSH THÀNH CÔNG (1 phút)

```bash
# Service 1
cd /d/agrios/service-1-user && git log -1 --oneline

# Service 2
cd /d/agrios/service-2-article && git log -1 --oneline
```

Hoặc check trên GitHub:
- https://github.com/thatlq1812/service-1-user
- https://github.com/thatlq1812/service-2-article

---

## BƯỚC 3: CHUẨN BỊ DEMO (2 phút)

### Verify Services Đang Chạy

```bash
# Check processes
jobs

# Check ports
netstat -an | grep "LISTENING" | grep -E ":(50051|50052)"

# Nếu không chạy, start lại:
# Terminal 1
cd /d/agrios/service-1-user && go run cmd/server/main.go &

# Terminal 2
cd /d/agrios/service-2-article && go run cmd/server/main.go &
```

### Quick Test Commands

```bash
# Test Service 1
grpcurl -plaintext localhost:50051 user.UserService/ListUsers

# Test Service 2 (inter-service call)
grpcurl -plaintext localhost:50052 article.ArticleService/ListArticles

# Test error handling
grpcurl -plaintext -d '{"title": "Test", "content": "Test", "user_id": 999}' \
  localhost:50052 article.ArticleService/CreateArticle
```

---

## BƯỚC 4: GỬI BÁO CÁO (2 phút)

### Copy Template Từ File

Mở file: `d:/agrios/docs/FINAL_REPORT_FOR_MANAGER.md`

Copy phần **EMAIL/MESSAGE TEMPLATE** và điền thông tin:

### Cập Nhật Cần Thiết:

1. **Repository links** (nếu đã push GitHub):
   ```
   Service 1: https://github.com/thatlq1812/service-1-user
   Service 2: https://github.com/thatlq1812/service-2-article
   ```

2. **Thời gian hoàn thành** (nếu khác):
   ```
   Thời gian: [X] giờ (bắt đầu lúc [Y]h, kết thúc lúc [Z]h)
   ```

### Gửi Qua Đâu?

Tùy văn hóa công ty:
- 📧 Email công ty
- 💬 Telegram/Zalo (nếu anh Lợi dùng)
- 📱 Microsoft Teams/Slack
- 📞 Hoặc báo trực tiếp (rồi gửi text follow-up)

---

## BƯỚC 5: SẴN SÀNG DEMO (Optional)

Nếu anh Lợi muốn demo ngay:

### Chuẩn bị môi trường:

```bash
# 1. Mở 3 terminals

# Terminal 1: Service 1
cd /d/agrios/service-1-user
go run cmd/server/main.go

# Terminal 2: Service 2
cd /d/agrios/service-2-article
go run cmd/server/main.go

# Terminal 3: Demo commands (chạy từng command cho anh xem)
```

### Demo Script (5 phút):

```bash
echo "=== 1. Kiểm tra services đang chạy ==="
netstat -an | grep "LISTENING" | grep -E ":(50051|50052)"

echo ""
echo "=== 2. Service 1 - List Users ==="
grpcurl -plaintext localhost:50051 user.UserService/ListUsers

echo ""
echo "=== 3. Service 2 - List Articles (with User Info) ==="
grpcurl -plaintext localhost:50052 article.ArticleService/ListArticles

echo ""
echo "=== 4. Service 2 - Get Article (inter-service call) ==="
grpcurl -plaintext -d '{"id": 1}' localhost:50052 article.ArticleService/GetArticle

echo ""
echo "=== 5. Create New Article ==="
grpcurl -plaintext -d '{"title": "Demo Article", "content": "Content for demo", "user_id": 1}' \
  localhost:50052 article.ArticleService/CreateArticle

echo ""
echo "=== 6. Error Handling - Invalid User ==="
grpcurl -plaintext -d '{"title": "Test", "content": "Test", "user_id": 999}' \
  localhost:50052 article.ArticleService/CreateArticle

echo ""
echo "=== 7. Database Check ==="
docker exec agrios-postgres psql -U agrios -d userdb -c \
  "SELECT 'Users' as table_name, COUNT(*)::text FROM users 
   UNION ALL SELECT 'Articles', COUNT(*)::text FROM articles;"
```

---

## CHECKLIST CUỐI CÙNG

Trước khi gửi, check lại:

### Code:
- [ ] ✅ Service 1 committed & pushed
- [ ] ✅ Service 2 committed & pushed
- [ ] ✅ Documentation committed (nếu có git repo)
- [ ] ✅ Không commit binary files (*.exe, *.log)

### Testing:
- [ ] ✅ Both services running (ports 50051, 50052)
- [ ] ✅ Service 1 test passed (ListUsers works)
- [ ] ✅ Service 2 test passed (ListArticles with user info)
- [ ] ✅ Inter-service call works (Article + User)
- [ ] ✅ Error handling works (invalid user_id)

### Documentation:
- [ ] ✅ FINAL_SUMMARY.md updated
- [ ] ✅ Email/message drafted
- [ ] ✅ Repository links ready
- [ ] ✅ Demo script ready (nếu cần)

### Mindset:
- [ ] ✅ Sẵn sàng giải thích kỹ thuật
- [ ] ✅ Sẵn sàng nhận feedback
- [ ] ✅ Tự tin với code đã viết (vì đã tự gõ hết)

---

## 🎯 SAMPLE MESSAGE (Quick Version)

Nếu muốn gửi nhanh (không cần formal email):

```
Anh Lợi ơi,

Em đã xong dự án Golang + gRPC rồi anh:

✅ 2 services chạy ngon (port 50051 & 50052)
✅ Service 2 gọi Service 1 qua gRPC ok
✅ CRUD đầy đủ cho users & articles
✅ Error handling + validation có
✅ Code: 1,191 dòng (tự gõ, không AI)

Repos:
- Service 1: https://github.com/thatlq1812/service-1-user
- Service 2: https://github.com/thatlq1812/service-2-article

Anh test thử được không, hoặc cần em demo trực tiếp?

Em.
```

---

## 💡 TIPS

### Nếu Anh Lợi Hỏi Kỹ Thuật:

**Stay calm và trả lời rõ ràng:**
- Giải thích bằng ví dụ thực tế
- Chỉ vào code hoặc terminal output
- Thừa nhận nếu có phần chưa hiểu sâu

### Nếu Có Bug Phát Hiện Sau:

**Không panic:**
- Acknowledge the bug
- Explain the cause (nếu biết)
- Offer timeline to fix
- Follow up with fix ngay

### Nếu Anh Satisfied:

**Hỏi next steps:**
- "Anh có project nào tiếp theo em có thể học không?"
- "Em có thể improve gì thêm cho dự án này không anh?"
- "Anh có feedback gì để em code tốt hơn không?"

---

## 🚀 READY TO SUBMIT?

Khi đã check hết checklist:

1. **Commit & Push** (Bước 1)
2. **Copy email template** (Bước 4)
3. **Gửi message/email** cho Anh Lợi
4. **Đợi feedback** và sẵn sàng demo

**Good luck! You've got this! 💪**
