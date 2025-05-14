package api

import (
	"errors"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/toeic-app/internal/token"
)

// Using constants from constants.go

// authMiddleware is a Gin middleware for JWT authentication
func (server *Server) authMiddleware() gin.HandlerFunc {
	return func(ctx *gin.Context) {
		authorizationHeader := ctx.GetHeader(AuthorizationHeaderKey)

		if len(authorizationHeader) == 0 {
			err := errors.New("authorization header is not provided")
			ErrorResponse(ctx, http.StatusUnauthorized, "Unauthorized", err)
			ctx.Abort()
			return
		}

		fields := strings.Fields(authorizationHeader)
		if len(fields) < 2 {
			err := errors.New("invalid authorization header format")
			ErrorResponse(ctx, http.StatusUnauthorized, "Unauthorized", err)
			ctx.Abort()
			return
		}

		authorizationType := strings.ToLower(fields[0])
		if authorizationType != AuthorizationTypeBearer {
			err := errors.New("unsupported authorization type")
			ErrorResponse(ctx, http.StatusUnauthorized, "Unauthorized", err)
			ctx.Abort()
			return
		}

		accessToken := fields[1]
		payload, err := server.tokenMaker.VerifyToken(accessToken)
		if err != nil {
			ErrorResponse(ctx, http.StatusUnauthorized, "Unauthorized", err)
			ctx.Abort()
			return
		}

		ctx.Set(AuthorizationPayloadKey, payload)
		ctx.Next()
	}
}

// GetAuthPayload extracts the token payload from the request context
func (server *Server) GetAuthPayload(ctx *gin.Context) (*token.Payload, error) {
	payload, exists := ctx.Get(AuthorizationPayloadKey)
	if !exists {
		return nil, errors.New("authorization payload not found")
	}

	authPayload, ok := payload.(*token.Payload)
	if !ok {
		return nil, errors.New("invalid authorization payload")
	}

	return authPayload, nil
}
