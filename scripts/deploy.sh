#!/bin/bash

# PRODUCTION Cluster Deployment Script
# This script deploys ONLY PRODUCTION business applications
# 
# IMPORTANT: For proper multi-cluster setup, use:
# - clusters/dev/deploy-dev.sh in DEV cluster
# - clusters/uat/deploy-uat.sh in UAT cluster  
# - clusters/prod/deploy-prod.sh in PROD cluster
#
# This script is equivalent to clusters/prod/deploy-prod.sh but includes
# additional validation and the ApplicationSet for demonstration purposes.

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MINIO_HELM_REPO="http://s3.devkuban.com/helm-charts"
ARGOCD_NAMESPACE="argocd"
ENVIRONMENT="prod"

echo -e "${BLUE}🚀 PRODUCTION Cluster Business Applications Deployment${NC}"
echo "====================================================="
echo -e "${YELLOW}⚠️  This script deploys ONLY PRODUCTION applications${NC}"
echo -e "${YELLOW}⚠️  For dev/uat, use cluster-specific scripts in clusters/ directory${NC}"
echo ""

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
    print_warning "Current context '$CURRENT_CONTEXT' doesn't appear to be PRODUCTION cluster"
    print_warning "This script should only be run in the PRODUCTION cluster"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled. Use appropriate cluster-specific script:"
        echo "- For DEV: clusters/dev/deploy-dev.sh"
        echo "- For UAT: clusters/uat/deploy-uat.sh"
        echo "- For PROD: clusters/prod/deploy-prod.sh"
        exit 1
    fi
fi

# Check prerequisites
echo -e "${BLUE}🔍 Checking prerequisites...${NC}"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    print_error "helm is not installed or not in PATH"
    exit 1
fi

# Check if ArgoCD namespace exists
if ! kubectl get namespace $ARGOCD_NAMESPACE &> /dev/null; then
    print_error "ArgoCD namespace '$ARGOCD_NAMESPACE' does not exist"
    print_warning "Please install ArgoCD first"
    exit 1
fi

print_status "Prerequisites check passed"

# Test MinIO Helm repository connectivity
echo -e "${BLUE}🌐 Testing MinIO Helm repository connectivity...${NC}"

if curl -s --connect-timeout 10 "$MINIO_HELM_REPO/index.yaml" > /dev/null; then
    print_status "MinIO Helm repository is accessible"
else
    print_error "Cannot reach MinIO Helm repository at $MINIO_HELM_REPO"
    print_warning "Please check your network connection and MinIO setup"
    exit 1
fi

# Add Helm repository locally for testing
echo -e "${BLUE}📦 Adding MinIO Helm repository locally...${NC}"

if helm repo list | grep -q "myrepo"; then
    print_warning "MinIO repo 'myrepo' already exists, updating..."
    helm repo update myrepo
else
    helm repo add myrepo "$MINIO_HELM_REPO"
    print_status "Added MinIO Helm repository as 'myrepo'"
fi

# Test chart availability
echo -e "${BLUE}🔍 Testing chart availability...${NC}"

if helm search repo myrepo/webapp --version 1.0.9 | grep -q "webapp"; then
    print_status "webapp chart v1.0.9 found in MinIO repository"
else
    print_error "webapp chart v1.0.9 not found in MinIO repository"
    echo "Available charts:"
    helm search repo myrepo
    exit 1
fi

# Apply MinIO repository secret
echo -e "${BLUE}🔐 Configuring ArgoCD repository secret...${NC}"

kubectl apply -f bootstrap/minio-helm-repo.yaml
print_status "Applied MinIO Helm repository secret to ArgoCD"

# Apply environment projects - PRODUCTION ONLY
echo -e "${BLUE}📋 Applying PRODUCTION project...${NC}"

kubectl apply -f projects/prod-project.yaml
print_status "Applied production project"

# Wait for projects to be ready
echo -e "${BLUE}⏳ Waiting for ArgoCD project to be ready...${NC}"
sleep 5

# Apply PRODUCTION application only
echo -e "${BLUE}📱 Deploying PRODUCTION applications...${NC}"

kubectl apply -f applications/prod/webapp.yaml
print_status "Applied production webapp application"

# Apply ApplicationSet for demonstration (optional)
echo -e "${BLUE}🎯 Deploying ApplicationSet (for demo purposes)...${NC}"
print_warning "ApplicationSet will create ALL environments in this cluster"
print_warning "This is NOT recommended for production multi-cluster setup"

read -p "Deploy ApplicationSet anyway? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    kubectl apply -f app-sets/business-apps-simple.yaml
    print_status "Applied ApplicationSet (demo mode)"
else
    print_status "Skipped ApplicationSet deployment (recommended for prod)"
fi

# Check ArgoCD application status
echo -e "${BLUE}📊 Checking ArgoCD application status...${NC}"

echo "Waiting for applications to appear in ArgoCD..."
sleep 10

# List ArgoCD applications
echo -e "${YELLOW}📋 ArgoCD Applications:${NC}"
kubectl get applications -n $ARGOCD_NAMESPACE | grep -E "(NAME|webapp-prod)" || echo "No production webapp applications found yet"

echo ""
echo -e "${GREEN}🎉 PRODUCTION Business Applications Deployment Complete!${NC}"
echo "======================================================="
echo ""
echo -e "${BLUE}📋 Summary:${NC}"
echo "✅ MinIO Helm repository configured in ArgoCD"
echo "✅ Production project created"
echo "✅ Production webapp application deployed"
echo ""
echo -e "${BLUE}🔗 Access Points:${NC}"
echo "• MinIO Helm Repository: $MINIO_HELM_REPO"
echo "• Webapp Prod: https://webapp.devkuban.com"
echo ""
echo -e "${BLUE}📝 Next Steps for Multi-Cluster Setup:${NC}"
echo "1. In DEV cluster: Run 'clusters/dev/deploy-dev.sh'"
echo "2. In UAT cluster: Run 'clusters/uat/deploy-uat.sh'"
echo "3. In PROD cluster: This script or 'clusters/prod/deploy-prod.sh'"
echo "4. Monitor each cluster's ArgoCD UI separately"
echo ""
echo -e "${YELLOW}💡 Multi-Cluster Commands:${NC}"
echo "• kubectl get applications -n argocd (in each cluster)"
echo "• kubectl get pods -n business-apps-prod (production only)"
