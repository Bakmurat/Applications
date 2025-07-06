#!/bin/bash

# Cleanup Script - Remove Dev/UAT Apps from Production Cluster
# This script removes dev and uat applications from the production cluster

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🧹 Cleaning Up Multi-Environment Deployment${NC}"
echo "============================================="
echo ""
echo -e "${YELLOW}⚠️  This script will remove DEV and UAT applications from this cluster${NC}"
echo -e "${YELLOW}⚠️  Only PRODUCTION applications should remain${NC}"
echo ""

# Show current applications
echo -e "${BLUE}📋 Current ArgoCD Applications:${NC}"
kubectl get applications -n argocd | grep -E "(NAME|webapp)" || echo "No webapp applications found"
echo ""

# Confirm deletion
read -p "Do you want to remove webapp-dev and webapp-uat applications? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo -e "${BLUE}🗑️  Removing dev and uat applications...${NC}"

# Function to force delete ArgoCD application
force_delete_app() {
    local app_name=$1
    echo -e "${BLUE}🔄 Force deleting $app_name...${NC}"
    
    # First try graceful deletion
    if kubectl delete application $app_name -n argocd --timeout=30s; then
        echo -e "${GREEN}✅ Gracefully deleted $app_name${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}⚠️  Graceful deletion failed, removing finalizers...${NC}"
    
    # Remove finalizers to force deletion
    kubectl patch application $app_name -n argocd -p '{"metadata":{"finalizers":null}}' --type=merge
    
    # Force delete
    kubectl delete application $app_name -n argocd --force --grace-period=0
    
    echo -e "${GREEN}✅ Force deleted $app_name${NC}"
}

# Remove dev application
if kubectl get application webapp-dev -n argocd &> /dev/null; then
    force_delete_app webapp-dev
else
    echo -e "${YELLOW}⚠️  webapp-dev not found${NC}"
fi

# Remove uat application  
if kubectl get application webapp-uat -n argocd &> /dev/null; then
    force_delete_app webapp-uat
else
    echo -e "${YELLOW}⚠️  webapp-uat not found${NC}"
fi

# Remove ApplicationSet if it exists
if kubectl get applicationset business-apps-multi-env -n argocd &> /dev/null; then
    echo ""
    read -p "Remove ApplicationSet (will recreate all environments)? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}🔄 Force deleting ApplicationSet...${NC}"
        
        # Try graceful deletion first
        if kubectl delete applicationset business-apps-multi-env -n argocd --timeout=30s; then
            echo -e "${GREEN}✅ Gracefully deleted ApplicationSet${NC}"
        else
            echo -e "${YELLOW}⚠️  Graceful deletion failed, removing finalizers...${NC}"
            # Remove finalizers and force delete
            kubectl patch applicationset business-apps-multi-env -n argocd -p '{"metadata":{"finalizers":null}}' --type=merge
            kubectl delete applicationset business-apps-multi-env -n argocd --force --grace-period=0
            echo -e "${GREEN}✅ Force deleted ApplicationSet${NC}"
        fi
    fi
fi

# Remove dev and uat projects
echo ""
echo -e "${BLUE}📋 Removing dev and uat projects...${NC}"

if kubectl get appproject dev-project -n argocd &> /dev/null; then
    kubectl delete appproject dev-project -n argocd
    echo -e "${GREEN}✅ Removed dev-project${NC}"
else
    echo -e "${YELLOW}⚠️  dev-project not found${NC}"
fi

if kubectl get appproject uat-project -n argocd &> /dev/null; then
    kubectl delete appproject uat-project -n argocd  
    echo -e "${GREEN}✅ Removed uat-project${NC}"
else
    echo -e "${YELLOW}⚠️  uat-project not found${NC}"
fi

echo ""
echo -e "${BLUE}📋 Remaining ArgoCD Applications:${NC}"
kubectl get applications -n argocd | grep -E "(NAME|webapp)" || echo "No webapp applications found"

echo ""
echo -e "${GREEN}🎉 Cleanup Complete!${NC}"
echo "========================"
echo ""
echo -e "${BLUE}📋 Summary:${NC}"
echo "✅ Removed dev applications and project"
echo "✅ Removed uat applications and project"
echo "✅ Production cluster now contains only production apps"
echo ""
echo -e "${BLUE}📝 Next Steps:${NC}"
echo "1. Deploy dev apps to dev cluster: ./clusters/dev/deploy-dev.sh"
echo "2. Deploy uat apps to uat cluster: ./clusters/uat/deploy-uat.sh"
echo "3. Verify prod apps are working correctly in this cluster"
