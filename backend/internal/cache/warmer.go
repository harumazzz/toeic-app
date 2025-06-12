package cache

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"sync"
	"time"

	db "github.com/toeic-app/internal/db/sqlc"
	"github.com/toeic-app/internal/logger"
)

// CacheWarmer handles cache warming strategies
type CacheWarmer struct {
	cache       Cache
	store       db.Querier
	config      CacheWarmerConfig
	stopChan    chan struct{}
	isRunning   bool
	mutex       sync.RWMutex
	lastWarmup  time.Time
	warmupStats WarmupStats
}

// CacheWarmerConfig holds configuration for cache warming
type CacheWarmerConfig struct {
	Enabled          bool
	WarmupInterval   time.Duration
	BatchSize        int
	MaxConcurrency   int
	WarmupStrategies []WarmupStrategy
}

// WarmupStrategy defines what data to warm up
type WarmupStrategy struct {
	Name       string
	DataType   string // "words", "grammars", "popular_searches", "user_data"
	TTL        time.Duration
	Priority   int // Higher priority items are warmed first
	Enabled    bool
	Parameters map[string]interface{} // Strategy-specific parameters
}

// WarmupStats tracks cache warming statistics
type WarmupStats struct {
	LastRun        time.Time
	TotalWarmed    int64
	LastDuration   time.Duration
	SuccessRate    float64
	ErrorCount     int64
	StrategyCounts map[string]int64
}

// NewCacheWarmer creates a new cache warmer
func NewCacheWarmer(cache Cache, store db.Querier, config CacheWarmerConfig) *CacheWarmer {
	return &CacheWarmer{
		cache:    cache,
		store:    store,
		config:   config,
		stopChan: make(chan struct{}),
		warmupStats: WarmupStats{
			StrategyCounts: make(map[string]int64),
		},
	}
}

// Start begins the cache warming process
func (cw *CacheWarmer) Start(ctx context.Context) error {
	if !cw.config.Enabled {
		logger.Info("Cache warming is disabled")
		return nil
	}

	cw.mutex.Lock()
	if cw.isRunning {
		cw.mutex.Unlock()
		return fmt.Errorf("cache warmer is already running")
	}
	cw.isRunning = true
	cw.mutex.Unlock()

	logger.Info("Starting cache warmer with %d strategies", len(cw.config.WarmupStrategies))

	// Initial warmup
	go func() {
		if err := cw.performWarmup(ctx); err != nil {
			logger.Error("Initial cache warmup failed: %v", err)
		}
	}()

	// Start periodic warmup
	ticker := time.NewTicker(cw.config.WarmupInterval)
	go func() {
		defer ticker.Stop()
		for {
			select {
			case <-ticker.C:
				if err := cw.performWarmup(ctx); err != nil {
					logger.Error("Periodic cache warmup failed: %v", err)
				}
			case <-cw.stopChan:
				return
			}
		}
	}()

	return nil
}

// Stop stops the cache warming process
func (cw *CacheWarmer) Stop() {
	cw.mutex.Lock()
	defer cw.mutex.Unlock()

	if cw.isRunning {
		close(cw.stopChan)
		cw.isRunning = false
		logger.Info("Cache warmer stopped")
	}
}

// performWarmup executes all enabled warmup strategies
func (cw *CacheWarmer) performWarmup(ctx context.Context) error {
	startTime := time.Now()
	totalWarmed := int64(0)
	totalErrors := int64(0)

	logger.Info("Starting cache warmup cycle...")

	// Sort strategies by priority
	strategies := make([]WarmupStrategy, len(cw.config.WarmupStrategies))
	copy(strategies, cw.config.WarmupStrategies)

	// Create worker pool
	semaphore := make(chan struct{}, cw.config.MaxConcurrency)
	var wg sync.WaitGroup

	for _, strategy := range strategies {
		if !strategy.Enabled {
			continue
		}

		wg.Add(1)
		go func(s WarmupStrategy) {
			defer wg.Done()
			semaphore <- struct{}{}        // Acquire
			defer func() { <-semaphore }() // Release

			count, err := cw.executeStrategy(ctx, s)
			if err != nil {
				logger.Error("Warmup strategy '%s' failed: %v", s.Name, err)
				totalErrors++
			} else {
				totalWarmed += count
				cw.mutex.Lock()
				cw.warmupStats.StrategyCounts[s.Name] = count
				cw.mutex.Unlock()
				logger.Debug("Warmup strategy '%s' completed: %d items", s.Name, count)
			}
		}(strategy)
	}

	wg.Wait()

	duration := time.Since(startTime)
	successRate := float64(totalWarmed) / float64(totalWarmed+totalErrors) * 100

	// Update stats
	cw.mutex.Lock()
	cw.warmupStats.LastRun = time.Now()
	cw.warmupStats.TotalWarmed = totalWarmed
	cw.warmupStats.LastDuration = duration
	cw.warmupStats.SuccessRate = successRate
	cw.warmupStats.ErrorCount = totalErrors
	cw.lastWarmup = time.Now()
	cw.mutex.Unlock()

	logger.Info("Cache warmup completed: %d items warmed in %v (%.1f%% success rate)",
		totalWarmed, duration, successRate)

	return nil
}

// executeStrategy executes a specific warmup strategy
func (cw *CacheWarmer) executeStrategy(ctx context.Context, strategy WarmupStrategy) (int64, error) {
	switch strategy.DataType {
	case "words":
		return cw.warmupWords(ctx, strategy)
	case "grammars":
		return cw.warmupGrammars(ctx, strategy)
	case "popular_searches":
		return cw.warmupPopularSearches(ctx, strategy)
	case "user_data":
		return cw.warmupUserData(ctx, strategy)
	case "exam_questions":
		return cw.warmupExamQuestions(ctx, strategy)
	default:
		return 0, fmt.Errorf("unknown warmup strategy: %s", strategy.DataType)
	}
}

// warmupWords warms up word data
func (cw *CacheWarmer) warmupWords(ctx context.Context, strategy WarmupStrategy) (int64, error) {
	limit := int32(cw.config.BatchSize)
	if limitParam, ok := strategy.Parameters["limit"]; ok {
		if l, ok := limitParam.(int); ok {
			limit = int32(l)
		}
	}

	// Warm up most popular words using GetPopularWords
	words, err := cw.store.GetPopularWords(ctx, db.GetPopularWordsParams{
		Limit:  limit,
		Offset: 0,
	})
	if err != nil {
		return 0, err
	}

	count := int64(0)
	for _, word := range words {
		cacheKey := fmt.Sprintf("word:definition:%d", word.ID)

		// Check if already cached
		exists, _ := cw.cache.Exists(ctx, cacheKey)
		if exists {
			continue
		}

		wordData, err := json.Marshal(word)
		if err != nil {
			continue
		}

		if err := cw.cache.Set(ctx, cacheKey, wordData, strategy.TTL); err == nil {
			count++
		}
	}

	// Warm up words by level using GetWordsByLevel
	for level := 1; level <= 7; level++ {
		levelWords, err := cw.store.GetWordsByLevel(ctx, db.GetWordsByLevelParams{
			Level:  int32(level),
			Limit:  limit / 7, // Distribute across levels
			Offset: 0,
		})
		if err != nil {
			continue
		}

		cacheKey := fmt.Sprintf("words:level:%d", level)
		wordsData, err := json.Marshal(levelWords)
		if err != nil {
			continue
		}

		if err := cw.cache.Set(ctx, cacheKey, wordsData, strategy.TTL); err == nil {
			count++
		}
	}

	return count, nil
}

// warmupGrammars warms up grammar data
func (cw *CacheWarmer) warmupGrammars(ctx context.Context, strategy WarmupStrategy) (int64, error) {
	limit := int32(cw.config.BatchSize)

	grammars, err := cw.store.ListGrammars(ctx, db.ListGrammarsParams{
		Limit:  limit,
		Offset: 0,
	})
	if err != nil {
		return 0, err
	}

	count := int64(0)
	for _, grammar := range grammars {
		cacheKey := fmt.Sprintf("grammar:rules:%d", grammar.ID)

		exists, _ := cw.cache.Exists(ctx, cacheKey)
		if exists {
			continue
		}

		grammarData, err := json.Marshal(grammar)
		if err != nil {
			continue
		}

		if err := cw.cache.Set(ctx, cacheKey, grammarData, strategy.TTL); err == nil {
			count++
		}
	}

	// Warm up grammars by level
	for level := 1; level <= 7; level++ {
		levelGrammars, err := cw.store.ListGrammarsByLevel(ctx, db.ListGrammarsByLevelParams{
			Level:  int32(level),
			Limit:  limit / 7,
			Offset: 0,
		})
		if err != nil {
			continue
		}

		cacheKey := fmt.Sprintf("grammars:level:%d", level)
		grammarsData, err := json.Marshal(levelGrammars)
		if err != nil {
			continue
		}

		if err := cw.cache.Set(ctx, cacheKey, grammarsData, strategy.TTL); err == nil {
			count++
		}
	}

	return count, nil
}

// warmupPopularSearches warms up popular search results
func (cw *CacheWarmer) warmupPopularSearches(ctx context.Context, strategy WarmupStrategy) (int64, error) {
	// Define popular search terms (could be dynamic based on analytics)
	popularTerms := []string{
		"business", "technology", "education", "environment", "health",
		"travel", "finance", "communication", "culture", "science",
	}

	if terms, ok := strategy.Parameters["terms"]; ok {
		if termsList, ok := terms.([]string); ok {
			popularTerms = termsList
		}
	}

	count := int64(0)
	limit := int32(20) // Cache top 20 results for each search

	for _, term := range popularTerms {
		// Warm up word searches using correct parameter structure
		wordCacheKey := fmt.Sprintf("search:words:%s:20:0", term)
		exists, _ := cw.cache.Exists(ctx, wordCacheKey)
		if !exists {
			words, err := cw.store.SearchWords(ctx, db.SearchWordsParams{
				Column1: sql.NullString{String: term, Valid: true},
				Limit:   limit,
				Offset:  0,
			})
			if err == nil {
				wordsData, err := json.Marshal(words)
				if err == nil {
					if err := cw.cache.Set(ctx, wordCacheKey, wordsData, strategy.TTL); err == nil {
						count++
					}
				}
			}
		}

		// Warm up grammar searches using correct parameter structure
		grammarCacheKey := fmt.Sprintf("search:grammars:%s:20:0", term)
		exists, _ = cw.cache.Exists(ctx, grammarCacheKey)
		if !exists {
			grammars, err := cw.store.SearchGrammars(ctx, db.SearchGrammarsParams{
				Column1: sql.NullString{String: term, Valid: true},
				Limit:   limit,
				Offset:  0,
			})
			if err == nil {
				grammarsData, err := json.Marshal(grammars)
				if err == nil {
					if err := cw.cache.Set(ctx, grammarCacheKey, grammarsData, strategy.TTL); err == nil {
						count++
					}
				}
			}
		}
	}

	return count, nil
}

// warmupUserData warms up user-specific data for active users
func (cw *CacheWarmer) warmupUserData(ctx context.Context, strategy WarmupStrategy) (int64, error) {
	// This could be enhanced with user activity analytics
	// For now, we'll warm up data for recently active users

	limit := int32(100) // Top 100 active users
	if limitParam, ok := strategy.Parameters["user_limit"]; ok {
		if l, ok := limitParam.(int); ok {
			limit = int32(l)
		}
	}

	// Get recent users (this would need a proper query in production)
	users, err := cw.store.ListUsers(ctx, db.ListUsersParams{
		Limit:  limit,
		Offset: 0,
	})
	if err != nil {
		return 0, err
	}

	count := int64(0)
	for _, user := range users {
		// Warm up user profile
		profileKey := fmt.Sprintf("user:profile:%d", user.ID)
		exists, _ := cw.cache.Exists(ctx, profileKey)
		if !exists {
			userData, err := json.Marshal(user)
			if err == nil {
				if err := cw.cache.Set(ctx, profileKey, userData, strategy.TTL); err == nil {
					count++
				}
			}
		}
	}

	return count, nil
}

// warmupExamQuestions warms up exam questions
func (cw *CacheWarmer) warmupExamQuestions(ctx context.Context, strategy WarmupStrategy) (int64, error) {
	// Get all exams (no parameters needed)
	exams, err := cw.store.ListExams(ctx)
	if err != nil {
		return 0, err
	}

	count := int64(0)
	for _, exam := range exams {
		cacheKey := fmt.Sprintf("exam:questions:%d", exam.ExamID)

		exists, _ := cw.cache.Exists(ctx, cacheKey)
		if exists {
			continue
		}

		// Get parts for this exam
		parts, err := cw.store.ListPartsByExam(ctx, exam.ExamID)
		if err != nil {
			continue
		}

		// Get all questions for all parts of this exam
		allQuestions := []db.Question{}
		for _, part := range parts {
			contents, err := cw.store.ListContentsByPart(ctx, part.PartID)
			if err != nil {
				continue
			}

			for _, content := range contents {
				questions, err := cw.store.ListQuestionsByContent(ctx, content.ContentID)
				if err != nil {
					continue
				}
				allQuestions = append(allQuestions, questions...)
			}
		}

		questionsData, err := json.Marshal(allQuestions)
		if err != nil {
			continue
		}

		if err := cw.cache.Set(ctx, cacheKey, questionsData, strategy.TTL); err == nil {
			count++
		}
	}

	return count, nil
}

// GetStats returns cache warming statistics
func (cw *CacheWarmer) GetStats() WarmupStats {
	cw.mutex.RLock()
	defer cw.mutex.RUnlock()

	// Create a copy to avoid race conditions
	stats := WarmupStats{
		LastRun:        cw.warmupStats.LastRun,
		TotalWarmed:    cw.warmupStats.TotalWarmed,
		LastDuration:   cw.warmupStats.LastDuration,
		SuccessRate:    cw.warmupStats.SuccessRate,
		ErrorCount:     cw.warmupStats.ErrorCount,
		StrategyCounts: make(map[string]int64),
	}

	for k, v := range cw.warmupStats.StrategyCounts {
		stats.StrategyCounts[k] = v
	}

	return stats
}

// DefaultCacheWarmerConfig returns a default cache warmer configuration
func DefaultCacheWarmerConfig() CacheWarmerConfig {
	return CacheWarmerConfig{
		Enabled:        true,
		WarmupInterval: 1 * time.Hour,
		BatchSize:      1000,
		MaxConcurrency: 5,
		WarmupStrategies: []WarmupStrategy{
			{
				Name:     "Popular Words",
				DataType: "words",
				TTL:      2 * time.Hour,
				Priority: 1,
				Enabled:  true,
				Parameters: map[string]interface{}{
					"limit": 1000,
				},
			},
			{
				Name:     "Popular Grammars",
				DataType: "grammars",
				TTL:      2 * time.Hour,
				Priority: 2,
				Enabled:  true,
				Parameters: map[string]interface{}{
					"limit": 500,
				},
			},
			{
				Name:     "Popular Searches",
				DataType: "popular_searches",
				TTL:      1 * time.Hour,
				Priority: 3,
				Enabled:  true,
			},
			{
				Name:     "Exam Questions",
				DataType: "exam_questions",
				TTL:      4 * time.Hour,
				Priority: 4,
				Enabled:  true,
			},
			{
				Name:     "Active User Data",
				DataType: "user_data",
				TTL:      30 * time.Minute,
				Priority: 5,
				Enabled:  false, // Disabled by default for privacy
				Parameters: map[string]interface{}{
					"user_limit": 100,
				},
			},
		},
	}
}
