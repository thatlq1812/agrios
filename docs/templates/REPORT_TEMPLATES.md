# Project Templates

## 1. Pull Request (PR) Template
Copy nội dung này vào phần mô tả khi tạo PR mới.

```markdown
### Description
<!-- Tóm tắt ngắn gọn những thay đổi trong PR này -->

### Related Issue
<!-- Link tới issue liên quan, ví dụ: Closes #12 -->
Closes #

### Changes
<!-- Liệt kê các thay đổi chính -->
- [ ] Refactor...
- [ ] Add feature...
- [ ] Fix bug...

### How to Test
<!-- Hướng dẫn các bước để reviewer kiểm tra code -->
1. Chạy lệnh...
2. Gọi API...
3. Kết quả mong đợi...

### Screenshots (Optional)
<!-- Ảnh chụp màn hình nếu có thay đổi về UI hoặc Log -->
```

## 2. Commit Message Convention
Tuân thủ chuẩn **Conventional Commits**:

`type(scope): description (ref #issue)`

**Types:**
- `feat`: Tính năng mới
- `fix`: Sửa lỗi
- `docs`: Thay đổi tài liệu
- `refactor`: Sửa code nhưng không đổi tính năng (dọn dẹp, tối ưu)
- `chore`: Các việc vặt (update dependencies, config build...)

**Ví dụ:**
- `feat(auth): add jwt token validation (ref #15)`
- `fix(user): handle duplicate email error (ref #12)`
- `refactor(config): move env loading to config package`
