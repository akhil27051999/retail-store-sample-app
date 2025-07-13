# EKS Management Server CloudFormation Template

## Overview
This CloudFormation template creates an EC2 instance configured as an EKS management server with all necessary tools and IAM permissions to create and manage EKS clusters and worker nodes.

## Template Features
- **EC2 Instance** configured as EKS management server
- **IAM Role** with comprehensive EKS and AWS permissions
- **SSM Access** for secure shell access without SSH keys
- **Elastic IP** automatically assigned
- **30GB encrypted EBS volume** (gp3 type)
- **Security Group** with SSH, HTTP, and HTTPS access
- **Pre-installed Tools**: AWS CLI v2, kubectl, eksctl, Helm
- **User Data** script for EKS tools installation

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| InstanceType | Dropdown | t3a.small | Choose between t3a.small or t3a.medium |
| SubnetId | Subnet Selection | - | Select subnet for EC2 deployment |
| VPCId | VPC Selection | - | Select VPC for security group |
| KeyPairName | Key Pair | - | Select existing EC2 Key Pair for SSH |
| InstanceName | String | RetailStore-EC2 | Name tag for the instance |

## Instance Specifications
- **AMI ID**: ami-0f918f7e67a3323f0 (Amazon Linux 2)
- **Instance Types**: t3a.small, t3a.medium
- **Storage**: 30GB gp3 EBS volume (encrypted)
- **Network**: Elastic IP assigned
- **IAM Role**: EKS management permissions
- **Tools**: AWS CLI, kubectl, eksctl, Helm pre-installed

## Security Group Rules
| Protocol | Port | Source | Description |
|----------|------|--------|-------------|
| TCP | 22 | 0.0.0.0/0 | SSH access |
| TCP | 80 | 0.0.0.0/0 | HTTP access |
| TCP | 443 | 0.0.0.0/0 | HTTPS access |

## Deployment Instructions

### Method 1: AWS Console Deployment

#### Step 1: Upload Template to S3
1. Go to **S3 Console**
2. Upload `ec2-instance-template.yaml` to your bucket
3. Copy the S3 Object URL

#### Step 2: Deploy via CloudFormation Console
1. Go to **CloudFormation Console**
2. Click **Create stack** → **With new resources**
3. Select **Template is ready** and **Amazon S3 URL**
4. Paste the S3 URL and click **Next**
5. **Configure Parameters**:
   - Stack name: `retail-ec2-instance`
   - Instance Type: Select from dropdown
   - Subnet ID: Choose target subnet
   - VPC ID: Select corresponding VPC
   - Key Pair: Select existing key pair
   - Instance Name: Customize if needed
6. Click **Next** → **Next** → **Create stack**

### Method 2: AWS CLI Deployment
```bash
aws cloudformation create-stack \
  --stack-name retail-ec2-instance \
  --template-body file://ec2-instance-template.yaml \
  --parameters \
    ParameterKey=InstanceType,ParameterValue=t3a.small \
    ParameterKey=SubnetId,ParameterValue=subnet-xxxxxxxxx \
    ParameterKey=VPCId,ParameterValue=vpc-xxxxxxxxx \
    ParameterKey=KeyPairName,ParameterValue=your-key-pair
```

## Stack Outputs
- **Instance ID**: EC2 instance identifier
- **Elastic IP**: Public IP address for external access
- **Public DNS**: Public DNS name
- **Private IP**: Private IP address
- **Security Group ID**: Security group identifier
- **IAM Role ARN**: EKS management role ARN
- **Instance Profile ARN**: Instance profile ARN

## Access Methods

### Method 1: SSM Session Manager (Recommended)
```bash
# Connect via AWS CLI
aws ssm start-session --target <INSTANCE_ID>

# Or use AWS Console
# Go to EC2 Console → Select Instance → Connect → Session Manager
```

### Method 2: SSH Access
```bash
ssh -i your-key.pem ec2-user@<ELASTIC_IP>
```

## Post-Deployment Setup

1. **Verify Installation**:
   ```bash
   # Check installed tools
   aws --version
   kubectl version --client
   eksctl version
   helm version
   ```

2. **Create EKS Cluster**:
   ```bash
   # Example EKS cluster creation
   eksctl create cluster \
     --name retail-eks-cluster \
     --version 1.28 \
     --region us-west-2 \
     --nodegroup-name retail-nodes \
     --node-type t3.medium \
     --nodes 2 \
     --nodes-min 1 \
     --nodes-max 4
   ```

3. **Configure kubectl**:
   ```bash
   # Update kubeconfig
   aws eks update-kubeconfig --region us-west-2 --name retail-eks-cluster
   
   # Verify connection
   kubectl get nodes
   ```

## IAM Permissions Included
- **EKS Cluster Management**: Create, delete, and manage EKS clusters
- **Worker Node Management**: Manage EKS node groups and Auto Scaling
- **EC2 Permissions**: Full EC2 access for node management
- **IAM Permissions**: Create and manage service roles
- **SSM Access**: Systems Manager for secure shell access
- **CloudFormation**: Stack management for EKS resources

## Security Considerations
- **Encrypted Storage**: EBS volume is encrypted at rest
- **IAM Role**: Principle of least privilege with EKS-specific permissions
- **SSM Access**: Secure shell access without exposing SSH keys
- **Security Group**: Restrict access to specific IP ranges if needed
- **VPC Deployment**: Deploy in private subnet for enhanced security