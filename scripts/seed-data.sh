#!/bin/bash

# Agrios Seed Data Script
# Populates database with sample data for testing and development

set -e

echo "========================================="
echo "Agrios - Seed Sample Data"
echo "========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Gateway URL
GATEWAY_URL="http://localhost:8080"

# Check if gateway is accessible
echo "Checking gateway connectivity..."
if ! curl -s "$GATEWAY_URL/health" >/dev/null 2>&1; then
    echo -e "${RED}✗ Gateway is not accessible at $GATEWAY_URL${NC}"
    echo "Please ensure services are running: docker-compose up -d"
    exit 1
fi
echo -e "${GREEN}✓ Gateway is accessible${NC}"
echo ""

echo "========================================="
echo "Creating Sample Users"
echo "========================================="
echo ""

# User 1: Admin
echo -n "Creating admin user... "
ADMIN_RESPONSE=$(curl -s -X POST "$GATEWAY_URL/api/v1/users" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Admin User",
    "email": "admin@agrios.com",
    "password": "admin123"
  }')

if echo "$ADMIN_RESPONSE" | grep -q '"code":"000"'; then
    ADMIN_ID=$(echo "$ADMIN_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
    echo -e "${GREEN}✓ Created (ID: $ADMIN_ID)${NC}"
else
    echo -e "${YELLOW}⚠ Already exists or failed${NC}"
fi

# User 2: John Doe
echo -n "Creating John Doe... "
JOHN_RESPONSE=$(curl -s -X POST "$GATEWAY_URL/api/v1/users" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "john123"
  }')

if echo "$JOHN_RESPONSE" | grep -q '"code":"000"'; then
    JOHN_ID=$(echo "$JOHN_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
    echo -e "${GREEN}✓ Created (ID: $JOHN_ID)${NC}"
else
    echo -e "${YELLOW}⚠ Already exists or failed${NC}"
fi

# User 3: Jane Smith
echo -n "Creating Jane Smith... "
JANE_RESPONSE=$(curl -s -X POST "$GATEWAY_URL/api/v1/users" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Jane Smith",
    "email": "jane@example.com",
    "password": "jane123"
  }')

if echo "$JANE_RESPONSE" | grep -q '"code":"000"'; then
    JANE_ID=$(echo "$JANE_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
    echo -e "${GREEN}✓ Created (ID: $JANE_ID)${NC}"
else
    echo -e "${YELLOW}⚠ Already exists or failed${NC}"
fi

# User 4: Bob Wilson
echo -n "Creating Bob Wilson... "
BOB_RESPONSE=$(curl -s -X POST "$GATEWAY_URL/api/v1/users" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Bob Wilson",
    "email": "bob@example.com",
    "password": "bob123"
  }')

if echo "$BOB_RESPONSE" | grep -q '"code":"000"'; then
    BOB_ID=$(echo "$BOB_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
    echo -e "${GREEN}✓ Created (ID: $BOB_ID)${NC}"
else
    echo -e "${YELLOW}⚠ Already exists or failed${NC}"
fi

echo ""
echo "========================================="
echo "Creating Sample Articles"
echo "========================================="
echo ""

# Login as admin to get token
echo -n "Logging in as admin... "
LOGIN_RESPONSE=$(curl -s -X POST "$GATEWAY_URL/api/v1/users/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@agrios.com",
    "password": "admin123"
  }')

ADMIN_TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$ADMIN_TOKEN" ]; then
    echo -e "${RED}✗ Failed to get admin token${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Token obtained${NC}"

# Article 1: Getting Started
echo -n "Creating 'Getting Started with Microservices'... "
ARTICLE1=$(curl -s -X POST "$GATEWAY_URL/api/v1/articles" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "title": "Getting Started with Microservices",
    "content": "Microservices architecture is a design pattern that structures an application as a collection of loosely coupled services. Each service is self-contained and implements a single business capability. This approach offers several advantages including scalability, flexibility, and easier maintenance. In this article, we will explore the fundamentals of microservices and how to implement them effectively."
  }')

if echo "$ARTICLE1" | grep -q '"code":"000"'; then
    echo -e "${GREEN}✓ Created${NC}"
else
    echo -e "${YELLOW}⚠ Failed${NC}"
fi

# Article 2: gRPC Communication
echo -n "Creating 'Understanding gRPC Communication'... "
ARTICLE2=$(curl -s -X POST "$GATEWAY_URL/api/v1/articles" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "title": "Understanding gRPC Communication",
    "content": "gRPC is a modern open-source high-performance Remote Procedure Call (RPC) framework. It uses HTTP/2 for transport, Protocol Buffers as the interface description language, and provides features such as authentication, bidirectional streaming, and flow control. gRPC is ideal for microservices communication due to its efficiency and strong typing. This article covers the basics of gRPC and how to implement it in your services."
  }')

if echo "$ARTICLE2" | grep -q '"code":"000"'; then
    echo -e "${GREEN}✓ Created${NC}"
else
    echo -e "${YELLOW}⚠ Failed${NC}"
fi

# Article 3: JWT Authentication
echo -n "Creating 'JWT Authentication Best Practices'... "
ARTICLE3=$(curl -s -X POST "$GATEWAY_URL/api/v1/articles" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "title": "JWT Authentication Best Practices",
    "content": "JSON Web Tokens (JWT) are a popular method for handling authentication in modern web applications. A JWT is a compact, URL-safe token that contains claims about a user. This article discusses best practices for implementing JWT authentication, including token expiration, refresh tokens, secure storage, and token revocation using Redis blacklists. We also cover common security pitfalls and how to avoid them."
  }')

if echo "$ARTICLE3" | grep -q '"code":"000"'; then
    echo -e "${GREEN}✓ Created${NC}"
else
    echo -e "${YELLOW}⚠ Failed${NC}"
fi

# Article 4: Docker Deployment
echo -n "Creating 'Docker Deployment Strategies'... "
ARTICLE4=$(curl -s -X POST "$GATEWAY_URL/api/v1/articles" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "title": "Docker Deployment Strategies",
    "content": "Docker has revolutionized application deployment by providing consistent environments across development, testing, and production. This article explores various Docker deployment strategies including multi-stage builds, container orchestration with Docker Compose, health checks, and volume management. We also discuss best practices for securing Docker containers and optimizing image sizes for faster deployment."
  }')

if echo "$ARTICLE4" | grep -q '"code":"000"'; then
    echo -e "${GREEN}✓ Created${NC}"
else
    echo -e "${YELLOW}⚠ Failed${NC}"
fi

# Article 5: PostgreSQL Optimization
echo -n "Creating 'PostgreSQL Performance Optimization'... "
ARTICLE5=$(curl -s -X POST "$GATEWAY_URL/api/v1/articles" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "title": "PostgreSQL Performance Optimization",
    "content": "PostgreSQL is a powerful open-source relational database system. To get the most out of PostgreSQL, it is important to understand performance optimization techniques. This article covers indexing strategies, query optimization, connection pooling, and proper configuration settings. We also explore common performance bottlenecks and how to identify and resolve them using PostgreSQL built-in tools."
  }')

if echo "$ARTICLE5" | grep -q '"code":"000"'; then
    echo -e "${GREEN}✓ Created${NC}"
else
    echo -e "${YELLOW}⚠ Failed${NC}"
fi

# Login as John and create more articles
echo ""
echo -n "Logging in as John... "
JOHN_LOGIN=$(curl -s -X POST "$GATEWAY_URL/api/v1/users/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "john123"
  }')

JOHN_TOKEN=$(echo "$JOHN_LOGIN" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
echo -e "${GREEN}✓ Token obtained${NC}"

# Article 6: Redis Caching
echo -n "Creating 'Redis Caching Strategies'... "
ARTICLE6=$(curl -s -X POST "$GATEWAY_URL/api/v1/articles" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JOHN_TOKEN" \
  -d '{
    "title": "Redis Caching Strategies",
    "content": "Redis is an in-memory data structure store used as a database, cache, and message broker. Effective caching strategies can significantly improve application performance. This article discusses various Redis caching patterns including cache-aside, write-through, and write-behind. We also cover cache invalidation strategies, TTL configuration, and using Redis for session management and token blacklisting."
  }')

if echo "$ARTICLE6" | grep -q '"code":"000"'; then
    echo -e "${GREEN}✓ Created${NC}"
else
    echo -e "${YELLOW}⚠ Failed${NC}"
fi

# Article 7: API Gateway Pattern
echo -n "Creating 'API Gateway Pattern Explained'... "
ARTICLE7=$(curl -s -X POST "$GATEWAY_URL/api/v1/articles" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JOHN_TOKEN" \
  -d '{
    "title": "API Gateway Pattern Explained",
    "content": "The API Gateway pattern is a service that sits between clients and backend services. It provides a single entry point for all client requests and handles tasks such as request routing, authentication, rate limiting, and protocol translation. This article explores the benefits of using an API Gateway in microservices architecture, common implementation patterns, and best practices for handling errors and maintaining high availability."
  }')

if echo "$ARTICLE7" | grep -q '"code":"000"'; then
    echo -e "${GREEN}✓ Created${NC}"
else
    echo -e "${YELLOW}⚠ Failed${NC}"
fi

echo ""
echo "========================================="
echo "Summary"
echo "========================================="
echo ""
echo -e "${GREEN}Sample data created successfully!${NC}"
echo ""
echo "Created Users:"
echo "  1. admin@agrios.com   / admin123  (Admin User)"
echo "  2. john@example.com   / john123   (John Doe)"
echo "  3. jane@example.com   / jane123   (Jane Smith)"
echo "  4. bob@example.com    / bob123    (Bob Wilson)"
echo ""
echo "Created Articles: 7 articles"
echo "  - 5 by Admin User"
echo "  - 2 by John Doe"
echo ""
echo "Quick Test Commands:"
echo "  # Login as admin"
echo "  curl -X POST $GATEWAY_URL/api/v1/users/login \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"email\":\"admin@agrios.com\",\"password\":\"admin123\"}'"
echo ""
echo "  # Get all articles"
echo "  curl $GATEWAY_URL/api/v1/articles"
echo ""
echo "  # Get specific article"
echo "  curl $GATEWAY_URL/api/v1/articles/1"
echo ""
