package notification

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/toeic-app/internal/config"
	"github.com/toeic-app/internal/logger"
)

// NotificationManager handles backup/restore notifications
type NotificationManager struct {
	config config.BackupConfig
}

// SlackMessage represents a Slack webhook message
type SlackMessage struct {
	Text        string            `json:"text"`
	Username    string            `json:"username,omitempty"`
	Channel     string            `json:"channel,omitempty"`
	IconEmoji   string            `json:"icon_emoji,omitempty"`
	Attachments []SlackAttachment `json:"attachments,omitempty"`
}

// SlackAttachment represents a Slack message attachment
type SlackAttachment struct {
	Color     string       `json:"color"`
	Title     string       `json:"title"`
	Text      string       `json:"text"`
	Fields    []SlackField `json:"fields,omitempty"`
	Timestamp int64        `json:"ts"`
}

// SlackField represents a field in a Slack attachment
type SlackField struct {
	Title string `json:"title"`
	Value string `json:"value"`
	Short bool   `json:"short"`
}

// BackupMetadata represents backup metadata for notifications
type BackupMetadata struct {
	Filename     string    `json:"filename"`
	Size         int64     `json:"size"`
	CreatedAt    time.Time `json:"created_at"`
	Description  string    `json:"description"`
	Compressed   bool      `json:"compressed"`
	Encrypted    bool      `json:"encrypted"`
	DatabaseName string    `json:"database_name"`
	Type         string    `json:"type"`
}

// NewNotificationManager creates a new notification manager
func NewNotificationManager(config config.BackupConfig) *NotificationManager {
	return &NotificationManager{
		config: config,
	}
}

// NotifyBackupSuccess sends a notification for successful backup
func (nm *NotificationManager) NotifyBackupSuccess(metadata *BackupMetadata) {
	if !nm.config.NotifyOnSuccess {
		return
	}

	message := fmt.Sprintf("✅ Database backup completed successfully: %s", metadata.Filename)

	// Send to Slack if configured
	if nm.config.SlackWebhookURL != "" {
		nm.sendSlackNotification(message, "good", metadata, nil)
	}

	// Send to webhook if configured
	if nm.config.WebhookURL != "" {
		nm.sendWebhookNotification("backup.success", metadata, nil)
	}

	logger.Info("Backup success notification sent")
}

// NotifyBackupFailure sends a notification for failed backup
func (nm *NotificationManager) NotifyBackupFailure(filename string, err error) {
	if !nm.config.NotifyOnFailure {
		return
	}

	message := fmt.Sprintf("❌ Database backup failed: %s - Error: %v", filename, err)

	// Send to Slack if configured
	if nm.config.SlackWebhookURL != "" {
		nm.sendSlackNotification(message, "danger", nil, err)
	}

	// Send to webhook if configured
	if nm.config.WebhookURL != "" {
		nm.sendWebhookNotification("backup.failure", nil, err)
	}

	logger.Info("Backup failure notification sent")
}

// NotifyRestoreSuccess sends a notification for successful restore
func (nm *NotificationManager) NotifyRestoreSuccess(filename string, duration time.Duration) {
	if !nm.config.NotifyOnSuccess {
		return
	}

	message := fmt.Sprintf("✅ Database restore completed successfully from: %s (duration: %v)", filename, duration)

	// Send to Slack if configured
	if nm.config.SlackWebhookURL != "" {
		nm.sendSlackNotification(message, "good", nil, nil)
	}

	// Send to webhook if configured
	if nm.config.WebhookURL != "" {
		nm.sendWebhookNotification("restore.success", map[string]interface{}{
			"filename": filename,
			"duration": duration.String(),
		}, nil)
	}

	logger.Info("Restore success notification sent")
}

// NotifyRestoreFailure sends a notification for failed restore
func (nm *NotificationManager) NotifyRestoreFailure(filename string, err error) {
	if !nm.config.NotifyOnFailure {
		return
	}

	message := fmt.Sprintf("❌ Database restore failed from: %s - Error: %v", filename, err)

	// Send to Slack if configured
	if nm.config.SlackWebhookURL != "" {
		nm.sendSlackNotification(message, "danger", nil, err)
	}

	// Send to webhook if configured
	if nm.config.WebhookURL != "" {
		nm.sendWebhookNotification("restore.failure", map[string]interface{}{
			"filename": filename,
		}, err)
	}

	logger.Info("Restore failure notification sent")
}

// sendSlackNotification sends a notification to Slack
func (nm *NotificationManager) sendSlackNotification(message, color string, metadata *BackupMetadata, err error) {
	attachment := SlackAttachment{
		Color:     color,
		Title:     "TOEIC Database Backup/Restore",
		Text:      message,
		Timestamp: time.Now().Unix(),
	}

	// Add metadata fields if available
	if metadata != nil {
		attachment.Fields = []SlackField{
			{Title: "Filename", Value: metadata.Filename, Short: true},
			{Title: "Size", Value: formatBytes(metadata.Size), Short: true},
			{Title: "Database", Value: metadata.DatabaseName, Short: true},
			{Title: "Type", Value: metadata.Type, Short: true},
		}

		if metadata.Compressed {
			attachment.Fields = append(attachment.Fields, SlackField{
				Title: "Compressed", Value: "Yes", Short: true,
			})
		}

		if metadata.Encrypted {
			attachment.Fields = append(attachment.Fields, SlackField{
				Title: "Encrypted", Value: "Yes", Short: true,
			})
		}
	}

	// Add error details if present
	if err != nil {
		attachment.Fields = append(attachment.Fields, SlackField{
			Title: "Error", Value: err.Error(), Short: false,
		})
	}

	slackMsg := SlackMessage{
		Username:    "Backup Bot",
		IconEmoji:   ":floppy_disk:",
		Attachments: []SlackAttachment{attachment},
	}

	// Send the message
	if err := nm.sendHTTPNotification(nm.config.SlackWebhookURL, slackMsg); err != nil {
		logger.Error("Failed to send Slack notification: %v", err)
	}
}

// sendWebhookNotification sends a notification to a generic webhook
func (nm *NotificationManager) sendWebhookNotification(event string, data interface{}, err error) {
	payload := map[string]interface{}{
		"event":     event,
		"timestamp": time.Now().Unix(),
		"data":      data,
	}

	if err != nil {
		payload["error"] = err.Error()
	}

	if err := nm.sendHTTPNotification(nm.config.WebhookURL, payload); err != nil {
		logger.Error("Failed to send webhook notification: %v", err)
	}
}

// sendHTTPNotification sends an HTTP POST notification
func (nm *NotificationManager) sendHTTPNotification(url string, payload interface{}) error {
	jsonData, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal notification payload: %w", err)
	}

	req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonData))
	if err != nil {
		return fmt.Errorf("failed to create notification request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("User-Agent", "TOEIC-Backup-Manager/1.0")

	client := &http.Client{
		Timeout: 10 * time.Second,
	}

	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to send notification: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 {
		return fmt.Errorf("notification request failed with status: %d", resp.StatusCode)
	}

	return nil
}

// formatBytes formats byte count as human readable string
func formatBytes(bytes int64) string {
	const unit = 1024
	if bytes < unit {
		return fmt.Sprintf("%d B", bytes)
	}
	div, exp := int64(unit), 0
	for n := bytes / unit; n >= unit; n /= unit {
		div *= unit
		exp++
	}
	return fmt.Sprintf("%.1f %cB", float64(bytes)/float64(div), "KMGTPE"[exp])
}
