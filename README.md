# ArgoCD Applications Repository

This repository contains ArgoCD application definitions for deploying business applications into multi-environment Kubernetes clusters.

## Repository Structure

```
├── apps/                           # App-of-Apps definitions
│   ├── dev/                       # Development environment apps
│   ├── uat/                       # UAT environment apps
│   └── prod/                      # Production environment apps
├── applications/                   # Individual application definitions
│   ├── sample-nginx/              # Sample nginx application
│   └── sample-hello-world/        # Sample hello-world application
└── manifests/                     # Kubernetes manifests for applications
    ├── sample-nginx/              # Nginx application manifests
    │   ├── base/                  # Base manifests
    │   ├── dev/                   # Development overlays
    │   ├── uat/                   # UAT overlays
    │   └── prod/                  # Production overlays
    └── sample-hello-world/        # Hello-world application manifests
        ├── base/                  # Base manifests
        ├── dev/                   # Development overlays
        ├── uat/                   # UAT overlays
        └── prod/                  # Production overlays
```

## Environments

- **dev**: Development environment (devcluster)
- **uat**: UAT environment (uatcluster)  
- **prod**: Production environment (prodcluster)

## Applications

### Sample Applications
- **sample-nginx**: Simple nginx web server
- **sample-hello-world**: Simple hello world web application

## ArgoCD Configuration

- **Namespace**: argocd
- **Sync Policy**: Automatic with auto-prune and self-heal enabled
- **Repository**: git@github.com:Bakmurat/Applications.git

## Deployment

1. Apply the App-of-Apps for your desired environment:
   ```bash
   kubectl apply -f apps/prod/app-of-apps.yaml
   ```

2. ArgoCD will automatically deploy all applications defined in the App-of-Apps.

## Best Practices

- Each application has its own ArgoCD Application definition
- Environment-specific configurations use Kustomize overlays
- Separate namespaces for different applications
- Auto-sync enabled for continuous deployment
- Proper RBAC and security configurations
