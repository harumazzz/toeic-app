package i18n

import (
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/toeic-app/internal/logger"
)

// LanguageMiddleware returns a middleware that detects and sets the language preference
func LanguageMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		lang := detectLanguage(c)
		SetLanguageInContext(c, lang)

		// Add language to response headers for client awareness
		c.Header("Content-Language", string(lang))

		logger.Debug("Language set to: %s for request: %s %s", lang, c.Request.Method, c.Request.URL.Path)

		c.Next()
	}
}

// detectLanguage detects the preferred language from various sources
func detectLanguage(c *gin.Context) SupportedLanguage {
	// Priority order:
	// 1. Query parameter 'lang'
	// 2. Accept-Language header
	// 3. X-Language header (custom header)
	// 4. Default language

	// Check query parameter first
	if langParam := c.Query("lang"); langParam != "" {
		if lang := parseLanguageParam(langParam); GetI18n().IsSupported(lang) {
			return lang
		}
	}

	// Check custom X-Language header
	if langHeader := c.GetHeader("X-Language"); langHeader != "" {
		if lang := parseLanguageParam(langHeader); GetI18n().IsSupported(lang) {
			return lang
		}
	}

	// Check Accept-Language header
	if acceptLang := c.GetHeader(LanguageHeaderKey); acceptLang != "" {
		if lang := ParseLanguageFromHeader(acceptLang); GetI18n().IsSupported(lang) {
			return lang
		}
	}

	// Fallback to default language
	return DefaultLanguage
}

// parseLanguageParam parses language parameter and returns appropriate SupportedLanguage
func parseLanguageParam(param string) SupportedLanguage {
	param = strings.ToLower(strings.TrimSpace(param))

	switch param {
	case "vi", "vn", "vietnamese", "tieng-viet", "tiếng-việt":
		return LanguageVietnamese
	case "en", "eng", "english":
		return LanguageEnglish
	default:
		return DefaultLanguage
	}
}

// GetLanguageFromRequest extracts language from request without middleware
func GetLanguageFromRequest(c *gin.Context) SupportedLanguage {
	return detectLanguage(c)
}

// WithLanguage wraps a handler to force a specific language
func WithLanguage(lang SupportedLanguage, handler gin.HandlerFunc) gin.HandlerFunc {
	return func(c *gin.Context) {
		SetLanguageInContext(c, lang)
		c.Header("Content-Language", string(lang))
		handler(c)
	}
}

// LanguageInfo represents language information for API responses
type LanguageInfo struct {
	Code         string `json:"code"`
	Name         string `json:"name"`
	NativeName   string `json:"native_name"`
	IsDefault    bool   `json:"is_default"`
	MessageCount int    `json:"message_count"`
}

// GetLanguageInfoResponse returns language information for API responses
func GetLanguageInfoResponse() map[string]LanguageInfo {
	i18n := GetI18n()
	languages := make(map[string]LanguageInfo)

	for _, lang := range i18n.GetAllLanguages() {
		info := i18n.GetLanguageInfo(lang)

		langInfo := LanguageInfo{
			Code:         string(lang),
			IsDefault:    lang == DefaultLanguage,
			MessageCount: info["message_count"].(int),
		}

		switch lang {
		case LanguageEnglish:
			langInfo.Name = "English"
			langInfo.NativeName = "English"
		case LanguageVietnamese:
			langInfo.Name = "Vietnamese"
			langInfo.NativeName = "Tiếng Việt"
		}

		languages[string(lang)] = langInfo
	}

	return languages
}
