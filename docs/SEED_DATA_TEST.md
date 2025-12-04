# Quick Test Guide - Seed Data

Test the new seed data functionality:

## 1. Fresh Installation Test

```bash
# Clone and deploy
git clone https://github.com/thatlq1812/agrios.git
cd agrios
cp service-1-user/.env.example service-1-user/.env
cp service-2-article/.env.example service-2-article/.env
docker-compose up -d
sleep 15

# Initialize
bash scripts/init-services.sh

# Seed sample data
bash scripts/seed-data.sh
```

## 2. Verify Sample Data

```bash
# Login as admin
curl -X POST http://localhost:8080/api/v1/users/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@agrios.com","password":"admin123"}'

# Save token
export TOKEN="<paste_access_token_here>"

# Get all articles (should return 7 articles)
curl http://localhost:8080/api/v1/articles

# Get specific article
curl http://localhost:8080/api/v1/articles/1
```

## 3. Test User Accounts

All test accounts with password format: `<name>123`

```bash
# Test each user login
curl -X POST http://localhost:8080/api/v1/users/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@agrios.com","password":"admin123"}'

curl -X POST http://localhost:8080/api/v1/users/login \
  -H "Content-Type: application/json" \
  -d '{"email":"john@example.com","password":"john123"}'

curl -X POST http://localhost:8080/api/v1/users/login \
  -H "Content-Type: application/json" \
  -d '{"email":"jane@example.com","password":"jane123"}'

curl -X POST http://localhost:8080/api/v1/users/login \
  -H "Content-Type: application/json" \
  -d '{"email":"bob@example.com","password":"bob123"}'
```

## 4. Expected Results

- ✅ 4 users created successfully
- ✅ 7 articles created successfully
- ✅ All users can login
- ✅ Articles have proper content
- ✅ No duplicate user errors on re-run

## 5. Clean and Re-seed

```bash
# Clean data
bash scripts/clean-data.sh  # Type: yes

# Restart
docker-compose up -d
sleep 15

# Initialize and seed
bash scripts/init-services.sh
bash scripts/seed-data.sh
```

## Sample Credentials

| Email | Password | Name | Articles |
|-------|----------|------|----------|
| admin@agrios.com | admin123 | Admin User | 5 |
| john@example.com | john123 | John Doe | 2 |
| jane@example.com | jane123 | Jane Smith | 0 |
| bob@example.com | bob123 | Bob Wilson | 0 |

## Sample Articles

1. Getting Started with Microservices (Admin)
2. Understanding gRPC Communication (Admin)
3. JWT Authentication Best Practices (Admin)
4. Docker Deployment Strategies (Admin)
5. PostgreSQL Performance Optimization (Admin)
6. Redis Caching Strategies (John)
7. API Gateway Pattern Explained (John)
