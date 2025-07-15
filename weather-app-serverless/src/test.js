// Local testing script for the weather Lambda function
const { handler } = require('./index');

// Mock environment variables for testing
process.env.OPENWEATHER_API_KEY = 'your_test_api_key_here';
process.env.ZIP_CODE = '10001';
process.env.COUNTRY_CODE = 'US';

// Mock event object
const mockEvent = {
    httpMethod: 'GET',
    path: '/weather',
    headers: {},
    queryStringParameters: null,
    body: null
};

// Test the function
async function testWeatherFunction() {
    console.log('🧪 Testing Weather Lambda Function...\n');
    
    try {
        const result = await handler(mockEvent);
        
        console.log('Status Code:', result.statusCode);
        console.log('Headers:', JSON.stringify(result.headers, null, 2));
        console.log('Response Body:', JSON.stringify(JSON.parse(result.body), null, 2));
        
        if (result.statusCode === 200) {
            console.log('\n✅ Test passed! Weather data retrieved successfully.');
        } else {
            console.log('\n❌ Test failed. Check the error message above.');
        }
        
    } catch (error) {
        console.error('❌ Test error:', error.message);
    }
}

// Run the test
testWeatherFunction();