package api

import (
	"github.com/gin-gonic/gin"
	"github.com/toeic-app/internal/i18n"
	"github.com/toeic-app/internal/logger"
)

// Response is a standardized API response structure
type Response struct {
	Status   string `json:"status"`
	Message  string `json:"message,omitempty"`
	Data     any    `json:"data,omitempty"`
	Error    string `json:"error,omitempty"`
	Language string `json:"language,omitempty"`
}

// SuccessResponse returns a standard success response with i18n support
func SuccessResponse(c *gin.Context, statusCode int, messageKey string, data interface{}) {
	path := c.Request.URL.Path
	method := c.Request.Method
	lang := i18n.GetLanguageFromContext(c)

	// Translate the message
	translatedMessage := i18n.T(lang, "%s", messageKey)

	resp := Response{
		Status:   "success",
		Message:  translatedMessage,
		Data:     data,
		Language: string(lang),
	}

	// Log successful response
	logger.Debug("[%s] %s - Success (%d): %s (key: %s, lang: %s)", method, path, statusCode, translatedMessage, messageKey, lang)

	c.JSON(statusCode, resp)
}

// SuccessResponseWithMessage returns a standard success response with custom message (no translation)
func SuccessResponseWithMessage(c *gin.Context, statusCode int, message string, data interface{}) {
	path := c.Request.URL.Path
	method := c.Request.Method
	lang := i18n.GetLanguageFromContext(c)

	resp := Response{
		Status:   "success",
		Message:  message,
		Data:     data,
		Language: string(lang),
	}

	// Log successful response
	logger.Debug("[%s] %s - Success (%d): %s (custom message, lang: %s)", method, path, statusCode, message, lang)

	c.JSON(statusCode, resp)
}

// ErrorResponse returns a standard error response with i18n support
func ErrorResponse(c *gin.Context, statusCode int, messageKey string, err error) {
	path := c.Request.URL.Path
	method := c.Request.Method
	lang := i18n.GetLanguageFromContext(c)

	// Translate the message
	translatedMessage := i18n.T(lang, "%s", messageKey)

	errMsg := ""
	if err != nil {
		errMsg = err.Error()
	}

	resp := Response{
		Status:   "error",
		Message:  translatedMessage,
		Error:    errMsg,
		Language: string(lang),
	}

	// Log error response with appropriate level based on status code
	switch {
	case statusCode >= 500:
		logger.Error("[%s] %s - Error (%d): %s (key: %s, lang: %s) - %s", method, path, statusCode, translatedMessage, messageKey, lang, errMsg)
	case statusCode >= 400:
		logger.Warn("[%s] %s - Error (%d): %s (key: %s, lang: %s) - %s", method, path, statusCode, translatedMessage, messageKey, lang, errMsg)
	default:
		logger.Info("[%s] %s - Error (%d): %s (key: %s, lang: %s) - %s", method, path, statusCode, translatedMessage, messageKey, lang, errMsg)
	}

	c.JSON(statusCode, resp)
}

// ErrorResponseWithMessage returns a standard error response with custom message (no translation)
func ErrorResponseWithMessage(c *gin.Context, statusCode int, message string, err error) {
	path := c.Request.URL.Path
	method := c.Request.Method
	lang := i18n.GetLanguageFromContext(c)

	errMsg := ""
	if err != nil {
		errMsg = err.Error()
	}

	resp := Response{
		Status:   "error",
		Message:  message,
		Error:    errMsg,
		Language: string(lang),
	}

	// Log error response with appropriate level based on status code
	switch {
	case statusCode >= 500:
		logger.Error("[%s] %s - Error (%d): %s (custom message, lang: %s) - %s", method, path, statusCode, message, lang, errMsg)
	case statusCode >= 400:
		logger.Warn("[%s] %s - Error (%d): %s (custom message, lang: %s) - %s", method, path, statusCode, message, lang, errMsg)
	default:
		logger.Info("[%s] %s - Error (%d): %s (custom message, lang: %s) - %s", method, path, statusCode, message, lang, errMsg)
	}

	c.JSON(statusCode, resp)
}

// I18nSuccessResponse is an alias for SuccessResponse for backward compatibility
var I18nSuccessResponse = SuccessResponse

// I18nErrorResponse is an alias for ErrorResponse for backward compatibility
var I18nErrorResponse = ErrorResponse
