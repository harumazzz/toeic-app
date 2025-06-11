package middleware

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/toeic-app/internal/config"
	"github.com/toeic-app/internal/logger"
	"github.com/toeic-app/internal/token"
)

// Security header constants
const (
	// Primary security headers
	HeaderSecurityToken      = "X-Security-Token"      // Primary security validation token
	HeaderClientSignature    = "X-Client-Signature"    // Client-side signature
	HeaderRequestTimestamp   = "X-Request-Timestamp"   // Request timestamp
	HeaderBrowserFingerprint = "X-Browser-Fingerprint" // Browser fingerprint

	// WASM/WebWorker compatibility headers
	HeaderWasmMode         = "X-WASM-Mode"         // Indicates WASM environment
	HeaderWorkerContext    = "X-Worker-Context"    // Web worker context info
	HeaderOriginValidation = "X-Origin-Validation" // Enhanced origin validation

	// Additional security headers
	HeaderSecurityLevel    = "X-Security-Level"    // Security level indicator
	HeaderEncryptedPayload = "X-Encrypted-Payload" // For sensitive data transmission
	HeaderNonce            = "X-Request-Nonce"     // Request nonce for replay protection

	// Constants
	MaxTimestampAge       = 5 * time.Minute // Maximum age for timestamp validation
	RequiredSecurityLevel = 2               // Minimum security level required
)

// AdvancedSecurityConfig holds the configuration for advanced security
type AdvancedSecurityConfig struct {
	Enabled               bool
	SecretKey             string
	RequiredHeaders       []string
	AllowedOrigins        []string
	WasmEnabled           bool
	WebWorkerEnabled      bool
	MaxTimestampAge       time.Duration
	RequiredSecurityLevel int
	BypassPaths           []string // Paths that bypass advanced security
}

// AdvancedSecurityMiddleware provides enhanced security beyond JWT
type AdvancedSecurityMiddleware struct {
	config     AdvancedSecurityConfig
	tokenMaker token.Maker
}

// NewAdvancedSecurityMiddleware creates a new advanced security middleware
func NewAdvancedSecurityMiddleware(cfg config.Config, tokenMaker token.Maker) *AdvancedSecurityMiddleware {
	// Build allowed origins from config
	var allowedOrigins []string
	if cfg.CORSAllowedOrigins != "" {
		allowedOrigins = strings.Split(cfg.CORSAllowedOrigins, ",")
		for i, origin := range allowedOrigins {
			allowedOrigins[i] = strings.TrimSpace(origin)
		}
	}

	// Always add Flutter app origin for mobile app support
	allowedOrigins = append(allowedOrigins, "flutter-app://toeic-app")

	// Default required headers for enhanced security
	requiredHeaders := []string{
		HeaderSecurityToken,
		HeaderClientSignature,
		HeaderRequestTimestamp,
		HeaderOriginValidation,
	}

	// Bypass paths (authentication endpoints, health checks, etc.)
	bypassPaths := []string{
		"/health",
		"/metrics",
		"/api/auth/login",
		"/api/auth/register",
		"/api/auth/refresh-token",
		"/swagger",
		"/api/v1/grammars",    // Public grammar endpoints
		"/api/v1/performance", // Public performance endpoints
	}

	securityConfig := AdvancedSecurityConfig{
		Enabled:               true,                  // Can be controlled via environment variable
		SecretKey:             cfg.TokenSymmetricKey, // Reuse JWT secret for HMAC
		RequiredHeaders:       requiredHeaders,
		AllowedOrigins:        allowedOrigins,
		WasmEnabled:           true,
		WebWorkerEnabled:      true,
		MaxTimestampAge:       MaxTimestampAge,
		RequiredSecurityLevel: RequiredSecurityLevel,
		BypassPaths:           bypassPaths,
	}

	return &AdvancedSecurityMiddleware{
		config:     securityConfig,
		tokenMaker: tokenMaker,
	}
}

// Middleware returns the advanced security middleware function
func (asm *AdvancedSecurityMiddleware) Middleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Skip security checks for bypass paths
		if asm.shouldBypassSecurity(c.Request.URL.Path) {
			c.Next()
			return
		}

		// Skip for OPTIONS requests (CORS preflight)
		if c.Request.Method == "OPTIONS" {
			c.Next()
			return
		}
		// Debug: Log all headers received
		logger.Debug("Request headers for %s %s:", c.Request.Method, c.Request.URL.Path)
		for name, values := range c.Request.Header {
			if strings.HasPrefix(name, "X-") || name == "Origin" || name == "Referer" {
				logger.Debug("  %s: %s", name, strings.Join(values, ", "))
			}
		}

		// Perform enhanced security validation
		if err := asm.validateAdvancedSecurity(c); err != nil {
			logger.Warn("Advanced security validation failed: %v - %s %s from %s",
				err, c.Request.Method, c.Request.URL.Path, c.ClientIP())

			c.JSON(http.StatusUnauthorized, gin.H{
				"status":  "error",
				"message": "Advanced security validation failed",
				"code":    "SECURITY_VALIDATION_FAILED",
				"error":   err.Error(), // Add detailed error for debugging
			})
			c.Abort()
			return
		}

		// Add security response headers
		asm.addSecurityResponseHeaders(c)

		c.Next()
	}
}

// validateAdvancedSecurity performs comprehensive security validation
func (asm *AdvancedSecurityMiddleware) validateAdvancedSecurity(c *gin.Context) error {
	// 1. Validate required security headers are present
	if err := asm.validateRequiredHeaders(c); err != nil {
		return fmt.Errorf("header validation failed: %w", err)
	}

	// 2. Validate request timestamp to prevent replay attacks
	if err := asm.validateTimestamp(c); err != nil {
		return fmt.Errorf("timestamp validation failed: %w", err)
	}

	// 3. Validate origin and referer
	if err := asm.validateOrigin(c); err != nil {
		return fmt.Errorf("origin validation failed: %w", err)
	}

	// 4. Validate client signature
	if err := asm.validateClientSignature(c); err != nil {
		return fmt.Errorf("signature validation failed: %w", err)
	}

	// 5. Validate security token
	if err := asm.validateSecurityToken(c); err != nil {
		return fmt.Errorf("security token validation failed: %w", err)
	}

	// 6. Validate security level
	if err := asm.validateSecurityLevel(c); err != nil {
		return fmt.Errorf("security level validation failed: %w", err)
	}

	// 7. Validate WASM/WebWorker context if applicable
	if err := asm.validateWasmWorkerContext(c); err != nil {
		return fmt.Errorf("WASM/worker context validation failed: %w", err)
	}

	return nil
}

// validateRequiredHeaders checks if all required security headers are present
func (asm *AdvancedSecurityMiddleware) validateRequiredHeaders(c *gin.Context) error {
	for _, header := range asm.config.RequiredHeaders {
		if value := c.GetHeader(header); value == "" {
			return fmt.Errorf("missing required header: %s", header)
		}
	}
	return nil
}

// validateTimestamp validates the request timestamp to prevent replay attacks
func (asm *AdvancedSecurityMiddleware) validateTimestamp(c *gin.Context) error {
	timestampStr := c.GetHeader(HeaderRequestTimestamp)
	if timestampStr == "" {
		return fmt.Errorf("missing timestamp header")
	}

	timestamp, err := strconv.ParseInt(timestampStr, 10, 64)
	if err != nil {
		return fmt.Errorf("invalid timestamp format")
	}

	requestTime := time.Unix(timestamp, 0)
	now := time.Now()

	// Check if timestamp is too old
	if now.Sub(requestTime) > asm.config.MaxTimestampAge {
		return fmt.Errorf("timestamp too old")
	}

	// Check if timestamp is in the future (allow small clock skew)
	if requestTime.Sub(now) > 1*time.Minute {
		return fmt.Errorf("timestamp too far in future")
	}

	return nil
}

// validateOrigin validates the request origin against allowed origins
func (asm *AdvancedSecurityMiddleware) validateOrigin(c *gin.Context) error {
	origin := c.GetHeader("Origin")
	referer := c.GetHeader("Referer")
	originValidation := c.GetHeader(HeaderOriginValidation)

	// For WASM/WebWorker requests, origin might be null or different
	wasmMode := c.GetHeader(HeaderWasmMode)
	workerContext := c.GetHeader(HeaderWorkerContext)

	// If WASM or WebWorker mode, use special validation
	if wasmMode != "" || workerContext != "" {
		return asm.validateWasmOrigin(c, originValidation)
	}

	// Standard origin validation
	if origin == "" && referer == "" {
		return fmt.Errorf("missing origin and referer headers")
	}

	// Validate origin against allowed list
	if origin != "" {
		if !asm.isOriginAllowed(origin) {
			return fmt.Errorf("origin not allowed: %s", origin)
		}
	}

	// Validate referer if present
	if referer != "" {
		if !asm.isRefererAllowed(referer) {
			return fmt.Errorf("referer not allowed: %s", referer)
		}
	}

	return nil
}

// validateWasmOrigin validates origin for WASM/WebWorker contexts
func (asm *AdvancedSecurityMiddleware) validateWasmOrigin(c *gin.Context, originValidation string) error {
	if !asm.config.WasmEnabled {
		return fmt.Errorf("WASM requests not enabled")
	}

	// Origin validation should be a signed token proving origin legitimacy
	if originValidation == "" {
		return fmt.Errorf("missing WASM origin validation")
	}

	// Verify the origin validation signature
	return asm.verifyOriginValidationSignature(originValidation, c)
}

// validateClientSignature validates the client-side signature
func (asm *AdvancedSecurityMiddleware) validateClientSignature(c *gin.Context) error {
	signature := c.GetHeader(HeaderClientSignature)
	if signature == "" {
		return fmt.Errorf("missing client signature")
	}

	// Build the message to verify
	timestamp := c.GetHeader(HeaderRequestTimestamp)
	method := c.Request.Method
	path := c.Request.URL.Path
	userAgent := c.GetHeader("User-Agent")

	message := fmt.Sprintf("%s|%s|%s|%s", method, path, timestamp, userAgent)

	// Verify HMAC signature using user-specific secret key
	return asm.verifyHMACSignatureWithContext(c, message, signature)
}

// validateSecurityToken validates the security token
func (asm *AdvancedSecurityMiddleware) validateSecurityToken(c *gin.Context) error {
	securityToken := c.GetHeader(HeaderSecurityToken)
	if securityToken == "" {
		return fmt.Errorf("missing security token")
	}

	// Security token should be a combination of timestamp and nonce, signed
	parts := strings.Split(securityToken, ".")
	if len(parts) != 3 {
		return fmt.Errorf("invalid security token format")
	}

	timestamp := parts[0]
	nonce := parts[1]
	signature := parts[2]

	// Verify the security token signature using user-specific secret key
	message := fmt.Sprintf("%s.%s", timestamp, nonce)
	return asm.verifyHMACSignatureWithContext(c, message, signature)
}

// validateSecurityLevel validates the security level
func (asm *AdvancedSecurityMiddleware) validateSecurityLevel(c *gin.Context) error {
	levelStr := c.GetHeader(HeaderSecurityLevel)
	if levelStr == "" {
		return fmt.Errorf("missing security level")
	}

	level, err := strconv.Atoi(levelStr)
	if err != nil {
		return fmt.Errorf("invalid security level format")
	}

	if level < asm.config.RequiredSecurityLevel {
		return fmt.Errorf("insufficient security level: %d, required: %d",
			level, asm.config.RequiredSecurityLevel)
	}

	return nil
}

// validateWasmWorkerContext validates WASM/WebWorker specific context
func (asm *AdvancedSecurityMiddleware) validateWasmWorkerContext(c *gin.Context) error {
	wasmMode := c.GetHeader(HeaderWasmMode)
	workerContext := c.GetHeader(HeaderWorkerContext)

	// If neither is present, skip WASM/Worker validation
	if wasmMode == "" && workerContext == "" {
		return nil
	}

	// Validate WASM mode if present
	if wasmMode != "" {
		if !asm.config.WasmEnabled {
			return fmt.Errorf("WASM mode not enabled")
		}

		// Validate WASM mode signature
		if err := asm.validateWasmModeSignature(wasmMode, c); err != nil {
			return fmt.Errorf("invalid WASM mode signature: %w", err)
		}
	}

	// Validate worker context if present
	if workerContext != "" {
		if !asm.config.WebWorkerEnabled {
			return fmt.Errorf("web worker mode not enabled")
		}

		// Validate worker context signature
		if err := asm.validateWorkerContextSignature(workerContext, c); err != nil {
			return fmt.Errorf("invalid worker context signature: %w", err)
		}
	}

	return nil
}

// Utility functions

// shouldBypassSecurity checks if the request path should bypass security
func (asm *AdvancedSecurityMiddleware) shouldBypassSecurity(path string) bool {
	for _, bypassPath := range asm.config.BypassPaths {
		if strings.HasPrefix(path, bypassPath) {
			return true
		}
	}
	return false
}

// isOriginAllowed checks if the origin is in the allowed list
func (asm *AdvancedSecurityMiddleware) isOriginAllowed(origin string) bool {
	for _, allowedOrigin := range asm.config.AllowedOrigins {
		if origin == allowedOrigin {
			return true
		}
	}
	return false
}

// isRefererAllowed checks if the referer is from an allowed origin
func (asm *AdvancedSecurityMiddleware) isRefererAllowed(referer string) bool {
	for _, allowedOrigin := range asm.config.AllowedOrigins {
		if strings.HasPrefix(referer, allowedOrigin) {
			return true
		}
	}
	return false
}

// verifyHMACSignature verifies an HMAC signature using user-specific secret key
func (asm *AdvancedSecurityMiddleware) verifyHMACSignature(message, signature string) error {
	// This is a fallback method that uses server secret key
	// The context-aware methods should be preferred
	logger.Debug("Using fallback server secret key for HMAC verification")

	// Calculate expected signature using server secret key
	h := hmac.New(sha256.New, []byte(asm.config.SecretKey))
	h.Write([]byte(message))
	expectedSignature := hex.EncodeToString(h.Sum(nil))

	// Debug logging to help troubleshoot HMAC mismatches
	logger.Debug("HMAC Verification - Message: %s", message)
	logger.Debug("HMAC Verification - Server Secret Key Length: %d", len(asm.config.SecretKey))
	logger.Debug("HMAC Verification - Expected Signature: %s", expectedSignature)
	logger.Debug("HMAC Verification - Received Signature: %s", signature)

	// Compare signatures
	if !hmac.Equal([]byte(signature), []byte(expectedSignature)) {
		return fmt.Errorf("signature verification failed")
	}

	return nil
}

// verifyHMACSignatureWithContext verifies an HMAC signature using user-specific secret key
func (asm *AdvancedSecurityMiddleware) verifyHMACSignatureWithContext(c *gin.Context, message, signature string) error {
	// Get user-specific secret key from the JWT token
	userSecretKey, err := asm.getUserSecretKeyFromContext(c)
	if err != nil {
		logger.Debug("Failed to get user secret key, falling back to server key: %v", err)
		// Fallback to server secret key for compatibility
		return asm.verifyHMACSignature(message, signature)
	}

	// Calculate expected signature using user-specific secret key
	h := hmac.New(sha256.New, []byte(userSecretKey))
	h.Write([]byte(message))
	expectedSignature := hex.EncodeToString(h.Sum(nil))

	// Debug logging to help troubleshoot HMAC mismatches
	logger.Debug("HMAC Verification - Message: %s", message)
	logger.Debug("HMAC Verification - User Secret Key: %s", (userSecretKey))
	logger.Debug("HMAC Verification - User Secret Key Length: %d", len(userSecretKey))
	logger.Debug("HMAC Verification - Expected Signature: %s", expectedSignature)
	logger.Debug("HMAC Verification - Received Signature: %s", signature)
	logger.Debug("HMAC Verification - Message Length: %d", len(message))
	logger.Debug("HMAC Verification - Signature Length: %d", len(signature))

	// Compare signatures
	if !hmac.Equal([]byte(signature), []byte(expectedSignature)) {
		return fmt.Errorf("signature verification failed")
	}

	return nil
}

// verifyOriginValidationSignature verifies the origin validation signature for WASM
func (asm *AdvancedSecurityMiddleware) verifyOriginValidationSignature(validation string, c *gin.Context) error {
	// Decode the validation token
	parts := strings.Split(validation, ".")
	if len(parts) != 2 {
		return fmt.Errorf("invalid origin validation format")
	}

	payload := parts[0]
	signature := parts[1]

	logger.Debug("Origin validation payload (plain text): %s", payload)
	logger.Debug("Origin validation signature: %s", signature)

	// Flutter client sends the payload as plain text (not base64 encoded)
	// and generates HMAC on the plain text payload directly
	return asm.verifyHMACSignatureWithContext(c, payload, signature)
}

// validateWasmModeSignature validates WASM mode signature
func (asm *AdvancedSecurityMiddleware) validateWasmModeSignature(wasmMode string, c *gin.Context) error {
	parts := strings.Split(wasmMode, ".")
	if len(parts) != 2 {
		return fmt.Errorf("invalid WASM mode format")
	}

	payload := parts[0]
	signature := parts[1]

	// Flutter client sends payload as plain text (not base64 encoded)
	return asm.verifyHMACSignatureWithContext(c, payload, signature)
}

// validateWorkerContextSignature validates web worker context signature
func (asm *AdvancedSecurityMiddleware) validateWorkerContextSignature(workerContext string, c *gin.Context) error {
	parts := strings.Split(workerContext, ".")
	if len(parts) != 2 {
		return fmt.Errorf("invalid worker context format")
	}

	payload := parts[0]
	signature := parts[1]

	// Flutter client sends payload as plain text (not base64 encoded)
	return asm.verifyHMACSignatureWithContext(c, payload, signature)
}

// addSecurityResponseHeaders adds security-related response headers
func (asm *AdvancedSecurityMiddleware) addSecurityResponseHeaders(c *gin.Context) {
	// Add security policy headers
	c.Header("X-Content-Type-Options", "nosniff")
	c.Header("X-Frame-Options", "DENY")
	c.Header("X-XSS-Protection", "1; mode=block")
	c.Header("Referrer-Policy", "strict-origin-when-cross-origin")

	// Add WASM-specific headers if applicable
	if c.GetHeader(HeaderWasmMode) != "" {
		c.Header("Cross-Origin-Embedder-Policy", "require-corp")
		c.Header("Cross-Origin-Opener-Policy", "same-origin")
	}

	// Add response nonce for client validation
	nonce := asm.generateResponseNonce()
	c.Header("X-Response-Nonce", nonce)
}

// generateResponseNonce generates a response nonce
func (asm *AdvancedSecurityMiddleware) generateResponseNonce() string {
	timestamp := time.Now().Unix()
	message := fmt.Sprintf("response_%d", timestamp)
	h := hmac.New(sha256.New, []byte(asm.config.SecretKey))
	h.Write([]byte(message))
	return hex.EncodeToString(h.Sum(nil))[:16] // Use first 16 characters
}

// getUserSecretKeyFromContext extracts the user ID from the JWT token and generates the user-specific secret key
func (asm *AdvancedSecurityMiddleware) getUserSecretKeyFromContext(c *gin.Context) (string, error) {
	// Try to get the Authorization header to extract user ID
	authHeader := c.GetHeader("Authorization")
	if authHeader == "" {
		return "", fmt.Errorf("no authorization header")
	}

	// Parse Bearer token
	parts := strings.Split(authHeader, " ")
	if len(parts) != 2 || strings.ToLower(parts[0]) != "bearer" {
		return "", fmt.Errorf("invalid authorization header format")
	}

	token := parts[1]
	// Verify token and extract payload
	payload, err := asm.tokenMaker.VerifyToken(token)
	if err != nil {
		return "", fmt.Errorf("invalid token: %w", err)
	}

	// Generate user-specific secret key using the same logic as in auth handler
	return asm.generateClientSecurityKey(payload.ID), nil
}

// generateClientSecurityKey generates a unique security key for the client (same as auth handler)
func (asm *AdvancedSecurityMiddleware) generateClientSecurityKey(userID int32) string {
	// Generate deterministic key based on server secret and user ID (no timestamp)
	// This must match the same logic in auth handler
	message := fmt.Sprintf("%s_user_%d", asm.config.SecretKey, userID)

	// Generate HMAC-SHA256 hash
	h := hmac.New(sha256.New, []byte(asm.config.SecretKey))
	h.Write([]byte(message))
	hash := h.Sum(nil)

	// Return first 32 bytes as hex string (256 bits)
	return hex.EncodeToString(hash)[:64]
}
