# Retail Store App - Complete Deployment Guide

## Overview
This guide provides instructions for deploying the retail store application with modern Application Load Balancer (ALB) implementation.

## Architecture

### Modern ALB Architecture (kubernetesv02.yaml)
```
┌───────────────────────────────────────────────────────────────┐
│                    🌐 Application Load Balancer (ALB)                    │
│  • Path-based routing: /, /api/catalog, /api/carts, /api/orders    │
│  • SSL termination • Health checks • WAF integration ready        │
└───────────────────────────────────────────────────────────────┘
                              │
┌───────────────────────────────────────────────────────────────┐
│                        📱 Frontend Layer                        │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    UI Service                     │    │
│  │  • React/Angular Frontend • ClusterIP Service      │    │
│  └─────────────────────────────────────────────────────────┘    │
└───────────────────────────────────────────────────────────────┘
                              │
┌───────────────────────────────────────────────────────────────┐
│                      ⚙️ Microservices Layer                      │
│ ┌────────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐ │
│ │  Catalog   │ │   Carts   │ │  Orders   │ │ Checkout  │ │
│ │ (Go Lang) │ │  (Java)   │ │  (Java)   │ │ (Node.js) │ │
│ └────────────┘ └───────────┘ └───────────┘ └───────────┘ │
└───────────────────────────────────────────────────────────────┘
                              │
┌───────────────────────────────────────────────────────────────┐
│                        💾 Data Layer                         │
│ ┌────────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐ │
│ │   MySQL   │ │ DynamoDB  │ │PostgreSQL│ │   Redis   │ │
│ │ (Catalog) │ │  (Carts)  │ │ (Orders)  │ │(Checkout)│ │
│ └────────────┘ └───────────┘ └───────────┘ └───────────┘ │
│                     + RabbitMQ (Message Queue)                     │
└───────────────────────────────────────────────────────────────┘
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

#### Step 1: Configure IAM for AWS Load Balancer Controller
```bash
# 1. Download IAM policy (latest version v2.13.0)
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.13.0/docs/install/iam_policy.json

# 2. Create IAM policy
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

# 3. Get AWS Account ID automatically
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS Account ID: $AWS_ACCOUNT_ID"

# 4. Create IAM OIDC provider for the cluster
eksctl utils associate-iam-oidc-provider --region=ap-south-1 --cluster=retail-eks-cluster --approve

# 5. Create IAM service account
eksctl create iamserviceaccount \
    --cluster=retail-eks-cluster \
    --namespace=kube-system \
    --name=aws-load-balancer-controller \
    --attach-policy-arn=arn:aws:iam::${AWS_ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy \
    --override-existing-serviceaccounts \
    --region ap-south-1 \
    --approve
```

#### Step 2: Install AWS Load Balancer Controller
```bash
# 1. Add EKS Helm repository
helm repo add eks https://aws.github.io/eks-charts
helm repo update eks

# 2. Install AWS Load Balancer Controller (latest version 1.13.0)
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=retail-eks-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --version 1.13.0

# 3. Verify installation
kubectl get deployment -n kube-system aws-load-balancer-controller
```

#### Expected Output:
```
NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
aws-load-balancer-controller   2/2     2            2           84s
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

### If SSL Certificate Error Occurs
If you encounter SSL certificate errors during ALB creation, follow these steps:

```bash
# 1. Pull the latest updates (HTTP-only configuration)
git pull origin main

# 2. Delete the current deployment
kubectl delete -f kubernetesv02.yaml

# 3. Wait for all resources to be deleted (30-60 seconds)
kubectl get pods --all-namespaces | grep -E "catalog|carts|orders|checkout|ui"

# 4. Redeploy with updated manifest
kubectl apply -f kubernetesv02.yaml

# 5. Monitor deployment
kubectl get pods --watch
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

3. **ALB Controller Issues**
   ```bash
   # Check ALB controller status
   kubectl get deployment -n kube-system aws-load-balancer-controller
   
   # Check ALB controller logs
   kubectl logs -n kube-system deployment/aws-load-balancer-controller
   
   # Verify IAM service account
   kubectl describe serviceaccount aws-load-balancer-controller -n kube-system
   ```

4. **SSL Certificate Error (ValidationError: A certificate must be specified)**
   ```bash
   # Check Ingress events for SSL errors
   kubectl describe ingress retail-store-alb
   
   # If SSL certificate errors occur, redeploy with HTTP-only:
   git pull origin main
   kubectl delete -f kubernetesv02.yaml
   kubectl apply -f kubernetesv02.yaml
   ```

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

### Cost Comparison
| Component | Classic LB | ALB | Savings |
|-----------|------------|-----|----------|
| Load Balancer | $18/month | $16/month | 11% |
| Rules | N/A | $0.008/rule | Flexible |
| Data Processing | $0.008/GB | $0.008/GB | Same |
| **Total (typical)** | **$25/month** | **$20/month** | **20%** |

## Cleanup

### Remove Application
```bash
# Remove ALB deployment
kubectl delete -f kubernetesv02.yaml

# Or remove namespace-based deployment
kubectl delete -f k8s-manifests/frontend-tier/ui-service.yaml
kubectl delete -f k8s-manifests/services-tier/backend-services.yaml
kubectl delete -f k8s-manifests/data-tier/databases.yaml
kubectl delete -f k8s-manifests/namespaces/namespaces.yaml
```

## 🚀 Karpenter Auto-Scaling Setup

### What is Karpenter?
**Karpenter** is a Kubernetes cluster autoscaler that automatically provisions right-sized compute resources in response to changing application load. Unlike traditional cluster autoscalers, Karpenter:

- **Provisions nodes in seconds** (not minutes)
- **Right-sizes instances** based on actual pod requirements
- **Supports mixed instance types** and spot instances
- **Reduces costs** by up to 60% with intelligent instance selection
- **Eliminates node groups** - provisions nodes directly

### Prerequisites for Karpenter
```bash
# 1. Export cluster and region variables
export CLUSTER_NAME=retail-eks-cluster
export AWS_DEFAULT_REGION=ap-south-1
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
```

### Step 1: Install Karpenter
```bash
# 1. Create Karpenter namespace
kubectl create namespace karpenter

# 2. Add Karpenter Helm repository
helm repo add karpenter https://charts.karpenter.sh/
helm repo update

# 3. Install Karpenter
helm install karpenter karpenter/karpenter \
  --version 1.0.7 \
  --namespace karpenter \
  --create-namespace \
  --set settings.clusterName=${CLUSTER_NAME} \
  --set settings.interruptionQueue=${CLUSTER_NAME} \
  --set controller.resources.requests.cpu=1 \
  --set controller.resources.requests.memory=1Gi \
  --set controller.resources.limits.cpu=1 \
  --set controller.resources.limits.memory=1Gi

# 4. Verify Karpenter installation
kubectl get pods -n karpenter
kubectl logs -f -n karpenter -l app.kubernetes.io/name=karpenter
```

### Step 2: Create Karpenter NodePool
```bash
# Create NodePool configuration
cat <<EOF | kubectl apply -f -
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: retail-nodepool
spec:
  # Template for nodes
  template:
    metadata:
      labels:
        karpenter.sh/nodepool: retail-nodepool
    spec:
      # Node requirements
      requirements:
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot", "on-demand"]
        - key: node.kubernetes.io/instance-type
          operator: In
          values: ["t3.medium", "t3.large", "t3.xlarge", "m5.large", "m5.xlarge"]
      # Node properties
      nodeClassRef:
        apiVersion: karpenter.k8s.aws/v1beta1
        kind: EC2NodeClass
        name: retail-nodeclass
      # Taints for workload isolation (optional)
      taints:
        - key: karpenter.sh/nodepool
          value: retail-nodepool
          effect: NoSchedule
  # Scaling limits
  limits:
    cpu: 1000
    memory: 1000Gi
  # Disruption settings
  disruption:
    consolidationPolicy: WhenEmpty
    consolidateAfter: 30s
    expireAfter: 2m
EOF
```

### Step 3: Create EC2NodeClass
```bash
# Create EC2NodeClass configuration
cat <<EOF | kubectl apply -f -
apiVersion: karpenter.k8s.aws/v1beta1
kind: EC2NodeClass
metadata:
  name: retail-nodeclass
spec:
  # AMI selection
  amiFamily: AL2
  
  # Subnet selection (use your EKS cluster subnets)
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: ${CLUSTER_NAME}
  
  # Security group selection
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: ${CLUSTER_NAME}
  
  # Instance profile
  role: KarpenterNodeInstanceProfile
  
  # User data for node initialization
  userData: |
    #!/bin/bash
    /etc/eks/bootstrap.sh ${CLUSTER_NAME}
    
  # Instance store policy
  instanceStorePolicy: RAID0
  
  # Tags for created instances
  tags:
    Name: Karpenter-${CLUSTER_NAME}
    Environment: Development
    ManagedBy: Karpenter
EOF
```

### Step 4: Verify Karpenter Setup
```bash
# Check Karpenter resources
kubectl get nodepool
kubectl get ec2nodeclass
kubectl get nodes -l karpenter.sh/nodepool
```

## 🧪 Load Testing Karpenter

### Test 1: CPU-Intensive Load
```bash
# Create CPU stress test deployment
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cpu-stress-test
spec:
  replicas: 0  # Start with 0, scale up manually
  selector:
    matchLabels:
      app: cpu-stress
  template:
    metadata:
      labels:
        app: cpu-stress
    spec:
      tolerations:
        - key: karpenter.sh/nodepool
          operator: Equal
          value: retail-nodepool
          effect: NoSchedule
      containers:
      - name: cpu-stress
        image: polinux/stress
        resources:
          requests:
            cpu: 500m
            memory: 256Mi
          limits:
            cpu: 1000m
            memory: 512Mi
        command: ["stress"]
        args: ["--cpu", "1", "--timeout", "300s"]
EOF

# Scale up to trigger node provisioning
kubectl scale deployment cpu-stress-test --replicas=10

# Watch nodes being created
kubectl get nodes --watch

# Monitor Karpenter logs
kubectl logs -f -n karpenter -l app.kubernetes.io/name=karpenter
```

### Test 2: Memory-Intensive Load
```bash
# Create memory stress test
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: memory-stress-test
spec:
  replicas: 5
  selector:
    matchLabels:
      app: memory-stress
  template:
    metadata:
      labels:
        app: memory-stress
    spec:
      tolerations:
        - key: karpenter.sh/nodepool
          operator: Equal
          value: retail-nodepool
          effect: NoSchedule
      containers:
      - name: memory-stress
        image: polinux/stress
        resources:
          requests:
            memory: 1Gi
          limits:
            memory: 2Gi
        command: ["stress"]
        args: ["--vm", "1", "--vm-bytes", "1G", "--timeout", "300s"]
EOF
```

### Test 3: Scale Retail Application
```bash
# Scale retail application components to test Karpenter
kubectl scale deployment ui --replicas=5
kubectl scale deployment catalog --replicas=3
kubectl scale deployment carts --replicas=3
kubectl scale deployment orders --replicas=3
kubectl scale deployment checkout --replicas=3

# Watch pod scheduling and node provisioning
kubectl get pods -o wide --watch
```

### Monitoring Karpenter Performance
```bash
# Check node provisioning
kubectl get nodes -l karpenter.sh/nodepool --show-labels

# Check Karpenter metrics
kubectl top nodes
kubectl top pods

# View Karpenter events
kubectl get events --sort-by='.lastTimestamp' | grep -i karpenter

# Check node costs (if cost monitoring enabled)
kubectl describe nodes -l karpenter.sh/nodepool
```

### Cleanup Load Tests
```bash
# Scale down test deployments
kubectl scale deployment cpu-stress-test --replicas=0
kubectl delete deployment memory-stress-test

# Scale down retail application
kubectl scale deployment ui --replicas=1
kubectl scale deployment catalog --replicas=1
kubectl scale deployment carts --replicas=1
kubectl scale deployment orders --replicas=1
kubectl scale deployment checkout --replicas=1

# Karpenter will automatically terminate unused nodes
```

### Karpenter Cost Optimization Features

**Spot Instance Support:**
- Automatically uses spot instances when available
- Falls back to on-demand if spot unavailable
- Can save up to 90% on compute costs

**Right-Sizing:**
- Provisions exact instance types needed
- Considers CPU, memory, and storage requirements
- Avoids over-provisioning

**Fast Scaling:**
- Provisions nodes in ~30 seconds
- Terminates unused nodes quickly
- Reduces idle resource costs

## Benefits of Modern ALB Approach

- **Cost Effective**: 20% savings over Classic Load Balancer
- **Advanced Routing**: Path-based routing for microservices
- **SSL Integration**: Seamless certificate management
- **Better Performance**: HTTP/2 and WebSocket support
- **Security**: WAF integration ready
- **Monitoring**: Enhanced health checks and metrics