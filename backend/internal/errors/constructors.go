package errors

import (
	"database/sql"
	"errors"
	"fmt"
	"runtime"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/lib/pq"
)

// New creates a new AppError with the given code and message
func New(code ErrorCode, message string) *AppError {
	return &AppError{
		Code:      code,
		Message:   message,
		Timestamp: time.Now().UTC(),
	}
}

// Newf creates a new AppError with formatted message
func Newf(code ErrorCode, format string, args ...interface{}) *AppError {
	return &AppError{
		Code:      code,
		Message:   fmt.Sprintf(format, args...),
		Timestamp: time.Now().UTC(),
	}
}

// Wrap wraps an existing error with an AppError
func Wrap(err error, code ErrorCode, message string) *AppError {
	if err == nil {
		return nil
	}

	return &AppError{
		Code:      code,
		Message:   message,
		Details:   err.Error(),
		Cause:     err,
		Timestamp: time.Now().UTC(),
	}
}

// Wrapf wraps an existing error with formatted message
func Wrapf(err error, code ErrorCode, format string, args ...interface{}) *AppError {
	if err == nil {
		return nil
	}

	return &AppError{
		Code:      code,
		Message:   fmt.Sprintf(format, args...),
		Details:   err.Error(),
		Cause:     err,
		Timestamp: time.Now().UTC(),
	}
}

// FromGinContext creates an AppError with context information from Gin
func FromGinContext(c *gin.Context, code ErrorCode, message string) *AppError {
	appErr := New(code, message)

	if c != nil {
		appErr.RequestPath = c.Request.URL.Path

		// Add trace ID if available
		if traceID := c.GetHeader("X-Trace-ID"); traceID != "" {
			appErr.TraceID = traceID
		}

		// Add user ID if available from auth middleware
		if payload, exists := c.Get("authorization_payload"); exists && payload != nil {
			if userPayload, ok := payload.(interface{ GetID() int32 }); ok {
				appErr.UserID = &[]int32{userPayload.GetID()}[0]
			}
		}
	}

	return appErr
}

// NewValidationError creates a new validation error
func NewValidationError(message string) *ValidationError {
	return &ValidationError{
		AppError: &AppError{
			Code:      ErrCodeValidationFailed,
			Message:   message,
			Timestamp: time.Now().UTC(),
		},
		Fields: make(map[string]string),
	}
}

// NewValidationErrorWithFields creates a validation error with field errors
func NewValidationErrorWithFields(message string, fields map[string]string) *ValidationError {
	return &ValidationError{
		AppError: &AppError{
			Code:      ErrCodeValidationFailed,
			Message:   message,
			Timestamp: time.Now().UTC(),
		},
		Fields: fields,
	}
}

// HandleDatabaseError converts database errors to appropriate AppErrors
func HandleDatabaseError(err error) *AppError {
	if err == nil {
		return nil
	}

	// Handle sql.ErrNoRows
	if errors.Is(err, sql.ErrNoRows) {
		return New(ErrCodeNotFound, "Record not found")
	}

	// Handle PostgreSQL errors
	if pqErr, ok := err.(*pq.Error); ok {
		return handlePostgreSQLError(pqErr)
	}

	// Generic database error
	return Wrap(err, ErrCodeDatabaseError, "Database operation failed")
}

// handlePostgreSQLError handles specific PostgreSQL error codes
func handlePostgreSQLError(pqErr *pq.Error) *AppError {
	switch pqErr.Code {
	case "23505": // unique_violation
		return &AppError{
			Code:      ErrCodeAlreadyExists,
			Message:   "Resource already exists",
			Details:   extractConstraintDetails(pqErr),
			Cause:     pqErr,
			Timestamp: time.Now().UTC(),
		}
	case "23503": // foreign_key_violation
		return &AppError{
			Code:      ErrCodeConstraintViolation,
			Message:   "Foreign key constraint violation",
			Details:   extractConstraintDetails(pqErr),
			Cause:     pqErr,
			Timestamp: time.Now().UTC(),
		}
	case "23502": // not_null_violation
		return &AppError{
			Code:      ErrCodeValidationFailed,
			Message:   "Required field is missing",
			Details:   fmt.Sprintf("Column '%s' cannot be null", pqErr.Column),
			Cause:     pqErr,
			Timestamp: time.Now().UTC(),
		}
	case "23514": // check_violation
		return &AppError{
			Code:      ErrCodeValidationFailed,
			Message:   "Data validation failed",
			Details:   extractConstraintDetails(pqErr),
			Cause:     pqErr,
			Timestamp: time.Now().UTC(),
		}
	case "42P01": // undefined_table
		return &AppError{
			Code:      ErrCodeDatabaseError,
			Message:   "Database schema error",
			Details:   fmt.Sprintf("Table '%s' does not exist", pqErr.Table),
			Cause:     pqErr,
			Timestamp: time.Now().UTC(),
		}
	case "42703": // undefined_column
		return &AppError{
			Code:      ErrCodeDatabaseError,
			Message:   "Database schema error",
			Details:   fmt.Sprintf("Column '%s' does not exist", pqErr.Column),
			Cause:     pqErr,
			Timestamp: time.Now().UTC(),
		}
	case "08006": // connection_failure
		return &AppError{
			Code:      ErrCodeConnectionFailed,
			Message:   "Database connection failed",
			Details:   "Unable to connect to database",
			Cause:     pqErr,
			Timestamp: time.Now().UTC(),
		}
	case "57014": // query_canceled
		return &AppError{
			Code:      ErrCodeTimeout,
			Message:   "Database query timeout",
			Details:   "Query execution was canceled due to timeout",
			Cause:     pqErr,
			Timestamp: time.Now().UTC(),
		}
	default:
		return &AppError{
			Code:      ErrCodeDatabaseError,
			Message:   "Database error",
			Details:   pqErr.Message,
			Cause:     pqErr,
			Timestamp: time.Now().UTC(),
		}
	}
}

// extractConstraintDetails extracts useful information from PostgreSQL constraint errors
func extractConstraintDetails(pqErr *pq.Error) string {
	details := make([]string, 0)

	if pqErr.Table != "" {
		details = append(details, fmt.Sprintf("table: %s", pqErr.Table))
	}
	if pqErr.Column != "" {
		details = append(details, fmt.Sprintf("column: %s", pqErr.Column))
	}
	if pqErr.Constraint != "" {
		details = append(details, fmt.Sprintf("constraint: %s", pqErr.Constraint))
	}
	if pqErr.Detail != "" {
		details = append(details, fmt.Sprintf("detail: %s", pqErr.Detail))
	}

	if len(details) > 0 {
		return strings.Join(details, ", ")
	}

	return pqErr.Message
}

// IsAppError checks if an error is an AppError
func IsAppError(err error) (*AppError, bool) {
	if err == nil {
		return nil, false
	}

	var appErr *AppError
	if errors.As(err, &appErr) {
		return appErr, true
	}

	return nil, false
}

// IsValidationError checks if an error is a ValidationError
func IsValidationError(err error) (*ValidationError, bool) {
	if err == nil {
		return nil, false
	}

	var validationErr *ValidationError
	if errors.As(err, &validationErr) {
		return validationErr, true
	}

	return nil, false
}

// GetStackTrace returns a formatted stack trace
func GetStackTrace(skip int) string {
	var traces []string

	for i := skip; i < skip+10; i++ {
		pc, file, line, ok := runtime.Caller(i)
		if !ok {
			break
		}

		fn := runtime.FuncForPC(pc)
		if fn == nil {
			continue
		}

		// Extract just the filename from the full path
		parts := strings.Split(file, "/")
		filename := parts[len(parts)-1]

		trace := fmt.Sprintf("%s:%d %s", filename, line, fn.Name())
		traces = append(traces, trace)
	}

	return strings.Join(traces, "\n")
}

// RecoverFromPanic recovers from a panic and returns an AppError
func RecoverFromPanic(recovered interface{}) *AppError {
	if recovered == nil {
		return nil
	}

	stackTrace := GetStackTrace(2)

	return &AppError{
		Code:    ErrCodeInternalServer,
		Message: "Internal server error due to panic",
		Details: fmt.Sprintf("Panic: %v", recovered),
		Metadata: map[string]interface{}{
			"stack_trace": stackTrace,
			"panic_value": recovered,
		},
		Timestamp: time.Now().UTC(),
	}
}
