# Development Workflow Guide

Tài liệu hướng dẫn quy trình làm việc chuẩn cho dự án Agrios.

## 1. Quy trình xử lý Issue (The GitHub Flow)

### Bước 1: Nhận diện & Phân tích (Analyze)
- Đọc kỹ yêu cầu Issue.
- Tái hiện lỗi (nếu là bug) trên môi trường local.
- Comment xác nhận trên Issue: "Đã nhận task/Đã tái hiện được lỗi".

### Bước 2: Tạo nhánh (Branching)
- Luôn tạo nhánh mới từ `master`.
- Quy tắc đặt tên: `type/issue-id/short-description`
- Ví dụ:
  - `feat/15/user-login`
  - `fix/12/mobile-button`
  - `refactor/10/config-structure`

### Bước 3: Code & Commit
- Thực hiện code.
- Chạy test local đảm bảo không lỗi.
- Commit code theo chuẩn [Commit Message](../templates/REPORT_TEMPLATES.md#2-commit-message-convention).

### Bước 4: Pull Request (PR)
- Push nhánh lên remote: `git push origin <branch-name>`
- Tạo PR trên GitHub.
- Điền thông tin theo [PR Template](../templates/REPORT_TEMPLATES.md#1-pull-request-pr-template).
- Gắn label (nếu có) và assign reviewer (Mentor).

### Bước 5: Review & Merge
- Theo dõi comment của Reviewer.
- Fix các vấn đề được chỉ ra -> Commit & Push tiếp vào nhánh cũ.
- Khi PR được Approve -> Merge vào `master`.

## 2. Các lệnh Git thường dùng

```bash
# Lấy code mới nhất từ master
git checkout master
git pull origin master

# Tạo nhánh mới
git checkout -b feat/new-feature

# Xem trạng thái file
git status

# Thêm file vào staging
git add .

# Commit
git commit -m "feat: description"

# Push lên server
git push origin feat/new-feature
```
