# VPC Infrastructure Documentation

## Overview
This CloudFormation template creates a multi-tier VPC architecture for the retail store application with proper network segmentation and security.

## Architecture Details

### VPC Configuration
- **CIDR Block**: 10.0.0.0/16
- **DNS Support**: Enabled
- **DNS Hostnames**: Enabled

### Subnet Layout

| Tier | Subnet Name | CIDR Block | Availability Zone | Type |
|------|-------------|------------|-------------------|------|
| Web  | Web-Subnet-1 | 10.0.1.0/24 | AZ-1 | Public |
| Web  | Web-Subnet-2 | 10.0.2.0/24 | AZ-2 | Public |
| App  | App-Subnet-1 | 10.0.3.0/24 | AZ-1 | Private |
| App  | App-Subnet-2 | 10.0.4.0/24 | AZ-2 | Private |
| Data | Data-Subnet-1 | 10.0.5.0/24 | AZ-1 | Private |
| Data | Data-Subnet-2 | 10.0.6.0/24 | AZ-2 | Private |

### Network Components

#### Internet Gateway
- Provides internet access to public subnets
- Attached to VPC for bidirectional internet connectivity

#### NAT Gateway
- **Location**: Web-Subnet-1 (Public)
- **Purpose**: Outbound internet access for private subnets
- **Elastic IP**: Automatically allocated

#### Route Tables

| Route Table | Associated Subnets | Default Route |
|-------------|-------------------|---------------|
| Public-RouteTable | Web-Subnet-1, Web-Subnet-2 | Internet Gateway |
| Private-RouteTable | App-Subnet-1, App-Subnet-2, Data-Subnet-1, Data-Subnet-2 | NAT Gateway |

## Deployment

### Prerequisites
- AWS CLI configured
- Appropriate IAM permissions for CloudFormation and VPC resources

### Deploy Command
```bash
aws cloudformation create-stack \
  --stack-name retail-vpc \
  --template-body file://vpc-template.yaml
```

### Stack Outputs
- VPC ID
- All subnet IDs (exportable for cross-stack references)

## Security Considerations
- Private subnets have no direct internet access
- NAT Gateway provides secure outbound connectivity
- Network ACLs and Security Groups can be added as needed