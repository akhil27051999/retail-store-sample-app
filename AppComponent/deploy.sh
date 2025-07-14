#!/bin/bash

# Retail Store App - Namespace-Based Deployment Script
# This script deploys the retail store application using a three-tier namespace approach

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

# Function to check if kubectl is available
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    # Check if kubectl can connect to cluster
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to deploy namespaces
deploy_namespaces() {
    print_status "Creating namespaces..."
    kubectl apply -f k8s-manifests/namespaces/namespaces.yaml
    
    # Verify namespaces
    sleep 2
    kubectl get namespaces | grep retail
    print_success "Namespaces created successfully"
}

# Function to deploy data tier
deploy_data_tier() {
    print_status "Deploying data tier (databases)..."
    kubectl apply -f k8s-manifests/data-tier/databases.yaml
    
    print_status "Waiting for databases to be ready..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=mysql -n retail-data --timeout=300s
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=dynamodb -n retail-data --timeout=300s
    
    print_success "Data tier deployed successfully"
    kubectl get pods -n retail-data
}

# Function to deploy services tier
deploy_services_tier() {
    print_status "Deploying services tier (backend APIs)..."
    kubectl apply -f k8s-manifests/services-tier/backend-services.yaml
    
    print_status "Waiting for services to be ready..."
    kubectl wait --for=condition=available deployment/catalog -n retail-services --timeout=300s
    kubectl wait --for=condition=available deployment/carts -n retail-services --timeout=300s
    
    print_success "Services tier deployed successfully"
    kubectl get pods -n retail-services
}

# Function to deploy frontend tier
deploy_frontend_tier() {
    print_status "Deploying frontend tier (UI)..."
    kubectl apply -f k8s-manifests/frontend-tier/ui-service.yaml
    
    print_status "Waiting for UI to be ready..."
    kubectl wait --for=condition=available deployment/ui -n retail-frontend --timeout=300s
    
    print_success "Frontend tier deployed successfully"
    kubectl get pods -n retail-frontend
}

# Function to get application URL
get_application_url() {
    print_status "Getting application URL..."
    
    # Wait a bit for LoadBalancer to get external IP
    sleep 30
    
    UI_URL=$(kubectl get service ui -n retail-frontend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    
    if [ -z "$UI_URL" ]; then
        UI_URL=$(kubectl get service ui -n retail-frontend -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    fi
    
    if [ -z "$UI_URL" ]; then
        print_warning "LoadBalancer external IP/hostname not yet assigned"
        print_status "You can check the service status with: kubectl get service ui -n retail-frontend"
        print_status "Or use port-forward: kubectl port-forward -n retail-frontend service/ui 8080:80"
    else
        print_success "Application is available at: http://$UI_URL"
    fi
}

# Function to show deployment status
show_status() {
    print_status "Deployment Status Summary:"
    echo ""
    echo "Data Tier (retail-data):"
    kubectl get pods -n retail-data
    echo ""
    echo "Services Tier (retail-services):"
    kubectl get pods -n retail-services
    echo ""
    echo "Frontend Tier (retail-frontend):"
    kubectl get pods -n retail-frontend
    echo ""
    echo "Services:"
    kubectl get services --all-namespaces | grep retail
}

# Main deployment function
main() {
    echo "=========================================="
    echo "Retail Store App - Namespace Deployment"
    echo "=========================================="
    
    check_prerequisites
    
    echo ""
    print_status "Starting deployment process..."
    
    # Deploy in order
    deploy_namespaces
    echo ""
    
    deploy_data_tier
    echo ""
    
    deploy_services_tier
    echo ""
    
    deploy_frontend_tier
    echo ""
    
    get_application_url
    echo ""
    
    show_status
    
    echo ""
    print_success "Deployment completed successfully!"
    print_status "Use 'kubectl get pods --all-namespaces | grep retail' to monitor all pods"
    print_status "Use './cleanup.sh' to remove the application"
}

# Run main function
main