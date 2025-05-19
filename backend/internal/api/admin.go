package api

import (
	"context"
	"database/sql"
)

// IsUserAdmin checks if a user has admin privileges
// Currently, for simplicity, we're checking based on user ID (e.g., ID 1 is admin)
// This should be replaced with a proper role system in a production environment
func (server *Server) IsUserAdmin(ctx context.Context, userID int32) (bool, error) {
	// For a real application, this would query a user_roles table
	// or check an is_admin field in the users table

	// Get the user from the database
	user, err := server.store.GetUser(ctx, userID)
	if err != nil {
		if err == sql.ErrNoRows {
			return false, nil // User doesn't exist, so not an admin
		}
		return false, err
	}

	// TODO: Replace this with an actual role-based check
	// For now, assume only user with ID 1 is admin (for example purposes)
	// In a real application, check role from database
	return user.ID == 1, nil
}
