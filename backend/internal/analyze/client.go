package analyze

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/toeic-app/internal/logger"
)

// AnalyzeClient represents a client for the analyze service
type AnalyzeClient struct {
	baseURL    string
	httpClient *http.Client
	timeout    time.Duration
}

// Suggestion represents a word suggestion with level and definition
type Suggestion struct {
	Word       string `json:"word"`
	Level      string `json:"level"`
	Definition string `json:"definition"`
}

// WordAnalysis represents the analysis result for a single word
type WordAnalysis struct {
	Word        string        `json:"word"`
	Level       string        `json:"level"`
	Count       int           `json:"count"`
	Suggestions *[]Suggestion `json:"suggestions,omitempty"`
}

// TextAnalysisRequest represents the request payload for text analysis
type TextAnalysisRequest struct {
	Text            string `json:"text" binding:"required"`
	MinSynonymLevel string `json:"min_synonym_level,omitempty"`
}

// TextAnalysisResponse represents the response from text analysis
type TextAnalysisResponse struct {
	Words []WordAnalysis `json:"words"`
}

// HealthResponse represents the health check response
type HealthResponse struct {
	Status           string `json:"status"`
	WordLevelsLoaded bool   `json:"word_levels_loaded"`
	WordCount        int    `json:"word_count"`
}

// AnalysisResult represents the result of an asynchronous analysis
type AnalysisResult struct {
	UserID    int32                 `json:"user_id"`
	Text      string                `json:"text"`
	Result    *TextAnalysisResponse `json:"result,omitempty"`
	Error     string                `json:"error,omitempty"`
	Timestamp time.Time             `json:"timestamp"`
}

// NewAnalyzeClient creates a new analyze service client
func NewAnalyzeClient(baseURL string, timeout time.Duration) *AnalyzeClient {
	if timeout == 0 {
		timeout = 30 * time.Second
	}

	return &AnalyzeClient{
		baseURL: baseURL,
		httpClient: &http.Client{
			Timeout: timeout,
		},
		timeout: timeout,
	}
}

// AnalyzeText performs synchronous text analysis
func (c *AnalyzeClient) AnalyzeText(ctx context.Context, request TextAnalysisRequest) (*TextAnalysisResponse, error) {
	requestBody, err := json.Marshal(request)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	url := fmt.Sprintf("%s/analyze", c.baseURL)
	req, err := http.NewRequestWithContext(ctx, "POST", url, bytes.NewBuffer(requestBody))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("analyze service returned status %d: %s", resp.StatusCode, string(body))
	}

	var words []WordAnalysis
	if err := json.NewDecoder(resp.Body).Decode(&words); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return &TextAnalysisResponse{Words: words}, nil
}

// AnalyzeTextAsync performs asynchronous text analysis using goroutines
func (c *AnalyzeClient) AnalyzeTextAsync(ctx context.Context, userID int32, request TextAnalysisRequest, resultChan chan<- AnalysisResult) {
	go func() {
		defer close(resultChan)

		logger.Debug("Starting async text analysis for user %d", userID)
		start := time.Now()

		result := AnalysisResult{
			UserID:    userID,
			Text:      request.Text,
			Timestamp: time.Now(),
		}

		// Perform the analysis
		analysisResult, err := c.AnalyzeText(ctx, request)
		if err != nil {
			logger.Error("Failed to analyze text for user %d: %v", userID, err)
			result.Error = err.Error()
		} else {
			result.Result = analysisResult
			logger.Debug("Text analysis completed for user %d in %v", userID, time.Since(start))
		}

		// Send result to channel
		select {
		case resultChan <- result:
			logger.Debug("Analysis result sent to channel for user %d", userID)
		case <-ctx.Done():
			logger.Warn("Context cancelled while sending analysis result for user %d", userID)
		}
	}()
}

// AnalyzeTextBatch performs batch analysis of multiple texts
func (c *AnalyzeClient) AnalyzeTextBatch(ctx context.Context, userID int32, requests []TextAnalysisRequest, resultChan chan<- []AnalysisResult) {
	go func() {
		defer close(resultChan)

		logger.Debug("Starting batch text analysis for user %d with %d texts", userID, len(requests))
		start := time.Now()

		results := make([]AnalysisResult, len(requests))

		// Use a semaphore to limit concurrent requests to the analyze service
		semaphore := make(chan struct{}, 3) // Limit to 3 concurrent requests

		// Use a channel to collect results in order
		resultsChan := make(chan struct {
			index  int
			result AnalysisResult
		}, len(requests))

		// Process each request concurrently
		for i, request := range requests {
			go func(index int, req TextAnalysisRequest) {
				defer func() { <-semaphore }()
				semaphore <- struct{}{} // Acquire semaphore

				result := AnalysisResult{
					UserID:    userID,
					Text:      req.Text,
					Timestamp: time.Now(),
				}

				analysisResult, err := c.AnalyzeText(ctx, req)
				if err != nil {
					logger.Error("Failed to analyze text %d for user %d: %v", index, userID, err)
					result.Error = err.Error()
				} else {
					result.Result = analysisResult
				}

				select {
				case resultsChan <- struct {
					index  int
					result AnalysisResult
				}{index, result}:
				case <-ctx.Done():
					return
				}
			}(i, request)
		}

		// Collect results
		for i := 0; i < len(requests); i++ {
			select {
			case res := <-resultsChan:
				results[res.index] = res.result
			case <-ctx.Done():
				logger.Warn("Context cancelled during batch analysis for user %d", userID)
				return
			}
		}

		logger.Debug("Batch text analysis completed for user %d in %v", userID, time.Since(start))

		// Send results to channel
		select {
		case resultChan <- results:
			logger.Debug("Batch analysis results sent to channel for user %d", userID)
		case <-ctx.Done():
			logger.Warn("Context cancelled while sending batch analysis results for user %d", userID)
		}
	}()
}

// HealthCheck checks if the analyze service is healthy
func (c *AnalyzeClient) HealthCheck(ctx context.Context) (*HealthResponse, error) {
	url := fmt.Sprintf("%s/health", c.baseURL)
	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("health check failed with status %d", resp.StatusCode)
	}

	var health HealthResponse
	if err := json.NewDecoder(resp.Body).Decode(&health); err != nil {
		return nil, fmt.Errorf("failed to decode health response: %w", err)
	}

	return &health, nil
}

// IsHealthy performs a simple health check and returns a boolean
func (c *AnalyzeClient) IsHealthy(ctx context.Context) bool {
	health, err := c.HealthCheck(ctx)
	if err != nil {
		logger.Error("Analyze service health check failed: %v", err)
		return false
	}

	return health.Status == "healthy" && health.WordLevelsLoaded
}
