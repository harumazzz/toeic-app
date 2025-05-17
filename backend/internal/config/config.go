package config

import (
	"fmt"
	"log"
	"os"
	"strconv"
	"time"

	"github.com/joho/godotenv"
)

// Config stores all configuration of the application.
// The values are read from environment variables or .env file.
type Config struct {
	DBDriver             string        `mapstructure:"DB_DRIVER"`
	DBSource             string        `mapstructure:"DB_SOURCE"`
	ServerAddress        string        `mapstructure:"SERVER_ADDRESS"`
	TokenSymmetricKey    string        `mapstructure:"TOKEN_SYMMETRIC_KEY"`
	AccessTokenDuration  time.Duration `mapstructure:"ACCESS_TOKEN_DURATION"`
	RefreshTokenDuration int64         `mapstructure:"REFRESH_TOKEN_DURATION"`
	CloudinaryURL        string        `mapstructure:"CLOUDINARY_URL"`
}

// LoadEnv loads environment variables from .env file
func LoadEnv() {
	err := godotenv.Load()
	if err != nil {
		log.Printf("Warning: .env file not found, using environment variables")
	}
}

// GetDBSource returns the database connection string.
func GetDBSource(host, port, user, password, dbname string) string {
	return fmt.Sprintf("postgresql://%s:%s@%s:%s/%s?sslmode=disable",
		user, password, host, port, dbname)
}

// GetEnv gets an environment variable or returns a default value
func GetEnv(key, defaultValue string) string {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}
	return value
}

// GetEnvAsInt gets an environment variable as int or returns a default value
func GetEnvAsInt(key string, defaultValue int64) int64 {
	valueStr := os.Getenv(key)
	if valueStr == "" {
		return defaultValue
	}

	value, err := strconv.ParseInt(valueStr, 10, 64)
	if err != nil {
		log.Printf("Warning: could not parse %s as int: %v", key, err)
		return defaultValue
	}

	return value
}

// DefaultConfig returns configuration from environment variables
func DefaultConfig() Config {
	// Load environment variables from .env file
	LoadEnv()

	// Get database configuration
	dbDriver := GetEnv("DB_DRIVER", "postgres")
	dbHost := GetEnv("DB_HOST", "localhost")
	dbPort := GetEnv("DB_PORT", "5432")
	dbUser := GetEnv("DB_USER", "root")
	dbPassword := GetEnv("DB_PASSWORD", "password")
	dbName := GetEnv("DB_NAME", "toeic_db")

	// Get server configuration
	serverAddress := GetEnv("SERVER_ADDRESS", "127.0.0.1:8000")

	// Get JWT configuration
	tokenKey := GetEnv("TOKEN_SYMMETRIC_KEY", "12345678901234567890123456789012")
	accessTokenDuration := time.Duration(GetEnvAsInt("ACCESS_TOKEN_DURATION", 3600)) * time.Second
	refreshTokenDuration := GetEnvAsInt("REFRESH_TOKEN_DURATION", 604800)

	// Get Cloudinary configuration
	cloudinaryURL := GetEnv("CLOUDINARY_URL", "")

	if cloudinaryURL == "" {
		log.Fatal("CLOUDINARY_URL environment variable is required")
	}

	return Config{
		DBDriver:             dbDriver,
		DBSource:             GetDBSource(dbHost, dbPort, dbUser, dbPassword, dbName),
		ServerAddress:        serverAddress,
		TokenSymmetricKey:    tokenKey,
		AccessTokenDuration:  accessTokenDuration,
		RefreshTokenDuration: refreshTokenDuration,
		CloudinaryURL:        cloudinaryURL,
	}
}
