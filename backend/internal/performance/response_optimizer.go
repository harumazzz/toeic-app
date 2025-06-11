package performance

import (
	"encoding/json"
	"strings"

	"github.com/gin-gonic/gin"
	db "github.com/toeic-app/internal/db/sqlc"
)

// ResponseOptimizer handles response optimization including field selection
type ResponseOptimizer struct {
	objectPool *ObjectPool
}

// NewResponseOptimizer creates a new response optimizer
func NewResponseOptimizer() *ResponseOptimizer {
	return &ResponseOptimizer{
		objectPool: NewObjectPool(),
	}
}

// FieldSelector allows clients to specify which fields they want in the response
type FieldSelector struct {
	Fields []string `form:"fields"`
}

// OptimizedWordResponse represents a word response with optional field selection
type OptimizedWordResponse struct {
	ID            *int32      `json:"id,omitempty"`
	Word          *string     `json:"word,omitempty"`
	Pronounce     *string     `json:"pronounce,omitempty"`
	Level         *int32      `json:"level,omitempty"`
	DescriptLevel *string     `json:"descript_level,omitempty"`
	ShortMean     *string     `json:"short_mean,omitempty"`
	Means         interface{} `json:"means,omitempty"`
	Snym          interface{} `json:"snym,omitempty"`
	Freq          *float32    `json:"freq,omitempty"`
	Conjugation   interface{} `json:"conjugation,omitempty"`
}

// OptimizedGrammarResponse represents a grammar response with optional field selection
type OptimizedGrammarResponse struct {
	ID         *int32      `json:"id,omitempty"`
	Title      *string     `json:"title,omitempty"`
	GrammarKey *string     `json:"grammar_key,omitempty"`
	Level      *int32      `json:"level,omitempty"`
	Tag        interface{} `json:"tag,omitempty"`
	Contents   *string     `json:"contents,omitempty"`
	Examples   interface{} `json:"examples,omitempty"`
}

// OptimizeWordResponse creates an optimized word response with field selection
func (ro *ResponseOptimizer) OptimizeWordResponse(word db.Word, fields []string) interface{} {
	if len(fields) == 0 {
		// Return full response if no field selection
		return WordResponse{
			ID:            word.ID,
			Word:          word.Word,
			Pronounce:     word.Pronounce,
			Level:         word.Level,
			DescriptLevel: word.DescriptLevel,
			ShortMean:     word.ShortMean,
			Means:         word.Means.RawMessage,
			Snym:          word.Snym.RawMessage,
			Freq:          word.Freq,
			Conjugation:   word.Conjugation.RawMessage,
		}
	}

	// Create optimized response with only requested fields
	response := OptimizedWordResponse{}
	fieldSet := make(map[string]bool)
	for _, field := range fields {
		fieldSet[strings.ToLower(field)] = true
	}

	if fieldSet["id"] {
		response.ID = &word.ID
	}
	if fieldSet["word"] {
		response.Word = &word.Word
	}
	if fieldSet["pronounce"] {
		response.Pronounce = &word.Pronounce
	}
	if fieldSet["level"] {
		response.Level = &word.Level
	}
	if fieldSet["descript_level"] {
		response.DescriptLevel = &word.DescriptLevel
	}
	if fieldSet["short_mean"] {
		response.ShortMean = &word.ShortMean
	}
	if fieldSet["means"] {
		response.Means = word.Means.RawMessage
	}
	if fieldSet["snym"] {
		response.Snym = word.Snym.RawMessage
	}
	if fieldSet["freq"] {
		response.Freq = &word.Freq
	}
	if fieldSet["conjugation"] {
		response.Conjugation = word.Conjugation.RawMessage
	}

	return response
}

// OptimizeWordsResponse creates optimized word responses with field selection
func (ro *ResponseOptimizer) OptimizeWordsResponse(words []db.Word, fields []string) interface{} {
	if len(fields) == 0 {
		// Use object pool for better performance
		return ro.objectPool.ConvertWordsToResponses(words)
	}

	// Create optimized responses with field selection
	responses := make([]OptimizedWordResponse, len(words))
	fieldSet := make(map[string]bool)
	for _, field := range fields {
		fieldSet[strings.ToLower(field)] = true
	}

	for i, word := range words {
		response := OptimizedWordResponse{}

		if fieldSet["id"] {
			response.ID = &word.ID
		}
		if fieldSet["word"] {
			response.Word = &word.Word
		}
		if fieldSet["pronounce"] {
			response.Pronounce = &word.Pronounce
		}
		if fieldSet["level"] {
			response.Level = &word.Level
		}
		if fieldSet["descript_level"] {
			response.DescriptLevel = &word.DescriptLevel
		}
		if fieldSet["short_mean"] {
			response.ShortMean = &word.ShortMean
		}
		if fieldSet["means"] {
			response.Means = word.Means.RawMessage
		}
		if fieldSet["snym"] {
			response.Snym = word.Snym.RawMessage
		}
		if fieldSet["freq"] {
			response.Freq = &word.Freq
		}
		if fieldSet["conjugation"] {
			response.Conjugation = word.Conjugation.RawMessage
		}

		responses[i] = response
	}

	return responses
}

// CompressResponse compresses JSON response if it's large enough
func (ro *ResponseOptimizer) CompressResponse(data interface{}) ([]byte, error) {
	jsonData, err := json.Marshal(data)
	if err != nil {
		return nil, err
	}

	// If response is small, return as-is
	if len(jsonData) < 1024 {
		return jsonData, nil
	}

	// For larger responses, the gzip middleware will handle compression
	return jsonData, nil
}

// GetFieldsFromContext extracts field selection from Gin context
func (ro *ResponseOptimizer) GetFieldsFromContext(ctx *gin.Context) []string {
	var selector FieldSelector
	if err := ctx.ShouldBindQuery(&selector); err != nil {
		return nil
	}

	// Parse comma-separated fields
	if len(selector.Fields) == 1 && strings.Contains(selector.Fields[0], ",") {
		return strings.Split(selector.Fields[0], ",")
	}

	return selector.Fields
}

// BatchOptimizeWords optimizes multiple word responses efficiently
func (ro *ResponseOptimizer) BatchOptimizeWords(words []db.Word, fields []string, batchSize int) interface{} {
	if len(words) <= batchSize {
		return ro.OptimizeWordsResponse(words, fields)
	}

	// Process in batches for very large datasets
	var allResponses []interface{}
	for i := 0; i < len(words); i += batchSize {
		end := i + batchSize
		if end > len(words) {
			end = len(words)
		}

		batch := words[i:end]
		batchResponse := ro.OptimizeWordsResponse(batch, fields)
		allResponses = append(allResponses, batchResponse)
	}

	return allResponses
}

// CalculateResponseSize estimates the size of a response for logging/monitoring
func (ro *ResponseOptimizer) CalculateResponseSize(data interface{}) int {
	jsonData, err := json.Marshal(data)
	if err != nil {
		return 0
	}
	return len(jsonData)
}

// CreateMinimalWordResponse creates a minimal word response for very fast responses
func (ro *ResponseOptimizer) CreateMinimalWordResponse(word db.Word) map[string]interface{} {
	return map[string]interface{}{
		"id":         word.ID,
		"word":       word.Word,
		"short_mean": word.ShortMean,
		"level":      word.Level,
	}
}

// CreateMinimalWordsResponse creates minimal word responses for search suggestions
func (ro *ResponseOptimizer) CreateMinimalWordsResponse(words []db.Word) []map[string]interface{} {
	responses := make([]map[string]interface{}, len(words))
	for i, word := range words {
		responses[i] = ro.CreateMinimalWordResponse(word)
	}
	return responses
}

// OptimizeByResponseType returns different response formats based on client preferences
func (ro *ResponseOptimizer) OptimizeByResponseType(ctx *gin.Context, words []db.Word) interface{} {
	responseType := ctx.Query("response_type")
	fields := ro.GetFieldsFromContext(ctx)

	switch responseType {
	case "minimal":
		return ro.CreateMinimalWordsResponse(words)
	case "fields":
		return ro.OptimizeWordsResponse(words, fields)
	case "batch":
		batchSize := 50 // Default batch size
		return ro.BatchOptimizeWords(words, fields, batchSize)
	default:
		return ro.OptimizeWordsResponse(words, fields)
	}
}
