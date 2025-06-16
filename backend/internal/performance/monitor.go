package performance

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"github.com/toeic-app/internal/logger"
)

// PerformanceMetrics represents database performance metrics
type PerformanceMetrics struct {
	IndexUsage       []IndexUsageStats       `json:"index_usage"`
	TableStats       []TableStats            `json:"table_stats"`
	QueryPerformance []QueryPerformanceStats `json:"query_performance"`
	CacheHitRatio    CacheStats              `json:"cache_hit_ratio"`
	DatabaseSize     DatabaseSizeStats       `json:"database_size"`
}

// IndexUsageStats represents index usage statistics
type IndexUsageStats struct {
	SchemaName  string `json:"schema_name"`
	TableName   string `json:"table_name"`
	IndexName   string `json:"index_name"`
	Scans       int64  `json:"scans"`
	TuplesRead  int64  `json:"tuples_read"`
	TuplesFetch int64  `json:"tuples_fetch"`
	UsageLevel  string `json:"usage_level"`
	IndexSize   string `json:"index_size"`
}

// TableStats represents table statistics
type TableStats struct {
	SchemaName        string  `json:"schema_name"`
	TableName         string  `json:"table_name"`
	SequentialScans   int64   `json:"sequential_scans"`
	SeqTuplesRead     int64   `json:"seq_tuples_read"`
	IndexScans        int64   `json:"index_scans"`
	IdxTuplesFetch    int64   `json:"idx_tuples_fetch"`
	Inserts           int64   `json:"inserts"`
	Updates           int64   `json:"updates"`
	Deletes           int64   `json:"deletes"`
	SeqScanPercentage float64 `json:"seq_scan_percentage"`
	TotalSize         string  `json:"total_size"`
}

// QueryPerformanceStats represents query performance statistics
type QueryPerformanceStats struct {
	Query      string  `json:"query"`
	Calls      int64   `json:"calls"`
	TotalTime  float64 `json:"total_time"`
	MeanTime   float64 `json:"mean_time"`
	Rows       int64   `json:"rows"`
	HitPercent float64 `json:"hit_percent"`
}

// CacheStats represents cache hit statistics
type CacheStats struct {
	BufferCacheHitRatio float64 `json:"buffer_cache_hit_ratio"`
	IndexCacheHitRatio  float64 `json:"index_cache_hit_ratio"`
}

// DatabaseSizeStats represents database size statistics
type DatabaseSizeStats struct {
	TotalSize  string  `json:"total_size"`
	TableSize  string  `json:"table_size"`
	IndexSize  string  `json:"index_size"`
	IndexRatio float64 `json:"index_ratio"`
}

// OptimizationRecommendation represents an optimization recommendation
type OptimizationRecommendation struct {
	Type             string `json:"type"`
	TableName        string `json:"table_name"`
	ColumnNames      string `json:"column_names"`
	Rationale        string `json:"rationale"`
	EstimatedBenefit string `json:"estimated_benefit"`
	SQLCommand       string `json:"sql_command"`
}

// PerformanceMonitor handles database performance monitoring
type PerformanceMonitor struct {
	db *sql.DB
}

// NewPerformanceMonitor creates a new performance monitor
func NewPerformanceMonitor(db *sql.DB) *PerformanceMonitor {
	return &PerformanceMonitor{
		db: db,
	}
}

// GetIndexUsageStats retrieves index usage statistics
func (pm *PerformanceMonitor) GetIndexUsageStats(ctx context.Context) ([]IndexUsageStats, error) {
	query := `
		SELECT 
			schemaname,
			tablename,
			indexname,
			idx_scan as scans,
			idx_tup_read as tuples_read,
			idx_tup_fetch as tuples_fetched,
			CASE 
				WHEN idx_scan = 0 THEN 'UNUSED'
				WHEN idx_scan < 100 THEN 'LOW_USAGE'
				WHEN idx_scan < 1000 THEN 'MODERATE_USAGE'
				ELSE 'HIGH_USAGE'
			END as usage_level,
			pg_size_pretty(pg_relation_size(indexrelid)) as index_size
		FROM pg_stat_user_indexes 
		WHERE schemaname = 'public'
		ORDER BY idx_scan DESC, pg_relation_size(indexrelid) DESC;
	`

	rows, err := pm.db.QueryContext(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("failed to query index usage stats: %w", err)
	}
	defer rows.Close()

	var stats []IndexUsageStats
	for rows.Next() {
		var stat IndexUsageStats
		err := rows.Scan(
			&stat.SchemaName,
			&stat.TableName,
			&stat.IndexName,
			&stat.Scans,
			&stat.TuplesRead,
			&stat.TuplesFetch,
			&stat.UsageLevel,
			&stat.IndexSize,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan index usage stats: %w", err)
		}
		stats = append(stats, stat)
	}

	return stats, nil
}

// GetTableStats retrieves table statistics
func (pm *PerformanceMonitor) GetTableStats(ctx context.Context) ([]TableStats, error) {
	query := `
		SELECT 
			schemaname,
			relname as tablename,
			seq_scan as sequential_scans,
			seq_tup_read as seq_tuples_read,
			idx_scan as index_scans,
			idx_tup_fetch as idx_tuples_fetched,
			n_tup_ins as inserts,
			n_tup_upd as updates,
			n_tup_del as deletes,
			ROUND(100.0 * seq_scan / GREATEST(seq_scan + idx_scan, 1), 2) as seq_scan_percentage,
			pg_size_pretty(pg_total_relation_size(relid)) as total_size
		FROM pg_stat_user_tables 
		WHERE schemaname = 'public'
		ORDER BY seq_scan DESC, pg_total_relation_size(relid) DESC;
	`

	rows, err := pm.db.QueryContext(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("failed to query table stats: %w", err)
	}
	defer rows.Close()

	var stats []TableStats
	for rows.Next() {
		var stat TableStats
		err := rows.Scan(
			&stat.SchemaName,
			&stat.TableName,
			&stat.SequentialScans,
			&stat.SeqTuplesRead,
			&stat.IndexScans,
			&stat.IdxTuplesFetch,
			&stat.Inserts,
			&stat.Updates,
			&stat.Deletes,
			&stat.SeqScanPercentage,
			&stat.TotalSize,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan table stats: %w", err)
		}
		stats = append(stats, stat)
	}

	return stats, nil
}

// GetCacheHitRatio retrieves cache hit ratio statistics
func (pm *PerformanceMonitor) GetCacheHitRatio(ctx context.Context) (CacheStats, error) {
	var stats CacheStats

	// Buffer cache hit ratio
	bufferQuery := `
		SELECT ROUND(100.0 * sum(blks_hit) / GREATEST(sum(blks_hit) + sum(blks_read), 1), 2) as percentage
		FROM pg_stat_database 
		WHERE datname = current_database();
	`

	err := pm.db.QueryRowContext(ctx, bufferQuery).Scan(&stats.BufferCacheHitRatio)
	if err != nil {
		return stats, fmt.Errorf("failed to query buffer cache hit ratio: %w", err)
	}

	// Index cache hit ratio
	indexQuery := `
		SELECT ROUND(100.0 * sum(idx_blks_hit) / GREATEST(sum(idx_blks_hit) + sum(idx_blks_read), 1), 2) as percentage
		FROM pg_statio_user_indexes;
	`

	err = pm.db.QueryRowContext(ctx, indexQuery).Scan(&stats.IndexCacheHitRatio)
	if err != nil {
		return stats, fmt.Errorf("failed to query index cache hit ratio: %w", err)
	}

	return stats, nil
}

// GetOptimizationRecommendations retrieves optimization recommendations
func (pm *PerformanceMonitor) GetOptimizationRecommendations(ctx context.Context) ([]OptimizationRecommendation, error) {
	query := `SELECT * FROM analyze_missing_indexes();`

	rows, err := pm.db.QueryContext(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("failed to query optimization recommendations: %w", err)
	}
	defer rows.Close()

	var recommendations []OptimizationRecommendation
	for rows.Next() {
		var rec OptimizationRecommendation
		err := rows.Scan(
			&rec.Type,
			&rec.TableName,
			&rec.ColumnNames,
			&rec.Rationale,
			&rec.EstimatedBenefit,
			&rec.SQLCommand,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan optimization recommendation: %w", err)
		}
		recommendations = append(recommendations, rec)
	}

	return recommendations, nil
}

// RunOptimization executes automatic database optimization
func (pm *PerformanceMonitor) RunOptimization(ctx context.Context) (string, error) {
	query := `SELECT run_database_optimization();`

	var result string
	err := pm.db.QueryRowContext(ctx, query).Scan(&result)
	if err != nil {
		return "", fmt.Errorf("failed to run database optimization: %w", err)
	}

	logger.InfoWithFields(logger.Fields{
		"component": "performance",
		"operation": "optimization",
		"result":    result,
	}, "Database optimization completed")

	return result, nil
}

// GetPerformanceMetrics retrieves comprehensive performance metrics
func (pm *PerformanceMonitor) GetPerformanceMetrics(ctx context.Context) (*PerformanceMetrics, error) {
	metrics := &PerformanceMetrics{}

	// Get index usage stats
	indexStats, err := pm.GetIndexUsageStats(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get index usage stats: %w", err)
	}
	metrics.IndexUsage = indexStats

	// Get table stats
	tableStats, err := pm.GetTableStats(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get table stats: %w", err)
	}
	metrics.TableStats = tableStats

	// Get cache hit ratio
	cacheStats, err := pm.GetCacheHitRatio(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get cache hit ratio: %w", err)
	}
	metrics.CacheHitRatio = cacheStats

	return metrics, nil
}

// MonitorPerformanceContinuously starts continuous performance monitoring
func (pm *PerformanceMonitor) MonitorPerformanceContinuously(ctx context.Context, interval time.Duration) {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()

	logger.InfoWithFields(logger.Fields{
		"component": "performance",
		"interval":  interval,
	}, "Starting continuous performance monitoring")

	for {
		select {
		case <-ctx.Done():
			logger.Info("Stopping performance monitoring")
			return
		case <-ticker.C:
			metrics, err := pm.GetPerformanceMetrics(ctx)
			if err != nil {
				logger.ErrorWithFields(logger.Fields{
					"component": "performance",
					"error":     err.Error(),
				}, "Failed to get performance metrics")
				continue
			}

			// Log performance summary
			pm.logPerformanceSummary(metrics)

			// Check for performance issues
			pm.checkPerformanceIssues(ctx, metrics)
		}
	}
}

// logPerformanceSummary logs a summary of performance metrics
func (pm *PerformanceMonitor) logPerformanceSummary(metrics *PerformanceMetrics) {
	// Count unused indexes
	unusedIndexes := 0
	for _, idx := range metrics.IndexUsage {
		if idx.UsageLevel == "UNUSED" {
			unusedIndexes++
		}
	}

	// Count high sequential scan tables
	highSeqScanTables := 0
	for _, table := range metrics.TableStats {
		if table.SeqScanPercentage > 50 {
			highSeqScanTables++
		}
	}

	logger.InfoWithFields(logger.Fields{
		"component":            "performance",
		"unused_indexes":       unusedIndexes,
		"high_seq_scan_tables": highSeqScanTables,
		"buffer_cache_hit":     metrics.CacheHitRatio.BufferCacheHitRatio,
		"index_cache_hit":      metrics.CacheHitRatio.IndexCacheHitRatio,
	}, "Performance monitoring summary")
}

// checkPerformanceIssues checks for performance issues and logs warnings
func (pm *PerformanceMonitor) checkPerformanceIssues(ctx context.Context, metrics *PerformanceMetrics) {
	// Check for low cache hit ratios
	if metrics.CacheHitRatio.BufferCacheHitRatio < 95 {
		logger.WarnWithFields(logger.Fields{
			"component":       "performance",
			"issue":           "low_buffer_cache_hit",
			"cache_hit_ratio": metrics.CacheHitRatio.BufferCacheHitRatio,
			"recommendation":  "consider_increasing_shared_buffers",
		}, "Low buffer cache hit ratio detected")
	}

	// Check for high sequential scan ratios
	for _, table := range metrics.TableStats {
		if table.SeqScanPercentage > 75 && table.SequentialScans > 100 {
			logger.WarnWithFields(logger.Fields{
				"component":           "performance",
				"issue":               "high_sequential_scans",
				"table":               table.TableName,
				"seq_scan_percentage": table.SeqScanPercentage,
				"sequential_scans":    table.SequentialScans,
				"recommendation":      "consider_adding_indexes",
			}, "High sequential scan ratio detected")
		}
	}

	// Check for unused indexes
	for _, idx := range metrics.IndexUsage {
		if idx.UsageLevel == "UNUSED" && idx.Scans == 0 {
			logger.WarnWithFields(logger.Fields{
				"component":      "performance",
				"issue":          "unused_index",
				"table":          idx.TableName,
				"index":          idx.IndexName,
				"index_size":     idx.IndexSize,
				"recommendation": "consider_dropping_index",
			}, "Unused index detected")
		}
	}
}
