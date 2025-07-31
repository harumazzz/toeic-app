package ai

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/toeic-app/internal/logger"
)

// TOEICBand represents the different TOEIC proficiency levels
type TOEICBand string

const (
	// TOEIC Writing Score Bands
	BandLevel1  TOEICBand = "1"  // 0-30 points - Novice Low
	BandLevel2  TOEICBand = "2"  // 40-50 points - Novice Mid
	BandLevel3  TOEICBand = "3"  // 60-70 points - Novice High
	BandLevel4  TOEICBand = "4"  // 80-90 points - Intermediate Low
	BandLevel5  TOEICBand = "5"  // 100-110 points - Intermediate Mid
	BandLevel6  TOEICBand = "6"  // 120-130 points - Intermediate High
	BandLevel7  TOEICBand = "7"  // 140-150 points - Advanced Low
	BandLevel8  TOEICBand = "8"  // 160-170 points - Advanced Mid
	BandLevel9  TOEICBand = "9"  // 180-190 points - Advanced High
	BandLevel10 TOEICBand = "10" // 200 points - Superior
)

// ScoringCriteria represents the criteria used for TOEIC writing assessment
type ScoringCriteria struct {
	Grammar      string `json:"grammar"`
	Vocabulary   string `json:"vocabulary"`
	Organization string `json:"organization"`
	Development  string `json:"development"`
	TaskResponse string `json:"task_response"`
	LanguageUse  string `json:"language_use"`
	Overall      string `json:"overall"`
}

// AIScoreResponse represents the AI scoring response
type AIScoreResponse struct {
	Score       int             `json:"score"`       // 0-200 TOEIC writing score
	Band        TOEICBand       `json:"band"`        // TOEIC band level
	Feedback    ScoringCriteria `json:"feedback"`    // Detailed feedback
	Suggestions []string        `json:"suggestions"` // Improvement suggestions
	Confidence  float64         `json:"confidence"`  // AI confidence score (0-1)
	ProcessedAt time.Time       `json:"processed_at"`
}

// AIScoreRequest represents the request to score writing
type AIScoreRequest struct {
	Text     string `json:"text"`
	PromptID *int32 `json:"prompt_id,omitempty"`
	UserID   int32  `json:"user_id"`
}

// AISpeakingRequest represents the request to generate speaking response
type AISpeakingRequest struct {
	UserMessage         string `json:"user_message"`
	ConversationContext string `json:"conversation_context"`
	Difficulty          string `json:"difficulty,omitempty"`
}

// AISpeakingResponse represents the AI speaking response
type AISpeakingResponse struct {
	Response    string    `json:"response"`
	ProcessedAt time.Time `json:"processed_at"`
}

// OpenAI API structures
type OpenAIRequest struct {
	Model       string    `json:"model"`
	Messages    []Message `json:"messages"`
	MaxTokens   int       `json:"max_tokens"`
	Temperature float64   `json:"temperature"`
}

type Message struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type OpenAIResponse struct {
	Choices []Choice `json:"choices"`
	Usage   Usage    `json:"usage"`
}

type Choice struct {
	Message      Message `json:"message"`
	FinishReason string  `json:"finish_reason"`
}

type Usage struct {
	PromptTokens     int `json:"prompt_tokens"`
	CompletionTokens int `json:"completion_tokens"`
	TotalTokens      int `json:"total_tokens"`
}

// Usage tracking for cost monitoring
type UsageStats struct {
	TotalRequests    int       `json:"total_requests"`
	TotalTokensUsed  int       `json:"total_tokens_used"`
	EstimatedCostUSD float64   `json:"estimated_cost_usd"`
	LastRequestTime  time.Time `json:"last_request_time"`
}

// ScoringService handles AI-based writing scoring
type ScoringService struct {
	apiKey     string
	apiURL     string
	httpClient *http.Client
	timeout    time.Duration
	usageStats UsageStats
}

// NewScoringService creates a new instance of the AI scoring service
func NewScoringService(apiKey, apiURL string) *ScoringService {
	if apiURL == "" {
		apiURL = "https://api.openai.com/v1/chat/completions"
	}
	return &ScoringService{
		apiKey: apiKey,
		apiURL: apiURL,
		httpClient: &http.Client{
			Timeout: 60 * time.Second,
		},
		timeout: 60 * time.Second,
	}
}

// ScoreWriting scores the given text using OpenAI ChatGPT and returns TOEIC band assessment
func (s *ScoringService) ScoreWriting(ctx context.Context, req AIScoreRequest) (*AIScoreResponse, error) {
	// Use OpenAI API to score the writing
	return s.ScoreWritingWithOpenAI(ctx, req)
}

// ScoreWritingWithOpenAI scores writing using OpenAI ChatGPT API
func (s *ScoringService) ScoreWritingWithOpenAI(ctx context.Context, req AIScoreRequest) (*AIScoreResponse, error) {
	// Create the prompt for TOEIC writing assessment
	prompt := s.createTOEICPrompt(req.Text)
	// Prepare OpenAI request
	openAIReq := OpenAIRequest{
		Model: "gpt-3.5-turbo", // Using GPT-3.5-turbo for cost efficiency
		Messages: []Message{
			{
				Role:    "system",
				Content: `You are an expert TOEIC writing assessor. Evaluate the writing sample and provide a detailed assessment following TOEIC writing scoring criteria. Respond in JSON format with the exact structure specified.`,
			},
			{
				Role:    "user",
				Content: prompt,
			},
		},
		MaxTokens:   1000, // Reduced token limit to control costs
		Temperature: 0.3,
	}

	// Convert to JSON
	requestBody, err := json.Marshal(openAIReq)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %v", err)
	}

	// Create HTTP request
	httpReq, err := http.NewRequestWithContext(ctx, "POST", s.apiURL, bytes.NewBuffer(requestBody))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %v", err)
	}

	// Set headers
	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("Authorization", "Bearer "+s.apiKey)

	// Make the request
	resp, err := s.httpClient.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("failed to make request: %v", err)
	}
	defer resp.Body.Close()

	// Read response
	responseBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %v", err)
	}

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("OpenAI API error (status %d): %s", resp.StatusCode, string(responseBody))
	}

	// Parse OpenAI response
	var openAIResp OpenAIResponse
	if err := json.Unmarshal(responseBody, &openAIResp); err != nil {
		return nil, fmt.Errorf("failed to parse OpenAI response: %v", err)
	}
	if len(openAIResp.Choices) == 0 {
		return nil, fmt.Errorf("no choices in OpenAI response")
	}

	// Track usage and costs for monitoring
	s.updateUsageStats(openAIResp.Usage)

	// Parse the AI assessment from the response
	aiAssessment := openAIResp.Choices[0].Message.Content
	response, err := s.parseAIAssessment(aiAssessment)
	if err != nil {
		// Fallback to basic scoring if AI parsing fails
		logger.Warn("Failed to parse AI assessment, falling back to basic scoring: %v", err)
		return s.fallbackScoring(req)
	}

	response.ProcessedAt = time.Now()
	logger.Info("Scored writing submission for user %d using OpenAI: Score=%d, Band=%s", req.UserID, response.Score, response.Band)

	// Update usage statistics
	s.usageStats.TotalRequests++
	s.usageStats.TotalTokensUsed += openAIResp.Usage.TotalTokens
	s.usageStats.LastRequestTime = time.Now()

	// Estimate cost (assuming $0.0004 per token as an example)
	s.usageStats.EstimatedCostUSD = float64(s.usageStats.TotalTokensUsed) * 0.0004

	return response, nil
}

// calculateBasicScore calculates a basic score based on text analysis
func (s *ScoringService) calculateBasicScore(text string, wordCount, _ int, avgWordsPerSentence float64) int {
	score := 100 // Base score

	// Word count factor (optimal range: 150-300 words)
	if wordCount < 50 {
		score -= 40
	} else if wordCount < 100 {
		score -= 20
	} else if wordCount > 400 {
		score -= 10
	} else if wordCount >= 150 && wordCount <= 300 {
		score += 20
	}

	// Sentence structure (optimal: 12-20 words per sentence)
	if avgWordsPerSentence < 8 {
		score -= 15
	} else if avgWordsPerSentence > 25 {
		score -= 20
	} else if avgWordsPerSentence >= 12 && avgWordsPerSentence <= 20 {
		score += 15
	}

	// Basic complexity checks
	if strings.Contains(strings.ToLower(text), "however") ||
		strings.Contains(strings.ToLower(text), "moreover") ||
		strings.Contains(strings.ToLower(text), "furthermore") {
		score += 10
	}

	// Grammar and punctuation checks (basic)
	if strings.Count(text, ",") > wordCount/20 {
		score += 5
	}

	// Ensure score is within valid range
	if score < 0 {
		score = 0
	} else if score > 200 {
		score = 200
	}

	return score
}

// scoreToBand converts a numeric score to TOEIC band
func (s *ScoringService) scoreToBand(score int) TOEICBand {
	switch {
	case score >= 200:
		return BandLevel10
	case score >= 180:
		return BandLevel9
	case score >= 160:
		return BandLevel8
	case score >= 140:
		return BandLevel7
	case score >= 120:
		return BandLevel6
	case score >= 100:
		return BandLevel5
	case score >= 80:
		return BandLevel4
	case score >= 60:
		return BandLevel3
	case score >= 40:
		return BandLevel2
	default:
		return BandLevel1
	}
}

// generateFeedback creates detailed feedback based on text analysis
func (s *ScoringService) generateFeedback(_ string, wordCount, sentenceCount int, avgWordsPerSentence float64, score int) ScoringCriteria {
	feedback := ScoringCriteria{}

	// Grammar feedback
	if score >= 160 {
		feedback.Grammar = "Excellent grammatical control with minor errors that do not impede communication."
	} else if score >= 120 {
		feedback.Grammar = "Good grammatical control with some errors that rarely impede communication."
	} else if score >= 80 {
		feedback.Grammar = "Fair grammatical control with errors that sometimes impede communication."
	} else {
		feedback.Grammar = "Limited grammatical control with frequent errors that impede communication."
	}

	// Vocabulary feedback
	if score >= 160 {
		feedback.Vocabulary = "Wide range of vocabulary used accurately and appropriately."
	} else if score >= 120 {
		feedback.Vocabulary = "Good range of vocabulary with occasional inaccuracies."
	} else if score >= 80 {
		feedback.Vocabulary = "Limited vocabulary with some repetition and basic word choice."
	} else {
		feedback.Vocabulary = "Very limited vocabulary with frequent repetition."
	}

	// Organization feedback
	if sentenceCount > 1 && avgWordsPerSentence >= 12 && avgWordsPerSentence <= 20 {
		feedback.Organization = "Well-organized response with clear structure and logical flow."
	} else if sentenceCount > 1 {
		feedback.Organization = "Generally well-organized with minor structural issues."
	} else {
		feedback.Organization = "Limited organization with unclear structure."
	}

	// Development feedback
	if wordCount >= 150 {
		feedback.Development = "Ideas are well-developed with adequate supporting details."
	} else if wordCount >= 100 {
		feedback.Development = "Ideas are partially developed with some supporting details."
	} else {
		feedback.Development = "Ideas are minimally developed with insufficient details."
	}

	// Task response feedback
	if wordCount >= 100 {
		feedback.TaskResponse = "Response addresses the task requirements appropriately."
	} else {
		feedback.TaskResponse = "Response partially addresses the task requirements."
	}

	// Language use feedback
	feedback.LanguageUse = fmt.Sprintf("Text contains %d words in %d sentences (avg: %.1f words/sentence).",
		wordCount, sentenceCount, avgWordsPerSentence)

	// Overall feedback
	band := s.scoreToBand(score)
	feedback.Overall = fmt.Sprintf("TOEIC Writing Band %s performance. Score: %d/200.", band, score)

	return feedback
}

// generateSuggestions creates improvement suggestions based on the score and analysis
func (s *ScoringService) generateSuggestions(text string, score int, band TOEICBand) []string {
	suggestions := []string{}

	wordCount := len(strings.Fields(text))

	if wordCount < 100 {
		suggestions = append(suggestions, "Aim for 150-300 words to fully develop your ideas.")
	}

	if score < 160 {
		suggestions = append(suggestions, "Use more varied sentence structures to improve your writing.")
		suggestions = append(suggestions, "Include transition words (however, moreover, furthermore) to connect ideas.")
	}

	if score < 120 {
		suggestions = append(suggestions, "Focus on basic grammar accuracy, especially verb tenses.")
		suggestions = append(suggestions, "Expand your vocabulary by using more specific and varied words.")
	}

	if score < 80 {
		suggestions = append(suggestions, "Practice writing complete sentences with proper punctuation.")
		suggestions = append(suggestions, "Review basic sentence structure and word order.")
	}

	// Band-specific suggestions
	switch band {
	case BandLevel1, BandLevel2, BandLevel3:
		suggestions = append(suggestions, "Focus on basic sentence formation and common vocabulary.")
	case BandLevel4, BandLevel5:
		suggestions = append(suggestions, "Work on connecting ideas between sentences and paragraphs.")
	case BandLevel6, BandLevel7:
		suggestions = append(suggestions, "Practice using complex sentence structures and advanced vocabulary.")
	case BandLevel8, BandLevel9:
		suggestions = append(suggestions, "Focus on precise word choice and sophisticated language use.")
	case BandLevel10:
		suggestions = append(suggestions, "Excellent work! Continue practicing to maintain this high level.")
	}

	return suggestions
}

// IsHealthy checks if the scoring service is operational
func (s *ScoringService) IsHealthy() bool {
	// For the mock service, always return true
	// In production, this would check API connectivity
	return true
}

// GetStats returns service statistics
func (s *ScoringService) GetStats() map[string]interface{} {
	return map[string]interface{}{
		"service":     "AI Writing Scoring",
		"version":     "1.0.0",
		"status":      "active",
		"last_check":  time.Now().Format(time.RFC3339),
		"api_url":     s.apiURL,
		"timeout":     s.timeout.String(),
		"usage_stats": s.usageStats,
	}
}

// createTOEICPrompt creates a detailed prompt for TOEIC writing assessment
func (s *ScoringService) createTOEICPrompt(text string) string {
	return fmt.Sprintf(`Please evaluate this TOEIC writing sample according to official TOEIC writing assessment criteria and provide a score from 0-200.

WRITING SAMPLE:
%s

Please assess the writing based on these TOEIC criteria:
1. Grammar - accuracy and variety of grammatical structures
2. Vocabulary - range, accuracy, and appropriateness of word choice
3. Organization - logical structure and coherence
4. Development - how well ideas are developed and supported
5. Task Response - how well the writing addresses the task requirements
6. Language Use - overall fluency and natural expression

SCORING BANDS:
- Band 1 (0-30): Novice Low
- Band 2 (40-50): Novice Mid
- Band 3 (60-70): Novice High
- Band 4 (80-90): Intermediate Low
- Band 5 (100-110): Intermediate Mid
- Band 6 (120-130): Intermediate High
- Band 7 (140-150): Advanced Low
- Band 8 (160-170): Advanced Mid
- Band 9 (180-190): Advanced High
- Band 10 (200): Superior

Respond in JSON format:
{
  "score": [numeric score 0-200],
  "band": "[1-10]",
  "feedback": {
    "grammar": "[detailed feedback on grammar]",
    "vocabulary": "[detailed feedback on vocabulary]",
    "organization": "[detailed feedback on organization]",
    "development": "[detailed feedback on development]",
    "task_response": "[detailed feedback on task response]",
    "language_use": "[detailed feedback on language use]",
    "overall": "[overall assessment summary]"
  },
  "suggestions": [
    "[specific improvement suggestion 1]",
    "[specific improvement suggestion 2]",
    "[specific improvement suggestion 3]"
  ],
  "confidence": [0.0-1.0]
}`, text)
}

// parseAIAssessment parses the AI response and converts it to AIScoreResponse
func (s *ScoringService) parseAIAssessment(assessment string) (*AIScoreResponse, error) {
	// Try to extract JSON from the response
	assessment = strings.TrimSpace(assessment)

	// Find JSON content (sometimes AI wraps JSON in markdown)
	start := strings.Index(assessment, "{")
	end := strings.LastIndex(assessment, "}")

	if start == -1 || end == -1 || start >= end {
		return nil, fmt.Errorf("no valid JSON found in AI response")
	}

	jsonStr := assessment[start : end+1]

	// Parse the JSON response
	var aiResp struct {
		Score       int               `json:"score"`
		Band        string            `json:"band"`
		Feedback    map[string]string `json:"feedback"`
		Suggestions []string          `json:"suggestions"`
		Confidence  float64           `json:"confidence"`
	}

	if err := json.Unmarshal([]byte(jsonStr), &aiResp); err != nil {
		return nil, fmt.Errorf("failed to parse AI JSON response: %v", err)
	}

	// Validate and convert band
	band := s.validateBand(aiResp.Band)

	// Validate score
	score := aiResp.Score
	if score < 0 {
		score = 0
	} else if score > 200 {
		score = 200
	}

	// Convert feedback map to ScoringCriteria
	feedback := ScoringCriteria{
		Grammar:      getOrDefault(aiResp.Feedback, "grammar", "No feedback provided"),
		Vocabulary:   getOrDefault(aiResp.Feedback, "vocabulary", "No feedback provided"),
		Organization: getOrDefault(aiResp.Feedback, "organization", "No feedback provided"),
		Development:  getOrDefault(aiResp.Feedback, "development", "No feedback provided"),
		TaskResponse: getOrDefault(aiResp.Feedback, "task_response", "No feedback provided"),
		LanguageUse:  getOrDefault(aiResp.Feedback, "language_use", "No feedback provided"),
		Overall:      getOrDefault(aiResp.Feedback, "overall", "No feedback provided"),
	}

	// Validate confidence
	confidence := aiResp.Confidence
	if confidence < 0 {
		confidence = 0
	} else if confidence > 1 {
		confidence = 1
	}

	return &AIScoreResponse{
		Score:       score,
		Band:        band,
		Feedback:    feedback,
		Suggestions: aiResp.Suggestions,
		Confidence:  confidence,
	}, nil
}

// fallbackScoring provides basic scoring when AI assessment fails
func (s *ScoringService) fallbackScoring(req AIScoreRequest) (*AIScoreResponse, error) {
	// Analyze the text for basic metrics
	wordCount := len(strings.Fields(req.Text))
	sentenceCount := strings.Count(req.Text, ".") + strings.Count(req.Text, "!") + strings.Count(req.Text, "?")
	if sentenceCount == 0 {
		sentenceCount = 1
	}

	avgWordsPerSentence := float64(wordCount) / float64(sentenceCount)

	// Calculate a basic score based on text metrics
	score := s.calculateBasicScore(req.Text, wordCount, sentenceCount, avgWordsPerSentence)

	// Determine TOEIC band based on score
	band := s.scoreToBand(score)

	// Generate feedback based on analysis
	feedback := s.generateFeedback(req.Text, wordCount, sentenceCount, avgWordsPerSentence, score)

	// Generate improvement suggestions
	suggestions := s.generateSuggestions(req.Text, score, band)

	response := &AIScoreResponse{
		Score:       score,
		Band:        band,
		Feedback:    feedback,
		Suggestions: suggestions,
		Confidence:  0.60, // Lower confidence for basic scoring
		ProcessedAt: time.Now(),
	}

	logger.Info("Used fallback scoring for user %d: Score=%d, Band=%s", req.UserID, score, band)

	return response, nil
}

// updateUsageStats tracks token usage and estimates costs
func (s *ScoringService) updateUsageStats(usage Usage) {
	s.usageStats.TotalRequests++
	s.usageStats.TotalTokensUsed += usage.TotalTokens
	s.usageStats.LastRequestTime = time.Now()

	// GPT-3.5-turbo pricing (as of 2024): $0.001 per 1K input tokens, $0.002 per 1K output tokens
	inputCost := float64(usage.PromptTokens) / 1000.0 * 0.001
	outputCost := float64(usage.CompletionTokens) / 1000.0 * 0.002
	requestCost := inputCost + outputCost

	s.usageStats.EstimatedCostUSD += requestCost

	// Log the cost information for monitoring
	logger.Info("OpenAI API usage - Tokens: %d (input: %d, output: %d), Cost: $%.4f, Total cost: $%.4f",
		usage.TotalTokens, usage.PromptTokens, usage.CompletionTokens, requestCost, s.usageStats.EstimatedCostUSD)
}

// GetUsageStats returns the current usage statistics
func (s *ScoringService) GetUsageStats() UsageStats {
	return s.usageStats
}

// Helper functions
func getOrDefault(m map[string]string, key, defaultValue string) string {
	if value, exists := m[key]; exists && value != "" {
		return value
	}
	return defaultValue
}

func (s *ScoringService) validateBand(bandStr string) TOEICBand {
	switch bandStr {
	case "1":
		return BandLevel1
	case "2":
		return BandLevel2
	case "3":
		return BandLevel3
	case "4":
		return BandLevel4
	case "5":
		return BandLevel5
	case "6":
		return BandLevel6
	case "7":
		return BandLevel7
	case "8":
		return BandLevel8
	case "9":
		return BandLevel9
	case "10":
		return BandLevel10
	default:
		// Default to band 4 if invalid
		return BandLevel4
	}
}

// GenerateSpeakingResponse generates an AI response for speaking practice
func (s *ScoringService) GenerateSpeakingResponse(ctx context.Context, req AISpeakingRequest) (*AISpeakingResponse, error) {
	// Create the prompt for TOEIC speaking conversation
	prompt := s.createSpeakingPrompt(req.UserMessage, req.ConversationContext, req.Difficulty)
	
	// Prepare OpenAI request
	openAIReq := OpenAIRequest{
		Model: "gpt-3.5-turbo",
		Messages: []Message{
			{
				Role:    "system",
				Content: `You are a TOEIC speaking practice assistant. Help the user practice English conversation with appropriate responses. Keep responses conversational, encouraging, and suitable for TOEIC speaking practice. Ask follow-up questions to continue the conversation naturally.`,
			},
			{
				Role:    "user",
				Content: prompt,
			},
		},
		MaxTokens:   500,
		Temperature: 0.7,
	}

	// Convert to JSON
	requestBody, err := json.Marshal(openAIReq)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %v", err)
	}

	// Create HTTP request
	httpReq, err := http.NewRequestWithContext(ctx, "POST", s.apiURL, bytes.NewBuffer(requestBody))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %v", err)
	}

	// Set headers
	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("Authorization", "Bearer "+s.apiKey)

	// Make the request
	resp, err := s.httpClient.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("failed to make request: %v", err)
	}
	defer resp.Body.Close()

	// Read response
	responseBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %v", err)
	}

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("OpenAI API error (status %d): %s", resp.StatusCode, string(responseBody))
	}

	// Parse OpenAI response
	var openAIResp OpenAIResponse
	if err := json.Unmarshal(responseBody, &openAIResp); err != nil {
		return nil, fmt.Errorf("failed to parse OpenAI response: %v", err)
	}
	
	if len(openAIResp.Choices) == 0 {
		return nil, fmt.Errorf("no choices in OpenAI response")
	}

	// Track usage
	s.updateUsageStats(openAIResp.Usage)

	return &AISpeakingResponse{
		Response:    openAIResp.Choices[0].Message.Content,
		ProcessedAt: time.Now(),
	}, nil
}

// createSpeakingPrompt creates a prompt for speaking conversation
func (s *ScoringService) createSpeakingPrompt(userMessage, conversationContext, difficulty string) string {
	if difficulty == "" {
		difficulty = "intermediate"
	}

	prompt := fmt.Sprintf(`Context: You are helping a student practice TOEIC speaking skills at %s level.

Previous conversation:
%s

User's latest message: %s

Please provide a natural, encouraging response that:
1. Acknowledges what the user said
2. Asks a follow-up question to continue the conversation
3. Uses vocabulary appropriate for %s level
4. Helps the user practice speaking skills
5. Keeps the tone friendly and supportive

Respond naturally as if you're having a real conversation.`, 
		difficulty, 
		conversationContext, 
		userMessage, 
		difficulty)

	return prompt
}
