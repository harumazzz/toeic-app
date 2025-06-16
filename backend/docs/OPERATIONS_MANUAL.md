# 📋 TOEIC App Backend - Operations Manual

## 🎯 Overview

This operations manual provides comprehensive guidance for managing the TOEIC App Backend in production environments. It covers day-to-day operations, monitoring, troubleshooting, and maintenance procedures.

## 🚀 Quick Start Operations

### Daily Operations Checklist

#### Morning Health Check
```powershell
# Quick system status check
.\deploy-advanced.ps1 status -Environment production

# Check application health
.\deploy-advanced.ps1 health-check -Environment production

# Review overnight logs
.\deploy-advanced.ps1 logs -Environment production | Select-String "ERROR\|WARN"
```

#### Daily Backup Verification
```powershell
# Verify latest backup
Get-ChildItem backups/ | Sort-Object LastWriteTime -Descending | Select-Object -First 5

# Test backup integrity (weekly)
.\deploy-advanced.ps1 restore -Environment staging -BackupFile backups/latest-backup.sql.gz
```

### Weekly Maintenance

#### System Cleanup
```powershell
# Clean up old Docker resources
.\deploy-advanced.ps1 cleanup -Environment production

# Update application dependencies
docker-compose pull
.\deploy-advanced.ps1 deploy -Environment production
```

#### Performance Review
```powershell
# Monitor system performance
.\deploy-advanced.ps1 monitor -Environment production

# Review cache performance
curl https://api.toeic-app.com/api/v1/admin/cache/stats -H "Authorization: Bearer $ADMIN_TOKEN"
```

## 📊 Monitoring and Alerting

### Real-time Monitoring Dashboard

#### System Metrics
```bash
# CPU and Memory Usage
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"

# Application Performance
curl https://api.toeic-app.com/metrics | grep -E "response_time|throughput|error_rate"

# Database Performance
docker-compose exec postgres psql -U root -d toeic_db -c "
SELECT 
    schemaname,
    tablename,
    n_tup_ins + n_tup_upd + n_tup_del as total_operations,
    n_tup_ins as inserts,
    n_tup_upd as updates,
    n_tup_del as deletes
FROM pg_stat_user_tables 
ORDER BY total_operations DESC;
"
```

#### Cache Performance
```bash
# Redis Cache Statistics
docker-compose exec redis redis-cli INFO memory
docker-compose exec redis redis-cli INFO stats

# Application Cache Hit Rate
curl https://api.toeic-app.com/api/v1/admin/cache/advanced-stats \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq '.hit_rate'
```

### Alerting Thresholds

| Metric | Warning | Critical | Action |
|--------|---------|----------|--------|
| **CPU Usage** | >70% | >85% | Scale up instances |
| **Memory Usage** | >80% | >90% | Restart services |
| **Disk Usage** | >75% | >85% | Clean logs/backups |
| **Response Time** | >200ms | >500ms | Check cache/DB |
| **Error Rate** | >1% | >5% | Investigate logs |
| **Cache Hit Rate** | <90% | <80% | Warm cache |

### Automated Alerting Setup

#### PowerShell Monitoring Script
```powershell
# monitoring/health-monitor.ps1
param(
    [string]$Environment = "production",
    [string]$WebhookUrl = $env:ALERT_WEBHOOK_URL
)

$healthUrl = "https://api.toeic-app.com/health"
$metricsUrl = "https://api.toeic-app.com/metrics"

while ($true) {
    try {
        # Check application health
        $health = Invoke-RestMethod -Uri $healthUrl -TimeoutSec 10
        
        if ($health.status -ne "healthy") {
            Send-Alert "🚨 Application unhealthy: $($health.status)" $WebhookUrl
        }
        
        # Check metrics
        $metrics = Invoke-RestMethod -Uri $metricsUrl -TimeoutSec 10
        
        # CPU Alert
        if ($metrics.system.cpu_usage -gt 85) {
            Send-Alert "🚨 High CPU usage: $($metrics.system.cpu_usage)%" $WebhookUrl
        }
        
        # Memory Alert
        if ($metrics.system.memory_usage -gt 90) {
            Send-Alert "🚨 High memory usage: $($metrics.system.memory_usage)%" $WebhookUrl
        }
        
        # Cache Hit Rate Alert
        if ($metrics.application.cache_hit_rate -lt 80) {
            Send-Alert "⚠️ Low cache hit rate: $($metrics.application.cache_hit_rate)%" $WebhookUrl
        }
        
    }
    catch {
        Send-Alert "🚨 Health check failed: $($_.Exception.Message)" $WebhookUrl
    }
    
    Start-Sleep 300  # Check every 5 minutes
}

function Send-Alert($message, $webhookUrl) {
    if ($webhookUrl) {
        $payload = @{ text = $message } | ConvertTo-Json
        Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $payload -ContentType "application/json"
    }
    Write-Host "[$(Get-Date)] ALERT: $message" -ForegroundColor Red
}
```

## 🔧 Troubleshooting Guide

### Common Issues and Solutions

#### 1. Application Not Responding

**Symptoms:**
- Health check endpoint returns 500 or times out
- Users cannot access the application
- High response times

**Diagnosis:**
```powershell
# Check container status
docker-compose ps

# Check application logs
.\deploy-advanced.ps1 logs -Environment production | Select-String "ERROR\|PANIC\|FATAL"

# Check resource usage
docker stats --no-stream
```

**Solutions:**
```powershell
# Quick restart
.\deploy-advanced.ps1 rollback -Environment production -Force

# Scale up if resource constrained
.\deploy-advanced.ps1 scale -Environment production -Replicas 5

# Full redeployment if needed
.\deploy-advanced.ps1 deploy -Environment production -Force
```

#### 2. Database Connection Issues

**Symptoms:**
- "Connection refused" errors in logs
- Slow query performance
- Connection pool exhaustion

**Diagnosis:**
```powershell
# Check PostgreSQL status
docker-compose exec postgres pg_isready -U root -d toeic_db

# Check active connections
docker-compose exec postgres psql -U root -d toeic_db -c "
SELECT count(*) as active_connections 
FROM pg_stat_activity 
WHERE state = 'active';
"

# Check long-running queries
docker-compose exec postgres psql -U root -d toeic_db -c "
SELECT pid, now() - pg_stat_activity.query_start AS duration, query 
FROM pg_stat_activity 
WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes';
"
```

**Solutions:**
```powershell
# Restart PostgreSQL
docker-compose restart postgres

# Terminate long-running queries
docker-compose exec postgres psql -U root -d toeic_db -c "
SELECT pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE (now() - pg_stat_activity.query_start) > interval '10 minutes';
"

# Increase connection pool if needed
# Edit .env: DB_MAX_CONNECTIONS=100
.\deploy-advanced.ps1 deploy -Environment production
```

#### 3. Cache Performance Issues

**Symptoms:**
- Low cache hit rate (<80%)
- Slow response times
- High memory usage

**Diagnosis:**
```powershell
# Check Redis status
docker-compose exec redis redis-cli ping

# Check memory usage
docker-compose exec redis redis-cli INFO memory

# Check cache statistics
curl https://api.toeic-app.com/api/v1/admin/cache/stats \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

**Solutions:**
```powershell
# Clear cache and warm it up
curl -X POST https://api.toeic-app.com/api/v1/admin/cache/warm \
  -H "Authorization: Bearer $ADMIN_TOKEN"

# Restart Redis if memory issues
docker-compose restart redis

# Scale Redis if needed
# Edit docker-compose.prod.yml to add Redis cluster
```

#### 4. High Memory Usage

**Symptoms:**
- Memory usage >90%
- Application becomes slow
- Out of memory errors

**Diagnosis:**
```powershell
# Check memory usage by container
docker stats --format "table {{.Container}}\t{{.MemUsage}}\t{{.MemPerc}}"

# Check Go memory statistics
curl https://api.toeic-app.com/metrics | grep -E "go_memstats"
```

**Solutions:**
```powershell
# Restart application to free memory
docker-compose restart app

# Reduce cache size
# Edit .env: CACHE_MAX_MEMORY_USAGE=536870912  # 512MB
.\deploy-advanced.ps1 deploy -Environment production

# Scale horizontally
.\deploy-advanced.ps1 scale -Environment production -Replicas 4
```

## 🔄 Deployment Procedures

### Standard Deployment

#### Development to Staging
```powershell
# Deploy to staging with full validation
.\deploy-advanced.ps1 deploy-staging -Verbose

# Run integration tests
cd tests/integration
go test -v ./...

# Verify staging environment
.\deploy-advanced.ps1 health-check -Environment staging
```

#### Staging to Production
```powershell
# Create production backup
.\deploy-advanced.ps1 backup -Environment production

# Deploy to production
.\deploy-advanced.ps1 deploy-prod

# Monitor deployment
.\deploy-advanced.ps1 monitor -Environment production
```

### Emergency Deployment

#### Hotfix Deployment
```powershell
# Quick hotfix deployment
git checkout hotfix/critical-fix
.\deploy-advanced.ps1 deploy -Environment production -Force -SkipTests

# Monitor for issues
.\deploy-advanced.ps1 health-check -Environment production
```

#### Zero-Downtime Deployment
```powershell
# Deploy without downtime
.\deploy-advanced.ps1 deploy-zero-downtime -Environment production -Replicas 3

# Verify all instances are healthy
for ($i = 1; $i -le 5; $i++) {
    .\deploy-advanced.ps1 health-check -Environment production
    Start-Sleep 10
}
```

### Rollback Procedures

#### Quick Rollback
```powershell
# Rollback to previous version
git checkout HEAD~1
.\deploy-advanced.ps1 deploy -Environment production -Force

# Or rollback using backup
.\deploy-advanced.ps1 rollback -Environment production -BackupFile backups/pre_deploy_backup.sql.gz
```

#### Database Rollback
```powershell
# Restore database to previous state
.\deploy-advanced.ps1 restore -Environment production -BackupFile backups/known_good_backup.sql.gz

# Verify data integrity
docker-compose exec postgres psql -U root -d toeic_db -c "SELECT COUNT(*) FROM users;"
```

## 📈 Performance Optimization

### Cache Optimization

#### Cache Warming
```powershell
# Warm cache with common queries
curl -X POST https://api.toeic-app.com/api/v1/admin/cache/warm \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{"patterns": ["users:*", "auth:*", "content:*"]}'
```

#### Cache Tuning
```powershell
# Analyze cache patterns
curl https://api.toeic-app.com/api/v1/admin/cache/advanced-stats \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq '.key_patterns'

# Adjust cache TTL for optimal performance
# Edit application configuration
```

### Database Optimization

#### Index Analysis
```sql
-- Check for missing indexes
SELECT schemaname, tablename, attname, n_distinct, correlation
FROM pg_stats
WHERE schemaname = 'public'
AND n_distinct > 100
AND correlation < 0.1;

-- Analyze slow queries
SELECT query, mean_time, calls, total_time
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;
```

#### Connection Pool Tuning
```env
# Optimize for high load
DB_MAX_CONNECTIONS=100
DB_MIN_CONNECTIONS=10
DB_MAX_IDLE_TIME=5m
DB_MAX_LIFETIME=1h
```

### Application Scaling

#### Horizontal Scaling
```powershell
# Scale based on load
.\deploy-advanced.ps1 scale -Environment production -Replicas 5

# Monitor resource usage
while ($true) {
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
    Start-Sleep 30
}
```

#### Load Balancing
```nginx
# Nginx upstream configuration
upstream backend {
    least_conn;
    server app_1:8000 weight=1;
    server app_2:8000 weight=1;
    server app_3:8000 weight=1;
    keepalive 32;
}
```

## 🔐 Security Operations

### Security Monitoring

#### Failed Login Attempts
```powershell
# Monitor failed login attempts
.\deploy-advanced.ps1 logs -Environment production | 
  Select-String "authentication failed" | 
  Group-Object { ($_ -split " ")[0] } | 
  Sort-Object Count -Descending
```

#### Security Headers Verification
```powershell
# Check security headers
curl -I https://api.toeic-app.com | grep -E "Strict-Transport-Security|X-Frame-Options|X-Content-Type-Options"
```

### Certificate Management

#### SSL Certificate Renewal
```powershell
# Check certificate expiration
openssl x509 -in ssl/cert.pem -text -noout | grep "Not After"

# Renew Let's Encrypt certificate
certbot renew --nginx --dry-run
```

#### Security Auditing
```powershell
# Run security audit
docker run --rm -v ${PWD}:/app node:alpine npm audit --prefix /app

# Check for vulnerabilities
docker run --rm -v ${PWD}:/app securecodewarrior/docker-security-checker /app
```

## 📊 Backup and Recovery

### Automated Backup System

#### Backup Schedule
```powershell
# Schedule automatic backups
$trigger = New-ScheduledTaskTrigger -Daily -At "2:00AM"
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\toeic-production\backend\scripts\backup-daily.ps1"
Register-ScheduledTask -TaskName "TOEIC-Daily-Backup" -Trigger $trigger -Action $action
```

#### Backup Verification
```powershell
# Verify backup integrity
.\scripts\verify-backup.ps1 -BackupFile backups/latest-backup.sql.gz

# Test restore in staging
.\deploy-advanced.ps1 restore -Environment staging -BackupFile backups/production-backup.sql.gz
```

### Disaster Recovery

#### Full System Recovery
```powershell
# 1. Provision new infrastructure
# 2. Restore from backup
.\deploy-advanced.ps1 restore -Environment production -BackupFile backups/disaster-recovery-backup.sql.gz

# 3. Verify system health
.\deploy-advanced.ps1 health-check -Environment production

# 4. Update DNS if needed
# 5. Notify users of recovery completion
```

#### Data Recovery Procedures
```powershell
# Point-in-time recovery
.\scripts\point-in-time-recovery.ps1 -DateTime "2025-06-15 14:30:00"

# Partial data recovery
.\scripts\selective-restore.ps1 -Tables "users,user_sessions" -BackupFile backups/selective-backup.sql
```

## 📞 Emergency Procedures

### Emergency Contact List

| Role | Contact | Phone | Email |
|------|---------|-------|-------|
| **Primary SRE** | John Doe | +1-555-0101 | john.doe@company.com |
| **Backup SRE** | Jane Smith | +1-555-0102 | jane.smith@company.com |
| **Database Admin** | Bob Wilson | +1-555-0103 | bob.wilson@company.com |
| **Security Lead** | Alice Brown | +1-555-0104 | alice.brown@company.com |

### Incident Response

#### Severity Levels

**P1 - Critical (Response: Immediate)**
- Complete service outage
- Data loss or corruption
- Security breach

**P2 - High (Response: 1 hour)**
- Significant performance degradation
- Partial service unavailability
- Failed deployments

**P3 - Medium (Response: 4 hours)**
- Minor performance issues
- Non-critical feature failures
- Monitoring alerts

**P4 - Low (Response: Next business day)**
- Enhancement requests
- Documentation updates
- Scheduled maintenance

#### Emergency Response Steps

1. **Immediate Assessment**
   ```powershell
   # Quick system check
   .\deploy-advanced.ps1 status -Environment production
   .\deploy-advanced.ps1 health-check -Environment production
   ```

2. **Impact Analysis**
   ```powershell
   # Check user impact
   curl https://api.toeic-app.com/metrics | grep active_users
   
   # Check error rates
   .\deploy-advanced.ps1 logs -Environment production | Select-String "ERROR" | Measure-Object
   ```

3. **Immediate Mitigation**
   ```powershell
   # Quick rollback if needed
   .\deploy-advanced.ps1 rollback -Environment production -Force
   
   # Scale up if performance issue
   .\deploy-advanced.ps1 scale -Environment production -Replicas 6
   ```

4. **Communication**
   - Update status page
   - Notify stakeholders
   - Document incident timeline

## 📚 Useful Commands Reference

### Docker Operations
```powershell
# View all containers
docker-compose ps

# View logs for specific service
docker-compose logs -f app

# Execute command in container
docker-compose exec app bash

# Restart specific service
docker-compose restart app

# Update and restart services
docker-compose pull && docker-compose up -d
```

### Database Operations
```powershell
# Connect to database
docker-compose exec postgres psql -U root -d toeic_db

# Create backup
docker-compose exec postgres pg_dump -U root -d toeic_db > backup.sql

# Restore backup
docker-compose exec -T postgres psql -U root -d toeic_db < backup.sql

# Check database size
docker-compose exec postgres psql -U root -d toeic_db -c "SELECT pg_size_pretty(pg_database_size('toeic_db'));"
```

### Application Operations
```powershell
# Check application health
curl https://api.toeic-app.com/health

# Get system metrics
curl https://api.toeic-app.com/metrics

# Cache operations
curl -X POST https://api.toeic-app.com/api/v1/admin/cache/warm -H "Authorization: Bearer $TOKEN"
curl https://api.toeic-app.com/api/v1/admin/cache/stats -H "Authorization: Bearer $TOKEN"

# View active sessions
curl https://api.toeic-app.com/api/v1/admin/sessions -H "Authorization: Bearer $ADMIN_TOKEN"
```

---

This operations manual should be regularly updated as the system evolves and new procedures are developed.
