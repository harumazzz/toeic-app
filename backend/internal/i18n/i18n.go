package i18n

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sync"

	"github.com/gin-gonic/gin"
	"github.com/toeic-app/internal/logger"
)

// SupportedLanguage represents a supported language
type SupportedLanguage string

// Supported languages
const (
	LanguageEnglish    SupportedLanguage = "en"
	LanguageVietnamese SupportedLanguage = "vi"
)

// DefaultLanguage is the fallback language
const DefaultLanguage = LanguageEnglish

// LanguageHeaderKey is the HTTP header key for language preference
const LanguageHeaderKey = "Accept-Language"

// LanguageContextKey is the context key for storing current language
const LanguageContextKey = "language"

// I18n represents the internationalization manager
type I18n struct {
	messages      map[SupportedLanguage]map[string]string
	mutex         sync.RWMutex
	fallbackLang  SupportedLanguage
	supportedLang map[SupportedLanguage]bool
}

// Global instance
var globalI18n *I18n
var once sync.Once

// GetI18n returns the global I18n instance
func GetI18n() *I18n {
	once.Do(func() {
		globalI18n = NewI18n()
	})
	return globalI18n
}

// NewI18n creates a new I18n instance
func NewI18n() *I18n {
	i18n := &I18n{
		messages:     make(map[SupportedLanguage]map[string]string),
		fallbackLang: DefaultLanguage,
		supportedLang: map[SupportedLanguage]bool{
			LanguageEnglish:    true,
			LanguageVietnamese: true,
		},
	}

	// Load default messages
	i18n.loadDefaultMessages()

	// Try to load from files if they exist
	i18n.LoadMessagesFromFiles("./i18n")

	return i18n
}

// IsSupported checks if a language is supported
func (i *I18n) IsSupported(lang SupportedLanguage) bool {
	i.mutex.RLock()
	defer i.mutex.RUnlock()
	return i.supportedLang[lang]
}

// SetFallbackLanguage sets the fallback language
func (i *I18n) SetFallbackLanguage(lang SupportedLanguage) {
	i.mutex.Lock()
	defer i.mutex.Unlock()
	i.fallbackLang = lang
}

// AddMessage adds a message for a specific language and key
func (i *I18n) AddMessage(lang SupportedLanguage, key, message string) {
	i.mutex.Lock()
	defer i.mutex.Unlock()

	if i.messages[lang] == nil {
		i.messages[lang] = make(map[string]string)
	}
	i.messages[lang][key] = message
}

// AddMessages adds multiple messages for a specific language
func (i *I18n) AddMessages(lang SupportedLanguage, messages map[string]string) {
	i.mutex.Lock()
	defer i.mutex.Unlock()

	if i.messages[lang] == nil {
		i.messages[lang] = make(map[string]string)
	}

	for key, message := range messages {
		i.messages[lang][key] = message
	}
}

// GetMessage gets a message for a specific language and key
func (i *I18n) GetMessage(lang SupportedLanguage, key string, args ...interface{}) string {
	i.mutex.RLock()
	defer i.mutex.RUnlock()

	// Try to get message in requested language
	if langMessages, exists := i.messages[lang]; exists {
		if message, exists := langMessages[key]; exists {
			if len(args) > 0 {
				return fmt.Sprintf(message, args...)
			}
			return message
		}
	}

	// Fallback to default language
	if lang != i.fallbackLang {
		if langMessages, exists := i.messages[i.fallbackLang]; exists {
			if message, exists := langMessages[key]; exists {
				if len(args) > 0 {
					return fmt.Sprintf(message, args...)
				}
				return message
			}
		}
	}

	// If still not found, return the key itself as fallback
	if len(args) > 0 {
		return fmt.Sprintf(key, args...)
	}
	return key
}

// GetLanguageFromContext extracts language from Gin context
func GetLanguageFromContext(c *gin.Context) SupportedLanguage {
	if lang, exists := c.Get(LanguageContextKey); exists {
		if langStr, ok := lang.(SupportedLanguage); ok {
			return langStr
		}
	}
	return DefaultLanguage
}

// SetLanguageInContext sets language in Gin context
func SetLanguageInContext(c *gin.Context, lang SupportedLanguage) {
	c.Set(LanguageContextKey, lang)
}

// ParseLanguageFromHeader parses language preference from Accept-Language header
func ParseLanguageFromHeader(header string) SupportedLanguage {
	if header == "" {
		return DefaultLanguage
	}

	// Simple parsing - can be enhanced for more complex Accept-Language parsing
	switch {
	case header == "vi" || header == "vi-VN" || header == "vietnamese":
		return LanguageVietnamese
	case header == "en" || header == "en-US" || header == "english":
		return LanguageEnglish
	default:
		// Try to extract language code from complex header like "vi-VN,vi;q=0.9,en;q=0.8"
		if len(header) >= 2 {
			langCode := header[:2]
			switch langCode {
			case "vi":
				return LanguageVietnamese
			case "en":
				return LanguageEnglish
			}
		}
		return DefaultLanguage
	}
}

// LoadMessagesFromFiles loads messages from JSON files
func (i *I18n) LoadMessagesFromFiles(dir string) error {
	// Try to load messages from files
	for lang := range i.supportedLang {
		filename := filepath.Join(dir, fmt.Sprintf("%s.json", string(lang)))
		if err := i.loadMessagesFromFile(lang, filename); err != nil {
			logger.Debug("Could not load messages from file %s: %v", filename, err)
		} else {
			logger.Info("Loaded messages for language %s from file %s", lang, filename)
		}
	}
	return nil
}

// loadMessagesFromFile loads messages from a specific JSON file
func (i *I18n) loadMessagesFromFile(lang SupportedLanguage, filename string) error {
	data, err := os.ReadFile(filename)
	if err != nil {
		return err
	}

	var messages map[string]string
	if err := json.Unmarshal(data, &messages); err != nil {
		return err
	}

	i.AddMessages(lang, messages)
	return nil
}

// SaveMessagesToFile saves messages to a JSON file
func (i *I18n) SaveMessagesToFile(lang SupportedLanguage, filename string) error {
	i.mutex.RLock()
	messages := i.messages[lang]
	i.mutex.RUnlock()

	if messages == nil {
		return fmt.Errorf("no messages found for language %s", lang)
	}

	// Create directory if it doesn't exist
	dir := filepath.Dir(filename)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("failed to create directory %s: %w", dir, err)
	}

	data, err := json.MarshalIndent(messages, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(filename, data, 0644)
}

// GetAllLanguages returns all supported languages
func (i *I18n) GetAllLanguages() []SupportedLanguage {
	i.mutex.RLock()
	defer i.mutex.RUnlock()

	languages := make([]SupportedLanguage, 0, len(i.supportedLang))
	for lang := range i.supportedLang {
		languages = append(languages, lang)
	}
	return languages
}

// GetLanguageInfo returns information about a language
func (i *I18n) GetLanguageInfo(lang SupportedLanguage) map[string]interface{} {
	info := map[string]interface{}{
		"code":      string(lang),
		"supported": i.IsSupported(lang),
	}

	switch lang {
	case LanguageEnglish:
		info["name"] = "English"
		info["native_name"] = "English"
	case LanguageVietnamese:
		info["name"] = "Vietnamese"
		info["native_name"] = "Tiếng Việt"
	}

	i.mutex.RLock()
	if messages, exists := i.messages[lang]; exists {
		info["message_count"] = len(messages)
	} else {
		info["message_count"] = 0
	}
	i.mutex.RUnlock()

	return info
}

// GetStats returns statistics about loaded messages
func (i *I18n) GetStats() map[string]interface{} {
	i.mutex.RLock()
	defer i.mutex.RUnlock()

	stats := map[string]interface{}{
		"supported_languages": len(i.supportedLang),
		"fallback_language":   string(i.fallbackLang),
		"languages":           make(map[string]interface{}),
	}

	for lang := range i.supportedLang {
		langStats := map[string]interface{}{
			"supported": true,
		}
		if messages, exists := i.messages[lang]; exists {
			langStats["message_count"] = len(messages)
		} else {
			langStats["message_count"] = 0
		}
		stats["languages"].(map[string]interface{})[string(lang)] = langStats
	}

	return stats
}

// Convenience functions using global instance

// T translates a message using the global I18n instance
func T(lang SupportedLanguage, key string, args ...interface{}) string {
	return GetI18n().GetMessage(lang, key, args...)
}

// TWithContext translates a message using language from Gin context
func TWithContext(c *gin.Context, key string, args ...interface{}) string {
	lang := GetLanguageFromContext(c)
	return GetI18n().GetMessage(lang, key, args...)
}

// AddGlobalMessage adds a message to the global I18n instance
func AddGlobalMessage(lang SupportedLanguage, key, message string) {
	GetI18n().AddMessage(lang, key, message)
}

// AddGlobalMessages adds multiple messages to the global I18n instance
func AddGlobalMessages(lang SupportedLanguage, messages map[string]string) {
	GetI18n().AddMessages(lang, messages)
}
