package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/toeic-app/internal/token"
)

// @Summary     Get current user profile
// @Description Get authenticated user's profile
// @Tags        users
// @Accept      json
// @Produce     json
// @Success     200 {object} Response{data=db.User} "User profile retrieved successfully"
// @Failure     401 {object} Response "Unauthorized"
// @Failure     500 {object} Response "Server error"
// @Security    ApiKeyAuth
// @Router      /api/v1/users/me [get]
func (server *Server) getCurrentUser(ctx *gin.Context) {
	payload, _ := ctx.Get(AuthorizationPayloadKey)
	authPayload, ok := payload.(*token.Payload)
	if !ok {
		ErrorResponse(ctx, http.StatusInternalServerError, "Cannot get user information", nil)
		return
	}

	user, err := server.store.GetUser(ctx, authPayload.ID)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve user profile", err)
		return
	}

	SuccessResponse(ctx, http.StatusOK, "User profile retrieved successfully", user)
}
