#!/bin/bash

# Multi-Cluster Deployment Helper
# This script helps you deploy to the correct clusters

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🏢 Multi-Cluster Business Applications Deployment${NC}"
echo "=================================================="
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: Multi-Cluster Best Practices${NC}"
echo ""
echo "For proper GitOps multi-cluster setup, each ArgoCD instance should"
echo "only manage applications for its own environment."
echo ""
echo -e "${BLUE}📋 Available Deployment Options:${NC}"
echo ""
echo "1. 🔧 DEV Cluster   - Run: clusters/dev/deploy-dev.sh"
echo "2. 🧪 UAT Cluster   - Run: clusters/uat/deploy-uat.sh"  
echo "3. 🚀 PROD Cluster  - Run: clusters/prod/deploy-prod.sh"
echo "4. 🎯 Single Demo   - Run: deploy.sh (deploys all envs to current cluster)"
echo ""
echo -e "${GREEN}🎯 Recommended Workflow:${NC}"
echo ""
echo "1. Switch to DEV cluster context"
echo "   kubectl config use-context dev-cluster"
echo "   ./clusters/dev/deploy-dev.sh"
echo ""
echo "2. Switch to UAT cluster context"
echo "   kubectl config use-context uat-cluster"
echo "   ./clusters/uat/deploy-uat.sh"
echo ""
echo "3. Switch to PROD cluster context" 
echo "   kubectl config use-context prod-cluster"
echo "   ./clusters/prod/deploy-prod.sh"
echo ""
echo -e "${BLUE}📊 Current kubectl context:${NC}"
kubectl config current-context
echo ""
echo -e "${YELLOW}💡 Tip:${NC} Use 'kubectl config get-contexts' to see all available contexts"
