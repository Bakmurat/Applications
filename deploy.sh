#!/bin/bash

# Business Applications Deployment Script
# This script deploys business applications using ArgoCD and MinIO Helm repository

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

echo -e "${BLUE}🚀 Business Applications Deployment${NC}"
echo "====================================="

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

# Apply environment projects
echo -e "${BLUE}📋 Applying environment projects...${NC}"

kubectl apply -f projects/dev-project.yaml
kubectl apply -f projects/uat-project.yaml
kubectl apply -f projects/prod-project.yaml
print_status "Applied environment projects"

# Wait for projects to be ready
echo -e "${BLUE}⏳ Waiting for ArgoCD projects to be ready...${NC}"
sleep 5

# Apply individual applications
echo -e "${BLUE}📱 Deploying individual applications...${NC}"

kubectl apply -f applications/dev/webapp.yaml
kubectl apply -f applications/uat/webapp.yaml
kubectl apply -f applications/prod/webapp.yaml
print_status "Applied individual applications"

# Apply ApplicationSet for multi-environment management
echo -e "${BLUE}🎯 Deploying ApplicationSet...${NC}"

kubectl apply -f app-sets/business-apps-simple.yaml
print_status "Applied ApplicationSet for multi-environment management"

# Check ArgoCD application status
echo -e "${BLUE}📊 Checking ArgoCD application status...${NC}"

echo "Waiting for applications to appear in ArgoCD..."
sleep 10

# List ArgoCD applications
echo -e "${YELLOW}📋 ArgoCD Applications:${NC}"
kubectl get applications -n $ARGOCD_NAMESPACE | grep webapp || echo "No webapp applications found yet (they may still be syncing)"

echo ""
echo -e "${GREEN}🎉 Business Applications Deployment Complete!${NC}"
echo "=================================================="
echo ""
echo -e "${BLUE}📋 Summary:${NC}"
echo "✅ MinIO Helm repository configured in ArgoCD"
echo "✅ Environment projects created (dev, uat, prod)"
echo "✅ Individual applications deployed"
echo "✅ ApplicationSet deployed for multi-environment management"
echo ""
echo -e "${BLUE}🔗 Access Points:${NC}"
echo "• MinIO Helm Repository: $MINIO_HELM_REPO"
echo "• Webapp Dev: https://webapp-dev.devkuban.com"
echo "• Webapp UAT: https://webapp-uat.devkuban.com"
echo "• Webapp Prod: https://webapp.devkuban.com"
echo ""
echo -e "${BLUE}📝 Next Steps:${NC}"
echo "1. Check ArgoCD UI to verify applications are syncing"
echo "2. Monitor application deployment status"
echo "3. Configure DNS for ingress hosts"
echo "4. Set up SSL certificates with cert-manager"
echo ""
echo -e "${YELLOW}💡 Useful Commands:${NC}"
echo "• kubectl get applications -n argocd"
echo "• kubectl get pods -n business-apps-dev"
echo "• kubectl get pods -n business-apps-uat"
echo "• kubectl get pods -n business-apps-prod"
echo "• helm search repo myrepo"
