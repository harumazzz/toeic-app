package security

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"fmt"
	"io"
	"os"
	"strings"
	"time"

	"github.com/toeic-app/internal/logger"
	"golang.org/x/crypto/pbkdf2"
)

// SecretsManager handles secure storage and retrieval of sensitive configuration
type SecretsManager struct {
	masterKey []byte
	salt      []byte
}

// NewSecretsManager creates a new secrets manager
func NewSecretsManager() (*SecretsManager, error) {
	// Get master key from environment or generate
	masterKeyStr := os.Getenv("MASTER_ENCRYPTION_KEY")
	if masterKeyStr == "" {
		return nil, fmt.Errorf("MASTER_ENCRYPTION_KEY environment variable is required")
	}

	// Decode master key
	masterKey, err := hex.DecodeString(masterKeyStr)
	if err != nil {
		return nil, fmt.Errorf("invalid master key format: %w", err)
	}

	// Get or generate salt
	saltStr := os.Getenv("ENCRYPTION_SALT")
	var salt []byte
	if saltStr != "" {
		salt, err = hex.DecodeString(saltStr)
		if err != nil {
			return nil, fmt.Errorf("invalid salt format: %w", err)
		}
	} else {
		// Generate new salt (for first-time setup)
		salt = make([]byte, 32)
		if _, err := rand.Read(salt); err != nil {
			return nil, fmt.Errorf("failed to generate salt: %w", err)
		}
		logger.Warn("Generated new encryption salt. Save this to ENCRYPTION_SALT environment variable: %s", hex.EncodeToString(salt))
	}

	return &SecretsManager{
		masterKey: masterKey,
		salt:      salt,
	}, nil
}

// Encrypt encrypts a secret value
func (sm *SecretsManager) Encrypt(plaintext string) (string, error) {
	// Derive key using PBKDF2
	key := pbkdf2.Key(sm.masterKey, sm.salt, 100000, 32, sha256.New)

	// Create AES cipher
	block, err := aes.NewCipher(key)
	if err != nil {
		return "", fmt.Errorf("failed to create cipher: %w", err)
	}

	// Create GCM mode
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", fmt.Errorf("failed to create GCM: %w", err)
	}

	// Generate nonce
	nonce := make([]byte, gcm.NonceSize())
	if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
		return "", fmt.Errorf("failed to generate nonce: %w", err)
	}

	// Encrypt
	ciphertext := gcm.Seal(nonce, nonce, []byte(plaintext), nil)

	// Return base64 encoded result
	return base64.StdEncoding.EncodeToString(ciphertext), nil
}

// Decrypt decrypts a secret value
func (sm *SecretsManager) Decrypt(ciphertext string) (string, error) {
	// Decode from base64
	data, err := base64.StdEncoding.DecodeString(ciphertext)
	if err != nil {
		return "", fmt.Errorf("failed to decode base64: %w", err)
	}

	// Derive key using PBKDF2
	key := pbkdf2.Key(sm.masterKey, sm.salt, 100000, 32, sha256.New)

	// Create AES cipher
	block, err := aes.NewCipher(key)
	if err != nil {
		return "", fmt.Errorf("failed to create cipher: %w", err)
	}

	// Create GCM mode
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", fmt.Errorf("failed to create GCM: %w", err)
	}
	// Extract nonce and ciphertext
	nonceSize := gcm.NonceSize()
	if len(data) < nonceSize {
		return "", fmt.Errorf("ciphertext too short")
	}

	nonce, ciphertextBytes := data[:nonceSize], data[nonceSize:]

	// Decrypt
	plaintext, err := gcm.Open(nil, nonce, ciphertextBytes, nil)
	if err != nil {
		return "", fmt.Errorf("failed to decrypt: %w", err)
	}

	return string(plaintext), nil
}

// GetSecret retrieves and decrypts a secret from environment
func (sm *SecretsManager) GetSecret(key string) (string, error) {
	encryptedValue := os.Getenv(key)
	if encryptedValue == "" {
		return "", fmt.Errorf("secret %s not found", key)
	}

	// Check if it's prefixed with "encrypted:"
	if strings.HasPrefix(encryptedValue, "encrypted:") {
		encryptedValue = strings.TrimPrefix(encryptedValue, "encrypted:")
		return sm.Decrypt(encryptedValue)
	}

	// If not encrypted, return as-is (for backward compatibility)
	return encryptedValue, nil
}

// SecretRotationConfig holds configuration for secret rotation
type SecretRotationConfig struct {
	RotationInterval time.Duration
	RotationEnabled  bool
	NotifyBeforeExp  time.Duration
}

// SecretMetadata holds metadata about a secret
type SecretMetadata struct {
	Key         string    `json:"key"`
	CreatedAt   time.Time `json:"created_at"`
	LastRotated time.Time `json:"last_rotated"`
	ExpiresAt   time.Time `json:"expires_at"`
	Version     int       `json:"version"`
}

// RotationManager handles automatic secret rotation
type RotationManager struct {
	secretsManager *SecretsManager
	config         SecretRotationConfig
	metadata       map[string]SecretMetadata
}

// NewRotationManager creates a new rotation manager
func NewRotationManager(sm *SecretsManager, config SecretRotationConfig) *RotationManager {
	return &RotationManager{
		secretsManager: sm,
		config:         config,
		metadata:       make(map[string]SecretMetadata),
	}
}

// ShouldRotate checks if a secret should be rotated
func (rm *RotationManager) ShouldRotate(key string) bool {
	if !rm.config.RotationEnabled {
		return false
	}

	metadata, exists := rm.metadata[key]
	if !exists {
		return true // New secret, should be rotated
	}

	return time.Since(metadata.LastRotated) > rm.config.RotationInterval
}

// RotateSecret rotates a secret
func (rm *RotationManager) RotateSecret(key string, newValue string) error {
	// Encrypt new value
	encrypted, err := rm.secretsManager.Encrypt(newValue)
	if err != nil {
		return fmt.Errorf("failed to encrypt new secret: %w", err)
	}

	// Update environment (in practice, this would update your secret store)
	os.Setenv(key, "encrypted:"+encrypted)

	// Update metadata
	now := time.Now()
	rm.metadata[key] = SecretMetadata{
		Key:         key,
		CreatedAt:   rm.metadata[key].CreatedAt,
		LastRotated: now,
		ExpiresAt:   now.Add(rm.config.RotationInterval),
		Version:     rm.metadata[key].Version + 1,
	}

	logger.InfoWithFields(logger.Fields{
		"component": "secrets",
		"action":    "rotate",
		"key":       key,
		"version":   rm.metadata[key].Version,
	}, "Secret rotated successfully")

	return nil
}

// GenerateRandomKey generates a random encryption key
func GenerateRandomKey() (string, error) {
	key := make([]byte, 32) // 256-bit key
	if _, err := rand.Read(key); err != nil {
		return "", fmt.Errorf("failed to generate random key: %w", err)
	}
	return hex.EncodeToString(key), nil
}

// ValidateSecretStrength validates the strength of a secret
func ValidateSecretStrength(secret string) error {
	if len(secret) < 16 {
		return fmt.Errorf("secret must be at least 16 characters long")
	}

	hasUpper := false
	hasLower := false
	hasDigit := false
	hasSpecial := false

	for _, r := range secret {
		switch {
		case r >= 'A' && r <= 'Z':
			hasUpper = true
		case r >= 'a' && r <= 'z':
			hasLower = true
		case r >= '0' && r <= '9':
			hasDigit = true
		default:
			hasSpecial = true
		}
	}

	if !hasUpper || !hasLower || !hasDigit || !hasSpecial {
		return fmt.Errorf("secret must contain uppercase, lowercase, digit, and special characters")
	}

	return nil
}
