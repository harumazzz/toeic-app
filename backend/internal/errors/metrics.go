package errors

import (
	"sync"
	"time"
)

// ErrorMetrics tracks error statistics for monitoring
type ErrorMetrics struct {
	mu               sync.RWMutex
	errorCounts      map[ErrorCode]int64
	categoryCounts   map[ErrorCategory]int64
	severityCounts   map[ErrorSeverity]int64
	httpStatusCounts map[int]int64
	totalErrors      int64
	lastReset        time.Time
}

// ErrorEvent represents an error event for monitoring
type ErrorEvent struct {
	Error      *AppError     `json:"error"`
	Timestamp  time.Time     `json:"timestamp"`
	Severity   ErrorSeverity `json:"severity"`
	Category   ErrorCategory `json:"category"`
	HTTPStatus int           `json:"http_status"`
	UserAgent  string        `json:"user_agent,omitempty"`
	ClientIP   string        `json:"client_ip,omitempty"`
}

// NewErrorMetrics creates a new ErrorMetrics instance
func NewErrorMetrics() *ErrorMetrics {
	return &ErrorMetrics{
		errorCounts:      make(map[ErrorCode]int64),
		categoryCounts:   make(map[ErrorCategory]int64),
		severityCounts:   make(map[ErrorSeverity]int64),
		httpStatusCounts: make(map[int]int64),
		lastReset:        time.Now(),
	}
}

// RecordError records an error in the metrics
func (m *ErrorMetrics) RecordError(appErr *AppError, userAgent, clientIP string) {
	if appErr == nil {
		return
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	// Increment counters
	m.errorCounts[appErr.Code]++
	m.categoryCounts[appErr.Code.GetCategory()]++
	m.severityCounts[appErr.Code.GetSeverity()]++
	m.httpStatusCounts[appErr.Code.GetHTTPStatus()]++
	m.totalErrors++
}

// GetErrorCounts returns error counts by error code
func (m *ErrorMetrics) GetErrorCounts() map[ErrorCode]int64 {
	m.mu.RLock()
	defer m.mu.RUnlock()

	counts := make(map[ErrorCode]int64)
	for code, count := range m.errorCounts {
		counts[code] = count
	}
	return counts
}

// GetCategoryCounts returns error counts by category
func (m *ErrorMetrics) GetCategoryCounts() map[ErrorCategory]int64 {
	m.mu.RLock()
	defer m.mu.RUnlock()

	counts := make(map[ErrorCategory]int64)
	for category, count := range m.categoryCounts {
		counts[category] = count
	}
	return counts
}

// GetSeverityCounts returns error counts by severity
func (m *ErrorMetrics) GetSeverityCounts() map[ErrorSeverity]int64 {
	m.mu.RLock()
	defer m.mu.RUnlock()

	counts := make(map[ErrorSeverity]int64)
	for severity, count := range m.severityCounts {
		counts[severity] = count
	}
	return counts
}

// GetHTTPStatusCounts returns error counts by HTTP status code
func (m *ErrorMetrics) GetHTTPStatusCounts() map[int]int64 {
	m.mu.RLock()
	defer m.mu.RUnlock()

	counts := make(map[int]int64)
	for status, count := range m.httpStatusCounts {
		counts[status] = count
	}
	return counts
}

// GetTotalErrors returns the total number of errors recorded
func (m *ErrorMetrics) GetTotalErrors() int64 {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return m.totalErrors
}

// GetErrorRate returns the error rate per minute since last reset
func (m *ErrorMetrics) GetErrorRate() float64 {
	m.mu.RLock()
	defer m.mu.RUnlock()

	duration := time.Since(m.lastReset).Minutes()
	if duration == 0 {
		return 0
	}
	return float64(m.totalErrors) / duration
}

// Reset resets all metrics
func (m *ErrorMetrics) Reset() {
	m.mu.Lock()
	defer m.mu.Unlock()

	m.errorCounts = make(map[ErrorCode]int64)
	m.categoryCounts = make(map[ErrorCategory]int64)
	m.severityCounts = make(map[ErrorSeverity]int64)
	m.httpStatusCounts = make(map[int]int64)
	m.totalErrors = 0
	m.lastReset = time.Now()
}

// GetTopErrors returns the most frequent error codes
func (m *ErrorMetrics) GetTopErrors(limit int) []struct {
	Code  ErrorCode
	Count int64
} {
	m.mu.RLock()
	defer m.mu.RUnlock()

	type errorCount struct {
		Code  ErrorCode
		Count int64
	}

	var errors []errorCount
	for code, count := range m.errorCounts {
		errors = append(errors, errorCount{Code: code, Count: count})
	}

	// Simple bubble sort for small datasets
	for i := 0; i < len(errors)-1; i++ {
		for j := 0; j < len(errors)-i-1; j++ {
			if errors[j].Count < errors[j+1].Count {
				errors[j], errors[j+1] = errors[j+1], errors[j]
			}
		}
	}

	if limit > 0 && limit < len(errors) {
		errors = errors[:limit]
	}

	result := make([]struct {
		Code  ErrorCode
		Count int64
	}, len(errors))

	for i, err := range errors {
		result[i] = struct {
			Code  ErrorCode
			Count int64
		}{Code: err.Code, Count: err.Count}
	}

	return result
}

// ErrorSummary provides a summary of error metrics
type ErrorSummary struct {
	TotalErrors      int64                   `json:"total_errors"`
	ErrorRate        float64                 `json:"error_rate_per_minute"`
	TopErrors        []TopErrorStat          `json:"top_errors"`
	CategoryCounts   map[ErrorCategory]int64 `json:"category_counts"`
	SeverityCounts   map[ErrorSeverity]int64 `json:"severity_counts"`
	HTTPStatusCounts map[int]int64           `json:"http_status_counts"`
	SinceReset       time.Duration           `json:"since_reset" swaggertype:"string" example:"5m30s"`
}

// TopErrorStat represents a top error statistic
type TopErrorStat struct {
	Code       ErrorCode     `json:"code"`
	Count      int64         `json:"count"`
	Percentage float64       `json:"percentage"`
	Severity   ErrorSeverity `json:"severity"`
	Category   ErrorCategory `json:"category"`
}

// GetSummary returns a comprehensive error summary
func (m *ErrorMetrics) GetSummary(topLimit int) ErrorSummary {
	m.mu.RLock()
	defer m.mu.RUnlock()

	topErrors := m.GetTopErrors(topLimit)
	topErrorStats := make([]TopErrorStat, len(topErrors))

	for i, err := range topErrors {
		percentage := 0.0
		if m.totalErrors > 0 {
			percentage = float64(err.Count) / float64(m.totalErrors) * 100
		}

		topErrorStats[i] = TopErrorStat{
			Code:       err.Code,
			Count:      err.Count,
			Percentage: percentage,
			Severity:   err.Code.GetSeverity(),
			Category:   err.Code.GetCategory(),
		}
	}

	return ErrorSummary{
		TotalErrors:      m.totalErrors,
		ErrorRate:        m.GetErrorRate(),
		TopErrors:        topErrorStats,
		CategoryCounts:   m.GetCategoryCounts(),
		SeverityCounts:   m.GetSeverityCounts(),
		HTTPStatusCounts: m.GetHTTPStatusCounts(),
		SinceReset:       time.Since(m.lastReset),
	}
}
