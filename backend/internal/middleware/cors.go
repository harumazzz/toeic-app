package middleware

import (
	"strings"

	"slices"

	"github.com/gin-gonic/gin"
	"github.com/toeic-app/internal/config"
)

// CORS middleware for handling Cross-Origin Resource Sharing
func CORS(cfg config.Config) gin.HandlerFunc {
	// Parse allowed origins from config
	var allowedOrigins []string
	if cfg.CORSAllowedOrigins != "" {
		allowedOrigins = strings.Split(cfg.CORSAllowedOrigins, ",")
		// Trim whitespace from each origin
		for i, origin := range allowedOrigins {
			allowedOrigins[i] = strings.TrimSpace(origin)
		}
	} else {
		// Default allowed origins if not configured
		allowedOrigins = []string{
			"http://localhost:3000",
			"http://localhost:8080",
			"http://localhost:8000",
			"http://192.168.31.37:8000",
			"http://127.0.0.1:8000",
			"https://localhost:3000",
			"https://localhost:8080",
			"https://localhost:8000",
			"https://192.168.31.37:8000",
			"https://127.0.0.1:8000",
			"flutter-app://toeic-app", // Flutter mobile app origin
		}
	}

	// Always ensure Flutter app origin is included
	if !slices.Contains(allowedOrigins, "flutter-app://toeic-app") {
		allowedOrigins = append(allowedOrigins, "flutter-app://toeic-app")
	}

	return func(c *gin.Context) {
		origin := c.Request.Header.Get("Origin")

		// Check if the origin is in the allowed list
		isAllowed := slices.Contains(allowedOrigins, origin)

		// Set the appropriate Access-Control-Allow-Origin header
		if isAllowed {
			c.Writer.Header().Set("Access-Control-Allow-Origin", origin)
		} else if origin == "" {
			// Allow requests without origin (like Postman, curl, etc.)
			c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		}
		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With, X-Security-Token, X-Client-Signature, X-Request-Timestamp, X-Browser-Fingerprint, X-WASM-Mode, X-Worker-Context, X-Origin-Validation, X-Security-Level, X-Encrypted-Payload, X-Request-Nonce")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE, PATCH")
		c.Writer.Header().Set("Access-Control-Expose-Headers", "Content-Length, Access-Control-Allow-Origin, Access-Control-Allow-Headers, Content-Type, X-Response-Nonce")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	}
}
