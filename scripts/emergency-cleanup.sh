#!/bin/bash

# Emergency Cleanup - Force Delete Stuck ArgoCD Applications
# Use this if applications are stuck in deletion

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}🚨 Emergency ArgoCD Application Cleanup${NC}"
echo "========================================="
echo ""
echo -e "${YELLOW}⚠️  This will force delete stuck applications${NC}"
echo ""

# Function to force delete with finalizer removal
force_delete_app() {
    local app_name=$1
    echo -e "${BLUE}🔄 Processing $app_name...${NC}"
    
    if ! kubectl get application $app_name -n argocd &> /dev/null; then
        echo -e "${YELLOW}⚠️  $app_name not found, skipping${NC}"
        return 0
    fi
    
    # Check if it's stuck in deletion
    local deletion_timestamp=$(kubectl get application $app_name -n argocd -o jsonpath='{.metadata.deletionTimestamp}' 2>/dev/null || echo "")
    
    if [[ -n "$deletion_timestamp" ]]; then
        echo -e "${YELLOW}⚠️  $app_name is stuck in deletion, removing finalizers...${NC}"
        # Remove finalizers
        kubectl patch application $app_name -n argocd -p '{"metadata":{"finalizers":null}}' --type=merge
        echo -e "${GREEN}✅ Removed finalizers from $app_name${NC}"
    else
        echo -e "${BLUE}🗑️  Deleting $app_name...${NC}"
        # Remove finalizers first to prevent hanging
        kubectl patch application $app_name -n argocd -p '{"metadata":{"finalizers":null}}' --type=merge
        kubectl delete application $app_name -n argocd --force --grace-period=0
        echo -e "${GREEN}✅ Force deleted $app_name${NC}"
    fi
}

# Force delete dev and uat applications
echo -e "${BLUE}📋 Current Applications:${NC}"
kubectl get applications -n argocd | grep -E "(NAME|webapp)" || echo "No webapp applications found"
echo ""

force_delete_app webapp-dev
force_delete_app webapp-uat

# Handle ApplicationSet
if kubectl get applicationset business-apps-multi-env -n argocd &> /dev/null; then
    echo ""
    echo -e "${BLUE}🔄 Processing ApplicationSet...${NC}"
    
    deletion_timestamp=$(kubectl get applicationset business-apps-multi-env -n argocd -o jsonpath='{.metadata.deletionTimestamp}' 2>/dev/null || echo "")
    
    if [[ -n "$deletion_timestamp" ]]; then
        echo -e "${YELLOW}⚠️  ApplicationSet is stuck in deletion, removing finalizers...${NC}"
        kubectl patch applicationset business-apps-multi-env -n argocd -p '{"metadata":{"finalizers":null}}' --type=merge
        echo -e "${GREEN}✅ Removed finalizers from ApplicationSet${NC}"
    else
        read -p "Delete ApplicationSet? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            kubectl patch applicationset business-apps-multi-env -n argocd -p '{"metadata":{"finalizers":null}}' --type=merge
            kubectl delete applicationset business-apps-multi-env -n argocd --force --grace-period=0
            echo -e "${GREEN}✅ Force deleted ApplicationSet${NC}"
        fi
    fi
fi

# Force delete projects if they're stuck
for project in dev-project uat-project; do
    if kubectl get appproject $project -n argocd &> /dev/null; then
        echo -e "${BLUE}🔄 Processing $project...${NC}"
        
        deletion_timestamp=$(kubectl get appproject $project -n argocd -o jsonpath='{.metadata.deletionTimestamp}' 2>/dev/null || echo "")
        
        if [[ -n "$deletion_timestamp" ]]; then
            echo -e "${YELLOW}⚠️  $project is stuck in deletion, removing finalizers...${NC}"
            kubectl patch appproject $project -n argocd -p '{"metadata":{"finalizers":null}}' --type=merge
        else
            kubectl patch appproject $project -n argocd -p '{"metadata":{"finalizers":null}}' --type=merge
            kubectl delete appproject $project -n argocd --force --grace-period=0
        fi
        echo -e "${GREEN}✅ Processed $project${NC}"
    fi
done

echo ""
echo -e "${BLUE}📋 Final State:${NC}"
kubectl get applications -n argocd | grep -E "(NAME|webapp)" || echo "No webapp applications found"
kubectl get applicationsets -n argocd | grep business-apps || echo "No ApplicationSet found"
kubectl get appprojects -n argocd | grep -E "(dev-project|uat-project)" || echo "No dev/uat projects found"

echo ""
echo -e "${GREEN}🎉 Emergency Cleanup Complete!${NC}"
echo "=============================="
echo ""
echo -e "${BLUE}📝 Next Steps:${NC}"
echo "1. Verify only webapp-prod remains in this cluster"
echo "2. Deploy to correct clusters:"
echo "   - Dev: kubectl config use-context dev-cluster && ./clusters/dev/deploy-dev.sh"
echo "   - UAT: kubectl config use-context uat-cluster && ./clusters/uat/deploy-uat.sh"
