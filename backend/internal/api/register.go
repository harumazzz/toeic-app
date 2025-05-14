package api

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	db "github.com/toeic-app/internal/db/sqlc"
	"github.com/toeic-app/internal/util"
)

type registerUserRequest struct {
	Username string `json:"username" binding:"required,min=3,max=50"`
	Email    string `json:"email" binding:"required,valid_email"`
	Password string `json:"password" binding:"required,min=8,strong_password"`
}

type registerUserResponse struct {
	User         UserResponse `json:"user"`
	AccessToken  string       `json:"access_token"`
	RefreshToken string       `json:"refresh_token"`
}

// @Summary     Register a new user
// @Description Register a new user and return authentication tokens
// @Tags        auth
// @Accept      json
// @Produce     json
// @Param       register body registerUserRequest true "Registration information"
// @Success     201 {object} Response{data=registerUserResponse} "User registered successfully"
// @Failure     400 {object} Response "Invalid request"
// @Failure     500 {object} Response "Server error"
// @Router      /api/register [post]
func (server *Server) registerUser(ctx *gin.Context) {
	var req registerUserRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request parameters", err)
		return
	}

	// Validate email format
	if !util.IsValidEmail(req.Email) {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid email format", nil)
		return
	}

	// Validate password strength
	if !util.IsStrongPassword(req.Password) {
		ErrorResponse(ctx, http.StatusBadRequest, "Password doesn't meet security requirements. It must have at least 8 characters including uppercase, lowercase, numbers and special characters", nil)
		return
	}

	// Check if email already exists
	_, err := server.store.GetUserByEmail(ctx, req.Email)
	if err == nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Email already registered", nil)
		return
	}

	// Hash the password
	hashedPassword, err := util.HashPassword(req.Password)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to process password", err)
		return
	}

	arg := db.CreateUserParams{
		Username:     req.Username,
		Email:        req.Email,
		PasswordHash: hashedPassword,
	}

	user, err := server.store.CreateUser(ctx, arg)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create user", err)
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

	// Generate refresh token
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

	response := registerUserResponse{
		User:         userResp,
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	}

	SuccessResponse(ctx, http.StatusCreated, "User registered successfully", response)
}
