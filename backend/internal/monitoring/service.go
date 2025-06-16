package monitoring

import (
	"context"
	"database/sql"
	"time"

	"github.com/toeic-app/internal/cache"
	"github.com/toeic-app/internal/config"
	"github.com/toeic-app/internal/logger"
)

// MonitoringService is the main monitoring service that coordinates all monitoring components
type MonitoringService struct {
	Monitor   *Monitor
	Health    *HealthService
	Alerts    *AlertManager
	config    *MonitoringConfig
	db        *sql.DB
	cache     cache.Cache
	appConfig config.Config
}

// MonitoringConfig holds configuration for all monitoring components
type MonitoringConfig struct {
	Enabled        bool
	MetricsEnabled bool
	HealthEnabled  bool
	AlertsEnabled  bool

	// Metrics configuration
	MetricsConfig *MetricsConfig

	// Health configuration
	HealthConfig *HealthConfig

	// Alerts configuration
	AlertConfig *AlertConfig

	// External services to monitor
	ExternalServices []ExternalServiceConfig
}

// ExternalServiceConfig configuration for external service monitoring
type ExternalServiceConfig struct {
	Name    string
	URL     string
	Timeout time.Duration
}

// DefaultMonitoringConfig returns default monitoring configuration
func DefaultMonitoringConfig() *MonitoringConfig {
	return &MonitoringConfig{
		Enabled:          true,
		MetricsEnabled:   true,
		HealthEnabled:    true,
		AlertsEnabled:    true,
		MetricsConfig:    DefaultMetricsConfig(),
		HealthConfig:     DefaultHealthConfig(),
		AlertConfig:      DefaultAlertConfig(),
		ExternalServices: []ExternalServiceConfig{
			// Add external services here as needed
		},
	}
}

// NewMonitoringService creates a new monitoring service
func NewMonitoringService(db *sql.DB, cache cache.Cache, appConfig config.Config, monitoringConfig *MonitoringConfig) *MonitoringService {
	if monitoringConfig == nil {
		monitoringConfig = DefaultMonitoringConfig()
	}

	// Create monitoring components
	var monitor *Monitor
	var healthService *HealthService
	var alertManager *AlertManager

	if monitoringConfig.MetricsEnabled {
		monitor = NewMonitor(db, cache, appConfig, monitoringConfig.MetricsConfig)
	}

	if monitoringConfig.HealthEnabled {
		healthService = NewHealthService("1.0.0", monitoringConfig.HealthConfig)

		// Register default health checkers
		if db != nil {
			dbChecker := NewDatabaseHealthChecker(db, "database", 5*time.Second)
			healthService.RegisterChecker(dbChecker)
		}

		if cache != nil {
			cacheChecker := NewCacheHealthChecker(cache, "cache", 5*time.Second)
			healthService.RegisterChecker(cacheChecker)
		}

		// Register external service health checkers
		for _, extService := range monitoringConfig.ExternalServices {
			extChecker := NewExternalServiceHealthChecker(extService.Name, extService.URL, extService.Timeout)
			healthService.RegisterChecker(extChecker)
		}
	}

	if monitoringConfig.AlertsEnabled {
		alertManager = NewAlertManager(monitoringConfig.AlertConfig)

		// Register common alert rules if health and monitor are available
		if monitor != nil && healthService != nil {
			rules := CreateCommonAlertRules(monitor, healthService)
			for _, rule := range rules {
				alertManager.RegisterRule(rule)
			}
		}
	}

	return &MonitoringService{
		Monitor:   monitor,
		Health:    healthService,
		Alerts:    alertManager,
		config:    monitoringConfig,
		db:        db,
		cache:     cache,
		appConfig: appConfig,
	}
}

// Start starts all monitoring services
func (ms *MonitoringService) Start(ctx context.Context) {
	if !ms.config.Enabled {
		logger.Info("Monitoring service is disabled")
		return
	}

	logger.Info("Starting monitoring service...")

	// Start metrics collection
	if ms.Monitor != nil && ms.config.MetricsEnabled {
		ms.Monitor.Start()
		logger.Info("Metrics monitoring started")
	}

	// Start health service
	if ms.Health != nil && ms.config.HealthEnabled {
		ms.Health.Start(ctx)
		logger.Info("Health monitoring started")
	}

	// Start alert manager
	if ms.Alerts != nil && ms.config.AlertsEnabled {
		ms.Alerts.Start(ctx)
		logger.Info("Alert manager started")
	}

	logger.Info("Monitoring service started successfully")
}

// GetMetricsMiddleware returns middleware for metrics collection
func (ms *MonitoringService) GetMetricsMiddleware() func(interface{}) interface{} {
	if ms.Monitor == nil || !ms.config.MetricsEnabled {
		return nil
	}

	// Return a generic interface that can be type-asserted to gin.HandlerFunc
	return func(interface{}) interface{} {
		return ms.Monitor.MetricsMiddleware()
	}
}

// IsEnabled returns whether monitoring is enabled
func (ms *MonitoringService) IsEnabled() bool {
	return ms.config.Enabled
}

// GetMonitor returns the monitor instance
func (ms *MonitoringService) GetMonitor() *Monitor {
	return ms.Monitor
}

// GetHealthService returns the health service instance
func (ms *MonitoringService) GetHealthService() *HealthService {
	return ms.Health
}

// GetAlertManager returns the alert manager instance
func (ms *MonitoringService) GetAlertManager() *AlertManager {
	return ms.Alerts
}

// GetConfig returns the monitoring configuration
func (ms *MonitoringService) GetConfig() *MonitoringConfig {
	return ms.config
}
