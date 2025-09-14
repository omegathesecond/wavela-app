# API Key Authentication Setup

The Yebo Verify app now uses `X-API-Key` authentication for all API calls.

## Setting the API Key

### Method 1: Environment Variable (Recommended)
```bash
flutter run --dart-define=API_KEY=your-actual-api-key-here
```

### Method 2: Build-time Configuration
```bash
flutter build apk --dart-define=API_KEY=your-actual-api-key-here
```

## API Key Format

The API key should be:
- At least 32 characters long
- A secure, randomly generated string
- Provided by your backend API service

## How It Works

### 1. All API calls include the header:
```
X-API-Key: your-actual-api-key-here
```

### 2. The ApiService automatically adds this header:
```dart
// Automatic header inclusion
final response = await apiService.get('/jobs');
// Headers sent:
// X-API-Key: your-actual-api-key-here
// Content-Type: application/json
// Accept: application/json
```

### 3. For user-specific operations, both headers are sent:
```dart
// When user is logged in, both headers are included:
// X-API-Key: your-actual-api-key-here
// Authorization: Bearer user-jwt-token
```

## API Configuration

The app uses a centralized configuration:

```dart
// lib/data/config/api_config.dart
static String get apiKey {
  const key = String.fromEnvironment('API_KEY', defaultValue: 'your-api-key-here');
  // Returns the API key from environment
}
```

## API Endpoints Structure

All endpoints follow the clean URL pattern (no `/api/` prefix):

```
POST /jobs                    # Create verification job
GET  /jobs/{id}/status       # Get job status  
POST /media/upload           # Upload files
GET  /verification/{id}      # Get verification results
```

## Security Benefits

1. **Server-side Processing**: All verification logic runs on the server
2. **API Key Protection**: Rate limiting and access control
3. **No Sensitive Data on Device**: Biometric templates stay on server
4. **Audit Trail**: All API calls are logged with key authentication

## Development vs Production

- **Development**: Shows warning if using default API key
- **Production**: Uses environment-provided key
- **Validation**: API key must be 32+ characters

## Testing the Setup

The app will automatically validate the API key on startup:

```dart
final apiService = Get.find<ApiService>();
final isValid = await apiService.validateApiKey();
print('API Key Valid: $isValid');
```

## Example Usage Flow

1. **App Launch**: Load API key from environment
2. **Create Job**: `POST /jobs` with X-API-Key header
3. **Upload Files**: `POST /media/upload` with files and job ID
4. **Poll Status**: `GET /jobs/{id}/status` until completed
5. **Get Results**: `GET /jobs/{id}/results` for final verification

This ensures secure, server-side processing while maintaining a smooth user experience.