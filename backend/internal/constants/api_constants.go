package constants

import (
	"github.com/gin-gonic/gin"
)

// AuthorizationHeaderKey is the key of the authorization header
const AuthorizationHeaderKey = "Authorization"

// AuthorizationTypeBearer is the type of authorization
const AuthorizationTypeBearer = "bearer"

// AuthorizationPayloadKey is the key to store/retrieve the authorization payload in the context
const AuthorizationPayloadKey = "authorization_payload"

// ErrorResponseFunc represents a standardized error response function
type ErrorResponseFunc func(ctx *gin.Context, statusCode int, message string, err error)

// SuccessResponseFunc represents a standardized success response function
type SuccessResponseFunc func(ctx *gin.Context, statusCode int, message string, data interface{})
