package api

import (
	"database/sql"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	db "github.com/toeic-app/internal/db/sqlc"
	"github.com/toeic-app/internal/token"
	"github.com/toeic-app/internal/util"
)

// createUserRequest defines the structure for user creation requests.
// It includes username, email, and password, all of which are required and validated.
type createUserRequest struct {
	Username string `json:"username" binding:"required,min=3,max=50"`
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required,min=8,strong_password"`
}

// @Summary     Create a new user
// @Description Create a new user in the system. This endpoint is typically used for user registration.
// @Tags        users
// @Accept      json
// @Produce     json
// @Param       user body createUserRequest true "User information for registration"
// @Success     201 {object} Response{data=UserResponse} "User created successfully"
// @Failure     400 {object} Response "Invalid request parameters or validation failure"
// @Failure     500 {object} Response "Server error during user creation"
// @Security    ApiKeyAuth
// @Router      /api/v1/users [post]
func (server *Server) createUser(ctx *gin.Context) {
	var req createUserRequest
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

	userResp := NewUserResponse(user)

	SuccessResponse(ctx, http.StatusCreated, "User created successfully", userResp)
}

// @Summary     Get a user by ID
// @Description Retrieve a specific user's details by their ID.
// @Tags        users
// @Accept      json
// @Produce     json
// @Param       id path int true "User ID"
// @Success     200 {object} Response{data=UserResponse} "User retrieved successfully"
// @Failure     400 {object} Response "Invalid user ID format"
// @Failure     404 {object} Response "User not found"
// @Failure     500 {object} Response "Server error during user retrieval"
// @Security    ApiKeyAuth
// @Router      /api/v1/users/{id} [get]
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

	userResp := NewUserResponse(user)

	SuccessResponse(ctx, http.StatusOK, "User retrieved successfully", userResp)
}

// listUsersRequest defines the structure for listing users with pagination.
type listUsersRequest struct {
	Limit  int32 `form:"limit" binding:"required,min=1,max=100"`
	Offset int32 `form:"offset" binding:"min=0"`
}

// @Summary     List users
// @Description Get a list of users with pagination. Allows for browsing through users.
// @Tags        users
// @Accept      json
// @Produce     json
// @Param       limit query int true "Number of users to return per page" minimum(1) maximum(100) default(10)
// @Param       offset query int false "Offset for pagination" minimum(0) default(0)
// @Success     200 {object} Response{data=[]UserResponse} "Users retrieved successfully"
// @Failure     400 {object} Response "Invalid query parameters"
// @Failure     500 {object} Response "Server error during user listing"
// @Security    ApiKeyAuth
// @Router      /api/v1/users [get]
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
	var userResponses []UserResponse
	for _, user := range users {
		userResponses = append(userResponses, NewUserResponse(user))
	}
	// Ensure we return an empty array instead of null if no results
	if userResponses == nil {
		userResponses = []UserResponse{}
	}
	SuccessResponse(ctx, http.StatusOK, "Users retrieved successfully", userResponses)
}

// updateUserRequest defines the structure for updating user information.
// All fields are optional; only provided fields will be updated.
type updateUserRequest struct {
	Username string `json:"username" binding:"omitempty,min=3,max=50"`
	Email    string `json:"email" binding:"omitempty,email"`
	Password string `json:"password" binding:"omitempty,min=8,strong_password"`
}

// @Summary     Update a user
// @Description Update an existing user's information by their ID.
// @Tags        users
// @Accept      json
// @Produce     json
// @Param       id path int true "User ID of the user to update"
// @Param       user body updateUserRequest true "User information to update. Only provided fields are updated."
// @Success     200 {object} Response{data=UserResponse} "User updated successfully"
// @Failure     400 {object} Response "Invalid request parameters or user ID format"
// @Failure     404 {object} Response "User not found"
// @Failure     500 {object} Response "Server error during user update"
// @Security    ApiKeyAuth
// @Router      /api/v1/users/{id} [put]
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

	currentUser, err := server.store.GetUser(ctx, int32(id))
	if err != nil {
		if err == sql.ErrNoRows {
			ErrorResponse(ctx, http.StatusNotFound, "User not found", err)
			return
		}
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve user", err)
		return
	}

	arg := db.UpdateUserParams{
		ID:           int32(id),
		Username:     currentUser.Username,
		Email:        currentUser.Email,
		PasswordHash: currentUser.PasswordHash, // Keep existing password hash by default
	}

	if req.Username != "" {
		arg.Username = req.Username
	}

	if req.Email != "" {
		if !util.IsValidEmail(req.Email) {
			ErrorResponse(ctx, http.StatusBadRequest, "Invalid email format", nil)
			return
		}
		arg.Email = req.Email
	}

	if req.Password != "" {
		if !util.IsStrongPassword(req.Password) {
			ErrorResponse(ctx, http.StatusBadRequest, "Password doesn't meet security requirements", nil)
			return
		}
		hashedPassword, err := util.HashPassword(req.Password)
		if err != nil {
			ErrorResponse(ctx, http.StatusInternalServerError, "Failed to process new password", err)
			return
		}
		arg.PasswordHash = hashedPassword
	}
	user, err := server.store.UpdateUser(ctx, arg)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to update user", err)
		return
	}

	userResp := NewUserResponse(user)

	SuccessResponse(ctx, http.StatusOK, "User updated successfully", userResp)
}

// @Summary     Delete a user
// @Description Delete a user by their ID.
// @Tags        users
// @Accept      json
// @Produce     json
// @Param       id path int true "User ID of the user to delete"
// @Success     200 {object} Response "User deleted successfully"
// @Failure     400 {object} Response "Invalid user ID format"
// @Failure     404 {object} Response "User not found"
// @Failure     500 {object} Response "Server error during user deletion"
// @Security    ApiKeyAuth
// @Router      /api/v1/users/{id} [delete]
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

// @Summary     Get current user profile
// @Description Get the profile of the currently authenticated user.
// @Tags        users
// @Accept      json
// @Produce     json
// @Success     200 {object} Response{data=UserResponse} "User profile retrieved successfully"
// @Failure     401 {object} Response "Unauthorized if the user is not authenticated"
// @Failure     500 {object} Response "Server error when retrieving user profile"
// @Security    ApiKeyAuth
// @Router      /api/v1/users/me [get]
func (server *Server) getCurrentUser(ctx *gin.Context) {
	payload, exists := ctx.Get(AuthorizationPayloadKey)
	if !exists {
		ErrorResponse(ctx, http.StatusUnauthorized, "Authorization payload not found", nil)
		return
	}

	authPayload, ok := payload.(*token.Payload)
	if !ok {
		ErrorResponse(ctx, http.StatusUnauthorized, "Invalid authorization payload", nil)
		return
	}
	user, err := server.store.GetUser(ctx, authPayload.ID)
	if err != nil {
		ErrorResponse(ctx, http.StatusInternalServerError, "Failed to retrieve user profile", err)
		return
	}

	userResp := NewUserResponse(user)

	SuccessResponse(ctx, http.StatusOK, "User profile retrieved successfully", userResp)
}
