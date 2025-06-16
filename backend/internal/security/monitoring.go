package security

import (
	"encoding/json"
	"fmt"
	"sync"
	"time"

	"github.com/toeic-app/internal/logger"
)

// SecurityEvent represents a security-related event
type SecurityEvent struct {
	ID          string                 `json:"id"`
	Timestamp   time.Time              `json:"timestamp"`
	Type        SecurityEventType      `json:"type"`
	Severity    SecuritySeverity       `json:"severity"`
	Source      string                 `json:"source"`
	UserID      int64                  `json:"user_id,omitempty"`
	IPAddress   string                 `json:"ip_address"`
	UserAgent   string                 `json:"user_agent"`
	Path        string                 `json:"path"`
	Method      string                 `json:"method"`
	Description string                 `json:"description"`
	Details     map[string]interface{} `json:"details,omitempty"`
	Resolved    bool                   `json:"resolved"`
	ResolvedAt  *time.Time             `json:"resolved_at,omitempty"`
	ResolvedBy  string                 `json:"resolved_by,omitempty"`
}

// SecurityEventType represents types of security events
type SecurityEventType string

const (
	EventTypeAuthFailure          SecurityEventType = "auth_failure"
	EventTypeRateLimitExceeded    SecurityEventType = "rate_limit_exceeded"
	EventTypeSuspiciousActivity   SecurityEventType = "suspicious_activity"
	EventTypeInputValidation      SecurityEventType = "input_validation"
	EventTypeUnauthorizedAccess   SecurityEventType = "unauthorized_access"
	EventTypeDataBreach           SecurityEventType = "data_breach"
	EventTypeAccountLockout       SecurityEventType = "account_lockout"
	EventTypePasswordChange       SecurityEventType = "password_change"
	EventTypePermissionEscalation SecurityEventType = "permission_escalation"
	EventTypeConfigurationChange  SecurityEventType = "configuration_change"
)

// SecuritySeverity represents the severity of a security event
type SecuritySeverity string

const (
	SeverityLow      SecuritySeverity = "low"
	SeverityMedium   SecuritySeverity = "medium"
	SeverityHigh     SecuritySeverity = "high"
	SeverityCritical SecuritySeverity = "critical"
)

// SecurityMonitor handles security event monitoring and alerting
type SecurityMonitor struct {
	events          []SecurityEvent
	mu              sync.RWMutex
	alertThresholds map[SecurityEventType]AlertThreshold
	alertHandler    AlertHandler
}

// AlertThreshold defines when to trigger alerts
type AlertThreshold struct {
	EventType    SecurityEventType `json:"event_type"`
	Count        int               `json:"count"`
	TimeWindow   time.Duration     `json:"time_window"`
	Severity     SecuritySeverity  `json:"severity"`
	AutoResolve  bool              `json:"auto_resolve"`
	ResolveAfter time.Duration     `json:"resolve_after"`
}

// AlertHandler interface for handling security alerts
type AlertHandler interface {
	HandleAlert(alert SecurityAlert) error
}

// SecurityAlert represents an alert triggered by security events
type SecurityAlert struct {
	ID          string            `json:"id"`
	Timestamp   time.Time         `json:"timestamp"`
	Type        SecurityEventType `json:"type"`
	Severity    SecuritySeverity  `json:"severity"`
	Description string            `json:"description"`
	EventCount  int               `json:"event_count"`
	TimeWindow  time.Duration     `json:"time_window"`
	Events      []SecurityEvent   `json:"events"`
	Resolved    bool              `json:"resolved"`
}

// NewSecurityMonitor creates a new security monitor
func NewSecurityMonitor(alertHandler AlertHandler) *SecurityMonitor {
	monitor := &SecurityMonitor{
		events:       make([]SecurityEvent, 0),
		alertHandler: alertHandler,
		alertThresholds: map[SecurityEventType]AlertThreshold{
			EventTypeAuthFailure: {
				EventType:    EventTypeAuthFailure,
				Count:        5,
				TimeWindow:   5 * time.Minute,
				Severity:     SeverityMedium,
				AutoResolve:  true,
				ResolveAfter: 30 * time.Minute,
			},
			EventTypeRateLimitExceeded: {
				EventType:    EventTypeRateLimitExceeded,
				Count:        10,
				TimeWindow:   1 * time.Minute,
				Severity:     SeverityLow,
				AutoResolve:  true,
				ResolveAfter: 10 * time.Minute,
			},
			EventTypeSuspiciousActivity: {
				EventType:    EventTypeSuspiciousActivity,
				Count:        3,
				TimeWindow:   10 * time.Minute,
				Severity:     SeverityHigh,
				AutoResolve:  false,
				ResolveAfter: 0,
			},
			EventTypeUnauthorizedAccess: {
				EventType:    EventTypeUnauthorizedAccess,
				Count:        1,
				TimeWindow:   1 * time.Minute,
				Severity:     SeverityCritical,
				AutoResolve:  false,
				ResolveAfter: 0,
			},
		},
	}

	// Start background processes
	go monitor.cleanupOldEvents()
	go monitor.checkAlertThresholds()

	return monitor
}

// LogSecurityEvent logs a security event
func (sm *SecurityMonitor) LogSecurityEvent(event SecurityEvent) {
	// Set timestamp and ID if not provided
	if event.Timestamp.IsZero() {
		event.Timestamp = time.Now()
	}
	if event.ID == "" {
		event.ID = generateEventID()
	}

	sm.mu.Lock()
	sm.events = append(sm.events, event)
	sm.mu.Unlock()

	// Log the event
	logger.InfoWithFields(logger.Fields{
		"component":   "security_monitor",
		"event_id":    event.ID,
		"event_type":  string(event.Type),
		"severity":    string(event.Severity),
		"source":      event.Source,
		"user_id":     event.UserID,
		"ip_address":  event.IPAddress,
		"path":        event.Path,
		"method":      event.Method,
		"description": event.Description,
	}, "Security event logged")

	// Check for immediate critical events
	if event.Severity == SeverityCritical {
		go sm.triggerImmediateAlert(event)
	}
}

// GetEvents returns security events with optional filtering
func (sm *SecurityMonitor) GetEvents(eventType *SecurityEventType, severity *SecuritySeverity, since *time.Time, limit int) []SecurityEvent {
	sm.mu.RLock()
	defer sm.mu.RUnlock()

	var filtered []SecurityEvent
	for _, event := range sm.events {
		// Apply filters
		if eventType != nil && event.Type != *eventType {
			continue
		}
		if severity != nil && event.Severity != *severity {
			continue
		}
		if since != nil && event.Timestamp.Before(*since) {
			continue
		}

		filtered = append(filtered, event)

		// Apply limit
		if limit > 0 && len(filtered) >= limit {
			break
		}
	}

	return filtered
}

// GetEventStats returns statistics about security events
func (sm *SecurityMonitor) GetEventStats(timeWindow time.Duration) map[SecurityEventType]int {
	since := time.Now().Add(-timeWindow)
	sm.mu.RLock()
	defer sm.mu.RUnlock()

	stats := make(map[SecurityEventType]int)
	for _, event := range sm.events {
		if event.Timestamp.After(since) {
			stats[event.Type]++
		}
	}

	return stats
}

// cleanupOldEvents removes old events to prevent memory leaks
func (sm *SecurityMonitor) cleanupOldEvents() {
	ticker := time.NewTicker(1 * time.Hour)
	defer ticker.Stop()

	for range ticker.C {
		cutoff := time.Now().Add(-24 * time.Hour) // Keep events for 24 hours

		sm.mu.Lock()
		var keepEvents []SecurityEvent
		for _, event := range sm.events {
			if event.Timestamp.After(cutoff) {
				keepEvents = append(keepEvents, event)
			}
		}
		sm.events = keepEvents
		sm.mu.Unlock()

		logger.Debug("Cleaned up old security events")
	}
}

// checkAlertThresholds checks if any alert thresholds are exceeded
func (sm *SecurityMonitor) checkAlertThresholds() {
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	for range ticker.C {
		for eventType, threshold := range sm.alertThresholds {
			sm.checkThreshold(eventType, threshold)
		}
	}
}

// checkThreshold checks a specific threshold
func (sm *SecurityMonitor) checkThreshold(eventType SecurityEventType, threshold AlertThreshold) {
	since := time.Now().Add(-threshold.TimeWindow)

	sm.mu.RLock()
	var recentEvents []SecurityEvent
	for _, event := range sm.events {
		if event.Type == eventType && event.Timestamp.After(since) {
			recentEvents = append(recentEvents, event)
		}
	}
	sm.mu.RUnlock()

	if len(recentEvents) >= threshold.Count {
		alert := SecurityAlert{
			ID:          generateAlertID(),
			Timestamp:   time.Now(),
			Type:        eventType,
			Severity:    threshold.Severity,
			Description: fmt.Sprintf("Security threshold exceeded: %d %s events in %v", len(recentEvents), eventType, threshold.TimeWindow),
			EventCount:  len(recentEvents),
			TimeWindow:  threshold.TimeWindow,
			Events:      recentEvents,
			Resolved:    false,
		}

		if sm.alertHandler != nil {
			go sm.alertHandler.HandleAlert(alert)
		}
	}
}

// triggerImmediateAlert triggers an immediate alert for critical events
func (sm *SecurityMonitor) triggerImmediateAlert(event SecurityEvent) {
	alert := SecurityAlert{
		ID:          generateAlertID(),
		Timestamp:   time.Now(),
		Type:        event.Type,
		Severity:    event.Severity,
		Description: fmt.Sprintf("Critical security event: %s", event.Description),
		EventCount:  1,
		TimeWindow:  0,
		Events:      []SecurityEvent{event},
		Resolved:    false,
	}

	if sm.alertHandler != nil {
		sm.alertHandler.HandleAlert(alert)
	}
}

// DefaultAlertHandler is a simple alert handler that logs alerts
type DefaultAlertHandler struct{}

// HandleAlert handles security alerts
func (h *DefaultAlertHandler) HandleAlert(alert SecurityAlert) error {
	alertJSON, _ := json.Marshal(alert)

	logger.ErrorWithFields(logger.Fields{
		"component":   "security_alert",
		"alert_id":    alert.ID,
		"alert_type":  string(alert.Type),
		"severity":    string(alert.Severity),
		"event_count": alert.EventCount,
		"time_window": alert.TimeWindow.String(),
	}, "Security alert triggered: %s", alert.Description)

	// In production, this could send notifications via:
	// - Email
	// - Slack/Teams
	// - PagerDuty
	// - SMS
	// - Webhook

	logger.Debug("Alert details: %s", string(alertJSON))
	return nil
}

// generateEventID generates a unique event ID
func generateEventID() string {
	return fmt.Sprintf("evt_%d", time.Now().UnixNano())
}

// generateAlertID generates a unique alert ID
func generateAlertID() string {
	return fmt.Sprintf("alt_%d", time.Now().UnixNano())
}

// SecurityMetrics holds security-related metrics
type SecurityMetrics struct {
	TotalEvents      int64                       `json:"total_events"`
	EventsByType     map[SecurityEventType]int64 `json:"events_by_type"`
	EventsBySeverity map[SecuritySeverity]int64  `json:"events_by_severity"`
	ActiveAlerts     int64                       `json:"active_alerts"`
	ResolvedAlerts   int64                       `json:"resolved_alerts"`
	AvgResponseTime  time.Duration               `json:"avg_response_time"`
	LastUpdate       time.Time                   `json:"last_update"`
}

// GetSecurityMetrics returns current security metrics
func (sm *SecurityMonitor) GetSecurityMetrics() SecurityMetrics {
	sm.mu.RLock()
	defer sm.mu.RUnlock()

	metrics := SecurityMetrics{
		EventsByType:     make(map[SecurityEventType]int64),
		EventsBySeverity: make(map[SecuritySeverity]int64),
		LastUpdate:       time.Now(),
	}

	for _, event := range sm.events {
		metrics.TotalEvents++
		metrics.EventsByType[event.Type]++
		metrics.EventsBySeverity[event.Severity]++
	}

	return metrics
}
