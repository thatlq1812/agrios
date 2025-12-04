#!/bin/bash

# Test API Gateway với curl

BASE_URL="http://localhost:8080/api/v1"

echo "================================"
echo "API Gateway Testing Script"
echo "================================"
echo ""

# Test 1: Create User
echo "1. Testing: Create User"
echo "   POST $BASE_URL/users"
curl -X POST $BASE_URL/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","password":"password123"}' \
  -w "\nHTTP Status: %{http_code}\n\n"

echo "Expected: {\"code\":\"0\",\"message\":\"success\",\"data\":{...}}"
echo ""

# Test 2: Get User
echo "2. Testing: Get User"
echo "   GET $BASE_URL/users/1"
curl -X GET $BASE_URL/users/1 \
  -w "\nHTTP Status: %{http_code}\n\n"

echo "Expected: {\"code\":\"0\",\"message\":\"success\",\"data\":{...}}"
echo ""

# Test 3: Login
echo "3. Testing: Login"
echo "   POST $BASE_URL/auth/login"
curl -X POST $BASE_URL/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}' \
  -w "\nHTTP Status: %{http_code}\n\n"

echo "Expected: {\"code\":\"0\",\"message\":\"success\",\"data\":{\"access_token\":...}}"
echo ""

# Test 4: List Users
echo "4. Testing: List Users"
echo "   GET $BASE_URL/users?page=1&page_size=10"
curl -X GET "$BASE_URL/users?page=1&page_size=10" \
  -w "\nHTTP Status: %{http_code}\n\n"

echo "Expected: {\"code\":\"0\",\"message\":\"success\",\"data\":{\"items\":[...],\"total\":...}}"
echo ""

# Test 5: Create Article
echo "5. Testing: Create Article"
echo "   POST $BASE_URL/articles"
curl -X POST $BASE_URL/articles \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Article","content":"This is test content","user_id":1}' \
  -w "\nHTTP Status: %{http_code}\n\n"

echo "Expected: {\"code\":\"0\",\"message\":\"success\",\"data\":{...}}"
echo ""

# Test 6: Get Article with User
echo "6. Testing: Get Article"
echo "   GET $BASE_URL/articles/1"
curl -X GET $BASE_URL/articles/1 \
  -w "\nHTTP Status: %{http_code}\n\n"

echo "Expected: {\"code\":\"0\",\"message\":\"success\",\"data\":{\"user\":{...}}}"
echo ""

# Test 7: List Articles
echo "7. Testing: List Articles"
echo "   GET $BASE_URL/articles?page=1&page_size=10"
curl -X GET "$BASE_URL/articles?page=1&page_size=10" \
  -w "\nHTTP Status: %{http_code}\n\n"

echo "Expected: {\"code\":\"0\",\"message\":\"success\",\"data\":{\"items\":[...]}}"
echo ""

# Test 8: Error Test - Invalid Email
echo "8. Testing: Error - Invalid Email"
echo "   POST $BASE_URL/users"
curl -X POST $BASE_URL/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"invalid-email","password":"pass"}' \
  -w "\nHTTP Status: %{http_code}\n\n"

echo "Expected: {\"code\":\"3\",\"message\":\"invalid email format\"}"
echo ""

# Test 9: Error Test - User Not Found
echo "9. Testing: Error - User Not Found"
echo "   GET $BASE_URL/users/999"
curl -X GET $BASE_URL/users/999 \
  -w "\nHTTP Status: %{http_code}\n\n"

echo "Expected: {\"code\":\"5\",\"message\":\"user not found\"}"
echo ""

# Test 10: Error Test - Duplicate Email
echo "10. Testing: Error - Duplicate Email"
echo "    POST $BASE_URL/users"
curl -X POST $BASE_URL/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","password":"password123"}' \
  -w "\nHTTP Status: %{http_code}\n\n"

echo "Expected: {\"code\":\"6\",\"message\":\"email is already registered\"}"
echo ""

echo "================================"
echo "Testing Complete!"
echo "================================"
