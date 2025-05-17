package api

import (
	"github.com/gin-gonic/gin"
	"github.com/toeic-app/internal/logger"
)

// Response is a standardized API response structure
type Response struct {
	Status  string `json:"status"`
	Message string `json:"message,omitempty"`
	Data    any    `json:"data,omitempty"`
	Error   string `json:"error,omitempty"`
}

// SuccessResponse returns a standard success response
func SuccessResponse(c *gin.Context, statusCode int, message string, data interface{}) {
	path := c.Request.URL.Path
	method := c.Request.Method

	resp := Response{
		Status:  "success",
		Message: message,
		Data:    data,
	}

	// Log successful response
	logger.Debug("[%s] %s - Success (%d): %s", method, path, statusCode, message)

	c.JSON(statusCode, resp)
}

// ErrorResponse returns a standard error response
func ErrorResponse(c *gin.Context, statusCode int, message string, err error) {
	path := c.Request.URL.Path
	method := c.Request.Method

	errMsg := ""
	if err != nil {
		errMsg = err.Error()
	}

	resp := Response{
		Status:  "error",
		Message: message,
		Error:   errMsg,
	}

	// Log error response with appropriate level based on status code
	switch {
	case statusCode >= 500:
		logger.Error("[%s] %s - Error (%d): %s - %s", method, path, statusCode, message, errMsg)
	case statusCode >= 400:
		logger.Warn("[%s] %s - Error (%d): %s - %s", method, path, statusCode, message, errMsg)
	default:
		logger.Info("[%s] %s - Error (%d): %s - %s", method, path, statusCode, message, errMsg)
	}

	c.JSON(statusCode, resp)
}
