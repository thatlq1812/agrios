package common

import "regexp"

// Email validation regex pattern
var emailRegex = regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)

// IsValidEmail validates email format using regex
func IsValidEmail(email string) bool {
	return emailRegex.MatchString(email)
}
