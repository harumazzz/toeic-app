# Enhanced Monitoring Setup for TOEIC Backend

This directory contains the enhanced monitoring setup for the TOEIC application backend, providing comprehensive observability through metrics, health checks, alerting, and logging.

## Components

### 1. Application Monitoring
- **Prometheus Metrics**: Detailed application metrics including HTTP requests, response times, error rates, database operations, cache performance, and business metrics
- **Health Checks**: Multi-level health checks for database, cache, external services, and overall application health
- **Alerting**: Intelligent alerting based on configurable thresholds and conditions

### 2. Infrastructure Monitoring
- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **Alertmanager**: Alert routing and notification management
- **Node Exporter**: System-level metrics
- **Redis Exporter**: Redis cache metrics
- **Postgres Exporter**: Database metrics

### 3. Logging
- **Loki**: Log aggregation and storage
- **Promtail**: Log shipping and parsing

## Quick Start

### 1. Start with Monitoring Stack
```bash
# Start the full monitoring stack
docker-compose -f docker-compose.monitoring.yml up -d

# View logs
docker-compose -f docker-compose.monitoring.yml logs -f app
```

### 2. Access Monitoring Interfaces

| Service | URL | Default Credentials |
|---------|-----|-------------------|
| Application | http://localhost:8081 | - |
| Grafana | http://localhost:3001 | admin/admin123 |
| Prometheus | http://localhost:9090 | - |
| Alertmanager | http://localhost:9093 | - |
| Adminer | http://localhost:8080 | - |

### 3. Key Endpoints

#### Application Health & Metrics
- `GET /health` - Basic health check
- `GET /health/detailed` - Comprehensive health check with component details
- `GET /health/live` - Liveness probe (for Kubernetes)
- `GET /health/ready` - Readiness probe (for Kubernetes)
- `GET /metrics` - Basic application metrics
- `GET /prometheus` - Prometheus-format metrics
- `GET /alerts` - Active alerts
- `GET /alerts/history` - Alert history
- `GET /monitoring/status` - Monitoring system status

## Configuration

### Environment Variables

Add these to your `.env` file:

```env
# Monitoring Configuration
MONITORING_ENABLED=true
METRICS_ENABLED=true
HEALTH_ENABLED=true
ALERTS_ENABLED=true

# Metrics Collection
METRICS_COLLECTION_INTERVAL=30s
DB_MONITORING_ENABLED=true
CACHE_MONITORING_ENABLED=true
SYSTEM_MONITORING_ENABLED=true

# Health Check Configuration
HEALTH_CHECK_INTERVAL=30
HEALTH_DEFAULT_TIMEOUT=5s
HEALTH_CACHE_RESULTS=true
HEALTH_MAX_CACHE_AGE=1m

# Alert Configuration
ALERT_CHECK_INTERVAL=30s
ALERT_DEFAULT_COOLDOWN=5m
ALERT_MAX_HISTORY=1000
```

### Custom Monitoring Configuration

You can customize monitoring by modifying:

1. **Prometheus Configuration**: `monitoring/prometheus.yml`
2. **Alert Rules**: `monitoring/alerts.yml`
3. **Alertmanager Configuration**: `monitoring/alertmanager.yml`
4. **Grafana Datasources**: `monitoring/grafana/provisioning/datasources/`
5. **Grafana Dashboards**: `monitoring/grafana/provisioning/dashboards/`

## Metrics Overview

### HTTP Metrics
- `http_requests_total` - Total HTTP requests by method, endpoint, status
- `http_request_duration_seconds` - Request duration histogram
- `http_request_size_bytes` - Request size histogram
- `http_response_size_bytes` - Response size histogram

### Error Metrics
- `errors_total` - Total errors by type, severity, endpoint
- `error_rate` - Current error rate percentage

### Database Metrics
- `db_connections` - Database connections by state (open, idle, in_use)
- `db_query_duration_seconds` - Database query duration
- `db_queries_total` - Total database queries by operation, table, status

### Cache Metrics
- `cache_hits_total` - Total cache hits
- `cache_misses_total` - Total cache misses
- `cache_operation_duration_seconds` - Cache operation duration

### Business Metrics
- `exams_completed_total` - Total completed exams
- `user_registrations_total` - Total user registrations
- `audio_uploads_total` - Total audio uploads

### System Metrics
- `memory_usage_bytes` - Memory usage by type
- `goroutines_count` - Number of goroutines
- `cpu_usage_percent` - CPU usage percentage

## Alert Rules

### Application Alerts
- **ApplicationDown**: Application is unreachable
- **HighErrorRate**: Error rate > 10% for 2 minutes
- **HighResponseTime**: 95th percentile > 2 seconds for 5 minutes
- **HighMemoryUsage**: Memory usage > 1GB for 5 minutes
- **HighCacheMissRate**: Cache miss rate > 50% for 5 minutes

### Database Alerts
- **DatabaseDown**: Database is unreachable
- **DatabaseConnectionPoolHigh**: Connection pool > 80% for 3 minutes
- **HighDatabaseConnections**: Database connections > 80% of max

### Infrastructure Alerts
- **RedisDown**: Redis cache is unreachable
- **HighCPUUsage**: CPU usage > 80% for 5 minutes
- **HighSystemMemoryUsage**: System memory > 85% for 5 minutes
- **LowDiskSpace**: Disk usage > 90% for 5 minutes

## Health Checks

### Component Health Checkers

1. **Database Health**
   - Connection ping test
   - Connection pool statistics
   - Query response time

2. **Cache Health**
   - Basic set/get operations
   - Data integrity verification
   - Response time measurement

3. **External Service Health**
   - HTTP endpoint availability
   - Response time measurement
   - Status code validation

### Health Check Responses

```json
{
  "status": "UP|DOWN|WARNING|UNKNOWN",
  "timestamp": "2025-06-15T10:00:00Z",
  "version": "1.0.0",
  "uptime": "2h30m45s",
  "components": {
    "database": {
      "status": "UP",
      "message": "Database is healthy",
      "last_checked": "2025-06-15T10:00:00Z",
      "response_time": "5ms",
      "details": {
        "open_connections": 5,
        "max_connections": 100
      }
    }
  }
}
```

## Grafana Dashboards

### Pre-configured Dashboards
1. **Application Overview**: Key application metrics and health
2. **HTTP Performance**: Request rates, response times, error rates
3. **Database Monitoring**: Connection pools, query performance
4. **Cache Performance**: Hit rates, operation times
5. **System Resources**: CPU, memory, disk usage
6. **Business Metrics**: User activity, exam completions

### Custom Dashboards
You can create custom dashboards by:
1. Accessing Grafana at http://localhost:3001
2. Using the Prometheus datasource
3. Importing dashboard JSON files or creating from scratch

## Production Deployment

### Security Considerations
1. **Authentication**: Enable authentication for Grafana, Prometheus
2. **Network Security**: Use firewalls to restrict access
3. **SSL/TLS**: Enable HTTPS for all monitoring interfaces
4. **Secrets Management**: Use proper secret management for credentials

### Scaling Considerations
1. **Prometheus**: Consider federation for multiple instances
2. **Grafana**: Use external database for HA setup
3. **Alertmanager**: Configure clustering for HA
4. **Storage**: Plan for long-term metrics storage

### Performance Tuning
1. **Scrape Intervals**: Adjust based on requirements
2. **Retention Policies**: Configure appropriate retention periods
3. **Resource Limits**: Set proper CPU/memory limits
4. **Cardinality**: Monitor and control metric cardinality

## Troubleshooting

### Common Issues

1. **Missing Metrics**
   - Check if monitoring service is enabled
   - Verify Prometheus scrape configuration
   - Check application logs for errors

2. **High Memory Usage**
   - Review metric cardinality
   - Check retention policies
   - Monitor Prometheus memory usage

3. **Alert Fatigue**
   - Adjust alert thresholds
   - Implement proper grouping
   - Use inhibition rules

### Debug Commands

```bash
# Check monitoring service status
curl http://localhost:8081/monitoring/status

# Check Prometheus targets
curl http://localhost:9090/api/v1/targets

# Check alert rules
curl http://localhost:9090/api/v1/rules

# View application logs
docker-compose logs -f app

# Check health endpoints
curl http://localhost:8081/health/detailed
```

## Development

### Adding Custom Metrics

```go
// Define metric
myMetric := promauto.NewCounterVec(
    prometheus.CounterOpts{
        Name: "my_custom_metric_total",
        Help: "Description of my metric",
    },
    []string{"label1", "label2"},
)

// Use metric
myMetric.WithLabelValues("value1", "value2").Inc()
```

### Adding Custom Health Checks

```go
// Implement HealthChecker interface
type MyHealthChecker struct {
    // ...
}

func (h *MyHealthChecker) CheckHealth(ctx context.Context) *ComponentHealth {
    // Implement health check logic
}

// Register with health service
healthService.RegisterChecker(myHealthChecker)
```

### Adding Custom Alerts

```yaml
# Add to monitoring/alerts.yml
- alert: MyCustomAlert
  expr: my_custom_metric > 100
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "Custom alert triggered"
    description: "My custom metric is {{ $value }}"
```

## Support

For issues or questions about the monitoring setup:
1. Check the application logs
2. Review Prometheus/Grafana documentation
3. Consult the troubleshooting section above
4. Check component health endpoints
