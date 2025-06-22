package config

import (
	"fmt"
	"os"
	"strconv"
	"time"
)

// BackupConfig holds configuration for backup operations
type BackupConfig struct {
	// Basic settings
	Enabled    bool          `json:"enabled"`
	BackupDir  string        `json:"backup_dir"`
	MaxRetries int           `json:"max_retries"`
	RetryWait  time.Duration `json:"retry_wait"`

	// Scheduling settings
	AutoBackupEnabled bool          `json:"auto_backup_enabled"`
	BackupInterval    time.Duration `json:"backup_interval"`
	BackupTime        string        `json:"backup_time"` // Format: "15:04" for daily backup at specific time

	// Retention settings
	RetentionDays   int  `json:"retention_days"`
	MaxBackupCount  int  `json:"max_backup_count"`
	CompressBackups bool `json:"compress_backups"`

	// Validation settings
	ValidateAfterBackup   bool `json:"validate_after_backup"`
	ValidateBeforeRestore bool `json:"validate_before_restore"`

	// Security settings
	EncryptBackups bool   `json:"encrypt_backups"`
	EncryptionKey  string `json:"encryption_key"`

	// Storage settings
	StorageType string             `json:"storage_type"` // local, s3, azure, gcp
	S3Config    *S3BackupConfig    `json:"s3_config,omitempty"`
	AzureConfig *AzureBackupConfig `json:"azure_config,omitempty"`

	// Performance settings
	CompressionLevel int `json:"compression_level"` // 1-9 for gzip
	ParallelJobs     int `json:"parallel_jobs"`
	BufferSize       int `json:"buffer_size"`

	// Monitoring settings
	NotifyOnSuccess    bool   `json:"notify_on_success"`
	NotifyOnFailure    bool   `json:"notify_on_failure"`
	WebhookURL         string `json:"webhook_url"`
	SlackWebhookURL    string `json:"slack_webhook_url"`
	EmailNotifications bool   `json:"email_notifications"`
}

// S3BackupConfig holds AWS S3 specific configuration
type S3BackupConfig struct {
	AccessKeyID     string `json:"access_key_id"`
	SecretAccessKey string `json:"secret_access_key"`
	Region          string `json:"region"`
	Bucket          string `json:"bucket"`
	Prefix          string `json:"prefix"`
	StorageClass    string `json:"storage_class"` // STANDARD, REDUCED_REDUNDANCY, IA, GLACIER
}

// AzureBackupConfig holds Azure specific configuration
type AzureBackupConfig struct {
	AccountName   string `json:"account_name"`
	AccountKey    string `json:"account_key"`
	ContainerName string `json:"container_name"`
	Prefix        string `json:"prefix"`
}

// LoadBackupConfig loads backup configuration from environment variables
func LoadBackupConfig() BackupConfig {
	cfg := BackupConfig{
		// Default values
		Enabled:    getEnvBool("BACKUP_ENABLED", true),
		BackupDir:  getEnvString("BACKUP_DIR", "./backups"),
		MaxRetries: getEnvInt("BACKUP_MAX_RETRIES", 3),
		RetryWait:  getEnvDuration("BACKUP_RETRY_WAIT", time.Second),

		AutoBackupEnabled: getEnvBool("AUTO_BACKUP_ENABLED", true),
		BackupInterval:    getEnvDuration("BACKUP_INTERVAL", 24*time.Hour),
		BackupTime:        getEnvString("BACKUP_TIME", "03:00"), // 3 AM default

		RetentionDays:   getEnvInt("BACKUP_RETENTION_DAYS", 30),
		MaxBackupCount:  getEnvInt("BACKUP_MAX_COUNT", 100),
		CompressBackups: getEnvBool("BACKUP_COMPRESS", true),

		ValidateAfterBackup:   getEnvBool("BACKUP_VALIDATE_AFTER", true),
		ValidateBeforeRestore: getEnvBool("BACKUP_VALIDATE_BEFORE_RESTORE", true),

		EncryptBackups: getEnvBool("BACKUP_ENCRYPT", false),
		EncryptionKey:  getEnvString("BACKUP_ENCRYPTION_KEY", ""),

		StorageType: getEnvString("BACKUP_STORAGE_TYPE", "local"),

		CompressionLevel: getEnvInt("BACKUP_COMPRESSION_LEVEL", 6),
		ParallelJobs:     getEnvInt("BACKUP_PARALLEL_JOBS", 1),
		BufferSize:       getEnvInt("BACKUP_BUFFER_SIZE", 64*1024), // 64KB

		NotifyOnSuccess:    getEnvBool("BACKUP_NOTIFY_SUCCESS", false),
		NotifyOnFailure:    getEnvBool("BACKUP_NOTIFY_FAILURE", true),
		WebhookURL:         getEnvString("BACKUP_WEBHOOK_URL", ""),
		SlackWebhookURL:    getEnvString("BACKUP_SLACK_WEBHOOK_URL", ""),
		EmailNotifications: getEnvBool("BACKUP_EMAIL_NOTIFICATIONS", false),
	}

	// Load cloud storage configs if needed
	if cfg.StorageType == "s3" {
		cfg.S3Config = &S3BackupConfig{
			AccessKeyID:     getEnvString("AWS_ACCESS_KEY_ID", ""),
			SecretAccessKey: getEnvString("AWS_SECRET_ACCESS_KEY", ""),
			Region:          getEnvString("AWS_REGION", "us-east-1"),
			Bucket:          getEnvString("BACKUP_S3_BUCKET", ""),
			Prefix:          getEnvString("BACKUP_S3_PREFIX", "toeic-backups/"),
			StorageClass:    getEnvString("BACKUP_S3_STORAGE_CLASS", "STANDARD"),
		}
	}

	if cfg.StorageType == "azure" {
		cfg.AzureConfig = &AzureBackupConfig{
			AccountName:   getEnvString("AZURE_STORAGE_ACCOUNT", ""),
			AccountKey:    getEnvString("AZURE_STORAGE_KEY", ""),
			ContainerName: getEnvString("BACKUP_AZURE_CONTAINER", "toeic-backups"),
			Prefix:        getEnvString("BACKUP_AZURE_PREFIX", "backups/"),
		}
	}

	return cfg
}

// Validate validates the backup configuration
func (c *BackupConfig) Validate() error {
	if !c.Enabled {
		return nil // Skip validation if backups are disabled
	}

	if c.BackupDir == "" {
		return fmt.Errorf("backup directory cannot be empty")
	}

	if c.MaxRetries < 1 {
		return fmt.Errorf("max retries must be at least 1")
	}

	if c.RetentionDays < 1 {
		return fmt.Errorf("retention days must be at least 1")
	}

	if c.MaxBackupCount < 1 {
		return fmt.Errorf("max backup count must be at least 1")
	}

	if c.CompressionLevel < 1 || c.CompressionLevel > 9 {
		return fmt.Errorf("compression level must be between 1 and 9")
	}

	if c.StorageType == "s3" && c.S3Config == nil {
		return fmt.Errorf("S3 configuration required when storage type is s3")
	}

	if c.StorageType == "azure" && c.AzureConfig == nil {
		return fmt.Errorf("azure configuration required when storage type is azure")
	}

	if c.EncryptBackups && c.EncryptionKey == "" {
		return fmt.Errorf("encryption key required when backup encryption is enabled")
	}

	return nil
}

// GetRetentionDuration returns the retention period as a duration
func (c *BackupConfig) GetRetentionDuration() time.Duration {
	return time.Duration(c.RetentionDays) * 24 * time.Hour
}

// Helper functions for environment variables
func getEnvString(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvBool(key string, defaultValue bool) bool {
	if value := os.Getenv(key); value != "" {
		if parsed, err := strconv.ParseBool(value); err == nil {
			return parsed
		}
	}
	return defaultValue
}

func getEnvInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if parsed, err := strconv.Atoi(value); err == nil {
			return parsed
		}
	}
	return defaultValue
}

func getEnvDuration(key string, defaultValue time.Duration) time.Duration {
	if value := os.Getenv(key); value != "" {
		if parsed, err := time.ParseDuration(value); err == nil {
			return parsed
		}
	}
	return defaultValue
}
