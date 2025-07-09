# Multi-Environment ArgoCD Setup

This repository contains ArgoCD application definitions for a multi-cluster setup with dev, uat, and prod environments.

## 🏗️ Architecture

```
├── apps/                    # Main application definitions
│   ├── dev/                # Development environment applications
│   ├── uat/                # UAT environment applications  
│   └── prod/               # Production environment applications
├── values/                 # Helm values files
│   ├── dev/                # Development environment values
│   ├── uat/                # UAT environment values
│   └── prod/               # Production environment values
├── projects/               # ArgoCD project definitions
│   ├── dev-project.yaml    # Development project with RBAC
│   ├── uat-project.yaml    # UAT project with RBAC
│   └── prod-project.yaml   # Production project with RBAC
├── bootstrap/              # Bootstrap configuration
│   └── helm-repositories.yaml  # Helm repository secrets
└── scripts/                # Deployment scripts
    ├── deploy-dev.sh       # Deploy to dev cluster
    ├── deploy-uat.sh       # Deploy to uat cluster
    └── deploy-prod.sh      # Deploy to prod cluster
```

## 🚀 Deployment Guide

### Prerequisites
- ArgoCD installed in each cluster
- kubectl configured with cluster contexts
- Helm charts available in MinIO repository: `http://s3.devkuban.com/helm-charts`

### Multi-Cluster Deployment

**Step 1: Deploy to Development Cluster**
```bash
kubectl config use-context devcluster
./scripts/deploy-dev.sh
```

**Step 2: Deploy to UAT Cluster**
```bash
kubectl config use-context uatcluster
./scripts/deploy-uat.sh
```

**Step 3: Deploy to Production Cluster**
```bash
kubectl config use-context prodcluster
./scripts/deploy-prod.sh
```

## 📱 Applications

### simple-nginx
- **Chart**: `simple-nginx:1.2.0` from MinIO Helm repository
- **Environments**: dev (1 replica), uat (2 replicas), prod (3 replicas)
- **Namespace**: `business-apps-{env}`

### simple-redis
- **Chart**: `simple-redis:1.0.0` from MinIO Helm repository
- **Environments**: dev (1 replica), uat (1 replica), prod (2 replicas)
- **Namespace**: `business-apps-{env}`

## 🛡️ Security & RBAC

Each environment has its own ArgoCD project with appropriate RBAC:

- **dev-project**: Full access for developers
- **uat-project**: Limited access for testers
- **prod-project**: Restricted access for SRE team

## 🔧 Customization

Environment-specific values are stored in separate files in the `values/` directory:

- `values/dev/` - Development environment values (minimal resources)
- `values/uat/` - UAT environment values (moderate resources)
- `values/prod/` - Production environment values (high resources, HA)

Each application references its environment-specific values file using ArgoCD's multiple sources feature.

## 📊 Monitoring

Each application includes:
- Automated sync policies
- Health checks
- Resource limits appropriate for environment
- High availability configurations (prod)

## 🎯 Best Practices Implemented

✅ **Single Source of Truth**: All configurations in one repository
✅ **Environment Isolation**: Each cluster only gets its applications
✅ **Proper RBAC**: Environment-specific permissions
✅ **Resource Optimization**: Environment-appropriate resource limits
✅ **High Availability**: Anti-affinity rules in production
✅ **Automated Sync**: With proper retry policies
✅ **Namespace Isolation**: Separate namespaces per environment
