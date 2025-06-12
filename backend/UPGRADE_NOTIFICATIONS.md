# 🚀 Real-time Upgrade Notification System

This document explains how to use the real-time upgrade notification system implemented in the TOEIC backend application.

## 📋 Overview

The upgrade notification system provides real-time notifications to clients about new app versions, updates, and required upgrades through WebSocket connections. It includes:

- **WebSocket-based real-time notifications**
- **Version management and comparison**
- **User subscription preferences**
- **Admin-controlled upgrade announcements**
- **Cross-platform support (web, mobile)**

## 🏗️ Architecture

```
┌─────────────────┐    WebSocket    ┌─────────────────┐
│                 │◄──────────────►│                 │
│  Client Apps    │                │  Backend Server │
│  (Web/Mobile)   │    HTTP API    │                 │
│                 │◄──────────────►│                 │
└─────────────────┘                └─────────────────┘
                                            │
                                            ▼
                                   ┌─────────────────┐
                                   │                 │
                                   │ Upgrade Service │
                                   │ Version Manager │
                                   │                 │
                                   └─────────────────┘
```

## 🔧 Components

### 1. WebSocket Manager (`internal/websocket/manager.go`)
- Handles WebSocket connections
- Manages client subscriptions
- Broadcasts notifications to connected clients
- Maintains connection health with ping/pong

### 2. Upgrade Service (`internal/upgrade/service.go`)
- Manages app versions
- Handles subscription preferences
- Checks for updates
- Sends targeted notifications

### 3. HTTP Handlers (`internal/api/upgrade_handler.go`)
- REST API endpoints for version management
- WebSocket upgrade endpoint
- Subscription management endpoints

## 📚 API Endpoints

### Public Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/v1/upgrade/check` | Check for available updates |
| `GET` | `/api/v1/upgrade/current` | Get current app version |
| `GET` | `/api/v1/upgrade/versions` | Get all available versions |
| `GET` | `/api/v1/upgrade/versions/{version}` | Get specific version details |
| `GET` | `/api/v1/upgrade/ws/status` | Get WebSocket connection status |

### Authenticated Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/v1/upgrade/ws` | WebSocket upgrade for real-time notifications |
| `POST` | `/api/v1/upgrade/subscribe` | Subscribe to upgrade notifications |
| `POST` | `/api/v1/upgrade/unsubscribe` | Unsubscribe from notifications |

### Admin Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/v1/admin/upgrade/stats` | Get upgrade service statistics |
| `POST` | `/api/v1/admin/upgrade/versions` | Add new app version |
| `POST` | `/api/v1/admin/upgrade/notify` | Send upgrade notification |

## 🚀 Quick Start

### 1. Start the Backend Server

```bash
cd backend
go run main.go
```

The server will start on `http://localhost:8000` (or your configured address).

### 2. Test with the HTML Client

Open `upgrade-test-client.html` in your browser:

1. **Login**: Enter your credentials
2. **Connect**: Establish WebSocket connection
3. **Subscribe**: Set notification preferences
4. **Test**: Check for updates and receive notifications

### 3. Use the Demo Script

```bash
cd backend
go run upgrade-demo.go
```

This will demonstrate the full API functionality.

## 💻 Client Integration

### WebSocket Connection

```javascript
// Connect to WebSocket (requires authentication)
const ws = new WebSocket('ws://localhost:8000/api/v1/upgrade/ws');

// Handle messages
ws.onmessage = function(event) {
    const message = JSON.parse(event.data);
    
    if (message.type === 'upgrade_notification') {
        const notification = message.data;
        showUpgradeNotification(notification);
    }
};
```

### HTTP API Usage

```javascript
// Check for updates
const response = await fetch('/api/v1/upgrade/check', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
        current_version: '1.0.0',
        platform: 'web'
    })
});

const result = await response.json();
if (result.data.has_update) {
    console.log('Update available:', result.data.latest_version);
}
```

### Subscribe to Notifications

```javascript
// Subscribe with preferences
await fetch('/api/v1/upgrade/subscribe', {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${accessToken}`
    },
    body: JSON.stringify({
        notify_major: true,
        notify_minor: true,
        notify_patches: false,
        notify_required: true,
        client_version: '1.0.0',
        platform: 'web'
    })
});
```

## 🔒 Authentication

### WebSocket Authentication

WebSocket connections require JWT authentication. Include the token in the Authorization header during the HTTP upgrade request:

```javascript
const ws = new WebSocket('ws://localhost:8000/api/v1/upgrade/ws', [], {
    headers: {
        'Authorization': `Bearer ${accessToken}`
    }
});
```

### HTTP API Authentication

Include the JWT token in the Authorization header:

```javascript
headers: {
    'Authorization': `Bearer ${accessToken}`,
    'Content-Type': 'application/json'
}
```

## 👑 Admin Features

### Adding a New Version

```javascript
await fetch('/api/v1/admin/upgrade/versions', {
    method: 'POST',
    headers: {
        'Authorization': `Bearer ${adminToken}`,
        'Content-Type': 'application/json'
    },
    body: JSON.stringify({
        version: '1.1.0',
        title: 'TOEIC App v1.1.0',
        description: 'New features and improvements',
        required: false,
        changes: [
            'Added real-time notifications',
            'Improved UI/UX',
            'Bug fixes'
        ],
        downloads: {
            web: '/',
            android: '/downloads/app-1.1.0.apk',
            ios: '/downloads/app-1.1.0.ipa'
        }
    })
});
```

### Sending Upgrade Notifications

```javascript
// Broadcast to all users
await fetch('/api/v1/admin/upgrade/notify', {
    method: 'POST',
    headers: {
        'Authorization': `Bearer ${adminToken}`,
        'Content-Type': 'application/json'
    },
    body: JSON.stringify({
        version: '1.1.0'
    })
});

// Send to specific users
await fetch('/api/v1/admin/upgrade/notify', {
    method: 'POST',
    headers: {
        'Authorization': `Bearer ${adminToken}`,
        'Content-Type': 'application/json'
    },
    body: JSON.stringify({
        version: '1.1.0',
        target_users: ['user1', 'user2']
    })
});
```

## 📱 Message Types

### WebSocket Messages

#### Welcome Message
```json
{
    "type": "welcome",
    "data": {
        "message": "Connected to TOEIC app upgrade notifications"
    },
    "timestamp": "2023-06-11T10:30:00Z"
}
```

#### Upgrade Notification
```json
{
    "type": "upgrade_notification",
    "data": {
        "version": "1.1.0",
        "title": "TOEIC App v1.1.0",
        "description": "New features and improvements",
        "update_url": "/downloads/app-1.1.0.apk",
        "required": false,
        "release_date": "2023-06-11T10:00:00Z",
        "changes": [
            "Added real-time notifications",
            "Improved UI/UX"
        ]
    },
    "timestamp": "2023-06-11T10:30:00Z"
}
```

## 🔧 Configuration

The upgrade system uses existing server configuration. Key settings:

```env
# CORS Configuration (add WebSocket origins)
CORS_ALLOWED_ORIGINS=http://localhost:3000,ws://localhost:3000
```

## 🧪 Testing

### 1. Manual Testing
- Use `upgrade-test-client.html` for interactive testing
- Test WebSocket connections, subscriptions, and notifications

### 2. Automated Testing
- Run `upgrade-demo.go` for API testing
- Includes login, subscription, and admin operations

### 3. Load Testing
- Connect multiple WebSocket clients
- Test broadcast performance with many connected users

## 🐛 Troubleshooting

### Common Issues

1. **WebSocket Connection Failed**
   - Check if user is authenticated
   - Verify CORS settings
   - Ensure server is running

2. **No Notifications Received**
   - Check subscription preferences
   - Verify user is connected via WebSocket
   - Check if notifications are being sent

3. **Admin Operations Failed**
   - Ensure user has admin privileges
   - Check JWT token validity
   - Verify endpoint paths

### Debug Mode

Enable debug logging to see detailed WebSocket and upgrade service logs:

```go
logger.SetLevel(logger.LevelDebug)
```

## 🚀 Deployment

### Production Considerations

1. **WebSocket Scaling**: Use Redis for multi-instance WebSocket management
2. **Load Balancing**: Configure sticky sessions for WebSocket connections
3. **Security**: Implement rate limiting for WebSocket connections
4. **Monitoring**: Track connection counts and message delivery rates

### Environment Variables

```env
# Add to your .env file
WEBSOCKET_ORIGIN_CHECK=true
UPGRADE_NOTIFICATIONS_ENABLED=true
MAX_WEBSOCKET_CONNECTIONS=1000
```

## 📈 Monitoring

### Metrics Available

- Connected WebSocket clients count
- Total upgrade notifications sent
- User subscription statistics
- Version adoption rates

### Health Checks

```bash
# Check WebSocket status
curl http://localhost:8000/api/v1/upgrade/ws/status

# Get upgrade service stats (admin)
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
     http://localhost:8000/api/v1/admin/upgrade/stats
```

## 🔮 Future Enhancements

- [ ] Push notification integration (FCM, APNs)
- [ ] A/B testing for upgrade rollouts
- [ ] Rollback notifications
- [ ] Upgrade analytics dashboard
- [ ] Multi-language notification support
- [ ] Scheduled upgrade announcements

## 📞 Support

For questions or issues:
1. Check the logs for error messages
2. Review the API documentation
3. Test with the provided HTML client
4. Run the demo script for debugging

---

🎉 **Congratulations!** You now have a fully functional real-time upgrade notification system for your TOEIC app!
