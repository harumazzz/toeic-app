package middleware

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"regexp"
	"strings"
	"unicode"

	"github.com/gin-gonic/gin"
	"github.com/toeic-app/internal/logger"
)

// shouldValidateRequestBody determines if a request body should be validated
func shouldValidateRequestBody(c *gin.Context) bool {
	// Skip validation for methods that typically don't have bodies
	method := c.Request.Method
	if method == "GET" || method == "HEAD" || method == "OPTIONS" {
		return false
	}

	// For DELETE requests, only validate if there's actually a Content-Type indicating a body
	if method == "DELETE" {
		contentType := c.GetHeader("Content-Type")
		return contentType != "" && (strings.Contains(contentType, "application/json") ||
			strings.Contains(contentType, "application/x-www-form-urlencoded") ||
			strings.Contains(contentType, "multipart/form-data"))
	}

	// For PUT, POST, PATCH - always validate as they typically have bodies
	return true
}

// InputValidationConfig holds configuration for input validation
type InputValidationConfig struct {
	MaxJSONDepth        int
	MaxArrayLength      int
	MaxStringLength     int
	MaxNumericValue     float64
	ForbiddenPatterns   []string
	RequiredHeaders     []string
	AllowedContentTypes []string
}

// DefaultInputValidationConfig returns default validation configuration
func DefaultInputValidationConfig() InputValidationConfig {
	return InputValidationConfig{
		MaxJSONDepth:    10,
		MaxArrayLength:  1000,
		MaxStringLength: 10000,
		MaxNumericValue: 1e10,
		ForbiddenPatterns: []string{
			`<script`,
			`javascript:`,
			`vbscript:`,
			`onload=`,
			`onerror=`,
			`onclick=`,
			`<iframe`,
			`eval\(`,
			`setTimeout\(`,
			`setInterval\(`,
		},
		AllowedContentTypes: []string{
			"application/json",
			"application/x-www-form-urlencoded",
			"multipart/form-data",
		},
	}
}

// EnhancedInputValidation middleware provides comprehensive input validation
func EnhancedInputValidation(config InputValidationConfig) gin.HandlerFunc {
	forbiddenRegexes := make([]*regexp.Regexp, len(config.ForbiddenPatterns))
	for i, pattern := range config.ForbiddenPatterns {
		forbiddenRegexes[i] = regexp.MustCompile(`(?i)` + pattern)
	}

	return func(c *gin.Context) {
		// Validate content type
		if err := validateContentType(c, config.AllowedContentTypes); err != nil {
			logger.WarnWithFields(logger.Fields{
				"component": "input_validation",
				"error":     err.Error(),
				"path":      c.Request.URL.Path,
				"method":    c.Request.Method,
				"client_ip": c.ClientIP(),
			}, "Invalid content type")

			c.JSON(http.StatusBadRequest, gin.H{
				"status":  "error",
				"message": "Invalid content type",
				"error":   err.Error(),
			})
			c.Abort()
			return
		}

		// Validate request headers
		if err := validateHeaders(c, forbiddenRegexes); err != nil {
			logger.WarnWithFields(logger.Fields{
				"component": "input_validation",
				"error":     err.Error(),
				"path":      c.Request.URL.Path,
				"method":    c.Request.Method,
				"client_ip": c.ClientIP(),
			}, "Malicious header detected")

			c.JSON(http.StatusBadRequest, gin.H{
				"status":  "error",
				"message": "Invalid request headers",
			})
			c.Abort()
			return
		}

		// Validate query parameters
		if err := validateQueryParams(c, forbiddenRegexes, config.MaxStringLength); err != nil {
			logger.WarnWithFields(logger.Fields{
				"component": "input_validation",
				"error":     err.Error(),
				"path":      c.Request.URL.Path,
				"method":    c.Request.Method,
				"client_ip": c.ClientIP(),
			}, "Malicious query parameter detected")

			c.JSON(http.StatusBadRequest, gin.H{
				"status":  "error",
				"message": "Invalid query parameters",
			})
			c.Abort()
			return
		}
		// Validate request body for methods that typically have bodies
		// Only validate if the request actually has content or expects JSON
		if shouldValidateRequestBody(c) {
			if err := validateRequestBody(c, config, forbiddenRegexes); err != nil {
				logger.WarnWithFields(logger.Fields{
					"component": "input_validation",
					"error":     err.Error(),
					"path":      c.Request.URL.Path,
					"method":    c.Request.Method,
					"client_ip": c.ClientIP(),
				}, "Malicious request body detected")

				c.JSON(http.StatusBadRequest, gin.H{
					"status":  "error",
					"message": "Invalid request body",
				})
				c.Abort()
				return
			}
		}

		c.Next()
	}
}

// validateContentType checks if the content type is allowed
func validateContentType(c *gin.Context, allowedTypes []string) error {
	contentType := c.GetHeader("Content-Type")
	if contentType == "" && c.Request.Method != "GET" && c.Request.Method != "HEAD" {
		return fmt.Errorf("missing content type")
	}

	if contentType == "" {
		return nil // Allow empty content type for GET/HEAD requests
	}

	// Remove charset and other parameters
	mainType := strings.Split(contentType, ";")[0]
	mainType = strings.TrimSpace(mainType)

	for _, allowed := range allowedTypes {
		if strings.EqualFold(mainType, allowed) {
			return nil
		}
	}

	return fmt.Errorf("content type %s not allowed", mainType)
}

// validateHeaders checks request headers for malicious content
func validateHeaders(c *gin.Context, forbiddenRegexes []*regexp.Regexp) error {
	for name, values := range c.Request.Header {
		// Skip internal headers
		if strings.HasPrefix(name, "X-") && strings.Contains(name, "Security") {
			continue
		}

		for _, value := range values {
			if err := validateString(value, forbiddenRegexes); err != nil {
				return fmt.Errorf("malicious content in header %s: %w", name, err)
			}

			// Check for header injection
			if strings.Contains(value, "\n") || strings.Contains(value, "\r") {
				return fmt.Errorf("header injection attempt in %s", name)
			}
		}
	}

	return nil
}

// validateQueryParams checks query parameters for malicious content
func validateQueryParams(c *gin.Context, forbiddenRegexes []*regexp.Regexp, maxLength int) error {
	for key, values := range c.Request.URL.Query() {
		if len(key) > maxLength {
			return fmt.Errorf("query parameter key too long: %s", key)
		}

		if err := validateString(key, forbiddenRegexes); err != nil {
			return fmt.Errorf("malicious content in query parameter key %s: %w", key, err)
		}

		for _, value := range values {
			if len(value) > maxLength {
				return fmt.Errorf("query parameter value too long for key: %s", key)
			}

			if err := validateString(value, forbiddenRegexes); err != nil {
				return fmt.Errorf("malicious content in query parameter %s: %w", key, err)
			}
		}
	}

	return nil
}

// validateRequestBody validates the request body
func validateRequestBody(c *gin.Context, config InputValidationConfig, forbiddenRegexes []*regexp.Regexp) error {
	if c.Request.Body == nil {
		return nil
	}

	// Read the body
	body, err := io.ReadAll(c.Request.Body)
	if err != nil {
		logger.WarnWithFields(logger.Fields{
			"component": "input_validation",
			"error":     err.Error(),
			"path":      c.Request.URL.Path,
			"method":    c.Request.Method,
		}, "Failed to read request body")
		return fmt.Errorf("failed to read request body: %w", err)
	}

	// Restore the body for further processing - create a new reader
	c.Request.Body = io.NopCloser(bytes.NewReader(body))

	// If body is empty, no validation needed
	if len(body) == 0 {
		// For POST/PUT/PATCH requests, empty body might be suspicious
		if c.Request.Method == "POST" || c.Request.Method == "PUT" || c.Request.Method == "PATCH" {
			contentType := c.GetHeader("Content-Type")
			if strings.Contains(contentType, "application/json") {
				logger.DebugWithFields(logger.Fields{
					"component":    "input_validation",
					"path":         c.Request.URL.Path,
					"method":       c.Request.Method,
					"content_type": contentType,
				}, "Empty JSON body detected")
			}
		}
		return nil
	}

	// Check if it's JSON
	contentType := c.GetHeader("Content-Type")
	if strings.Contains(contentType, "application/json") {
		return validateJSONBody(body, config, forbiddenRegexes)
	}

	// For other content types, validate as string
	return validateString(string(body), forbiddenRegexes)
}

// validateJSONBody validates JSON request body
func validateJSONBody(body []byte, config InputValidationConfig, forbiddenRegexes []*regexp.Regexp) error {
	// First, validate the raw JSON string
	if err := validateString(string(body), forbiddenRegexes); err != nil {
		return fmt.Errorf("malicious content in JSON body: %w", err)
	}

	// Parse JSON to validate structure
	var data interface{}
	if err := json.Unmarshal(body, &data); err != nil {
		return fmt.Errorf("invalid JSON: %w", err)
	}

	// Validate JSON structure
	return validateJSONStructure(data, config, forbiddenRegexes, 0)
}

// validateJSONStructure recursively validates JSON structure
func validateJSONStructure(data interface{}, config InputValidationConfig, forbiddenRegexes []*regexp.Regexp, depth int) error {
	if depth > config.MaxJSONDepth {
		return fmt.Errorf("JSON nesting too deep: %d", depth)
	}

	switch v := data.(type) {
	case string:
		if len(v) > config.MaxStringLength {
			return fmt.Errorf("string value too long: %d", len(v))
		}
		return validateString(v, forbiddenRegexes)

	case float64:
		if v > config.MaxNumericValue || v < -config.MaxNumericValue {
			return fmt.Errorf("numeric value out of range: %f", v)
		}

	case []interface{}:
		if len(v) > config.MaxArrayLength {
			return fmt.Errorf("array too long: %d", len(v))
		}
		for _, item := range v {
			if err := validateJSONStructure(item, config, forbiddenRegexes, depth+1); err != nil {
				return err
			}
		}

	case map[string]interface{}:
		for key, value := range v {
			if len(key) > config.MaxStringLength {
				return fmt.Errorf("object key too long: %s", key)
			}
			if err := validateString(key, forbiddenRegexes); err != nil {
				return fmt.Errorf("malicious content in object key %s: %w", key, err)
			}
			if err := validateJSONStructure(value, config, forbiddenRegexes, depth+1); err != nil {
				return err
			}
		}
	}

	return nil
}

// validateString checks a string against forbidden patterns
func validateString(s string, forbiddenRegexes []*regexp.Regexp) error {
	// Check for NULL bytes
	if strings.Contains(s, "\x00") {
		return fmt.Errorf("null byte detected")
	}

	// Check for control characters (except normal whitespace)
	for _, r := range s {
		if unicode.IsControl(r) && r != '\n' && r != '\r' && r != '\t' {
			return fmt.Errorf("control character detected: %U", r)
		}
	}

	// Check against forbidden patterns
	for _, regex := range forbiddenRegexes {
		if regex.MatchString(s) {
			return fmt.Errorf("forbidden pattern detected")
		}
	}
	return nil
}

// XMLBombProtection protects against XML bomb attacks
func XMLBombProtection(maxEntityExpansions int, maxEntityDepth int) gin.HandlerFunc {
	return func(c *gin.Context) {
		contentType := c.GetHeader("Content-Type")
		if strings.Contains(contentType, "xml") {
			// Read and check XML content
			body, err := io.ReadAll(c.Request.Body)
			if err != nil {
				c.JSON(http.StatusBadRequest, gin.H{
					"status":  "error",
					"message": "Failed to read request body",
				})
				c.Abort()
				return
			}

			// Simple XML bomb detection
			bodyStr := string(body)
			entityCount := strings.Count(bodyStr, "<!ENTITY")
			if entityCount > maxEntityExpansions {
				logger.WarnWithFields(logger.Fields{
					"component":    "xml_protection",
					"entity_count": entityCount,
					"client_ip":    c.ClientIP(),
					"path":         c.Request.URL.Path,
				}, "Potential XML bomb detected")

				c.JSON(http.StatusBadRequest, gin.H{
					"status":  "error",
					"message": "XML entity limit exceeded",
				})
				c.Abort()
				return
			}

			// Restore body
			c.Request.Body = io.NopCloser(bytes.NewBuffer(body))
		}

		c.Next()
	}
}
