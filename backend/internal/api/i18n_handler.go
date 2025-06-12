package api

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/toeic-app/internal/i18n"
	"github.com/toeic-app/internal/logger"
)

// LanguageResponse represents language information in API responses
type LanguageResponse struct {
	Code          string `json:"code"`
	Name          string `json:"name"`
	NativeName    string `json:"native_name"`
	IsDefault     bool   `json:"is_default"`
	IsSupported   bool   `json:"is_supported"`
	MessageCount  int    `json:"message_count"`
	CurrentlyUsed bool   `json:"currently_used"`
}

// I18nStatsResponse represents i18n statistics
type I18nStatsResponse struct {
	SupportedLanguages int                         `json:"supported_languages"`
	FallbackLanguage   string                      `json:"fallback_language"`
	CurrentLanguage    string                      `json:"current_language"`
	Languages          map[string]LanguageResponse `json:"languages"`
	Statistics         map[string]interface{}      `json:"statistics"`
}

// MessageRequest represents a request to add/update a message
type MessageRequest struct {
	Key     string `json:"key" binding:"required"`
	Message string `json:"message" binding:"required"`
}

// MessagesRequest represents a request to add/update multiple messages
type MessagesRequest struct {
	Messages map[string]string `json:"messages" binding:"required"`
}

// @Summary Get supported languages
// @Description Get list of all supported languages with their information
// @Tags i18n
// @Accept json
// @Produce json
// @Success 200 {object} Response{data=I18nStatsResponse} "Languages retrieved successfully"
// @Router /api/v1/i18n/languages [get]
func (server *Server) getLanguages(ctx *gin.Context) {
	currentLang := i18n.GetLanguageFromContext(ctx)
	i18nInstance := i18n.GetI18n()
	stats := i18nInstance.GetStats()

	languages := make(map[string]LanguageResponse)

	for _, lang := range i18nInstance.GetAllLanguages() {
		info := i18nInstance.GetLanguageInfo(lang)

		langResponse := LanguageResponse{
			Code:          string(lang),
			IsDefault:     lang == i18n.DefaultLanguage,
			IsSupported:   true,
			MessageCount:  info["message_count"].(int),
			CurrentlyUsed: lang == currentLang,
		}

		switch lang {
		case i18n.LanguageEnglish:
			langResponse.Name = "English"
			langResponse.NativeName = "English"
		case i18n.LanguageVietnamese:
			langResponse.Name = "Vietnamese"
			langResponse.NativeName = "Tiếng Việt"
		}

		languages[string(lang)] = langResponse
	}

	response := I18nStatsResponse{
		SupportedLanguages: len(languages),
		FallbackLanguage:   string(i18n.DefaultLanguage),
		CurrentLanguage:    string(currentLang),
		Languages:          languages,
		Statistics:         stats,
	}

	SuccessResponse(ctx, http.StatusOK, "languages_retrieved_successfully", response)
}

// @Summary Get current language
// @Description Get the current language being used for the request
// @Tags i18n
// @Accept json
// @Produce json
// @Success 200 {object} Response{data=LanguageResponse} "Current language retrieved successfully"
// @Router /api/v1/i18n/current [get]
func (server *Server) getCurrentLanguage(ctx *gin.Context) {
	currentLang := i18n.GetLanguageFromContext(ctx)
	i18nInstance := i18n.GetI18n()
	info := i18nInstance.GetLanguageInfo(currentLang)

	langResponse := LanguageResponse{
		Code:          string(currentLang),
		IsDefault:     currentLang == i18n.DefaultLanguage,
		IsSupported:   true,
		MessageCount:  info["message_count"].(int),
		CurrentlyUsed: true,
	}

	switch currentLang {
	case i18n.LanguageEnglish:
		langResponse.Name = "English"
		langResponse.NativeName = "English"
	case i18n.LanguageVietnamese:
		langResponse.Name = "Vietnamese"
		langResponse.NativeName = "Tiếng Việt"
	}

	SuccessResponse(ctx, http.StatusOK, "retrieved_successfully", langResponse)
}

// @Summary Get i18n statistics
// @Description Get detailed statistics about the i18n system
// @Tags i18n
// @Accept json
// @Produce json
// @Success 200 {object} Response{data=map[string]interface{}} "I18n statistics retrieved successfully"
// @Router /api/v1/i18n/stats [get]
func (server *Server) getI18nStats(ctx *gin.Context) {
	i18nInstance := i18n.GetI18n()
	stats := i18nInstance.GetStats()

	SuccessResponse(ctx, http.StatusOK, "retrieved_successfully", stats)
}

// @Summary Test message translation
// @Description Test translation of a message key with the current language
// @Tags i18n
// @Accept json
// @Produce json
// @Param key query string true "Message key to translate"
// @Success 200 {object} Response{data=object} "Message translated successfully"
// @Failure 400 {object} Response "Invalid request parameters"
// @Router /api/v1/i18n/translate [get]
func (server *Server) testTranslation(ctx *gin.Context) {
	messageKey := ctx.Query("key")
	if messageKey == "" {
		ErrorResponse(ctx, http.StatusBadRequest, "required_field_missing", nil)
		return
	}

	currentLang := i18n.GetLanguageFromContext(ctx)
	translatedMessage := i18n.T(currentLang, "%s", messageKey)

	// Check if we have arguments for sprintf formatting
	args := make([]interface{}, 0)
	for i := 0; i < 10; i++ { // Support up to 10 arguments
		argKey := "arg" + strconv.Itoa(i)
		if argValue := ctx.Query(argKey); argValue != "" {
			args = append(args, argValue)
		}
	}

	if len(args) > 0 {
		translatedMessage = i18n.T(currentLang, messageKey, args...)
	}

	response := gin.H{
		"key":                messageKey,
		"translated_message": translatedMessage,
		"language":           string(currentLang),
		"arguments":          args,
	}

	SuccessResponse(ctx, http.StatusOK, "translation_completed_successfully", response)
}

// @Summary Add or update a message (Admin only)
// @Description Add or update a translation message for a specific language
// @Tags i18n
// @Accept json
// @Produce json
// @Param language path string true "Language code (en, vi)"
// @Param message body MessageRequest true "Message details"
// @Success 200 {object} Response "Message updated successfully"
// @Success 201 {object} Response "Message created successfully"
// @Failure 400 {object} Response "Invalid request"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 403 {object} Response "Forbidden - Admin access required"
// @Security ApiKeyAuth
// @Router /api/v1/admin/i18n/languages/{language}/messages [post]
func (server *Server) addMessage(ctx *gin.Context) {
	langParam := ctx.Param("language")
	lang := i18n.SupportedLanguage(langParam)

	if !i18n.GetI18n().IsSupported(lang) {
		ErrorResponse(ctx, http.StatusBadRequest, "invalid_request", nil)
		return
	}

	var req MessageRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "invalid_request_body", err)
		return
	}

	// Check if message already exists
	i18nInstance := i18n.GetI18n()
	existingMessage := i18nInstance.GetMessage(lang, "%s", req.Key)
	messageExists := existingMessage != req.Key // If it returns the key, it doesn't exist

	// Add the message
	i18nInstance.AddMessage(lang, req.Key, req.Message)

	logger.Info("Message '%s' for language '%s' updated by admin", req.Key, lang)

	if messageExists {
		SuccessResponse(ctx, http.StatusOK, "updated_successfully", gin.H{
			"key":      req.Key,
			"message":  req.Message,
			"language": string(lang),
		})
	} else {
		SuccessResponse(ctx, http.StatusCreated, "created_successfully", gin.H{
			"key":      req.Key,
			"message":  req.Message,
			"language": string(lang),
		})
	}
}

// @Summary Add or update multiple messages (Admin only)
// @Description Add or update multiple translation messages for a specific language
// @Tags i18n
// @Accept json
// @Produce json
// @Param language path string true "Language code (en, vi)"
// @Param messages body MessagesRequest true "Messages details"
// @Success 200 {object} Response "Messages updated successfully"
// @Failure 400 {object} Response "Invalid request"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 403 {object} Response "Forbidden - Admin access required"
// @Security ApiKeyAuth
// @Router /api/v1/admin/i18n/languages/{language}/messages/batch [post]
func (server *Server) addMessages(ctx *gin.Context) {
	langParam := ctx.Param("language")
	lang := i18n.SupportedLanguage(langParam)

	if !i18n.GetI18n().IsSupported(lang) {
		ErrorResponse(ctx, http.StatusBadRequest, "invalid_request", nil)
		return
	}

	var req MessagesRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ErrorResponse(ctx, http.StatusBadRequest, "invalid_request_body", err)
		return
	}

	// Add the messages
	i18nInstance := i18n.GetI18n()
	i18nInstance.AddMessages(lang, req.Messages)

	logger.Info("%d messages for language '%s' updated by admin", len(req.Messages), lang)

	SuccessResponse(ctx, http.StatusOK, "updated_successfully", gin.H{
		"language":      string(lang),
		"message_count": len(req.Messages),
		"messages":      req.Messages,
	})
}

// @Summary Export messages (Admin only)
// @Description Export all messages for a specific language as JSON
// @Tags i18n
// @Accept json
// @Produce json
// @Param language path string true "Language code (en, vi)"
// @Success 200 {object} Response{data=map[string]string} "Messages exported successfully"
// @Failure 400 {object} Response "Invalid language"
// @Failure 401 {object} Response "Unauthorized"
// @Failure 403 {object} Response "Forbidden - Admin access required"
// @Security ApiKeyAuth
// @Router /api/v1/admin/i18n/languages/{language}/export [get]
func (server *Server) exportMessages(ctx *gin.Context) {
	langParam := ctx.Param("language")
	lang := i18n.SupportedLanguage(langParam)

	if !i18n.GetI18n().IsSupported(lang) {
		ErrorResponse(ctx, http.StatusBadRequest, "invalid_request", nil)
		return
	}
	i18nInstance := i18n.GetI18n()

	// Get all messages for the language by trying to access the internal structure
	// This is a simplified approach - in a real implementation, you might want to add a GetAllMessages method
	allMessages := make(map[string]string)

	// For demonstration, we'll export some sample message keys
	// In a real implementation, you would need to expose the internal messages map
	testKeys := []string{
		"success", "error", "login_successful", "user_created_successfully",
		"exam_created_successfully", "word_created_successfully", "invalid_request",
	}

	for _, key := range testKeys {
		message := i18nInstance.GetMessage(lang, "%s", key)
		if message != key { // Only include if translation exists
			allMessages[key] = message
		}
	}

	logger.Info("Messages for language '%s' exported by admin", lang)

	response := gin.H{
		"language":      string(lang),
		"message_count": len(allMessages),
		"messages":      allMessages,
		"exported_at":   "now", // You might want to use time.Now()
	}

	SuccessResponse(ctx, http.StatusOK, "retrieved_successfully", response)
}
