# Observability Stack for EKS 1.31

This document provides instructions for deploying a comprehensive observability stack on Amazon EKS 1.31, including Jenkins, Kubernetes Dashboard, Grafana, Prometheus, and ArgoCD behind a single Application Load Balancer (ALB).

## Prerequisites

1. **EKS Cluster 1.31** running in AWS
2. **AWS Load Balancer Controller** installed
3. **kubectl** configured to access your cluster
4. **Domain names** configured in Route 53 or your DNS provider

## Components Included

| Component | Version | Port | Purpose |
|-----------|---------|------|---------|
| Prometheus | v2.48.0 | 9090 | Metrics collection and monitoring |
| Grafana | 10.2.0 | 3000 | Metrics visualization and dashboards |
| Jenkins | 2.426.1-lts | 8080 | CI/CD pipeline automation |
| ArgoCD | v2.9.3 | 8080 | GitOps continuous deployment |
| Kubernetes Dashboard | v2.7.0 | 9090 | Cluster management interface |

## Installation Steps

### 1. Install AWS Load Balancer Controller

```bash
# Create IAM role for AWS Load Balancer Controller
eksctl create iamserviceaccount \
  --cluster=your-cluster-name \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name=AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess \
  --approve

# Install AWS Load Balancer Controller
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=your-cluster-name \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

### 2. Deploy Observability Stack

```bash
# Apply the observability manifest
kubectl apply -f observability.yaml

# Verify deployment
kubectl get pods -n observability
kubectl get svc -n observability
kubectl get ingress -n observability
```

### 3. Configure DNS

Update your DNS records to point to the ALB:

```bash
# Get ALB DNS name
kubectl get ingress observability-ingress -n observability -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Create CNAME records:
- `prometheus.example.com` → ALB DNS name
- `grafana.example.com` → ALB DNS name
- `jenkins.example.com` → ALB DNS name
- `argocd.example.com` → ALB DNS name
- `dashboard.example.com` → ALB DNS name

## Access Information

### Grafana
- **URL**: http://grafana.example.com
- **Username**: admin
- **Password**: admin123

### Jenkins
- **URL**: http://jenkins.example.com
- **Initial Setup**: Disabled (ready to use)

### ArgoCD
- **URL**: http://argocd.example.com
- **Username**: admin
- **Password**: Get with `kubectl -n observability get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

### Kubernetes Dashboard
- **URL**: http://dashboard.example.com
- **Authentication**: Cluster admin token

### Prometheus
- **URL**: http://prometheus.example.com
- **No authentication required**

## Configuration

### Prometheus Configuration
The Prometheus configuration includes:
- Kubernetes pod discovery
- 15-second scrape interval
- Automatic service discovery

### Grafana Dashboards
Import popular dashboards:
1. Kubernetes Cluster Monitoring (ID: 315)
2. Node Exporter Full (ID: 1860)
3. Kubernetes Pod Monitoring (ID: 6417)

### Jenkins Plugins
Recommended plugins to install:
- Kubernetes Plugin
- Pipeline Plugin
- Git Plugin
- Docker Pipeline Plugin

### ArgoCD Applications
Connect to your Git repositories for GitOps workflows.

## Security Considerations

⚠️ **Important**: This configuration is for development/testing purposes only.

For production use:
1. Enable HTTPS with SSL certificates
2. Configure proper authentication and RBAC
3. Use secrets management for passwords
4. Enable network policies
5. Configure backup strategies

## Troubleshooting

### Common Issues

1. **ALB not created**
   ```bash
   # Check AWS Load Balancer Controller logs
   kubectl logs -n kube-system deployment/aws-load-balancer-controller
   ```

2. **Pods not starting**
   ```bash
   # Check pod status and logs
   kubectl describe pod <pod-name> -n observability
   kubectl logs <pod-name> -n observability
   ```

3. **Ingress not working**
   ```bash
   # Verify ingress configuration
   kubectl describe ingress observability-ingress -n observability
   ```

### Health Checks

```bash
# Check all components
kubectl get all -n observability

# Check ingress status
kubectl get ingress -n observability

# Test connectivity
curl -I http://prometheus.example.com
curl -I http://grafana.example.com
```

## Cleanup

To remove the observability stack:

```bash
kubectl delete -f observability.yaml
kubectl delete namespace observability
```

## Monitoring and Alerts

### Prometheus Targets
Monitor these key metrics:
- Cluster resource usage
- Pod health and status
- Application performance
- Infrastructure metrics

### Grafana Alerts
Configure alerts for:
- High CPU/Memory usage
- Pod restart loops
- Service unavailability
- Storage capacity

## Support

For issues related to:
- **EKS**: AWS Support or EKS documentation
- **Individual tools**: Refer to respective project documentation
- **This setup**: Create an issue in this repository

---

**Note**: Replace `example.com` with your actual domain name and update the AWS account ID in the service account annotation.