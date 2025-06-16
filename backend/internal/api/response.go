package api

import (
	"fmt"

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

	// Create structured log fields
	fields := logger.Fields{
		"component":          "api_response",
		"method":             method,
		"path":               path,
		"status_code":        statusCode,
		"message_key":        messageKey,
		"translated_message": translatedMessage,
		"language":           string(lang),
		"client_ip":          c.ClientIP(),
		"user_agent":         c.GetHeader("User-Agent"),
		"request_id":         c.GetHeader("X-Request-ID"),
		"has_data":           data != nil,
	}

	// Add user information if available
	if payload, exists := c.Get("authorization_payload"); exists && payload != nil {
		if userPayload, ok := payload.(interface{ GetID() int32 }); ok {
			fields["user_id"] = userPayload.GetID()
		}
	}

	// Log successful response
	message := fmt.Sprintf("API Success Response: %s", translatedMessage)
	logger.InfoWithFields(fields, "%s", message)

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

	// Create structured log fields
	fields := logger.Fields{
		"component":      "api_response",
		"method":         method,
		"path":           path,
		"status_code":    statusCode,
		"custom_message": message,
		"language":       string(lang),
		"client_ip":      c.ClientIP(),
		"user_agent":     c.GetHeader("User-Agent"),
		"request_id":     c.GetHeader("X-Request-ID"),
		"has_data":       data != nil,
	}

	// Add user information if available
	if payload, exists := c.Get("authorization_payload"); exists && payload != nil {
		if userPayload, ok := payload.(interface{ GetID() int32 }); ok {
			fields["user_id"] = userPayload.GetID()
		}
	}

	// Log successful response
	logMessage := fmt.Sprintf("API Success Response: %s", message)
	logger.InfoWithFields(fields, "%s", logMessage)
	c.JSON(statusCode, resp)
}
