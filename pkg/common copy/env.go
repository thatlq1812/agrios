package common

import (
	"log"
	"os"
	"strconv"
	"time"
)

// GetEnvInt retrieves an int value from environment variable with fallback to default value
func GetEnvInt(key string, defaultValue int) int {
	valStr := os.Getenv(key)
	if valStr == "" {
		return defaultValue
	}
	val, err := strconv.Atoi(valStr)
	if err != nil {
		log.Printf("Warning: could not parse %s='%s' to int. Using default value %d.", key, valStr, defaultValue)
		return defaultValue
	}
	return val
}

// GetEnvInt32 retrieves an int32 value from environment variable with fallback to default value
func GetEnvInt32(key string, defaultValue int32) int32 {
	valStr := os.Getenv(key)
	if valStr == "" {
		return defaultValue
	}
	val, err := strconv.ParseInt(valStr, 10, 32)
	if err != nil {
		log.Printf("Warning: could not parse %s='%s' to int32. Using default value %d.", key, valStr, defaultValue)
		return defaultValue
	}
	return int32(val)
}

// GetEnvDuration retrieves a time.Duration from environment variable with fallback to default value
// Accepts formats like: 1h, 30m, 5s, 100ms
func GetEnvDuration(key string, defaultValue time.Duration) time.Duration {
	valStr := os.Getenv(key)
	if valStr == "" {
		return defaultValue
	}
	val, err := time.ParseDuration(valStr)
	if err != nil {
		log.Printf("Warning: could not parse %s='%s' to time.Duration. Using default value %v. Example format: 1h, 30m, 5s.", key, valStr, defaultValue)
		return defaultValue
	}
	return val
}

// GetEnvString retrieves a string from environment variable with fallback to default value
func GetEnvString(key string, defaultValue string) string {
	val := os.Getenv(key)
	if val == "" {
		return defaultValue
	}
	return val
}

// MustGetEnvString retrieves a string from environment variable or panics if not set
func MustGetEnvString(key string) string {
	val := os.Getenv(key)
	if val == "" {
		log.Fatalf("Fatal: Environment variable %s is required but not set", key)
	}
	return val
}
