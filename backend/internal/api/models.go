package api

import (
	"time"

	db "github.com/toeic-app/internal/db/sqlc"
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
