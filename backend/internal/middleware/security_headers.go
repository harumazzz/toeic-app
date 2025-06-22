package middleware

import (
	"crypto/tls"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/toeic-app/internal/config"
	"github.com/toeic-app/internal/logger"
)

// SecurityHeaders middleware adds comprehensive security headers
func SecurityHeaders(cfg config.Config) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Strict Transport Security (HSTS)
		if c.Request.TLS != nil || c.GetHeader("X-Forwarded-Proto") == "https" {
			c.Header("Strict-Transport-Security", "max-age=31536000; includeSubDomains; preload")
		}
		// Content Security Policy (CSP) - relaxed for Swagger UI
		var csp string
		if strings.HasPrefix(c.Request.URL.Path, "/swagger") {
			csp = buildSwaggerCSP(cfg)
		} else {
			csp = buildContentSecurityPolicy(cfg)
		}
		c.Header("Content-Security-Policy", csp)

		// Additional security headers
		c.Header("X-Frame-Options", "DENY")
		c.Header("X-Content-Type-Options", "nosniff")
		c.Header("X-XSS-Protection", "1; mode=block")
		c.Header("Referrer-Policy", "strict-origin-when-cross-origin")
		c.Header("X-Download-Options", "noopen")
		c.Header("X-Permitted-Cross-Domain-Policies", "none")

		// Permissions Policy (formerly Feature Policy)
		permissionsPolicy := buildPermissionsPolicy()
		c.Header("Permissions-Policy", permissionsPolicy)

		// Cross-Origin headers for enhanced security
		c.Header("Cross-Origin-Embedder-Policy", "require-corp")
		c.Header("Cross-Origin-Opener-Policy", "same-origin")
		c.Header("Cross-Origin-Resource-Policy", "same-origin")

		// Remove server identifying headers
		c.Header("Server", "")
		c.Header("X-Powered-By", "")

		c.Next()
	}
}

// buildContentSecurityPolicy creates a comprehensive CSP header
func buildContentSecurityPolicy(cfg config.Config) string {
	// Base CSP for API endpoints
	csp := []string{
		"default-src 'none'",
		"script-src 'none'",
		"style-src 'none'",
		"img-src 'none'",
		"font-src 'none'",
		"connect-src 'self'",
		"frame-ancestors 'none'",
		"base-uri 'none'",
		"form-action 'none'",
	}
	// Allow specific origins for development
	if strings.Contains(cfg.CORSAllowedOrigins, "localhost") || cfg.DisableHTTPSRedirect {
		// Development: don't upgrade insecure requests
		// csp = append(csp, "upgrade-insecure-requests") - commented out for dev
	} else {
		// Production: require HTTPS
		csp = append(csp, "upgrade-insecure-requests", "block-all-mixed-content")
	}

	return strings.Join(csp, "; ")
}

// buildSwaggerCSP creates a CSP header suitable for Swagger UI
func buildSwaggerCSP(cfg config.Config) string {
	// More permissive CSP for Swagger UI to function properly
	csp := []string{
		"default-src 'self'",
		"script-src 'self' 'unsafe-inline'",
		"style-src 'self' 'unsafe-inline'",
		"img-src 'self' data:",
		"font-src 'self'",
		"connect-src 'self'",
		"frame-ancestors 'none'",
		"base-uri 'self'",
		"form-action 'self'",
	}

	// Allow specific origins for development
	if strings.Contains(cfg.CORSAllowedOrigins, "localhost") || cfg.DisableHTTPSRedirect {
		// Development: don't upgrade insecure requests
		// csp = append(csp, "upgrade-insecure-requests") - commented out for dev
	} else {
		// Production: require HTTPS
		csp = append(csp, "upgrade-insecure-requests", "block-all-mixed-content")
	}

	return strings.Join(csp, "; ")
}

// buildPermissionsPolicy creates a restrictive permissions policy
func buildPermissionsPolicy() string {
	policies := []string{
		"accelerometer=()",
		"camera=()",
		"geolocation=()",
		"gyroscope=()",
		"magnetometer=()",
		"microphone=()",
		"payment=()",
		"usb=()",
		"interest-cohort=()",
	}

	return strings.Join(policies, ", ")
}

// TLSConfig returns a secure TLS configuration
func TLSConfig() *tls.Config {
	return &tls.Config{
		MinVersion: tls.VersionTLS12,
		CipherSuites: []uint16{
			tls.TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,
			tls.TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,
			tls.TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,
			tls.TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,
			tls.TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,
			tls.TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,
		},
		PreferServerCipherSuites: true,
		CurvePreferences: []tls.CurveID{
			tls.X25519,
			tls.CurveP256,
			tls.CurveP384,
			tls.CurveP521,
		},
	}
}

// HTTPSRedirect middleware redirects HTTP to HTTPS in production
func HTTPSRedirect(cfg config.Config) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Log the configuration for debugging
		logger.InfoWithFields(logger.Fields{
			"component":              "security",
			"action":                 "https_redirect_check",
			"server_address":         cfg.ServerAddress,
			"disable_https_redirect": cfg.DisableHTTPSRedirect,
		}, "Checking HTTPS redirect configuration")

		// Skip redirect if explicitly disabled
		if cfg.DisableHTTPSRedirect {
			logger.Info("HTTPS redirect disabled by configuration")
			c.Next()
			return
		}

		// Skip redirect in development environments
		isDevelopment := strings.Contains(cfg.ServerAddress, "127.0.0.1") ||
			strings.Contains(cfg.ServerAddress, "localhost") ||
			strings.HasPrefix(cfg.ServerAddress, "192.168.") ||
			strings.HasPrefix(cfg.ServerAddress, "10.") ||
			strings.HasPrefix(cfg.ServerAddress, "172.16.") ||
			strings.Contains(cfg.ServerAddress, ":8000") || // Common dev port
			strings.Contains(cfg.ServerAddress, ":3000") // Common dev port

		if isDevelopment {
			logger.InfoWithFields(logger.Fields{
				"component": "security",
				"action":    "https_redirect_skip",
				"reason":    "development_environment",
			}, "Skipping HTTPS redirect for development")
			c.Next()
			return
		}

		// Check if request is not HTTPS
		if c.Request.TLS == nil && c.GetHeader("X-Forwarded-Proto") != "https" {
			// Redirect to HTTPS
			httpsURL := "https://" + c.Request.Host + c.Request.RequestURI
			logger.InfoWithFields(logger.Fields{
				"component": "security",
				"action":    "https_redirect",
				"from":      c.Request.URL.String(),
				"to":        httpsURL,
			}, "Redirecting HTTP to HTTPS")

			c.Redirect(http.StatusMovedPermanently, httpsURL)
			c.Abort()
			return
		}

		c.Next()
	}
}

// RequestSizeLimit middleware limits request body size
func RequestSizeLimit(maxBytes int64) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, maxBytes)
		c.Next()
	}
}

// SecureHeaders middleware for sensitive endpoints
func SecureHeaders() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Additional headers for sensitive operations
		c.Header("Cache-Control", "no-cache, no-store, must-revalidate, private")
		c.Header("Pragma", "no-cache")
		c.Header("Expires", "0")

		c.Next()
	}
}
