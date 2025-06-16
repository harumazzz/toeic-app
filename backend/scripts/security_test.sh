#!/bin/bash

# Security Testing Script for TOEIC Backend
# This script performs basic security tests on the API

set -e

# Configuration
API_BASE_URL="${API_BASE_URL:-http://localhost:8000}"
TEST_OUTPUT_DIR="./security_test_results"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create output directory
mkdir -p "$TEST_OUTPUT_DIR"

# Log file
LOG_FILE="$TEST_OUTPUT_DIR/security_test_$TIMESTAMP.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

test_result() {
    local test_name="$1"
    local result="$2"
    local details="$3"
    
    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}[PASS]${NC} $test_name" | tee -a "$LOG_FILE"
    elif [ "$result" = "FAIL" ]; then
        echo -e "${RED}[FAIL]${NC} $test_name - $details" | tee -a "$LOG_FILE"
    else
        echo -e "${YELLOW}[WARN]${NC} $test_name - $details" | tee -a "$LOG_FILE"
    fi
}

# Test 1: Security Headers
test_security_headers() {
    log "Testing security headers..."
    
    response=$(curl -s -I "$API_BASE_URL/health" 2>/dev/null || echo "")
    
    # Check for important security headers
    if echo "$response" | grep -qi "x-frame-options"; then
        test_result "X-Frame-Options header" "PASS"
    else
        test_result "X-Frame-Options header" "FAIL" "Missing X-Frame-Options header"
    fi
    
    if echo "$response" | grep -qi "x-content-type-options"; then
        test_result "X-Content-Type-Options header" "PASS"
    else
        test_result "X-Content-Type-Options header" "FAIL" "Missing X-Content-Type-Options header"
    fi
    
    if echo "$response" | grep -qi "strict-transport-security"; then
        test_result "Strict-Transport-Security header" "PASS"
    else
        test_result "Strict-Transport-Security header" "WARN" "Missing HSTS header (expected for HTTPS)"
    fi
}

# Test 2: Rate Limiting
test_rate_limiting() {
    log "Testing rate limiting..."
    
    # Test rate limiting by making rapid requests
    rate_limit_exceeded=false
    for i in {1..25}; do
        response_code=$(curl -s -o /dev/null -w "%{http_code}" "$API_BASE_URL/health" 2>/dev/null || echo "000")
        if [ "$response_code" = "429" ]; then
            rate_limit_exceeded=true
            break
        fi
        sleep 0.1
    done
    
    if [ "$rate_limit_exceeded" = true ]; then
        test_result "Rate limiting" "PASS"
    else
        test_result "Rate limiting" "WARN" "Rate limit not triggered with 25 rapid requests"
    fi
}

# Test 3: Input Validation
test_input_validation() {
    log "Testing input validation..."
    
    # Test XSS payload
    xss_payload="<script>alert('xss')</script>"
    response_code=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST "$API_BASE_URL/api/auth/login" \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"$xss_payload\",\"password\":\"test\"}" 2>/dev/null || echo "000")
    
    if [ "$response_code" = "400" ]; then
        test_result "XSS input validation" "PASS"
    else
        test_result "XSS input validation" "WARN" "XSS payload not rejected (code: $response_code)"
    fi
    
    # Test SQL injection payload
    sql_payload="'; DROP TABLE users; --"
    response_code=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST "$API_BASE_URL/api/auth/login" \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"$sql_payload\",\"password\":\"test\"}" 2>/dev/null || echo "000")
    
    if [ "$response_code" = "400" ]; then
        test_result "SQL injection input validation" "PASS"
    else
        test_result "SQL injection input validation" "WARN" "SQL injection payload not rejected (code: $response_code)"
    fi
}

# Test 4: Authentication Security
test_authentication() {
    log "Testing authentication security..."
    
    # Test access to protected endpoint without token
    response_code=$(curl -s -o /dev/null -w "%{http_code}" \
        "$API_BASE_URL/api/v1/users" 2>/dev/null || echo "000")
    
    if [ "$response_code" = "401" ]; then
        test_result "Protected endpoint access control" "PASS"
    else
        test_result "Protected endpoint access control" "FAIL" "Protected endpoint accessible without auth (code: $response_code)"
    fi
    
    # Test weak password (if registration is available)
    weak_password_response=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST "$API_BASE_URL/api/auth/register" \
        -H "Content-Type: application/json" \
        -d '{"username":"testuser","email":"test@example.com","password":"123"}' 2>/dev/null || echo "000")
    
    if [ "$weak_password_response" = "400" ]; then
        test_result "Weak password rejection" "PASS"
    else
        test_result "Weak password rejection" "WARN" "Weak password not rejected (code: $weak_password_response)"
    fi
}

# Test 5: HTTPS Enforcement (if applicable)
test_https_enforcement() {
    log "Testing HTTPS enforcement..."
    
    if [[ "$API_BASE_URL" == https://* ]]; then
        # Test HTTP redirect to HTTPS
        http_url=$(echo "$API_BASE_URL" | sed 's/https:/http:/')
        response_code=$(curl -s -o /dev/null -w "%{http_code}" "$http_url/health" 2>/dev/null || echo "000")
        
        if [ "$response_code" = "301" ] || [ "$response_code" = "302" ]; then
            test_result "HTTPS redirect" "PASS"
        else
            test_result "HTTPS redirect" "WARN" "HTTP not redirected to HTTPS (code: $response_code)"
        fi
    else
        test_result "HTTPS enforcement" "WARN" "Testing against HTTP endpoint"
    fi
}

# Test 6: Information Disclosure
test_information_disclosure() {
    log "Testing information disclosure..."
    
    # Test server header
    server_header=$(curl -s -I "$API_BASE_URL/health" 2>/dev/null | grep -i "server:" || echo "")
    if [ -z "$server_header" ]; then
        test_result "Server header disclosure" "PASS"
    else
        test_result "Server header disclosure" "WARN" "Server header present: $server_header"
    fi
    
    # Test error message information disclosure
    error_response=$(curl -s "$API_BASE_URL/nonexistent" 2>/dev/null || echo "")
    if echo "$error_response" | grep -qi "stack trace\|debug\|exception"; then
        test_result "Error message disclosure" "FAIL" "Detailed error information exposed"
    else
        test_result "Error message disclosure" "PASS"
    fi
}

# Test 7: CORS Configuration
test_cors() {
    log "Testing CORS configuration..."
    
    # Test CORS with malicious origin
    cors_response=$(curl -s -H "Origin: https://malicious-site.com" \
        -H "Access-Control-Request-Method: GET" \
        -H "Access-Control-Request-Headers: X-Requested-With" \
        -X OPTIONS "$API_BASE_URL/api/v1/health" 2>/dev/null || echo "")
    
    if echo "$cors_response" | grep -qi "access-control-allow-origin: https://malicious-site.com"; then
        test_result "CORS origin validation" "FAIL" "Malicious origin accepted"
    else
        test_result "CORS origin validation" "PASS"
    fi
}

# Test 8: Content Type Validation
test_content_type() {
    log "Testing content type validation..."
    
    # Test with invalid content type
    response_code=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST "$API_BASE_URL/api/auth/login" \
        -H "Content-Type: text/html" \
        -d "username=test&password=test" 2>/dev/null || echo "000")
    
    if [ "$response_code" = "400" ] || [ "$response_code" = "415" ]; then
        test_result "Content type validation" "PASS"
    else
        test_result "Content type validation" "WARN" "Invalid content type accepted (code: $response_code)"
    fi
}

# Main execution
main() {
    log "Starting security tests for $API_BASE_URL"
    log "Results will be saved to $LOG_FILE"
    
    echo "🔒 TOEIC Backend Security Tests"
    echo "================================"
    
    test_security_headers
    echo
    test_rate_limiting
    echo
    test_input_validation
    echo
    test_authentication
    echo
    test_https_enforcement
    echo
    test_information_disclosure
    echo
    test_cors
    echo
    test_content_type
    
    echo
    log "Security tests completed. Check $LOG_FILE for detailed results."
}

# Run main function
main "$@"
