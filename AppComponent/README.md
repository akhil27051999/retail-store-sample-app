# Retail Store App - Namespace-Based Deployment Guide

## Overview
This guide provides instructions for deploying the retail store application using a namespace-based approach with three-tier architecture separation.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    retail-frontend                          │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                UI Service                           │    │
│  │  - LoadBalancer Service                             │    │
│  │  - Web Interface                                    │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                   retail-services                           │
│  ┌─────────────────┐  ┌─────────────────┐                  │
│  │ Catalog Service │  │  Cart Service   │                  │
│  │ - Product API   │  │ - Shopping Cart │                  │
│  │ - ClusterIP     │  │ - ClusterIP     │                  │
│  └─────────────────┘  └─────────────────┘                  │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                     retail-data                             │
│  ┌─────────────────┐  ┌─────────────────┐                  │
│  │   MySQL DB      │  │  DynamoDB Local │                  │
│  │ - Catalog Data  │  │ - Cart Data     │                  │
│  │ - StatefulSet   │  │ - Deployment    │                  │
│  └─────────────────┘  └─────────────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

- EKS cluster running in ap-south-1 region
- kubectl configured to connect to your cluster
- Sufficient cluster resources (minimum 2 nodes with t3.medium)

## Deployment Instructions

**⚠️ Important: Deploy in the correct order to avoid dependency issues**

### Step 1: Create Namespaces

```bash
# Create the three-tier namespaces
kubectl apply -f k8s-manifests/namespaces/namespaces.yaml

# Verify namespaces
kubectl get namespaces | grep retail
```

### Step 2: Deploy Data Tier (Databases)

```bash
# Deploy databases first
kubectl apply -f k8s-manifests/data-tier/databases.yaml

# Wait for databases to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=mysql -n retail-data --timeout=300s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=dynamodb -n retail-data --timeout=300s

# Verify data tier
kubectl get pods -n retail-data
kubectl get services -n retail-data
```

### Step 3: Deploy Services Tier (Backend APIs)

**Note:** The password `gjEcijAD7OSDnHf8` matches the base64 encoded value in kubernetes.yaml

```bash
# Create required secrets first (using password from kubernetes.yaml)
kubectl create secret generic catalog-db -n retail-services \
  --from-literal=username=catalog \
  --from-literal=password=gjEcijAD7OSDnHf8

# Deploy backend services
kubectl apply -f k8s-manifests/services-tier/backend-services.yaml

# Wait for services to be ready
kubectl wait --for=condition=available deployment/catalog -n retail-services --timeout=300s
kubectl wait --for=condition=available deployment/carts -n retail-services --timeout=300s

# Verify services tier
kubectl get pods -n retail-services
kubectl get services -n retail-services
```

### Step 4: Deploy Frontend Tier (UI)

```bash
# Deploy UI service
kubectl apply -f k8s-manifests/frontend-tier/ui-service.yaml

# Wait for UI to be ready
kubectl wait --for=condition=available deployment/ui -n retail-frontend --timeout=300s

# Verify frontend tier
kubectl get pods -n retail-frontend
kubectl get services -n retail-frontend
```

### Step 5: Access the Application

```bash
# Get the LoadBalancer URL
kubectl get service ui -n retail-frontend

# If using EKS, get the external IP/hostname
export UI_URL=$(kubectl get service ui -n retail-frontend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Application URL: http://$UI_URL"
```

## Verification Commands

### Check All Deployments
```bash
# Overview of all resources
kubectl get all -n retail-data
kubectl get all -n retail-services  
kubectl get all -n retail-frontend

# Check pod status across all namespaces
kubectl get pods --all-namespaces | grep retail
```

### Test Service Connectivity
```bash
# Test catalog service
kubectl exec -n retail-services deployment/catalog -- curl -s http://localhost:8080/health

# Test cart service
kubectl exec -n retail-services deployment/carts -- curl -s http://localhost:8080/health

# Test cross-namespace connectivity
kubectl exec -n retail-services deployment/catalog -- nslookup catalog-mysql.retail-data
```

### View Logs
```bash
# View application logs
kubectl logs -n retail-services deployment/catalog
kubectl logs -n retail-services deployment/carts
kubectl logs -n retail-frontend deployment/ui

# Follow logs in real-time
kubectl logs -f -n retail-frontend deployment/ui
```

## Troubleshooting

### Common Issues

1. **CreateContainerConfigError (Missing Secrets)**
   ```bash
   # Check if catalog-db secret exists
   kubectl get secrets -n retail-services
   
   # Create missing catalog-db secret (using password from kubernetes.yaml)
   kubectl create secret generic catalog-db -n retail-services \
     --from-literal=username=catalog \
     --from-literal=password=gjEcijAD7OSDnHf8
   
   # Restart the deployment
   kubectl rollout restart deployment/catalog -n retail-services
   ```

2. **CrashLoopBackOff (Application Crashes)**
   ```bash
   # Check application logs
   kubectl logs <pod-name> -n retail-services
   
   # Check if data tier is running
   kubectl get pods -n retail-data
   
   # Ensure databases are deployed first
   kubectl apply -f k8s-manifests/data-tier/databases.yaml
   ```

3. **Pods stuck in Pending state**
   ```bash
   kubectl describe pod <pod-name> -n <namespace>
   # Check for resource constraints or node selector issues
   ```

4. **Service connectivity issues**
   ```bash
   # Check service endpoints
   kubectl get endpoints -n retail-services
   
   # Test DNS resolution
   kubectl run test-pod --image=busybox -it --rm -- nslookup catalog.retail-services
   ```

5. **Database connection failures**
   ```bash
   # Check database pods
   kubectl logs -n retail-data statefulset/catalog-mysql
   kubectl logs -n retail-data deployment/carts-dynamodb
   ```

### Resource Monitoring
```bash
# Check resource usage
kubectl top pods -n retail-data
kubectl top pods -n retail-services
kubectl top pods -n retail-frontend

# Check node resources
kubectl top nodes
```

## Cleanup

### Remove Application
```bash
# Remove in reverse order
kubectl delete -f k8s-manifests/frontend-tier/ui-service.yaml
kubectl delete -f k8s-manifests/services-tier/backend-services.yaml
kubectl delete -f k8s-manifests/data-tier/databases.yaml

# Remove namespaces (this will delete all resources)
kubectl delete -f k8s-manifests/namespaces/namespaces.yaml
```

### Verify Cleanup
```bash
kubectl get namespaces | grep retail
kubectl get pods --all-namespaces | grep retail
```

## Benefits of Namespace-Based Approach

- **Isolation**: Clear separation between tiers
- **Security**: Network policies can be applied per namespace
- **Resource Management**: Resource quotas per tier
- **RBAC**: Role-based access control per namespace
- **Monitoring**: Easier to monitor and alert per tier
- **Scaling**: Independent scaling of each tier

## Next Steps

1. **Add Network Policies**: Implement network segmentation
2. **Resource Quotas**: Set limits per namespace
3. **Monitoring**: Deploy Prometheus/Grafana per namespace
4. **RBAC**: Configure role-based access
5. **Ingress**: Replace LoadBalancer with Ingress controller

## Cost Optimization

- Monitor resource usage with `kubectl top`
- Use Horizontal Pod Autoscaler (HPA) for dynamic scaling
- Implement Vertical Pod Autoscaler (VPA) for right-sizing
- Clean up resources after learning exercises

## Observability Tier (Optional)

### Deploy Observability Stack with Single ALB

This optional step deploys Prometheus, Grafana, ArgoCD, and Kubernetes Dashboard behind a single Application Load Balancer (ALB) for centralized observability.

**Prerequisites:**
- AWS Load Balancer Controller installed in your EKS cluster
- Proper IAM permissions for ALB creation

```bash
# Deploy observability stack
kubectl apply -f k8s-manifests/observability-tier/observability-alb.yaml

# Wait for deployments to be ready
kubectl wait --for=condition=available deployment/prometheus -n retail-observability --timeout=300s
kubectl wait --for=condition=available deployment/grafana -n retail-observability --timeout=300s
kubectl wait --for=condition=available deployment/argocd-server -n retail-observability --timeout=300s
kubectl wait --for=condition=available deployment/kubernetes-dashboard -n retail-observability --timeout=300s

# Get ALB URL
kubectl get ingress observability-alb -n retail-observability
```

### Access Observability Tools

Once deployed, access the tools via the ALB URL:

```bash
# Get the ALB hostname
export OBS_URL=$(kubectl get ingress observability-alb -n retail-observability -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "Prometheus: http://$OBS_URL/prometheus"
echo "Grafana: http://$OBS_URL/grafana (admin/admin123)"
echo "ArgoCD: http://$OBS_URL/argocd"
echo "Kubernetes Dashboard: http://$OBS_URL/dashboard"
```

### Observability Features

- **Prometheus**: Metrics collection and monitoring
- **Grafana**: Visualization dashboards (default login: admin/admin123)
- **ArgoCD**: GitOps continuous deployment
- **Kubernetes Dashboard**: Cluster management UI

### Cleanup Observability Stack

```bash
# Remove observability stack
kubectl delete -f k8s-manifests/observability-tier/observability-alb.yaml
```