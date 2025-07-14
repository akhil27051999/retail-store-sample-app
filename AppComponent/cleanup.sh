#!/bin/bash

# Retail Store App - Cleanup Script
# This script removes the retail store application deployed using namespace-based approach

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to confirm cleanup
confirm_cleanup() {
    echo "=========================================="
    echo "Retail Store App - Cleanup"
    echo "=========================================="
    echo ""
    print_warning "This will delete all retail store application resources!"
    echo ""
    echo "The following namespaces and all their resources will be deleted:"
    echo "- retail-frontend"
    echo "- retail-services"
    echo "- retail-data"
    echo ""
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Cleanup cancelled"
        exit 0
    fi
}

# Function to cleanup frontend tier
cleanup_frontend() {
    print_status "Removing frontend tier..."
    if kubectl get namespace retail-frontend &> /dev/null; then
        kubectl delete -f k8s-manifests/frontend-tier/ui-service.yaml --ignore-not-found=true
        print_success "Frontend tier removed"
    else
        print_warning "Frontend namespace not found, skipping..."
    fi
}

# Function to cleanup services tier
cleanup_services() {
    print_status "Removing services tier..."
    if kubectl get namespace retail-services &> /dev/null; then
        kubectl delete -f k8s-manifests/services-tier/backend-services.yaml --ignore-not-found=true
        print_success "Services tier removed"
    else
        print_warning "Services namespace not found, skipping..."
    fi
}

# Function to cleanup data tier
cleanup_data() {
    print_status "Removing data tier..."
    if kubectl get namespace retail-data &> /dev/null; then
        kubectl delete -f k8s-manifests/data-tier/databases.yaml --ignore-not-found=true
        print_success "Data tier removed"
    else
        print_warning "Data namespace not found, skipping..."
    fi
}

# Function to cleanup namespaces
cleanup_namespaces() {
    print_status "Removing namespaces..."
    kubectl delete -f k8s-manifests/namespaces/namespaces.yaml --ignore-not-found=true
    
    # Wait for namespaces to be fully deleted
    print_status "Waiting for namespaces to be fully deleted..."
    
    for ns in retail-frontend retail-services retail-data; do
        while kubectl get namespace $ns &> /dev/null; do
            print_status "Waiting for namespace $ns to be deleted..."
            sleep 5
        done
    done
    
    print_success "All namespaces removed"
}

# Function to verify cleanup
verify_cleanup() {
    print_status "Verifying cleanup..."
    
    # Check for any remaining retail resources
    REMAINING_NAMESPACES=$(kubectl get namespaces | grep retail || true)
    REMAINING_PODS=$(kubectl get pods --all-namespaces | grep retail || true)
    
    if [ -z "$REMAINING_NAMESPACES" ] && [ -z "$REMAINING_PODS" ]; then
        print_success "Cleanup completed successfully - no retail resources found"
    else
        print_warning "Some resources may still be terminating:"
        if [ ! -z "$REMAINING_NAMESPACES" ]; then
            echo "Namespaces:"
            echo "$REMAINING_NAMESPACES"
        fi
        if [ ! -z "$REMAINING_PODS" ]; then
            echo "Pods:"
            echo "$REMAINING_PODS"
        fi
        print_status "Resources may take a few more minutes to fully terminate"
    fi
}

# Function to show cleanup options
show_options() {
    echo ""
    echo "Cleanup Options:"
    echo "1. Full cleanup (recommended) - removes all tiers and namespaces"
    echo "2. Partial cleanup - remove specific tiers only"
    echo "3. Force cleanup - delete namespaces directly (faster but less graceful)"
    echo ""
    read -p "Select option (1-3): " -n 1 -r
    echo ""
    
    case $REPLY in
        1)
            full_cleanup
            ;;
        2)
            partial_cleanup
            ;;
        3)
            force_cleanup
            ;;
        *)
            print_error "Invalid option selected"
            exit 1
            ;;
    esac
}

# Function for full cleanup
full_cleanup() {
    print_status "Starting full cleanup..."
    cleanup_frontend
    cleanup_services
    cleanup_data
    cleanup_namespaces
    verify_cleanup
}

# Function for partial cleanup
partial_cleanup() {
    echo ""
    echo "Select tier to remove:"
    echo "1. Frontend tier only"
    echo "2. Services tier only"
    echo "3. Data tier only"
    echo "4. Frontend + Services (keep data)"
    echo ""
    read -p "Select option (1-4): " -n 1 -r
    echo ""
    
    case $REPLY in
        1)
            cleanup_frontend
            ;;
        2)
            cleanup_services
            ;;
        3)
            cleanup_data
            ;;
        4)
            cleanup_frontend
            cleanup_services
            ;;
        *)
            print_error "Invalid option selected"
            exit 1
            ;;
    esac
    
    print_success "Partial cleanup completed"
}

# Function for force cleanup
force_cleanup() {
    print_warning "Force cleanup will delete namespaces directly"
    print_status "This is faster but less graceful than removing individual resources"
    echo ""
    read -p "Continue with force cleanup? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Force deleting namespaces..."
        kubectl delete namespace retail-frontend retail-services retail-data --ignore-not-found=true
        
        print_status "Waiting for namespaces to be deleted..."
        sleep 10
        verify_cleanup
    else
        print_status "Force cleanup cancelled"
    fi
}

# Main function
main() {
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    # Check if any retail namespaces exist
    if ! kubectl get namespaces | grep -q retail; then
        print_status "No retail store namespaces found - nothing to cleanup"
        exit 0
    fi
    
    confirm_cleanup
    show_options
    
    echo ""
    print_success "Cleanup process completed!"
    print_status "You can verify with: kubectl get namespaces | grep retail"
}

# Run main function
main