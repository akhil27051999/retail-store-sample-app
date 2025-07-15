# 🌤️ Weather App API Documentation

## Base URL
```
https://your-api-id.execute-api.region.amazonaws.com/prod
```

## Endpoints

### GET /weather
Get current weather conditions for the configured location.

#### Request
```http
GET /weather HTTP/1.1
Host: your-api-id.execute-api.us-east-1.amazonaws.com
```

#### Response

**Success Response (200 OK)**
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

**Error Response (500 Internal Server Error)**
```json
{
  "error": "Failed to fetch weather data",
  "message": "Invalid API key"
}
```

## Weather Conditions

| Condition | Emoji | Description |
|-----------|-------|-------------|
| Thunderstorm | ⛈️ | Thunder and lightning |
| Drizzle | 🌦️ | Light rain |
| Rain | 🌧️ | Moderate to heavy rain |
| Snow | ❄️ | Snow conditions |
| Fog/Mist | 🌫️ | Low visibility |
| Clear | ☀️ | Clear sunny sky |
| Clouds | ☁️ | Cloudy conditions |

## Error Codes

| Status Code | Description |
|-------------|-------------|
| 200 | Success |
| 500 | Internal server error |
| 502 | Bad gateway (API unavailable) |
| 503 | Service unavailable |

## Rate Limits

- OpenWeatherMap Free Tier: 1,000 calls/day
- AWS Lambda: 1,000,000 requests/month (free tier)
- API Gateway: 1,000,000 requests/month (free tier for 12 months)

## Example Usage

### cURL
```bash
curl -X GET https://your-api-id.execute-api.us-east-1.amazonaws.com/prod/weather
```

### JavaScript (Fetch)
```javascript
fetch('https://your-api-id.execute-api.us-east-1.amazonaws.com/prod/weather')
  .then(response => response.json())
  .then(data => console.log(data))
  .catch(error => console.error('Error:', error));
```

### Python (requests)
```python
import requests

response = requests.get('https://your-api-id.execute-api.us-east-1.amazonaws.com/prod/weather')
weather_data = response.json()
print(weather_data)
```