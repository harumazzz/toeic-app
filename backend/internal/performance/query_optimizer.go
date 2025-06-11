package performance

import (
	"context"
	"database/sql"
	"sync"
	"time"

	"github.com/toeic-app/internal/logger"
)

// PreparedStatementCache manages prepared statements for better performance
type PreparedStatementCache struct {
	db         *sql.DB
	statements map[string]*sql.Stmt
	mutex      sync.RWMutex
	maxSize    int
	ttl        time.Duration
	cleanup    *time.Ticker
	done       chan bool
}

// NewPreparedStatementCache creates a new prepared statement cache
func NewPreparedStatementCache(db *sql.DB, maxSize int, ttl time.Duration) *PreparedStatementCache {
	cache := &PreparedStatementCache{
		db:         db,
		statements: make(map[string]*sql.Stmt),
		maxSize:    maxSize,
		ttl:        ttl,
		cleanup:    time.NewTicker(ttl),
		done:       make(chan bool),
	}

	// Start cleanup goroutine
	go cache.cleanupRoutine()

	return cache
}

// Get retrieves or creates a prepared statement
func (psc *PreparedStatementCache) Get(ctx context.Context, query string) (*sql.Stmt, error) {
	psc.mutex.RLock()
	if stmt, exists := psc.statements[query]; exists {
		psc.mutex.RUnlock()
		return stmt, nil
	}
	psc.mutex.RUnlock()

	// Need to create new prepared statement
	psc.mutex.Lock()
	defer psc.mutex.Unlock()

	// Double-check after acquiring write lock
	if stmt, exists := psc.statements[query]; exists {
		return stmt, nil
	}

	// Check if we need to evict old statements
	if len(psc.statements) >= psc.maxSize {
		psc.evictOldest()
	}

	// Prepare the statement
	stmt, err := psc.db.PrepareContext(ctx, query)
	if err != nil {
		return nil, err
	}

	psc.statements[query] = stmt
	logger.Debug("Prepared statement cached for query hash: %s", hashQuery(query))

	return stmt, nil
}

// Close closes all prepared statements and stops the cache
func (psc *PreparedStatementCache) Close() {
	psc.cleanup.Stop()
	psc.done <- true

	psc.mutex.Lock()
	defer psc.mutex.Unlock()

	for query, stmt := range psc.statements {
		if err := stmt.Close(); err != nil {
			logger.Warn("Failed to close prepared statement for query %s: %v", hashQuery(query), err)
		}
	}

	psc.statements = make(map[string]*sql.Stmt)
}

// evictOldest removes the oldest statement (simple FIFO for now)
func (psc *PreparedStatementCache) evictOldest() {
	for query, stmt := range psc.statements {
		if err := stmt.Close(); err != nil {
			logger.Warn("Failed to close evicted prepared statement: %v", err)
		}
		delete(psc.statements, query)
		break // Remove only one
	}
}

// cleanupRoutine periodically cleans up the cache
func (psc *PreparedStatementCache) cleanupRoutine() {
	for {
		select {
		case <-psc.cleanup.C:
			psc.performCleanup()
		case <-psc.done:
			return
		}
	}
}

// performCleanup removes unused statements
func (psc *PreparedStatementCache) performCleanup() {
	psc.mutex.Lock()
	defer psc.mutex.Unlock()

	// For now, we'll keep all statements since we don't track usage time
	// In a more sophisticated implementation, we would track last access time
	logger.Debug("Prepared statement cache cleanup completed. Current size: %d", len(psc.statements))
}

// GetStats returns cache statistics
func (psc *PreparedStatementCache) GetStats() map[string]interface{} {
	psc.mutex.RLock()
	defer psc.mutex.RUnlock()

	return map[string]interface{}{
		"total_statements": len(psc.statements),
		"max_size":         psc.maxSize,
		"ttl_minutes":      psc.ttl.Minutes(),
	}
}

// hashQuery creates a simple hash of the query for logging
func hashQuery(query string) string {
	if len(query) > 50 {
		return query[:50] + "..."
	}
	return query
}

// QueryOptimizer provides optimized database query execution
type QueryOptimizer struct {
	preparedCache *PreparedStatementCache
	db            *sql.DB
}

// NewQueryOptimizer creates a new query optimizer
func NewQueryOptimizer(db *sql.DB) *QueryOptimizer {
	return &QueryOptimizer{
		preparedCache: NewPreparedStatementCache(db, 100, 30*time.Minute),
		db:            db,
	}
}

// QueryRowContext executes a query that returns a single row using prepared statements
func (qo *QueryOptimizer) QueryRowContext(ctx context.Context, query string, args ...interface{}) *sql.Row {
	stmt, err := qo.preparedCache.Get(ctx, query)
	if err != nil {
		// Fallback to direct query if prepared statement fails
		logger.Warn("Failed to get prepared statement, falling back to direct query: %v", err)
		return qo.db.QueryRowContext(ctx, query, args...)
	}

	return stmt.QueryRowContext(ctx, args...)
}

// QueryContext executes a query that returns multiple rows using prepared statements
func (qo *QueryOptimizer) QueryContext(ctx context.Context, query string, args ...interface{}) (*sql.Rows, error) {
	stmt, err := qo.preparedCache.Get(ctx, query)
	if err != nil {
		// Fallback to direct query if prepared statement fails
		logger.Warn("Failed to get prepared statement, falling back to direct query: %v", err)
		return qo.db.QueryContext(ctx, query, args...)
	}

	return stmt.QueryContext(ctx, args...)
}

// ExecContext executes a query that doesn't return rows using prepared statements
func (qo *QueryOptimizer) ExecContext(ctx context.Context, query string, args ...interface{}) (sql.Result, error) {
	stmt, err := qo.preparedCache.Get(ctx, query)
	if err != nil {
		// Fallback to direct query if prepared statement fails
		logger.Warn("Failed to get prepared statement, falling back to direct query: %v", err)
		return qo.db.ExecContext(ctx, query, args...)
	}

	return stmt.ExecContext(ctx, args...)
}

// Close closes the query optimizer and all prepared statements
func (qo *QueryOptimizer) Close() {
	qo.preparedCache.Close()
}

// GetStats returns optimizer statistics
func (qo *QueryOptimizer) GetStats() map[string]interface{} {
	return qo.preparedCache.GetStats()
}
