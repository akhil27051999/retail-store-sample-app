# 🌤️ Serverless Weather App

A simple serverless weather application built with AWS Lambda and API Gateway that provides current weather conditions using the OpenWeatherMap API.

## 🏗️ Architecture

```
Internet → API Gateway → Lambda Function → OpenWeatherMap API
```

- **AWS Lambda**: Serverless function processing weather requests
- **API Gateway**: REST API endpoint for HTTP requests
- **OpenWeatherMap API**: External weather data source
- **CloudFormation**: Infrastructure as Code deployment

## 🚀 Features

- ☀️ Current weather conditions with emojis
- 🌡️ Temperature in Celsius
- 💧 Humidity information
- 🌍 Configurable location (ZIP code + country)
- ⚡ Serverless architecture (no server management)
- 🔒 Secure API key handling via environment variables

## 📋 Prerequisites

1. **AWS Account** with appropriate permissions
2. **AWS CLI** installed and configured
3. **OpenWeatherMap API Key** (free at [openweathermap.org](https://openweathermap.org/api))

## 🛠️ Quick Deployment

### Option 1: Automated Deployment (Recommended)

```bash
# Clone or download the project
cd weather-app-serverless

# Deploy with your API key and location
./deploy.sh YOUR_OPENWEATHER_API_KEY 10001 US
```

### Option 2: Manual Deployment

#### Step 1: Get OpenWeather API Key
1. Sign up at [OpenWeatherMap](https://openweathermap.org/api)
2. Get your free API key

#### Step 2: Deploy Infrastructure
```bash
aws cloudformation deploy \
    --template-file infrastructure/cloudformation-template.yaml \
    --stack-name weather-app-stack \
    --parameter-overrides \
        OpenWeatherAPIKey=YOUR_API_KEY_HERE \
        ZipCode=10001 \
        CountryCode=US \
    --capabilities CAPABILITY_NAMED_IAM \
    --region us-east-1
```

#### Step 3: Package and Upload Lambda Code
```bash
cd src
zip -r weather-app.zip index.js package.json

aws lambda update-function-code \
    --function-name weather-app-function \
    --zip-file fileb://weather-app.zip \
    --region us-east-1
```

## 🧪 Testing

### Test via cURL
```bash
curl https://your-api-id.execute-api.us-east-1.amazonaws.com/prod/weather
```

### Expected Response
```json
{
  "location": "New York, US",
  "condition": "☁️ Cloudy",
  "temperature": "22°C",
  "description": "scattered clouds",
  "humidity": "65%",
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

## ⚙️ Configuration

### Environment Variables (Lambda)
- `OPENWEATHER_API_KEY`: Your OpenWeatherMap API key
- `ZIP_CODE`: Location ZIP code (default: 10001)
- `COUNTRY_CODE`: Country code (default: US)

### Supported Weather Conditions
- ⛈️ Thunderstorm
- 🌦️ Drizzle  
- 🌧️ Raining
- ❄️ Snowing
- 🌫️ Foggy/Misty
- ☀️ Clear Sky
- ☁️ Cloudy

## 📁 Project Structure

```
weather-app-serverless/
├── src/
│   ├── index.js              # Lambda function code
│   └── package.json          # Node.js dependencies
├── infrastructure/
│   └── cloudformation-template.yaml  # AWS infrastructure
├── docs/
├── deploy.sh                 # Automated deployment script
└── README.md                 # This file
```

## 💰 Cost Estimation

This serverless app is extremely cost-effective:

- **Lambda**: ~$0.0000002 per request (first 1M requests free monthly)
- **API Gateway**: ~$0.0000035 per request (first 1M requests free for 12 months)
- **OpenWeatherMap**: Free tier (1000 calls/day)

**Monthly cost for 10,000 requests: ~$0.04**

## 🔧 Customization

### Change Location
Update the CloudFormation parameters:
```bash
aws cloudformation update-stack \
    --stack-name weather-app-stack \
    --use-previous-template \
    --parameters ParameterKey=ZipCode,ParameterValue=90210 \
                ParameterKey=CountryCode,ParameterValue=US
```

### Add More Weather Details
Modify `src/index.js` to include additional fields:
- Wind speed and direction
- Atmospheric pressure
- Sunrise/sunset times
- Weather forecast

## 🛡️ Security Best Practices

- ✅ API key stored as environment variable
- ✅ IAM role with minimal permissions
- ✅ HTTPS-only API endpoint
- ✅ CORS enabled for web integration

### Optional: Add API Key Authentication
```yaml
# Add to CloudFormation template
WeatherMethod:
  Properties:
    AuthorizationType: AWS_IAM
    # or use API Keys
    ApiKeyRequired: true
```

## 🚨 Troubleshooting

### Common Issues

1. **"API key not configured"**
   - Verify environment variable is set in Lambda

2. **"Failed to fetch weather data"**
   - Check OpenWeather API key validity
   - Verify ZIP code format

3. **CORS errors in browser**
   - Headers are configured in Lambda response

### Debug Commands
```bash
# Check stack status
aws cloudformation describe-stacks --stack-name weather-app-stack

# View Lambda logs
aws logs describe-log-groups --log-group-name-prefix /aws/lambda/weather-app

# Test Lambda directly
aws lambda invoke --function-name weather-app-function output.json
```

## 🧹 Cleanup

Remove all resources:
```bash
aws cloudformation delete-stack --stack-name weather-app-stack
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

MIT License - feel free to use this project for learning and development!

## 🌟 Next Steps

- Add weather forecast (5-day)
- Create a simple web frontend
- Add SMS/email notifications
- Implement caching with DynamoDB
- Add multiple location support
- Create mobile app integration

---

**Happy weather checking! 🌤️**