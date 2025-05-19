package util

import (
	"regexp"
	"unicode"
)

// IsValidEmail checks if the email follows a valid format
func IsValidEmail(email string) bool {
	// Simple check, can be made more sophisticated
	pattern := `^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$`
	match, _ := regexp.MatchString(pattern, email)
	return match
}

// IsStrongPassword checks if a password meets security criteria
func IsStrongPassword(password string) bool {
	if len(password) < 8 {
		return false
	}

	var hasUpper, hasLower, hasDigit, hasSpecial bool
	for _, char := range password {
		switch {
		case unicode.IsUpper(char):
			hasUpper = true
		case unicode.IsLower(char):
			hasLower = true
		case unicode.IsDigit(char):
			hasDigit = true
		case unicode.IsPunct(char) || unicode.IsSymbol(char):
			hasSpecial = true
		}
	}

	return hasUpper && hasLower && hasDigit && hasSpecial
}

// SanitizeName cleans a username or name input
func SanitizeName(name string) string {
	// Remove any potentially harmful characters
	reg := regexp.MustCompile(`[^a-zA-Z0-9_\s]`)
	return reg.ReplaceAllString(name, "")
}
