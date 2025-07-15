#!/bin/bash

# Serverless Weather App Deployment Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
STACK_NAME="weather-app-stack"
REGION="us-east-1"
ZIP_FILE="weather-app.zip"

echo -e "${GREEN}🌤️  Serverless Weather App Deployment${NC}"
echo "=================================="

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if required parameters are provided
if [ -z "$1" ] || [ -z "$2" ]; then
    echo -e "${YELLOW}Usage: $0 <OPENWEATHER_API_KEY> <ZIP_CODE> [COUNTRY_CODE]${NC}"
    echo "Example: $0 your_api_key_here 10001 US"
    exit 1
fi

OPENWEATHER_API_KEY=$1
ZIP_CODE=$2
COUNTRY_CODE=${3:-US}

echo -e "${YELLOW}📦 Creating deployment package...${NC}"
cd src
zip -r ../$ZIP_FILE index.js package.json
cd ..

echo -e "${YELLOW}☁️  Deploying CloudFormation stack...${NC}"
aws cloudformation deploy \
    --template-file infrastructure/cloudformation-template.yaml \
    --stack-name $STACK_NAME \
    --parameter-overrides \
        OpenWeatherAPIKey=$OPENWEATHER_API_KEY \
        ZipCode=$ZIP_CODE \
        CountryCode=$COUNTRY_CODE \
    --capabilities CAPABILITY_NAMED_IAM \
    --region $REGION

echo -e "${YELLOW}📤 Updating Lambda function code...${NC}"
FUNCTION_NAME=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`LambdaFunctionName`].OutputValue' \
    --output text)

aws lambda update-function-code \
    --function-name $FUNCTION_NAME \
    --zip-file fileb://$ZIP_FILE \
    --region $REGION

echo -e "${GREEN}✅ Deployment completed successfully!${NC}"

# Get API endpoint
API_ENDPOINT=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`APIEndpoint`].OutputValue' \
    --output text)

echo ""
echo -e "${GREEN}🌐 Your Weather API is ready!${NC}"
echo -e "API Endpoint: ${YELLOW}$API_ENDPOINT${NC}"
echo ""
echo -e "${GREEN}🧪 Test your API:${NC}"
echo "curl $API_ENDPOINT"
echo ""

# Clean up
rm -f $ZIP_FILE

echo -e "${GREEN}🎉 Happy weather checking!${NC}"