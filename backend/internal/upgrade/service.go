package upgrade

import (
	"fmt"
	"sort"
	"sync"
	"time"

	"github.com/toeic-app/internal/logger"
	"github.com/toeic-app/internal/websocket"
)

// Service handles app upgrade notifications and version management
type Service struct {
	wsManager      *websocket.Manager
	currentVersion *AppVersion
	versions       map[string]*AppVersion // version -> AppVersion
	mutex          sync.RWMutex
	subscribers    map[string]*Subscriber // userID -> subscriber preferences
	subMutex       sync.RWMutex
}

// AppVersion represents an application version
type AppVersion struct {
	Version     string            `json:"version"`
	Title       string            `json:"title"`
	Description string            `json:"description"`
	ReleaseDate time.Time         `json:"release_date"`
	Required    bool              `json:"required"`
	Changes     []string          `json:"changes"`
	Downloads   map[string]string `json:"downloads"` // platform -> download URL
	MinVersion  string            `json:"min_version,omitempty"`
	Deprecated  []string          `json:"deprecated,omitempty"` // versions that are deprecated
	Metadata    map[string]string `json:"metadata,omitempty"`
}

// Subscriber represents a user's subscription preferences
type Subscriber struct {
	UserID         string    `json:"user_id"`
	NotifyMajor    bool      `json:"notify_major"`
	NotifyMinor    bool      `json:"notify_minor"`
	NotifyPatches  bool      `json:"notify_patches"`
	NotifyRequired bool      `json:"notify_required"`
	LastNotified   time.Time `json:"last_notified"`
	ClientVersion  string    `json:"client_version,omitempty"`
	Platform       string    `json:"platform,omitempty"`
	SubscribedAt   time.Time `json:"subscribed_at"`
}

// UpdateCheckRequest represents a request to check for updates
type UpdateCheckRequest struct {
	CurrentVersion string `json:"current_version" binding:"required"`
	Platform       string `json:"platform,omitempty"`
	UserAgent      string `json:"user_agent,omitempty"`
}

// UpdateCheckResponse represents the response for update checks
type UpdateCheckResponse struct {
	HasUpdate      bool                             `json:"has_update"`
	LatestVersion  *AppVersion                      `json:"latest_version,omitempty"`
	UpdateRequired bool                             `json:"update_required"`
	Message        string                           `json:"message"`
	Notifications  []*websocket.UpgradeNotification `json:"notifications,omitempty"`
}

// NewService creates a new upgrade service
func NewService(wsManager *websocket.Manager) *Service {
	service := &Service{
		wsManager:   wsManager,
		versions:    make(map[string]*AppVersion),
		subscribers: make(map[string]*Subscriber),
	}

	// Set initial version
	service.currentVersion = &AppVersion{
		Version:     "1.0.0",
		Title:       "TOEIC App - Initial Release",
		Description: "Initial release of the TOEIC Learning Application",
		ReleaseDate: time.Now(),
		Required:    false,
		Changes: []string{
			"Initial release with core functionality",
			"User authentication system",
			"Vocabulary learning module",
			"Grammar exercises",
			"Practice tests",
		},
		Downloads: map[string]string{
			"android": "/downloads/toeic-app-1.0.0.apk",
			"ios":     "/downloads/toeic-app-1.0.0.ipa",
			"web":     "/",
		},
	}

	service.versions["1.0.0"] = service.currentVersion

	logger.Info("Upgrade service initialized with version: %s", service.currentVersion.Version)
	return service
}

// AddVersion adds a new version to the system
func (s *Service) AddVersion(version *AppVersion) error {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	if version.Version == "" {
		return fmt.Errorf("version string cannot be empty")
	}

	// Validate version format (basic validation)
	if !isValidVersionFormat(version.Version) {
		return fmt.Errorf("invalid version format: %s", version.Version)
	}

	s.versions[version.Version] = version

	// Update current version if this is the latest
	if isNewerVersion(version.Version, s.currentVersion.Version) {
		s.currentVersion = version
		logger.Info("Updated current version to: %s", version.Version)
	}

	logger.Info("Added new version: %s - %s", version.Version, version.Title)
	return nil
}

// NotifyUpgrade sends upgrade notification to all subscribed users
func (s *Service) NotifyUpgrade(version *AppVersion, targetUsers []string) error {
	if version == nil {
		return fmt.Errorf("version cannot be nil")
	}

	notification := websocket.UpgradeNotification{
		Version:     version.Version,
		Title:       version.Title,
		Description: version.Description,
		Required:    version.Required,
		ReleaseDate: version.ReleaseDate,
		Changes:     version.Changes,
	}

	// Add download URL for web platform
	if downloadURL, exists := version.Downloads["web"]; exists {
		notification.UpdateURL = downloadURL
	}

	// If specific users are targeted, send to them only
	if len(targetUsers) > 0 {
		for _, userID := range targetUsers {
			if err := s.wsManager.SendToUser(userID, "upgrade_notification", notification); err != nil {
				logger.Error("Failed to send upgrade notification to user %s: %v", userID, err)
			}
		}
		logger.Info("Sent targeted upgrade notification for version %s to %d users", version.Version, len(targetUsers))
		return nil
	}

	// Otherwise, broadcast to all connected users based on their preferences
	s.subMutex.RLock()
	connectedUsers := s.wsManager.GetConnectedUserIDs()
	s.subMutex.RUnlock()

	sentCount := 0
	for _, userID := range connectedUsers {
		if s.shouldNotifyUser(userID, version) {
			if err := s.wsManager.SendToUser(userID, "upgrade_notification", notification); err != nil {
				logger.Error("Failed to send upgrade notification to user %s: %v", userID, err)
			} else {
				sentCount++
			}
		}
	}

	// Also broadcast to all clients for general announcement
	if err := s.wsManager.BroadcastUpgradeNotification(notification); err != nil {
		logger.Error("Failed to broadcast upgrade notification: %v", err)
		return err
	}

	logger.Info("Sent upgrade notification for version %s to %d users", version.Version, sentCount)
	return nil
}

// CheckForUpdates checks if there's an update available for the given version
func (s *Service) CheckForUpdates(currentVersion, platform string) (*UpdateCheckResponse, error) {
	s.mutex.RLock()
	defer s.mutex.RUnlock()

	response := &UpdateCheckResponse{
		HasUpdate:      false,
		UpdateRequired: false,
		Message:        "You're running the latest version",
	}

	// Validate current version
	if !isValidVersionFormat(currentVersion) {
		response.Message = "Invalid version format provided"
		return response, nil
	}

	// Check if there's a newer version available
	if isNewerVersion(s.currentVersion.Version, currentVersion) {
		response.HasUpdate = true
		response.LatestVersion = s.currentVersion
		response.Message = fmt.Sprintf("New version %s is available", s.currentVersion.Version)

		// Check if update is required
		if s.currentVersion.Required || s.isVersionDeprecated(currentVersion) {
			response.UpdateRequired = true
			response.Message = fmt.Sprintf("Version %s is required. Please update immediately.", s.currentVersion.Version)
		}

		// Get all newer versions for notifications
		newerVersions := s.getNewerVersions(currentVersion)
		response.Notifications = make([]*websocket.UpgradeNotification, 0, len(newerVersions))

		for _, version := range newerVersions {
			notification := &websocket.UpgradeNotification{
				Version:     version.Version,
				Title:       version.Title,
				Description: version.Description,
				Required:    version.Required,
				ReleaseDate: version.ReleaseDate,
				Changes:     version.Changes,
			}

			if downloadURL, exists := version.Downloads[platform]; exists {
				notification.UpdateURL = downloadURL
			}

			response.Notifications = append(response.Notifications, notification)
		}
	}

	return response, nil
}

// Subscribe subscribes a user to upgrade notifications
func (s *Service) Subscribe(userID string, preferences *Subscriber) error {
	s.subMutex.Lock()
	defer s.subMutex.Unlock()

	if preferences == nil {
		preferences = &Subscriber{
			NotifyMajor:    true,
			NotifyMinor:    true,
			NotifyPatches:  false,
			NotifyRequired: true,
		}
	}

	preferences.UserID = userID
	preferences.SubscribedAt = time.Now()

	s.subscribers[userID] = preferences
	logger.Info("User %s subscribed to upgrade notifications", userID)
	return nil
}

// Unsubscribe unsubscribes a user from upgrade notifications
func (s *Service) Unsubscribe(userID string) error {
	s.subMutex.Lock()
	defer s.subMutex.Unlock()

	delete(s.subscribers, userID)
	logger.Info("User %s unsubscribed from upgrade notifications", userID)
	return nil
}

// GetCurrentVersion returns the current version
func (s *Service) GetCurrentVersion() *AppVersion {
	s.mutex.RLock()
	defer s.mutex.RUnlock()
	return s.currentVersion
}

// GetVersions returns all available versions
func (s *Service) GetVersions() map[string]*AppVersion {
	s.mutex.RLock()
	defer s.mutex.RUnlock()

	// Return a copy to prevent external modification
	versions := make(map[string]*AppVersion)
	for k, v := range s.versions {
		versions[k] = v
	}
	return versions
}

// GetVersion returns a specific version
func (s *Service) GetVersion(version string) (*AppVersion, bool) {
	s.mutex.RLock()
	defer s.mutex.RUnlock()

	v, exists := s.versions[version]
	return v, exists
}

// GetStats returns upgrade service statistics
func (s *Service) GetStats() map[string]interface{} {
	s.mutex.RLock()
	s.subMutex.RLock()
	defer s.mutex.RUnlock()
	defer s.subMutex.RUnlock()

	return map[string]interface{}{
		"current_version":     s.currentVersion.Version,
		"total_versions":      len(s.versions),
		"total_subscribers":   len(s.subscribers),
		"connected_clients":   s.wsManager.GetConnectedUsers(),
		"latest_release_date": s.currentVersion.ReleaseDate,
	}
}

// shouldNotifyUser determines if a user should be notified based on their preferences
func (s *Service) shouldNotifyUser(userID string, version *AppVersion) bool {
	s.subMutex.RLock()
	subscriber, exists := s.subscribers[userID]
	s.subMutex.RUnlock()

	if !exists {
		// Default behavior: notify for required updates only
		return version.Required
	}

	// Always notify for required updates if enabled
	if version.Required && subscriber.NotifyRequired {
		return true
	}

	// Check version type preferences
	versionType := getVersionType(version.Version)
	switch versionType {
	case "major":
		return subscriber.NotifyMajor
	case "minor":
		return subscriber.NotifyMinor
	case "patch":
		return subscriber.NotifyPatches
	default:
		return false
	}
}

// isVersionDeprecated checks if a version is deprecated
func (s *Service) isVersionDeprecated(version string) bool {
	for _, deprecated := range s.currentVersion.Deprecated {
		if deprecated == version {
			return true
		}
	}
	return false
}

// getNewerVersions returns all versions newer than the given version
func (s *Service) getNewerVersions(currentVersion string) []*AppVersion {
	var newerVersions []*AppVersion

	for _, version := range s.versions {
		if isNewerVersion(version.Version, currentVersion) {
			newerVersions = append(newerVersions, version)
		}
	}

	// Sort by version (newest first)
	sort.Slice(newerVersions, func(i, j int) bool {
		return isNewerVersion(newerVersions[i].Version, newerVersions[j].Version)
	})

	return newerVersions
}

// Helper functions for version comparison and validation

func isValidVersionFormat(version string) bool {
	// Basic semver validation (X.Y.Z format)
	// You can implement more sophisticated validation here
	if len(version) == 0 {
		return false
	}

	// Simple regex-like check for X.Y.Z format
	parts := 0
	for _, char := range version {
		if char == '.' {
			parts++
		} else if char < '0' || char > '9' {
			return false
		}
	}

	return parts == 2 // Should have exactly 2 dots for X.Y.Z
}

func isNewerVersion(version1, version2 string) bool {
	// Simple version comparison
	// In production, you should use a proper semver library
	v1Parts := parseVersion(version1)
	v2Parts := parseVersion(version2)

	for i := 0; i < 3; i++ {
		if v1Parts[i] > v2Parts[i] {
			return true
		} else if v1Parts[i] < v2Parts[i] {
			return false
		}
	}

	return false
}

func parseVersion(version string) [3]int {
	parts := [3]int{0, 0, 0}
	currentPart := 0
	currentNumber := 0

	for _, char := range version {
		if char == '.' {
			if currentPart < 3 {
				parts[currentPart] = currentNumber
				currentPart++
				currentNumber = 0
			}
		} else if char >= '0' && char <= '9' {
			currentNumber = currentNumber*10 + int(char-'0')
		}
	}

	if currentPart < 3 {
		parts[currentPart] = currentNumber
	}

	return parts
}

func getVersionType(version string) string {
	// Simple version type detection
	// You can implement more sophisticated logic here
	parts := parseVersion(version)

	if parts[0] > 0 {
		return "major"
	} else if parts[1] > 0 {
		return "minor"
	}
	return "patch"
}
