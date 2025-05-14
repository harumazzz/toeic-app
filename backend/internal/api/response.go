package api

import "github.com/gin-gonic/gin"

// Response is a standardized API response structure
type Response struct {
	Status  string `json:"status"`
	Message string `json:"message,omitempty"`
	Data    any    `json:"data,omitempty"`
	Error   string `json:"error,omitempty"`
}

// SuccessResponse returns a standard success response
func SuccessResponse(c *gin.Context, statusCode int, message string, data interface{}) {
	resp := Response{
		Status:  "success",
		Message: message,
		Data:    data,
	}
	c.JSON(statusCode, resp)
}

// ErrorResponse returns a standard error response
func ErrorResponse(c *gin.Context, statusCode int, message string, err error) {
	errMsg := ""
	if err != nil {
		errMsg = err.Error()
	}

	resp := Response{
		Status:  "error",
		Message: message,
		Error:   errMsg,
	}
	c.JSON(statusCode, resp)
}
