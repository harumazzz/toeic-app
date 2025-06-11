package performance

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	db "github.com/toeic-app/internal/db/sqlc"
)

func TestObjectPool(t *testing.T) {
	t.Run("ObjectPool Performance", func(t *testing.T) {
		pool := NewObjectPool()

		// Test word response pooling
		start := time.Now()
		for i := 0; i < 1000; i++ {
			wr := pool.GetWordResponse()
			wr.Word = fmt.Sprintf("test%d", i)
			pool.PutWordResponse(wr)
		}
		duration := time.Since(start)

		t.Logf("Object pool test completed in %v", duration)
		assert.Less(t, duration, 10*time.Millisecond, "Object pooling should be very fast")
	})

	t.Run("Word Conversion Performance", func(t *testing.T) {
		pool := NewObjectPool()

		// Create test words
		words := make([]db.Word, 100)
		for i := range words {
			words[i] = db.Word{
				ID:   int32(i),
				Word: fmt.Sprintf("word%d", i),
			}
		}

		start := time.Now()
		responses := pool.ConvertWordsToResponses(words)
		duration := time.Since(start)

		assert.Equal(t, len(words), len(responses))
		assert.Less(t, duration, 5*time.Millisecond, "Word conversion should be fast")
		t.Logf("Converted %d words in %v", len(words), duration)
	})
}

func TestBackgroundProcessor(t *testing.T) {
	t.Run("Background Processor Basic Operations", func(t *testing.T) {
		processor := NewBackgroundProcessor(2, 10)
		defer processor.Stop()

		// Test task submission
		completed := make(chan bool, 1)
		task := BackgroundTask{
			ID:   "test-task",
			Type: "test",
			Data: "test-data",
			Handler: func(ctx context.Context, data interface{}) error {
				assert.Equal(t, "test-data", data)
				completed <- true
				return nil
			},
			Timeout: 5 * time.Second,
		}

		processor.SubmitTask(task)

		select {
		case <-completed:
			t.Log("Task completed successfully")
		case <-time.After(2 * time.Second):
			t.Fatal("Task did not complete within timeout")
		}

		// Check stats
		stats := processor.GetStats()
		assert.Greater(t, stats.TotalTasks, int64(0))
		assert.Greater(t, stats.CompletedTasks, int64(0))
	})

	t.Run("Queue Health Check", func(t *testing.T) {
		processor := NewBackgroundProcessor(1, 5)
		defer processor.Stop()

		health := processor.GetQueueHealth()
		assert.Contains(t, health, "health")
		assert.Contains(t, health, "queue_size")
		assert.Contains(t, health, "max_workers")

		t.Logf("Queue health: %+v", health)
	})
}

func TestResponseOptimizer(t *testing.T) {
	t.Run("Response Optimization", func(t *testing.T) {
		optimizer := NewResponseOptimizer()

		// Create test word
		word := db.Word{
			ID:   1,
			Word: "test",
		}

		// Test full response
		fullResponse := optimizer.OptimizeWordResponse(word, nil)
		assert.NotNil(t, fullResponse)

		// Test field selection
		fieldResponse := optimizer.OptimizeWordResponse(word, []string{"id", "word"})
		assert.NotNil(t, fieldResponse)

		// Test minimal response
		minimalResponse := optimizer.CreateMinimalWordResponse(word)
		assert.Contains(t, minimalResponse, "id")
		assert.Contains(t, minimalResponse, "word")
		assert.Equal(t, 4, len(minimalResponse)) // id, word, short_mean, level
	})

	t.Run("Batch Optimization", func(t *testing.T) {
		optimizer := NewResponseOptimizer()

		words := make([]db.Word, 50)
		for i := range words {
			words[i] = db.Word{
				ID:   int32(i),
				Word: fmt.Sprintf("word%d", i),
			}
		}

		start := time.Now()
		result := optimizer.BatchOptimizeWords(words, nil, 20)
		duration := time.Since(start)

		assert.NotNil(t, result)
		assert.Less(t, duration, 10*time.Millisecond)

		t.Logf("Batch optimization of %d words completed in %v", len(words), duration)
	})
}

func BenchmarkPerformanceOptimizations(b *testing.B) {
	b.Run("ObjectPool vs Regular Allocation", func(b *testing.B) {
		pool := NewObjectPool()

		b.Run("WithPool", func(b *testing.B) {
			for i := 0; i < b.N; i++ {
				wr := pool.GetWordResponse()
				wr.Word = "benchmark"
				pool.PutWordResponse(wr)
			}
		})

		b.Run("WithoutPool", func(b *testing.B) {
			for i := 0; i < b.N; i++ {
				wr := &WordResponse{}
				wr.Word = "benchmark"
				_ = wr // Simulate usage
			}
		})
	})

	b.Run("Response Optimization", func(b *testing.B) {
		optimizer := NewResponseOptimizer()
		word := db.Word{ID: 1, Word: "benchmark"}

		b.ResetTimer()
		for i := 0; i < b.N; i++ {
			optimizer.OptimizeWordResponse(word, nil)
		}
	})

	b.Run("Background Task Processing", func(b *testing.B) {
		processor := NewBackgroundProcessor(4, 1000)
		defer processor.Stop()

		b.ResetTimer()
		for i := 0; i < b.N; i++ {
			task := BackgroundTask{
				ID:   fmt.Sprintf("bench-task-%d", i),
				Type: "benchmark",
				Data: i,
				Handler: func(ctx context.Context, data interface{}) error {
					return nil // No-op for benchmarking
				},
			}
			processor.SubmitTask(task)
		}
	})
}

// Performance regression test
func TestPerformanceRegression(t *testing.T) {
	t.Run("Word Search Performance Regression", func(t *testing.T) {
		// This test would typically run against a real database
		// For now, we'll test the optimization components

		optimizer := NewResponseOptimizer()
		pool := NewObjectPool()

		// Create large dataset
		words := make([]db.Word, 1000)
		for i := range words {
			words[i] = db.Word{
				ID:   int32(i),
				Word: fmt.Sprintf("word%d", i),
			}
		}

		// Test optimization performance
		start := time.Now()
		responses := pool.ConvertWordsToResponses(words)
		optimizedResponses := optimizer.OptimizeWordsResponse(words, nil)
		duration := time.Since(start)

		assert.Equal(t, len(words), len(responses))
		assert.NotNil(t, optimizedResponses)
		assert.Less(t, duration, 50*time.Millisecond, "Performance regression detected")

		t.Logf("Processed %d words in %v (%.2f μs/word)",
			len(words), duration, float64(duration.Nanoseconds())/float64(len(words))/1000)
	})
}

// Integration test for all performance components
func TestPerformanceIntegration(t *testing.T) {
	t.Run("Full Performance Stack", func(t *testing.T) {
		// Initialize all components
		pool := NewObjectPool()
		optimizer := NewResponseOptimizer()
		processor := NewBackgroundProcessor(2, 50)
		defer processor.Stop()

		// Simulate a search operation
		words := make([]db.Word, 100)
		for i := range words {
			words[i] = db.Word{
				ID:   int32(i),
				Word: fmt.Sprintf("search%d", i),
			}
		}

		// Process with all optimizations
		start := time.Now()

		// 1. Use object pool for conversion
		responses := pool.ConvertWordsToResponses(words)

		// 2. Optimize responses
		optimized := optimizer.OptimizeWordsResponse(words, []string{"id", "word"})

		// 3. Submit background caching task
		cacheTask := BackgroundTask{
			ID:   "cache-warmup",
			Type: "cache",
			Data: []string{"test:cache:key"},
			Handler: func(ctx context.Context, data interface{}) error {
				return nil
			},
			Timeout: 2 * time.Second,
		}
		processor.SubmitTask(cacheTask)

		totalDuration := time.Since(start)

		assert.Equal(t, len(words), len(responses))
		assert.NotNil(t, optimized)
		assert.Less(t, totalDuration, 20*time.Millisecond, "Integrated performance should be fast")

		// Wait for background task
		time.Sleep(100 * time.Millisecond)
		stats := processor.GetStats()
		assert.Greater(t, stats.TotalTasks, int64(0))

		t.Logf("Full performance stack processed %d words in %v", len(words), totalDuration)
	})
}
