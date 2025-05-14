package api

import (
	"database/sql"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/toeic-app/internal/util"
)

// @Summary     Login user
// @Description Authenticate a user and return a JWT token
// @Tags        auth
// @Accept      json
// @Produce     json
// @Param       login body loginUserRequest true "Login credentials"
// @Success     200 {object} Response{data=loginUserResponse} "Login successful"
// @Failure     400 {object} Response "Invalid request"
// @Failure     401 {object} Response "Authentication failed"
// @Failure     500 {object} Response "Server error"
// @Router      /api/login [post]
func (server *Server) loginUser(ctx *gin.Context) {
	var req loginUserRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request parameters", err)
		return
	}

	// Get user by email
	user, err := server.store.GetUserByEmail(ctx, req.Email)
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusUnauthorized, "Invalid email or password", nil)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to find user", err)
		return
	}

	// Check password
	err = util.CheckPassword(req.Password, user.PasswordHash)
	if err != nil {
		ErrorResponse(ctx, http.StatusUnauthorized, "Invalid email or password", nil)
		return
	}
	// Generate access token
	accessToken, err := server.tokenMaker.CreateToken(
		user.ID,
		user.Username,
		time.Duration(server.config.AccessTokenDuration)*time.Second,
	)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create access token", err)
		return
	}

	// Generate refresh token with longer duration
	refreshToken, err := server.tokenMaker.CreateToken(
		user.ID,
		user.Username,
		time.Duration(server.config.RefreshTokenDuration)*time.Second,
	)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create refresh token", err)
		return
	}

	userResp := UserResponse{
		ID:        user.ID,
		Username:  user.Username,
		Email:     user.Email,
		CreatedAt: user.CreatedAt.Format(time.RFC3339),
	}

	response := loginUserResponse{
		User:         userResp,
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	}

	SuccessResponse(ctx, http.StatusOK, "Login successful", response)
}
