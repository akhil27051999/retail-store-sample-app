# VPC Infrastructure Documentation

## Overview
This CloudFormation template creates a multi-tier VPC architecture for the retail store application with proper network segmentation and security.

## Architecture Details

### VPC Configuration
- **CIDR Block**: 192.168.0.0/16 (default)
- **DNS Support**: Enabled
- **DNS Hostnames**: Enabled

### Subnet Layout

| Tier | Subnet Name | CIDR Block | Availability Zone | Type |
|------|-------------|------------|-------------------|------|
| Web  | Web-Subnet-1 | 192.168.1.0/24 | AZ-1 | Public |
| Web  | Web-Subnet-2 | 192.168.2.0/24 | AZ-2 | Public |
| App  | App-Subnet-1 | 192.168.3.0/24 | AZ-1 | Private |
| App  | App-Subnet-2 | 192.168.4.0/24 | AZ-2 | Private |
| Data | Data-Subnet-1 | 192.168.5.0/24 | AZ-1 | Private |
| Data | Data-Subnet-2 | 192.168.6.0/24 | AZ-2 | Private |

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
- AWS Account with appropriate IAM permissions
- Access to AWS Console
- IAM permissions for CloudFormation, VPC, and S3 resources

### Method 1: Deploy via AWS Console (Recommended)

#### Step 1: Create S3 Bucket
1. Go to **S3 Console** in AWS
2. Click **Create bucket**
3. Enter bucket name (e.g., `retail-vpc-templates-[your-account-id]`)
4. Select your preferred region
5. Keep default settings and click **Create bucket**

#### Step 2: Upload VPC Template
1. Open your newly created S3 bucket
2. Click **Upload**
3. Select `vpc-template.yaml` from your local CloudFormation folder
4. Click **Upload**
5. Copy the **Object URL** of the uploaded template

#### Step 3: Deploy via CloudFormation Console
1. Go to **CloudFormation Console**
2. Click **Create stack** → **With new resources**
3. Select **Template is ready**
4. Choose **Amazon S3 URL**
5. Paste the S3 Object URL from Step 2
6. Click **Next**
7. Enter Stack name: `retail-vpc`
8. Review/modify CIDR parameters if needed (defaults use 192.168.0.0/16)
9. Click **Next** → **Next** → **Create stack**

### Method 2: Deploy via AWS CLI
```bash
aws cloudformation create-stack \
  --stack-name retail-vpc \
  --template-body file://vpc-template.yaml
```

### Stack Outputs
- VPC ID
- All subnet IDs (exportable for cross-stack references)

### Template Parameters
| Parameter | Default Value | Description |
|-----------|---------------|-------------|
| VpcCidr | 192.168.0.0/16 | CIDR block for VPC |
| WebSubnet1Cidr | 192.168.1.0/24 | CIDR block for Web Subnet 1 |
| WebSubnet2Cidr | 192.168.2.0/24 | CIDR block for Web Subnet 2 |
| AppSubnet1Cidr | 192.168.3.0/24 | CIDR block for App Subnet 1 |
| AppSubnet2Cidr | 192.168.4.0/24 | CIDR block for App Subnet 2 |
| DataSubnet1Cidr | 192.168.5.0/24 | CIDR block for Data Subnet 1 |
| DataSubnet2Cidr | 192.168.6.0/24 | CIDR block for Data Subnet 2 |

## Security Considerations
- Private subnets have no direct internet access
- NAT Gateway provides secure outbound connectivity
- Network ACLs and Security Groups can be added as needed