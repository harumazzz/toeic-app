# TOEIC Backend Kubernetes Setup

This directory contains Kubernetes manifests and deployment scripts for the TOEIC backend application.

## 🏗️ Architecture Overview

The Kubernetes deployment includes:

- **Backend Application**: Go-based TOEIC API server (3 replicas with HPA)
- **PostgreSQL Database**: Primary data storage with persistent volumes
- **Redis Cache**: Caching layer for improved performance
- **Monitoring Stack**: Prometheus + Grafana for observability
- **Backup System**: Automated database backups via CronJob
- **Security**: RBAC, secrets management, and network policies

## 📁 Files Structure

```
k8s/
├── namespace.yaml         # Kubernetes namespace
├── configmap.yaml        # Configuration and secrets
├── rbac.yaml            # Role-based access control
├── postgres.yaml        # PostgreSQL database
├── redis.yaml           # Redis cache
├── backend.yaml         # Backend application + ingress
├── hpa.yaml            # Horizontal Pod Autoscaler
├── monitoring.yaml     # Prometheus monitoring
├── grafana.yaml        # Grafana dashboard
├── exporters.yaml      # Postgres & Redis exporters
├── backup.yaml         # Database backup CronJob
├── migration.yaml      # Database migration job
└── nodeports.yaml      # NodePort services for access
```

## 🚀 Quick Start

### Prerequisites

1. **Kubernetes Cluster**: Ensure you have a running Kubernetes cluster
   ```bash
   # Check cluster status
   kubectl cluster-info
   ```

2. **Docker**: For building the application image
   ```bash
   docker --version
   ```

3. **kubectl**: Kubernetes CLI tool
   ```bash
   kubectl version --client
   ```

### Deployment Options

#### Option 1: Using PowerShell Script (Windows)
```powershell
# Deploy the application
.\deploy-k8s.ps1 deploy

# Check status
.\deploy-k8s.ps1 status

# View logs
.\deploy-k8s.ps1 logs

# Delete deployment
.\deploy-k8s.ps1 delete
```

#### Option 2: Using Bash Script (Linux/Mac/WSL)
```bash
# Make script executable
chmod +x deploy-k8s.sh

# Deploy the application
./deploy-k8s.sh deploy

# Check status
./deploy-k8s.sh status

# View logs
./deploy-k8s.sh logs

# Delete deployment
./deploy-k8s.sh delete
```

#### Option 3: Manual Deployment
```bash
# 1. Create namespace
kubectl apply -f k8s/namespace.yaml

# 2. Build Docker image
docker build -t toeic-backend:latest .

# 3. Deploy infrastructure
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/rbac.yaml
kubectl apply -f k8s/postgres.yaml
kubectl apply -f k8s/redis.yaml

# 4. Wait for databases to be ready
kubectl wait --for=condition=available --timeout=300s deployment/postgres -n toeic-app
kubectl wait --for=condition=available --timeout=300s deployment/redis -n toeic-app

# 5. Deploy application
kubectl apply -f k8s/backend.yaml
kubectl apply -f k8s/hpa.yaml

# 6. Deploy monitoring
kubectl apply -f k8s/exporters.yaml
kubectl apply -f k8s/monitoring.yaml
kubectl apply -f k8s/grafana.yaml

# 7. Deploy services for external access
kubectl apply -f k8s/nodeports.yaml

# 8. Deploy backup system
kubectl apply -f k8s/backup.yaml
```

## 🌐 Access Information

After deployment, services are accessible via NodePort:

| Service | Port | Credentials | URL |
|---------|------|-------------|-----|
| Backend API | 30080 | - | `http://<node-ip>:30080` |
| Prometheus | 30090 | - | `http://<node-ip>:30090` |
| Grafana | 30030 | admin/admin123 | `http://<node-ip>:30030` |

To get your node IP:
```bash
kubectl get nodes -o wide
```

## 📊 Monitoring & Observability

### Prometheus Metrics
- Backend application metrics: `/metrics` endpoint
- PostgreSQL metrics via postgres-exporter
- Redis metrics via redis-exporter
- Kubernetes cluster metrics

### Grafana Dashboards
Access Grafana at `http://<node-ip>:30030` with credentials `admin/admin123`.

Recommended dashboards to import:
- Kubernetes cluster monitoring
- PostgreSQL database metrics
- Redis performance metrics
- Go application metrics

## 🔧 Configuration

### Environment Variables
Key configuration is managed through ConfigMaps and Secrets:

**ConfigMap** (`configmap.yaml`):
- Database connection settings
- Redis configuration
- Application settings
- Rate limiting configuration

**Secrets** (`configmap.yaml`):
- Database credentials
- Redis password
- JWT secret key

### Scaling Configuration
The application is configured with:
- **Replicas**: 3 (minimum)
- **HPA**: Auto-scaling from 3 to 10 replicas
- **Resource Limits**: 
  - CPU: 500m (limit), 250m (request)
  - Memory: 512Mi (limit), 256Mi (request)

### Storage Configuration
- **PostgreSQL**: 10Gi persistent storage
- **Redis**: 5Gi persistent storage
- **Backups**: 20Gi persistent storage

## 💾 Backup & Recovery

### Automated Backups
- **Schedule**: Daily at 2:00 AM UTC
- **Retention**: 7 days
- **Location**: Persistent volume (`backup-pvc`)

### Manual Backup
```bash
# Create immediate backup
kubectl create job --from=cronjob/postgres-backup manual-backup-$(date +%Y%m%d-%H%M%S) -n toeic-app
```

### Restore from Backup
```bash
# List available backups
kubectl exec -it postgres-xxx -n toeic-app -- ls -la /backups

# Restore from backup
kubectl exec -it postgres-xxx -n toeic-app -- psql -U toeicuser -d toeicdb < /backups/backup_YYYYMMDD_HHMMSS.sql
```

## 🔒 Security Features

### RBAC (Role-Based Access Control)
- Service accounts with minimal required permissions
- Namespace-scoped roles
- Secure service-to-service communication

### Secrets Management
- Database credentials stored as Kubernetes secrets
- JWT secret keys encrypted
- Redis authentication enabled

### Network Security
- Internal service communication only
- No direct database/cache exposure
- Configurable ingress rules

## 🐛 Troubleshooting

### Common Issues

1. **Pod Not Starting**
   ```bash
   kubectl describe pod <pod-name> -n toeic-app
   kubectl logs <pod-name> -n toeic-app
   ```

2. **Database Connection Issues**
   ```bash
   # Check PostgreSQL status
   kubectl exec -it deployment/postgres -n toeic-app -- pg_isready

   # Check database connectivity from backend
   kubectl exec -it deployment/toeic-backend -n toeic-app -- netcat -zv postgres-service 5432
   ```

3. **Redis Connection Issues**
   ```bash
   # Check Redis status
   kubectl exec -it deployment/redis -n toeic-app -- redis-cli ping

   # Test Redis from backend
   kubectl exec -it deployment/toeic-backend -n toeic-app -- netcat -zv redis-service 6379
   ```

4. **Image Pull Issues**
   ```bash
   # Rebuild and ensure image is available
   docker build -t toeic-backend:latest .
   
   # For local clusters, you may need to load the image
   # For kind: kind load docker-image toeic-backend:latest
   # For minikube: eval $(minikube docker-env) && docker build -t toeic-backend:latest .
   ```

### Useful Commands

```bash
# Get all resources
kubectl get all -n toeic-app

# Check pod logs
kubectl logs -f deployment/toeic-backend -n toeic-app

# Get pod details
kubectl describe pod <pod-name> -n toeic-app

# Scale deployment manually
kubectl scale deployment toeic-backend --replicas=5 -n toeic-app

# Check HPA status
kubectl get hpa -n toeic-app

# Port forward for direct access
kubectl port-forward service/toeic-backend-service 8000:8000 -n toeic-app
```

## 🔄 Updates & Maintenance

### Rolling Updates
```bash
# Update application image
kubectl set image deployment/toeic-backend toeic-backend=toeic-backend:v2.0.0 -n toeic-app

# Check rollout status
kubectl rollout status deployment/toeic-backend -n toeic-app

# Rollback if needed
kubectl rollout undo deployment/toeic-backend -n toeic-app
```

### Configuration Updates
```bash
# Update ConfigMap
kubectl apply -f k8s/configmap.yaml

# Restart deployment to pick up changes
kubectl rollout restart deployment/toeic-backend -n toeic-app
```

## 🏷️ Labels & Annotations

The deployment uses consistent labeling:
- `app`: Component name (toeic-backend, postgres, redis, etc.)
- `version`: Application version
- `component`: Component type (database, cache, api, etc.)
- `part-of`: toeic-app

## 📈 Performance Tuning

### Resource Optimization
Adjust resource requests and limits based on your cluster capacity:

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

### Database Performance
- Connection pooling configured in application
- Read replicas can be added for read-heavy workloads
- Consider using PostgreSQL operator for advanced features

### Cache Optimization
- Redis persistence enabled for data durability
- Configure Redis clustering for high availability
- Monitor cache hit rates via metrics

## 🤝 Contributing

When adding new Kubernetes resources:
1. Follow the existing naming conventions
2. Add appropriate labels and annotations
3. Include resource requests and limits
4. Add health checks where applicable
5. Update this documentation

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [PostgreSQL on Kubernetes](https://kubernetes.io/docs/tutorials/stateful-application/postgresql/)
- [Monitoring with Prometheus](https://prometheus.io/docs/introduction/overview/)
- [Grafana Documentation](https://grafana.com/docs/)
