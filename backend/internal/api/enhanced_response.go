package api

import (
	"fmt"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/toeic-app/internal/errors"
	"github.com/toeic-app/internal/i18n"
	"github.com/toeic-app/internal/logger"
)

// Enhanced response structure with better error handling
type EnhancedResponse struct {
	Status    string                 `json:"status"`
	Message   string                 `json:"message,omitempty"`
	Data      interface{}            `json:"data,omitempty"`
	Error     *ErrorDetails          `json:"error,omitempty"`
	Metadata  map[string]interface{} `json:"metadata,omitempty"`
	Language  string                 `json:"language,omitempty"`
	Timestamp string                 `json:"timestamp"`
	TraceID   string                 `json:"trace_id,omitempty"`
}

// ErrorDetails provides detailed error information
type ErrorDetails struct {
	Code     string                 `json:"code"`
	Message  string                 `json:"message"`
	Details  string                 `json:"details,omitempty"`
	Fields   map[string]string      `json:"fields,omitempty"`
	Metadata map[string]interface{} `json:"metadata,omitempty"`
}

// EnhancedSuccessResponse returns an enhanced success response
func EnhancedSuccessResponse(c *gin.Context, statusCode int, messageKey string, data interface{}) {
	lang := i18n.GetLanguageFromContext(c)
	translatedMessage := i18n.T(lang, "%s", messageKey)

	resp := EnhancedResponse{
		Status:    "success",
		Message:   translatedMessage,
		Data:      data,
		Language:  string(lang),
		Timestamp: time.Now().UTC().Format(time.RFC3339),
		TraceID:   c.GetHeader("X-Trace-ID"),
	}

	logSuccessResponse(c, statusCode, translatedMessage, messageKey, data != nil)
	c.JSON(statusCode, resp)
}

// EnhancedErrorResponse returns an enhanced error response with AppError support
func EnhancedErrorResponse(c *gin.Context, appErr *errors.AppError) {
	if appErr == nil {
		appErr = errors.FromGinContext(c, errors.ErrCodeInternalServer, "Unknown error occurred")
	}

	lang := i18n.GetLanguageFromContext(c)
	statusCode := appErr.Code.GetHTTPStatus()

	errorDetails := &ErrorDetails{
		Code:    string(appErr.Code),
		Message: appErr.Message,
		Details: appErr.Details,
	}

	// Add metadata if in debug mode
	if gin.Mode() == gin.DebugMode && appErr.Metadata != nil {
		errorDetails.Metadata = appErr.Metadata
	}

	resp := EnhancedResponse{
		Status:    "error",
		Error:     errorDetails,
		Language:  string(lang),
		Timestamp: appErr.Timestamp.Format(time.RFC3339),
		TraceID:   appErr.TraceID,
	}

	logErrorResponse(c, appErr, statusCode)
	c.JSON(statusCode, resp)
}

// EnhancedValidationErrorResponse returns an enhanced validation error response
func EnhancedValidationErrorResponse(c *gin.Context, validationErr *errors.ValidationError) {
	if validationErr == nil {
		appErr := errors.FromGinContext(c, errors.ErrCodeValidationFailed, "Validation failed")
		EnhancedErrorResponse(c, appErr)
		return
	}

	lang := i18n.GetLanguageFromContext(c)
	statusCode := validationErr.Code.GetHTTPStatus()

	errorDetails := &ErrorDetails{
		Code:    string(validationErr.Code),
		Message: validationErr.Message,
		Details: validationErr.Details,
		Fields:  validationErr.Fields,
	}

	// Add metadata if in debug mode
	if gin.Mode() == gin.DebugMode && validationErr.Metadata != nil {
		errorDetails.Metadata = validationErr.Metadata
	}

	resp := EnhancedResponse{
		Status:    "error",
		Error:     errorDetails,
		Language:  string(lang),
		Timestamp: validationErr.Timestamp.Format(time.RFC3339),
		TraceID:   validationErr.TraceID,
	}

	logErrorResponse(c, validationErr.AppError, statusCode)
	c.JSON(statusCode, resp)
}

// QuickErrorResponse quickly creates an error response from error code and message
func QuickErrorResponse(c *gin.Context, code errors.ErrorCode, message string) {
	appErr := errors.FromGinContext(c, code, message)
	EnhancedErrorResponse(c, appErr)
}

// QuickErrorResponseWithDetails creates an error response with additional details
func QuickErrorResponseWithDetails(c *gin.Context, code errors.ErrorCode, message, details string) {
	appErr := errors.FromGinContext(c, code, message)
	appErr.Details = details
	EnhancedErrorResponse(c, appErr)
}

// DatabaseErrorResponse handles database errors specifically
func DatabaseErrorResponse(c *gin.Context, err error, operation string) {
	appErr := errors.HandleDatabaseError(err)
	if appErr == nil {
		appErr = errors.FromGinContext(c, errors.ErrCodeDatabaseError, "Database operation failed")
	}

	// Add operation context
	if appErr.Metadata == nil {
		appErr.Metadata = make(map[string]interface{})
	}
	appErr.Metadata["operation"] = operation

	EnhancedErrorResponse(c, appErr)
}

// logSuccessResponse logs successful responses
func logSuccessResponse(c *gin.Context, statusCode int, translatedMessage, messageKey string, hasData bool) {
	fields := logger.Fields{
		"component":          "enhanced_response",
		"method":             c.Request.Method,
		"path":               c.Request.URL.Path,
		"status_code":        statusCode,
		"message_key":        messageKey,
		"translated_message": translatedMessage,
		"client_ip":          c.ClientIP(),
		"user_agent":         c.GetHeader("User-Agent"),
		"request_id":         c.GetHeader("X-Request-ID"),
		"trace_id":           c.GetHeader("X-Trace-ID"),
		"has_data":           hasData,
	}

	// Add user information if available
	if payload, exists := c.Get("authorization_payload"); exists && payload != nil {
		if userPayload, ok := payload.(interface{ GetID() int32 }); ok {
			fields["user_id"] = userPayload.GetID()
		}
	}

	message := fmt.Sprintf("Enhanced API Success: %s", translatedMessage)
	logger.InfoWithFields(fields, "%s", message)
}

// logErrorResponse logs error responses
func logErrorResponse(c *gin.Context, appErr *errors.AppError, statusCode int) {
	fields := logger.Fields{
		"component":     "enhanced_response",
		"error_code":    string(appErr.Code),
		"error_message": appErr.Message,
		"http_status":   statusCode,
		"severity":      string(appErr.Code.GetSeverity()),
		"category":      string(appErr.Code.GetCategory()),
		"method":        c.Request.Method,
		"path":          c.Request.URL.Path,
		"client_ip":     c.ClientIP(),
		"user_agent":    c.GetHeader("User-Agent"),
		"request_id":    c.GetHeader("X-Request-ID"),
		"trace_id":      appErr.TraceID,
		"timestamp":     appErr.Timestamp.Format(time.RFC3339),
	}

	if appErr.UserID != nil {
		fields["user_id"] = *appErr.UserID
	}

	if appErr.Details != "" {
		fields["error_details"] = appErr.Details
	}

	if appErr.Metadata != nil {
		for key, value := range appErr.Metadata {
			fields[fmt.Sprintf("error_meta_%s", key)] = value
		}
	}

	message := fmt.Sprintf("Enhanced API Error: %s", appErr.Message)

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

// Backward compatibility functions - these maintain compatibility with existing code
// while gradually allowing migration to the enhanced error handling

// ErrorResponse maintains backward compatibility
func ErrorResponse(c *gin.Context, statusCode int, messageKey string, err error) {
	if err == nil {
		// Convert to AppError
		appErr := errors.FromGinContext(c, getErrorCodeFromStatus(statusCode), messageKey)
		EnhancedErrorResponse(c, appErr)
		return
	}

	// Check if it's already an AppError
	if appErr, ok := errors.IsAppError(err); ok {
		EnhancedErrorResponse(c, appErr)
		return
	}

	// Check if it's a validation error
	if validationErr, ok := errors.IsValidationError(err); ok {
		EnhancedValidationErrorResponse(c, validationErr)
		return
	}

	// Handle database errors
	if isDatabaseError(err) {
		DatabaseErrorResponse(c, err, "unknown_operation")
		return
	}

	// Convert generic error to AppError
	code := getErrorCodeFromStatus(statusCode)
	appErr := errors.Wrap(err, code, messageKey)
	appErr = appErr.WithRequestPath(c.Request.URL.Path)

	// Add trace ID if available
	if traceID := c.GetHeader("X-Trace-ID"); traceID != "" {
		appErr = appErr.WithTraceID(traceID)
	}

	// Add user ID if available
	if payload, exists := c.Get("authorization_payload"); exists && payload != nil {
		if userPayload, ok := payload.(interface{ GetID() int32 }); ok {
			appErr = appErr.WithUserID(userPayload.GetID())
		}
	}

	EnhancedErrorResponse(c, appErr)
}

// ErrorResponseWithMessage maintains backward compatibility
func ErrorResponseWithMessage(c *gin.Context, statusCode int, message string, err error) {
	code := getErrorCodeFromStatus(statusCode)
	var appErr *errors.AppError

	if err != nil {
		appErr = errors.Wrap(err, code, message)
	} else {
		appErr = errors.FromGinContext(c, code, message)
	}

	EnhancedErrorResponse(c, appErr)
}

// getErrorCodeFromStatus maps HTTP status codes to error codes
func getErrorCodeFromStatus(statusCode int) errors.ErrorCode {
	switch statusCode {
	case 400:
		return errors.ErrCodeInvalidInput
	case 401:
		return errors.ErrCodeUnauthorized
	case 403:
		return errors.ErrCodeForbidden
	case 404:
		return errors.ErrCodeNotFound
	case 409:
		return errors.ErrCodeConflict
	case 422:
		return errors.ErrCodeValidationFailed
	case 429:
		return errors.ErrCodeRateLimited
	case 500:
		return errors.ErrCodeInternalServer
	case 503:
		return errors.ErrCodeServiceUnavailable
	default:
		return errors.ErrCodeInternalServer
	}
}

// isDatabaseError checks if an error is database-related
func isDatabaseError(err error) bool {
	if err == nil {
		return false
	}

	errorMsg := err.Error()
	dbKeywords := []string{
		"sql", "database", "connection", "driver", "postgres", "pq:",
		"constraint", "foreign key", "unique", "not null", "check",
	}

	for _, keyword := range dbKeywords {
		if contains(errorMsg, keyword) {
			return true
		}
	}
	return false
}

// contains is a helper function for string checking
func contains(s, substr string) bool {
	return len(s) >= len(substr) && findSubstring(s, substr)
}

func findSubstring(s, substr string) bool {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}
