#!/bin/bash

# ArgoCD Applications Deployment Script
# This script deploys the App-of-Apps to ArgoCD for the specified environment

set -e

ENVIRONMENT=${1:-prod}
ARGOCD_NAMESPACE="argocd"

echo "🚀 Deploying ArgoCD App-of-Apps for environment: $ENVIRONMENT"

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|uat|prod)$ ]]; then
    echo "❌ Error: Environment must be one of: dev, uat, prod"
    exit 1
fi

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ Error: kubectl is not installed or not in PATH"
    exit 1
fi

# Check if ArgoCD namespace exists
if ! kubectl get namespace $ARGOCD_NAMESPACE &> /dev/null; then
    echo "❌ Error: ArgoCD namespace '$ARGOCD_NAMESPACE' does not exist"
    exit 1
fi

# Apply the App-of-Apps
echo "📦 Applying App-of-Apps for $ENVIRONMENT environment..."
kubectl apply -f apps/$ENVIRONMENT/app-of-apps.yaml

echo "✅ Successfully deployed App-of-Apps for $ENVIRONMENT environment"
echo "🔍 You can check the status with:"
echo "   kubectl get applications -n $ARGOCD_NAMESPACE"
echo "   argocd app list"

echo ""
echo "📋 Applications that will be deployed:"
echo "   - sample-nginx-$ENVIRONMENT"
echo "   - sample-hello-world-$ENVIRONMENT"
echo ""
echo "🎯 Target namespace: sample-apps-$ENVIRONMENT"
