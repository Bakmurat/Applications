#!/bin/bash

# UAT Cluster Deployment Script
# Run this ONLY in the UAT cluster where ArgoCD is installed

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ENVIRONMENT="uat"
MINIO_HELM_REPO="http://s3.devkuban.com/helm-charts"
ARGOCD_NAMESPACE="argocd"

echo -e "${BLUE}🚀 UAT Cluster Business Applications Deployment${NC}"
echo "================================================="

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

if [[ ! "$CURRENT_CONTEXT" =~ "uat" ]]; then
    print_warning "Current context '$CURRENT_CONTEXT' doesn't appear to be UAT cluster"
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

if ! command -v helm &> /dev/null; then
    print_error "helm is not installed"
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
kubectl apply -f ../../bootstrap/minio-helm-repo.yaml
print_status "Applied MinIO repository secret"

# Apply uat project
echo -e "${BLUE}📋 Applying UAT project...${NC}"
kubectl apply -f ../../projects/uat-project.yaml
print_status "Applied uat-project"

# Wait for project
sleep 3

# Deploy UAT applications
echo -e "${BLUE}📱 Deploying UAT applications...${NC}"
kubectl apply -f webapp.yaml
print_status "Applied webapp for UAT"

# Check status
echo -e "${BLUE}📊 Checking deployment status...${NC}"
sleep 5

kubectl get applications -n $ARGOCD_NAMESPACE | grep -E "(NAME|webapp-uat)" || true

echo ""
echo -e "${GREEN}🎉 UAT Cluster Deployment Complete!${NC}"
echo "======================================="
echo ""
echo -e "${BLUE}📋 What was deployed:${NC}"
echo "✅ MinIO Helm repository configured"
echo "✅ UAT project created"
echo "✅ webapp-uat application deployed"
echo ""
echo -e "${BLUE}🔗 Access:${NC}"
echo "• ArgoCD UI: Check for 'webapp-uat' application"
echo "• Application URL: https://webapp-uat.devkuban.com"
echo ""
echo -e "${YELLOW}💡 Next Steps:${NC}"
echo "• Monitor application sync status in ArgoCD UI"
echo "• Run QA tests on UAT environment"
echo "• Prepare for production deployment after UAT approval"
