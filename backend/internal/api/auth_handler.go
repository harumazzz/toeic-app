package api

import (
	"database/sql"
	"errors"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	db "github.com/toeic-app/internal/db/sqlc"
	"github.com/toeic-app/internal/logger"
	"github.com/toeic-app/internal/token"
	"github.com/toeic-app/internal/util"
)

// loginUserRequest defines the structure for user login requests.
// It includes email and password, both of which are required.
type loginUserRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required,min=6"`
}

// loginUserResponse defines the structure for user login responses.
// It includes user details, access token, and refresh token.
type loginUserResponse struct {
	User         UserResponse `json:"user"`
	AccessToken  string       `json:"access_token"`
	RefreshToken string       `json:"refresh_token"`
}

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

	user, err := server.store.GetUserByEmail(ctx, req.Email)
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusUnauthorized, "Invalid email or password", nil)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to find user", err)
		return
	}

	err = util.CheckPassword(req.Password, user.PasswordHash)
	if err != nil {
		ErrorResponse(ctx, http.StatusUnauthorized, "Invalid email or password", nil)
		return
	}

	accessToken, err := server.tokenMaker.CreateToken(
		user.ID,
		user.Username,
		time.Duration(server.config.AccessTokenDuration)*time.Second,
	)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create access token", err)
		return
	}

	refreshToken, err := server.tokenMaker.CreateToken(
		user.ID,
		user.Username,
		time.Duration(server.config.RefreshTokenDuration)*time.Second,
	)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create refresh token", err)
		return
	}

	userResp := NewUserResponse(user)

	response := loginUserResponse{
		User:         userResp,
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	}

	SuccessResponse(ctx, http.StatusOK, "Login successful", response)
}

// registerUserRequest defines the structure for user registration requests.
// It includes username, email, and password, all of which are required and validated.
type registerUserRequest struct {
	Username string `json:"username" binding:"required,min=3,max=50"`
	Email    string `json:"email" binding:"required,valid_email"`
	Password string `json:"password" binding:"required,min=8,strong_password"`
}

// registerUserResponse defines the structure for user registration responses.
// It includes user details, access token, and refresh token.
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

	if !util.IsValidEmail(req.Email) {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid email format", nil)
		return
	}

	if !util.IsStrongPassword(req.Password) {
		ErrorResponse(ctx, http.StatusBadRequest, "Password doesn't meet security requirements. It must have at least 8 characters including uppercase, lowercase, numbers and special characters", nil)
		return
	}

	_, err := server.store.GetUserByEmail(ctx, req.Email)
	if err == nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Email already registered", nil)
		return
	}

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

	accessToken, err := server.tokenMaker.CreateToken(
		user.ID,
		user.Username,
		time.Duration(server.config.AccessTokenDuration)*time.Second,
	)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create access token", err)
		return
	}

	refreshToken, err := server.tokenMaker.CreateToken(
		user.ID,
		user.Username,
		time.Duration(server.config.RefreshTokenDuration)*time.Second,
	)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create refresh token", err)
		return
	}

	userResp := NewUserResponse(user)

	response := registerUserResponse{
		User:         userResp,
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	}

	SuccessResponse(ctx, http.StatusCreated, "User registered successfully", response)
}

// refreshTokenRequest defines the structure for refresh token requests.
// It includes the refresh token, which is required.
type refreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

// refreshTokenResponse defines the structure for refresh token responses.
// It includes the new access token and user details.
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

	payload, err := server.tokenMaker.VerifyToken(req.RefreshToken)
	if err != nil {
		ErrorResponse(ctx, http.StatusUnauthorized, "Invalid refresh token", err)
		return
	}

	user, err := server.store.GetUser(ctx, payload.ID)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to find user", err)
		return
	}

	accessToken, err := server.tokenMaker.CreateToken(
		user.ID,
		user.Username,
		time.Duration(server.config.AccessTokenDuration)*time.Second,
	)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create access token", err)
		return
	}

	userResp := NewUserResponse(user)

	response := refreshTokenResponse{
		AccessToken: accessToken,
		User:        userResp,
	}

	SuccessResponse(ctx, http.StatusOK, "Token refreshed successfully", response)
}

// authMiddleware is a Gin middleware for JWT authentication
func (server *Server) authMiddleware() gin.HandlerFunc {
	return func(ctx *gin.Context) {
		path := ctx.Request.URL.Path
		method := ctx.Request.Method
		logger.Debug("Auth middleware checking: %s %s", method, path)

		authorizationHeader := ctx.GetHeader(AuthorizationHeaderKey)

		if len(authorizationHeader) == 0 {
			err := errors.New("authorization header is not provided")
			logger.Warn("Auth failed - no header: %s %s", method, path)
			ErrorResponse(ctx, http.StatusUnauthorized, "Unauthorized", err)
			ctx.Abort()
			return
		}

		fields := strings.Fields(authorizationHeader)
		if len(fields) < 2 {
			err := errors.New("invalid authorization header format")
			logger.Warn("Auth failed - invalid format: %s %s", method, path)
			ErrorResponse(ctx, http.StatusUnauthorized, "Unauthorized", err)
			ctx.Abort()
			return
		}

		authorizationType := strings.ToLower(fields[0])
		if authorizationType != AuthorizationTypeBearer {
			err := errors.New("unsupported authorization type")
			logger.Warn("Auth failed - unsupported type: %s %s - got %s", method, path, authorizationType)
			ErrorResponse(ctx, http.StatusUnauthorized, "Unauthorized", err)
			ctx.Abort()
			return
		}

		accessToken := fields[1]
		payload, err := server.tokenMaker.VerifyToken(accessToken)
		if err != nil {
			logger.Warn("Auth failed - invalid token: %s %s - %v", method, path, err)
			ErrorResponse(ctx, http.StatusUnauthorized, "Unauthorized", err)
			ctx.Abort()
			return
		}
		ctx.Set(AuthorizationPayloadKey, payload)
		logger.Debug("Auth successful - user ID: %d - %s %s", payload.ID, method, path)
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
