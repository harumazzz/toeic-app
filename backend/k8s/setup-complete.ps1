# TOEIC Backend Kubernetes Setup Complete!

Write-Host @"
🎉 TOEIC Backend Kubernetes Setup Complete!
========================================

Your TOEIC backend project is now fully configured for Kubernetes deployment.

📁 What's Included:
├── k8s/                      # Kubernetes manifests
│   ├── namespace.yaml        # Application namespace
│   ├── configmap.yaml       # Configuration and secrets
│   ├── backend.yaml         # Backend application deployment
│   ├── postgres.yaml        # PostgreSQL database
│   ├── redis.yaml          # Redis cache
│   ├── monitoring.yaml     # Prometheus monitoring
│   ├── grafana.yaml        # Grafana dashboards
│   ├── hpa.yaml            # Auto-scaling configuration
│   ├── backup.yaml         # Automated backups
│   └── README.md           # Detailed documentation
├── deploy-k8s.ps1           # Main deployment script
├── quick-start.ps1          # Quick management script
└── health-check.ps1         # Health monitoring script

🚀 Quick Start Guide:

1. Prerequisites Check:
   .\k8s\quick-start.ps1 setup

2. Build Docker Image:
   .\k8s\quick-start.ps1 build

3. Deploy to Kubernetes:
   .\k8s\quick-start.ps1 deploy

4. Check Status:
   .\k8s\quick-start.ps1 status

🔍 Monitoring & Management:

• Health Checks:      .\k8s\health-check.ps1 health
• Live Monitoring:    .\k8s\health-check.ps1 monitor
• Troubleshooting:    .\k8s\health-check.ps1 troubleshoot
• View Logs:          .\k8s\quick-start.ps1 logs
• Scale Application:  .\k8s\quick-start.ps1 scale 5

🌐 Access Points (after deployment):

• Backend API:        http://<node-ip>:30080
• API Health Check:   http://<node-ip>:30080/health
• Prometheus:         http://<node-ip>:30090
• Grafana:           http://<node-ip>:30030 (admin/admin123)

📊 Features:

✓ Auto-scaling (3-10 replicas based on CPU/memory)
✓ Persistent data storage for PostgreSQL and Redis
✓ Automated daily database backups
✓ Comprehensive monitoring with Prometheus & Grafana
✓ Health checks and readiness probes
✓ Resource limits and requests
✓ Security with RBAC and secrets
✓ Rolling updates and rollback capabilities

🛠️ Common Operations:

# Deploy application
.\deploy-k8s.ps1 deploy

# Check health
.\k8s\health-check.ps1 health

# Scale to 5 replicas
.\k8s\quick-start.ps1 scale 5

# Create manual backup
.\k8s\quick-start.ps1 backup

# View live logs
kubectl logs -f deployment/toeic-backend -n toeic-app

# Port forward for direct access
kubectl port-forward service/toeic-backend-service 8000:8000 -n toeic-app

🔧 Troubleshooting:

If you encounter issues:
1. Run: .\k8s\health-check.ps1 troubleshoot
2. Check: .\k8s\quick-start.ps1 status
3. View logs: .\k8s\quick-start.ps1 logs

📚 Next Steps:

1. Customize configuration in k8s/configmap.yaml
2. Adjust resource limits in k8s/backend.yaml
3. Configure ingress for external access
4. Set up CI/CD pipeline for automated deployments
5. Configure additional monitoring dashboards

💡 Tips:

• Use 'kubectl get all -n toeic-app' to see all resources
• Monitor resource usage with 'kubectl top pods -n toeic-app'
• Check HPA status with 'kubectl get hpa -n toeic-app'
• Use port-forwarding for local development testing

For detailed documentation, see: k8s/README.md

Happy coding! 🚀
"@ -ForegroundColor Green

Write-Host "`n🎯 Ready to deploy? Run:" -ForegroundColor Yellow
Write-Host "   .\k8s\quick-start.ps1 setup" -ForegroundColor Cyan
Write-Host "   .\k8s\quick-start.ps1 build" -ForegroundColor Cyan
Write-Host "   .\k8s\quick-start.ps1 deploy" -ForegroundColor Cyan
