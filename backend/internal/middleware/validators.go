package middleware

import (
	"github.com/gin-gonic/gin/binding"
	"github.com/go-playground/validator/v10"
	"github.com/toeic-app/internal/util"
)

// RegisterValidators adds custom validators to the Gin validation engine
func RegisterValidators() {
	if v, ok := binding.Validator.Engine().(*validator.Validate); ok {
		// Register custom validation for email
		err := v.RegisterValidation("valid_email", validEmailValidator)
		if err != nil {
			// If registration fails, log but don't panic
			// This could happen if the validator is already registered
		}

		// Register custom validation for password strength
		err = v.RegisterValidation("strong_password", strongPasswordValidator)
		if err != nil {
			// If registration fails, log but don't panic
			// This could happen if the validator is already registered
		}
	}
}

// validEmailValidator implements a custom email validator using our utility function
func validEmailValidator(fl validator.FieldLevel) bool {
	if email, ok := fl.Field().Interface().(string); ok {
		return util.IsValidEmail(email)
	}
	return false
}

// strongPasswordValidator implements a custom password strength validator
func strongPasswordValidator(fl validator.FieldLevel) bool {
	if password, ok := fl.Field().Interface().(string); ok {
		return util.IsStrongPassword(password)
	}
	return false
}
