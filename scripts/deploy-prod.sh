#!/bin/bash

# Production Cluster Deployment Script
# Run this ONLY in the PROD cluster (prodcluster)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ENVIRONMENT="prod"
MINIO_HELM_REPO="http://s3.devkuban.com/helm-charts"
ARGOCD_NAMESPACE="argocd"

echo -e "${BLUE}🚀 Production Cluster Deployment${NC}"
echo "=================================="

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

if [[ ! "$CURRENT_CONTEXT" =~ "prod" ]]; then
    print_warning "Current context '$CURRENT_CONTEXT' doesn't appear to be PROD cluster"
    print_warning "⚠️  THIS IS PRODUCTION - DOUBLE CHECK YOUR CONTEXT!"
    read -p "Are you SURE you want to deploy to PRODUCTION? (yes/no): " -r
    if [[ ! $REPLY == "yes" ]]; then
        print_error "Deployment cancelled for safety"
        exit 1
    fi
fi

# Extra production safety check
echo -e "${RED}🛡️  PRODUCTION DEPLOYMENT SAFETY CHECK${NC}"
echo "You are about to deploy to PRODUCTION environment"
read -p "Type 'DEPLOY-TO-PRODUCTION' to continue: " -r
if [[ ! $REPLY == "DEPLOY-TO-PRODUCTION" ]]; then
    print_error "Safety check failed. Deployment cancelled."
    exit 1
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

# Apply prod project
echo -e "${BLUE}📋 Applying production project...${NC}"
kubectl apply -f projects/prod-project.yaml
print_status "Applied prod-project"

# Wait for project
sleep 3

# Deploy production applications
echo -e "${BLUE}📱 Deploying production app-of-apps...${NC}"
kubectl apply -f app-of-apps/prod-apps.yaml
print_status "Applied prod-apps (app-of-apps pattern)"

# Check status
echo -e "${BLUE}📊 Checking deployment status...${NC}"
sleep 5

echo -e "${YELLOW}📋 ArgoCD Applications:${NC}"
kubectl get applications -n $ARGOCD_NAMESPACE | grep -E "(NAME|.*-prod|prod-apps)" || echo "No prod applications found yet"

echo ""
echo -e "${GREEN}🎉 Production Cluster Deployment Complete!${NC}"
echo "=============================================="
echo ""
echo -e "${BLUE}📋 What was deployed:${NC}"
echo "✅ MinIO Helm repository configured"
echo "✅ Production project created"
echo "✅ prod-apps (app-of-apps) deployed"
echo "✅ simple-nginx-prod application (via app-of-apps)"
echo "✅ simple-redis-prod application (via app-of-apps)"
echo ""
echo -e "${BLUE}🔗 Access:${NC}"
echo "• ArgoCD UI: Check for prod applications"
echo "• Namespaces: simple-nginx, simple-redis"
echo ""
echo -e "${YELLOW}💡 Monitoring:${NC}"
echo "• Monitor application sync status in ArgoCD UI"
echo "• Check nginx pods: kubectl get pods -n simple-nginx"
echo "• Check redis pods: kubectl get pods -n simple-redis"
echo "• Set up monitoring and alerting"
echo "• Verify high availability and performance"
