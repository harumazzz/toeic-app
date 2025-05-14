package api

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

type refreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

type refreshTokenResponse struct {
	AccessToken string       `json:"access_token"`
	User        UserResponse `json:"user"`
}

// @Summary     Refresh access token
// @Description Get a new access token using a refresh token
// @Tags        auth
// @Accept      json
// @Produce     json
// @Param       refresh_token body refreshTokenRequest true "Refresh token"
// @Success     200 {object} Response{data=refreshTokenResponse} "Token refreshed successfully"
// @Failure     400 {object} Response "Invalid request"
// @Failure     401 {object} Response "Invalid refresh token"
// @Failure     500 {object} Response "Server error"
// @Router      /api/refresh-token [post]
func (server *Server) refreshToken(ctx *gin.Context) {
	var req refreshTokenRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request parameters", err)
		return
	}

	// Verify refresh token
	payload, err := server.tokenMaker.VerifyToken(req.RefreshToken)
	if err != nil {
		ErrorResponse(ctx, http.StatusUnauthorized, "Invalid refresh token", err)
		return
	}

	// Get user from database to ensure they still exist and are active
	user, err := server.store.GetUser(ctx, payload.ID)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to find user", err)
		return
	}

	// Generate new access token
	accessToken, err := server.tokenMaker.CreateToken(
		user.ID,
		user.Username,
		time.Duration(server.config.AccessTokenDuration)*time.Second,
	)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create access token", err)
		return
	}

	userResp := UserResponse{
		ID:        user.ID,
		Username:  user.Username,
		Email:     user.Email,
		CreatedAt: user.CreatedAt.Format(time.RFC3339),
	}

	response := refreshTokenResponse{
		AccessToken: accessToken,
		User:        userResp,
	}

	SuccessResponse(ctx, http.StatusOK, "Token refreshed successfully", response)
}
