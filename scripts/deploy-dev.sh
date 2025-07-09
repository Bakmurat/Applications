#!/bin/bash

# Development Cluster Deployment Script
# Run this ONLY in the DEV cluster (devcluster)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ENVIRONMENT="dev"
MINIO_HELM_REPO="http://s3.devkuban.com/helm-charts"
ARGOCD_NAMESPACE="argocd"

echo -e "${BLUE}🚀 Development Cluster Deployment${NC}"
echo "==================================="

# Function to print status
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if we're in the right environment
echo -e "${BLUE}🔍 Environment Check...${NC}"
CURRENT_CONTEXT=$(kubectl config current-context)
echo "Current kubectl context: $CURRENT_CONTEXT"

if [[ ! "$CURRENT_CONTEXT" =~ "dev" ]]; then
    print_warning "Current context '$CURRENT_CONTEXT' doesn't appear to be DEV cluster"
    print_warning "This script should be run in the DEV cluster context"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check prerequisites
echo -e "${BLUE}🔍 Checking prerequisites...${NC}"

if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed"
    exit 1
fi

if ! kubectl get namespace $ARGOCD_NAMESPACE &> /dev/null; then
    print_error "ArgoCD namespace '$ARGOCD_NAMESPACE' does not exist"
    exit 1
fi

print_status "Prerequisites check passed"

# Test MinIO connectivity
echo -e "${BLUE}🌐 Testing MinIO Helm repository...${NC}"
if curl -s --connect-timeout 10 "$MINIO_HELM_REPO/index.yaml" > /dev/null; then
    print_status "MinIO Helm repository is accessible"
else
    print_error "Cannot reach MinIO Helm repository"
    exit 1
fi

# Configure ArgoCD repository
echo -e "${BLUE}🔐 Configuring ArgoCD repository secret...${NC}"
kubectl apply -f bootstrap/helm-repositories.yaml
print_status "Applied MinIO repository secret"

# Apply dev project
echo -e "${BLUE}📋 Applying development project...${NC}"
kubectl apply -f projects/dev-project.yaml
print_status "Applied dev-project"

# Wait for project
sleep 3

# Deploy development applications
echo -e "${BLUE}📱 Deploying development app-of-apps...${NC}"
kubectl apply -f app-of-apps/dev-apps.yaml
print_status "Applied dev-apps (app-of-apps pattern)"

# Check status
echo -e "${BLUE}📊 Checking deployment status...${NC}"
sleep 5

echo -e "${YELLOW}📋 ArgoCD Applications:${NC}"
kubectl get applications -n $ARGOCD_NAMESPACE | grep -E "(NAME|.*-dev|dev-apps)" || echo "No dev applications found yet"

echo ""
echo -e "${GREEN}🎉 Development Cluster Deployment Complete!${NC}"
echo "=============================================="
echo ""
echo -e "${BLUE}📋 What was deployed:${NC}"
echo "✅ MinIO Helm repository configured"
echo "✅ Development project created"
echo "✅ dev-apps (app-of-apps) deployed"
echo "✅ simple-nginx-dev application (via app-of-apps)"
echo "✅ simple-redis-dev application (via app-of-apps)"
echo ""
echo -e "${BLUE}🔗 Access:${NC}"
echo "• ArgoCD UI: Check for dev applications"
echo "• Namespaces: simple-nginx, simple-redis"
echo ""
echo -e "${YELLOW}💡 Next Steps:${NC}"
echo "• Monitor application sync status in ArgoCD UI"
echo "• Check nginx pods: kubectl get pods -n simple-nginx"
echo "• Check redis pods: kubectl get pods -n simple-redis"
echo "• Test applications and promote to UAT when ready"
