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

### Deployment Comparison

| Feature | kubernetesv02.yaml (ALB) | Namespace-based |
|---------|---------------------------|------------------|
| **Deployment** | Single command | Multi-step |
| **Load Balancer** | Modern ALB | Classic LB |
| **Routing** | Path-based | Basic |
| **SSL** | Integrated | Manual |
| **Cost** | Lower | Higher |
| **Services** | All included | Partial |
| **Production Ready** | ✅ Yes | ⚠️ Partial |

## Prerequisites

- EKS cluster running in ap-south-1 region
- kubectl configured to connect to your cluster
- Sufficient cluster resources (minimum 2 nodes with t3.medium)

## Deployment Instructions

**⚠️ Important: Deploy in the correct order to avoid dependency issues**

### Choose Your Deployment Method

**Option A: Complete Application (All Services) - kubernetesv02.yaml**
- ✅ **Recommended for production**
- ✅ **Modern ALB implementation**
- ✅ **All microservices included**
- ✅ **Comprehensive documentation**

**Option B: Namespace-Based Deployment (Modular)**
- ✅ **Good for learning/development**
- ✅ **Step-by-step deployment**
- ✅ **Easy troubleshooting**

---

## 🚀 OPTION A: Complete Application Deployment (Recommended)

### Prerequisites for ALB Deployment
```bash
# 1. Install AWS Load Balancer Controller
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"

# 2. Add EKS Helm repository
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# 3. Install AWS Load Balancer Controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=retail-eks-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

# 4. Verify installation
kubectl get deployment -n kube-system aws-load-balancer-controller
```

### Single Command Deployment
```bash
# Deploy entire application with modern ALB
kubectl apply -f kubernetesv02.yaml

# Wait for all components to be ready (5-10 minutes)
kubectl wait --for=condition=available deployment --all --timeout=600s

# Check deployment status
kubectl get pods --all-namespaces | grep -E "catalog|carts|orders|checkout|ui"
```

### Access Your Application
```bash
# Get ALB URL (may take 2-3 minutes to provision)
kubectl get ingress retail-store-alb

# Get the ALB hostname
export ALB_URL=$(kubectl get ingress retail-store-alb -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "🌐 Application URL: http://$ALB_URL"

# Test the application
curl -I http://$ALB_URL
```

### ALB Features Available
- **Main App**: `http://your-alb-url/`
- **Catalog API**: `http://your-alb-url/api/catalog`
- **Cart API**: `http://your-alb-url/api/carts`
- **Orders API**: `http://your-alb-url/api/orders`
- **Checkout API**: `http://your-alb-url/api/checkout`
- **SSL Redirect**: Automatic HTTPS redirect (if certificate configured)
- **Health Checks**: Advanced ALB health monitoring

---

## 📚 OPTION B: Namespace-Based Deployment (Step-by-Step)

### Choose Your Deployment Method

**Option A: Complete Application (All Services) - kubernetesv02.yaml**
- ✅ **Recommended for production**
- ✅ **Modern ALB implementation**
- ✅ **All microservices included**
- ✅ **Comprehensive documentation**

**Option B: Namespace-Based Deployment (Modular)**
- ✅ **Good for learning/development**
- ✅ **Step-by-step deployment**
- ✅ **Easy troubleshooting**

---

## 🚀 OPTION A: Complete Application Deployment (Recommended)

### Prerequisites for ALB Deployment
```bash
# 1. Install AWS Load Balancer Controller
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"

# 2. Add EKS Helm repository
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# 3. Install AWS Load Balancer Controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=retail-eks-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

# 4. Verify installation
kubectl get deployment -n kube-system aws-load-balancer-controller
```

### Single Command Deployment
```bash
# Deploy entire application with modern ALB
kubectl apply -f kubernetesv02.yaml

# Wait for all components to be ready (5-10 minutes)
kubectl wait --for=condition=available deployment --all --timeout=600s

# Check deployment status
kubectl get pods --all-namespaces | grep -E "catalog|carts|orders|checkout|ui"
```

### Access Your Application
```bash
# Get ALB URL (may take 2-3 minutes to provision)
kubectl get ingress retail-store-alb

# Get the ALB hostname
export ALB_URL=$(kubectl get ingress retail-store-alb -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "🌐 Application URL: http://$ALB_URL"

# Test the application
curl -I http://$ALB_URL
```

### ALB Features Available
- **Main App**: `http://your-alb-url/`
- **Catalog API**: `http://your-alb-url/api/catalog`
- **Cart API**: `http://your-alb-url/api/carts`
- **Orders API**: `http://your-alb-url/api/orders`
- **Checkout API**: `http://your-alb-url/api/checkout`
- **SSL Redirect**: Automatic HTTPS redirect (if certificate configured)
- **Health Checks**: Advanced ALB health monitoring

---

## 📚 OPTION B: Namespace-Based Deployment (Step-by-Step)

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

## 📊 Monitoring and Observability

### Built-in Monitoring Features
```bash
# Check all application metrics
kubectl top pods --all-namespaces | grep -E "catalog|carts|orders|checkout|ui"

# View Prometheus metrics (if enabled)
kubectl port-forward svc/catalog 8080:80
curl http://localhost:8080/metrics

# Check ALB health
kubectl describe ingress retail-store-alb
```

### Application Health Checks
```bash
# Test all service health endpoints
kubectl exec -it deployment/ui -- curl http://catalog/health
kubectl exec -it deployment/ui -- curl http://carts/actuator/health/readiness
kubectl exec -it deployment/ui -- curl http://orders/actuator/health/readiness
kubectl exec -it deployment/ui -- curl http://checkout/health
```

## 🔒 Security Features

### Security Highlights in kubernetesv02.yaml
- **Non-root containers**: All services run as user ID 1000
- **Read-only filesystems**: Prevents runtime modifications
- **Dropped capabilities**: Minimal Linux capabilities
- **Security contexts**: Comprehensive security policies
- **Secret management**: Encrypted credential storage

### Network Security
```bash
# View security contexts
kubectl get pods -o jsonpath='{.items[*].spec.securityContext}'

# Check service accounts
kubectl get serviceaccounts --all-namespaces | grep -E "catalog|carts|orders|checkout|ui"
```

## 🚀 Advanced Features

### Auto-scaling Configuration
```bash
# Enable Horizontal Pod Autoscaler
kubectl autoscale deployment ui --cpu-percent=70 --min=1 --max=10
kubectl autoscale deployment catalog --cpu-percent=70 --min=1 --max=5
kubectl autoscale deployment carts --cpu-percent=70 --min=1 --max=5

# Check HPA status
kubectl get hpa
```

### SSL/TLS Configuration (Optional)
```bash
# Add SSL certificate to ALB (replace with your certificate ARN)
kubectl annotate ingress retail-store-alb \
  alb.ingress.kubernetes.io/certificate-arn=arn:aws:acm:region:account:certificate/cert-id

# Enable SSL redirect
kubectl annotate ingress retail-store-alb \
  alb.ingress.kubernetes.io/ssl-redirect='443'
```

## Cost Optimization

- Monitor resource usage with `kubectl top`
- Use Horizontal Pod Autoscaler (HPA) for dynamic scaling
- Implement Vertical Pod Autoscaler (VPA) for right-sizing
- Clean up resources after learning exercises

### Cost Comparison
| Component | Classic LB | ALB | Savings |
|-----------|------------|-----|----------|
| Load Balancer | $18/month | $16/month | 11% |
| Rules | N/A | $0.008/rule | Flexible |
| Data Processing | $0.008/GB | $0.008/GB | Same |
| **Total (typical)** | **$25/month** | **$20/month** | **20%** |