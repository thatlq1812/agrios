# Scripts Documentation

Collection of utility scripts for Agrios microservices platform.

## Available Scripts

### 🚀 init-services.sh

**Purpose:** Initialize all services after deployment

**Usage:**
```bash
bash scripts/init-services.sh
```

**What it does:**
- Checks if all containers are running
- Waits for services to be ready
- Runs database migrations automatically
- Verifies service health
- Provides colored status output

**When to use:**
- After first `docker-compose up -d`
- After database changes
- When services need migration sync

---

### 🧹 clean-data.sh

**Purpose:** Clean all data volumes and handle version conflicts

**Usage:**
```bash
bash scripts/clean-data.sh
```

**What it does:**
- Stops all containers
- Removes all data volumes
- Cleans PostgreSQL and Redis data
- Interactive confirmation before deletion
- Provides next-steps instructions

**When to use:**
- PostgreSQL version conflict errors
- Need fresh database start
- Testing deployment from scratch
- Before switching between branches with schema changes

**Warning:** This will delete ALL data. Cannot be undone.

---

### 🌱 seed-data.sh

**Purpose:** Populate database with sample data for testing

**Usage:**
```bash
bash scripts/seed-data.sh
```

**What it does:**
- Creates 4 test user accounts
- Generates 7 sample articles
- Handles authentication automatically
- Provides test credentials
- Shows summary of created data

**Sample Data Created:**

**Users:**
- `admin@agrios.com` / `admin123` - Admin User
- `john@example.com` / `john123` - John Doe
- `jane@example.com` / `jane123` - Jane Smith
- `bob@example.com` / `bob123` - Bob Wilson

**Articles:**
- 5 articles by Admin User
- 2 articles by John Doe
- Topics: Microservices, gRPC, JWT, Docker, PostgreSQL, Redis, API Gateway

**When to use:**
- After initial deployment
- For demo/presentation
- Testing with realistic data
- Onboarding new developers
- CI/CD testing environments

---

### 🗄️ init-databases.sh

**Purpose:** Initialize PostgreSQL databases (called by Docker)

**Usage:**
```bash
# Automatically called by Docker on first startup
# Manual usage:
bash scripts/init-databases.sh
```

**What it does:**
- Creates `agrios_user` database
- Creates `agrios_article` database
- Grants necessary permissions
- Runs only on first container startup

**When to use:**
- Automatically run by docker-compose
- Manual database recreation (advanced)

---

### 🧪 test-gateway.sh

**Purpose:** Test API Gateway endpoints

**Usage:**
```bash
bash scripts/test-gateway.sh
```

**What it does:**
- Tests gateway health
- Validates user registration
- Tests login flow
- Tests article creation
- Verifies authentication

**When to use:**
- After deployment
- After code changes
- CI/CD pipeline
- Smoke testing

---

## Common Workflows

### Fresh Installation

```bash
# 1. Start services
docker-compose up -d
sleep 15

# 2. Initialize
bash scripts/init-services.sh

# 3. Seed data (optional)
bash scripts/seed-data.sh

# 4. Test
bash scripts/test-gateway.sh
```

### Fix Version Conflicts

```bash
# 1. Clean old data
bash scripts/clean-data.sh
# Type: yes

# 2. Restart
docker-compose up -d
sleep 15

# 3. Initialize
bash scripts/init-services.sh

# 4. Seed data
bash scripts/seed-data.sh
```

### Development Reset

```bash
# Quick reset for testing
bash scripts/clean-data.sh
docker-compose up -d && sleep 15
bash scripts/init-services.sh
bash scripts/seed-data.sh
```

---

## Troubleshooting

### Script Permission Denied

```bash
# Make scripts executable
chmod +x scripts/*.sh
```

### Services Not Ready

```bash
# Wait longer for services to start
docker-compose up -d
sleep 30  # Increase wait time
bash scripts/init-services.sh
```

### Seed Data Fails

```bash
# Check if services are running
docker-compose ps

# Check gateway is accessible
curl http://localhost:8080/health

# Re-run seed script
bash scripts/seed-data.sh
```

---

## Script Development

When creating new scripts:

1. **Use bash shebang:** `#!/bin/bash`
2. **Exit on error:** `set -e`
3. **Add colors:** Use ANSI color codes for better UX
4. **Provide feedback:** Echo status messages
5. **Handle errors:** Check prerequisites
6. **Document:** Add to this README

### Color Codes

```bash
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color

echo -e "${GREEN}Success message${NC}"
echo -e "${RED}Error message${NC}"
```

---

## See Also

- [Deployment Guide](../docs/DEPLOYMENT.md)
- [Testing Guide](../docs/GRPC_COMMANDS.md)
- [Architecture Guide](../docs/ARCHITECTURE_GUIDE.md)
