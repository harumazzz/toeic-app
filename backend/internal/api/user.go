package api

import (
	"database/sql"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	db "github.com/toeic-app/internal/db/sqlc"
	"github.com/toeic-app/internal/util"
)

type createUserRequest struct {
	Username string `json:"username" binding:"required,min=3,max=50"`
	Email    string `json:"email" binding:"required,valid_email"`
	Password string `json:"password" binding:"required,min=8,strong_password"`
}

type loginUserRequest struct {
	Email    string `json:"email" binding:"required,valid_email"`
	Password string `json:"password" binding:"required,min=6"`
}

// UserResponse is the safe user information to return to clients
type UserResponse struct {
	ID       int32  `json:"id"`
	Username string `json:"username"`
	Email    string `json:"email"`
	// Using string to represent time; Swagger can handle this better
	CreatedAt string `json:"created_at" example:"2025-05-01T13:45:00Z" format:"date-time"`
}

type loginUserResponse struct {
	User         UserResponse `json:"user"`
	AccessToken  string       `json:"access_token"`
	RefreshToken string       `json:"refresh_token"`
}

// @Summary     Create a new user
// @Description Create a new user in the system
// @Tags        users
// @Accept      json
// @Produce     json
// @Param       user body createUserRequest true "User information"
// @Success     201 {object} Response{data=db.User} "User created successfully"
// @Failure     400 {object} Response "Invalid request"
// @Failure     500 {object} Response "Server error"
// @Router      /api/users [post]
func (server *Server) createUser(ctx *gin.Context) {
	var req createUserRequest
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

	SuccessResponse(ctx, http.StatusCreated, "User created successfully", user)
}

// @Summary     Get a user
// @Description Get user by ID
// @Tags        users
// @Accept      json
// @Produce     json
// @Param       id path int true "User ID"
// @Success     200 {object} Response{data=db.User} "User retrieved successfully"
// @Failure     400 {object} Response "Invalid request"
// @Failure     404 {object} Response "User not found"
// @Failure     500 {object} Response "Server error"
// @Security    ApiKeyAuth
// @Router      /api/users/{id} [get]
func (server *Server) getUser(ctx *gin.Context) {
	id, err := strconv.ParseInt(ctx.Param("id"), 10, 64)
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid user ID format", err)
		return
	}

	user, err := server.store.GetUser(ctx, int32(id))
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "User not found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve user", err)
		return
	}

	SuccessResponse(ctx, http.StatusOK, "User retrieved successfully", user)
}

type listUsersRequest struct {
	Limit  int32 `form:"limit" binding:"required,min=1,max=100"`
	Offset int32 `form:"offset" binding:"min=0"`
}

// @Summary     List users
// @Description Get a list of users with pagination
// @Tags        users
// @Accept      json
// @Produce     json
// @Param       limit query int true "Limit" minimum(1) maximum(100) default(10)
// @Param       offset query int false "Offset" minimum(0) default(0)
// @Success     200 {object} Response{data=[]db.User} "Users retrieved successfully"
// @Failure     400 {object} Response "Invalid request"
// @Failure     500 {object} Response "Server error"
// @Security    ApiKeyAuth
// @Router      /api/users [get]
func (server *Server) listUsers(ctx *gin.Context) {
	var req listUsersRequest
	if err := ctx.ShouldBindQuery(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid query parameters", err)
		return
	}

	arg := db.ListUsersParams{
		Limit:  req.Limit,
		Offset: req.Offset,
	}

	users, err := server.store.ListUsers(ctx, arg)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve users", err)
		return
	}

	SuccessResponse(ctx, http.StatusOK, "Users retrieved successfully", users)
}

type updateUserRequest struct {
	Username     string `json:"username" binding:"omitempty,min=3"`
	Email        string `json:"email" binding:"omitempty,email"`
	PasswordHash string `json:"password_hash" binding:"omitempty,min=6"`
}

// @Summary     Update a user
// @Description Update user information by ID
// @Tags        users
// @Accept      json
// @Produce     json
// @Param       id path int true "User ID"
// @Param       user body updateUserRequest true "User information to update"
// @Success     200 {object} Response{data=db.User} "User updated successfully"
// @Failure     400 {object} Response "Invalid request"
// @Failure     404 {object} Response "User not found"
// @Failure     500 {object} Response "Server error"
// @Security    ApiKeyAuth
// @Router      /api/users/{id} [put]
func (server *Server) updateUser(ctx *gin.Context) {
	id, err := strconv.ParseInt(ctx.Param("id"), 10, 64)
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid user ID format", err)
		return
	}

	var req updateUserRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid request parameters", err)
		return
	}

	// Get existing user first
	currentUser, err := server.store.GetUser(ctx, int32(id))
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "User not found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve user", err)
		return
	}

	// Update fields only if provided in request
	username := currentUser.Username
	if req.Username != "" {
		username = req.Username
	}

	email := currentUser.Email
	if req.Email != "" {
		email = req.Email
	}

	passwordHash := currentUser.PasswordHash
	if req.PasswordHash != "" {
		passwordHash = req.PasswordHash
	}

	arg := db.UpdateUserParams{
		ID:           int32(id),
		Username:     username,
		Email:        email,
		PasswordHash: passwordHash,
	}
	user, err := server.store.UpdateUser(ctx, arg)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to update user", err)
		return
	}

	SuccessResponse(ctx, http.StatusOK, "User updated successfully", user)
}

// @Summary     Delete a user
// @Description Delete user by ID
// @Tags        users
// @Accept      json
// @Produce     json
// @Param       id path int true "User ID"
// @Success     200 {object} Response "User deleted successfully"
// @Failure     400 {object} Response "Invalid request"
// @Failure     404 {object} Response "User not found"
// @Failure     500 {object} Response "Server error"
// @Security    ApiKeyAuth
// @Router      /api/users/{id} [delete]
func (server *Server) deleteUser(ctx *gin.Context) {
	id, err := strconv.ParseInt(ctx.Param("id"), 10, 64)
	if err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "Invalid user ID format", err)
		return
	}

	err = server.store.DeleteUser(ctx, int32(id))
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "User not found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to delete user", err)
		return
	}

	SuccessResponse(ctx, http.StatusOK, "User deleted successfully", nil)
}
