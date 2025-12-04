# Documentation Map

Quick reference guide to find the right documentation.

## 🎯 I Need To...

### Setup & Deploy

| Task | Document | Section |
|------|----------|---------|
| Set up local development environment | [DEPLOYMENT_AND_TESTING.md](./DEPLOYMENT_AND_TESTING.md) | Local Development Deployment |
| Deploy with Docker | [DEPLOYMENT_AND_TESTING.md](./DEPLOYMENT_AND_TESTING.md) | Docker Deployment |
| Run database migrations | [DEPLOYMENT_AND_TESTING.md](./DEPLOYMENT_AND_TESTING.md) | Database Setup |
| Configure environment variables | [OPERATIONS_GUIDE.md](./OPERATIONS_GUIDE.md) | Environment Setup |

### Development

| Task | Document | Section |
|------|----------|---------|
| Understand system architecture | [ARCHITECTURE_GUIDE.md](./ARCHITECTURE_GUIDE.md) | Architecture Overview |
| Add new API endpoint | [API_REFERENCE.md](./API_REFERENCE.md) | API Patterns |
| Implement JWT authentication | [tutorials/JWT_BLACKLIST_REDIS.md](./tutorials/JWT_BLACKLIST_REDIS.md) | Complete Guide |
| Follow coding standards | [tutorials/WORKFLOW_GUIDE.md](./tutorials/WORKFLOW_GUIDE.md) | Development Workflow |
| Make gRPC service calls | [ARCHITECTURE_GUIDE.md](./ARCHITECTURE_GUIDE.md) | Service Communication |

### Testing

| Task | Document | Section |
|------|----------|---------|
| Test API endpoints | [DEPLOYMENT_AND_TESTING.md](./DEPLOYMENT_AND_TESTING.md) | API Testing Examples |
| Run automated tests | [TESTING_GUIDE.md](./TESTING_GUIDE.md) | Test Execution |
| Validate authentication | [DEPLOYMENT_AND_TESTING.md](./DEPLOYMENT_AND_TESTING.md) | Login/Logout Tests |
| Debug integration issues | [DEPLOYMENT_AND_TESTING.md](./DEPLOYMENT_AND_TESTING.md) | Common Issues |

### Operations

| Task | Document | Section |
|------|----------|---------|
| Monitor services | [OPERATIONS_GUIDE.md](./OPERATIONS_GUIDE.md) | Monitoring |
| Troubleshoot errors | [DEPLOYMENT_AND_TESTING.md](./DEPLOYMENT_AND_TESTING.md) | Common Issues |
| Manage database | [OPERATIONS_GUIDE.md](./OPERATIONS_GUIDE.md) | Database Operations |
| Scale services | [OPERATIONS_GUIDE.md](./OPERATIONS_GUIDE.md) | Scaling Guide |
| Handle production issues | [OPERATIONS_GUIDE.md](./OPERATIONS_GUIDE.md) | Troubleshooting |

### Integration

| Task | Document | Section |
|------|----------|---------|
| Integrate with User API | [API_REFERENCE.md](./API_REFERENCE.md) | User Service APIs |
| Integrate with Article API | [API_REFERENCE.md](./API_REFERENCE.md) | Article Service APIs |
| Handle API responses | [API_REFERENCE.md](./API_REFERENCE.md) | Response Format |
| Implement error handling | [API_REFERENCE.md](./API_REFERENCE.md) | Error Codes |

---

## 📊 Documentation by Role

### Backend Developer

**Start Here:**
1. [ARCHITECTURE_GUIDE.md](./ARCHITECTURE_GUIDE.md) - System design
2. [DEPLOYMENT_AND_TESTING.md](./DEPLOYMENT_AND_TESTING.md) - Local setup
3. [API_REFERENCE.md](./API_REFERENCE.md) - API contracts
4. [tutorials/WORKFLOW_GUIDE.md](./tutorials/WORKFLOW_GUIDE.md) - Coding standards

**Reference:**
- [tutorials/JWT_BLACKLIST_REDIS.md](./tutorials/JWT_BLACKLIST_REDIS.md) - Auth implementation
- [TESTING_GUIDE.md](./TESTING_GUIDE.md) - Testing practices

### Frontend Developer

**Start Here:**
1. [API_REFERENCE.md](./API_REFERENCE.md) - REST API documentation
2. [DEPLOYMENT_AND_TESTING.md](./DEPLOYMENT_AND_TESTING.md) - Backend setup for testing

**Reference:**
- Response format examples in [API_REFERENCE.md](./API_REFERENCE.md)
- Authentication flow in [tutorials/JWT_BLACKLIST_REDIS.md](./tutorials/JWT_BLACKLIST_REDIS.md)

### QA Engineer

**Start Here:**
1. [DEPLOYMENT_AND_TESTING.md](./DEPLOYMENT_AND_TESTING.md) - Environment setup & test examples
2. [TESTING_GUIDE.md](./TESTING_GUIDE.md) - Test scenarios

**Reference:**
- [API_REFERENCE.md](./API_REFERENCE.md) - Expected API behaviors
- [OPERATIONS_GUIDE.md](./OPERATIONS_GUIDE.md) - Troubleshooting

### DevOps Engineer

**Start Here:**
1. [DEPLOYMENT_AND_TESTING.md](./DEPLOYMENT_AND_TESTING.md) - Docker deployment
2. [OPERATIONS_GUIDE.md](./OPERATIONS_GUIDE.md) - Production operations

**Reference:**
- [ARCHITECTURE_GUIDE.md](./ARCHITECTURE_GUIDE.md) - System components
- Database setup in [OPERATIONS_GUIDE.md](./OPERATIONS_GUIDE.md)

### Product Manager

**Start Here:**
1. [README.md](./README.md) - System overview
2. [API_REFERENCE.md](./API_REFERENCE.md) - Feature capabilities

**Reference:**
- [ARCHITECTURE_GUIDE.md](./ARCHITECTURE_GUIDE.md) - Technical architecture

---

## 🔍 Documentation by Topic

### Architecture & Design

- **[ARCHITECTURE_GUIDE.md](./ARCHITECTURE_GUIDE.md)** - Complete system architecture
  - API Gateway pattern
  - Service communication flow
  - Response format design
  - File structure

### Deployment & Operations

- **[DEPLOYMENT_AND_TESTING.md](./DEPLOYMENT_AND_TESTING.md)** - Complete deployment guide
  - Docker deployment (production-ready)
  - Local development setup
  - API testing examples
  - Troubleshooting

- **[OPERATIONS_GUIDE.md](./OPERATIONS_GUIDE.md)** - Operations manual
  - Prerequisites
  - Environment configuration
  - Monitoring
  - Maintenance

### API & Integration

- **[API_REFERENCE.md](./API_REFERENCE.md)** - Complete API documentation
  - User Service APIs
  - Article Service APIs
  - Response format
  - Error codes

### Testing & Quality

- **[TESTING_GUIDE.md](./TESTING_GUIDE.md)** - Testing procedures
  - Test scenarios
  - Test execution
  - Quality standards

- **[DEPLOYMENT_AND_TESTING.md](./DEPLOYMENT_AND_TESTING.md)** - API testing
  - 14 complete test examples
  - Automated test script
  - Common issues

### Tutorials & Guides

- **[tutorials/JWT_BLACKLIST_REDIS.md](./tutorials/JWT_BLACKLIST_REDIS.md)** - JWT implementation
- **[tutorials/WORKFLOW_GUIDE.md](./tutorials/WORKFLOW_GUIDE.md)** - Development workflow

---

## 📈 Documentation Maturity

| Document | Status | Last Updated | Completeness |
|----------|--------|--------------|--------------|
| README.md | ✅ Current | 2025-12-04 | 100% |
| ARCHITECTURE_GUIDE.md | ✅ Current | 2025-12-04 | 100% |
| DEPLOYMENT_AND_TESTING.md | ✅ Current | 2025-12-04 | 100% |
| API_REFERENCE.md | ✅ Current | 2025-12-03 | 100% |
| OPERATIONS_GUIDE.md | ✅ Current | 2025-12-04 | 100% |
| TESTING_GUIDE.md | ✅ Current | 2025-12-04 | 100% |
| tutorials/JWT_BLACKLIST_REDIS.md | ✅ Current | 2025-12-03 | 100% |
| tutorials/WORKFLOW_GUIDE.md | ✅ Current | 2025-12-03 | 100% |

---

## 🔄 Quick Links

### Most Accessed

1. [API Reference](./API_REFERENCE.md) - API documentation
2. [Deployment Guide](./DEPLOYMENT_AND_TESTING.md) - Setup instructions
3. [Architecture Guide](./ARCHITECTURE_GUIDE.md) - System design

### Getting Started

- [New Developer Onboarding](./README.md#im-a-new-developer)
- [Quick Start Commands](./README.md#quick-start-commands)
- [System Overview](./README.md#system-architecture-at-a-glance)

### Common Tasks

- [Docker Deployment](./DEPLOYMENT_AND_TESTING.md#docker-deployment)
- [API Testing](./DEPLOYMENT_AND_TESTING.md#api-testing-examples)
- [Troubleshooting](./DEPLOYMENT_AND_TESTING.md#common-issues)

---

## 💡 Tips

1. **Use Ctrl+F / Cmd+F** to search within documents
2. **Check CHANGELOG.md** for recent changes
3. **Refer to archive/** for historical documentation
4. **Follow links** between documents for deeper context

---

Last Updated: December 4, 2025
