# 🚀 ArgoCD Multi-Environment Deployment Guide

## 📋 Current Situation
You have a messy repository with lots of duplicate files and inconsistent configurations. I've created a clean, best-practice structure that follows GitOps principles.

## 🏗️ New Clean Structure

```
Applications/
├── apps/                           # Main application definitions
│   ├── dev/                       # Development applications
│   │   ├── simple-nginx.yaml     # nginx for dev (1 replica)
│   │   └── simple-redis.yaml     # redis for dev (1 replica)
│   ├── uat/                       # UAT applications
│   │   ├── simple-nginx.yaml     # nginx for uat (2 replicas)
│   │   └── simple-redis.yaml     # redis for uat (1 replica)
│   └── prod/                      # Production applications
│       ├── simple-nginx.yaml     # nginx for prod (3 replicas, HA)
│       └── simple-redis.yaml     # redis for prod (2 replicas, HA)
├── projects/                      # ArgoCD projects (existing)
│   ├── dev-project.yaml          # Development RBAC
│   ├── uat-project.yaml          # UAT RBAC
│   └── prod-project.yaml         # Production RBAC
├── bootstrap/                     # Bootstrap configuration
│   └── helm-repositories.yaml    # MinIO Helm repo secret
└── scripts/                       # Deployment scripts
    ├── deploy-dev.sh             # Deploy to dev cluster
    ├── deploy-uat.sh             # Deploy to uat cluster
    └── deploy-prod.sh            # Deploy to prod cluster
```

## 🎯 Best Practices Implemented

✅ **Environment Isolation**: Each cluster only gets its own environment's applications
✅ **Helm Chart Source**: All applications pull from your MinIO repository
✅ **Embedded Values**: No external dependencies, all values are inline
✅ **Proper Resource Limits**: Environment-appropriate resource allocation
✅ **High Availability**: Production apps have anti-affinity rules
✅ **Correct Storage**: Production Redis uses "harvester" storage class
✅ **Automated Sync**: All apps sync automatically with retry policies
✅ **Clean Scripts**: Environment-specific deployment scripts with safety checks

## 🚀 How to Deploy

### Step 1: Deploy to Production Cluster (since you're currently in prodcluster)

```bash
# You're currently in prodcluster, so deploy production apps
./scripts/deploy-prod.sh
```

This will:
- Configure MinIO Helm repository in ArgoCD
- Apply production project with proper RBAC
- Deploy `simple-nginx-prod` (3 replicas with HA)
- Deploy `simple-redis-prod` (2 replicas with HA and persistence)

### Step 2: Deploy to Development Cluster

```bash
# Switch to dev cluster
kubectl config use-context devcluster

# Deploy development applications
./scripts/deploy-dev.sh
```

### Step 3: Deploy to UAT Cluster

```bash
# Switch to uat cluster
kubectl config use-context uatcluster

# Deploy UAT applications
./scripts/deploy-uat.sh
```

## 🔍 What Each Environment Gets

### Development (devcluster)
- **Namespace**: `business-apps-dev`
- **Resources**: Minimal (50m CPU, 64Mi RAM)
- **Replicas**: 1 for each application
- **Persistence**: Disabled (temporary data)

### UAT (uatcluster)
- **Namespace**: `business-apps-uat`
- **Resources**: Moderate (100m CPU, 128Mi RAM)
- **Replicas**: 2 nginx, 1 redis
- **Persistence**: Disabled (testing data)

### Production (prodcluster)
- **Namespace**: `business-apps-prod`
- **Resources**: High (250m CPU, 256Mi RAM)
- **Replicas**: 3 nginx, 2 redis
- **Persistence**: Enabled with harvester storage class
- **High Availability**: Anti-affinity rules

## 🛡️ Security & RBAC

Each environment has its own ArgoCD project with appropriate access controls:

- **dev-project**: Full access for developers
- **uat-project**: Limited access for testers
- **prod-project**: Restricted access for SRE team

## 🧹 Cleanup Required

After testing the new structure, you can remove these duplicate/unnecessary folders:

```bash
# Old duplicate folders to remove later
rm -rf applications/
rm -rf applicationsets/
rm -rf apps/
rm -rf clusters/
rm -rf dev/
rm -rf uat/
rm -rf prod/
rm -rf environments/
```

## 📊 Monitoring

After deployment, check status with:

```bash
# Check ArgoCD applications
kubectl get applications -n argocd

# Check application pods
kubectl get pods -n business-apps-prod

# Check application services
kubectl get svc -n business-apps-prod

# Check persistent volumes (prod only)
kubectl get pvc -n business-apps-prod
```

## 🎉 Benefits

✅ **Single Source of Truth**: All config in one place
✅ **No External Dependencies**: All values are inline
✅ **Environment Isolation**: Each cluster only has its apps
✅ **Proper Resource Management**: Environment-appropriate limits
✅ **GitOps Compliant**: Pure ArgoCD with Helm charts
✅ **Production Ready**: HA, persistence, and proper security
✅ **Easy Maintenance**: Clean structure and scripts

## 🚨 Important Notes

1. **Start with Production**: You're currently in prodcluster, so deploy there first
2. **Test Thoroughly**: Verify each environment before moving to next
3. **Monitor Resources**: Check that your clusters have enough resources
4. **Update Context**: Always verify `kubectl config current-context` before deployment
5. **Safety Checks**: Production script has extra safety confirmations

Ready to deploy? Start with `./scripts/deploy-prod.sh` in your current prodcluster! 🚀
