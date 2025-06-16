package monitoring

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/toeic-app/internal/logger"
)

// AlertLevel represents the severity of an alert
type AlertLevel string

const (
	AlertLevelInfo     AlertLevel = "INFO"
	AlertLevelWarning  AlertLevel = "WARNING"
	AlertLevelCritical AlertLevel = "CRITICAL"
)

// Alert represents a monitoring alert
type Alert struct {
	ID         string                 `json:"id"`
	Name       string                 `json:"name"`
	Level      AlertLevel             `json:"level"`
	Message    string                 `json:"message"`
	Details    map[string]interface{} `json:"details,omitempty"`
	Timestamp  time.Time              `json:"timestamp"`
	Source     string                 `json:"source"`
	Resolved   bool                   `json:"resolved"`
	ResolvedAt *time.Time             `json:"resolved_at,omitempty"`
	Count      int                    `json:"count"` // Number of times this alert fired
	LastFired  time.Time              `json:"last_fired"`
}

// AlertRule defines conditions for triggering alerts
type AlertRule struct {
	Name        string
	Description string
	Level       AlertLevel
	Condition   func(ctx context.Context) (bool, string, map[string]interface{})
	Interval    time.Duration
	Threshold   int           // Number of consecutive failures before alerting
	Cooldown    time.Duration // Minimum time between alerts of the same type
}

// AlertManager manages monitoring alerts
type AlertManager struct {
	rules         map[string]*AlertRule
	activeAlerts  map[string]*Alert
	alertHistory  []*Alert
	failureCounts map[string]int
	lastAlertTime map[string]time.Time
	config        *AlertConfig
	notifiers     []AlertNotifier
	mu            sync.RWMutex
}

// AlertConfig configuration for alert manager
type AlertConfig struct {
	Enabled         bool
	MaxHistory      int
	CheckInterval   time.Duration
	DefaultCooldown time.Duration
}

// AlertNotifier interface for sending alerts
type AlertNotifier interface {
	SendAlert(alert *Alert) error
	GetName() string
}

// LogAlertNotifier sends alerts to the logger
type LogAlertNotifier struct {
	name string
}

// NewLogAlertNotifier creates a new log alert notifier
func NewLogAlertNotifier() *LogAlertNotifier {
	return &LogAlertNotifier{
		name: "log",
	}
}

func (l *LogAlertNotifier) GetName() string {
	return l.name
}

func (l *LogAlertNotifier) SendAlert(alert *Alert) error {
	switch alert.Level {
	case AlertLevelCritical:
		logger.Error("ALERT [%s] %s: %s", alert.Level, alert.Name, alert.Message)
	case AlertLevelWarning:
		logger.Warn("ALERT [%s] %s: %s", alert.Level, alert.Name, alert.Message)
	default:
		logger.Info("ALERT [%s] %s: %s", alert.Level, alert.Name, alert.Message)
	}

	if alert.Details != nil {
		if len(alert.Details) > 0 {
			logger.Debug("Alert details: %+v", alert.Details)
		}
	}

	return nil
}

// DefaultAlertConfig returns default alert configuration
func DefaultAlertConfig() *AlertConfig {
	return &AlertConfig{
		Enabled:         true,
		MaxHistory:      1000,
		CheckInterval:   30 * time.Second,
		DefaultCooldown: 5 * time.Minute,
	}
}

// NewAlertManager creates a new alert manager
func NewAlertManager(config *AlertConfig) *AlertManager {
	if config == nil {
		config = DefaultAlertConfig()
	}

	return &AlertManager{
		rules:         make(map[string]*AlertRule),
		activeAlerts:  make(map[string]*Alert),
		alertHistory:  make([]*Alert, 0),
		failureCounts: make(map[string]int),
		lastAlertTime: make(map[string]time.Time),
		config:        config,
		notifiers:     make([]AlertNotifier, 0),
	}
}

// AddNotifier adds an alert notifier
func (am *AlertManager) AddNotifier(notifier AlertNotifier) {
	am.mu.Lock()
	defer am.mu.Unlock()

	am.notifiers = append(am.notifiers, notifier)
	logger.Info("Alert notifier added: %s", notifier.GetName())
}

// RegisterRule registers an alert rule
func (am *AlertManager) RegisterRule(rule *AlertRule) {
	am.mu.Lock()
	defer am.mu.Unlock()

	am.rules[rule.Name] = rule
	logger.Info("Alert rule registered: %s (%s)", rule.Name, rule.Level)
}

// UnregisterRule unregisters an alert rule
func (am *AlertManager) UnregisterRule(name string) {
	am.mu.Lock()
	defer am.mu.Unlock()

	delete(am.rules, name)
	delete(am.failureCounts, name)
	delete(am.lastAlertTime, name)
	logger.Info("Alert rule unregistered: %s", name)
}

// CheckRules checks all registered alert rules
func (am *AlertManager) CheckRules(ctx context.Context) {
	am.mu.RLock()
	rules := make(map[string]*AlertRule)
	for name, rule := range am.rules {
		rules[name] = rule
	}
	am.mu.RUnlock()

	for name, rule := range rules {
		triggered, message, details := rule.Condition(ctx)

		if triggered {
			am.handleAlertTriggered(name, rule, message, details)
		} else {
			am.handleAlertResolved(name)
		}
	}
}

// handleAlertTriggered handles when an alert rule is triggered
func (am *AlertManager) handleAlertTriggered(name string, rule *AlertRule, message string, details map[string]interface{}) {
	am.mu.Lock()
	defer am.mu.Unlock()

	// Increment failure count
	am.failureCounts[name]++

	// Check if threshold is met
	if am.failureCounts[name] < rule.Threshold {
		return
	}

	// Check cooldown
	cooldown := rule.Cooldown
	if cooldown == 0 {
		cooldown = am.config.DefaultCooldown
	}

	if lastAlert, exists := am.lastAlertTime[name]; exists {
		if time.Since(lastAlert) < cooldown {
			return
		}
	}

	// Create or update alert
	alertID := fmt.Sprintf("%s_%d", name, time.Now().Unix())

	alert, exists := am.activeAlerts[name]
	if !exists {
		alert = &Alert{
			ID:        alertID,
			Name:      name,
			Level:     rule.Level,
			Source:    "monitoring",
			Timestamp: time.Now(),
			Count:     1,
		}
		am.activeAlerts[name] = alert
	} else {
		alert.Count++
		alert.LastFired = time.Now()
	}

	alert.Message = message
	alert.Details = details

	// Record alert time
	am.lastAlertTime[name] = time.Now()

	// Add to history
	historicalAlert := *alert // Copy
	am.alertHistory = append(am.alertHistory, &historicalAlert)

	// Trim history if needed
	if len(am.alertHistory) > am.config.MaxHistory {
		am.alertHistory = am.alertHistory[1:]
	}

	// Send notifications
	for _, notifier := range am.notifiers {
		go func(n AlertNotifier, a *Alert) {
			if err := n.SendAlert(a); err != nil {
				logger.Error("Failed to send alert via %s: %v", n.GetName(), err)
			}
		}(notifier, alert)
	}
}

// handleAlertResolved handles when an alert condition is no longer met
func (am *AlertManager) handleAlertResolved(name string) {
	am.mu.Lock()
	defer am.mu.Unlock()

	// Reset failure count
	am.failureCounts[name] = 0

	// Mark alert as resolved if it exists
	if alert, exists := am.activeAlerts[name]; exists && !alert.Resolved {
		alert.Resolved = true
		now := time.Now()
		alert.ResolvedAt = &now

		// Send resolution notification
		for _, notifier := range am.notifiers {
			go func(n AlertNotifier, a *Alert) {
				if err := n.SendAlert(a); err != nil {
					logger.Error("Failed to send alert resolution via %s: %v", n.GetName(), err)
				}
			}(notifier, alert)
		}

		// Remove from active alerts
		delete(am.activeAlerts, name)
	}
}

// GetActiveAlerts returns all active alerts
func (am *AlertManager) GetActiveAlerts() []*Alert {
	am.mu.RLock()
	defer am.mu.RUnlock()

	alerts := make([]*Alert, 0, len(am.activeAlerts))
	for _, alert := range am.activeAlerts {
		alertCopy := *alert
		alerts = append(alerts, &alertCopy)
	}

	return alerts
}

// GetAlertHistory returns recent alert history
func (am *AlertManager) GetAlertHistory(limit int) []*Alert {
	am.mu.RLock()
	defer am.mu.RUnlock()

	if limit <= 0 || limit > len(am.alertHistory) {
		limit = len(am.alertHistory)
	}

	start := len(am.alertHistory) - limit
	if start < 0 {
		start = 0
	}

	history := make([]*Alert, limit)
	copy(history, am.alertHistory[start:])

	return history
}

// Start starts the alert manager
func (am *AlertManager) Start(ctx context.Context) {
	if !am.config.Enabled {
		logger.Info("Alert manager is disabled")
		return
	}

	logger.Info("Starting alert manager with check interval: %v", am.config.CheckInterval)

	// Add default log notifier if no notifiers are configured
	if len(am.notifiers) == 0 {
		am.AddNotifier(NewLogAlertNotifier())
	}

	ticker := time.NewTicker(am.config.CheckInterval)
	go func() {
		defer ticker.Stop()

		for {
			select {
			case <-ticker.C:
				am.CheckRules(ctx)
			case <-ctx.Done():
				logger.Info("Alert manager stopped")
				return
			}
		}
	}()
}

// CreateCommonAlertRules creates common monitoring alert rules
func CreateCommonAlertRules(monitor *Monitor, healthService *HealthService) []*AlertRule {
	rules := []*AlertRule{
		// High error rate alert
		{
			Name:        "high_error_rate",
			Description: "High error rate detected",
			Level:       AlertLevelWarning,
			Threshold:   3,
			Cooldown:    5 * time.Minute,
			Condition: func(ctx context.Context) (bool, string, map[string]interface{}) {
				// This would check error rate from metrics
				// For now, return false as placeholder
				return false, "", nil
			},
		},

		// Database connection pool exhaustion
		{
			Name:        "db_connection_pool_exhausted",
			Description: "Database connection pool is nearly exhausted",
			Level:       AlertLevelCritical,
			Threshold:   2,
			Cooldown:    10 * time.Minute,
			Condition: func(ctx context.Context) (bool, string, map[string]interface{}) {
				health := healthService.CheckHealth(ctx)
				if dbHealth, exists := health.Components["database"]; exists {
					if openConns, ok := dbHealth.Details["open_connections"].(int); ok {
						if maxConns, ok := dbHealth.Details["max_open_connections"].(int); ok {
							if float64(openConns)/float64(maxConns) > 0.9 {
								return true, fmt.Sprintf("Database connection pool is %d%% full (%d/%d)",
										int(float64(openConns)/float64(maxConns)*100), openConns, maxConns),
									map[string]interface{}{
										"open_connections": openConns,
										"max_connections":  maxConns,
										"utilization":      float64(openConns) / float64(maxConns),
									}
							}
						}
					}
				}
				return false, "", nil
			},
		},

		// Service health check failures
		{
			Name:        "service_health_check_failed",
			Description: "Service health check is failing",
			Level:       AlertLevelCritical,
			Threshold:   2,
			Cooldown:    5 * time.Minute,
			Condition: func(ctx context.Context) (bool, string, map[string]interface{}) {
				health := healthService.CheckHealth(ctx)
				if health.Status == HealthStatusDown {
					downComponents := make([]string, 0)
					for name, component := range health.Components {
						if component.Status == HealthStatusDown {
							downComponents = append(downComponents, name)
						}
					}

					if len(downComponents) > 0 {
						return true, fmt.Sprintf("Health check failed for components: %v", downComponents),
							map[string]interface{}{
								"down_components":  downComponents,
								"total_components": len(health.Components),
								"overall_status":   health.Status,
							}
					}
				}
				return false, "", nil
			},
		},
	}

	return rules
}
