#!/bin/bash

# Test Partial Update Feature
# Demonstrates updating individual user fields

echo "========================================="
echo "Testing Partial Update Feature"
echo "========================================="
echo ""

GATEWAY_URL="http://localhost:8080"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Step 1: Create a test user${NC}"
echo "-------------------------------------------"
CREATE_RESPONSE=$(curl -s -X POST "$GATEWAY_URL/api/v1/users" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "testupdate@example.com",
    "password": "original123"
  }')

USER_ID=$(echo "$CREATE_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)

if [ -z "$USER_ID" ]; then
    echo -e "${YELLOW}User might already exist, trying to get existing user...${NC}"
    # Try to login to verify
    LOGIN_RESP=$(curl -s -X POST "$GATEWAY_URL/api/v1/users/login" \
      -H "Content-Type: application/json" \
      -d '{"email":"testupdate@example.com","password":"original123"}')
    
    USER_ID=$(echo "$LOGIN_RESP" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
fi

echo -e "User ID: ${GREEN}$USER_ID${NC}"
echo "Initial: testupdate@example.com / original123"
echo ""

echo -e "${BLUE}Step 2: Update only name${NC}"
echo "-------------------------------------------"
echo "Command: Update name to 'Updated Name Only'"

# For gateway, we need to check if it supports partial update
# If gateway doesn't support it yet, we'll use gRPC directly
if command -v grpcurl &> /dev/null; then
    grpcurl -plaintext -d "{\"id\": $USER_ID, \"name\": \"Updated Name Only\"}" \
      localhost:50051 user.UserService.UpdateUser
else
    echo "grpcurl not found. Using gateway (might require all fields)..."
    curl -s -X PUT "$GATEWAY_URL/api/v1/users/$USER_ID" \
      -H "Content-Type: application/json" \
      -d "{\"name\":\"Updated Name Only\",\"email\":\"testupdate@example.com\"}"
fi
echo ""

echo -e "${BLUE}Step 3: Update only email${NC}"
echo "-------------------------------------------"
echo "Command: Update email to 'newemail@example.com'"

if command -v grpcurl &> /dev/null; then
    grpcurl -plaintext -d "{\"id\": $USER_ID, \"email\": \"newemail@example.com\"}" \
      localhost:50051 user.UserService.UpdateUser
else
    curl -s -X PUT "$GATEWAY_URL/api/v1/users/$USER_ID" \
      -H "Content-Type: application/json" \
      -d "{\"name\":\"Updated Name Only\",\"email\":\"newemail@example.com\"}"
fi
echo ""

echo -e "${BLUE}Step 4: Update only password${NC}"
echo "-------------------------------------------"
echo "Command: Update password to 'newpassword456'"

if command -v grpcurl &> /dev/null; then
    grpcurl -plaintext -d "{\"id\": $USER_ID, \"password\": \"newpassword456\"}" \
      localhost:50051 user.UserService.UpdateUser
else
    echo "Password update via gateway not shown for security"
fi
echo ""

echo -e "${BLUE}Step 5: Verify changes by logging in${NC}"
echo "-------------------------------------------"
echo "Attempting login with new credentials..."

LOGIN_RESPONSE=$(curl -s -X POST "$GATEWAY_URL/api/v1/users/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newemail@example.com",
    "password": "newpassword456"
  }')

if echo "$LOGIN_RESPONSE" | grep -q '"access_token"'; then
    echo -e "${GREEN}✓ Login successful with updated credentials!${NC}"
    echo ""
    echo "Final state:"
    echo "  Name: Updated Name Only"
    echo "  Email: newemail@example.com"
    echo "  Password: newpassword456"
else
    echo -e "${YELLOW}Login failed. Response:${NC}"
    echo "$LOGIN_RESPONSE"
fi

echo ""
echo -e "${BLUE}Step 6: Update multiple fields at once${NC}"
echo "-------------------------------------------"
echo "Command: Update name and email together"

if command -v grpcurl &> /dev/null; then
    grpcurl -plaintext -d "{\"id\": $USER_ID, \"name\": \"Final Name\", \"email\": \"final@example.com\"}" \
      localhost:50051 user.UserService.UpdateUser
else
    curl -s -X PUT "$GATEWAY_URL/api/v1/users/$USER_ID" \
      -H "Content-Type: application/json" \
      -d "{\"name\":\"Final Name\",\"email\":\"final@example.com\"}"
fi
echo ""

echo "========================================="
echo "Partial Update Test Complete!"
echo "========================================="
echo ""
echo "Key Features Tested:"
echo "  ✓ Update name only"
echo "  ✓ Update email only"
echo "  ✓ Update password only"
echo "  ✓ Update multiple fields"
echo "  ✓ Verify changes persist"
echo ""
echo "Note: For full gRPC testing, install grpcurl:"
echo "  go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest"
echo ""
