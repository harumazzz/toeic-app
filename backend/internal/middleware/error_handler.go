package middleware

import (
	"fmt"
	"runtime/debug"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/toeic-app/internal/errors"
	"github.com/toeic-app/internal/logger"
)

// ErrorHandlerConfig represents configuration for error handling middleware
type ErrorHandlerConfig struct {
	EnableStackTrace   bool
	EnableMetrics      bool
	EnableDetailedLogs bool
	MaxStackTraceDepth int
}

// DefaultErrorHandlerConfig returns default configuration for error handling
func DefaultErrorHandlerConfig() ErrorHandlerConfig {
	return ErrorHandlerConfig{
		EnableStackTrace:   true,
		EnableMetrics:      true,
		EnableDetailedLogs: true,
		MaxStackTraceDepth: 10,
	}
}

// ErrorHandler creates an enhanced error handling middleware
func ErrorHandler(config ErrorHandlerConfig, metrics *errors.ErrorMetrics) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Process the request
		c.Next()

		// Check if there are any errors to handle
		if len(c.Errors) > 0 {
			handleErrors(c, c.Errors, config, metrics)
		}
	}
}

// Recovery creates an enhanced recovery middleware that handles panics
func Recovery(config ErrorHandlerConfig, metrics *errors.ErrorMetrics) gin.HandlerFunc {
	return func(c *gin.Context) {
		defer func() {
			if recovered := recover(); recovered != nil {
				handlePanic(c, recovered, config, metrics)
			}
		}()
		c.Next()
	}
}

// handleErrors processes accumulated errors from the request
func handleErrors(c *gin.Context, ginErrors []*gin.Error, config ErrorHandlerConfig, metrics *errors.ErrorMetrics) {
	// Get the last error (most recent)
	lastError := ginErrors[len(ginErrors)-1]

	var appErr *errors.AppError
	var validationErr *errors.ValidationError

	// Check if it's already an AppError
	if existingAppErr, ok := errors.IsAppError(lastError.Err); ok {
		appErr = existingAppErr
	} else if existingValidationErr, ok := errors.IsValidationError(lastError.Err); ok {
		validationErr = existingValidationErr
		appErr = validationErr.AppError
	} else {
		// Convert generic error to AppError
		appErr = convertGenericError(lastError.Err, c)
	}

	// Enhance error with context information
	enhanceErrorWithContext(appErr, c)

	// Record metrics if enabled
	if config.EnableMetrics && metrics != nil {
		metrics.RecordError(appErr, c.GetHeader("User-Agent"), c.ClientIP())
	}

	// Log the error
	if config.EnableDetailedLogs {
		logError(appErr, c, config)
	}

	// Send response
	if validationErr != nil {
		sendValidationErrorResponse(c, validationErr)
	} else {
		sendErrorResponse(c, appErr)
	}
}

// handlePanic processes panic recovery
func handlePanic(c *gin.Context, recovered interface{}, config ErrorHandlerConfig, metrics *errors.ErrorMetrics) {
	// Create error from panic
	appErr := errors.RecoverFromPanic(recovered)

	// Enhance with context
	enhanceErrorWithContext(appErr, c)

	// Add stack trace if enabled
	if config.EnableStackTrace {
		stackTrace := string(debug.Stack())
		if appErr.Metadata == nil {
			appErr.Metadata = make(map[string]interface{})
		}
		appErr.Metadata["full_stack_trace"] = stackTrace
	}

	// Record metrics
	if config.EnableMetrics && metrics != nil {
		metrics.RecordError(appErr, c.GetHeader("User-Agent"), c.ClientIP())
	}

	// Log the panic
	if config.EnableDetailedLogs {
		logPanic(appErr, recovered, c)
	}

	// Send response
	sendErrorResponse(c, appErr)
}

// convertGenericError converts a generic error to an AppError
func convertGenericError(err error, c *gin.Context) *errors.AppError {
	// Check for common error types
	switch err.Error() {
	case "EOF", "unexpected EOF":
		return errors.FromGinContext(c, errors.ErrCodeInvalidInput, "Invalid request body")
	case "invalid character":
		return errors.FromGinContext(c, errors.ErrCodeInvalidFormat, "Invalid JSON format")
	default:
		// Check if it's a binding error
		if isBindingError(err) {
			return errors.FromGinContext(c, errors.ErrCodeValidationFailed, "Request validation failed")
		}

		// Default to internal server error
		return errors.FromGinContext(c, errors.ErrCodeInternalServer, "Internal server error")
	}
}

// isBindingError checks if the error is a binding/validation error
func isBindingError(err error) bool {
	errorMsg := err.Error()
	bindingKeywords := []string{
		"binding", "validation", "required", "invalid", "format",
		"json", "unmarshal", "decode", "parse",
	}

	for _, keyword := range bindingKeywords {
		if contains(errorMsg, keyword) {
			return true
		}
	}
	return false
}

// contains is a simple string contains function
func contains(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr ||
		(len(s) > len(substr) && (s[:len(substr)] == substr ||
			s[len(s)-len(substr):] == substr ||
			containsMiddle(s, substr))))
}

func containsMiddle(s, substr string) bool {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}

// enhanceErrorWithContext adds context information to the error
func enhanceErrorWithContext(appErr *errors.AppError, c *gin.Context) {
	if appErr == nil || c == nil {
		return
	}

	// Add request path if not already set
	if appErr.RequestPath == "" {
		appErr.RequestPath = c.Request.URL.Path
	}

	// Add trace ID if available
	if appErr.TraceID == "" {
		if traceID := c.GetHeader("X-Trace-ID"); traceID != "" {
			appErr.TraceID = traceID
		}
	}

	// Add user ID if available and not already set
	if appErr.UserID == nil {
		if payload, exists := c.Get("authorization_payload"); exists && payload != nil {
			if userPayload, ok := payload.(interface{ GetID() int32 }); ok {
				userID := userPayload.GetID()
				appErr.UserID = &userID
			}
		}
	}

	// Add metadata
	if appErr.Metadata == nil {
		appErr.Metadata = make(map[string]interface{})
	}

	appErr.Metadata["method"] = c.Request.Method
	appErr.Metadata["client_ip"] = c.ClientIP()
	appErr.Metadata["user_agent"] = c.GetHeader("User-Agent")
	appErr.Metadata["timestamp"] = time.Now().UTC().Format(time.RFC3339)

	if referer := c.GetHeader("Referer"); referer != "" {
		appErr.Metadata["referer"] = referer
	}
}

// logError logs the error with structured logging
func logError(appErr *errors.AppError, c *gin.Context, _ ErrorHandlerConfig) {
	fields := logger.Fields{
		"component":     "error_handler",
		"error_code":    string(appErr.Code),
		"error_message": appErr.Message,
		"http_status":   appErr.Code.GetHTTPStatus(),
		"severity":      string(appErr.Code.GetSeverity()),
		"category":      string(appErr.Code.GetCategory()),
		"request_path":  appErr.RequestPath,
		"method":        c.Request.Method,
		"client_ip":     c.ClientIP(),
		"user_agent":    c.GetHeader("User-Agent"),
		"timestamp":     appErr.Timestamp.Format(time.RFC3339),
	}

	if appErr.TraceID != "" {
		fields["trace_id"] = appErr.TraceID
	}

	if appErr.UserID != nil {
		fields["user_id"] = *appErr.UserID
	}

	if appErr.Details != "" {
		fields["error_details"] = appErr.Details
	}

	if appErr.Metadata != nil {
		for key, value := range appErr.Metadata {
			fields[fmt.Sprintf("meta_%s", key)] = value
		}
	}

	message := fmt.Sprintf("API Error: %s", appErr.Message)

	// Log with appropriate level based on severity
	switch appErr.Code.GetSeverity() {
	case errors.SeverityCritical:
		logger.ErrorWithFields(fields, "%s", message)
	case errors.SeverityHigh:
		logger.ErrorWithFields(fields, "%s", message)
	case errors.SeverityMedium:
		logger.WarnWithFields(fields, "%s", message)
	case errors.SeverityLow:
		logger.InfoWithFields(fields, "%s", message)
	default:
		logger.WarnWithFields(fields, "%s", message)
	}
}

// logPanic logs panic information
func logPanic(appErr *errors.AppError, recovered interface{}, c *gin.Context) {
	fields := logger.Fields{
		"component":    "panic_recovery",
		"panic_value":  fmt.Sprintf("%v", recovered),
		"error_code":   string(appErr.Code),
		"request_path": appErr.RequestPath,
		"method":       c.Request.Method,
		"client_ip":    c.ClientIP(),
		"user_agent":   c.GetHeader("User-Agent"),
	}

	if appErr.TraceID != "" {
		fields["trace_id"] = appErr.TraceID
	}

	if appErr.UserID != nil {
		fields["user_id"] = *appErr.UserID
	}

	if appErr.Metadata != nil {
		if stackTrace, exists := appErr.Metadata["full_stack_trace"]; exists {
			fields["stack_trace"] = stackTrace
		}
		if shortStack, exists := appErr.Metadata["stack_trace"]; exists {
			fields["short_stack_trace"] = shortStack
		}
	}

	logger.ErrorWithFields(fields, "Panic recovered: %v", recovered)
}

// sendErrorResponse sends a standardized error response
func sendErrorResponse(c *gin.Context, appErr *errors.AppError) {
	statusCode := appErr.Code.GetHTTPStatus()

	response := gin.H{
		"status":    "error",
		"code":      string(appErr.Code),
		"message":   appErr.Message,
		"timestamp": appErr.Timestamp.Format(time.RFC3339),
	}

	if appErr.Details != "" {
		response["details"] = appErr.Details
	}

	if appErr.TraceID != "" {
		response["trace_id"] = appErr.TraceID
	}

	// Add metadata in development mode only
	if gin.Mode() == gin.DebugMode && appErr.Metadata != nil {
		response["metadata"] = appErr.Metadata
	}

	c.JSON(statusCode, response)
}

// sendValidationErrorResponse sends a validation error response
func sendValidationErrorResponse(c *gin.Context, validationErr *errors.ValidationError) {
	statusCode := validationErr.Code.GetHTTPStatus()

	response := gin.H{
		"status":    "error",
		"code":      string(validationErr.Code),
		"message":   validationErr.Message,
		"timestamp": validationErr.Timestamp.Format(time.RFC3339),
		"fields":    validationErr.Fields,
	}

	if validationErr.Details != "" {
		response["details"] = validationErr.Details
	}

	if validationErr.TraceID != "" {
		response["trace_id"] = validationErr.TraceID
	}

	c.JSON(statusCode, response)
}
