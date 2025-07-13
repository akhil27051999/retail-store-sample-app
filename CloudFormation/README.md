# CloudFormation Templates for Retail Store Infrastructure

## Overview
This directory contains CloudFormation templates to deploy a complete AWS infrastructure for the retail store application, including VPC networking and EKS management server.

## Templates Included

### 1. VPC Infrastructure (`vpc-template.yaml`)
Multi-tier VPC architecture with proper network segmentation

### 2. EKS Management Server (`ec2-instance-template.yaml`)
EC2 instance configured for EKS cluster management

---

## VPC Infrastructure Template

### Architecture Details
- **CIDR Block**: 192.168.0.0/16 (default)
- **DNS Support**: Enabled
- **6 Subnets across 2 AZs**:

| Tier | Subnet Name | CIDR Block | Availability Zone | Type |
|------|-------------|------------|-------------------|------|
| Web  | Web-Subnet-1 | 192.168.1.0/24 | AZ-1 | Public |
| Web  | Web-Subnet-2 | 192.168.2.0/24 | AZ-2 | Public |
| App  | App-Subnet-1 | 192.168.3.0/24 | AZ-1 | Private |
| App  | App-Subnet-2 | 192.168.4.0/24 | AZ-2 | Private |
| Data | Data-Subnet-1 | 192.168.5.0/24 | AZ-1 | Private |
| Data | Data-Subnet-2 | 192.168.6.0/24 | AZ-2 | Private |

### Network Components
- **Internet Gateway**: Public subnet internet access
- **NAT Gateway**: Located in Web-Subnet-1 for private subnet outbound access
- **Route Tables**:
  - Public: Web subnets → Internet Gateway
  - Private: App subnets → NAT Gateway
  - Data: Data subnets → Local only (isolated)

### VPC Parameters
| Parameter | Default Value | Description |
|-----------|---------------|-------------|
| VpcCidr | 192.168.0.0/16 | CIDR block for VPC |
| WebSubnet1Cidr | 192.168.1.0/24 | Web Subnet 1 CIDR |
| WebSubnet2Cidr | 192.168.2.0/24 | Web Subnet 2 CIDR |
| AppSubnet1Cidr | 192.168.3.0/24 | App Subnet 1 CIDR |
| AppSubnet2Cidr | 192.168.4.0/24 | App Subnet 2 CIDR |
| DataSubnet1Cidr | 192.168.5.0/24 | Data Subnet 1 CIDR |
| DataSubnet2Cidr | 192.168.6.0/24 | Data Subnet 2 CIDR |

---

## EKS Management Server Template

### Server Features
- **EC2 Instance** configured as EKS management server
- **IAM Role** with comprehensive EKS and AWS permissions
- **SSM Access** for secure shell access
- **Elastic IP** automatically assigned
- **30GB encrypted EBS volume** (gp3 type)
- **Pre-installed Tools**: AWS CLI v2, kubectl, eksctl, Helm

### Instance Specifications
- **AMI ID**: ami-0f918f7e67a3323f0 (Ubuntu 24.04)
- **Instance Types**: t3a.small, t3a.medium
- **Storage**: 30GB gp3 EBS volume (encrypted)
- **Network**: Elastic IP assigned
- **OS**: Ubuntu 24.04 LTS

### EKS Management Parameters
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| InstanceType | Dropdown | t3a.small | t3a.small or t3a.medium |
| SubnetId | Subnet Selection | - | Target subnet for deployment |
| VPCId | VPC Selection | - | VPC for security group |
| KeyPairName | Key Pair | - | EC2 Key Pair for SSH |
| InstanceName | String | RetailStore-EC2 | Instance name tag |

### Security Group Rules
| Protocol | Port | Source | Description |
|----------|------|--------|-------------|
| TCP | 22 | 0.0.0.0/0 | SSH access |
| TCP | 80 | 0.0.0.0/0 | HTTP access |
| TCP | 443 | 0.0.0.0/0 | HTTPS access |

---

## Deployment Instructions

### Prerequisites
- AWS Account with appropriate IAM permissions
- Access to AWS Console
- S3 bucket for template storage

### Step 1: Deploy VPC Infrastructure

#### Console Deployment:
1. **Upload to S3**: Upload `vpc-template.yaml` to S3 bucket
2. **CloudFormation Console**:
   - Create stack → Template from S3 URL
   - Stack name: `retail-vpc`
   - Review/modify CIDR parameters if needed
   - Deploy stack

#### CLI Deployment:
```bash
aws cloudformation create-stack \
  --stack-name retail-vpc \
  --template-body file://vpc-template.yaml
```

### Step 2: Deploy EKS Management Server

#### Console Deployment:
1. **Upload to S3**: Upload `ec2-instance-template.yaml` to S3 bucket
2. **CloudFormation Console**:
   - Create stack → Template from S3 URL
   - Stack name: `retail-eks-management`
   - **Configure Parameters**:
     - Instance Type: Select from dropdown
     - Subnet ID: Choose from VPC subnets (recommend App subnet)
     - VPC ID: Select the VPC created in Step 1
     - Key Pair: Select existing key pair
   - Deploy stack

#### CLI Deployment:
```bash
aws cloudformation create-stack \
  --stack-name retail-eks-management \
  --template-body file://ec2-instance-template.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters \
    ParameterKey=InstanceType,ParameterValue=t3a.small \
    ParameterKey=SubnetId,ParameterValue=subnet-xxxxxxxxx \
    ParameterKey=VPCId,ParameterValue=vpc-xxxxxxxxx \
    ParameterKey=KeyPairName,ParameterValue=your-key-pair
```

---

## Post-Deployment Usage

### Access EKS Management Server

#### Method 1: SSM Session Manager (Recommended)
```bash
# Via AWS CLI
aws ssm start-session --target <INSTANCE_ID>

# Via AWS Console: EC2 → Instance → Connect → Session Manager
```

#### Method 2: SSH Access
```bash
ssh -i your-key.pem ubuntu@<ELASTIC_IP>
```

### Manual kubectl Installation (Ubuntu 24.04)

If you need to manually install kubectl on Ubuntu 24.04:

```bash
# Check if kubectl is already installed
kubectl version --client

# Download kubectl binary (Kubernetes 1.31)
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.31.7/2025-04-17/bin/linux/amd64/kubectl

# (Optional) Verify checksum
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.31.7/2025-04-17/bin/linux/amd64/kubectl.sha256
sha256sum -c kubectl.sha256

# Make executable and install
chmod +x ./kubectl
mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl
sudo cp ./kubectl /usr/local/bin/kubectl

# Add to PATH
echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# Verify installation
kubectl version --client
```

### Create EKS Cluster
```bash
# Verify tools installation
aws --version && kubectl version --client && eksctl version

# Create EKS cluster in the VPC
eksctl create cluster \
  --name retail-eks-cluster \
  --version 1.31 \
  --region us-west-2 \
  --vpc-private-subnets=subnet-app1,subnet-app2 \
  --vpc-public-subnets=subnet-web1,subnet-web2 \
  --nodegroup-name retail-nodes \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 4

# Configure kubectl
aws eks update-kubeconfig --region us-west-2 --name retail-eks-cluster
kubectl get nodes
```

---

## Stack Outputs

### VPC Template Outputs
- VPC ID and all subnet IDs (exportable for cross-stack references)

### EKS Management Server Outputs
- Instance ID, Elastic IP, DNS names
- IAM Role ARN and Instance Profile ARN
- Security Group ID

---

## Security Considerations

### Network Security
- **Web subnets**: Direct internet access via Internet Gateway
- **App subnets**: Outbound internet via NAT Gateway
- **Data subnets**: Completely isolated (local routes only)

### EKS Management Security
- **Encrypted Storage**: EBS volume encrypted at rest
- **IAM Role**: Principle of least privilege with EKS-specific permissions
- **SSM Access**: Secure shell access without exposing SSH keys
- **VPC Deployment**: Deploy in private subnet for enhanced security

### IAM Permissions Included
- EKS Cluster Management, Worker Node Management
- EC2 and Auto Scaling permissions
- IAM role creation and management
- SSM and CloudFormation access

---

## Architecture Diagram
```
Internet Gateway
       |
   Web Subnets (Public)
       |
   NAT Gateway
       |
   App Subnets (Private) ← EKS Management Server
       |
   Data Subnets (Isolated)
```

This infrastructure provides a secure, scalable foundation for deploying the retail store application on EKS with proper network segmentation and management capabilities.