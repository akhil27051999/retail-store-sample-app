const https = require('https');

exports.handler = async (event) => {
    const headers = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type'
    };

    try {
        // Get environment variables
        const API_KEY = process.env.OPENWEATHER_API_KEY;
        const ZIP_CODE = process.env.ZIP_CODE || '10001';
        const COUNTRY_CODE = process.env.COUNTRY_CODE || 'US';

        if (!API_KEY) {
            return {
                statusCode: 500,
                headers,
                body: JSON.stringify({
                    error: 'OpenWeather API key not configured'
                })
            };
        }

        // Build API URL
        const url = `https://api.openweathermap.org/data/2.5/weather?zip=${ZIP_CODE},${COUNTRY_CODE}&appid=${API_KEY}&units=metric`;

        // Fetch weather data
        const weatherData = await fetchWeatherData(url);
        
        // Process weather data
        const weatherCondition = getWeatherCondition(weatherData);
        
        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({
                location: `${weatherData.name}, ${weatherData.sys.country}`,
                condition: weatherCondition,
                temperature: `${Math.round(weatherData.main.temp)}°C`,
                description: weatherData.weather[0].description,
                humidity: `${weatherData.main.humidity}%`,
                timestamp: new Date().toISOString()
            })
        };

    } catch (error) {
        console.error('Error:', error);
        return {
            statusCode: 500,
            headers,
            body: JSON.stringify({
                error: 'Failed to fetch weather data',
                message: error.message
            })
        };
    }
};

function fetchWeatherData(url) {
    return new Promise((resolve, reject) => {
        https.get(url, (response) => {
            let data = '';
            
            response.on('data', (chunk) => {
                data += chunk;
            });
            
            response.on('end', () => {
                try {
                    const weatherData = JSON.parse(data);
                    if (weatherData.cod === 200) {
                        resolve(weatherData);
                    } else {
                        reject(new Error(weatherData.message || 'Weather API error'));
                    }
                } catch (error) {
                    reject(new Error('Failed to parse weather data'));
                }
            });
        }).on('error', (error) => {
            reject(error);
        });
    });
}

function getWeatherCondition(weatherData) {
    const weatherId = weatherData.weather[0].id;
    const main = weatherData.weather[0].main.toLowerCase();
    
    // Weather condition mapping based on OpenWeather API codes
    if (weatherId >= 200 && weatherId < 300) {
        return '⛈️ Thunderstorm';
    } else if (weatherId >= 300 && weatherId < 400) {
        return '🌦️ Drizzle';
    } else if (weatherId >= 500 && weatherId < 600) {
        return '🌧️ Raining';
    } else if (weatherId >= 600 && weatherId < 700) {
        return '❄️ Snowing';
    } else if (weatherId >= 700 && weatherId < 800) {
        return '🌫️ Foggy/Misty';
    } else if (weatherId === 800) {
        return '☀️ Clear Sky';
    } else if (weatherId > 800) {
        return '☁️ Cloudy';
    }
    
    return `🌤️ ${main}`;
}