# Business Applications - ArgoCD GitOps

This repository contains ArgoCD configuration for deploying **business applications only** across multiple environments using Helm charts stored in MinIO.

## 🎯 Focus

- **Business Applications Only**: No platform tools or infrastructure
- **Helm-First**: All applications use Helm charts from MinIO repository
- **Multi-Environment**: Dev, UAT, and Production environments
- **Industry Best Practices**: RBAC, security, and progressive deployment

## 🏗️ Repository Structure

```
├── bootstrap/
│   └── minio-helm-repo.yaml           # ArgoCD repository secret for MinIO
├── projects/
│   ├── dev-project.yaml               # Development environment project
│   ├── uat-project.yaml               # UAT environment project
│   └── prod-project.yaml              # Production environment project
├── applications/
│   ├── dev/
│   │   └── webapp.yaml                # Individual dev application
│   ├── uat/
│   │   └── webapp.yaml                # Individual UAT application
│   └── prod/
│       └── webapp.yaml                # Individual prod application
├── app-sets/
│   └── business-apps-simple.yaml      # ApplicationSet for multi-env deployment
├── environments/
│   ├── dev/
│   │   └── webapp-values.yaml         # Development values
│   ├── uat/
│   │   └── webapp-values.yaml         # UAT values
│   └── prod/
│       └── webapp-values.yaml         # Production values
└── deploy.sh                          # Deployment script
```

## 🚀 Quick Start

### Prerequisites

- ArgoCD installed and running
- kubectl configured
- Access to MinIO Helm repository: `http://s3.devkuban.com/helm-charts`

### Deploy Everything

```bash
# Clone this repository
git clone git@github.com:Bakmurat/Applications.git
cd Applications

# Deploy all business applications
./deploy.sh
```

### Manual Deployment

```bash
# 1. Configure MinIO repository in ArgoCD
kubectl apply -f bootstrap/minio-helm-repo.yaml

# 2. Create environment projects
kubectl apply -f projects/

# 3. Deploy applications (choose one approach)

# Option A: Individual applications
kubectl apply -f applications/dev/webapp.yaml
kubectl apply -f applications/uat/webapp.yaml
kubectl apply -f applications/prod/webapp.yaml

# Option B: ApplicationSet (manages all environments)
kubectl apply -f app-sets/business-apps-simple.yaml
```

## 📦 Helm Charts

All business applications use Helm charts stored in MinIO:

- **Repository**: `http://s3.devkuban.com/helm-charts`
- **Available Charts**: 
  - `webapp` (versions: 1.0.9, 1.0.6, 1.0.0)
- **Chart Management**: Automated via GitHub Actions in separate repository

### Testing Chart Access

```bash
# Add repository locally
helm repo add myrepo http://s3.devkuban.com/helm-charts
helm repo update

# Search available charts
helm search repo myrepo
helm search repo myrepo/webapp --versions

# Test chart installation
helm install test-webapp myrepo/webapp --dry-run
```

## 🌍 Environments

### Development (`business-apps-dev`)
- **Replicas**: 2
- **Security**: Relaxed for development
- **SSL**: Disabled
- **Autoscaling**: Disabled
- **Resources**: 200m CPU, 256Mi memory
- **Domain**: `webapp-dev.devkuban.com`

### UAT (`business-apps-uat`)
- **Replicas**: 3
- **Security**: Moderate hardening
- **SSL**: Enabled (staging certificates)
- **Autoscaling**: Enabled (2-8 replicas)
- **Resources**: 500m CPU, 512Mi memory
- **Domain**: `webapp-uat.devkuban.com`

### Production (`business-apps-prod`)
- **Replicas**: 5+
- **Security**: Full hardening
- **SSL**: Production certificates
- **Autoscaling**: Enabled (3-20 replicas)
- **Resources**: 1000m CPU, 1Gi memory
- **Domain**: `webapp.devkuban.com`

## 🔐 Security & RBAC

### Project-Based Access Control

- **Dev Project**: Development and platform teams
- **UAT Project**: QA testers and developers
- **Prod Project**: SRE and platform teams only

### Security Features

- **Pod Security Contexts**: Non-root users in UAT/Prod
- **Network Policies**: Traffic isolation in production
- **Resource Limits**: CPU and memory constraints
- **Read-Only Filesystems**: In production
- **Pod Disruption Budgets**: High availability

## 🎛️ Application Management

### Individual Applications

Each environment has dedicated application definitions with environment-specific configurations embedded in the YAML.

### ApplicationSet

The ApplicationSet provides centralized management across all environments:

- **Single definition** manages dev, uat, and prod
- **Environment-specific values** from Git repository
- **Automatic chart version management**
- **Progressive deployment** capabilities

### Adding New Applications

1. **Create Helm chart** in your MinIO repository
2. **Add to ApplicationSet** in `app-sets/business-apps-simple.yaml`
3. **Create environment values** in `environments/{env}/{app}-values.yaml`
4. **Commit and sync**

## 🔄 Operations

### Check Application Status

```bash
# List all applications
kubectl get applications -n argocd

# Check specific environment
kubectl get pods -n business-apps-dev
kubectl get pods -n business-apps-uat
kubectl get pods -n business-apps-prod

# Application logs
kubectl logs -n business-apps-prod -l app=webapp
```

### Update Chart Version

```bash
# Update ApplicationSet
kubectl patch applicationset business-apps-multi-env -n argocd --type merge \
  -p '{"spec":{"generators":[{"list":{"elements":[{"chartVersion":"1.0.6"}]}}]}}'

# Or update individual application
kubectl patch application webapp-prod -n argocd --type merge \
  -p '{"spec":{"source":{"targetRevision":"1.0.6"}}}'
```

### Force Sync

```bash
# Sync specific application
kubectl patch application webapp-prod -n argocd --type merge \
  -p '{"spec":{"operation":{"sync":{"revision":"HEAD"}}}}'
```

## 🏭 Industry Best Practices Implemented

### GitOps Principles
- **Declarative**: All configurations in Git
- **Versioned**: Git-based change tracking
- **Immutable**: Infrastructure as Code
- **Observable**: ArgoCD UI and monitoring

### Helm Best Practices
- **Values Separation**: Environment-specific values files
- **Chart Versioning**: Semantic versioning
- **Repository Management**: Centralized in MinIO
- **Templating**: Clean, reusable charts

### Multi-Environment Strategy
- **Progressive Deployment**: Dev → UAT → Prod
- **Environment Isolation**: Separate namespaces and RBAC
- **Configuration Management**: Environment-specific values
- **Security Hardening**: Increasing security by environment

### RBAC & Security
- **Least Privilege**: Minimal required permissions
- **Role-Based Access**: Team-specific access controls
- **Security Contexts**: Pod and container security
- **Network Policies**: Traffic isolation

## 🔧 Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Chart not found | Check MinIO repository connectivity |
| Application stuck syncing | Check RBAC permissions |
| Pods not starting | Review resource quotas and security contexts |
| Ingress not working | Verify DNS and SSL certificate setup |

### Debug Commands

```bash
# Check ArgoCD application details
kubectl describe application webapp-prod -n argocd

# Check application events
kubectl get events -n business-apps-prod --sort-by='.lastTimestamp'

# Test chart locally
helm template test-webapp myrepo/webapp -f environments/prod/webapp-values.yaml

# Check ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

## 📞 Support

- **MinIO Repository**: Maintained by platform team
- **Chart Issues**: Create issues in chart repository
- **Deployment Issues**: Check ArgoCD UI and logs
- **Security Questions**: Contact security team

---

**Repository Type**: Business Applications Only  
**Chart Storage**: MinIO S3 (`s3.devkuban.com`)  
**GitOps Tool**: ArgoCD  
**Last Updated**: July 5, 2025
