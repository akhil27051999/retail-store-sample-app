# Changelog - Educational Fork

All notable changes to this educational fork of the AWS Containers Retail Sample App will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-01-20

### Added - Initial Educational Fork Release

#### Infrastructure as Code
- **CloudFormation Templates**
  - VPC template with multi-tier architecture (Web, App, Data subnets)
  - EKS Management Server template with Ubuntu 24.04
  - Complete networking setup with Internet Gateway and NAT Gateway
  - Security groups with proper access controls

#### EKS Management Server Features
- **Pre-installed Tools**
  - AWS CLI v2
  - kubectl v1.31.7
  - eksctl (latest)
  - Helm v3
  - SSM Agent for secure access
- **IAM Configuration**
  - Comprehensive EKS management permissions
  - EC2 and Auto Scaling permissions
  - CloudFormation and IAM role management
- **Instance Specifications**
  - Ubuntu 24.04 LTS AMI
  - t3a.small/medium instance types
  - 30GB encrypted gp3 EBS volume
  - Elastic IP assignment

#### Regional Configuration
- **Asia Pacific (Mumbai) - ap-south-1**
  - Updated all deployment commands for ap-south-1 region
  - Regional-specific kubectl installation
  - EKS cluster creation commands for Mumbai region

#### Documentation Updates
- **README Files**
  - Main README with EKS deployment instructions
  - CloudFormation README with detailed deployment guide
  - Step-by-step infrastructure setup instructions
- **Educational Focus**
  - Learning-oriented documentation
  - Cost monitoring reminders
  - Security best practices
  - Resource cleanup guidelines

#### License and Attribution
- **Educational Fork License**
  - Clear attribution to original AWS repository
  - Educational use disclaimer
  - Fork-specific modifications documentation
  - Support guidance for learning purposes

### Infrastructure Architecture
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

### Deployment Capabilities
- **VPC Infrastructure**: Complete multi-tier network setup
- **EKS Management**: Ready-to-use management server
- **Regional Deployment**: Optimized for ap-south-1 region
- **Security**: Encrypted storage, IAM roles, network segmentation
- **Automation**: CloudFormation-based infrastructure deployment

### Educational Value
- **Learning AWS Container Services**: EKS, ECR, ECS concepts
- **Infrastructure as Code**: CloudFormation templates and best practices
- **Network Architecture**: VPC design patterns and security
- **Container Orchestration**: Kubernetes deployment and management
- **Cost Management**: Resource optimization and cleanup procedures

---

## Original Upstream Changes

This fork is based on the original AWS Containers Retail Sample App. For upstream changes and original application features, refer to the [original repository](https://github.com/aws-containers/retail-store-sample-app).

### Original Application Features Included
- **Microservices Architecture**: Cart, Catalog, Checkout, Orders, UI services
- **Container Images**: Pre-built for x86-64 and ARM64 architectures
- **Observability**: Prometheus metrics and OpenTelemetry tracing
- **Multiple Backends**: MariaDB, DynamoDB, Redis support
- **Load Testing**: Built-in load generator
- **Istio Support**: Service mesh capabilities

---

**Note**: This is an educational fork intended for learning AWS container services. Always follow AWS security best practices and monitor costs during experimentation.