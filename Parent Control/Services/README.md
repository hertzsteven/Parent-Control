# Zuludesk API Integration Guide

## Overview

This folder contains all the networking layer components for integrating with the Zuludesk/Jamf School API. The implementation uses modern Swift async/await patterns with proper error handling and data mapping.

## Files

### 1. APIConfiguration.swift
Stores API credentials and configuration.

**Setup Instructions:**
1. Obtain your Network ID from Zuludesk: `Devices > Enroll Device(s)`
2. Generate an API Key from: `Organization > Settings > API`
3. Update the configuration:

```swift
// Option 1: Update default configuration
let config = APIConfiguration(
    baseURL: "yourDomain.jamfcloud.com",  // or "apiv6.zuludesk.com"
    networkID: "10482058",                 // Your Network ID
    apiKey: "YOUR_API_KEY_HERE",          // Your generated API key
    apiVersion: "1"
)

// Option 2: Use custom configuration
let service = NetworkService(configuration: .custom(
    baseURL: "yourDomain.jamfcloud.com",
    networkID: "10482058",
    apiKey: "YOUR_API_KEY_HERE"
))
```

### 2. APIModels.swift
Data Transfer Objects (DTOs) that match the Zuludesk API response structure.

- `AppsResponse` - Contains array of apps from `/apps/` endpoint
- `DevicesResponse` - Contains array of devices from `/devices/` endpoint
- `AppDTO` - Individual app data from API
- `DeviceDTO` - Individual device data from API

### 3. NetworkService.swift
Handles all network communication with the Zuludesk API.

**Key Methods:**
- `fetchApps()` - Retrieves all apps
- `fetchDevices()` - Retrieves all devices

**Error Handling:**
The service throws `NetworkError` enum with these cases:
- `.invalidURL` - URL construction failed
- `.authenticationFailed` - 401 status code
- `.networkUnavailable` - No internet connection
- `.invalidResponse` - Unexpected response format
- `.decodingFailed` - JSON parsing error
- `.serverError` - 4xx or 5xx status codes

### 4. ModelMappers.swift
Converts API DTOs to your app's domain models.

**Mappings:**
- `AppDTO` → `AppItem` - Maps API apps to your app models
- `DeviceDTO` → `Device` - Maps API devices with app associations

**Features:**
- Automatic icon mapping for common apps (YouTube, Safari, Music, etc.)
- Device type detection (iPad, iPhone, Mac, Apple TV)
- Color assignment for devices
- Bundle ID and platform info preservation

## Usage

### Basic Usage in ViewModel

The `ParentalControlViewModel` is already set up to use the network service. Here's how to use it:

```swift
// In your SwiftUI view
@State private var viewModel = ParentalControlViewModel()

var body: some View {
    ContentView()
        .task {
            // Load data when view appears
            await viewModel.loadData()
        }
}
```

### Loading Data

```swift
// Async/await in Task
Task {
    await viewModel.loadData()
}

// Or use convenience method
viewModel.loadDataInBackground()
```

### Monitoring Loading State

```swift
// In your SwiftUI view
if viewModel.isLoading {
    ProgressView("Loading...")
}

if let error = viewModel.errorMessage {
    Text("Error: \(error)")
        .foregroundColor(.red)
}
```

### Custom Network Service

If you need direct access to the network service:

```swift
let config = APIConfiguration(
    baseURL: "yourDomain.jamfcloud.com",
    networkID: "YOUR_NETWORK_ID",
    apiKey: "YOUR_API_KEY"
)

let networkService = NetworkService(configuration: config)

// Use in ViewModel
let viewModel = ParentalControlViewModel(
    networkService: networkService
)
```

## Testing

### Using Mock Data

The ViewModel automatically falls back to default mock data if network requests fail. This allows you to:
1. Develop the UI without network connectivity
2. Test error handling scenarios
3. Work offline

### Switching Between Mock and Live Data

```swift
// For development: Use with default mock data
let viewModel = ParentalControlViewModel()

// For production: Load from API
let viewModel = ParentalControlViewModel()
await viewModel.loadData()
```

## API Endpoints

Based on Zuludesk documentation:

| Endpoint | Method | Description | Response |
|----------|--------|-------------|----------|
| `/apps/` | GET | List all apps | `{"apps": [...]}` |
| `/devices/` | GET | List all devices | `{"devices": [...]}` |

## Authentication

The API uses HTTP Basic Authorization:
- **Username:** Network ID (e.g., "10482058")
- **Password:** API Key (e.g., "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
- **Header Format:** `Authorization: Basic <base64(networkID:apiKey)>`

## Example Response Structures

### Apps Response
```json
{
  "apps": [
    {
      "id": 25769,
      "bundleId": "com.apple.pages",
      "adamId": 335493278,
      "name": "Pages",
      "vendor": "Apple",
      "platform": "iOS"
    }
  ]
}
```

### Device Response (expected structure)
```json
{
  "devices": [
    {
      "id": 12345,
      "name": "Living Room iPad",
      "device_type": "iPad",
      "model": "iPad Pro",
      "apps": [25769, 25771]
    }
  ]
}
```

## Next Steps

1. **Update API Configuration** - Replace placeholder credentials with your actual Network ID and API Key
2. **Test Network Calls** - Call `loadData()` from your views
3. **Handle Errors** - Display `errorMessage` to users when requests fail
4. **Verify Device Response** - The device endpoint structure is assumed; verify it matches your API
5. **Add Additional Endpoints** - Extend `NetworkService` as needed

## Security Notes

⚠️ **Important:** Never commit your actual API keys to version control!

Consider:
- Using environment variables for credentials
- Storing sensitive data in Keychain
- Using `.gitignore` for configuration files
- Implementing secure credential storage

## Troubleshooting

### "Authentication Failed" Error
- Verify your Network ID is correct
- Check that your API Key has proper permissions
- Ensure API Key is active in Zuludesk settings

### "Invalid Response" Error
- Check if the API endpoint structure has changed
- Verify `DeviceDTO` matches actual device response
- Enable logging to see raw API responses

### "Network Unavailable" Error
- Check internet connectivity
- Verify firewall settings
- Confirm API base URL is accessible

## Future Enhancements

Consider adding:
- Token refresh logic if needed
- Caching layer for offline support
- Rate limiting protection
- Request retry logic
- Pagination support for large datasets
- WebSocket support for real-time updates

