# Enhanced Backup System Documentation

The TOEIC app backend now includes an enhanced backup and restore system with advanced features and improved reliability.

## New Features Added

### 1. Enhanced Backup Manager
- **Compression**: Automatic backup compression to save storage space
- **Validation**: Pre and post-backup validation with checksum verification
- **Retry Logic**: Automatic retry on failures with configurable retry count and wait times
- **Metadata**: Rich backup metadata including timestamps, checksums, and descriptions
- **Notifications**: Integration with Slack, webhooks, and email for backup events
- **Safety Backups**: Automatic safety backups before restore operations

### 2. Advanced Backup Scheduler
- **Multiple Schedules**: Support for different backup schedules (daily, weekly, monthly)
- **Schedule Management**: Add, remove, and modify backup schedules
- **Backup Types**: Support for different backup types (full, incremental, differential)
- **Retention Policies**: Automatic cleanup based on configurable retention periods
- **Health Monitoring**: Continuous health monitoring of backup system

### 3. Enhanced Configuration
The backup system is now configured via environment variables and supports:
- Custom backup directories
- Compression settings
- Validation options
- Retry configuration
- Notification settings (Slack, webhooks, email)
- Storage limits and cleanup policies

### 4. Backup CLI Tool
A new command-line tool (`backup-admin`) provides:
- Manual backup creation with custom descriptions
- Restore operations with confirmation prompts
- Backup validation and integrity checks
- List and manage backup files
- System status and health monitoring

## Configuration

### Environment Variables
```bash
# Backup Directory
BACKUP_DIR=/path/to/backups

# Compression
BACKUP_COMPRESSION_ENABLED=true
BACKUP_COMPRESSION_LEVEL=6

# Validation
BACKUP_VALIDATE_AFTER_BACKUP=true
BACKUP_VALIDATE_BEFORE_RESTORE=true

# Retry Configuration
BACKUP_MAX_RETRIES=3
BACKUP_RETRY_WAIT=30s

# Retention
BACKUP_RETENTION_DAYS=30
BACKUP_MAX_BACKUPS=100

# Notifications
BACKUP_SLACK_WEBHOOK_URL=https://hooks.slack.com/...
BACKUP_NOTIFICATION_EMAIL=admin@example.com
```

## API Endpoints

### Enhanced Backup Endpoints
- `POST /api/v1/admin/backups/enhanced` - Create enhanced backup
- `POST /api/v1/admin/backups/enhanced/restore` - Restore with enhanced features
- `GET /api/v1/admin/backups/status` - Get backup system status
- `POST /api/v1/admin/backups/validate/:filename` - Validate backup file
- `GET /api/v1/admin/backups/schedules` - Get backup schedules
- `POST /api/v1/admin/backups/schedules` - Add backup schedule
- `DELETE /api/v1/admin/backups/schedules/:id` - Remove backup schedule
- `GET /api/v1/admin/backups/history` - Get backup history
- `POST /api/v1/admin/backups/cleanup` - Manual cleanup

## CLI Usage

### Basic Commands
```bash
# Create a backup
./backup-admin create --description "Manual backup before update" --compress --validate

# Restore from backup
./backup-admin restore --file auto_backup_20231215_143022.sql --yes

# List backups
./backup-admin list

# Validate backup
./backup-admin validate --file backup_20231215.sql

# Check system status
./backup-admin status

# Monitor system health
./backup-admin monitor
```

### Advanced Usage
```bash
# Create specific backup type
./backup-admin create --description "Pre-migration backup" --type full --compress

# Restore with safety backup
./backup-admin restore --file backup.sql --safety-backup

# Cleanup old backups
./backup-admin cleanup --max-age 720h  # 30 days

# Validate all backups
./backup-admin validate --all
```

## Integration

### Server Integration
The enhanced backup system is automatically initialized when the server starts:
- Enhanced backup manager is created with loaded configuration
- Backup scheduler starts with configured schedules
- Notification manager is initialized for backup events
- Health monitoring begins automatically

### Legacy Compatibility
The enhanced system maintains compatibility with existing backup endpoints:
- All legacy backup API endpoints continue to work
- Existing backup files are compatible with the new system
- Legacy scheduled backups continue to function

## Monitoring

### Health Checks
The system continuously monitors:
- Backup directory accessibility and disk space
- Scheduler health and next backup times
- Recent backup success rates
- System resource utilization

### Notifications
Automatic notifications are sent for:
- Successful backup completion
- Backup failures with error details
- Storage space warnings
- Schedule execution status
- System health alerts

### Metrics
The system tracks:
- Total backups created
- Success/failure rates
- Average backup sizes and durations
- Disk usage trends
- Performance metrics

## Security

### Access Control
- All backup endpoints require admin privileges
- RBAC integration for fine-grained permissions
- Audit logging for all backup operations

### Data Protection
- Optional backup encryption (configurable)
- Secure file permissions on backup files
- Checksum verification for data integrity
- Safe restore operations with rollback capability

## Troubleshooting

### Common Issues
1. **Backup Failures**: Check disk space, permissions, and database connectivity
2. **Restore Issues**: Validate backup file integrity before restore
3. **Schedule Problems**: Check scheduler status and configuration
4. **Notification Failures**: Verify webhook URLs and email settings

### Log Analysis
Enhanced logging provides detailed information about:
- Backup creation and restore operations
- Validation results and checksum verification
- Scheduler execution and timing
- Error details and retry attempts

### Health Monitoring
Use the `/status` endpoint or CLI `status` command to check:
- Overall system health
- Recent backup activity
- Disk usage and capacity
- Active schedules and next run times

## Migration from Legacy System

The enhanced backup system is designed to work alongside the existing system:
1. Existing backups continue to work with new features
2. Legacy API endpoints remain functional
3. Gradual migration to enhanced endpoints is supported
4. Configuration can be updated incrementally

For full benefits, update clients to use the enhanced API endpoints and configure the new environment variables.