package config

import (
	"fmt"
)

// Config stores all configuration of the application.
// The values are read by viper from a config file or environment variables.
type Config struct {
	DBDriver             string `mapstructure:"DB_DRIVER"`
	DBSource             string `mapstructure:"DB_SOURCE"`
	ServerAddress        string `mapstructure:"SERVER_ADDRESS"`
	TokenSymmetricKey    string `mapstructure:"TOKEN_SYMMETRIC_KEY"`
	AccessTokenDuration  int64  `mapstructure:"ACCESS_TOKEN_DURATION"`
	RefreshTokenDuration int64  `mapstructure:"REFRESH_TOKEN_DURATION"`
}

// GetDBSource returns the database connection string.
func GetDBSource(host, port, user, password, dbname string) string {
	return fmt.Sprintf("postgresql://%s:%s@%s:%s/%s?sslmode=disable",
		user, password, host, port, dbname)
}

// DefaultConfig returns default configuration
func DefaultConfig() Config {
	return Config{
		DBDriver:             "postgres",
		DBSource:             GetDBSource("localhost", "5432", "root", "password", "toeic_db"),
		ServerAddress:        "127.0.0.1:8000",
		TokenSymmetricKey:    "12345678901234567890123456789012", // Should be set from environment in production
		AccessTokenDuration:  60 * 60,                            // 1 hour in seconds
		RefreshTokenDuration: 60 * 60 * 24 * 7,                   // 7 days in seconds
	}
}
