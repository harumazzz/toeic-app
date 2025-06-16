package api

import (
	"crypto/hmac"
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"errors"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	db "github.com/toeic-app/internal/db/sqlc"
	apperrors "github.com/toeic-app/internal/errors"
	"github.com/toeic-app/internal/logger"
	"github.com/toeic-app/internal/token"
	"github.com/toeic-app/internal/util"
)

// UserResponse defines the structure for user information returned to clients.
// It excludes sensitive data like the password hash.
type UserResponse struct {
	ID        int32  `json:"id"`
	Username  string `json:"username"`
	Email     string `json:"email"`
	CreatedAt string `json:"created_at" example:"2025-05-01T13:45:00Z" format:"date-time"`
}

// NewUserResponse creates a UserResponse from a user model
func NewUserResponse(user db.User) UserResponse {
	return UserResponse{
		ID:        user.ID,
		Username:  user.Username,
		Email:     user.Email,
		CreatedAt: user.CreatedAt.Format(time.RFC3339),
	}
}

// loginUserRequest defines the structure for user login requests.
// It includes email and password, both of which are required.
type loginUserRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required,min=6"`
}

// loginUserResponse defines the structure for user login responses.
// It includes user details, access token, refresh token, and security configuration.
type loginUserResponse struct {
	User           UserResponse   `json:"user"`
	AccessToken    string         `json:"access_token"`
	RefreshToken   string         `json:"refresh_token"`
	SecurityConfig SecurityConfig `json:"security_config"`
}

// SecurityConfig defines the security configuration sent to the client
type SecurityConfig struct {
	SecretKey        string   `json:"secret_key"`         // Client-side security secret
	SecurityLevel    int      `json:"security_level"`     // Required security level
	WasmEnabled      bool     `json:"wasm_enabled"`       // WASM support enabled
	WebWorkerEnabled bool     `json:"web_worker_enabled"` // Web worker support enabled
	RequiredHeaders  []string `json:"required_headers"`   // List of required headers
	MaxTimestampAge  int      `json:"max_timestamp_age"`  // Maximum timestamp age in seconds
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
// @Router      /api/auth/login [post]
func (server *Server) loginUser(ctx *gin.Context) {
	var req loginUserRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		// Use improved error handling for validation errors
		appErr := apperrors.NewValidationError("Invalid request parameters")
		appErr.AddFieldError("request_body", "Invalid JSON format or missing required fields")
		appErr.WithRequestPath(ctx.Request.URL.Path)
		if traceID := ctx.GetHeader("X-Trace-ID"); traceID != "" {
			appErr.WithTraceID(traceID)
		}
		ctx.Error(appErr) // Add to Gin's error context for middleware processing
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request parameters", appErr)
		return
	}

	user, err := server.store.GetUserByEmail(ctx, req.Email)
	if err != nil {
		if err == sql.ErrNoRows {
			// Use specific error code for authentication failures
			appErr := apperrors.FromGinContext(ctx, apperrors.ErrCodeInvalidCredentials, "Invalid email or password")
			appErr.WithMetadata("attempted_email", req.Email)
			ctx.Error(appErr)
			ErrorResponse(ctx, http.StatusUnauthorized, "Invalid email or password", appErr)
			return
		}
		// Handle database errors properly
		appErr := apperrors.HandleDatabaseError(err)
		appErr.WithRequestPath(ctx.Request.URL.Path)
		appErr.WithMetadata("operation", "get_user_by_email")
		ctx.Error(appErr)
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to find user", appErr)
		return
	}

	err = util.CheckPassword(req.Password, user.PasswordHash)
	if err != nil {
		// Use specific error code for authentication failures
		appErr := apperrors.FromGinContext(ctx, apperrors.ErrCodeInvalidCredentials, "Invalid email or password")
		appErr.WithUserID(user.ID)
		appErr.WithMetadata("user_email", user.Email)
		ctx.Error(appErr)
		ErrorResponse(ctx, http.StatusUnauthorized, "Invalid email or password", appErr)
		return
	}

	accessToken, err := server.tokenMaker.CreateToken(
		user.ID,
		user.Username,
		time.Duration(server.config.AccessTokenDuration)*time.Second,
	)
	if err != nil {
		appErr := apperrors.Wrap(err, apperrors.ErrCodeInternalServer, "Failed to create access token")
		appErr.WithUserID(user.ID)
		appErr.WithRequestPath(ctx.Request.URL.Path)
		appErr.WithMetadata("token_type", "access_token")
		ctx.Error(appErr)
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create access token", appErr)
		return
	}

	refreshToken, err := server.tokenMaker.CreateToken(
		user.ID,
		user.Username,
		time.Duration(server.config.RefreshTokenDuration)*time.Second,
	)
	if err != nil {
		appErr := apperrors.Wrap(err, apperrors.ErrCodeInternalServer, "Failed to create refresh token")
		appErr.WithUserID(user.ID)
		appErr.WithRequestPath(ctx.Request.URL.Path)
		appErr.WithMetadata("token_type", "refresh_token")
		ctx.Error(appErr)
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create refresh token", appErr)
		return
	}
	userResp := NewUserResponse(user)

	// Generate client-side security configuration
	securityConfig := SecurityConfig{
		SecretKey:        server.generateClientSecurityKey(user.ID),
		SecurityLevel:    2, // Standard security level
		WasmEnabled:      true,
		WebWorkerEnabled: true,
		RequiredHeaders: []string{
			"X-Security-Token",
			"X-Client-Signature",
			"X-Request-Timestamp",
			"X-Origin-Validation",
		},
		MaxTimestampAge: 300, // 5 minutes
	}

	response := loginUserResponse{
		User:           userResp,
		AccessToken:    accessToken,
		RefreshToken:   refreshToken,
		SecurityConfig: securityConfig,
	}

	SuccessResponse(ctx, http.StatusOK, "Login successful", response)
}

// registerUserRequest defines the structure for user registration requests.
// It includes username, email, and password, all of which are required and validated.
type registerUserRequest struct {
	Username string `json:"username" binding:"required,min=3,max=50"`
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required,min=8,strong_password"`
}

// registerUserResponse defines the structure for user registration responses.
// It includes user details, access token, refresh token, and security configuration.
type registerUserResponse struct {
	User           UserResponse   `json:"user"`
	AccessToken    string         `json:"access_token"`
	RefreshToken   string         `json:"refresh_token"`
	SecurityConfig SecurityConfig `json:"security_config"`
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
// @Router      /api/auth/register [post]
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

	// Generate client-side security configuration
	securityConfig := SecurityConfig{
		SecretKey:        server.generateClientSecurityKey(user.ID),
		SecurityLevel:    2, // Standard security level
		WasmEnabled:      true,
		WebWorkerEnabled: true,
		RequiredHeaders: []string{
			"X-Security-Token",
			"X-Client-Signature",
			"X-Request-Timestamp",
			"X-Origin-Validation",
		},
		MaxTimestampAge: 300, // 5 minutes
	}

	response := registerUserResponse{
		User:           userResp,
		AccessToken:    accessToken,
		RefreshToken:   refreshToken,
		SecurityConfig: securityConfig,
	}

	SuccessResponse(ctx, http.StatusCreated, "User registered successfully", response)
}

// refreshTokenRequest defines the structure for refresh token requests.
// It includes the refresh token, which is required.
type refreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

// refreshTokenResponse defines the structure for refresh token responses.
// It includes the new access token, refresh token, and user details.
type refreshTokenResponse struct {
	AccessToken  string       `json:"access_token"`
	RefreshToken string       `json:"refresh_token"`
	User         UserResponse `json:"user"`
}

// logoutRequest defines the structure for logout requests.
// It includes the refresh token, which is optional.
type logoutRequest struct {
	RefreshToken string `json:"refresh_token"`
}

// @Summary     Logout user
// @Description Logout a user by invalidating their access and refresh tokens
// @Tags        auth
// @Accept      json
// @Produce     json
// @Param       logout body logoutRequest false "Logout request with optional refresh token"
// @Success     200 {object} Response "Logout successful"
// @Failure     401 {object} Response "Unauthorized if the user is not authenticated"
// @Failure     500 {object} Response "Server error"
// @Security    ApiKeyAuth
// @Router      /api/auth/logout [post]
func (server *Server) logoutUser(ctx *gin.Context) {
	// Extract auth header
	authorizationHeader := ctx.GetHeader(AuthorizationHeaderKey)
	if len(authorizationHeader) == 0 {
		ErrorResponse(ctx, http.StatusUnauthorized, "Authorization header is not provided", nil)
		return
	}

	fields := strings.Fields(authorizationHeader)
	if len(fields) < 2 {
		ErrorResponse(ctx, http.StatusUnauthorized, "Invalid authorization header format", nil)
		return
	}

	authorizationType := strings.ToLower(fields[0])
	if authorizationType != AuthorizationTypeBearer {
		ErrorResponse(ctx, http.StatusUnauthorized, "Unsupported authorization type", nil)
		return
	}

	accessToken := fields[1]

	// Blacklist the access token
	err := server.tokenMaker.BlacklistToken(accessToken)
	if err != nil {
		// Don't return an error if the token is already invalid or expired
		if err != token.ErrExpiredToken {
			ErrorResponse(ctx, http.StatusInternalServerError, "Failed to invalidate access token", err)
			return
		}
		logger.Debug("Access token already expired during logout")
	}

	// Check if there's a refresh token in the request body
	var req logoutRequest
	if err := ctx.ShouldBindJSON(&req); err == nil && req.RefreshToken != "" {
		// If refresh token exists, blacklist it too
		err = server.tokenMaker.BlacklistToken(req.RefreshToken)
		if err != nil {
			if err != token.ErrExpiredToken {
				logger.Warn("Failed to blacklist refresh token: %v", err)
			} else {
				logger.Debug("Refresh token already expired during logout")
			}
		}
	}

	SuccessResponse(ctx, http.StatusOK, "Logout successful", nil)
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
// @Router      /api/auth/refresh-token [post]
func (server *Server) refreshToken(ctx *gin.Context) {
	var req refreshTokenRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		// Handle EOF and other binding errors more gracefully
		if err.Error() == "EOF" {
			ErrorResponse(ctx, http.StatusBadRequest, "Empty request body - refresh token is required", nil)
		} else {
			ErrorResponse(ctx, http.StatusBadRequest, "Invalid request format - please provide refresh_token in JSON body", err)
		}
		return
	}

	// Validate that refresh token is not empty
	if req.RefreshToken == "" {
		ErrorResponse(ctx, http.StatusBadRequest, "Refresh token cannot be empty", nil)
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

	// Create new access token
	accessToken, err := server.tokenMaker.CreateToken(
		user.ID,
		user.Username,
		time.Duration(server.config.AccessTokenDuration)*time.Second,
	)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create access token", err)
		return
	}

	// Create new refresh token
	newRefreshToken, err := server.tokenMaker.CreateToken(
		user.ID,
		user.Username,
		time.Duration(server.config.RefreshTokenDuration)*time.Second,
	)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to create refresh token", err)
		return
	}

	userResp := NewUserResponse(user)

	response := refreshTokenResponse{
		AccessToken:  accessToken,
		RefreshToken: newRefreshToken,
		User:         userResp,
	}

	SuccessResponse(ctx, http.StatusOK, "Token refreshed successfully", response)
}

// authMiddleware is a Gin middleware for JWT authentication
func (server *Server) authMiddleware() gin.HandlerFunc {
	return func(ctx *gin.Context) {
		path := ctx.Request.URL.Path
		method := ctx.Request.Method

		// Create base log fields
		fields := logger.Fields{
			"component":  "auth_middleware",
			"method":     method,
			"path":       path,
			"client_ip":  ctx.ClientIP(),
			"user_agent": ctx.GetHeader("User-Agent"),
			"request_id": ctx.GetHeader("X-Request-ID"),
		}

		logger.DebugWithFields(fields, "Auth middleware checking request")

		authorizationHeader := ctx.GetHeader(AuthorizationHeaderKey)

		if len(authorizationHeader) == 0 {
			err := errors.New("authorization header is not provided")
			fields["error"] = "missing_auth_header"
			logger.WarnWithFields(fields, "Auth failed - no header")
			ErrorResponse(ctx, http.StatusUnauthorized, "Unauthorized", err)
			ctx.Abort()
			return
		}

		fields["has_auth_header"] = true
		fieldsArray := strings.Fields(authorizationHeader)
		if len(fieldsArray) < 2 {
			err := errors.New("invalid authorization header format")
			fields["error"] = "invalid_auth_format"
			fields["header_parts"] = len(fieldsArray)
			logger.WarnWithFields(fields, "Auth failed - invalid format")
			ErrorResponse(ctx, http.StatusUnauthorized, "Unauthorized", err)
			ctx.Abort()
			return
		}

		authorizationType := strings.ToLower(fieldsArray[0])
		fields["auth_type"] = authorizationType

		if authorizationType != AuthorizationTypeBearer {
			err := errors.New("unsupported authorization type")
			fields["error"] = "unsupported_auth_type"
			logger.WarnWithFields(fields, "Auth failed - unsupported type")
			ErrorResponse(ctx, http.StatusUnauthorized, "Unauthorized", err)
			ctx.Abort()
			return
		}

		accessToken := fieldsArray[1]
		fields["token_length"] = len(accessToken)

		payload, err := server.tokenMaker.VerifyToken(accessToken)
		if err != nil {
			fields["error"] = "invalid_token"
			fields["token_error"] = err.Error()
			logger.WarnWithFields(fields, "Auth failed - invalid token")
			ErrorResponse(ctx, http.StatusUnauthorized, "Unauthorized", err)
			ctx.Abort()
			return
		}

		ctx.Set(AuthorizationPayloadKey, payload)
		fields["user_id"] = payload.ID
		fields["token_valid"] = true
		logger.DebugWithFields(fields, "Auth successful")
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

// generateClientSecurityKey generates a unique security key for the client
func (server *Server) generateClientSecurityKey(userID int32) string {
	// Generate deterministic key based on server secret and user ID (no timestamp)
	// This allows the middleware to recreate the same key later
	message := fmt.Sprintf("%s_user_%d", server.config.TokenSymmetricKey, userID)

	// Generate HMAC-SHA256 hash
	h := hmac.New(sha256.New, []byte(server.config.TokenSymmetricKey))
	h.Write([]byte(message))
	hash := h.Sum(nil)

	// Return first 32 bytes as hex string (256 bits)
	return hex.EncodeToString(hash)[:64]
}
