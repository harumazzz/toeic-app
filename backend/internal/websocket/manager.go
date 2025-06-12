package websocket

import (
	"context"
	"encoding/json"
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
	"github.com/toeic-app/internal/logger"
	"github.com/toeic-app/internal/token"
)

// Manager handles WebSocket connections and message broadcasting
type Manager struct {
	clients    map[string]*Client // userID -> client
	broadcast  chan []byte        // Broadcast channel
	register   chan *Client       // Register requests from clients
	unregister chan *Client       // Unregister requests from clients
	upgrader   websocket.Upgrader
	mutex      sync.RWMutex
}

// Client represents a websocket client connection
type Client struct {
	ID       string          // User ID
	Socket   *websocket.Conn // WebSocket connection
	Send     chan []byte     // Buffered channel of outbound messages
	Manager  *Manager        // Reference to the manager
	UserID   int32           // User ID for authentication
	LastPing time.Time       // Last ping time for connection health
}

// Message represents a WebSocket message
type Message struct {
	Type      string      `json:"type"`
	Data      interface{} `json:"data"`
	Timestamp time.Time   `json:"timestamp"`
	UserID    string      `json:"user_id,omitempty"`
}

// UpgradeNotification represents an upgrade notification
type UpgradeNotification struct {
	Version     string    `json:"version"`
	Title       string    `json:"title"`
	Description string    `json:"description"`
	UpdateURL   string    `json:"update_url,omitempty"`
	Required    bool      `json:"required"`
	ReleaseDate time.Time `json:"release_date"`
	Changes     []string  `json:"changes,omitempty"`
}

// NewManager creates a new WebSocket manager
func NewManager() *Manager {
	return &Manager{
		clients:    make(map[string]*Client),
		broadcast:  make(chan []byte),
		register:   make(chan *Client),
		unregister: make(chan *Client),
		upgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool {
				// Allow connections from any origin in development
				// In production, you should validate the origin
				return true
			},
			ReadBufferSize:  1024,
			WriteBufferSize: 1024,
		},
	}
}

// Start starts the WebSocket manager
func (m *Manager) Start() {
	logger.Info("Starting WebSocket manager...")

	go func() {
		for {
			select {
			case client := <-m.register:
				m.registerClient(client)
			case client := <-m.unregister:
				m.unregisterClient(client)
			case message := <-m.broadcast:
				m.broadcastMessage(message)
			}
		}
	}()

	// Start ping routine to maintain connections
	go m.pingClients()
}

// HandleWebSocket handles WebSocket connection upgrade
func (m *Manager) HandleWebSocket(c *gin.Context, tokenMaker token.Maker) {
	// Get user from JWT token
	authHeader := c.GetHeader("Authorization")
	if authHeader == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Authorization header required"})
		return
	}

	// Extract token from "Bearer <token>"
	if len(authHeader) < 7 || authHeader[:7] != "Bearer " {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid authorization format"})
		return
	}

	tokenString := authHeader[7:]
	payload, err := tokenMaker.VerifyToken(tokenString)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
		return
	}

	// Upgrade HTTP connection to WebSocket
	conn, err := m.upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		logger.Error("Failed to upgrade connection to WebSocket: %v", err)
		return
	}

	// Create new client
	client := &Client{
		ID:       payload.Username,
		Socket:   conn,
		Send:     make(chan []byte, 256),
		Manager:  m,
		UserID:   payload.ID,
		LastPing: time.Now(),
	}

	// Register client
	m.register <- client

	// Start goroutines for reading and writing
	go client.readMessages()
	go client.writeMessages()

	logger.Info("WebSocket connection established for user: %s (ID: %d)", client.ID, client.UserID)
}

// registerClient registers a new client
func (m *Manager) registerClient(client *Client) {
	m.mutex.Lock()
	defer m.mutex.Unlock()

	// Close existing connection if user is already connected
	if existingClient, exists := m.clients[client.ID]; exists {
		close(existingClient.Send)
		existingClient.Socket.Close()
		logger.Info("Replaced existing WebSocket connection for user: %s", client.ID)
	}

	m.clients[client.ID] = client
	logger.Info("Registered WebSocket client: %s (Total clients: %d)", client.ID, len(m.clients))

	// Send welcome message
	welcome := Message{
		Type:      "welcome",
		Data:      gin.H{"message": "Connected to TOEIC app upgrade notifications"},
		Timestamp: time.Now(),
	}

	if data, err := json.Marshal(welcome); err == nil {
		select {
		case client.Send <- data:
		default:
			close(client.Send)
			delete(m.clients, client.ID)
		}
	}
}

// unregisterClient unregisters a client
func (m *Manager) unregisterClient(client *Client) {
	m.mutex.Lock()
	defer m.mutex.Unlock()

	if _, exists := m.clients[client.ID]; exists {
		delete(m.clients, client.ID)
		close(client.Send)
		client.Socket.Close()
		logger.Info("Unregistered WebSocket client: %s (Total clients: %d)", client.ID, len(m.clients))
	}
}

// broadcastMessage broadcasts a message to all connected clients
func (m *Manager) broadcastMessage(message []byte) {
	m.mutex.RLock()
	defer m.mutex.RUnlock()

	for clientID, client := range m.clients {
		select {
		case client.Send <- message:
		default:
			// Client's send channel is full, remove the client
			delete(m.clients, clientID)
			close(client.Send)
			client.Socket.Close()
			logger.Warn("Removed unresponsive WebSocket client: %s", clientID)
		}
	}
}

// BroadcastUpgradeNotification broadcasts an upgrade notification to all clients
func (m *Manager) BroadcastUpgradeNotification(notification UpgradeNotification) error {
	message := Message{
		Type:      "upgrade_notification",
		Data:      notification,
		Timestamp: time.Now(),
	}

	data, err := json.Marshal(message)
	if err != nil {
		return err
	}

	m.broadcast <- data
	logger.Info("Broadcasted upgrade notification: %s", notification.Version)
	return nil
}

// SendToUser sends a message to a specific user
func (m *Manager) SendToUser(userID string, messageType string, data interface{}) error {
	m.mutex.RLock()
	client, exists := m.clients[userID]
	m.mutex.RUnlock()

	if !exists {
		return nil // User not connected, ignore
	}

	message := Message{
		Type:      messageType,
		Data:      data,
		Timestamp: time.Now(),
		UserID:    userID,
	}

	messageData, err := json.Marshal(message)
	if err != nil {
		return err
	}

	select {
	case client.Send <- messageData:
		return nil
	default:
		// Client's send channel is full, remove the client
		m.unregister <- client
		return nil
	}
}

// GetConnectedUsers returns the number of connected users
func (m *Manager) GetConnectedUsers() int {
	m.mutex.RLock()
	defer m.mutex.RUnlock()
	return len(m.clients)
}

// GetConnectedUserIDs returns the list of connected user IDs
func (m *Manager) GetConnectedUserIDs() []string {
	m.mutex.RLock()
	defer m.mutex.RUnlock()

	userIDs := make([]string, 0, len(m.clients))
	for userID := range m.clients {
		userIDs = append(userIDs, userID)
	}
	return userIDs
}

// pingClients sends ping messages to maintain connections
func (m *Manager) pingClients() {
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			m.mutex.RLock()
			for _, client := range m.clients {
				// Check if client is still responsive
				if time.Since(client.LastPing) > 60*time.Second {
					logger.Warn("Client %s appears unresponsive, removing...", client.ID)
					m.unregister <- client
					continue
				}

				// Send ping
				if err := client.Socket.WriteControl(websocket.PingMessage, []byte{}, time.Now().Add(10*time.Second)); err != nil {
					logger.Warn("Failed to ping client %s: %v", client.ID, err)
					m.unregister <- client
				}
			}
			m.mutex.RUnlock()
		}
	}
}

// readMessages reads messages from the WebSocket connection
func (c *Client) readMessages() {
	defer func() {
		c.Manager.unregister <- c
	}()

	// Set read deadline and pong handler
	c.Socket.SetReadDeadline(time.Now().Add(60 * time.Second))
	c.Socket.SetPongHandler(func(string) error {
		c.LastPing = time.Now()
		c.Socket.SetReadDeadline(time.Now().Add(60 * time.Second))
		return nil
	})

	for {
		_, message, err := c.Socket.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				logger.Error("WebSocket error for client %s: %v", c.ID, err)
			}
			break
		}

		logger.Debug("Received message from client %s: %s", c.ID, string(message))
		// Handle incoming messages if needed (e.g., subscription preferences)
	}
}

// writeMessages writes messages to the WebSocket connection
func (c *Client) writeMessages() {
	ticker := time.NewTicker(54 * time.Second)
	defer func() {
		ticker.Stop()
		c.Socket.Close()
	}()

	for {
		select {
		case message, ok := <-c.Send:
			c.Socket.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if !ok {
				c.Socket.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			w, err := c.Socket.NextWriter(websocket.TextMessage)
			if err != nil {
				return
			}
			w.Write(message)

			// Add queued messages if any
			n := len(c.Send)
			for i := 0; i < n; i++ {
				w.Write([]byte{'\n'})
				w.Write(<-c.Send)
			}

			if err := w.Close(); err != nil {
				return
			}

		case <-ticker.C:
			c.Socket.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if err := c.Socket.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

// Shutdown gracefully shuts down the WebSocket manager
func (m *Manager) Shutdown(ctx context.Context) error {
	logger.Info("Shutting down WebSocket manager...")

	m.mutex.Lock()
	defer m.mutex.Unlock()

	// Close all client connections
	for _, client := range m.clients {
		close(client.Send)
		client.Socket.Close()
	}

	// Clear clients map
	m.clients = make(map[string]*Client)

	logger.Info("WebSocket manager shutdown complete")
	return nil
}
