package errors

import (
	"fmt"
	"net/http"
	"time"
)

// ErrorCode represents a custom error code for better error categorization
type ErrorCode string

const (
	// Authentication and Authorization errors
	ErrCodeUnauthorized       ErrorCode = "UNAUTHORIZED"
	ErrCodeForbidden          ErrorCode = "FORBIDDEN"
	ErrCodeInvalidCredentials ErrorCode = "INVALID_CREDENTIALS"
	ErrCodeTokenExpired       ErrorCode = "TOKEN_EXPIRED"
	ErrCodeTokenInvalid       ErrorCode = "TOKEN_INVALID"

	// Validation errors
	ErrCodeValidationFailed ErrorCode = "VALIDATION_FAILED"
	ErrCodeInvalidInput     ErrorCode = "INVALID_INPUT"
	ErrCodeMissingField     ErrorCode = "MISSING_FIELD"
	ErrCodeInvalidFormat    ErrorCode = "INVALID_FORMAT"

	// Resource errors
	ErrCodeNotFound      ErrorCode = "NOT_FOUND"
	ErrCodeAlreadyExists ErrorCode = "ALREADY_EXISTS"
	ErrCodeConflict      ErrorCode = "CONFLICT"

	// Database errors
	ErrCodeDatabaseError       ErrorCode = "DATABASE_ERROR"
	ErrCodeConnectionFailed    ErrorCode = "CONNECTION_FAILED"
	ErrCodeTransactionFailed   ErrorCode = "TRANSACTION_FAILED"
	ErrCodeConstraintViolation ErrorCode = "CONSTRAINT_VIOLATION"

	// External service errors
	ErrCodeExternalService    ErrorCode = "EXTERNAL_SERVICE_ERROR"
	ErrCodeServiceUnavailable ErrorCode = "SERVICE_UNAVAILABLE"
	ErrCodeTimeout            ErrorCode = "TIMEOUT"

	// Business logic errors
	ErrCodeBusinessLogic    ErrorCode = "BUSINESS_LOGIC_ERROR"
	ErrCodeInsufficientData ErrorCode = "INSUFFICIENT_DATA"
	ErrCodeInvalidOperation ErrorCode = "INVALID_OPERATION"

	// System errors
	ErrCodeInternalServer ErrorCode = "INTERNAL_SERVER_ERROR"
	ErrCodeFileSystem     ErrorCode = "FILE_SYSTEM_ERROR"
	ErrCodeMemoryLimit    ErrorCode = "MEMORY_LIMIT_EXCEEDED"
	ErrCodeRateLimited    ErrorCode = "RATE_LIMITED"
)

// AppError represents a structured application error
type AppError struct {
	Code        ErrorCode              `json:"code"`
	Message     string                 `json:"message"`
	Details     string                 `json:"details,omitempty"`
	Metadata    map[string]interface{} `json:"metadata,omitempty"`
	Timestamp   time.Time              `json:"timestamp"`
	TraceID     string                 `json:"trace_id,omitempty"`
	UserID      *int32                 `json:"user_id,omitempty"`
	RequestPath string                 `json:"request_path,omitempty"`
	Cause       error                  `json:"-"` // Original error, not serialized
}

// Error implements the error interface
func (e *AppError) Error() string {
	if e.Details != "" {
		return fmt.Sprintf("%s: %s - %s", e.Code, e.Message, e.Details)
	}
	return fmt.Sprintf("%s: %s", e.Code, e.Message)
}

// Unwrap returns the underlying error for error unwrapping
func (e *AppError) Unwrap() error {
	return e.Cause
}

// IsCode checks if the error has a specific error code
func (e *AppError) IsCode(code ErrorCode) bool {
	return e.Code == code
}

// WithMetadata adds metadata to the error
func (e *AppError) WithMetadata(key string, value interface{}) *AppError {
	if e.Metadata == nil {
		e.Metadata = make(map[string]interface{})
	}
	e.Metadata[key] = value
	return e
}

// WithTraceID adds a trace ID to the error
func (e *AppError) WithTraceID(traceID string) *AppError {
	e.TraceID = traceID
	return e
}

// WithUserID adds a user ID to the error
func (e *AppError) WithUserID(userID int32) *AppError {
	e.UserID = &userID
	return e
}

// WithRequestPath adds the request path to the error
func (e *AppError) WithRequestPath(path string) *AppError {
	e.RequestPath = path
	return e
}

// ValidationError represents a validation error with field-specific details
type ValidationError struct {
	*AppError
	Fields map[string]string `json:"fields"`
}

// Error implements the error interface for ValidationError
func (e *ValidationError) Error() string {
	return e.AppError.Error()
}

// AddFieldError adds a field-specific error
func (e *ValidationError) AddFieldError(field, message string) {
	if e.Fields == nil {
		e.Fields = make(map[string]string)
	}
	e.Fields[field] = message
}

// ErrorSeverity represents the severity level of an error
type ErrorSeverity string

const (
	SeverityLow      ErrorSeverity = "LOW"
	SeverityMedium   ErrorSeverity = "MEDIUM"
	SeverityHigh     ErrorSeverity = "HIGH"
	SeverityCritical ErrorSeverity = "CRITICAL"
)

// ErrorCategory represents the category of an error for monitoring
type ErrorCategory string

const (
	CategoryClient     ErrorCategory = "CLIENT"
	CategoryServer     ErrorCategory = "SERVER"
	CategoryDatabase   ErrorCategory = "DATABASE"
	CategoryExternal   ErrorCategory = "EXTERNAL"
	CategoryValidation ErrorCategory = "VALIDATION"
	CategoryAuth       ErrorCategory = "AUTH"
	CategoryBusiness   ErrorCategory = "BUSINESS"
)

// GetHTTPStatus returns the appropriate HTTP status code for an error code
func (code ErrorCode) GetHTTPStatus() int {
	switch code {
	case ErrCodeUnauthorized, ErrCodeInvalidCredentials, ErrCodeTokenExpired, ErrCodeTokenInvalid:
		return http.StatusUnauthorized
	case ErrCodeForbidden:
		return http.StatusForbidden
	case ErrCodeValidationFailed, ErrCodeInvalidInput, ErrCodeMissingField, ErrCodeInvalidFormat:
		return http.StatusBadRequest
	case ErrCodeNotFound:
		return http.StatusNotFound
	case ErrCodeAlreadyExists, ErrCodeConflict:
		return http.StatusConflict
	case ErrCodeServiceUnavailable:
		return http.StatusServiceUnavailable
	case ErrCodeTimeout:
		return http.StatusRequestTimeout
	case ErrCodeRateLimited:
		return http.StatusTooManyRequests
	case ErrCodeDatabaseError, ErrCodeConnectionFailed, ErrCodeTransactionFailed,
		ErrCodeExternalService, ErrCodeInternalServer, ErrCodeFileSystem, ErrCodeMemoryLimit:
		return http.StatusInternalServerError
	default:
		return http.StatusInternalServerError
	}
}

// GetSeverity returns the severity level for an error code
func (code ErrorCode) GetSeverity() ErrorSeverity {
	switch code {
	case ErrCodeValidationFailed, ErrCodeInvalidInput, ErrCodeMissingField, ErrCodeInvalidFormat,
		ErrCodeNotFound, ErrCodeUnauthorized, ErrCodeForbidden:
		return SeverityLow
	case ErrCodeAlreadyExists, ErrCodeConflict, ErrCodeInvalidCredentials, ErrCodeTokenExpired:
		return SeverityMedium
	case ErrCodeDatabaseError, ErrCodeConnectionFailed, ErrCodeExternalService, ErrCodeTimeout:
		return SeverityHigh
	case ErrCodeInternalServer, ErrCodeTransactionFailed, ErrCodeMemoryLimit, ErrCodeConstraintViolation:
		return SeverityCritical
	default:
		return SeverityMedium
	}
}

// GetCategory returns the category for an error code
func (code ErrorCode) GetCategory() ErrorCategory {
	switch code {
	case ErrCodeValidationFailed, ErrCodeInvalidInput, ErrCodeMissingField, ErrCodeInvalidFormat:
		return CategoryValidation
	case ErrCodeUnauthorized, ErrCodeForbidden, ErrCodeInvalidCredentials, ErrCodeTokenExpired, ErrCodeTokenInvalid:
		return CategoryAuth
	case ErrCodeDatabaseError, ErrCodeConnectionFailed, ErrCodeTransactionFailed, ErrCodeConstraintViolation:
		return CategoryDatabase
	case ErrCodeExternalService, ErrCodeServiceUnavailable, ErrCodeTimeout:
		return CategoryExternal
	case ErrCodeBusinessLogic, ErrCodeInsufficientData, ErrCodeInvalidOperation:
		return CategoryBusiness
	case ErrCodeNotFound, ErrCodeAlreadyExists, ErrCodeConflict, ErrCodeRateLimited:
		return CategoryClient
	default:
		return CategoryServer
	}
}
