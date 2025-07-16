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
**Karpenter** is an open-source Kubernetes node lifecycle management project that automatically provisions and deprovisions nodes based on pod scheduling requirements. Unlike traditional cluster autoscalers, Karpenter:

- **Monitors unschedulable pods** due to resource constraints
- **Evaluates scheduling requirements** (resources, selectors, affinities, tolerations)
- **Provisions right-sized nodes** that meet pod requirements
- **Removes nodes** when no longer needed
- **Consolidates workloads** for cost optimization
- **Supports spot instances** with interruption handling

### Why Use Karpenter?
- **Simplified Management**: No need for dozens of node groups
- **Faster Scaling**: Provisions nodes in ~30 seconds vs minutes
- **Cost Optimization**: Up to 60% savings with spot instances
- **Flexible Instance Selection**: Uses diverse instance types automatically
- **Kubernetes Native**: Closer integration with K8s APIs than ASGs

### Prerequisites for Karpenter
```bash
# 1. Export cluster and region variables
export CLUSTER_NAME=retail-eks-cluster
export AWS_DEFAULT_REGION=ap-south-1
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
```

### Step 1: Create Karpenter IAM Resources
```bash
# 1. Create Karpenter service account with IRSA
eksctl create iamserviceaccount \
  --cluster=${CLUSTER_NAME} \
  --namespace=karpenter \
  --name=karpenter \
  --attach-policy-arn=arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy \
  --attach-policy-arn=arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy \
  --attach-policy-arn=arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly \
  --attach-policy-arn=arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore \
  --override-existing-serviceaccounts \
  --region=${AWS_DEFAULT_REGION} \
  --approve

# 2. Create EC2 instance profile for Karpenter nodes
aws iam create-role --role-name KarpenterNodeInstanceProfile --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}'

# 3. Attach policies to the role
aws iam attach-role-policy --role-name KarpenterNodeInstanceProfile --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
aws iam attach-role-policy --role-name KarpenterNodeInstanceProfile --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
aws iam attach-role-policy --role-name KarpenterNodeInstanceProfile --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
aws iam attach-role-policy --role-name KarpenterNodeInstanceProfile --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

# 4. Create instance profile
aws iam create-instance-profile --instance-profile-name KarpenterNodeInstanceProfile
aws iam add-role-to-instance-profile --instance-profile-name KarpenterNodeInstanceProfile --role-name KarpenterNodeInstanceProfile
```

### Step 2: Install Karpenter
```bash
# 1. Add Karpenter Helm repository
helm repo add karpenter https://charts.karpenter.sh/
helm repo update

# 2. Install Karpenter (available stable version)
helm install karpenter karpenter/karpenter \
  --version 0.16.3 \
  --namespace karpenter \
  --create-namespace \
  --set settings.clusterName=${CLUSTER_NAME} \
  --set serviceAccount.create=false \
  --set serviceAccount.name=karpenter \
  --set controller.resources.requests.cpu=1 \
  --set controller.resources.requests.memory=1Gi \
  --set controller.resources.limits.cpu=1 \
  --set controller.resources.limits.memory=1Gi

# 3. Verify Karpenter installation
kubectl get pods -n karpenter
kubectl logs -f -n karpenter -l app.kubernetes.io/name=karpenter
```

#### If Installation Fails ("cannot re-use a name that is still in use")
```bash
# Check existing Helm releases
helm list -n karpenter

# Option 1: Uninstall and reinstall
helm uninstall karpenter -n karpenter
sleep 10

# Then run the install command again
helm install karpenter karpenter/karpenter \
  --version 0.16.3 \
  --namespace karpenter \
  --create-namespace \
  --set settings.clusterName=${CLUSTER_NAME} \
  --set serviceAccount.create=false \
  --set serviceAccount.name=karpenter \
  --set controller.resources.requests.cpu=1 \
  --set controller.resources.requests.memory=1Gi \
  --set controller.resources.limits.cpu=1 \
  --set controller.resources.limits.memory=1Gi

# Option 2: Upgrade existing installation
helm upgrade karpenter karpenter/karpenter \
  --version 0.16.3 \
  --namespace karpenter \
  --set settings.clusterName=${CLUSTER_NAME} \
  --set serviceAccount.create=false \
  --set serviceAccount.name=karpenter \
  --set controller.resources.requests.cpu=1 \
  --set controller.resources.requests.memory=1Gi \
  --set controller.resources.limits.cpu=1 \
  --set controller.resources.limits.memory=1Gi
```

### Step 3: Create Karpenter NodePool
```bash
# Create NodePool configuration with best practices
cat <<EOF | kubectl apply -f -
apiVersion: karpenter.sh/v1alpha5
kind: Provisioner
metadata:
  name: retail-provisioner
spec:
  # Node requirements - diverse instance types for better spot availability
  requirements:
    - key: kubernetes.io/arch
      operator: In
      values: ["amd64"]
    - key: karpenter.sh/capacity-type
      operator: In
      values: ["spot", "on-demand"]
    - key: node.kubernetes.io/instance-type
      operator: In
      values: ["t3.medium", "t3.large", "t3.xlarge", "m5.large", "m5.xlarge", "c5.large", "c5.xlarge"]
    # Exclude expensive instances not needed for retail workload
    - key: node.kubernetes.io/instance-type
      operator: NotIn
      values: ["m6g.16xlarge", "r6g.16xlarge", "c6g.16xlarge"]
  # Scaling limits to control costs
  limits:
    resources:
      cpu: 1000
      memory: 1000Gi
  # Node properties
  providerRef:
    name: retail-nodepool
  # Node expiration for regular updates (best practice)
  ttlSecondsAfterEmpty: 30
  # Labels for nodes
  labels:
    karpenter.sh/provisioner: retail-provisioner
    billing-team: retail-team
  # Consolidation settings
  consolidation:
    enabled: true
EOF
```

### Step 4: Create EC2NodeClass
```bash
# First, tag your subnets and security groups for Karpenter discovery
# Get cluster VPC and subnets
VPC_ID=$(aws eks describe-cluster --name ${CLUSTER_NAME} --query 'cluster.resourcesVpcConfig.vpcId' --output text)
SUBNET_IDS=$(aws eks describe-cluster --name ${CLUSTER_NAME} --query 'cluster.resourcesVpcConfig.subnetIds' --output text)

# Tag subnets for Karpenter discovery
for subnet in $SUBNET_IDS; do
  aws ec2 create-tags --resources $subnet --tags Key=karpenter.sh/discovery,Value=${CLUSTER_NAME}
done

# Tag cluster security group
CLUSTER_SG=$(aws eks describe-cluster --name ${CLUSTER_NAME} --query 'cluster.resourcesVpcConfig.clusterSecurityGroupId' --output text)
aws ec2 create-tags --resources $CLUSTER_SG --tags Key=karpenter.sh/discovery,Value=${CLUSTER_NAME}

# Create AWSNodePool configuration
cat <<EOF | kubectl apply -f -
apiVersion: karpenter.k8s.aws/v1alpha1
kind: AWSNodePool
metadata:
  name: retail-nodepool
spec:
  # Subnet selection using discovery tags
  subnetSelector:
    karpenter.sh/discovery: ${CLUSTER_NAME}
  
  # Security group selection using discovery tags
  securityGroupSelector:
    karpenter.sh/discovery: ${CLUSTER_NAME}
  
  # Instance profile for node permissions
  instanceProfile: KarpenterNodeInstanceProfile
  
  # AMI family selection
  amiFamily: AL2
  
  # User data for node initialization
  userData: |
    #!/bin/bash
    /etc/eks/bootstrap.sh ${CLUSTER_NAME}
  
  # Tags for created instances
  tags:
    Name: Karpenter-${CLUSTER_NAME}
    Environment: Development
    ManagedBy: Karpenter
    BillingTeam: retail-team
EOF
```

### Step 5: Verify Karpenter Setup
```bash
# Check Karpenter resources
kubectl get provisioner
kubectl get awsnodepool
kubectl get nodes -l karpenter.sh/provisioner

# Check Karpenter controller logs
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter
```

### Karpenter Best Practices Applied

**✅ Cost Optimization:**
- Mixed spot/on-demand instances for cost savings
- Node consolidation when underutilized
- Automatic node expiration (24h) for updates
- Resource limits to prevent runaway costs

**✅ Availability & Performance:**
- Diverse instance types for better spot availability
- Excluded expensive instances not needed
- Fast provisioning (~30 seconds)
- Proper subnet distribution across AZs

**✅ Security & Management:**
- Dedicated IAM roles and policies
- Tagged resources for billing and management
- Latest AMI selection
- Proper node initialization

## 🧪 Load Testing Karpenter

### Test 1: CPU-Intensive Load
```bash
# Create CPU stress test deployment with proper resource requests
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
      # Node affinity to target Karpenter nodes
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: karpenter.sh/provisioner
                operator: In
                values: ["retail-provisioner"]
      containers:
      - name: cpu-stress
        image: polinux/stress
        resources:
          requests:
            cpu: 1000m      # 1 CPU core request
            memory: 512Mi   # Proper memory request
          limits:
            cpu: 1000m      # Match requests for predictable scheduling
            memory: 512Mi
        command: ["stress"]
        args: ["--cpu", "1", "--timeout", "600s"]
EOF

# Scale up to trigger node provisioning
kubectl scale deployment cpu-stress-test --replicas=8

# Watch nodes being created (should provision in ~30 seconds)
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

### Cleanup Karpenter (Complete Removal)
```bash
# 1. Delete Karpenter workloads first
kubectl delete deployment cpu-stress-test --ignore-not-found
kubectl delete deployment memory-stress-test --ignore-not-found

# 2. Delete Karpenter resources
kubectl delete provisioner retail-provisioner --ignore-not-found
kubectl delete awsnodepool retail-nodepool --ignore-not-found

# 3. Uninstall Karpenter Helm chart
helm uninstall karpenter -n karpenter

# 4. Delete Karpenter namespace
kubectl delete namespace karpenter --ignore-not-found

# 5. Delete IAM service account
eksctl delete iamserviceaccount \
  --cluster=${CLUSTER_NAME} \
  --namespace=karpenter \
  --name=karpenter \
  --region=${AWS_DEFAULT_REGION}

# 6. Remove instance profile
aws iam remove-role-from-instance-profile \
  --instance-profile-name KarpenterNodeInstanceProfile \
  --role-name KarpenterNodeInstanceProfile

aws iam delete-instance-profile \
  --instance-profile-name KarpenterNodeInstanceProfile

# 7. Detach policies from role
aws iam detach-role-policy \
  --role-name KarpenterNodeInstanceProfile \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy

aws iam detach-role-policy \
  --role-name KarpenterNodeInstanceProfile \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy

aws iam detach-role-policy \
  --role-name KarpenterNodeInstanceProfile \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly

aws iam detach-role-policy \
  --role-name KarpenterNodeInstanceProfile \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

# 8. Delete IAM role
aws iam delete-role --role-name KarpenterNodeInstanceProfile

# 9. Remove tags from subnets and security groups
VPC_ID=$(aws eks describe-cluster --name ${CLUSTER_NAME} --query 'cluster.resourcesVpcConfig.vpcId' --output text)
SUBNET_IDS=$(aws eks describe-cluster --name ${CLUSTER_NAME} --query 'cluster.resourcesVpcConfig.subnetIds' --output text)

# Remove subnet tags
for subnet in $SUBNET_IDS; do
  aws ec2 delete-tags --resources $subnet --tags Key=karpenter.sh/discovery,Value=${CLUSTER_NAME}
done

# Remove security group tags
CLUSTER_SG=$(aws eks describe-cluster --name ${CLUSTER_NAME} --query 'cluster.resourcesVpcConfig.clusterSecurityGroupId' --output text)
aws ec2 delete-tags --resources $CLUSTER_SG --tags Key=karpenter.sh/discovery,Value=${CLUSTER_NAME}

# 10. Verify cleanup
echo "Verifying Karpenter cleanup..."
kubectl get provisioner --ignore-not-found
kubectl get awsnodepool --ignore-not-found
kubectl get nodes -l karpenter.sh/provisioner --ignore-not-found
aws iam get-role --role-name KarpenterNodeInstanceProfile 2>/dev/null || echo "✅ KarpenterNodeInstanceProfile role deleted"
aws iam get-instance-profile --instance-profile-name KarpenterNodeInstanceProfile 2>/dev/null || echo "✅ KarpenterNodeInstanceProfile instance profile deleted"

echo "🎉 Karpenter cleanup completed!"
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

## 📊 Monitoring & Management Tools Setup

### Overview
Deploy comprehensive monitoring and management tools for your EKS cluster:
- **Prometheus & Grafana**: Metrics collection and visualization
- **ArgoCD**: GitOps continuous deployment
- **Kubernetes Dashboard**: Web-based cluster management UI

---

## 🔍 Prometheus & Grafana Monitoring Stack

### What is Prometheus & Grafana?
- **Prometheus**: Time-series database for metrics collection
- **Grafana**: Visualization and alerting platform
- **Benefits**: Real-time monitoring, custom dashboards, alerting

### Step 1: Install Prometheus & Grafana using Helm
```bash
# 1. Add Prometheus community Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# 2. Create monitoring namespace
kubectl create namespace monitoring

# 3. Install kube-prometheus-stack (includes Prometheus, Grafana, AlertManager)
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
  --set grafana.adminPassword=admin123 \
  --set grafana.service.type=ClusterIP \
  --set prometheus.service.type=ClusterIP

# 4. Wait for deployment
kubectl wait --for=condition=available deployment --all -n monitoring --timeout=300s
```

### Step 2: Expose Grafana via Existing ALB
```bash
# Create Ingress to expose Grafana through existing ALB
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: monitoring-ingress
  namespace: monitoring
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
spec:
  rules:
    - http:
        paths:
          - path: /grafana
            pathType: Prefix
            backend:
              service:
                name: prometheus-grafana
                port:
                  number: 80
          - path: /prometheus
            pathType: Prefix
            backend:
              service:
                name: prometheus-kube-prometheus-prometheus
                port:
                  number: 9090
EOF

# Get ALB URL (same as your retail store)
export ALB_URL=$(kubectl get ingress retail-store-alb -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "🎯 Grafana URL: http://$ALB_URL/grafana"
echo "📊 Prometheus URL: http://$ALB_URL/prometheus"
echo "👤 Username: admin"
echo "🔑 Password: admin123"
```

### Step 3: Configure Grafana for Subpath
```bash
# Update Grafana configuration to work with subpath
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --reuse-values \
  --set grafana.grafana\.ini.server.root_url="http://localhost:3000/grafana" \
  --set grafana.grafana\.ini.server.serve_from_sub_path=true

# Wait for Grafana to restart
kubectl rollout status deployment/prometheus-grafana -n monitoring
```

### Step 4: Pre-configured Dashboards
Grafana comes with pre-built dashboards:
- **Kubernetes Cluster Monitoring**
- **Node Exporter Full**
- **Kubernetes Pod Monitoring**
- **Kubernetes Deployment Monitoring**

---

## 🚀 ArgoCD GitOps Setup

### What is ArgoCD?
- **GitOps**: Declarative continuous deployment
- **Benefits**: Git-based deployments, rollbacks, multi-cluster management
- **Integration**: Works with your existing Git repositories

### Step 1: Install ArgoCD
```bash
# 1. Create ArgoCD namespace
kubectl create namespace argocd

# 2. Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 3. Wait for deployment
kubectl wait --for=condition=available deployment --all -n argocd --timeout=300s

# 4. ArgoCD server will use ClusterIP (default) for Ingress integration
```

### Step 2: Expose ArgoCD via Existing ALB
```bash
# Create Ingress to expose ArgoCD through existing ALB
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-ingress
  namespace: argocd
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
    alb.ingress.kubernetes.io/backend-protocol: HTTP
spec:
  rules:
    - http:
        paths:
          - path: /argocd
            pathType: Prefix
            backend:
              service:
                name: argocd-server
                port:
                  number: 80
EOF

# Get ALB URL and ArgoCD password
export ALB_URL=$(kubectl get ingress retail-store-alb -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
export ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "🎯 ArgoCD URL: http://$ALB_URL/argocd"
echo "👤 Username: admin"
echo "🔑 Password: $ARGOCD_PASSWORD"
```

### Step 3: Configure ArgoCD CLI (Optional)
```bash
# Install ArgoCD CLI
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

# Login to ArgoCD
argocd login $ARGOCD_URL --username admin --password $ARGOCD_PASSWORD --insecure

# Change admin password
argocd account update-password --current-password $ARGOCD_PASSWORD --new-password newpassword123
```

### Step 4: Create Sample Application
```bash
# Create application from your Git repository
cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: retail-store-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/elngovind/retail-store-sample-app.git
    targetRevision: main
    path: AppComponent
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF
```

---

## 🖥️ Kubernetes Dashboard

### What is Kubernetes Dashboard?
- **Web UI**: Browser-based cluster management
- **Benefits**: Visual cluster overview, resource management, troubleshooting
- **Features**: Pod logs, resource editing, metrics visualization

### Step 1: Install Kubernetes Dashboard
```bash
# 1. Install Kubernetes Dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# 2. Create admin service account
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

# 3. Create Ingress for Dashboard via existing ALB
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: dashboard-ingress
  namespace: kubernetes-dashboard
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS": 443}]'
    alb.ingress.kubernetes.io/backend-protocol: HTTPS
    alb.ingress.kubernetes.io/ssl-policy: ELBSecurityPolicy-TLS-1-2-2017-01
spec:
  rules:
    - http:
        paths:
          - path: /dashboard
            pathType: Prefix
            backend:
              service:
                name: kubernetes-dashboard
                port:
                  number: 443
EOF
```

### Step 2: Access Kubernetes Dashboard
```bash
# Get ALB URL and access token
export ALB_URL=$(kubectl get ingress retail-store-alb -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
export DASHBOARD_TOKEN=$(kubectl -n kubernetes-dashboard create token admin-user)
echo "🎯 Dashboard URL: https://$ALB_URL/dashboard"
echo "🔑 Access Token:"
echo $DASHBOARD_TOKEN

# Alternative: Port forward if Ingress has issues
# kubectl proxy
# Then access: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

### Step 3: Login to Dashboard
1. Open the Dashboard URL in your browser
2. Select **Token** authentication method
3. Paste the access token from above
4. Click **Sign In**

---

## 📋 Monitoring Your Retail Store Application

### Application Metrics Available
Your retail store application (kubernetesv02.yaml) includes Prometheus annotations:
```yaml
prometheus.io/path: /actuator/prometheus
prometheus.io/port: "8080"
prometheus.io/scrape: "true"
```

### Key Metrics to Monitor
```bash
# Check if metrics are being scraped
kubectl get pods -l prometheus.io/scrape=true

# View Prometheus targets
# Go to Prometheus UI -> Status -> Targets
# Look for your application endpoints
```

### Custom Grafana Dashboard for Retail Store
```bash
# Create custom dashboard JSON (save as retail-dashboard.json)
cat <<EOF > retail-dashboard.json
{
  "dashboard": {
    "title": "Retail Store Application Metrics",
    "panels": [
      {
        "title": "HTTP Requests per Second",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(http_requests_total[5m])",
            "legendFormat": "{{service}}"
          }
        ]
      },
      {
        "title": "Response Time",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))",
            "legendFormat": "95th percentile"
          }
        ]
      }
    ]
  }
}
EOF

# Import this dashboard in Grafana UI: + -> Import -> Upload JSON file
```

---

## 🔧 Management Commands

### Monitor All Services
```bash
# Check all monitoring components
kubectl get pods -n monitoring
kubectl get pods -n argocd
kubectl get pods -n kubernetes-dashboard

# Check service endpoints
kubectl get services -n monitoring
kubectl get services -n argocd
kubectl get services -n kubernetes-dashboard
```

### Troubleshooting
```bash
# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Visit: http://localhost:9090/targets

# Check Grafana datasources
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Visit: http://localhost:3000/datasources

# Check ArgoCD applications
kubectl get applications -n argocd
```

### Cleanup Commands
```bash
# Remove monitoring stack
helm uninstall prometheus -n monitoring
kubectl delete namespace monitoring

# Remove ArgoCD
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl delete namespace argocd

# Remove Kubernetes Dashboard
kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
```

---

## 🎯 Access Summary

After deployment, all tools are accessible via the **same ALB** (cost-effective!):

| Tool | URL | Username | Password |
|------|-----|----------|----------|
| **Retail Store** | `http://<alb-url>/` | - | - |
| **Grafana** | `http://<alb-url>/grafana` | admin | admin123 |
| **Prometheus** | `http://<alb-url>/prometheus` | - | - |
| **ArgoCD** | `http://<alb-url>/argocd` | admin | `<generated>` |
| **K8s Dashboard** | `https://<alb-url>/dashboard` | Token | `<generated>` |

**✅ Cost Savings**: Using 1 ALB instead of 4 LoadBalancers saves ~$54/month!

## Benefits of Modern ALB Approach

- **Cost Effective**: 20% savings over Classic Load Balancer
- **Advanced Routing**: Path-based routing for microservices
- **SSL Integration**: Seamless certificate management
- **Better Performance**: HTTP/2 and WebSocket support
- **Security**: WAF integration ready
- **Monitoring**: Enhanced health checks and metrics